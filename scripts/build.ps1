param(
    [ValidateSet('masm', 'uasm', 'jwasm')]
    [string]$Assembler = 'masm',
    [string]$AssemblerPath,
    [string]$MasmPath,
    [switch]$DebugBuild,
    [Nullable[int]]$DebugSeed,
    [switch]$DebugOverlay,
    [switch]$DebugStartInGame,
    [Nullable[int]]$DebugStartSector
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$srcDir = Join-Path $root 'src'
$buildDir = Join-Path $root 'build'

$layout = [pscustomobject]@{
    BootSectorBytes      = 512
    BootCodeLimitBytes   = 510
    FloppyBytes          = 1474560
    FloppySectors        = 2880
    Stage2LoadSegment    = 0x1000
    Stage2LoadOffset     = 0x0000
    Stage2LoadLimitBytes = 0x10000
    Stage2StartLba       = 1
    AssetBankLoadLimitBytes = 0x10000
}

$bootWarningBytes = 480
$stage2WarningBytes = 57344
$imageWarningPercent = 80
$screenshotPoolKeepCount = 6
$readmeScreenshotCount = 3
$readmeScreenshotPrefix = 'readme-shot-'

function Write-Section {
    param([string]$Title)

    Write-Host ""
    Write-Host ("== {0} ==" -f $Title)
}

function Assert-PathExists {
    param(
        [string]$Path,
        [string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw ("Missing {0}: {1}" -f $Label, $Path)
    }
}

function Read-UInt16Le {
    param([byte[]]$Bytes, [int]$Offset)
    return [BitConverter]::ToUInt16($Bytes, $Offset)
}

function Read-Int16Le {
    param([byte[]]$Bytes, [int]$Offset)
    return [BitConverter]::ToInt16($Bytes, $Offset)
}

function Read-UInt32Le {
    param([byte[]]$Bytes, [int]$Offset)
    return [BitConverter]::ToUInt32($Bytes, $Offset)
}

function Write-UInt16Le {
    param([byte[]]$Bytes, [int]$Offset, [int]$Value)

    $Bytes[$Offset] = [byte]($Value -band 0xFF)
    $Bytes[$Offset + 1] = [byte](($Value -shr 8) -band 0xFF)
}

function Format-Hex16 {
    param([int]$Value)
    return ("0x{0:X4}" -f ($Value -band 0xFFFF))
}

function Format-Hex32 {
    param([int]$Value)
    return ("0x{0:X8}" -f ($Value -band 0xFFFFFFFF))
}

function Format-Hex16Literal {
    param([int]$Value)
    return ("{0:X4}h" -f ($Value -band 0xFFFF))
}

function Get-PaddedSectorBytes {
    param(
        [int]$ByteCount,
        [int]$SectorBytes
    )

    if ($ByteCount -lt 0) {
        throw ("Byte count cannot be negative. Received: {0}" -f $ByteCount)
    }

    if ($ByteCount -eq 0) {
        return 0
    }

    return ([int][Math]::Ceiling($ByteCount / $SectorBytes) * $SectorBytes)
}

function Get-PhysicalAddress {
    param(
        [int]$Segment,
        [int]$Offset
    )

    return (($Segment -shl 4) + $Offset)
}

function Get-VsWherePath {
    $candidates = @(
        'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe',
        'C:\Program Files\Microsoft Visual Studio\Installer\vswhere.exe'
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return $null
}

function Get-AssemblerCliName {
    param([string]$Kind)

    switch ($Kind) {
        'masm' { return 'ml.exe' }
        'uasm' { return 'uasm.exe' }
        'jwasm' { return 'jwasm.exe' }
        default { throw ("Unsupported assembler kind: {0}" -f $Kind) }
    }
}

function Get-AssemblerDisplayName {
    param([string]$Kind)

    switch ($Kind) {
        'masm' { return 'MASM' }
        'uasm' { return 'UASM (experimental)' }
        'jwasm' { return 'JWasm (experimental)' }
        default { return $Kind }
    }
}

function Add-MasmCandidate {
    param(
        [System.Collections.Generic.List[object]]$Candidates,
        [string]$Path,
        [string]$Source
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $resolved = (Resolve-Path -LiteralPath $Path).Path
    if ($Candidates | Where-Object { $_.Path -eq $resolved }) {
        return
    }

    $Candidates.Add([pscustomobject]@{
        Path = $resolved
        Source = $Source
    })
}

function Resolve-AssemblerTool {
    param(
        [string]$Kind,
        [string]$RequestedPath,
        [string]$LegacyMasmPath
    )

    $candidates = New-Object 'System.Collections.Generic.List[object]'
    $cliName = Get-AssemblerCliName -Kind $Kind
    $displayName = Get-AssemblerDisplayName -Kind $Kind

    if ($RequestedPath) {
        if (-not (Test-Path -LiteralPath $RequestedPath)) {
            throw ("The requested {0} path does not exist: {1}" -f $displayName, $RequestedPath)
        }

        Add-MasmCandidate -Candidates $candidates -Path $RequestedPath -Source 'parameter'
    }

    if ($LegacyMasmPath) {
        if ($Kind -ne 'masm') {
            throw "-MasmPath can only be used with -Assembler masm. Use -AssemblerPath for alternate assemblers."
        }

        if (-not (Test-Path -LiteralPath $LegacyMasmPath)) {
            throw ("The requested MASM path does not exist: {0}" -f $LegacyMasmPath)
        }

        Add-MasmCandidate -Candidates $candidates -Path $LegacyMasmPath -Source 'MasmPath'
    }

    switch ($Kind) {
        'masm' {
            Add-MasmCandidate -Candidates $candidates -Path $env:ML_EXE -Source 'ML_EXE'

            $toolCommand = Get-Command $cliName -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($toolCommand) {
                Add-MasmCandidate -Candidates $candidates -Path $toolCommand.Source -Source 'PATH'
            }

            if ($env:VCToolsInstallDir) {
                foreach ($relative in @('bin\Hostx64\x86\ml.exe', 'bin\Hostx86\x86\ml.exe')) {
                    Add-MasmCandidate -Candidates $candidates -Path (Join-Path $env:VCToolsInstallDir $relative) -Source 'VCToolsInstallDir'
                }
            }

            $vswhere = Get-VsWherePath
            if ($vswhere) {
                foreach ($pattern in @(
                    'VC\Tools\MSVC\**\bin\Hostx64\x86\ml.exe',
                    'VC\Tools\MSVC\**\bin\Hostx86\x86\ml.exe'
                )) {
                    $found = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -find $pattern 2>$null | Select-Object -First 1
                    if ($LASTEXITCODE -eq 0 -and $found) {
                        Add-MasmCandidate -Candidates $candidates -Path $found -Source 'vswhere'
                    }
                }
            }
        }
        'uasm' {
            Add-MasmCandidate -Candidates $candidates -Path $env:UASM_EXE -Source 'UASM_EXE'
            $toolCommand = Get-Command $cliName -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($toolCommand) {
                Add-MasmCandidate -Candidates $candidates -Path $toolCommand.Source -Source 'PATH'
            }
        }
        'jwasm' {
            Add-MasmCandidate -Candidates $candidates -Path $env:JWASM_EXE -Source 'JWASM_EXE'
            $toolCommand = Get-Command $cliName -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($toolCommand) {
                Add-MasmCandidate -Candidates $candidates -Path $toolCommand.Source -Source 'PATH'
            }
        }
    }

    if ($candidates.Count -gt 0) {
        return [pscustomobject]@{
            Kind = $Kind
            Name = $displayName
            Path = $candidates[0].Path
            Source = $candidates[0].Source
            Experimental = ($Kind -ne 'masm')
        }
    }

    if ($Kind -eq 'masm') {
        throw @"
Could not find ml.exe for the MASM build.

Discovery order:
  1. -MasmPath
  2. -AssemblerPath
  3. ML_EXE environment variable
  4. PATH
  5. VCToolsInstallDir
  6. vswhere (Visual Studio / Build Tools)

Setup expectation:
  Install Visual Studio or Build Tools with the MSVC x86/x64 toolset that includes MASM.

Quick workaround:
  powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -MasmPath 'C:\path\to\ml.exe'
"@
    }

    throw @"
Could not find $cliName for the experimental $displayName build path.

Discovery order:
  1. -AssemblerPath
  2. $($Kind.ToUpperInvariant())_EXE environment variable
  3. PATH

Expectation:
  Install a MASM-compatible assembler that can accept `/coff` output and MASM-style source syntax.

Example:
  powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 -Assembler $Kind -AssemblerPath 'C:\path\to\$cliName'
"@
}

function Invoke-ExternalTool {
    param(
        [string]$Executable,
        [string[]]$Arguments
    )

    $captured = New-Object 'System.Collections.Generic.List[string]'
    & $Executable @Arguments 2>&1 | ForEach-Object {
        $line = $_.ToString()
        $captured.Add($line)
        Write-Host $line
    }

    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = $captured.ToArray()
    }
}

function Get-AssemblerDiagnosticSummary {
    param([string[]]$Output)

    return [pscustomobject]@{
        WarningCount = @($Output | Where-Object { $_ -match ':\s*warning\s' }).Count
        ErrorCount = @($Output | Where-Object { $_ -match ':\s*error\s' }).Count
    }
}

function Read-CoffName {
    param(
        [byte[]]$Bytes,
        [int]$Offset,
        [int]$StringTableOffset
    )

    $firstDword = Read-UInt32Le $Bytes $Offset
    $secondDword = Read-UInt32Le $Bytes ($Offset + 4)

    if ($firstDword -eq 0 -and $secondDword -ne 0) {
        if ($StringTableOffset -lt 0 -or $StringTableOffset -ge $Bytes.Length) {
            throw 'COFF string table offset was outside the object file.'
        }

        $cursor = $StringTableOffset + $secondDword
        if ($cursor -ge $Bytes.Length) {
            throw ("COFF string table reference {0} ran past the end of the object." -f $secondDword)
        }

        $nameBytes = New-Object 'System.Collections.Generic.List[byte]'
        while ($cursor -lt $Bytes.Length -and $Bytes[$cursor] -ne 0) {
            $nameBytes.Add($Bytes[$cursor])
            $cursor++
        }

        return [Text.Encoding]::ASCII.GetString($nameBytes.ToArray())
    }

    $raw = $Bytes[$Offset..($Offset + 7)]
    $end = [Array]::IndexOf($raw, [byte]0)
    if ($end -lt 0) {
        $end = $raw.Length
    }

    return [Text.Encoding]::ASCII.GetString($raw, 0, $end)
}

function Get-CoffObjectModel {
    param([string]$ObjectPath)

    Assert-PathExists -Path $ObjectPath -Label 'object file'
    $bytes = [IO.File]::ReadAllBytes($ObjectPath)

    if ($bytes.Length -lt 20) {
        throw ("COFF object is too small to contain a valid header: {0}" -f $ObjectPath)
    }

    $sectionCount = Read-UInt16Le $bytes 2
    $symbolTableOffset = [int](Read-UInt32Le $bytes 8)
    $symbolCount = [int](Read-UInt32Le $bytes 12)
    $optionalHeaderSize = Read-UInt16Le $bytes 16
    $sectionTableOffset = 20 + $optionalHeaderSize
    $sectionTableBytes = $sectionCount * 40
    $stringTableOffset = $symbolTableOffset + ($symbolCount * 18)

    if (($sectionTableOffset + $sectionTableBytes) -gt $bytes.Length) {
        throw ("Section table ran past the end of the object file: {0}" -f $ObjectPath)
    }

    if ($symbolTableOffset -gt $bytes.Length) {
        throw ("Symbol table offset was outside the object file: {0}" -f $ObjectPath)
    }

    if ($stringTableOffset -gt $bytes.Length) {
        throw ("String table offset was outside the object file: {0}" -f $ObjectPath)
    }

    $sections = @()
    for ($i = 0; $i -lt $sectionCount; $i++) {
        $offset = $sectionTableOffset + ($i * 40)
        $sections += [pscustomobject]@{
            Index = $i + 1
            Name = Read-CoffName $bytes $offset $stringTableOffset
            SizeOfRawData = [int](Read-UInt32Le $bytes ($offset + 16))
            PointerToRawData = [int](Read-UInt32Le $bytes ($offset + 20))
            PointerToRelocations = [int](Read-UInt32Le $bytes ($offset + 24))
            NumberOfRelocations = [int](Read-UInt16Le $bytes ($offset + 32))
        }
    }

    $symbolsByIndex = @{}
    $symbolsByName = @{}
    $symbolIndex = 0
    while ($symbolIndex -lt $symbolCount) {
        $offset = $symbolTableOffset + ($symbolIndex * 18)
        $symbol = [pscustomobject]@{
            Index = $symbolIndex
            Name = Read-CoffName $bytes $offset $stringTableOffset
            Value = [int](Read-UInt32Le $bytes ($offset + 8))
            SectionNumber = Read-Int16Le $bytes ($offset + 12)
            AuxCount = [int]$bytes[$offset + 17]
        }

        $symbolsByIndex[$symbolIndex] = $symbol
        if (-not $symbolsByName.ContainsKey($symbol.Name)) {
            $symbolsByName[$symbol.Name] = $symbol
        }

        $symbolIndex += 1 + $symbol.AuxCount
    }

    return [pscustomobject]@{
        Path = $ObjectPath
        Bytes = $bytes
        Sections = $sections
        SymbolsByIndex = $symbolsByIndex
        SymbolsByName = $symbolsByName
    }
}

function Get-CoffFlatBinary {
    param(
        [string]$ObjectPath,
        [string]$SectionPrefix = '.text'
    )

    $objectModel = Get-CoffObjectModel -ObjectPath $ObjectPath
    $targetSection = $objectModel.Sections | Where-Object { $_.Name.StartsWith($SectionPrefix) } | Select-Object -First 1

    if (-not $targetSection) {
        $available = ($objectModel.Sections | ForEach-Object { $_.Name }) -join ', '
        throw ("Could not find a section starting with '{0}' in {1}. Available sections: {2}" -f $SectionPrefix, $ObjectPath, $available)
    }

    if (($targetSection.PointerToRawData + $targetSection.SizeOfRawData) -gt $objectModel.Bytes.Length) {
        throw ("Target section '{0}' ran past the end of {1}" -f $targetSection.Name, $ObjectPath)
    }

    $flat = New-Object byte[] $targetSection.SizeOfRawData
    [Array]::Copy($objectModel.Bytes, $targetSection.PointerToRawData, $flat, 0, $targetSection.SizeOfRawData)

    for ($i = 0; $i -lt $targetSection.NumberOfRelocations; $i++) {
        $offset = $targetSection.PointerToRelocations + ($i * 10)
        if (($offset + 10) -gt $objectModel.Bytes.Length) {
            throw ("Relocation table for '{0}' ran past the end of {1}" -f $targetSection.Name, $ObjectPath)
        }

        $virtualAddress = [int](Read-UInt32Le $objectModel.Bytes $offset)
        $symbolIndex = [int](Read-UInt32Le $objectModel.Bytes ($offset + 4))
        $relocationType = Read-UInt16Le $objectModel.Bytes ($offset + 8)

        if ($virtualAddress -lt 0 -or ($virtualAddress + 2) -gt $flat.Length) {
            throw ("Relocation at RVA {0} was outside flattened section '{1}' in {2}" -f (Format-Hex32 $virtualAddress), $targetSection.Name, $ObjectPath)
        }

        if (-not $objectModel.SymbolsByIndex.ContainsKey($symbolIndex)) {
            throw ("Relocation referenced missing symbol index {0} in {1}" -f $symbolIndex, $ObjectPath)
        }

        $symbol = $objectModel.SymbolsByIndex[$symbolIndex]
        switch ($relocationType) {
            0x0001 {
                $current = Read-UInt16Le $flat $virtualAddress
                Write-UInt16Le $flat $virtualAddress ($current + $symbol.Value)
            }
            default {
                throw ("Unsupported relocation type {0} for symbol '{1}' in {2}" -f (Format-Hex16 $relocationType), $symbol.Name, $ObjectPath)
            }
        }
    }

    return [pscustomobject]@{
        FlatBytes = $flat
        ObjectModel = $objectModel
        TargetSection = $targetSection
        AppliedRelocations = $targetSection.NumberOfRelocations
    }
}

function Get-SymbolValue {
    param(
        $ObjectModel,
        [string[]]$Names
    )

    foreach ($name in $Names) {
        if ($ObjectModel.SymbolsByName.ContainsKey($name)) {
            return $ObjectModel.SymbolsByName[$name].Value
        }
    }

    return $null
}

function Invoke-Assembler {
    param(
        [string]$SourcePath,
        [string]$ObjectPath,
        [string]$ListPath,
        [string[]]$IncludePaths = @(),
        [string]$ToolPath,
        [string]$AssemblerName
    )

    Assert-PathExists -Path $SourcePath -Label 'assembly source'
    foreach ($includePath in $IncludePaths) {
        Assert-PathExists -Path $includePath -Label 'include directory'
    }

    $arguments = @('/nologo', '/c', '/coff', "/Fo$ObjectPath", "/Fl$ListPath")
    foreach ($includePath in $IncludePaths) {
        $arguments += "/I$includePath"
    }
    $arguments += $SourcePath

    $result = Invoke-ExternalTool -Executable $ToolPath -Arguments $arguments
    $diagnostics = Get-AssemblerDiagnosticSummary -Output $result.Output

    if ($result.ExitCode -ne 0) {
        throw @"
$AssemblerName failed.
  Source : $SourcePath
  Tool   : $ToolPath
  Object : $ObjectPath
  Listing: $ListPath
"@
    }

    Assert-PathExists -Path $ObjectPath -Label 'assembled object'
    Assert-PathExists -Path $ListPath -Label 'assembly listing'

    return [pscustomobject]@{
        Output = $result.Output
        WarningCount = $diagnostics.WarningCount
        ErrorCount = $diagnostics.ErrorCount
        ObjectPath = $ObjectPath
        ListPath = $ListPath
    }
}

function Validate-Stage2Layout {
    param(
        [int]$Stage2Bytes,
        [int]$Stage2Sectors,
        $Layout
    )

    if ($Stage2Bytes -lt 1) {
        throw 'Stage two was empty.'
    }

    if ($Stage2Bytes -gt $Layout.Stage2LoadLimitBytes) {
        throw @"
Stage two is too large for the current boot contract.
  Size      : $Stage2Bytes bytes
  Limit     : $($Layout.Stage2LoadLimitBytes) bytes
  Load addr : $(Format-Hex16 $Layout.Stage2LoadSegment):$(Format-Hex16 $Layout.Stage2LoadOffset)

The current bootloader reads stage two into a single 64 KiB segment.
"@
    }

    if ($Stage2Sectors -gt ($Layout.FloppySectors - 1)) {
        throw ("Stage two requires {0} sectors, but only {1} sectors are available after the boot sector." -f $Stage2Sectors, ($Layout.FloppySectors - 1))
    }

    $stage2EndOffset = $Layout.BootSectorBytes + $Stage2Bytes
    if ($stage2EndOffset -gt $Layout.FloppyBytes) {
        throw ("Boot + stage two would overflow the floppy image: end offset {0}, image size {1}." -f $stage2EndOffset, $Layout.FloppyBytes)
    }

    $stage2PaddedBytes = $Stage2Sectors * $Layout.BootSectorBytes
    if ($stage2PaddedBytes -gt $Layout.Stage2LoadLimitBytes) {
        throw ("Stage two padded size ({0} bytes) exceeds the loader's 64 KiB destination window." -f $stage2PaddedBytes)
    }
}

function Resolve-AssetBankLayout {
    param(
        [object[]]$AssetBanks,
        [int]$Stage2Sectors,
        $Layout
    )

    $nextLba = $Layout.Stage2StartLba + $Stage2Sectors
    $resolvedBanks = New-Object 'System.Collections.Generic.List[object]'

    foreach ($bank in @($AssetBanks)) {
        $bankBytes = [int]$bank.Bytes
        $bankSectors = [int][Math]::Ceiling($bankBytes / $Layout.BootSectorBytes)
        $bankPaddedBytes = Get-PaddedSectorBytes -ByteCount $bankBytes -SectorBytes $Layout.BootSectorBytes
        $bankEndLba = if ($bankSectors -gt 0) { $nextLba + $bankSectors - 1 } else { $nextLba - 1 }

        $resolvedBanks.Add([pscustomobject]@{
            Name = $bank.Name
            SymbolPrefix = $bank.SymbolPrefix
            SourcePath = $bank.SourcePath
            BinaryPath = $bank.BinaryPath
            LoadSegment = [int]$bank.LoadSegment
            Bytes = $bankBytes
            Sectors = $bankSectors
            PaddedBytes = $bankPaddedBytes
            StartLba = $nextLba
            EndLba = $bankEndLba
        })

        $nextLba = $bankEndLba + 1
    }

    return $resolvedBanks.ToArray()
}

function Write-GeneratedBankLayoutInclude {
    param(
        [string]$OutputPath,
        [object[]]$AssetBanks
    )

    $lines = New-Object 'System.Collections.Generic.List[string]'
    $lines.Add('; generated by scripts/build.ps1')
    $lines.Add('; stage two includes this file to locate banked read-only payloads on disk')
    $lines.Add('')

    foreach ($bank in @($AssetBanks)) {
        $prefix = [string]$bank.SymbolPrefix
        $lines.Add(("{0}_LBA EQU {1}" -f $prefix, [int]$bank.StartLba))
        $lines.Add(("{0}_SECTORS EQU {1}" -f $prefix, [int]$bank.Sectors))
        $lines.Add(("{0}_BYTES EQU {1}" -f $prefix, [int]$bank.Bytes))
        $lines.Add(("{0}_PADDED_BYTES EQU {1}" -f $prefix, [int]$bank.PaddedBytes))
        $lines.Add('')
    }

    if ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq '') {
        $lines.RemoveAt($lines.Count - 1)
    }

    Set-Content -LiteralPath $OutputPath -Encoding ascii -Value $lines
    Assert-PathExists -Path $OutputPath -Label 'generated bank layout include'
}

function Validate-AssetBanks {
    param(
        [int]$Stage2Sectors,
        [object[]]$AssetBanks,
        $Layout
    )

    $expectedStartLba = $Layout.Stage2StartLba + $Stage2Sectors
    foreach ($bank in @($AssetBanks)) {
        if ($bank.Bytes -lt 1) {
            throw ("Asset bank '{0}' is empty." -f $bank.Name)
        }

        if ($bank.Sectors -lt 1) {
            throw ("Asset bank '{0}' does not occupy any sectors." -f $bank.Name)
        }

        if ($bank.StartLba -ne $expectedStartLba) {
            throw ("Asset bank '{0}' is expected at LBA {1}, but was assigned {2}. The current phase-1 layout requires banks to be packed directly after stage two." -f $bank.Name, $expectedStartLba, $bank.StartLba)
        }

        if ($bank.PaddedBytes -gt $Layout.AssetBankLoadLimitBytes) {
            throw ("Asset bank '{0}' padded size ({1} bytes) exceeds the current single-segment runtime load window ({2} bytes)." -f $bank.Name, $bank.PaddedBytes, $Layout.AssetBankLoadLimitBytes)
        }

        if ($bank.EndLba -ge $Layout.FloppySectors) {
            throw ("Asset bank '{0}' would overflow the floppy image at LBA {1}. The highest valid LBA is {2}." -f $bank.Name, $bank.EndLba, ($Layout.FloppySectors - 1))
        }

        $expectedStartLba = $bank.EndLba + 1
    }
}

function Validate-ImageLayout {
    param(
        [int]$BootBytes,
        [int]$Stage2Bytes,
        [int]$Stage2Sectors,
        [object[]]$AssetBanks = @(),
        $Layout
    )

    if ($BootBytes -lt 1) {
        throw 'Boot sector payload was empty.'
    }

    if ($BootBytes -gt $Layout.BootCodeLimitBytes) {
        throw ("Bootloader is too large: {0} bytes (limit {1})." -f $BootBytes, $Layout.BootCodeLimitBytes)
    }

    Validate-Stage2Layout -Stage2Bytes $Stage2Bytes -Stage2Sectors $Stage2Sectors -Layout $Layout
    Validate-AssetBanks -Stage2Sectors $Stage2Sectors -AssetBanks $AssetBanks -Layout $Layout

    $diskFootprintBytes = $Layout.BootSectorBytes + ($Stage2Sectors * $Layout.BootSectorBytes) + ((@($AssetBanks) | Measure-Object -Property PaddedBytes -Sum).Sum)
    if ($diskFootprintBytes -gt $Layout.FloppyBytes) {
        throw ("Boot + stage two + asset banks would overflow the floppy image: {0} bytes required, image size {1}." -f $diskFootprintBytes, $Layout.FloppyBytes)
    }
}

function Get-BuildWarnings {
    param(
        [int]$BootBytes,
        [int]$Stage2Bytes,
        [int]$Stage2Sectors,
        [int]$ImageBytesUsed,
        [int]$DiskFootprintBytes,
        [object[]]$AssetBanks = @(),
        $Layout
    )

    $warnings = New-Object 'System.Collections.Generic.List[string]'

    if ($BootBytes -ge $bootWarningBytes) {
        $warnings.Add(("Boot code is within {0} bytes of the 510-byte limit." -f ($Layout.BootCodeLimitBytes - $BootBytes)))
    }

    if ($Stage2Bytes -ge $stage2WarningBytes) {
        $warnings.Add(("Stage two is within {0} bytes of the 64 KiB load limit." -f ($Layout.Stage2LoadLimitBytes - $Stage2Bytes)))
    }

    $imagePercent = [math]::Round(($DiskFootprintBytes / $Layout.FloppyBytes) * 100, 2)
    if ($imagePercent -ge $imageWarningPercent) {
        $warnings.Add(("Disk footprint is using {0}% of the floppy capacity." -f $imagePercent))
    }

    if ($Stage2Sectors -ge 120) {
        $warnings.Add(("Stage two uses {0} sectors; that is close to the 128-sector single-segment load limit." -f $Stage2Sectors))
    }

    foreach ($bank in @($AssetBanks)) {
        if ($bank.PaddedBytes -ge ($Layout.AssetBankLoadLimitBytes - 4096)) {
            $warnings.Add(("Asset bank '{0}' is within 4096 bytes of the current single-segment runtime load limit." -f $bank.Name))
        }
    }

    return $warnings.ToArray()
}

function Import-StructuredDataFile {
    param(
        [string]$SourcePath,
        [string]$Label
    )

    Assert-PathExists -Path $SourcePath -Label $Label

    try {
        $data = Import-PowerShellDataFile -LiteralPath $SourcePath
    } catch {
        try {
            $rawText = Get-Content -LiteralPath $SourcePath -Raw
            $data = [scriptblock]::Create($rawText).InvokeReturnAsIs()
        } catch {
            throw ("Failed to parse {0} {1}: {2}" -f $Label, $SourcePath, $_.Exception.Message)
        }
    }

    if (-not ($data -is [System.Collections.IDictionary])) {
        throw ("{0} must evaluate to a key/value table: {1}" -f $Label, $SourcePath)
    }

    return $data
}

function Get-AsmEquValue {
    param(
        [string]$SourcePath,
        [string]$Name
    )

    Assert-PathExists -Path $SourcePath -Label 'assembly constants source'
    $pattern = "^\s*{0}\s+equ\s+([0-9A-Fa-f]+h|\d+)\s*(?:;.*)?$" -f [regex]::Escape($Name)
    $match = Select-String -LiteralPath $SourcePath -Pattern $pattern | Select-Object -First 1
    if (-not $match) {
        throw ("Could not find numeric '{0} equ <value>' in {1}" -f $Name, $SourcePath)
    }

    $token = $match.Matches[0].Groups[1].Value
    if ($token -match '^[0-9A-Fa-f]+h$') {
        return [Convert]::ToInt32($token.Substring(0, $token.Length - 1), 16)
    }

    return [int]$token
}

function ConvertTo-AsmStringLiteral {
    param(
        [string]$Value,
        [string]$Context
    )

    if ($null -eq $Value) {
        throw ("{0} cannot be null." -f $Context)
    }

    if ($Value.Contains('"')) {
        throw ("{0} cannot contain double quotes because generated includes emit MASM double-quoted strings." -f $Context)
    }

    foreach ($ch in $Value.ToCharArray()) {
        if ([int][char]$ch -gt 127) {
            throw ("{0} must stay ASCII-only. Offending character: '{1}'." -f $Context, $ch)
        }
    }

    return ('"{0}"' -f $Value)
}

function Add-AsmDataLines {
    param(
        [System.Collections.Generic.List[string]]$Lines,
        [string]$Label,
        [string]$Directive,
        [string[]]$Values,
        [int]$ValuesPerLine = 4
    )

    if ($null -eq $Values -or $Values.Count -eq 0) {
        throw ("No values were provided for generated label '{0}'." -f $Label)
    }

    $indent = (' ' * ($Label.Length + 1)) + "$Directive "
    for ($i = 0; $i -lt $Values.Count; $i += $ValuesPerLine) {
        $chunkEnd = [Math]::Min(($i + $ValuesPerLine - 1), ($Values.Count - 1))
        $chunk = $Values[$i..$chunkEnd]
        $prefix = if ($i -eq 0) { "$Label $Directive " } else { $indent }
        $Lines.Add($prefix + ($chunk -join ', '))
    }
}

function Write-GeneratedSectorIncludes {
    param(
        [string]$SourcePath,
        [string]$SectorOutputPath,
        [string]$MapsOutputPath,
        [int]$ExpectedSectorCount,
        [int]$ExpectedMapWidth,
        [int]$ExpectedMapHeight
    )

    $contentData = Import-StructuredDataFile -SourcePath $SourcePath -Label 'sector content source'
    if (-not $contentData.ContainsKey('Sectors')) {
        throw ("Sector content source must define a 'Sectors' array: {0}" -f $SourcePath)
    }

    $sectors = @($contentData['Sectors'] | Sort-Object { [int]$_.Id })
    if ($sectors.Count -ne $ExpectedSectorCount) {
        throw ("Sector content defined {0} sectors, but the runtime contract expects {1}." -f $sectors.Count, $ExpectedSectorCount)
    }

    $sectorLines = New-Object 'System.Collections.Generic.List[string]'
    $mapLines = New-Object 'System.Collections.Generic.List[string]'

    $sectorLines.Add('; generated by scripts/build.ps1')
    $sectorLines.Add(("; source: {0}" -f $SourcePath))
    $sectorLines.Add('; edit the sector source file instead of this generated include')
    $sectorLines.Add('')

    $mapLines.Add('; generated by scripts/build.ps1')
    $mapLines.Add(("; source: {0}" -f $SourcePath))
    $mapLines.Add('; edit the sector source file instead of this generated include')
    $mapLines.Add('')

    $templateStart = New-Object 'System.Collections.Generic.List[string]'
    $templateCount = New-Object 'System.Collections.Generic.List[string]'
    $templateOffsets = New-Object 'System.Collections.Generic.List[string]'
    $nameRefs = New-Object 'System.Collections.Generic.List[string]'
    $introRefs = New-Object 'System.Collections.Generic.List[string]'
    $surgeCounts = New-Object 'System.Collections.Generic.List[string]'
    $terminalCounts = New-Object 'System.Collections.Generic.List[string]'
    $enemyBonuses = New-Object 'System.Collections.Generic.List[string]'
    $flankerThresholds = New-Object 'System.Collections.Generic.List[string]'
    $wardenThresholds = New-Object 'System.Collections.Generic.List[string]'
    $wardenDistances = New-Object 'System.Collections.Generic.List[string]'
    $templateSummary = New-Object 'System.Collections.Generic.List[string]'
    $ruleSummary = New-Object 'System.Collections.Generic.List[string]'
    $seenMapNames = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    $mapPayloadBytes = New-Object 'System.Collections.Generic.List[byte]'

    $mapCount = 0
    $mapBytes = 0
    $templateBase = 0

    foreach ($sector in $sectors) {
        if (-not ($sector -is [System.Collections.IDictionary])) {
            throw ("Each sector in {0} must be a hashtable." -f $SourcePath)
        }

        $sectorId = [int]$sector['Id']
        if ($sectorId -lt 1 -or $sectorId -gt $ExpectedSectorCount) {
            throw ("Sector id {0} in {1} is outside the expected 1..{2} range." -f $sectorId, $SourcePath, $ExpectedSectorCount)
        }

        if ($sectorId -ne ($templateSummary.Count + 1)) {
            throw ("Sector ids in {0} must be contiguous and ordered starting at 1." -f $SourcePath)
        }

        $title = [string]$sector['Title']
        if ([string]::IsNullOrWhiteSpace($title)) {
            throw ("Sector {0} in {1} is missing its Title." -f $sectorId, $SourcePath)
        }

        $intro = [string]$sector['Intro']
        if ([string]::IsNullOrWhiteSpace($intro)) {
            throw ("Sector {0} in {1} is missing its Intro text." -f $sectorId, $SourcePath)
        }

        $rules = $sector['Rules']
        if (-not ($rules -is [System.Collections.IDictionary])) {
            throw ("Sector {0} in {1} must define a Rules table." -f $sectorId, $SourcePath)
        }

        foreach ($requiredRule in @('SurgeCount', 'TerminalCount', 'EnemyBonus', 'FlankerThreshold', 'WardenThreshold', 'WardenEngageDistance')) {
            if (-not $rules.ContainsKey($requiredRule)) {
                throw ("Sector {0} in {1} is missing rule '{2}'." -f $sectorId, $SourcePath, $requiredRule)
            }
        }

        $surgeCount = [int]$rules['SurgeCount']
        $terminalCount = [int]$rules['TerminalCount']
        $enemyBonus = [int]$rules['EnemyBonus']
        $flankerThreshold = [int]$rules['FlankerThreshold']
        $wardenThreshold = [int]$rules['WardenThreshold']
        $wardenDistance = [int]$rules['WardenEngageDistance']

        foreach ($ruleValue in @(
            @{ Name = 'SurgeCount'; Value = $surgeCount },
            @{ Name = 'TerminalCount'; Value = $terminalCount },
            @{ Name = 'EnemyBonus'; Value = $enemyBonus },
            @{ Name = 'FlankerThreshold'; Value = $flankerThreshold },
            @{ Name = 'WardenThreshold'; Value = $wardenThreshold },
            @{ Name = 'WardenEngageDistance'; Value = $wardenDistance }
        )) {
            if ($ruleValue.Value -lt 0 -or $ruleValue.Value -gt 255) {
                throw ("Sector {0} rule '{1}' in {2} must fit in one byte. Received: {3}" -f $sectorId, $ruleValue.Name, $SourcePath, $ruleValue.Value)
            }
        }

        $maps = @($sector['Maps'])
        if ($maps.Count -eq 0) {
            throw ("Sector {0} in {1} did not define any maps." -f $sectorId, $SourcePath)
        }

        $templateStart.Add($templateBase.ToString())
        $templateCount.Add($maps.Count.ToString())
        $surgeCounts.Add($surgeCount.ToString())
        $terminalCounts.Add($terminalCount.ToString())
        $enemyBonuses.Add($enemyBonus.ToString())
        $flankerThresholds.Add($flankerThreshold.ToString())
        $wardenThresholds.Add($wardenThreshold.ToString())
        $wardenDistances.Add($wardenDistance.ToString())
        $templateSummary.Add(("S{0} x{1}" -f $sectorId, $maps.Count))
        $ruleSummary.Add(("S{0}: surge={1} terminal={2} bonus={3} flank<{4} warden<{5}" -f $sectorId, $surgeCount, $terminalCount, $enemyBonus, $flankerThreshold, $wardenThreshold))

        $sectorLabel = ("sector{0}" -f $sectorId)
        $nameRefs.Add(("offset {0}_name" -f $sectorLabel))
        $introRefs.Add(("offset {0}_intro" -f $sectorLabel))

        $mapLines.Add(("; Sector {0} - {1}" -f $sectorId, $title))
        foreach ($map in $maps) {
            if (-not ($map -is [System.Collections.IDictionary])) {
                throw ("Each map in sector {0} of {1} must be a hashtable." -f $sectorId, $SourcePath)
            }

            $mapName = [string]$map['Name']
            if ([string]::IsNullOrWhiteSpace($mapName) -or $mapName -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
                throw ("Sector {0} in {1} has an invalid map label '{2}'." -f $sectorId, $SourcePath, $mapName)
            }

            if (-not $seenMapNames.Add($mapName)) {
                throw ("Map label '{0}' was defined more than once in {1}." -f $mapName, $SourcePath)
            }

            $rows = @($map['Rows'])
            if ($rows.Count -ne $ExpectedMapHeight) {
                throw ("Map '{0}' in {1} declared {2} rows, expected {3}." -f $mapName, $SourcePath, $rows.Count, $ExpectedMapHeight)
            }

            $indent = (' ' * ($mapName.Length + 1)) + 'db '
            $templateOffsets.Add($mapPayloadBytes.Count.ToString())
            for ($rowIndex = 0; $rowIndex -lt $rows.Count; $rowIndex++) {
                $row = [string]$rows[$rowIndex]
                if ($row.Length -ne $ExpectedMapWidth) {
                    throw ("Map '{0}' row {1} in {2} has width {3}, expected {4}." -f $mapName, ($rowIndex + 1), $SourcePath, $row.Length, $ExpectedMapWidth)
                }

                foreach ($ch in $row.ToCharArray()) {
                    if ([int][char]$ch -gt 127) {
                        throw ("Map '{0}' row {1} in {2} must stay ASCII-only." -f $mapName, ($rowIndex + 1), $SourcePath)
                    }
                }

                $prefix = if ($rowIndex -eq 0) { "$mapName db " } else { $indent }
                $mapLines.Add($prefix + (ConvertTo-AsmStringLiteral -Value $row -Context ("map row {0} for {1}" -f ($rowIndex + 1), $mapName)))
                foreach ($byteValue in [Text.Encoding]::ASCII.GetBytes($row)) {
                    $mapPayloadBytes.Add($byteValue)
                }
            }

            $mapLines.Add('')
            $mapCount += 1
            $mapBytes += ($ExpectedMapWidth * $ExpectedMapHeight)
        }

        $templateBase += $maps.Count
    }

    Add-AsmDataLines -Lines $sectorLines -Label 'sector_rule_surge_count' -Directive 'db' -Values $surgeCounts.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $sectorLines -Label 'sector_rule_terminal_count' -Directive 'db' -Values $terminalCounts.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $sectorLines -Label 'sector_rule_enemy_bonus' -Directive 'db' -Values $enemyBonuses.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $sectorLines -Label 'sector_rule_flanker_threshold' -Directive 'db' -Values $flankerThresholds.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $sectorLines -Label 'sector_rule_warden_threshold' -Directive 'db' -Values $wardenThresholds.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $sectorLines -Label 'sector_rule_warden_engage_distance' -Directive 'db' -Values $wardenDistances.ToArray() -ValuesPerLine 8
    $sectorLines.Add('')
    Add-AsmDataLines -Lines $sectorLines -Label 'sector_template_start' -Directive 'db' -Values $templateStart.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $sectorLines -Label 'sector_template_count' -Directive 'db' -Values $templateCount.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $sectorLines -Label 'template_offset_table' -Directive 'dw' -Values $templateOffsets.ToArray() -ValuesPerLine 6
    Add-AsmDataLines -Lines $sectorLines -Label 'sector_name_table' -Directive 'dw' -Values $nameRefs.ToArray() -ValuesPerLine 3
    Add-AsmDataLines -Lines $sectorLines -Label 'sector_intro_table' -Directive 'dw' -Values $introRefs.ToArray() -ValuesPerLine 3
    $sectorLines.Add('')

    foreach ($sector in $sectors) {
        $sectorId = [int]$sector['Id']
        $sectorLabel = ("sector{0}" -f $sectorId)
        $sectorLines.Add(("{0}_name db {1}, 0" -f $sectorLabel, (ConvertTo-AsmStringLiteral -Value ([string]$sector['Title']) -Context ("sector {0} title" -f $sectorId))))
        $sectorLines.Add(("{0}_intro db {1}, 0" -f $sectorLabel, (ConvertTo-AsmStringLiteral -Value ([string]$sector['Intro']) -Context ("sector {0} intro" -f $sectorId))))
    }

    if ($mapLines.Count -gt 0 -and $mapLines[$mapLines.Count - 1] -eq '') {
        $mapLines.RemoveAt($mapLines.Count - 1)
    }

    Set-Content -LiteralPath $SectorOutputPath -Encoding ascii -Value $sectorLines
    Set-Content -LiteralPath $MapsOutputPath -Encoding ascii -Value $mapLines
    Assert-PathExists -Path $SectorOutputPath -Label 'generated sector content include'
    Assert-PathExists -Path $MapsOutputPath -Label 'generated maps include'

    return [pscustomobject]@{
        SourcePath = $SourcePath
        SectorOutputPath = $SectorOutputPath
        MapsOutputPath = $MapsOutputPath
        SectorCount = $sectors.Count
        MapCount = $mapCount
        MapBytes = $mapBytes
        MapPayloadBytes = $mapPayloadBytes.ToArray()
        Geometry = ("{0}x{1}" -f $ExpectedMapWidth, $ExpectedMapHeight)
        TemplateSummary = ($templateSummary -join ', ')
        RuleSummary = ($ruleSummary -join ' | ')
    }
}

function Write-GeneratedDemoInclude {
    param(
        [string]$SourcePath,
        [string]$OutputPath,
        [int]$ExpectedSectorCount
    )

    $demoData = Import-StructuredDataFile -SourcePath $SourcePath -Label 'demo source'
    if (-not $demoData.ContainsKey('Demos')) {
        throw ("Demo source must define a 'Demos' array: {0}" -f $SourcePath)
    }

    $actionTokenMap = @{
        'WAIT'  = 'DEMO_ACTION_WAIT'
        'LEFT'  = 'DEMO_ACTION_LEFT'
        'RIGHT' = 'DEMO_ACTION_RIGHT'
        'UP'    = 'DEMO_ACTION_UP'
        'DOWN'  = 'DEMO_ACTION_DOWN'
        'PULSE' = 'DEMO_ACTION_PULSE'
        'A'     = 'DEMO_ACTION_LEFT'
        'D'     = 'DEMO_ACTION_RIGHT'
        'W'     = 'DEMO_ACTION_UP'
        'S'     = 'DEMO_ACTION_DOWN'
        'C'     = 'DEMO_ACTION_PULSE'
    }

    $demos = @($demoData['Demos'])
    if ($demos.Count -eq 0) {
        throw ("Demo source must define at least one demo: {0}" -f $SourcePath)
    }

    $lines = New-Object 'System.Collections.Generic.List[string]'
    $lines.Add('; generated by scripts/build.ps1')
    $lines.Add(("; source: {0}" -f $SourcePath))
    $lines.Add('; demo scripts are compact [action, repeat-count] byte pairs')
    $lines.Add('; edit the demo source file instead of this generated include')
    $lines.Add('')
    $lines.Add(("DEMO_COUNT EQU {0}" -f $demos.Count))
    $lines.Add('')

    $startSectors = New-Object 'System.Collections.Generic.List[string]'
    $seeds = New-Object 'System.Collections.Generic.List[string]'
    $scriptRefs = New-Object 'System.Collections.Generic.List[string]'
    $demoDataLines = New-Object 'System.Collections.Generic.List[string]'
    $demoSummary = New-Object 'System.Collections.Generic.List[string]'
    $stepCount = 0

    for ($demoIndex = 0; $demoIndex -lt $demos.Count; $demoIndex++) {
        $demo = $demos[$demoIndex]
        if (-not ($demo -is [System.Collections.IDictionary])) {
            throw ("Each demo in {0} must be a hashtable." -f $SourcePath)
        }

        $name = [string]$demo['Name']
        if ([string]::IsNullOrWhiteSpace($name)) {
            throw ("Demo {0} in {1} is missing its Name." -f ($demoIndex + 1), $SourcePath)
        }

        $startSector = [int]$demo['StartSector']
        if ($startSector -lt 1 -or $startSector -gt $ExpectedSectorCount) {
            throw ("Demo '{0}' in {1} must use StartSector 1..{2}." -f $name, $SourcePath, $ExpectedSectorCount)
        }

        $seed = [int]$demo['Seed']
        if ($seed -lt 0 -or $seed -gt 0xFFFF) {
            throw ("Demo '{0}' in {1} must use a 16-bit Seed." -f $name, $SourcePath)
        }

        $steps = @($demo['Steps'])
        if ($steps.Count -eq 0) {
            throw ("Demo '{0}' in {1} did not define any Steps." -f $name, $SourcePath)
        }

        $demoLabel = ("demo_script_{0}" -f $demoIndex)
        $startSectors.Add($startSector.ToString())
        $seeds.Add((Format-Hex16Literal $seed))
        $scriptRefs.Add(("offset {0}" -f $demoLabel))
        $demoSummary.Add(("{0} (S{1}, {2} steps)" -f $name, $startSector, $steps.Count))
        $demoDataLines.Add(("; Demo {0}: {1}" -f ($demoIndex + 1), $name))

        for ($stepIndex = 0; $stepIndex -lt $steps.Count; $stepIndex++) {
            $step = $steps[$stepIndex]
            $actionKey = $null
            $repeatCount = $null

            if ($step -is [System.Collections.IDictionary]) {
                $actionKey = [string]$step['Action']
                if ($step.ContainsKey('Ticks')) {
                    $repeatCount = [int]$step['Ticks']
                } elseif ($step.ContainsKey('Count')) {
                    $repeatCount = [int]$step['Count']
                } elseif ($step.ContainsKey('Repeat')) {
                    $repeatCount = [int]$step['Repeat']
                }
            } else {
                $parts = ([string]$step).Trim() -split '\s+'
                if ($parts.Count -ne 2) {
                    throw ("Demo '{0}' step '{1}' in {2} must be 'ACTION COUNT'." -f $name, $step, $SourcePath)
                }

                $actionKey = $parts[0]
                $repeatCount = [int]$parts[1]
            }

            $actionKey = $actionKey.ToUpperInvariant()
            if (-not $actionTokenMap.ContainsKey($actionKey)) {
                throw ("Demo '{0}' in {1} used unsupported action '{2}'." -f $name, $SourcePath, $actionKey)
            }

            if ($repeatCount -lt 1 -or $repeatCount -gt 255) {
                throw ("Demo '{0}' action '{1}' in {2} must use a repeat count between 1 and 255." -f $name, $actionKey, $SourcePath)
            }

            $prefix = if ($stepIndex -eq 0) { "$demoLabel db " } else { (' ' * ($demoLabel.Length + 1)) + 'db ' }
            $demoDataLines.Add($prefix + ("{0}, {1}" -f $actionTokenMap[$actionKey], $repeatCount))
            $stepCount += 1
        }

        $demoDataLines.Add(((' ' * ($demoLabel.Length + 1)) + 'db DEMO_ACTION_END, 0'))
        $demoDataLines.Add('')
    }

    Add-AsmDataLines -Lines $lines -Label 'demo_start_sector_table' -Directive 'db' -Values $startSectors.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'demo_seed_table' -Directive 'dw' -Values $seeds.ToArray() -ValuesPerLine 6
    Add-AsmDataLines -Lines $lines -Label 'demo_script_table' -Directive 'dw' -Values $scriptRefs.ToArray() -ValuesPerLine 4
    $lines.Add('')
    foreach ($demoLine in $demoDataLines) {
        $lines.Add($demoLine)
    }

    if ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq '') {
        $lines.RemoveAt($lines.Count - 1)
    }

    Set-Content -LiteralPath $OutputPath -Encoding ascii -Value $lines
    Assert-PathExists -Path $OutputPath -Label 'generated demo include'

    return [pscustomobject]@{
        SourcePath = $SourcePath
        OutputPath = $OutputPath
        DemoCount = $demos.Count
        StepCount = $stepCount
        DemoSummary = ($demoSummary -join ', ')
    }
}

function Write-GeneratedMusicInclude {
    param(
        [string]$SourcePath,
        [string]$OutputPath
    )

    $musicData = Import-StructuredDataFile -SourcePath $SourcePath -Label 'music source'
    if (-not $musicData.ContainsKey('Themes')) {
        throw ("Music source must define a 'Themes' array: {0}" -f $SourcePath)
    }

    $expectedThemeKeys = @('splash', 'title', 'run', 'win', 'lose')
    $noteTokenMap = @{
        'REST' = 'MUSIC_NOTE_REST'
        'G3'   = 'MUSIC_NOTE_G3'
        'A3'   = 'MUSIC_NOTE_A3'
        'C4'   = 'MUSIC_NOTE_C4'
        'D4'   = 'MUSIC_NOTE_D4'
        'E4'   = 'MUSIC_NOTE_E4'
        'F4'   = 'MUSIC_NOTE_F4'
        'G4'   = 'MUSIC_NOTE_G4'
        'A4'   = 'MUSIC_NOTE_A4'
        'C5'   = 'MUSIC_NOTE_C5'
        'LOOP' = 'MUSIC_NOTE_LOOP'
    }

    $themes = @($musicData['Themes'])
    if ($themes.Count -ne $expectedThemeKeys.Count) {
        throw ("Music source defined {0} themes, but the runtime expects {1}." -f $themes.Count, $expectedThemeKeys.Count)
    }

    $lines = New-Object 'System.Collections.Generic.List[string]'
    $lines.Add('; generated by scripts/build.ps1')
    $lines.Add(("; source: {0}" -f $SourcePath))
    $lines.Add('; edit the music source file instead of this generated include')
    $lines.Add('')

    $themeDataLines = New-Object 'System.Collections.Generic.List[string]'
    $themeRefs = New-Object 'System.Collections.Generic.List[string]'
    $themeSummary = New-Object 'System.Collections.Generic.List[string]'
    $themeCount = 0
    $eventCount = 0

    foreach ($themeIndex in 0..($themes.Count - 1)) {
        $theme = $themes[$themeIndex]
        if (-not ($theme -is [System.Collections.IDictionary])) {
            throw ("Each theme in {0} must be a hashtable." -f $SourcePath)
        }

        $themeKey = ([string]$theme['Key']).ToLowerInvariant()
        if ($themeKey -ne $expectedThemeKeys[$themeIndex]) {
            throw ("Theme {0} in {1} must use key '{2}' to match the runtime theme order." -f ($themeIndex + 1), $SourcePath, $expectedThemeKeys[$themeIndex])
        }

        $events = @($theme['Events'])
        if ($events.Count -eq 0) {
            throw ("Theme '{0}' in {1} did not define any events." -f $themeKey, $SourcePath)
        }

        $themeLabel = ("music_theme_{0}_data" -f $themeKey)
        $themeRefs.Add(("offset {0}" -f $themeLabel))
        $themeSummary.Add(("{0} x{1}" -f $themeKey, $events.Count))
        $themeDataLines.Add(("; Theme: {0}" -f $themeKey.ToUpperInvariant()))

        for ($eventIndex = 0; $eventIndex -lt $events.Count; $eventIndex++) {
            $eventEntry = $events[$eventIndex]
            $noteKey = $null
            $duration = $null

            if ($eventEntry -is [System.Collections.IDictionary]) {
                $noteKey = [string]$eventEntry['Note']
                if ($eventEntry.ContainsKey('Ticks')) {
                    $duration = [int]$eventEntry['Ticks']
                } elseif ($eventEntry.ContainsKey('Duration')) {
                    $duration = [int]$eventEntry['Duration']
                }
            } else {
                $parts = ([string]$eventEntry).Trim() -split '\s+'
                if ($parts.Count -eq 1) {
                    $noteKey = $parts[0]
                    $duration = if ($parts[0].ToUpperInvariant() -eq 'LOOP') { 0 } else { $null }
                } elseif ($parts.Count -eq 2) {
                    $noteKey = $parts[0]
                    $duration = [int]$parts[1]
                } else {
                    throw ("Theme '{0}' event '{1}' in {2} must be 'NOTE TICKS' or 'LOOP'." -f $themeKey, $eventEntry, $SourcePath)
                }
            }

            $noteKey = $noteKey.ToUpperInvariant()
            if (-not $noteTokenMap.ContainsKey($noteKey)) {
                throw ("Theme '{0}' in {1} used unsupported note '{2}'." -f $themeKey, $SourcePath, $noteKey)
            }

            if ($null -eq $duration) {
                throw ("Theme '{0}' note '{1}' in {2} is missing its tick duration." -f $themeKey, $noteKey, $SourcePath)
            }

            if ($duration -lt 0 -or $duration -gt 255) {
                throw ("Theme '{0}' note '{1}' in {2} must use a 0..255 tick duration." -f $themeKey, $noteKey, $SourcePath)
            }

            if ($noteKey -eq 'LOOP' -and $duration -ne 0) {
                throw ("Theme '{0}' loop marker in {1} must use duration 0." -f $themeKey, $SourcePath)
            }

            if ($eventIndex -lt ($events.Count - 1) -and $noteKey -eq 'LOOP') {
                throw ("Theme '{0}' in {1} must place LOOP as its final event." -f $themeKey, $SourcePath)
            }

            $prefix = if ($eventIndex -eq 0) { "$themeLabel db " } else { (' ' * ($themeLabel.Length + 1)) + 'db ' }
            $themeDataLines.Add($prefix + ("{0}, {1}" -f $noteTokenMap[$noteKey], $duration))
        }

        $themeDataLines.Add('')
        $themeCount += 1
        $eventCount += $events.Count
    }

    Add-AsmDataLines -Lines $lines -Label 'music_theme_table' -Directive 'dw' -Values $themeRefs.ToArray() -ValuesPerLine 3
    $lines.Add('')
    foreach ($themeLine in $themeDataLines) {
        $lines.Add($themeLine)
    }

    if ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq '') {
        $lines.RemoveAt($lines.Count - 1)
    }

    Set-Content -LiteralPath $OutputPath -Encoding ascii -Value $lines
    Assert-PathExists -Path $OutputPath -Label 'generated music include'

    return [pscustomobject]@{
        SourcePath = $SourcePath
        OutputPath = $OutputPath
        ThemeCount = $themeCount
        EventCount = $eventCount
        ThemeSummary = ($themeSummary -join ', ')
    }
}

function Write-GeneratedArtInclude {
    param(
        [string]$SourcePath,
        [string]$OutputPath
    )

    Assert-PathExists -Path $SourcePath -Label 'art asset source'

    try {
        $assetData = Import-PowerShellDataFile -LiteralPath $SourcePath
    } catch {
        try {
            $assetSourceText = Get-Content -LiteralPath $SourcePath -Raw
            $assetData = [scriptblock]::Create($assetSourceText).InvokeReturnAsIs()
        } catch {
            throw ("Failed to parse art asset source {0}: {1}" -f $SourcePath, $_.Exception.Message)
        }
    }

    if (-not ($assetData -is [System.Collections.IDictionary])) {
        throw ("Art asset source must evaluate to a key/value table: {0}" -f $SourcePath)
    }

    if ($null -eq $assetData -or -not $assetData.ContainsKey('Legend')) {
        throw ("Art asset source must define a 'Legend' table: {0}" -f $SourcePath)
    }

    if ($null -eq $assetData -or -not $assetData.ContainsKey('Assets')) {
        throw ("Art asset source must define an 'Assets' array: {0}" -f $SourcePath)
    }

    $legend = New-Object 'System.Collections.Generic.Dictionary[string,string]' ([System.StringComparer]::Ordinal)
    if ($assetData.Legend -is [System.Collections.IDictionary]) {
        $legendEntries = @($assetData.Legend.GetEnumerator() | ForEach-Object {
            [pscustomobject]@{
                Key = $_.Key
                Value = $_.Value
            }
        })
    } else {
        $legendEntries = @($assetData.Legend)
    }

    if ($legendEntries.Count -eq 0) {
        throw ("Art asset legend did not define any entries: {0}" -f $SourcePath)
    }

    foreach ($entry in $legendEntries) {
        if ($entry -is [System.Collections.IDictionary]) {
            if ($entry.ContainsKey('Pixel')) {
                $key = [string]$entry['Pixel']
            } elseif ($entry.ContainsKey('Key')) {
                $key = [string]$entry['Key']
            } else {
                throw ("Legend entries in {0} must define either 'Pixel' or 'Key'." -f $SourcePath)
            }

            if ($entry.ContainsKey('Value')) {
                $value = [string]$entry['Value']
            } elseif ($entry.ContainsKey('Token')) {
                $value = [string]$entry['Token']
            } else {
                throw ("Legend entry '{0}' in {1} is missing its assembly token." -f $key, $SourcePath)
            }
        } else {
            throw ("Legend entries in {0} must be key/value pairs or Pixel/Value records." -f $SourcePath)
        }

        if ($key.Length -ne 1) {
            throw ("Legend key '{0}' in {1} must be exactly one character." -f $key, $SourcePath)
        }

        if ([string]::IsNullOrWhiteSpace($value)) {
            throw ("Legend entry '{0}' in {1} is blank." -f $key, $SourcePath)
        }

        if ($legend.ContainsKey($key)) {
            throw ("Legend key '{0}' was defined more than once in {1}." -f $key, $SourcePath)
        }

        $legend[$key] = $value.Trim()
    }

    $assets = @($assetData['Assets'])
    if ($assets.Count -eq 0) {
        throw ("Art asset source did not define any assets: {0}" -f $SourcePath)
    }

    $lines = New-Object 'System.Collections.Generic.List[string]'
    $lines.Add('; generated by scripts/build.ps1')
    $lines.Add(("; source: {0}" -f $SourcePath))
    $lines.Add('; edit the source asset file instead of this generated include')
    $lines.Add('')

    $assetCount = 0
    $totalBytes = 0
    $sizeCounts = @{}
    $currentSection = $null

    foreach ($asset in $assets) {
        if (-not ($asset -is [System.Collections.IDictionary])) {
            throw ("Each asset entry in {0} must be a hashtable." -f $SourcePath)
        }

        $name = [string]$asset['Name']
        if ([string]::IsNullOrWhiteSpace($name) -or $name -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
            throw ("Asset name '{0}' in {1} is missing or not a valid assembly label." -f $name, $SourcePath)
        }

        $section = ''
        if ($asset.ContainsKey('Section') -and -not [string]::IsNullOrWhiteSpace([string]$asset['Section'])) {
            $section = [string]$asset['Section']
        }

        if ($section -ne $currentSection) {
            if ($assetCount -gt 0) {
                $lines.Add('')
            }

            if ($section) {
                $lines.Add(("; {0}" -f $section))
            }

            $currentSection = $section
        }

        $rows = @($asset['Rows'])
        if ($rows.Count -eq 0) {
            throw ("Asset '{0}' in {1} did not define any rows." -f $name, $SourcePath)
        }

        $width = if ($asset.ContainsKey('Width')) { [int]$asset['Width'] } else { ([string]$rows[0]).Length }
        $height = if ($asset.ContainsKey('Height')) { [int]$asset['Height'] } else { $rows.Count }

        if ($width -le 0 -or $height -le 0) {
            throw ("Asset '{0}' in {1} must have positive Width/Height values." -f $name, $SourcePath)
        }

        if ($rows.Count -ne $height) {
            throw ("Asset '{0}' in {1} declared height {2} but provided {3} rows." -f $name, $SourcePath, $height, $rows.Count)
        }

        $indent = (' ' * ($name.Length + 1)) + 'db '
        for ($rowIndex = 0; $rowIndex -lt $rows.Count; $rowIndex++) {
            $row = [string]$rows[$rowIndex]
            if ($row.Length -ne $width) {
                throw ("Asset '{0}' row {1} in {2} has width {3}, expected {4}." -f $name, ($rowIndex + 1), $SourcePath, $row.Length, $width)
            }

            $tokens = New-Object 'System.Collections.Generic.List[string]'
            foreach ($ch in $row.ToCharArray()) {
                $key = [string]$ch
                if (-not $legend.ContainsKey($key)) {
                    throw ("Asset '{0}' in {1} used unknown legend key '{2}'." -f $name, $SourcePath, $key)
                }

                $tokens.Add($legend[$key])
            }

            $prefix = if ($rowIndex -eq 0) { "$name db " } else { $indent }
            $lines.Add($prefix + ($tokens -join ','))
        }

        $lines.Add('')

        $sizeKey = ("{0}x{1}" -f $width, $height)
        if (-not $sizeCounts.ContainsKey($sizeKey)) {
            $sizeCounts[$sizeKey] = 0
        }

        $sizeCounts[$sizeKey] += 1
        $assetCount += 1
        $totalBytes += ($width * $height)
    }

    if ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq '') {
        $lines.RemoveAt($lines.Count - 1)
    }

    Set-Content -LiteralPath $OutputPath -Encoding ascii -Value $lines
    Assert-PathExists -Path $OutputPath -Label 'generated art include'

    $sizeSummary = (($sizeCounts.GetEnumerator() | Sort-Object Key | ForEach-Object {
        "{0} x{1}" -f $_.Key, $_.Value
    }) -join ', ')

    return [pscustomobject]@{
        SourcePath = $SourcePath
        OutputPath = $OutputPath
        AssetCount = $assetCount
        TotalBytes = $totalBytes
        SizeSummary = $sizeSummary
    }
}

function Sync-ReadmeScreenshots {
    param(
        [string]$BuildDir,
        [int]$PoolKeepCount,
        [int]$ReadmeSlotCount,
        [string]$ReadmeSlotPrefix
    )

    Assert-PathExists -Path $BuildDir -Label 'build directory'

    $rotationStatePath = Join-Path $BuildDir 'readme-screenshot-rotation.txt'
    $slotNames = 1..$ReadmeSlotCount | ForEach-Object { "{0}{1}.png" -f $ReadmeSlotPrefix, $_ }
    $slotSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($slotName in $slotNames) {
        $null = $slotSet.Add($slotName)
    }

    $pngs = @(Get-ChildItem -LiteralPath $BuildDir -Filter '*.png' -File -ErrorAction SilentlyContinue)
    $sourceScreenshots = @(
        $pngs |
            Where-Object { -not $slotSet.Contains($_.Name) } |
            Sort-Object -Property @{ Expression = 'LastWriteTimeUtc'; Descending = $true }, @{ Expression = 'Name'; Descending = $false }
    )
    $removed = New-Object 'System.Collections.Generic.List[string]'

    if ($sourceScreenshots.Count -gt $PoolKeepCount) {
        foreach ($staleShot in @($sourceScreenshots | Select-Object -Skip $PoolKeepCount)) {
            Remove-Item -LiteralPath $staleShot.FullName -Force
            $removed.Add($staleShot.Name)
        }

        $sourceScreenshots = @($sourceScreenshots | Select-Object -First $PoolKeepCount)
    }

    $galleryCandidates = @($sourceScreenshots | Where-Object { $_.Length -ge 3000 })
    if ($galleryCandidates.Count -eq 0) {
        $galleryCandidates = $sourceScreenshots
    }

    function Get-ScreenshotTags {
        param([string]$Name)

        $stem = [IO.Path]::GetFileNameWithoutExtension($Name).ToLowerInvariant()
        $tags = New-Object 'System.Collections.Generic.List[string]'

        if ($stem -match '(title|splash|boot|bitriver|intro)') { $tags.Add('title') }
        if ($stem -match '(gameplay|sector|run|combat|hud|map)') { $tags.Add('gameplay') }
        if ($stem -match '(hazard|surge|terminal|spoof|shard|emp|pulse|trap)') { $tags.Add('hazard') }
        if ($stem -match '(elite|warden|flanker|hunter|enemy|pressure)') { $tags.Add('elite') }
        if ($stem -match '(ending|win|lose|gate|unlock|transition|victory|defeat)') { $tags.Add('ending') }
        if ($stem -match '(debug|overlay|pipeline|asset|bank|memory|module|technical|report)') { $tags.Add('technical') }

        if ($tags.Count -eq 0) {
            $tags.Add('uncategorized')
        }

        return @($tags)
    }

    function Get-PreferredScreenshotCandidate {
        param(
            [object[]]$Candidates,
            [string[]]$PreferenceOrder,
            [int]$RotationIndex
        )

        if ($Candidates.Count -eq 0) {
            return $null
        }

        $ranked = foreach ($candidate in $Candidates) {
            $rank = $PreferenceOrder.Count
            for ($preferenceIndex = 0; $preferenceIndex -lt $PreferenceOrder.Count; $preferenceIndex++) {
                if (@($candidate.Tags) -contains $PreferenceOrder[$preferenceIndex]) {
                    $rank = $preferenceIndex
                    break
                }
            }

            [pscustomobject]@{
                Candidate = $candidate
                Rank = $rank
            }
        }

        $bestRank = ($ranked | Measure-Object -Property Rank -Minimum).Minimum
        $bestCandidates = @(
            $ranked |
                Where-Object { $_.Rank -eq $bestRank } |
                Sort-Object -Property @{ Expression = { $_.Candidate.File.LastWriteTimeUtc }; Descending = $true }, @{ Expression = { $_.Candidate.File.Name }; Descending = $false }
        )

        $selectedIndex = $RotationIndex % $bestCandidates.Count
        return $bestCandidates[$selectedIndex].Candidate
    }

    $galleryMetadata = @(
        foreach ($candidate in $galleryCandidates) {
            [pscustomobject]@{
                File = $candidate
                Tags = @(Get-ScreenshotTags -Name $candidate.Name)
            }
        }
    )

    $slotTaxonomy = @(
        [pscustomobject]@{
            Label = 'title'
            PreferenceOrder = @('title', 'gameplay', 'technical', 'hazard', 'elite', 'ending', 'uncategorized')
        }
        [pscustomobject]@{
            Label = 'gameplay'
            PreferenceOrder = @('gameplay', 'hazard', 'elite', 'title', 'technical', 'ending', 'uncategorized')
        }
        [pscustomobject]@{
            Label = 'payoff'
            PreferenceOrder = @('ending', 'hazard', 'elite', 'technical', 'gameplay', 'title', 'uncategorized')
        }
    )

    $rotationIndex = 0
    if (Test-Path -LiteralPath $rotationStatePath) {
        $rawRotation = (Get-Content -LiteralPath $rotationStatePath -Raw).Trim()
        if ($rawRotation -match '^\d+$') {
            $rotationIndex = [int]$rawRotation
        }
    }

    $slotSummary = New-Object 'System.Collections.Generic.List[string]'
    $usedSourcePaths = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

    if ($sourceScreenshots.Count -eq 0) {
        foreach ($slotName in $slotNames) {
            $slotPath = Join-Path $BuildDir $slotName
            if (Test-Path -LiteralPath $slotPath) {
                Remove-Item -LiteralPath $slotPath -Force
                $removed.Add($slotName)
            }
        }

        Set-Content -LiteralPath $rotationStatePath -Encoding ascii -Value '0'
    } else {
        for ($slotIndex = 0; $slotIndex -lt $ReadmeSlotCount; $slotIndex++) {
            $slotConfig = if ($slotIndex -lt $slotTaxonomy.Count) { $slotTaxonomy[$slotIndex] } else { $slotTaxonomy[$slotTaxonomy.Count - 1] }
            $availableCandidates = @($galleryMetadata | Where-Object { -not $usedSourcePaths.Contains($_.File.FullName) })
            if ($availableCandidates.Count -eq 0) {
                $availableCandidates = $galleryMetadata
            }

            $sourceShot = Get-PreferredScreenshotCandidate `
                -Candidates $availableCandidates `
                -PreferenceOrder $slotConfig.PreferenceOrder `
                -RotationIndex ($rotationIndex + $slotIndex)
            $slotName = $slotNames[$slotIndex]
            $slotPath = Join-Path $BuildDir $slotName
            Copy-Item -LiteralPath $sourceShot.File.FullName -Destination $slotPath -Force
            $null = $usedSourcePaths.Add($sourceShot.File.FullName)
            $slotSummary.Add(("{0} [{1}] <- {2}" -f $slotName, $slotConfig.Label, $sourceShot.File.Name))
        }

        Set-Content -LiteralPath $rotationStatePath -Encoding ascii -Value ($rotationIndex + 1)
    }

    return [pscustomobject]@{
        RotationStatePath = $rotationStatePath
        SourceCount = $sourceScreenshots.Count
        RemovedCount = $removed.Count
        RemovedNames = @($removed)
        ReadmeSlots = @($slotSummary)
    }
}

function Write-BuildReport {
    param(
        [string]$ReportPath,
        [string]$AssemblerName,
        [string]$ToolPath,
        [string]$ToolSource,
        [string]$BuildMode,
        [string]$DeterministicSeed,
        [string]$OverlayMode,
        [string]$StartMode,
        [string]$StartSector,
        [string]$GeneratedArtSource,
        [string]$GeneratedArtInclude,
        [int]$GeneratedArtCount,
        [int]$GeneratedArtBytes,
        [string]$GeneratedArtSizes,
        [string[]]$GeneratedContentLines,
        [string[]]$ReplayHarnessLines,
        [string[]]$BalanceHarnessLines,
        [string[]]$RegressionHarnessLines,
        [string[]]$AssetBankLines,
        [string]$ScreenshotHousekeeping,
        [string[]]$ReadmeScreenshotSlots,
        [int]$BootBytes,
        [int]$Stage2Bytes,
        [int]$Stage2Sectors,
        [int]$Stage2PaddedBytes,
        [int]$ImageBytesUsed,
        [int]$DiskFootprintBytes,
        [int]$BootWarnings,
        [int]$StageWarnings,
        [int]$BootRelocations,
        [int]$StageRelocations,
        [string]$BootSectionName,
        [string]$StageSectionName,
        [Nullable[int]]$BootStartOffset,
        [Nullable[int]]$StageStartOffset,
        [string[]]$Warnings,
        [string[]]$ArtifactPaths,
        $Layout
    )

    $bootPhysical = Get-PhysicalAddress -Segment 0 -Offset 0x7C00
    $stagePhysical = Get-PhysicalAddress -Segment $Layout.Stage2LoadSegment -Offset $Layout.Stage2LoadOffset
    $bootFreeBytes = $Layout.BootCodeLimitBytes - $BootBytes
    $stage2FreeBytes = $Layout.Stage2LoadLimitBytes - $Stage2Bytes
    $imageFreeBytes = $Layout.FloppyBytes - $ImageBytesUsed
    $diskFootprintFreeBytes = $Layout.FloppyBytes - $DiskFootprintBytes
    $stage2EndLba = $Layout.Stage2StartLba + $Stage2Sectors - 1

    [array]$warningList = @()
    if ($null -ne $Warnings) {
        $warningList = @($Warnings) | Where-Object { $null -ne $_ -and $_ -ne '' }
    }

    [array]$artifactList = @()
    if ($null -ne $ArtifactPaths) {
        $artifactList = @($ArtifactPaths) | Where-Object { $null -ne $_ -and $_ -ne '' }
    }

    $lines = @(
        'CyberStorm Build Report'
        ("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'))
        ''
        'Toolchain'
        ("  Assembler: {0}" -f $AssemblerName)
        ("  Assembler path: {0}" -f $ToolPath)
        ("  Discovered via: {0}" -f $ToolSource)
        ''
        'Build Profile'
        ("  Mode: {0}" -f $BuildMode)
        ("  Deterministic seed: {0}" -f $DeterministicSeed)
        ("  Debug overlay: {0}" -f $OverlayMode)
        ("  Startup mode: {0}" -f $StartMode)
        ("  Run start sector: {0}" -f $StartSector)
        ''
        'Generated Art'
        ("  Source file: {0}" -f $GeneratedArtSource)
        ("  Generated include: {0}" -f $GeneratedArtInclude)
        ("  Bitmap count: {0}" -f $GeneratedArtCount)
        ("  Pixel data bytes: {0}" -f $GeneratedArtBytes)
        ("  Sizes: {0}" -f $GeneratedArtSizes)
    )

    if ($null -ne $GeneratedContentLines -and @($GeneratedContentLines).Count -gt 0) {
        $lines += @(
            ''
            'Generated Content'
        )

        foreach ($contentLine in @($GeneratedContentLines)) {
            $lines += ("  {0}" -f $contentLine)
        }
    }

    if ($null -ne $ReplayHarnessLines -and @($ReplayHarnessLines).Count -gt 0) {
        $lines += @(
            ''
            'Replay Harness'
        )

        foreach ($replayLine in @($ReplayHarnessLines)) {
            $lines += ("  {0}" -f $replayLine)
        }
    }

    if ($null -ne $BalanceHarnessLines -and @($BalanceHarnessLines).Count -gt 0) {
        $lines += @(
            ''
            'Balance Harness'
        )

        foreach ($balanceLine in @($BalanceHarnessLines)) {
            $lines += ("  {0}" -f $balanceLine)
        }
    }

    if ($null -ne $RegressionHarnessLines -and @($RegressionHarnessLines).Count -gt 0) {
        $lines += @(
            ''
            'Regression Harness'
        )

        foreach ($regressionLine in @($RegressionHarnessLines)) {
            $lines += ("  {0}" -f $regressionLine)
        }
    }

    if ($null -ne $AssetBankLines -and @($AssetBankLines).Count -gt 0) {
        $lines += @(
            ''
            'Asset Banks'
        )

        foreach ($bankLine in @($AssetBankLines)) {
            $lines += ("  {0}" -f $bankLine)
        }
    }

    $lines += @(
        ''
        'Screenshots'
        ("  Housekeeping: {0}" -f $ScreenshotHousekeeping)
    )

    if ($null -ne $ReadmeScreenshotSlots -and @($ReadmeScreenshotSlots).Count -gt 0) {
        foreach ($slotLine in @($ReadmeScreenshotSlots)) {
            $lines += ("  {0}" -f $slotLine)
        }
    } else {
        $lines += '  README slots: none'
    }

    $lines += @(
        ''
        'Layout'
        ("  Boot code bytes: {0} / {1}" -f $BootBytes, $Layout.BootCodeLimitBytes)
        ("  Boot code free bytes: {0}" -f $bootFreeBytes)
        ("  Stage2 bytes: {0}" -f $Stage2Bytes)
        ("  Stage2 free bytes before 64 KiB limit: {0}" -f $stage2FreeBytes)
        ("  Stage2 padded bytes: {0}" -f $Stage2PaddedBytes)
        ("  Stage2 sectors: {0}" -f $Stage2Sectors)
        ("  Image bytes used: {0} / {1}" -f $ImageBytesUsed, $Layout.FloppyBytes)
        ("  Image free bytes: {0}" -f $imageFreeBytes)
        ("  Disk footprint bytes: {0} / {1}" -f $DiskFootprintBytes, $Layout.FloppyBytes)
        ("  Disk footprint free bytes: {0}" -f $diskFootprintFreeBytes)
        ("  Boot load address: 0000:7C00 (phys {0})" -f (Format-Hex32 $bootPhysical))
        ("  Stage2 load address: {0}:{1} (phys {2})" -f (Format-Hex16 $Layout.Stage2LoadSegment), (Format-Hex16 $Layout.Stage2LoadOffset), (Format-Hex32 $stagePhysical))
        ("  Boot signature: 0x55AA @ byte 510")
        ("  Stage2 LBA range: {0}..{1}" -f $Layout.Stage2StartLba, $stage2EndLba)
        ("  Boot section: {0} (relocations applied: {1})" -f $BootSectionName, $BootRelocations)
        ("  Stage2 section: {0} (relocations applied: {1})" -f $StageSectionName, $StageRelocations)
        ("  Assembler warnings: boot={0}, stage2={1}" -f $BootWarnings, $StageWarnings)
    )

    if ($BootStartOffset -ne $null) {
        $lines += ("  Boot 'start' symbol offset: {0}" -f (Format-Hex16 $BootStartOffset))
    }

    if ($StageStartOffset -ne $null) {
        $lines += ("  Stage2 'start' symbol offset: {0}" -f (Format-Hex16 $StageStartOffset))
    }

    $lines += ''
    $lines += 'Artifacts'
    foreach ($artifactPath in $artifactList) {
        $lines += ("  {0}" -f $artifactPath)
    }

    $lines += ''
    $lines += 'Warnings'
    if ($warningList.Length -eq 0) {
        $lines += '  none'
    } else {
        foreach ($warning in $warningList) {
            $lines += ("  {0}" -f $warning)
        }
    }

    Set-Content -LiteralPath $ReportPath -Encoding ascii -Value $lines
}

Assert-PathExists -Path $srcDir -Label 'source directory'
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

if ($DebugSeed -ne $null -and ($DebugSeed -lt 0 -or $DebugSeed -gt 0xFFFF)) {
    throw ("Debug seed must be a 16-bit value between 0 and 65535. Received: {0}" -f $DebugSeed)
}

if ($DebugStartSector -ne $null -and ($DebugStartSector -lt 1 -or $DebugStartSector -gt 255)) {
    throw ("Debug start sector must fit in one byte (1-255). Received: {0}" -f $DebugStartSector)
}

$assemblerTool = Resolve-AssemblerTool -Kind $Assembler -RequestedPath $AssemblerPath -LegacyMasmPath $MasmPath

$gameAsm = Join-Path $srcDir 'game.asm'
$bootAsm = Join-Path $srcDir 'boot.asm'
$constantsSourcePath = Join-Path $srcDir 'game\constants.inc'
$artSourcePath = Join-Path $root 'assets\visuals.psd1'
$sectorSourcePath = Join-Path $root 'assets\sectors.psd1'
$demoSourcePath = Join-Path $root 'assets\demos.psd1'
$musicSourcePath = Join-Path $root 'assets\music.psd1'
$replayHarnessScript = Join-Path $PSScriptRoot 'replay-harness.ps1'
$balanceHarnessScript = Join-Path $PSScriptRoot 'balance-harness.ps1'
$regressionHarnessScript = Join-Path $PSScriptRoot 'regression-harness.ps1'
$gameObj = Join-Path $buildDir 'game.obj'
$bootObj = Join-Path $buildDir 'boot.obj'
$gameList = Join-Path $buildDir 'game.lst'
$bootList = Join-Path $buildDir 'boot.lst'
$bootConfig = Join-Path $buildDir 'boot_config.inc'
$debugConfig = Join-Path $buildDir 'debug_config.inc'
$generatedArtPath = Join-Path $buildDir 'generated_art.inc'
$generatedSectorContentPath = Join-Path $buildDir 'generated_sector_content.inc'
$generatedMapsPath = Join-Path $buildDir 'generated_maps.inc'
$generatedDemosPath = Join-Path $buildDir 'generated_demos.inc'
$generatedMusicPath = Join-Path $buildDir 'generated_music.inc'
$generatedBankLayoutPath = Join-Path $buildDir 'generated_bank_layout.inc'
$mapBankBinPath = Join-Path $buildDir 'cyberstorm-map-bank.bin'
$stage2BinPath = Join-Path $buildDir 'cyberstorm-stage2.bin'
$bootBinPath = Join-Path $buildDir 'cyberstorm-boot.bin'
$imgPath = Join-Path $buildDir 'cyberstorm.img'
$vfdPath = Join-Path $buildDir 'cyberstorm.vfd'
$reportPath = Join-Path $buildDir 'cyberstorm-build-report.txt'
$replayReportPath = Join-Path $buildDir 'cyberstorm-replay-report.txt'
$balanceReportPath = Join-Path $buildDir 'cyberstorm-balance-report.txt'
$regressionReportPath = Join-Path $buildDir 'cyberstorm-regression-report.txt'
$readmeScreenshotArtifacts = 1..$readmeScreenshotCount | ForEach-Object {
    Join-Path $buildDir ("{0}{1}.png" -f $readmeScreenshotPrefix, $_)
}

$seedProvided = $null -ne $DebugSeed
$startSectorProvided = $null -ne $DebugStartSector
$debugProfile = $DebugBuild.IsPresent -or $seedProvided -or $DebugOverlay.IsPresent -or $DebugStartInGame.IsPresent -or $startSectorProvided
$debugSeedValue = if ($seedProvided) { [int]$DebugSeed } else { 0xACE1 }
$debugStartSectorValue = if ($startSectorProvided) { [int]$DebugStartSector } else { 1 }
$debugConfigLines = @(
    '; generated by scripts/build.ps1'
    ("DEBUG_BUILD EQU {0}" -f ([int]$debugProfile))
    ("DEBUG_FORCE_SEED EQU {0}" -f ([int]$seedProvided))
    ("DEBUG_SEED_VALUE EQU {0}" -f (Format-Hex16Literal $debugSeedValue))
    ("DEBUG_OVERLAY EQU {0}" -f ([int]$DebugOverlay.IsPresent))
    ("DEBUG_START_IN_GAME EQU {0}" -f ([int]$DebugStartInGame.IsPresent))
    ("DEBUG_START_SECTOR EQU {0}" -f $debugStartSectorValue)
)
Set-Content -LiteralPath $debugConfig -Encoding ascii -Value $debugConfigLines
Assert-PathExists -Path $debugConfig -Label 'generated debug config'

$buildMode = if ($debugProfile) { 'debug' } else { 'release' }
$deterministicSeedText = if ($seedProvided) { (Format-Hex16 $debugSeedValue) } else { 'off' }
$overlayModeText = if ($DebugOverlay.IsPresent) { 'enabled' } else { 'off' }
$startModeText = if ($DebugStartInGame.IsPresent) { 'direct-to-game' } else { 'normal splash/title flow' }
$startSectorText = if ($startSectorProvided) { $debugStartSectorValue.ToString() } else { '1 (default)' }

Write-Section -Title 'Toolchain'
Write-Host ("Assembler: {0}" -f $assemblerTool.Name)
Write-Host ("Path     : {0}" -f $assemblerTool.Path)
Write-Host ("Discovery: {0}" -f $assemblerTool.Source)
if ($assemblerTool.Experimental) {
    Write-Host "Status   : experimental MASM-compatible path"
}
Write-Host ("Profile: {0}" -f $buildMode)
Write-Host ("Seed   : {0}" -f $deterministicSeedText)
Write-Host ("Overlay: {0}" -f $overlayModeText)
Write-Host ("Startup: {0}" -f $startModeText)
Write-Host ("Sector : {0}" -f $startSectorText)

$expectedMapWidth = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'MAP_W'
$expectedMapHeight = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'MAP_H'
$expectedSectorCount = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'TOTAL_SECTORS'

$generatedArt = Write-GeneratedArtInclude -SourcePath $artSourcePath -OutputPath $generatedArtPath
$generatedSectors = Write-GeneratedSectorIncludes `
    -SourcePath $sectorSourcePath `
    -SectorOutputPath $generatedSectorContentPath `
    -MapsOutputPath $generatedMapsPath `
    -ExpectedSectorCount $expectedSectorCount `
    -ExpectedMapWidth $expectedMapWidth `
    -ExpectedMapHeight $expectedMapHeight
$generatedDemos = Write-GeneratedDemoInclude `
    -SourcePath $demoSourcePath `
    -OutputPath $generatedDemosPath `
    -ExpectedSectorCount $expectedSectorCount
$generatedMusic = Write-GeneratedMusicInclude -SourcePath $musicSourcePath -OutputPath $generatedMusicPath
$mapBankLoadSegment = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'MAP_BANK_SEG'
[IO.File]::WriteAllBytes($mapBankBinPath, $generatedSectors.MapPayloadBytes)
Assert-PathExists -Path $mapBankBinPath -Label 'generated map bank payload'

Write-Section -Title 'Generated Assets'
Write-Host ("Source  : {0}" -f $generatedArt.SourcePath)
Write-Host ("Include : {0}" -f $generatedArt.OutputPath)
Write-Host ("Bitmaps : {0}" -f $generatedArt.AssetCount)
Write-Host ("Bytes   : {0}" -f $generatedArt.TotalBytes)
Write-Host ("Sizes   : {0}" -f $generatedArt.SizeSummary)

$generatedContentLines = @(
    ("Sector source: {0}" -f $generatedSectors.SourcePath)
    ("Sector include: {0}" -f $generatedSectors.SectorOutputPath)
    ("Maps include: {0}" -f $generatedSectors.MapsOutputPath)
    ("Sectors: {0}" -f $generatedSectors.SectorCount)
    ("Maps: {0} ({1} each, {2} bytes total)" -f $generatedSectors.MapCount, $generatedSectors.Geometry, $generatedSectors.MapBytes)
    ("Templates: {0}" -f $generatedSectors.TemplateSummary)
    ("Rules: {0}" -f $generatedSectors.RuleSummary)
    ("Demo source: {0}" -f $generatedDemos.SourcePath)
    ("Demo include: {0}" -f $generatedDemos.OutputPath)
    ("Demos: {0}" -f $generatedDemos.DemoCount)
    ("Demo steps: {0}" -f $generatedDemos.StepCount)
    ("Demo summary: {0}" -f $generatedDemos.DemoSummary)
    ("Music source: {0}" -f $generatedMusic.SourcePath)
    ("Music include: {0}" -f $generatedMusic.OutputPath)
    ("Themes: {0}" -f $generatedMusic.ThemeCount)
    ("Theme events: {0}" -f $generatedMusic.EventCount)
    ("Theme summary: {0}" -f $generatedMusic.ThemeSummary)
)

Write-Section -Title 'Generated Content'
foreach ($contentLine in $generatedContentLines) {
    Write-Host $contentLine
}

$replayHarness = & $replayHarnessScript `
    -SectorSourcePath $sectorSourcePath `
    -DemoSourcePath $demoSourcePath `
    -ConstantsSourcePath $constantsSourcePath `
    -ReportPath $replayReportPath
$replayHarnessLines = @(
    ("Report: {0}" -f $replayHarness.ReportPath)
    ("Scenarios: {0}" -f $replayHarness.ScenarioCount)
) + @($replayHarness.SummaryLines)

Write-Section -Title 'Replay Harness'
foreach ($replayLine in $replayHarnessLines) {
    Write-Host $replayLine
}

$balanceHarness = & $balanceHarnessScript `
    -SectorSourcePath $sectorSourcePath `
    -ConstantsSourcePath $constantsSourcePath `
    -ReportPath $balanceReportPath
$balanceHarnessLines = @(
    ("Report: {0}" -f $balanceHarness.ReportPath)
    ("Seeds: {0}" -f $balanceHarness.SeedSummary)
    ("Static maps: {0}" -f $balanceHarness.StaticMapCount)
    ("Scenarios: {0}" -f $balanceHarness.ScenarioCount)
) + @($balanceHarness.SummaryLines)

Write-Section -Title 'Balance Harness'
foreach ($balanceLine in $balanceHarnessLines) {
    Write-Host $balanceLine
}

$assetBanksBase = @(
    [pscustomobject]@{
        Name = 'Map bank'
        SymbolPrefix = 'MAP_BANK'
        SourcePath = $generatedSectors.SourcePath
        BinaryPath = $mapBankBinPath
        LoadSegment = $mapBankLoadSegment
        Bytes = $generatedSectors.MapBytes
    }
)

Write-Section -Title 'Stage Two'
$provisionalStage2Sectors = 0
$resolvedAssetBanks = @()
$stage2Resolved = $false
$gameBuild = $null
$gameFlat = $null
$gameBin = $null
$gameSectorCount = 0

for ($stage2Pass = 1; $stage2Pass -le 3; $stage2Pass++) {
    $resolvedAssetBanks = Resolve-AssetBankLayout -AssetBanks $assetBanksBase -Stage2Sectors $provisionalStage2Sectors -Layout $layout
    Write-GeneratedBankLayoutInclude -OutputPath $generatedBankLayoutPath -AssetBanks $resolvedAssetBanks

    if (@($resolvedAssetBanks).Count -gt 0) {
        Write-Host ("Pass {0} : assume {1} stage2 sectors, first bank at LBA {2}" -f $stage2Pass, $provisionalStage2Sectors, $resolvedAssetBanks[0].StartLba)
    } else {
        Write-Host ("Pass {0} : assume {1} stage2 sectors" -f $stage2Pass, $provisionalStage2Sectors)
    }

    $gameBuild = Invoke-Assembler -SourcePath $gameAsm -ObjectPath $gameObj -ListPath $gameList -IncludePaths @($buildDir) -ToolPath $assemblerTool.Path -AssemblerName $assemblerTool.Name
    $gameFlat = Get-CoffFlatBinary -ObjectPath $gameObj
    $gameBin = $gameFlat.FlatBytes
    $currentStage2Sectors = [int][Math]::Ceiling($gameBin.Length / $layout.BootSectorBytes)
    Validate-Stage2Layout -Stage2Bytes $gameBin.Length -Stage2Sectors $currentStage2Sectors -Layout $layout

    if ($currentStage2Sectors -eq $provisionalStage2Sectors) {
        $gameSectorCount = $currentStage2Sectors
        $stage2Resolved = $true
        break
    }

    $provisionalStage2Sectors = $currentStage2Sectors
}

if (-not $stage2Resolved) {
    throw "Stage-two bank metadata did not stabilize after 3 assembly passes. Check the generated bank layout include for a size-sensitive dependency."
}

$resolvedAssetBanks = Resolve-AssetBankLayout -AssetBanks $assetBanksBase -Stage2Sectors $gameSectorCount -Layout $layout
Write-GeneratedBankLayoutInclude -OutputPath $generatedBankLayoutPath -AssetBanks $resolvedAssetBanks
[IO.File]::WriteAllBytes($stage2BinPath, $gameBin)

$assetBankLines = @(
    ("Layout include: {0}" -f $generatedBankLayoutPath)
)
foreach ($assetBank in @($resolvedAssetBanks)) {
    $assetBankLines += ("{0}: {1} bytes ({2} padded), {3} sectors, LBA {4}..{5}, load {6}:0000, payload {7}" -f $assetBank.Name, $assetBank.Bytes, $assetBank.PaddedBytes, $assetBank.Sectors, $assetBank.StartLba, $assetBank.EndLba, (Format-Hex16 $assetBank.LoadSegment), $assetBank.BinaryPath)
}

Write-Section -Title 'Asset Banks'
foreach ($assetBankLine in $assetBankLines) {
    Write-Host $assetBankLine
}

Set-Content -LiteralPath $bootConfig -Encoding ascii -Value ("GAME_SECTORS EQU {0}" -f $gameSectorCount)
Assert-PathExists -Path $bootConfig -Label 'generated boot config'

Write-Section -Title 'Boot Sector'
$bootBuild = Invoke-Assembler -SourcePath $bootAsm -ObjectPath $bootObj -ListPath $bootList -IncludePaths @($buildDir) -ToolPath $assemblerTool.Path -AssemblerName $assemblerTool.Name
$bootFlat = Get-CoffFlatBinary -ObjectPath $bootObj
$bootBin = $bootFlat.FlatBytes

Validate-ImageLayout -BootBytes $bootBin.Length -Stage2Bytes $gameBin.Length -Stage2Sectors $gameSectorCount -AssetBanks $resolvedAssetBanks -Layout $layout

$bootSector = New-Object byte[] $layout.BootSectorBytes
[Array]::Copy($bootBin, 0, $bootSector, 0, $bootBin.Length)
$bootSector[510] = 0x55
$bootSector[511] = 0xAA

if ($bootSector[510] -ne 0x55 -or $bootSector[511] -ne 0xAA) {
    throw 'Boot signature validation failed before image write.'
}

[IO.File]::WriteAllBytes($bootBinPath, $bootSector)

$imageBytesUsed = $layout.BootSectorBytes + $gameBin.Length + ((@($resolvedAssetBanks) | Measure-Object -Property Bytes -Sum).Sum)
$stage2PaddedBytes = $gameSectorCount * $layout.BootSectorBytes
$diskFootprintBytes = $layout.BootSectorBytes + $stage2PaddedBytes + ((@($resolvedAssetBanks) | Measure-Object -Property PaddedBytes -Sum).Sum)
$warnings = Get-BuildWarnings -BootBytes $bootBin.Length -Stage2Bytes $gameBin.Length -Stage2Sectors $gameSectorCount -ImageBytesUsed $imageBytesUsed -DiskFootprintBytes $diskFootprintBytes -AssetBanks $resolvedAssetBanks -Layout $layout
if ($null -ne $replayHarness.WarningLines -and @($replayHarness.WarningLines).Count -gt 0) {
    $warnings = @($warnings) + @($replayHarness.WarningLines)
}
if ($null -ne $balanceHarness.WarningLines -and @($balanceHarness.WarningLines).Count -gt 0) {
    $warnings = @($warnings) + @($balanceHarness.WarningLines)
}

$floppy = New-Object byte[] $layout.FloppyBytes
[Array]::Copy($bootSector, 0, $floppy, 0, $bootSector.Length)
[Array]::Copy($gameBin, 0, $floppy, $layout.BootSectorBytes, $gameBin.Length)
foreach ($assetBank in @($resolvedAssetBanks)) {
    $assetBankBytes = [IO.File]::ReadAllBytes($assetBank.BinaryPath)
    [Array]::Copy($assetBankBytes, 0, $floppy, ($assetBank.StartLba * $layout.BootSectorBytes), $assetBankBytes.Length)
}

[IO.File]::WriteAllBytes($imgPath, $floppy)
[IO.File]::WriteAllBytes($vfdPath, $floppy)

if ((Get-Item -LiteralPath $imgPath).Length -ne $layout.FloppyBytes) {
    throw ("Image size mismatch after write: {0}" -f $imgPath)
}

if ((Get-Item -LiteralPath $vfdPath).Length -ne $layout.FloppyBytes) {
    throw ("Image size mismatch after write: {0}" -f $vfdPath)
}

$regressionHarness = & $regressionHarnessScript `
    -BootConfigPath $bootConfig `
    -BankLayoutPath $generatedBankLayoutPath `
    -BootBinaryPath $bootBinPath `
    -Stage2BinaryPath $stage2BinPath `
    -MapBankBinaryPath $mapBankBinPath `
    -ImagePath $imgPath `
    -VfdPath $vfdPath `
    -BootListPath $bootList `
    -GameListPath $gameList `
    -ReportPath $regressionReportPath
$regressionHarnessLines = @(
    ("Report: {0}" -f $regressionHarness.ReportPath)
) + @($regressionHarness.SummaryLines)
if ($null -ne $regressionHarness.WarningLines -and @($regressionHarness.WarningLines).Count -gt 0) {
    $warnings = @($warnings) + @($regressionHarness.WarningLines)
}

Write-Section -Title 'Regression Harness'
foreach ($regressionLine in $regressionHarnessLines) {
    Write-Host $regressionLine
}

$screenshotSync = Sync-ReadmeScreenshots -BuildDir $buildDir -PoolKeepCount $screenshotPoolKeepCount -ReadmeSlotCount $readmeScreenshotCount -ReadmeSlotPrefix $readmeScreenshotPrefix
$screenshotHousekeepingText = ("kept {0} source screenshots, removed {1}, rotated {2} README slots" -f $screenshotSync.SourceCount, $screenshotSync.RemovedCount, $readmeScreenshotCount)

$bootStartOffset = Get-SymbolValue -ObjectModel $bootFlat.ObjectModel -Names @('start', '_start')
$stageStartOffset = Get-SymbolValue -ObjectModel $gameFlat.ObjectModel -Names @('start', '_start')

Write-BuildReport `
    -ReportPath $reportPath `
    -AssemblerName $assemblerTool.Name `
    -ToolPath $assemblerTool.Path `
    -ToolSource $assemblerTool.Source `
    -BuildMode $buildMode `
    -DeterministicSeed $deterministicSeedText `
    -OverlayMode $overlayModeText `
    -StartMode $startModeText `
    -StartSector $startSectorText `
    -GeneratedArtSource $generatedArt.SourcePath `
    -GeneratedArtInclude $generatedArt.OutputPath `
    -GeneratedArtCount $generatedArt.AssetCount `
    -GeneratedArtBytes $generatedArt.TotalBytes `
    -GeneratedArtSizes $generatedArt.SizeSummary `
    -GeneratedContentLines $generatedContentLines `
    -ReplayHarnessLines $replayHarnessLines `
    -BalanceHarnessLines $balanceHarnessLines `
    -RegressionHarnessLines $regressionHarnessLines `
    -AssetBankLines $assetBankLines `
    -ScreenshotHousekeeping $screenshotHousekeepingText `
    -ReadmeScreenshotSlots $screenshotSync.ReadmeSlots `
    -BootBytes $bootBin.Length `
    -Stage2Bytes $gameBin.Length `
    -Stage2Sectors $gameSectorCount `
    -Stage2PaddedBytes $stage2PaddedBytes `
    -ImageBytesUsed $imageBytesUsed `
    -DiskFootprintBytes $diskFootprintBytes `
    -BootWarnings $bootBuild.WarningCount `
    -StageWarnings $gameBuild.WarningCount `
    -BootRelocations $bootFlat.AppliedRelocations `
    -StageRelocations $gameFlat.AppliedRelocations `
    -BootSectionName $bootFlat.TargetSection.Name `
    -StageSectionName $gameFlat.TargetSection.Name `
    -BootStartOffset $bootStartOffset `
    -StageStartOffset $stageStartOffset `
    -Warnings $warnings `
    -ArtifactPaths @($generatedArtPath, $generatedSectorContentPath, $generatedMapsPath, $generatedDemosPath, $generatedMusicPath, $replayReportPath, $balanceReportPath, $regressionReportPath, $generatedBankLayoutPath, $mapBankBinPath, $bootBinPath, $stage2BinPath, $bootList, $gameList, $bootConfig, $debugConfig, $imgPath, $vfdPath) + $readmeScreenshotArtifacts + @($reportPath, $screenshotSync.RotationStatePath) `
    -Layout $layout

Write-Section -Title 'Artifacts'
Write-Host ("Built {0}" -f $imgPath)
Write-Host ("Built {0}" -f $vfdPath)
Write-Host ("Art     {0}" -f $generatedArtPath)
Write-Host ("Rules   {0}" -f $generatedSectorContentPath)
Write-Host ("Maps    {0}" -f $generatedMapsPath)
Write-Host ("Demos   {0}" -f $generatedDemosPath)
Write-Host ("Music   {0}" -f $generatedMusicPath)
Write-Host ("Replay  {0}" -f $replayReportPath)
Write-Host ("Balance {0}" -f $balanceReportPath)
Write-Host ("Regress {0}" -f $regressionReportPath)
Write-Host ("Banks   {0}" -f $generatedBankLayoutPath)
Write-Host ("Bank    {0}" -f $mapBankBinPath)
foreach ($readmeShot in $readmeScreenshotArtifacts) {
    Write-Host ("Shot    {0}" -f $readmeShot)
}
Write-Host ("Listing {0}" -f $bootList)
Write-Host ("Listing {0}" -f $gameList)
Write-Host ("Config  {0}" -f $debugConfig)
Write-Host ("Report  {0}" -f $reportPath)

Write-Section -Title 'Screenshots'
Write-Host ("Policy  : keep newest {0} source screenshots + {1} rotating README slots" -f $screenshotPoolKeepCount, $readmeScreenshotCount)
Write-Host ("Status  : {0}" -f $screenshotHousekeepingText)
if (@($screenshotSync.ReadmeSlots).Count -gt 0) {
    foreach ($slotLine in @($screenshotSync.ReadmeSlots)) {
        Write-Host ("README  : {0}" -f $slotLine)
    }
}

Write-Section -Title 'Layout Summary'
Write-Host ("Boot code : {0} bytes ({1} bytes free)" -f $bootBin.Length, ($layout.BootCodeLimitBytes - $bootBin.Length))
Write-Host ("Stage2    : {0} bytes ({1} bytes free), {2} sectors, padded to {3} bytes" -f $gameBin.Length, ($layout.Stage2LoadLimitBytes - $gameBin.Length), $gameSectorCount, $stage2PaddedBytes)
Write-Host ("Image     : {0} / {1} bytes used ({2} bytes free)" -f $imageBytesUsed, $layout.FloppyBytes, ($layout.FloppyBytes - $imageBytesUsed))
Write-Host ("Disk use  : {0} / {1} bytes of occupied sectors ({2} bytes free)" -f $diskFootprintBytes, $layout.FloppyBytes, ($layout.FloppyBytes - $diskFootprintBytes))
Write-Host ("Boot load : 0000:7C00 (phys {0})" -f (Format-Hex32 (Get-PhysicalAddress -Segment 0 -Offset 0x7C00)))
Write-Host ("Stage2    : {0}:{1} (phys {2})" -f (Format-Hex16 $layout.Stage2LoadSegment), (Format-Hex16 $layout.Stage2LoadOffset), (Format-Hex32 (Get-PhysicalAddress -Segment $layout.Stage2LoadSegment -Offset $layout.Stage2LoadOffset)))
Write-Host ("Stage2 LBA: {0}..{1}" -f $layout.Stage2StartLba, ($layout.Stage2StartLba + $gameSectorCount - 1))
foreach ($assetBank in @($resolvedAssetBanks)) {
    Write-Host ("{0,-10}: {1} bytes, {2} sectors, LBA {3}..{4}, load {5}:0000" -f $assetBank.Name, $assetBank.Bytes, $assetBank.Sectors, $assetBank.StartLba, $assetBank.EndLba, (Format-Hex16 $assetBank.LoadSegment))
}
Write-Host ("Signature : 0x55AA @ byte 510")
Write-Host ("Warnings  : boot={0}, stage2={1}" -f $bootBuild.WarningCount, $gameBuild.WarningCount)

if ($bootStartOffset -ne $null) {
    Write-Host ("Boot start symbol : {0}" -f (Format-Hex16 $bootStartOffset))
}

if ($stageStartOffset -ne $null) {
    Write-Host ("Stage2 start symbol: {0}" -f (Format-Hex16 $stageStartOffset))
}

if (@($warnings).Count -gt 0) {
    Write-Section -Title 'Warnings'
    foreach ($warning in @($warnings)) {
        Write-Warning $warning
    }
}
