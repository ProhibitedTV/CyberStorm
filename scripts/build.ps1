param(
    [ValidateSet('masm', 'uasm', 'jwasm')]
    [string]$Assembler = 'masm',
    [string]$AssemblerPath,
    [string]$MasmPath,
    [switch]$ExperimentalMusic,
    [switch]$SfxOnly,
    [switch]$FrontendVerify,
    [switch]$VmSmoke,
    [switch]$RuntimeVerify,
    [switch]$CaptureShowcase,
    [switch]$DebugBuild,
    [Nullable[int]]$DebugSeed,
    [switch]$DebugOverlay,
    [switch]$DebugStartInGame,
    [Nullable[int]]$DebugStartSector,
    [switch]$AutomationChild,
    [switch]$DebugDemoBoot,
    [Nullable[int]]$DebugDemoIndex,
    [switch]$DebugFrontendVerify,
    [Nullable[int]]$DebugFrontendScenario,
    [switch]$DebugRuntimeVerify,
    [Nullable[int]]$DebugVerifyCorruptDemoIndex,
    [Nullable[int]]$DebugFrontendCorruptScenario,
    [switch]$DebugRender2D,
    [switch]$DebugRender3D,
    [switch]$DebugRenderReference,
    [switch]$DebugRenderMachine,
    [ValidateRange(0, 5)]
    [Nullable[int]]$DebugRenderStage
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($ExperimentalMusic.IsPresent -and $SfxOnly.IsPresent) {
    throw 'Use either -ExperimentalMusic (legacy alias) or -SfxOnly, not both.'
}

$musicEnabled = -not $SfxOnly.IsPresent

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
    $token = ("{0:X4}" -f ($Value -band 0xFFFF))
    if ($token -match '^[A-F]') {
        return ("0{0}h" -f $token)
    }

    return ("{0}h" -f $token)
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

function Get-MapRowChar {
    param(
        [string[]]$Rows,
        [int]$X,
        [int]$Y
    )

    return ([string]$Rows[$Y])[$X]
}

function ConvertTo-AnchorPoint {
    param(
        [string]$Token,
        [string]$Context,
        [int]$MapWidth,
        [int]$MapHeight
    )

    if ([string]::IsNullOrWhiteSpace($Token) -or $Token -notmatch '^\s*(\d+)\s*,\s*(\d+)\s*$') {
        throw ("{0} must use 'x,y' coordinates inside the playable bounds. Received: '{1}'." -f $Context, $Token)
    }

    $x = [int]$Matches[1]
    $y = [int]$Matches[2]
    if ($x -lt 1 -or $x -gt ($MapWidth - 2) -or $y -lt 1 -or $y -gt ($MapHeight - 2)) {
        throw ("{0} coordinate ({1},{2}) is outside the playable bounds 1..{3}, 1..{4}." -f $Context, $x, $y, ($MapWidth - 2), ($MapHeight - 2))
    }

    return [pscustomobject]@{
        X = $x
        Y = $y
    }
}

function Write-GeneratedSectorIncludes {
    param(
        [string]$SourcePath,
        [string]$SectorOutputPath,
        [string]$MapsOutputPath,
        [int]$ExpectedSectorCount,
        [int]$ExpectedMapWidth,
        [int]$ExpectedMapHeight,
        [int]$ExpectedShardPoolCount,
        [int]$StartX,
        [int]$StartY,
        [int]$ExitX,
        [int]$ExitY,
        [int]$SafeXMax,
        [int]$SafeYMin,
        [int]$EnemySpawnStep,
        [int]$EnemySpawnBase,
        [int]$MaxEnemies
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
    $scenarioNameRefs = New-Object 'System.Collections.Generic.List[string]'
    $scenarioEntryRefs = New-Object 'System.Collections.Generic.List[string]'
    $surgeCounts = New-Object 'System.Collections.Generic.List[string]'
    $terminalCounts = New-Object 'System.Collections.Generic.List[string]'
    $enemyBonuses = New-Object 'System.Collections.Generic.List[string]'
    $flankerThresholds = New-Object 'System.Collections.Generic.List[string]'
    $wardenThresholds = New-Object 'System.Collections.Generic.List[string]'
    $wardenDistances = New-Object 'System.Collections.Generic.List[string]'
    $templateSummary = New-Object 'System.Collections.Generic.List[string]'
    $ruleSummary = New-Object 'System.Collections.Generic.List[string]'
    $anchorSummary = New-Object 'System.Collections.Generic.List[string]'
    $scenarioSummary = New-Object 'System.Collections.Generic.List[string]'
    $shardPoolSummary = New-Object 'System.Collections.Generic.List[string]'
    $templateTerminalOffsets = New-Object 'System.Collections.Generic.List[string]'
    $templateTerminalAnchorCounts = New-Object 'System.Collections.Generic.List[string]'
    $templateSurgeOffsets = New-Object 'System.Collections.Generic.List[string]'
    $templateSurgeAnchorCounts = New-Object 'System.Collections.Generic.List[string]'
    $templateEnemyOffsets = New-Object 'System.Collections.Generic.List[string]'
    $templateEnemyAnchorCounts = New-Object 'System.Collections.Generic.List[string]'
    $templateShardPoolOffsets = New-Object 'System.Collections.Generic.List[string]'
    $templateShardPoolCounts = New-Object 'System.Collections.Generic.List[string]'
    $seenMapNames = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    $mapPayloadBytes = New-Object 'System.Collections.Generic.List[byte]'
    $terminalAnchorBytes = New-Object 'System.Collections.Generic.List[byte]'
    $surgeAnchorBytes = New-Object 'System.Collections.Generic.List[byte]'
    $enemyAnchorBytes = New-Object 'System.Collections.Generic.List[byte]'
    $shardPoolBytes = New-Object 'System.Collections.Generic.List[byte]'
    $mapScenarioRecords = New-Object 'System.Collections.Generic.List[object]'
    $enemyKindLookup = @{
        RUSHER = 0
        FLANKER = 1
        WARDEN = 2
    }

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
        $sectorEnemyCount = ($sectorId * $EnemySpawnStep) + $EnemySpawnBase + $enemyBonus
        if ($sectorEnemyCount -gt $MaxEnemies) {
            throw ("Sector {0} enemy budget ({1}) exceeds MAX_ENEMIES ({2})." -f $sectorId, $sectorEnemyCount, $MaxEnemies)
        }

        $sectorLabel = ("sector{0}" -f $sectorId)
        $nameRefs.Add(("offset {0}_name" -f $sectorLabel))
        $introRefs.Add(("offset {0}_intro" -f $sectorLabel))
        $sectorAnchorParts = New-Object 'System.Collections.Generic.List[string]'
        $sectorScenarioParts = New-Object 'System.Collections.Generic.List[string]'
        $sectorShardPoolParts = New-Object 'System.Collections.Generic.List[string]'

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

            $anchors = @{}
            if ($map.ContainsKey('Anchors')) {
                $anchors = $map['Anchors']
                if (-not ($anchors -is [System.Collections.IDictionary])) {
                    throw ("Map '{0}' anchors in {1} must be a hashtable." -f $mapName, $SourcePath)
                }
            }

            $occupiedAnchors = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
            $terminalAnchors = New-Object 'System.Collections.Generic.List[object]'
            $surgeAnchors = New-Object 'System.Collections.Generic.List[object]'
            $enemyAnchors = New-Object 'System.Collections.Generic.List[object]'

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

            $terminalEntries = @()
            if ($anchors.ContainsKey('Terminals')) { $terminalEntries += @($anchors['Terminals']) }
            $surgeEntries = @()
            if ($anchors.ContainsKey('Surges')) { $surgeEntries += @($anchors['Surges']) }
            $enemyEntries = @()
            if ($anchors.ContainsKey('Enemies')) { $enemyEntries += @($anchors['Enemies']) }

            if ($terminalEntries.Count -gt $terminalCount) {
                throw ("Map '{0}' in sector {1} defines {2} terminal anchors, but the sector budget is {3}." -f $mapName, $sectorId, $terminalEntries.Count, $terminalCount)
            }

            if ($surgeEntries.Count -gt $surgeCount) {
                throw ("Map '{0}' in sector {1} defines {2} surge anchors, but the sector budget is {3}." -f $mapName, $sectorId, $surgeEntries.Count, $surgeCount)
            }

            if ($enemyEntries.Count -gt $sectorEnemyCount) {
                throw ("Map '{0}' in sector {1} defines {2} enemy anchors, but the sector budget is {3}." -f $mapName, $sectorId, $enemyEntries.Count, $sectorEnemyCount)
            }

            foreach ($token in $terminalEntries) {
                $anchor = ConvertTo-AnchorPoint -Token ([string]$token) -Context ("Terminal anchor in {0}" -f $mapName) -MapWidth $ExpectedMapWidth -MapHeight $ExpectedMapHeight
                if ((Get-MapRowChar -Rows $rows -X $anchor.X -Y $anchor.Y) -eq '#') {
                    throw ("Terminal anchor ({0},{1}) in map '{2}' must sit on a floor tile." -f $anchor.X, $anchor.Y, $mapName)
                }

                if (($anchor.X -eq $StartX -and $anchor.Y -eq $StartY) -or ($anchor.X -eq $ExitX -and $anchor.Y -eq $ExitY)) {
                    throw ("Terminal anchor ({0},{1}) in map '{2}' cannot sit on the start or exit tile." -f $anchor.X, $anchor.Y, $mapName)
                }

                $anchorKey = ("{0},{1}" -f $anchor.X, $anchor.Y)
                if (-not $occupiedAnchors.Add($anchorKey)) {
                    throw ("Map '{0}' defines multiple anchors on tile ({1},{2})." -f $mapName, $anchor.X, $anchor.Y)
                }

                $terminalAnchors.Add($anchor)
            }

            foreach ($token in $surgeEntries) {
                $anchor = ConvertTo-AnchorPoint -Token ([string]$token) -Context ("Surge anchor in {0}" -f $mapName) -MapWidth $ExpectedMapWidth -MapHeight $ExpectedMapHeight
                if ((Get-MapRowChar -Rows $rows -X $anchor.X -Y $anchor.Y) -eq '#') {
                    throw ("Surge anchor ({0},{1}) in map '{2}' must sit on a floor tile." -f $anchor.X, $anchor.Y, $mapName)
                }

                if (($anchor.X -eq $StartX -and $anchor.Y -eq $StartY) -or ($anchor.X -eq $ExitX -and $anchor.Y -eq $ExitY)) {
                    throw ("Surge anchor ({0},{1}) in map '{2}' cannot sit on the start or exit tile." -f $anchor.X, $anchor.Y, $mapName)
                }

                $anchorKey = ("{0},{1}" -f $anchor.X, $anchor.Y)
                if (-not $occupiedAnchors.Add($anchorKey)) {
                    throw ("Map '{0}' defines multiple anchors on tile ({1},{2})." -f $mapName, $anchor.X, $anchor.Y)
                }

                $surgeAnchors.Add($anchor)
            }

            foreach ($enemyEntry in $enemyEntries) {
                if (-not ($enemyEntry -is [System.Collections.IDictionary])) {
                    throw ("Enemy anchors in map '{0}' must be hashtables with X, Y, and Kind." -f $mapName)
                }

                foreach ($requiredKey in @('X', 'Y', 'Kind')) {
                    if (-not $enemyEntry.ContainsKey($requiredKey)) {
                        throw ("Enemy anchor in map '{0}' is missing '{1}'." -f $mapName, $requiredKey)
                    }
                }

                $x = [int]$enemyEntry['X']
                $y = [int]$enemyEntry['Y']
                $kindToken = ([string]$enemyEntry['Kind']).Trim().ToUpperInvariant()
                if ($x -lt 1 -or $x -gt ($ExpectedMapWidth - 2) -or $y -lt 1 -or $y -gt ($ExpectedMapHeight - 2)) {
                    throw ("Enemy anchor ({0},{1}) in map '{2}' is outside the playable bounds 1..{3}, 1..{4}." -f $x, $y, $mapName, ($ExpectedMapWidth - 2), ($ExpectedMapHeight - 2))
                }

                if ((Get-MapRowChar -Rows $rows -X $x -Y $y) -eq '#') {
                    throw ("Enemy anchor ({0},{1}) in map '{2}' must sit on a floor tile." -f $x, $y, $mapName)
                }

                if (($x -eq $StartX -and $y -eq $StartY) -or ($x -eq $ExitX -and $y -eq $ExitY)) {
                    throw ("Enemy anchor ({0},{1}) in map '{2}' cannot sit on the start or exit tile." -f $x, $y, $mapName)
                }

                if ($x -le $SafeXMax -and $y -ge $SafeYMin) {
                    throw ("Enemy anchor ({0},{1}) in map '{2}' violates the enemy safe-zone contract." -f $x, $y, $mapName)
                }

                if (-not $enemyKindLookup.ContainsKey($kindToken)) {
                    throw ("Enemy anchor ({0},{1}) in map '{2}' used unsupported Kind '{3}'." -f $x, $y, $mapName, $enemyEntry['Kind'])
                }

                $anchorKey = ("{0},{1}" -f $x, $y)
                if (-not $occupiedAnchors.Add($anchorKey)) {
                    throw ("Map '{0}' defines multiple anchors on tile ({1},{2})." -f $mapName, $x, $y)
                }

                $enemyAnchors.Add([pscustomobject]@{
                    X = $x
                    Y = $y
                    Kind = $kindToken
                    KindValue = [int]$enemyKindLookup[$kindToken]
                })
            }

            if (-not $map.ContainsKey('Scenario')) {
                throw ("Map '{0}' in {1} is missing its Scenario block." -f $mapName, $SourcePath)
            }

            $scenario = $map['Scenario']
            if (-not ($scenario -is [System.Collections.IDictionary])) {
                throw ("Map '{0}' scenario in {1} must be a hashtable." -f $mapName, $SourcePath)
            }

            foreach ($requiredScenarioKey in @('Name', 'Entry', 'ShardPool')) {
                if (-not $scenario.ContainsKey($requiredScenarioKey)) {
                    throw ("Map '{0}' scenario in {1} is missing '{2}'." -f $mapName, $SourcePath, $requiredScenarioKey)
                }
            }

            $scenarioName = [string]$scenario['Name']
            $scenarioEntry = [string]$scenario['Entry']
            if ([string]::IsNullOrWhiteSpace($scenarioName)) {
                throw ("Map '{0}' scenario in {1} must define a non-empty Name." -f $mapName, $SourcePath)
            }

            if ([string]::IsNullOrWhiteSpace($scenarioEntry)) {
                throw ("Map '{0}' scenario in {1} must define a non-empty Entry." -f $mapName, $SourcePath)
            }

            $shardPoolEntries = @($scenario['ShardPool'])
            if ($shardPoolEntries.Count -ne $ExpectedShardPoolCount) {
                throw ("Map '{0}' scenario in {1} must define exactly {2} shard-pool coordinates. Received: {3}" -f $mapName, $SourcePath, $ExpectedShardPoolCount, $shardPoolEntries.Count)
            }

            $shardPoolAnchors = New-Object 'System.Collections.Generic.List[object]'
            $seenShardPoolTiles = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
            $shardMinX = [int]::MaxValue
            $shardMaxX = 0
            $shardMinY = [int]::MaxValue
            $shardMaxY = 0

            foreach ($token in $shardPoolEntries) {
                $point = ConvertTo-AnchorPoint -Token ([string]$token) -Context ("Shard pool in {0}" -f $mapName) -MapWidth $ExpectedMapWidth -MapHeight $ExpectedMapHeight
                if ((Get-MapRowChar -Rows $rows -X $point.X -Y $point.Y) -eq '#') {
                    throw ("Shard-pool coordinate ({0},{1}) in map '{2}' must sit on a floor tile." -f $point.X, $point.Y, $mapName)
                }

                if (($point.X -eq $StartX -and $point.Y -eq $StartY) -or ($point.X -eq $ExitX -and $point.Y -eq $ExitY)) {
                    throw ("Shard-pool coordinate ({0},{1}) in map '{2}' cannot sit on the start or exit tile." -f $point.X, $point.Y, $mapName)
                }

                $pointKey = ("{0},{1}" -f $point.X, $point.Y)
                if ($occupiedAnchors.Contains($pointKey)) {
                    throw ("Shard-pool coordinate ({0},{1}) in map '{2}' overlaps an authored anchor tile." -f $point.X, $point.Y, $mapName)
                }

                if (-not $seenShardPoolTiles.Add($pointKey)) {
                    throw ("Map '{0}' scenario defines duplicate shard-pool tile ({1},{2})." -f $mapName, $point.X, $point.Y)
                }

                $shardMinX = [Math]::Min($shardMinX, $point.X)
                $shardMaxX = [Math]::Max($shardMaxX, $point.X)
                $shardMinY = [Math]::Min($shardMinY, $point.Y)
                $shardMaxY = [Math]::Max($shardMaxY, $point.Y)
                $shardPoolAnchors.Add($point)
            }

            $templateTerminalOffsets.Add($terminalAnchorBytes.Count.ToString())
            $templateTerminalAnchorCounts.Add($terminalAnchors.Count.ToString())
            foreach ($anchor in $terminalAnchors) {
                $terminalAnchorBytes.Add([byte]$anchor.X)
                $terminalAnchorBytes.Add([byte]$anchor.Y)
            }

            $templateSurgeOffsets.Add($surgeAnchorBytes.Count.ToString())
            $templateSurgeAnchorCounts.Add($surgeAnchors.Count.ToString())
            foreach ($anchor in $surgeAnchors) {
                $surgeAnchorBytes.Add([byte]$anchor.X)
                $surgeAnchorBytes.Add([byte]$anchor.Y)
            }

            $templateEnemyOffsets.Add($enemyAnchorBytes.Count.ToString())
            $templateEnemyAnchorCounts.Add($enemyAnchors.Count.ToString())
            foreach ($anchor in $enemyAnchors) {
                $enemyAnchorBytes.Add([byte]$anchor.X)
                $enemyAnchorBytes.Add([byte]$anchor.Y)
                $enemyAnchorBytes.Add([byte]$anchor.KindValue)
            }

            $scenarioNameRefs.Add(("offset {0}_scenario_name" -f $mapName))
            $scenarioEntryRefs.Add(("offset {0}_scenario_entry" -f $mapName))
            $templateShardPoolOffsets.Add($shardPoolBytes.Count.ToString())
            $templateShardPoolCounts.Add($shardPoolAnchors.Count.ToString())
            foreach ($point in $shardPoolAnchors) {
                $shardPoolBytes.Add([byte]$point.X)
                $shardPoolBytes.Add([byte]$point.Y)
            }

            $mapScenarioRecords.Add([pscustomobject]@{
                MapName = $mapName
                ScenarioName = $scenarioName
                ScenarioEntry = $scenarioEntry
            })

            $mapLines.Add('')
            $mapCount += 1
            $mapBytes += ($ExpectedMapWidth * $ExpectedMapHeight)
            $sectorAnchorParts.Add(("{0}(T{1}/S{2}/E{3})" -f $mapName, $terminalAnchors.Count, $surgeAnchors.Count, $enemyAnchors.Count))
            $sectorScenarioParts.Add(("{0}={1}" -f $mapName, $scenarioName))
            $sectorShardPoolParts.Add(("{0}({1}:{2}x{3})" -f $mapName, $shardPoolAnchors.Count, ($shardMaxX - $shardMinX + 1), ($shardMaxY - $shardMinY + 1)))
        }

        $anchorSummary.Add(("S{0}: {1}" -f $sectorId, ($sectorAnchorParts -join ', ')))
        $scenarioSummary.Add(("S{0}: {1}" -f $sectorId, ($sectorScenarioParts -join ', ')))
        $shardPoolSummary.Add(("S{0}: {1}" -f $sectorId, ($sectorShardPoolParts -join ', ')))
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
    Add-AsmDataLines -Lines $sectorLines -Label 'template_terminal_anchor_offset' -Directive 'dw' -Values $templateTerminalOffsets.ToArray() -ValuesPerLine 6
    Add-AsmDataLines -Lines $sectorLines -Label 'template_terminal_anchor_count' -Directive 'db' -Values $templateTerminalAnchorCounts.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $sectorLines -Label 'template_surge_anchor_offset' -Directive 'dw' -Values $templateSurgeOffsets.ToArray() -ValuesPerLine 6
    Add-AsmDataLines -Lines $sectorLines -Label 'template_surge_anchor_count' -Directive 'db' -Values $templateSurgeAnchorCounts.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $sectorLines -Label 'template_enemy_anchor_offset' -Directive 'dw' -Values $templateEnemyOffsets.ToArray() -ValuesPerLine 6
    Add-AsmDataLines -Lines $sectorLines -Label 'template_enemy_anchor_count' -Directive 'db' -Values $templateEnemyAnchorCounts.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $sectorLines -Label 'template_scenario_name_table' -Directive 'dw' -Values $scenarioNameRefs.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $sectorLines -Label 'template_scenario_entry_table' -Directive 'dw' -Values $scenarioEntryRefs.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $sectorLines -Label 'template_shard_pool_offset' -Directive 'dw' -Values $templateShardPoolOffsets.ToArray() -ValuesPerLine 6
    Add-AsmDataLines -Lines $sectorLines -Label 'template_shard_pool_count' -Directive 'db' -Values $templateShardPoolCounts.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $sectorLines -Label 'sector_name_table' -Directive 'dw' -Values $nameRefs.ToArray() -ValuesPerLine 3
    Add-AsmDataLines -Lines $sectorLines -Label 'sector_intro_table' -Directive 'dw' -Values $introRefs.ToArray() -ValuesPerLine 3
    $sectorLines.Add('')
    Add-AsmDataLines -Lines $sectorLines -Label 'terminal_anchor_table' -Directive 'db' -Values (@($terminalAnchorBytes | ForEach-Object { $_.ToString() })) -ValuesPerLine 10
    Add-AsmDataLines -Lines $sectorLines -Label 'surge_anchor_table' -Directive 'db' -Values (@($surgeAnchorBytes | ForEach-Object { $_.ToString() })) -ValuesPerLine 10
    Add-AsmDataLines -Lines $sectorLines -Label 'enemy_anchor_table' -Directive 'db' -Values (@($enemyAnchorBytes | ForEach-Object { $_.ToString() })) -ValuesPerLine 12
    Add-AsmDataLines -Lines $sectorLines -Label 'shard_pool_table' -Directive 'db' -Values (@($shardPoolBytes | ForEach-Object { $_.ToString() })) -ValuesPerLine 10
    $sectorLines.Add('')

    foreach ($record in $mapScenarioRecords) {
        $sectorLines.Add(("{0}_scenario_name db {1}, 0" -f $record.MapName, (ConvertTo-AsmStringLiteral -Value ([string]$record.ScenarioName) -Context ("scenario name for {0}" -f $record.MapName))))
        $sectorLines.Add(("{0}_scenario_entry db {1}, 0" -f $record.MapName, (ConvertTo-AsmStringLiteral -Value ([string]$record.ScenarioEntry) -Context ("scenario entry for {0}" -f $record.MapName))))
    }

    if ($mapScenarioRecords.Count -gt 0) {
        $sectorLines.Add('')
    }

    foreach ($sector in $sectors) {
        $sectorId = [int]$sector['Id']
        $sectorLabel = ("sector{0}" -f $sectorId)
        $sectorLines.Add(("{0}_name db {1}, 0" -f $sectorLabel, (ConvertTo-AsmStringLiteral -Value ([string]$sector['Title']) -Context ("sector {0} title" -f $sectorId))))
        $sectorLines.Add(("{0}_intro db {1}, 0" -f $sectorLabel, (ConvertTo-AsmStringLiteral -Value ([string]$sector['Intro']) -Context ("sector {0} intro" -f $sectorId))))
    }

    if ($contentData.ContainsKey('AdventureRealm')) {
        $adventureRealm = $contentData['AdventureRealm']
        if (-not ($adventureRealm -is [System.Collections.IDictionary])) {
            throw ("AdventureRealm in {0} must be a hashtable." -f $SourcePath)
        }

        foreach ($requiredAdventureKey in @('Title', 'Intro', 'Start', 'Portal', 'RequiredGems', 'Key', 'Rows', 'MacroZones', 'RouteBeats', 'CaptureAnchors')) {
            if (-not $adventureRealm.ContainsKey($requiredAdventureKey)) {
                throw ("AdventureRealm in {0} is missing '{1}'." -f $SourcePath, $requiredAdventureKey)
            }
        }

        $adventureTitle = [string]$adventureRealm['Title']
        $adventureIntro = [string]$adventureRealm['Intro']
        $adventureRequiredGems = [int]$adventureRealm['RequiredGems']
        $adventureRows = @($adventureRealm['Rows'] | ForEach-Object { [string]$_ })
        $adventureMacroZones = @($adventureRealm['MacroZones'])
        $adventureRouteBeats = @($adventureRealm['RouteBeats'])
        $adventureCaptureAnchors = $adventureRealm['CaptureAnchors']
        if ($adventureRows.Count -ne $ExpectedMapHeight) {
            throw ("AdventureRealm in {0} must define exactly {1} rows." -f $SourcePath, $ExpectedMapHeight)
        }
        if ($adventureRequiredGems -lt 0 -or $adventureRequiredGems -gt 255) {
            throw ("AdventureRealm.RequiredGems in {0} must stay in the 0..255 range. Found {1}." -f $SourcePath, $adventureRequiredGems)
        }
        if ($adventureMacroZones.Count -eq 0) {
            throw ("AdventureRealm in {0} must define at least one MacroZones entry." -f $SourcePath)
        }
        if ($adventureRouteBeats.Count -eq 0) {
            throw ("AdventureRealm in {0} must define at least one RouteBeats entry." -f $SourcePath)
        }
        if (-not ($adventureCaptureAnchors -is [System.Collections.IDictionary])) {
            throw ("AdventureRealm.CaptureAnchors in {0} must be a hashtable." -f $SourcePath)
        }

        $adventureMacroZoneSummary = New-Object 'System.Collections.Generic.List[string]'
        $adventureRouteBeatSummary = New-Object 'System.Collections.Generic.List[string]'
        $adventureZoneIds = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($zoneEntry in $adventureMacroZones) {
            if (-not ($zoneEntry -is [System.Collections.IDictionary])) {
                throw ("AdventureRealm.MacroZones in {0} must be hashtables with Id and Label." -f $SourcePath)
            }

            $zoneId = ([string]$zoneEntry['Id']).Trim()
            $zoneLabel = ([string]$zoneEntry['Label']).Trim()
            $zoneBounds = if ($zoneEntry.ContainsKey('Bounds')) { ([string]$zoneEntry['Bounds']).Trim() } else { '' }
            if ([string]::IsNullOrWhiteSpace($zoneId) -or $zoneId -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') {
                throw ("AdventureRealm.MacroZones in {0} must use lowercase slug Id values. Found '{1}'." -f $SourcePath, $zoneEntry['Id'])
            }
            if ([string]::IsNullOrWhiteSpace($zoneLabel)) {
                throw ("AdventureRealm.MacroZones entry '{0}' in {1} is missing Label." -f $zoneId, $SourcePath)
            }
            if (-not $adventureZoneIds.Add($zoneId)) {
                throw ("AdventureRealm.MacroZones in {0} reused Id '{1}'." -f $SourcePath, $zoneId)
            }

            if ([string]::IsNullOrWhiteSpace($zoneBounds)) {
                $adventureMacroZoneSummary.Add(("{0} ({1})" -f $zoneId, $zoneLabel))
            } else {
                $adventureMacroZoneSummary.Add(("{0} ({1}, {2})" -f $zoneId, $zoneLabel, $zoneBounds))
            }
        }

        foreach ($beatEntry in @($adventureRouteBeats | Sort-Object -Property @{ Expression = { [int]$_.Sequence }; Ascending = $true })) {
            if (-not ($beatEntry -is [System.Collections.IDictionary])) {
                throw ("AdventureRealm.RouteBeats in {0} must be hashtables with Zone, Sequence, and Summary." -f $SourcePath)
            }

            $zoneId = ([string]$beatEntry['Zone']).Trim()
            $sequence = [int]$beatEntry['Sequence']
            $summary = ([string]$beatEntry['Summary']).Trim()
            if (-not $adventureZoneIds.Contains($zoneId)) {
                throw ("AdventureRealm.RouteBeats in {0} referenced unknown zone '{1}'." -f $SourcePath, $zoneId)
            }
            if ($sequence -lt 1 -or $sequence -gt 255) {
                throw ("AdventureRealm.RouteBeats in {0} must use Sequence values in the 1..255 range. Found {1}." -f $SourcePath, $sequence)
            }
            if ([string]::IsNullOrWhiteSpace($summary)) {
                throw ("AdventureRealm.RouteBeats in {0} is missing Summary for zone '{1}'." -f $SourcePath, $zoneId)
            }

            $adventureRouteBeatSummary.Add(("#{0} {1}: {2}" -f $sequence, $zoneId, $summary))
        }

        foreach ($captureKey in @('Beauty', 'Action')) {
            if (-not $adventureCaptureAnchors.ContainsKey($captureKey)) {
                throw ("AdventureRealm.CaptureAnchors in {0} is missing '{1}'." -f $SourcePath, $captureKey)
            }

            $captureId = ([string]$adventureCaptureAnchors[$captureKey]).Trim()
            if ([string]::IsNullOrWhiteSpace($captureId) -or $captureId -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') {
                throw ("AdventureRealm.CaptureAnchors.{0} in {1} must reference a lowercase demo Id. Found '{2}'." -f $captureKey, $SourcePath, $adventureCaptureAnchors[$captureKey])
            }
        }
        $adventureCaptureSummary = ("beauty={0}, action={1}" -f ([string]$adventureCaptureAnchors['Beauty']).Trim(), ([string]$adventureCaptureAnchors['Action']).Trim())

        $adventureStart = ConvertTo-AnchorPoint -Token ([string]$adventureRealm['Start']) -Context 'AdventureRealm.Start' -MapWidth $ExpectedMapWidth -MapHeight $ExpectedMapHeight
        $adventurePortal = ConvertTo-AnchorPoint -Token ([string]$adventureRealm['Portal']) -Context 'AdventureRealm.Portal' -MapWidth $ExpectedMapWidth -MapHeight $ExpectedMapHeight
        if ((Get-MapRowChar -Rows $adventureRows -X $adventureStart.X -Y $adventureStart.Y) -eq '#') {
            throw ("AdventureRealm.Start ({0},{1}) in {2} must sit on a floor tile." -f $adventureStart.X, $adventureStart.Y, $SourcePath)
        }

        if ((Get-MapRowChar -Rows $adventureRows -X $adventurePortal.X -Y $adventurePortal.Y) -eq '#') {
            throw ("AdventureRealm.Portal ({0},{1}) in {2} must sit on a floor tile." -f $adventurePortal.X, $adventurePortal.Y, $SourcePath)
        }

        $adventureGemBytes = New-Object 'System.Collections.Generic.List[string]'
        foreach ($token in @($adventureRealm['Gems'])) {
            $point = ConvertTo-AnchorPoint -Token ([string]$token) -Context 'AdventureRealm.Gems' -MapWidth $ExpectedMapWidth -MapHeight $ExpectedMapHeight
            $adventureGemBytes.Add($point.X.ToString())
            $adventureGemBytes.Add($point.Y.ToString())
        }

        $adventureSwitchBytes = New-Object 'System.Collections.Generic.List[string]'
        foreach ($token in @($adventureRealm['Switches'])) {
            $point = ConvertTo-AnchorPoint -Token ([string]$token) -Context 'AdventureRealm.Switches' -MapWidth $ExpectedMapWidth -MapHeight $ExpectedMapHeight
            $adventureSwitchBytes.Add($point.X.ToString())
            $adventureSwitchBytes.Add($point.Y.ToString())
        }

        $adventureKeyBytes = New-Object 'System.Collections.Generic.List[string]'
        foreach ($token in @($adventureRealm['Key'])) {
            $point = ConvertTo-AnchorPoint -Token ([string]$token) -Context 'AdventureRealm.Key' -MapWidth $ExpectedMapWidth -MapHeight $ExpectedMapHeight
            $adventureKeyBytes.Add($point.X.ToString())
            $adventureKeyBytes.Add($point.Y.ToString())
        }

        $adventureHazardBytes = New-Object 'System.Collections.Generic.List[string]'
        foreach ($token in @($adventureRealm['Hazards'])) {
            $point = ConvertTo-AnchorPoint -Token ([string]$token) -Context 'AdventureRealm.Hazards' -MapWidth $ExpectedMapWidth -MapHeight $ExpectedMapHeight
            $adventureHazardBytes.Add($point.X.ToString())
            $adventureHazardBytes.Add($point.Y.ToString())
        }

        $adventureEnemyBytes = New-Object 'System.Collections.Generic.List[string]'
        foreach ($enemyEntry in @($adventureRealm['Enemies'])) {
            if (-not ($enemyEntry -is [System.Collections.IDictionary])) {
                throw ("AdventureRealm enemies in {0} must be hashtables with X, Y, and Kind." -f $SourcePath)
            }

            $kindToken = ([string]$enemyEntry['Kind']).Trim().ToUpperInvariant()
            if (-not $enemyKindLookup.ContainsKey($kindToken)) {
                throw ("AdventureRealm enemy in {0} used unsupported Kind '{1}'." -f $SourcePath, $enemyEntry['Kind'])
            }

            $adventureEnemyBytes.Add(([int]$enemyEntry['X']).ToString())
            $adventureEnemyBytes.Add(([int]$enemyEntry['Y']).ToString())
            $adventureEnemyBytes.Add(([int]$enemyKindLookup[$kindToken]).ToString())
        }

        $adventurePropXs = New-Object 'System.Collections.Generic.List[string]'
        $adventurePropYs = New-Object 'System.Collections.Generic.List[string]'
        $adventurePropMeshes = New-Object 'System.Collections.Generic.List[string]'
        $adventurePropYaws = New-Object 'System.Collections.Generic.List[string]'
        foreach ($propEntry in @($adventureRealm['Props'])) {
            if (-not ($propEntry -is [System.Collections.IDictionary])) {
                throw ("AdventureRealm props in {0} must be hashtables with X, Y, Mesh, and optional YawDegrees." -f $SourcePath)
            }

            $meshToken = ([string]$propEntry['Mesh']).Trim()
            if ([string]::IsNullOrWhiteSpace($meshToken)) {
                throw ("AdventureRealm prop in {0} is missing Mesh." -f $SourcePath)
            }

            $meshAsmToken = ("GAME3D_MESH_{0}_INDEX" -f (($meshToken.ToUpperInvariant()) -replace '[^A-Z0-9]', '_'))
            $yawDegrees = if ($propEntry.ContainsKey('YawDegrees')) { [double]$propEntry['YawDegrees'] } else { 0.0 }
            $yawValue = [int][Math]::Round((($yawDegrees % 360.0 + 360.0) % 360.0) * 256.0 / 360.0) % 256

            $adventurePropXs.Add(([int]$propEntry['X']).ToString())
            $adventurePropYs.Add(([int]$propEntry['Y']).ToString())
            $adventurePropMeshes.Add($meshAsmToken)
            $adventurePropYaws.Add($yawValue.ToString())
        }

        $sectorLines.Add('')
        $sectorLines.Add('; Adventure vertical-slice realm')
        $sectorLines.Add(("adventure_realm_title db {0}, 0" -f (ConvertTo-AsmStringLiteral -Value $adventureTitle -Context 'AdventureRealm.Title')))
        $sectorLines.Add(("adventure_realm_intro db {0}, 0" -f (ConvertTo-AsmStringLiteral -Value $adventureIntro -Context 'AdventureRealm.Intro')))
        $sectorLines.Add(("adventure_realm_start_x db {0}" -f $adventureStart.X))
        $sectorLines.Add(("adventure_realm_start_y db {0}" -f $adventureStart.Y))
        $sectorLines.Add(("adventure_realm_portal_x db {0}" -f $adventurePortal.X))
        $sectorLines.Add(("adventure_realm_portal_y db {0}" -f $adventurePortal.Y))
        $sectorLines.Add(("adventure_realm_required_gems db {0}" -f $adventureRequiredGems))
        $sectorLines.Add(("adventure_realm_gem_count db {0}" -f ($adventureGemBytes.Count / 2)))
        $sectorLines.Add(("adventure_realm_switch_count db {0}" -f ($adventureSwitchBytes.Count / 2)))
        $sectorLines.Add(("adventure_realm_key_count db {0}" -f ($adventureKeyBytes.Count / 2)))
        $sectorLines.Add(("adventure_realm_hazard_count db {0}" -f ($adventureHazardBytes.Count / 2)))
        $sectorLines.Add(("adventure_realm_enemy_count db {0}" -f ($adventureEnemyBytes.Count / 3)))
        $sectorLines.Add(("adventure_realm_prop_count db {0}" -f $adventurePropXs.Count))
        Add-AsmDataLines -Lines $sectorLines -Label 'adventure_realm_gem_table' -Directive 'db' -Values $(if ($adventureGemBytes.Count -gt 0) { $adventureGemBytes.ToArray() } else { @('0') }) -ValuesPerLine 12
        Add-AsmDataLines -Lines $sectorLines -Label 'adventure_realm_switch_table' -Directive 'db' -Values $(if ($adventureSwitchBytes.Count -gt 0) { $adventureSwitchBytes.ToArray() } else { @('0') }) -ValuesPerLine 12
        Add-AsmDataLines -Lines $sectorLines -Label 'adventure_realm_key_table' -Directive 'db' -Values $(if ($adventureKeyBytes.Count -gt 0) { $adventureKeyBytes.ToArray() } else { @('0') }) -ValuesPerLine 12
        Add-AsmDataLines -Lines $sectorLines -Label 'adventure_realm_hazard_table' -Directive 'db' -Values $(if ($adventureHazardBytes.Count -gt 0) { $adventureHazardBytes.ToArray() } else { @('0') }) -ValuesPerLine 12
        Add-AsmDataLines -Lines $sectorLines -Label 'adventure_realm_enemy_table' -Directive 'db' -Values $(if ($adventureEnemyBytes.Count -gt 0) { $adventureEnemyBytes.ToArray() } else { @('0') }) -ValuesPerLine 12
        Add-AsmDataLines -Lines $sectorLines -Label 'adventure_realm_prop_x_table' -Directive 'db' -Values $(if ($adventurePropXs.Count -gt 0) { $adventurePropXs.ToArray() } else { @('0') }) -ValuesPerLine 12
        Add-AsmDataLines -Lines $sectorLines -Label 'adventure_realm_prop_y_table' -Directive 'db' -Values $(if ($adventurePropYs.Count -gt 0) { $adventurePropYs.ToArray() } else { @('0') }) -ValuesPerLine 12
        Add-AsmDataLines -Lines $sectorLines -Label 'adventure_realm_prop_mesh_table' -Directive 'db' -Values $(if ($adventurePropMeshes.Count -gt 0) { $adventurePropMeshes.ToArray() } else { @('0') }) -ValuesPerLine 8
        Add-AsmDataLines -Lines $sectorLines -Label 'adventure_realm_prop_yaw_table' -Directive 'db' -Values $(if ($adventurePropYaws.Count -gt 0) { $adventurePropYaws.ToArray() } else { @('0') }) -ValuesPerLine 12
        for ($rowIndex = 0; $rowIndex -lt $adventureRows.Count; $rowIndex++) {
            $row = $adventureRows[$rowIndex]
            if ($row.Length -ne $ExpectedMapWidth) {
                throw ("AdventureRealm row {0} in {1} has width {2}, expected {3}." -f ($rowIndex + 1), $SourcePath, $row.Length, $ExpectedMapWidth)
            }

            $rowPrefix = if ($rowIndex -eq 0) { 'adventure_realm_map db ' } else { (' ' * ('adventure_realm_map'.Length + 1)) + 'db ' }
            $sectorLines.Add($rowPrefix + (ConvertTo-AsmStringLiteral -Value $row -Context ("AdventureRealm row {0}" -f ($rowIndex + 1))))
        }
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
        AnchorSummary = ($anchorSummary -join ' | ')
        ScenarioSummary = ($scenarioSummary -join ' | ')
        ShardPoolSummary = ($shardPoolSummary -join ' | ')
        AdventureRealmSummary = if ($contentData.ContainsKey('AdventureRealm')) { ("{0} start {1},{2} -> portal {3},{4}, gems {5}/{6}" -f $adventureTitle, $adventureStart.X, $adventureStart.Y, $adventurePortal.X, $adventurePortal.Y, ($adventureGemBytes.Count / 2), $adventureRequiredGems) } else { 'none' }
        AdventureZoneSummary = if ($contentData.ContainsKey('AdventureRealm')) { ($adventureMacroZoneSummary -join ' | ') } else { 'none' }
        AdventureRouteSummary = if ($contentData.ContainsKey('AdventureRealm')) { ($adventureRouteBeatSummary -join ' | ') } else { 'none' }
        AdventureCaptureSummary = if ($contentData.ContainsKey('AdventureRealm')) { $adventureCaptureSummary } else { 'none' }
        AdventureRealmPresent = $contentData.ContainsKey('AdventureRealm')
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
        'WAIT'       = 'DEMO_ACTION_WAIT'
        'FORWARD'    = 'DEMO_ACTION_FORWARD'
        'BACK'       = 'DEMO_ACTION_BACK'
        'TURNLEFT'   = 'DEMO_ACTION_TURN_LEFT'
        'TURN_LEFT'  = 'DEMO_ACTION_TURN_LEFT'
        'TURNRIGHT'  = 'DEMO_ACTION_TURN_RIGHT'
        'TURN_RIGHT' = 'DEMO_ACTION_TURN_RIGHT'
        'FLAME'      = 'DEMO_ACTION_FLAME'
        'JUMP'       = 'DEMO_ACTION_JUMP'
        'GLIDE'      = 'DEMO_ACTION_GLIDE'
        'CHARGE'     = 'DEMO_ACTION_CHARGE'
        'ENTER'      = 'DEMO_ACTION_ENTER'
        'W'          = 'DEMO_ACTION_FORWARD'
        'S'          = 'DEMO_ACTION_BACK'
        'A'          = 'DEMO_ACTION_TURN_LEFT'
        'D'          = 'DEMO_ACTION_TURN_RIGHT'
        'C'          = 'DEMO_ACTION_FLAME'
        'SPACE'      = 'DEMO_ACTION_JUMP'
        'SHIFT'      = 'DEMO_ACTION_CHARGE'
        'RETURN'     = 'DEMO_ACTION_ENTER'
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
    $nameRefs = New-Object 'System.Collections.Generic.List[string]'
    $attractFlags = New-Object 'System.Collections.Generic.List[string]'
    $captureTicks = New-Object 'System.Collections.Generic.List[string]'
    $demoDataLines = New-Object 'System.Collections.Generic.List[string]'
    $demoNameLines = New-Object 'System.Collections.Generic.List[string]'
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

        $id = [string]$demo['Id']
        if ([string]::IsNullOrWhiteSpace($id) -or $id -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') {
            throw ("Demo '{0}' in {1} must define a stable Id using lowercase slug format." -f $name, $SourcePath)
        }

        $captureRole = ([string]$demo['CaptureRole']).Trim().ToLowerInvariant()
        if ([string]::IsNullOrWhiteSpace($captureRole) -or $captureRole -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') {
            throw ("Demo '{0}' in {1} must use a lowercase CaptureRole slug." -f $name, $SourcePath)
        }

        $captureTick = [int]$demo['CaptureTicks']
        if ($captureTick -lt 0 -or $captureTick -gt 255) {
            throw ("Demo '{0}' in {1} must use CaptureTicks in the 0..255 range." -f $name, $SourcePath)
        }

        $attract = if (($demo -is [System.Collections.IDictionary]) -and $demo.ContainsKey('Attract')) { [bool]$demo['Attract'] } else { $true }

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
        $demoNameLabel = ("demo_name_{0}" -f $demoIndex)
        $attractFlagValue = if ($attract) { '1' } else { '0' }
        $startSectors.Add($startSector.ToString())
        $seeds.Add((Format-Hex16Literal $seed))
        $scriptRefs.Add(("offset {0}" -f $demoLabel))
        $nameRefs.Add(("offset {0}" -f $demoNameLabel))
        $attractFlags.Add($attractFlagValue)
        $captureTicks.Add($captureTick.ToString())
        $demoSummary.Add(("{0} [{1}] (S{2}, capture {3}t, {4} steps)" -f $name, $captureRole, $startSector, $captureTick, $steps.Count))
        $demoDataLines.Add(("; Demo {0}: {1}" -f ($demoIndex + 1), $name))
        $demoNameLines.Add(("{0} db '{1}', 0" -f $demoNameLabel, $name.Replace("'", "''")))

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
    Add-AsmDataLines -Lines $lines -Label 'demo_name_table' -Directive 'dw' -Values $nameRefs.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'demo_attract_flag_table' -Directive 'db' -Values $attractFlags.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'demo_capture_tick_table' -Directive 'db' -Values $captureTicks.ToArray() -ValuesPerLine 8
    $lines.Add('')
    foreach ($demoLine in $demoDataLines) {
        $lines.Add($demoLine)
    }
    $lines.Add('')
    foreach ($demoNameLine in $demoNameLines) {
        $lines.Add($demoNameLine)
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

function Write-GeneratedRuntimeVerifyInclude {
    param(
        [object[]]$ReplayResults,
        [string]$OutputPath,
        [Nullable[int]]$CorruptDemoIndex
    )

    if (@($ReplayResults).Count -eq 0) {
        throw 'Runtime verification include generation requires at least one replay result.'
    }

    $lines = New-Object 'System.Collections.Generic.List[string]'
    $lines.Add('; generated by scripts/build.ps1')
    $lines.Add('; source: replay-harness results')
    $lines.Add('; edit assets/demos.psd1 or gameplay constants instead of this include')
    $lines.Add('')
    $lines.Add(("VERIFY_DEMO_COUNT EQU {0}" -f @($ReplayResults).Count))
    $lines.Add('')

    $checkpointCounts = New-Object 'System.Collections.Generic.List[string]'
    $finalSignatures = New-Object 'System.Collections.Generic.List[string]'
    $checkpointRefs = New-Object 'System.Collections.Generic.List[string]'
    $checkpointLines = New-Object 'System.Collections.Generic.List[string]'
    $summary = New-Object 'System.Collections.Generic.List[string]'
    $totalCheckpoints = 0
    $corruptIndex = if ($null -ne $CorruptDemoIndex) { [int]$CorruptDemoIndex } else { -1 }

    for ($demoIndex = 0; $demoIndex -lt @($ReplayResults).Count; $demoIndex++) {
        $result = $ReplayResults[$demoIndex]
        $checkpointValues = @($result.CheckpointSignatures | ForEach-Object { [int]$_ })
        $checkpointLabel = if ($checkpointValues.Count -gt 0) { "verify_demo_{0}_checkpoints" -f $demoIndex } else { $null }

        $finalSignature = [int]$result.RuntimeFinalSignature
        if ($demoIndex -eq $corruptIndex) {
            if ($checkpointValues.Count -gt 0) {
                $checkpointValues[0] = (($checkpointValues[0] -bxor 0x00FF) -band 0xFFFF)
            }
            $finalSignature = (($finalSignature + 1) -band 0xFFFF)
        }

        $checkpointCounts.Add($checkpointValues.Count.ToString())
        $finalSignatures.Add((Format-Hex16Literal $finalSignature))
        $checkpointRefs.Add($(if ($null -ne $checkpointLabel) { "offset {0}" -f $checkpointLabel } else { '0' }))
        $summary.Add(("{0} x{1} checkpoints final={2}" -f $result.Name, $checkpointValues.Count, (Format-Hex16 $finalSignature)))
        $totalCheckpoints += $checkpointValues.Count

        if ($null -ne $checkpointLabel) {
            Add-AsmDataLines -Lines $checkpointLines -Label $checkpointLabel -Directive 'dw' -Values @($checkpointValues | ForEach-Object { Format-Hex16Literal ([int]$_) }) -ValuesPerLine 6
            $checkpointLines.Add('')
        }
    }

    Add-AsmDataLines -Lines $lines -Label 'verify_demo_checkpoint_count_table' -Directive 'db' -Values $checkpointCounts.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'verify_demo_final_signature_table' -Directive 'dw' -Values $finalSignatures.ToArray() -ValuesPerLine 6
    Add-AsmDataLines -Lines $lines -Label 'verify_demo_checkpoint_table' -Directive 'dw' -Values $checkpointRefs.ToArray() -ValuesPerLine 4
    $lines.Add('')
    foreach ($checkpointLine in $checkpointLines) {
        $lines.Add($checkpointLine)
    }

    if ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq '') {
        $lines.RemoveAt($lines.Count - 1)
    }

    Set-Content -LiteralPath $OutputPath -Encoding ascii -Value $lines
    Assert-PathExists -Path $OutputPath -Label 'generated runtime verification include'

    return [pscustomobject]@{
        OutputPath = $OutputPath
        DemoCount = @($ReplayResults).Count
        CheckpointCount = $totalCheckpoints
        Summary = ($summary -join ', ')
        CorruptDemoIndex = $corruptIndex
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
        'G2'   = 'MUSIC_NOTE_G2'
        'A2'   = 'MUSIC_NOTE_A2'
        'C3'   = 'MUSIC_NOTE_C3'
        'D3'   = 'MUSIC_NOTE_D3'
        'E3'   = 'MUSIC_NOTE_E3'
        'F3'   = 'MUSIC_NOTE_F3'
        'G3'   = 'MUSIC_NOTE_G3'
        'A3'   = 'MUSIC_NOTE_A3'
        'C4'   = 'MUSIC_NOTE_C4'
        'D4'   = 'MUSIC_NOTE_D4'
        'E4'   = 'MUSIC_NOTE_E4'
        'F4'   = 'MUSIC_NOTE_F4'
        'G4'   = 'MUSIC_NOTE_G4'
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

function Write-GeneratedPresentationContent {
    param(
        [string]$SourcePath,
        [string]$OutputPath,
        [int]$ExpectedBannerWidth,
        [int]$ExpectedBannerHeight
    )

    $presentationData = Import-StructuredDataFile -SourcePath $SourcePath -Label 'presentation source'
    if (-not $presentationData.ContainsKey('Legend')) {
        throw ("Presentation source must define a 'Legend' table: {0}" -f $SourcePath)
    }

    if ((-not $presentationData.ContainsKey('Assets')) -and (-not $presentationData.ContainsKey('Banners'))) {
        throw ("Presentation source must define an 'Assets' array (or legacy 'Banners' array): {0}" -f $SourcePath)
    }

    $legend = $presentationData['Legend']
    if (-not ($legend -is [System.Collections.IDictionary])) {
        throw ("Presentation legend in {0} must be a key/value table." -f $SourcePath)
    }

    $legendMap = @{}
    foreach ($entry in $legend.GetEnumerator()) {
        $token = [string]$entry.Key
        if ($token.Length -ne 1) {
            throw ("Presentation legend key '{0}' in {1} must be exactly one ASCII character." -f $token, $SourcePath)
        }

        if ([int][char]$token[0] -gt 127) {
            throw ("Presentation legend key '{0}' in {1} must stay ASCII-only." -f $token, $SourcePath)
        }

        $paletteIndex = [int]$entry.Value
        if ($paletteIndex -lt 0 -or $paletteIndex -gt 255) {
            throw ("Presentation legend key '{0}' in {1} must map to a 0..255 palette index." -f $token, $SourcePath)
        }

        $legendMap[$token] = $paletteIndex
    }

    $expectedBannerKeys = @(
        'splash_logo',
        'splash_wordmark',
        'title_logo',
        'title_tagline',
        'title_prompt',
        'demo_badge',
        'sector1_card',
        'sector2_card',
        'sector3_card',
        'win_banner',
        'win_plate',
        'lose_banner',
        'lose_plate'
    )
    $assetCollectionKey = if ($presentationData.ContainsKey('Assets')) { 'Assets' } else { 'Banners' }
    $banners = @($presentationData[$assetCollectionKey])
    if ($banners.Count -ne $expectedBannerKeys.Count) {
        throw ("Presentation source defined {0} assets, but the runtime expects {1}." -f $banners.Count, $expectedBannerKeys.Count)
    }

    $lines = New-Object 'System.Collections.Generic.List[string]'
    $lines.Add('; generated by scripts/build.ps1')
    $lines.Add(("; source: {0}" -f $SourcePath))
    $lines.Add('; edit the presentation source file instead of this generated include')
    $lines.Add('')
    $lines.Add(("PRESENT_BANNER_WIDTH EQU {0}" -f $ExpectedBannerWidth))
    $lines.Add(("PRESENT_BANNER_HEIGHT EQU {0}" -f $ExpectedBannerHeight))
    $lines.Add('')

    $payload = New-Object 'System.Collections.Generic.List[byte]'
    $bannerSummary = New-Object 'System.Collections.Generic.List[string]'
    $bannerCount = 0
    $bannerBytes = $ExpectedBannerWidth * $ExpectedBannerHeight

    foreach ($bannerIndex in 0..($banners.Count - 1)) {
        $banner = $banners[$bannerIndex]
        if (-not ($banner -is [System.Collections.IDictionary])) {
            throw ("Each presentation asset in {0} must be a hashtable." -f $SourcePath)
        }

        $bannerKey = ([string]$banner['Key']).ToLowerInvariant()
        if ($bannerKey -ne $expectedBannerKeys[$bannerIndex]) {
            throw ("Presentation asset {0} in {1} must use key '{2}' to match the runtime order." -f ($bannerIndex + 1), $SourcePath, $expectedBannerKeys[$bannerIndex])
        }

        $rows = @($banner['Rows'])
        if ($rows.Count -ne $ExpectedBannerHeight) {
            throw ("Presentation asset '{0}' in {1} must define exactly {2} rows." -f $bannerKey, $SourcePath, $ExpectedBannerHeight)
        }

        $offset = $payload.Count
        $symbolPrefix = "PRESENT_BANNER_{0}" -f $bannerKey.ToUpperInvariant()
        $lines.Add(("{0}_OFFSET EQU {1}" -f $symbolPrefix, $offset))
        $lines.Add(("{0}_BYTES EQU {1}" -f $symbolPrefix, $bannerBytes))
        $lines.Add('')

        for ($rowIndex = 0; $rowIndex -lt $rows.Count; $rowIndex++) {
            $row = [string]$rows[$rowIndex]
            foreach ($ch in $row.ToCharArray()) {
                if ([int][char]$ch -gt 127) {
                    throw ("Presentation asset '{0}' row {1} in {2} must stay ASCII-only." -f $bannerKey, ($rowIndex + 1), $SourcePath)
                }
            }

            if ($row.Length -ne $ExpectedBannerWidth) {
                throw ("Presentation asset '{0}' row {1} in {2} must be exactly {3} characters wide." -f $bannerKey, ($rowIndex + 1), $SourcePath, $ExpectedBannerWidth)
            }

            foreach ($ch in $row.ToCharArray()) {
                $token = [string]$ch
                if (-not $legendMap.ContainsKey($token)) {
                    throw ("Presentation asset '{0}' row {1} in {2} used unknown legend token '{3}'." -f $bannerKey, ($rowIndex + 1), $SourcePath, $token)
                }

                $payload.Add([byte]$legendMap[$token])
            }
        }

        $bannerSummary.Add(("{0}@{1}" -f $bannerKey, $offset))
        $bannerCount += 1
    }

    if ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq '') {
        $lines.RemoveAt($lines.Count - 1)
    }

    Set-Content -LiteralPath $OutputPath -Encoding ascii -Value $lines
    Assert-PathExists -Path $OutputPath -Label 'generated presentation include'

    return [pscustomobject]@{
        SourcePath = $SourcePath
        OutputPath = $OutputPath
        BannerCount = $bannerCount
        BannerBytes = $bannerBytes
        TotalBytes = $payload.Count
        BannerSummary = ($bannerSummary -join ', ')
        BankPayloadBytes = $payload.ToArray()
    }
}

function ConvertTo-GeometryFixed88 {
    param(
        [object]$Value,
        [string]$Context
    )

    $numeric = [double]$Value
    $scaled = [int][Math]::Round($numeric * 256.0)
    if ($scaled -lt -32768 -or $scaled -gt 32767) {
        throw ("{0} must fit in a signed 8.8 fixed-point word. Received {1} -> {2}." -f $Context, $numeric, $scaled)
    }

    return $scaled
}

function ConvertTo-GeometryAngleByte {
    param(
        [object]$Value,
        [string]$Context
    )

    $numeric = [double]$Value
    $turn = $numeric % 360.0
    if ($turn -lt 0) {
        $turn += 360.0
    }

    return ([int][Math]::Round(($turn / 360.0) * 256.0)) -band 0xFF
}

function ConvertTo-GeometryPaletteSymbol {
    param(
        [object]$Value,
        [string]$Context
    )

    $symbol = ([string]$Value).Trim().ToUpperInvariant()
    if ([string]::IsNullOrWhiteSpace($symbol) -or $symbol -notmatch '^PAL_[A-Z0-9_]+$') {
        throw ("{0} must reference a PAL_* constant. Found '{1}'." -f $Context, $Value)
    }

    return $symbol
}

function Add-Int16Payload {
    param(
        [System.Collections.Generic.List[byte]]$Payload,
        [int]$Value
    )

    $masked = $Value -band 0xFFFF
    $Payload.Add([byte]($masked -band 0xFF))
    $Payload.Add([byte](($masked -shr 8) -band 0xFF))
}

function Align-BytePayload {
    param(
        [System.Collections.Generic.List[byte]]$Payload,
        [int]$Alignment
    )

    if ($Alignment -le 1) {
        return
    }

    while (($Payload.Count % $Alignment) -ne 0) {
        $Payload.Add([byte]0)
    }
}

function ConvertTo-AsmIdentifier {
    param([string]$Value)

    return (([string]$Value).ToUpperInvariant() -replace '[^A-Z0-9]', '_')
}

function Get-ByteArraySha256Hex {
    param([byte[]]$Bytes)

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash($Bytes)
    } finally {
        $sha.Dispose()
    }

    return ([BitConverter]::ToString($hash)).Replace('-', '')
}

function Write-GeneratedMachineCodeAssets {
    param(
        [string]$SourcePath,
        [string]$OutputPath,
        [string]$BinaryPath,
        [string]$ReportPath
    )

    $machineData = Import-StructuredDataFile -SourcePath $SourcePath -Label 'machine-code source'
    if (-not $machineData.ContainsKey('Kernels')) {
        throw ("Machine-code source must define a 'Kernels' array: {0}" -f $SourcePath)
    }

    $kernels = @($machineData['Kernels'])
    $tables = if ($machineData.ContainsKey('Tables')) {
        if ($machineData['Tables'] -is [System.Collections.IDictionary]) {
            ,$machineData['Tables']
        } else {
            @($machineData['Tables'])
        }
    } else {
        @()
    }
    if ($kernels.Count -eq 0) {
        throw ("Machine-code source must define at least one kernel: {0}" -f $SourcePath)
    }

    $stageMap = @{
        'transform' = 1
        'raster' = 2
        'effects' = 3
        'animation' = 4
    }

    $lines = New-Object 'System.Collections.Generic.List[string]'
    $lines.Add('; generated by scripts/build.ps1')
    $lines.Add(("; source: {0}" -f $SourcePath))
    $lines.Add('; raw machine-code kernels and code-bank tables')
    $lines.Add('')

    $reportLines = New-Object 'System.Collections.Generic.List[string]'
    $reportLines.Add('CyberStorm Machine Code Report')
    $reportLines.Add(("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')))
    $reportLines.Add(("Source: {0}" -f $SourcePath))
    $reportLines.Add('')

    $payload = New-Object 'System.Collections.Generic.List[byte]'
    $kernelSummary = New-Object 'System.Collections.Generic.List[string]'
    $tableSummary = New-Object 'System.Collections.Generic.List[string]'
    $kernelCount = 0
    $tableCount = 0

    foreach ($kernel in $kernels) {
        if (-not ($kernel -is [System.Collections.IDictionary])) {
            throw ("Each machine-code kernel in {0} must be a hashtable." -f $SourcePath)
        }

        $kernelId = ([string]$kernel['Id']).Trim().ToLowerInvariant()
        if ([string]::IsNullOrWhiteSpace($kernelId) -or $kernelId -notmatch '^[a-z0-9_]+$') {
            throw ("Machine-code kernel Id values in {0} must be lowercase identifiers. Found '{1}'." -f $SourcePath, $kernel['Id'])
        }

        $stageKey = ([string]$kernel['Stage']).Trim().ToLowerInvariant()
        if (-not $stageMap.ContainsKey($stageKey)) {
            throw ("Machine-code kernel '{0}' in {1} used unsupported Stage '{2}'." -f $kernelId, $SourcePath, $kernel['Stage'])
        }

        $fallbackSymbol = ([string]$kernel['FallbackSymbol']).Trim()
        if ([string]::IsNullOrWhiteSpace($fallbackSymbol)) {
            throw ("Machine-code kernel '{0}' in {1} must define FallbackSymbol." -f $kernelId, $SourcePath)
        }

        $paramBlockSize = [int]$kernel['ParamBlockSize']
        if ($paramBlockSize -lt 0 -or $paramBlockSize -gt 255) {
            throw ("Machine-code kernel '{0}' in {1} must keep ParamBlockSize in the 0..255 range. Found {2}." -f $kernelId, $SourcePath, $paramBlockSize)
        }

        $bytes = New-Object 'System.Collections.Generic.List[byte]'
        foreach ($value in @($kernel['Bytes'])) {
            $byteValue = [int]$value
            if ($byteValue -lt 0 -or $byteValue -gt 255) {
                throw ("Machine-code kernel '{0}' in {1} contains byte {2} outside 0..255." -f $kernelId, $SourcePath, $byteValue)
            }

            $bytes.Add([byte]$byteValue)
        }

        if ($bytes.Count -eq 0) {
            throw ("Machine-code kernel '{0}' in {1} cannot be empty." -f $kernelId, $SourcePath)
        }

        Align-BytePayload -Payload $payload -Alignment 16
        $entryOffset = $payload.Count
        foreach ($byteValue in $bytes) {
            $payload.Add($byteValue)
        }

        $asmId = ConvertTo-AsmIdentifier -Value $kernelId
        $signature = Get-ByteArraySha256Hex -Bytes $bytes.ToArray()
        $clobbers = if ($kernel.ContainsKey('Clobbers')) { ((@($kernel['Clobbers']) | ForEach-Object { [string]$_ }) -join ', ') } else { 'none listed' }
        $previewCount = [Math]::Min(12, $bytes.Count)
        $preview = ((0..($previewCount - 1) | ForEach-Object { "{0:X2}" -f [int]$bytes[$_] }) -join ' ')

        $lines.Add(("MC_KERNEL_{0}_OFFSET EQU {1}" -f $asmId, (Format-Hex16Literal $entryOffset)))
        $lines.Add(("MC_KERNEL_{0}_BYTES EQU {1}" -f $asmId, $bytes.Count))
        $lines.Add(("MC_KERNEL_{0}_PARAM_BYTES EQU {1}" -f $asmId, $paramBlockSize))
        $lines.Add(("MC_KERNEL_{0}_STAGE EQU {1}" -f $asmId, $stageMap[$stageKey]))
        $lines.Add('')

        $kernelSummary.Add(("{0}@{1} ({2} bytes, {3})" -f $kernelId, (Format-Hex16 $entryOffset), $bytes.Count, $stageKey))
        $reportLines.Add(("Kernel: {0}" -f $kernelId))
        $reportLines.Add(("  Stage: {0}" -f $stageKey))
        $reportLines.Add(("  Entry offset: {0}" -f (Format-Hex16 $entryOffset)))
        $reportLines.Add(("  Byte count: {0}" -f $bytes.Count))
        $reportLines.Add(("  Param block: {0} bytes" -f $paramBlockSize))
        $reportLines.Add(("  Fallback: {0}" -f $fallbackSymbol))
        $reportLines.Add(("  Clobbers: {0}" -f $clobbers))
        $reportLines.Add(("  SHA256: {0}" -f $signature))
        $reportLines.Add(("  Bytes: {0}" -f $preview))
        $reportLines.Add('')
        $kernelCount += 1
    }

    foreach ($table in $tables) {
        if (-not ($table -is [System.Collections.IDictionary])) {
            throw ("Each machine-code table in {0} must be a hashtable." -f $SourcePath)
        }

        $tableId = ([string]$table['Id']).Trim().ToLowerInvariant()
        if ([string]::IsNullOrWhiteSpace($tableId) -or $tableId -notmatch '^[a-z0-9_]+$') {
            throw ("Machine-code table Id values in {0} must be lowercase identifiers. Found '{1}'." -f $SourcePath, $table['Id'])
        }

        $elementSize = [int]$table['ElementSize']
        if ($elementSize -ne 1 -and $elementSize -ne 2) {
            throw ("Machine-code table '{0}' in {1} must use ElementSize 1 or 2. Found {2}." -f $tableId, $SourcePath, $elementSize)
        }

        $signed = if ($table.ContainsKey('Signed')) { [bool]$table['Signed'] } else { $false }
        $values = @($table['Values'])
        if ($values.Count -eq 0) {
            throw ("Machine-code table '{0}' in {1} cannot be empty." -f $tableId, $SourcePath)
        }

        Align-BytePayload -Payload $payload -Alignment $elementSize
        $tableOffset = $payload.Count
        foreach ($value in $values) {
            $intValue = [int]$value
            if ($elementSize -eq 1) {
                $payload.Add([byte]($intValue -band 0xFF))
            } else {
                Add-Int16Payload -Payload $payload -Value $intValue
            }
        }

        $tableBytes = $values.Count * $elementSize
        $asmId = ConvertTo-AsmIdentifier -Value $tableId
        $lines.Add(("MC_TABLE_{0}_OFFSET EQU {1}" -f $asmId, (Format-Hex16Literal $tableOffset)))
        $lines.Add(("MC_TABLE_{0}_COUNT EQU {1}" -f $asmId, $values.Count))
        $lines.Add(("MC_TABLE_{0}_BYTES EQU {1}" -f $asmId, $tableBytes))
        $lines.Add('')

        $tableSummary.Add(("{0}@{1} ({2} x {3} bytes)" -f $tableId, (Format-Hex16 $tableOffset), $values.Count, $elementSize))
        $reportLines.Add(("Table: {0}" -f $tableId))
        $reportLines.Add(("  Offset: {0}" -f (Format-Hex16 $tableOffset)))
        $reportLines.Add(("  Elements: {0}" -f $values.Count))
        $reportLines.Add(("  Element size: {0}" -f $elementSize))
        $reportLines.Add(("  Signed: {0}" -f $(if ($signed) { 'yes' } else { 'no' })))
        $reportLines.Add('')
        $tableCount += 1
    }

    $lines.Insert(4, ("MC_TABLE_COUNT EQU {0}" -f $tableCount))
    $lines.Insert(4, ("MC_KERNEL_COUNT EQU {0}" -f $kernelCount))
    $lines.Insert(6, '')
    $lines.Add(("MC_CODE_BANK_BYTES EQU {0}" -f $payload.Count))
    Set-Content -LiteralPath $OutputPath -Encoding ascii -Value $lines
    Set-Content -LiteralPath $ReportPath -Encoding ascii -Value $reportLines
    [IO.File]::WriteAllBytes($BinaryPath, $payload.ToArray())
    Assert-PathExists -Path $OutputPath -Label 'generated machine-code include'
    Assert-PathExists -Path $ReportPath -Label 'machine-code report'
    Assert-PathExists -Path $BinaryPath -Label 'machine-code bank payload'

    return [pscustomobject]@{
        SourcePath = $SourcePath
        OutputPath = $OutputPath
        ReportPath = $ReportPath
        BinaryPath = $BinaryPath
        KernelCount = $kernelCount
        TableCount = $tableCount
        TotalBytes = $payload.Count
        KernelSummary = ($kernelSummary -join ' | ')
        TableSummary = if ($tableSummary.Count -gt 0) { ($tableSummary -join ' | ') } else { 'none' }
        BankPayloadBytes = $payload.ToArray()
    }
}

function Write-GeneratedTextureBank {
    param(
        [object[]]$TextureEntries,
        [string]$BinaryPath,
        [string]$ReportPath
    )

    $atlasW = 128
    $atlasH = 128
    $effectW = 64
    $effectH = 64
    $tileSize = 32
    $tilesPerRow = [int]($atlasW / $tileSize)

    $atlas = New-Object byte[] ($atlasW * $atlasH)
    $effects = New-Object byte[] ($effectW * $effectH)

    $uniqueEntries = New-Object 'System.Collections.Generic.List[object]'
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in @($TextureEntries)) {
        if ($null -eq $entry) {
            continue
        }

        $key = ([string]$entry.TextureKey).Trim().ToLowerInvariant()
        if ([string]::IsNullOrWhiteSpace($key)) {
            continue
        }

        if ($seen.Add($key)) {
            $uniqueEntries.Add($entry)
        }
    }

    if ($uniqueEntries.Count -eq 0) {
        $uniqueEntries.Add([pscustomobject]@{
            TextureKey = 'fallback'
            Base = 7
            Dither = 6
            ShadeMode = 'affine'
        })
    }

    if ($uniqueEntries.Count -gt ($tilesPerRow * $tilesPerRow)) {
        throw ("Texture atlas supports at most {0} unique texture keys, but geometry referenced {1}." -f ($tilesPerRow * $tilesPerRow), $uniqueEntries.Count)
    }

    $summary = New-Object 'System.Collections.Generic.List[string]'
    for ($textureIndex = 0; $textureIndex -lt $uniqueEntries.Count; $textureIndex++) {
        $entry = $uniqueEntries[$textureIndex]
        $tileX = ($textureIndex % $tilesPerRow) * $tileSize
        $tileY = [int][Math]::Floor($textureIndex / $tilesPerRow) * $tileSize
        $base = [byte]([int]$entry.Base -band 0xFF)
        $dither = [byte]([int]$entry.Dither -band 0xFF)
        $key = ([string]$entry.TextureKey).Trim().ToLowerInvariant()

        for ($y = 0; $y -lt $tileSize; $y++) {
            for ($x = 0; $x -lt $tileSize; $x++) {
                $color = $base
                switch -Regex ($key) {
                    'grass|meadow' {
                        if ((($x + $y) % 7) -eq 0) { $color = $dither }
                        elseif (($y % 8) -eq 0) { $color = [byte](($base + 1) -band 0xFF) }
                    }
                    'stone|cliff|tower|portal' {
                        if (((($x * 3) + ($y * 5)) % 11) -lt 4) { $color = $dither }
                    }
                    'bridge|wood|bark|trunk' {
                        if (($x % 6) -lt 2) { $color = $dither }
                    }
                    'banner|warm' {
                        if (($x % 8) -lt 3) { $color = $dither }
                    }
                    'lava|hot' {
                        if (((($x * 5) + ($y * 3)) % 9) -lt 4) { $color = $dither } else { $color = [byte](($base + 1) -band 0xFF) }
                    }
                    'leaf|canopy' {
                        if (((($x * $x) + ($y * 3)) % 13) -lt 5) { $color = $dither }
                    }
                    'gem' {
                        if ((($x + $y) % 6) -lt 2) { $color = $dither } else { $color = [byte](($base + 1) -band 0xFF) }
                    }
                    default {
                        if ((($x + $y) % 4) -eq 0) { $color = $dither }
                    }
                }

                $atlas[(($tileY + $y) * $atlasW) + $tileX + $x] = $color
            }
        }

        $summary.Add(("{0}@{1},{2}" -f $key, $tileX, $tileY))
    }

    for ($y = 0; $y -lt $effectH; $y++) {
        for ($x = 0; $x -lt $effectW; $x++) {
            $color = if (((($x - 32) * ($x - 32)) + (($y - 32) * ($y - 32))) -lt 400) { 7 } else { 0 }
            if ((($x + $y) % 5) -eq 0) {
                $color = 8
            }

            $effects[($y * $effectW) + $x] = [byte]$color
        }
    }

    $bankPayload = New-Object byte[] ($atlas.Length + $effects.Length)
    [Array]::Copy($atlas, 0, $bankPayload, 0, $atlas.Length)
    [Array]::Copy($effects, 0, $bankPayload, $atlas.Length, $effects.Length)

    $reportLines = @(
        'CyberStorm Texture Bank Report'
        ("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'))
        ("Atlas: {0}x{1}" -f $atlasW, $atlasH)
        ("Effects page: {0}x{1}" -f $effectW, $effectH)
        ("Texture entries: {0}" -f $uniqueEntries.Count)
        ("Summary: {0}" -f ($summary -join ' | '))
        ("SHA256: {0}" -f (Get-ByteArraySha256Hex -Bytes $bankPayload))
    )

    [IO.File]::WriteAllBytes($BinaryPath, $bankPayload)
    Set-Content -LiteralPath $ReportPath -Encoding ascii -Value $reportLines
    Assert-PathExists -Path $BinaryPath -Label 'texture bank payload'
    Assert-PathExists -Path $ReportPath -Label 'texture bank report'

    return [pscustomobject]@{
        BinaryPath = $BinaryPath
        ReportPath = $ReportPath
        TotalBytes = $bankPayload.Length
        TextureCount = $uniqueEntries.Count
        Summary = ($summary -join ' | ')
        BankPayloadBytes = $bankPayload
    }
}

function Write-GeneratedGeometryInclude {
    param(
        [string]$SourcePath,
        [string]$OutputPath
    )

    $geometryData = Import-StructuredDataFile -SourcePath $SourcePath -Label 'geometry source'
    if (-not $geometryData.ContainsKey('Materials')) {
        throw ("Geometry source must define a 'Materials' array: {0}" -f $SourcePath)
    }

    foreach ($requiredField in @('Scenes', 'GameplayKits', 'Meshes')) {
        if (-not $geometryData.ContainsKey($requiredField)) {
            throw ("Geometry source must define a '{0}' array: {1}" -f $requiredField, $SourcePath)
        }
    }

    $expectedSceneKeys = @('splash', 'title', 'sector1', 'sector2', 'sector3', 'win', 'lose')
    $expectedKitKeys = @('sector1', 'sector2', 'sector3')
    $materials = @($geometryData['Materials'])
    $scenes = @($geometryData['Scenes'])
    $kits = @($geometryData['GameplayKits'])
    $meshes = @($geometryData['Meshes'])

    if ($scenes.Count -ne $expectedSceneKeys.Count) {
        throw ("Geometry source defined {0} scenes, but the runtime expects {1}." -f $scenes.Count, $expectedSceneKeys.Count)
    }

    if ($kits.Count -ne $expectedKitKeys.Count) {
        throw ("Geometry source defined {0} gameplay kits, but the runtime expects {1}." -f $kits.Count, $expectedKitKeys.Count)
    }

    if ($meshes.Count -lt 1) {
        throw ("Geometry source must define at least one gameplay mesh: {0}" -f $SourcePath)
    }

    $materialMap = @{}
    foreach ($material in $materials) {
        if (-not ($material -is [System.Collections.IDictionary])) {
            throw ("Each geometry material in {0} must be a hashtable." -f $SourcePath)
        }

        $key = ([string]$material['Key']).ToLowerInvariant()
        if ([string]::IsNullOrWhiteSpace($key)) {
            throw ("Geometry materials in {0} must define a non-empty Key." -f $SourcePath)
        }

        if ($materialMap.ContainsKey($key)) {
            throw ("Geometry material '{0}' is defined more than once in {1}." -f $key, $SourcePath)
        }

        $base = [int]$material['Base']
        $dither = [int]$material['Dither']
        foreach ($component in @(
            @{ Label = 'Base'; Value = $base },
            @{ Label = 'Dither'; Value = $dither }
        )) {
            if ($component.Value -lt 0 -or $component.Value -gt 255) {
                throw ("Geometry material '{0}' {1} color in {2} must stay in the 0..255 VGA palette range." -f $key, $component.Label, $SourcePath)
            }
        }

        $textureKey = if ($material.ContainsKey('TextureKey')) { ([string]$material['TextureKey']).Trim().ToLowerInvariant() } else { '' }
        if ($textureKey -and $textureKey -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') {
            throw ("Geometry material '{0}' in {1} must use lowercase TextureKey slugs. Found '{2}'." -f $key, $SourcePath, $material['TextureKey'])
        }

        $shadeMode = if ($material.ContainsKey('ShadeMode')) { ([string]$material['ShadeMode']).Trim().ToLowerInvariant() } else { 'flat' }
        if ($shadeMode -notin @('flat', 'affine')) {
            throw ("Geometry material '{0}' in {1} must use ShadeMode 'flat' or 'affine'. Found '{2}'." -f $key, $SourcePath, $shadeMode)
        }

        $materialMap[$key] = [pscustomobject]@{
            Key = $key
            Base = $base
            Dither = $dither
            TextureKey = $textureKey
            ShadeMode = $shadeMode
        }
    }

    $lines = New-Object 'System.Collections.Generic.List[string]'
    $lines.Add('; generated by scripts/build.ps1')
    $lines.Add(("; source: {0}" -f $SourcePath))
    $lines.Add('; edit the geometry source file instead of this generated include')
    $lines.Add('')

    $payload = New-Object 'System.Collections.Generic.List[byte]'
    $sceneSummary = New-Object 'System.Collections.Generic.List[string]'
    $sceneFaceSummary = New-Object 'System.Collections.Generic.List[string]'
    $meshSummary = New-Object 'System.Collections.Generic.List[string]'
    $kitSummary = New-Object 'System.Collections.Generic.List[string]'
    $sceneVertexOffsets = New-Object 'System.Collections.Generic.List[string]'
    $sceneVertexCounts = New-Object 'System.Collections.Generic.List[string]'
    $sceneFaceOffsets = New-Object 'System.Collections.Generic.List[string]'
    $sceneFaceCounts = New-Object 'System.Collections.Generic.List[string]'
    $sceneViewportXs = New-Object 'System.Collections.Generic.List[string]'
    $sceneViewportYs = New-Object 'System.Collections.Generic.List[string]'
    $sceneViewportWs = New-Object 'System.Collections.Generic.List[string]'
    $sceneViewportHs = New-Object 'System.Collections.Generic.List[string]'
    $sceneCameraXs = New-Object 'System.Collections.Generic.List[string]'
    $sceneCameraYs = New-Object 'System.Collections.Generic.List[string]'
    $sceneCameraZs = New-Object 'System.Collections.Generic.List[string]'
    $sceneYawBases = New-Object 'System.Collections.Generic.List[string]'
    $sceneYawSteps = New-Object 'System.Collections.Generic.List[string]'
    $scenePitchBases = New-Object 'System.Collections.Generic.List[string]'
    $scenePitchSteps = New-Object 'System.Collections.Generic.List[string]'
    $sceneProjectScales = New-Object 'System.Collections.Generic.List[string]'
    $sceneTimelineLengths = New-Object 'System.Collections.Generic.List[string]'
    $sceneTimelineLoops = New-Object 'System.Collections.Generic.List[string]'
    $sceneGroupStarts = New-Object 'System.Collections.Generic.List[string]'
    $sceneGroupCounts = New-Object 'System.Collections.Generic.List[string]'
    $sceneGroupVertexOffsets = New-Object 'System.Collections.Generic.List[string]'
    $sceneGroupVertexCounts = New-Object 'System.Collections.Generic.List[string]'
    $sceneGroupFaceOffsets = New-Object 'System.Collections.Generic.List[string]'
    $sceneGroupFaceCounts = New-Object 'System.Collections.Generic.List[string]'
    $sceneGroupStartTicks = New-Object 'System.Collections.Generic.List[string]'
    $sceneGroupEndTicks = New-Object 'System.Collections.Generic.List[string]'
    $sceneGroupMotionTicks = New-Object 'System.Collections.Generic.List[string]'
    $sceneGroupOffsetXs = New-Object 'System.Collections.Generic.List[string]'
    $sceneGroupOffsetYs = New-Object 'System.Collections.Generic.List[string]'
    $sceneGroupOffsetZs = New-Object 'System.Collections.Generic.List[string]'
    $sceneGroupOffsetXSteps = New-Object 'System.Collections.Generic.List[string]'
    $sceneGroupOffsetYSteps = New-Object 'System.Collections.Generic.List[string]'
    $sceneGroupOffsetZSteps = New-Object 'System.Collections.Generic.List[string]'
    $sceneGroupYawBases = New-Object 'System.Collections.Generic.List[string]'
    $sceneGroupYawSteps = New-Object 'System.Collections.Generic.List[string]'
    $timelineCameraXs = New-Object 'System.Collections.Generic.List[string]'
    $timelineCameraYs = New-Object 'System.Collections.Generic.List[string]'
    $timelineCameraZs = New-Object 'System.Collections.Generic.List[string]'
    $timelineProjectScales = New-Object 'System.Collections.Generic.List[string]'
    $timelineYaws = New-Object 'System.Collections.Generic.List[string]'
    $timelinePitches = New-Object 'System.Collections.Generic.List[string]'
    $meshVertexOffsets = New-Object 'System.Collections.Generic.List[string]'
    $meshVertexCounts = New-Object 'System.Collections.Generic.List[string]'
    $meshFaceOffsets = New-Object 'System.Collections.Generic.List[string]'
    $meshFaceCounts = New-Object 'System.Collections.Generic.List[string]'
    $kitFloorBaseColor = New-Object 'System.Collections.Generic.List[string]'
    $kitFloorBaseDither = New-Object 'System.Collections.Generic.List[string]'
    $kitFloorTrimColor = New-Object 'System.Collections.Generic.List[string]'
    $kitFloorTrimDither = New-Object 'System.Collections.Generic.List[string]'
    $kitWallBaseColor = New-Object 'System.Collections.Generic.List[string]'
    $kitWallBaseDither = New-Object 'System.Collections.Generic.List[string]'
    $kitWallTrimColor = New-Object 'System.Collections.Generic.List[string]'
    $kitWallTrimDither = New-Object 'System.Collections.Generic.List[string]'
    $kitWallCapColor = New-Object 'System.Collections.Generic.List[string]'
    $kitWallCapDither = New-Object 'System.Collections.Generic.List[string]'
    $kitLaneColor = New-Object 'System.Collections.Generic.List[string]'
    $kitLaneDither = New-Object 'System.Collections.Generic.List[string]'
    $kitGateMesh = New-Object 'System.Collections.Generic.List[string]'
    $kitTerminalMesh = New-Object 'System.Collections.Generic.List[string]'
    $kitSurgeMesh = New-Object 'System.Collections.Generic.List[string]'
    $kitShardMesh = New-Object 'System.Collections.Generic.List[string]'
    $kitCameraHeight = New-Object 'System.Collections.Generic.List[string]'
    $kitCameraDistance = New-Object 'System.Collections.Generic.List[string]'
    $kitCameraLookAhead = New-Object 'System.Collections.Generic.List[string]'
    $kitCameraNorthYaw = New-Object 'System.Collections.Generic.List[string]'
    $kitCameraEastYaw = New-Object 'System.Collections.Generic.List[string]'
    $kitCameraSouthYaw = New-Object 'System.Collections.Generic.List[string]'
    $kitCameraWestYaw = New-Object 'System.Collections.Generic.List[string]'
    $kitProjectionPitch = New-Object 'System.Collections.Generic.List[string]'
    $kitProjectionScale = New-Object 'System.Collections.Generic.List[string]'
    $kitNearOccluderInset = New-Object 'System.Collections.Generic.List[string]'
    $kitNearOccluderWidth = New-Object 'System.Collections.Generic.List[string]'
    $kitNearOccluderHeight = New-Object 'System.Collections.Generic.List[string]'
    $kitFarSilhouetteInset = New-Object 'System.Collections.Generic.List[string]'
    $kitFarSilhouetteHeight = New-Object 'System.Collections.Generic.List[string]'
    $kitBackdropFarColor = New-Object 'System.Collections.Generic.List[string]'
    $kitBackdropMidColor = New-Object 'System.Collections.Generic.List[string]'
    $kitBackdropNearColor = New-Object 'System.Collections.Generic.List[string]'
    $kitHorizonAColor = New-Object 'System.Collections.Generic.List[string]'
    $kitHorizonBColor = New-Object 'System.Collections.Generic.List[string]'
    $kitHorizonY = New-Object 'System.Collections.Generic.List[string]'
    $kitWobbleStrength = New-Object 'System.Collections.Generic.List[string]'
    $shotRigModes = @('BaseChase', 'MoveSettle', 'SectorEntry', 'EnemyReveal', 'Interaction', 'WardenPressure', 'EndBeat')
    $kitShotHeight = New-Object 'System.Collections.Generic.List[string]'
    $kitShotDistance = New-Object 'System.Collections.Generic.List[string]'
    $kitShotLookAhead = New-Object 'System.Collections.Generic.List[string]'
    $kitShotPitch = New-Object 'System.Collections.Generic.List[string]'
    $kitShotProjectScale = New-Object 'System.Collections.Generic.List[string]'
    $kitShotHorizon = New-Object 'System.Collections.Generic.List[string]'
    $kitShotFocusBiasX = New-Object 'System.Collections.Generic.List[string]'
    $kitShotFocusBiasZ = New-Object 'System.Collections.Generic.List[string]'
    $kitFrameDoorInset = New-Object 'System.Collections.Generic.List[string]'
    $kitFrameDoorWidth = New-Object 'System.Collections.Generic.List[string]'
    $kitFrameDoorHeight = New-Object 'System.Collections.Generic.List[string]'
    $kitFrameRailInset = New-Object 'System.Collections.Generic.List[string]'
    $kitFrameRailWidth = New-Object 'System.Collections.Generic.List[string]'
    $kitFrameRailHeight = New-Object 'System.Collections.Generic.List[string]'
    $kitFrameCeilingHeight = New-Object 'System.Collections.Generic.List[string]'
    $kitFrameCeilingThickness = New-Object 'System.Collections.Generic.List[string]'
    $kitFrameFarMassInset = New-Object 'System.Collections.Generic.List[string]'
    $kitFrameFarMassWidth = New-Object 'System.Collections.Generic.List[string]'
    $kitFrameFarMassHeight = New-Object 'System.Collections.Generic.List[string]'
    $kitLandmarkMesh = New-Object 'System.Collections.Generic.List[string]'

    $sceneCount = 0
    $sceneGroupCount = 0
    $totalTriangles = 0
    $meshMap = @{}
    $meshTriangleMap = @{}

    $appendGeometry = {
        param(
            [string]$OwnerKind,
            [string]$OwnerKey,
            [object[]]$Vertices,
            [object[]]$Faces
        )

        if ($Vertices.Count -lt 3 -or $Vertices.Count -gt 255) {
            throw ("{0} '{1}' in {2} must define 3..255 vertices. Found {3}." -f $OwnerKind, $OwnerKey, $SourcePath, $Vertices.Count)
        }

        if ($Faces.Count -lt 1) {
            throw ("{0} '{1}' in {2} must define at least one face." -f $OwnerKind, $OwnerKey, $SourcePath)
        }

        $vertexOffset = $payload.Count
        foreach ($vertexIndex in 0..($Vertices.Count - 1)) {
            $vertex = $Vertices[$vertexIndex]
            if (-not ($vertex -is [System.Collections.IDictionary])) {
                throw ("{0} '{1}' vertex {2} in {3} must be a hashtable." -f $OwnerKind, $OwnerKey, $vertexIndex, $SourcePath)
            }

            Add-Int16Payload -Payload $payload -Value (ConvertTo-GeometryFixed88 -Value $vertex['X'] -Context ("{0} '{1}' vertex {2} X" -f $OwnerKind, $OwnerKey, $vertexIndex))
            Add-Int16Payload -Payload $payload -Value (ConvertTo-GeometryFixed88 -Value $vertex['Y'] -Context ("{0} '{1}' vertex {2} Y" -f $OwnerKind, $OwnerKey, $vertexIndex))
            Add-Int16Payload -Payload $payload -Value (ConvertTo-GeometryFixed88 -Value $vertex['Z'] -Context ("{0} '{1}' vertex {2} Z" -f $OwnerKind, $OwnerKey, $vertexIndex))
        }

        $faceOffset = $payload.Count
        $triangleCount = 0
        foreach ($faceIndex in 0..($Faces.Count - 1)) {
            $face = $Faces[$faceIndex]
            if (-not ($face -is [System.Collections.IDictionary])) {
                throw ("{0} '{1}' face {2} in {3} must be a hashtable." -f $OwnerKind, $OwnerKey, $faceIndex, $SourcePath)
            }

            $materialKey = ([string]$face['Material']).ToLowerInvariant()
            if (-not $materialMap.ContainsKey($materialKey)) {
                throw ("{0} '{1}' face {2} in {3} referenced unknown material '{4}'." -f $OwnerKind, $OwnerKey, $faceIndex, $SourcePath, $materialKey)
            }

            $indices = @($face['Indices'])
            if ($indices.Count -lt 3) {
                throw ("{0} '{1}' face {2} in {3} must define at least 3 indices." -f $OwnerKind, $OwnerKey, $faceIndex, $SourcePath)
            }

            $fxToken = ([string]$face['Fx']).Trim().ToLowerInvariant()
            switch ($fxToken) {
                '' { $faceFx = 0 }
                'none' { $faceFx = 0 }
                'pulse_cyan' { $faceFx = 1 }
                'pulse_amber' { $faceFx = 2 }
                'glint' { $faceFx = 3 }
                default { throw ("{0} '{1}' face {2} in {3} referenced unknown Fx token '{4}'." -f $OwnerKind, $OwnerKey, $faceIndex, $SourcePath, $fxToken) }
            }

            $fanBase = [int]$indices[0]
            if ($fanBase -lt 0 -or $fanBase -ge $Vertices.Count) {
                throw ("{0} '{1}' face {2} in {3} referenced vertex index {4} outside 0..{5}." -f $OwnerKind, $OwnerKey, $faceIndex, $SourcePath, $fanBase, ($Vertices.Count - 1))
            }

            for ($triIndex = 1; $triIndex -lt ($indices.Count - 1); $triIndex++) {
                $tri = @($fanBase, [int]$indices[$triIndex], [int]$indices[$triIndex + 1])
                foreach ($corner in $tri) {
                    if ($corner -lt 0 -or $corner -ge $Vertices.Count) {
                        throw ("{0} '{1}' face {2} in {3} referenced vertex index {4} outside 0..{5}." -f $OwnerKind, $OwnerKey, $faceIndex, $SourcePath, $corner, ($Vertices.Count - 1))
                    }
                }

                foreach ($corner in $tri) {
                    $payload.Add([byte]$corner)
                }

                $payload.Add([byte]$materialMap[$materialKey].Base)
                $payload.Add([byte]$materialMap[$materialKey].Dither)
                $payload.Add([byte]$faceFx)
                $triangleCount += 1
            }
        }

        if ($triangleCount -gt 255) {
            throw ("{0} '{1}' in {2} expands to {3} triangles, which exceeds the 255-face table limit." -f $OwnerKind, $OwnerKey, $SourcePath, $triangleCount)
        }

        return [pscustomobject]@{
            VertexOffset = $vertexOffset
            VertexCount = $Vertices.Count
            FaceOffset = $faceOffset
            TriangleCount = $triangleCount
        }
    }

    foreach ($sceneIndex in 0..($scenes.Count - 1)) {
        $scene = $scenes[$sceneIndex]
        if (-not ($scene -is [System.Collections.IDictionary])) {
            throw ("Each geometry scene in {0} must be a hashtable." -f $SourcePath)
        }

        $sceneKey = ([string]$scene['Key']).ToLowerInvariant()
        if ($sceneKey -ne $expectedSceneKeys[$sceneIndex]) {
            throw ("Geometry scene {0} in {1} must use key '{2}' to match the runtime scene order." -f ($sceneIndex + 1), $SourcePath, $expectedSceneKeys[$sceneIndex])
        }

        $camera = $scene['Camera']
        if (-not ($camera -is [System.Collections.IDictionary])) {
            throw ("Geometry scene '{0}' in {1} must define a Camera block." -f $sceneKey, $SourcePath)
        }

        $viewport = $camera['Viewport']
        if (-not ($viewport -is [System.Collections.IDictionary])) {
            throw ("Geometry scene '{0}' in {1} must define a Camera.Viewport block." -f $sceneKey, $SourcePath)
        }

        $sceneSymbol = "SCENE3D_{0}" -f $sceneKey.ToUpperInvariant()
        $cameraX = ConvertTo-GeometryFixed88 -Value $camera['X'] -Context ("Scene '{0}' camera X" -f $sceneKey)
        $cameraY = ConvertTo-GeometryFixed88 -Value $camera['Y'] -Context ("Scene '{0}' camera Y" -f $sceneKey)
        $cameraZ = ConvertTo-GeometryFixed88 -Value $camera['Z'] -Context ("Scene '{0}' camera Z" -f $sceneKey)
        $yawBase = ConvertTo-GeometryAngleByte -Value $camera['YawDegrees'] -Context ("Scene '{0}' yaw" -f $sceneKey)
        $yawStep = ConvertTo-GeometryAngleByte -Value $camera['YawStepDegrees'] -Context ("Scene '{0}' yaw step" -f $sceneKey)
        $pitchBase = ConvertTo-GeometryAngleByte -Value $camera['PitchDegrees'] -Context ("Scene '{0}' pitch" -f $sceneKey)
        $pitchStep = ConvertTo-GeometryAngleByte -Value $camera['PitchStepDegrees'] -Context ("Scene '{0}' pitch step" -f $sceneKey)
        $projectScale = [int]$camera['ProjectScale']
        if ($projectScale -lt 32 -or $projectScale -gt 255) {
            throw ("Scene '{0}' in {1} must keep ProjectScale in the 32..255 range. Found {2}." -f $sceneKey, $SourcePath, $projectScale)
        }

        foreach ($viewportField in @('X', 'Y', 'W', 'H')) {
            if (-not $viewport.ContainsKey($viewportField)) {
                throw ("Scene '{0}' in {1} camera viewport is missing '{2}'." -f $sceneKey, $SourcePath, $viewportField)
            }
        }

        $viewX = [int]$viewport['X']
        $viewY = [int]$viewport['Y']
        $viewW = [int]$viewport['W']
        $viewH = [int]$viewport['H']
        if ($viewW -lt 16 -or $viewH -lt 16) {
            throw ("Scene '{0}' in {1} must keep viewport dimensions >= 16. Found {2}x{3}." -f $sceneKey, $SourcePath, $viewW, $viewH)
        }

        $timelineLength = if ($scene.ContainsKey('TimelineTicks')) { [int]$scene['TimelineTicks'] } else { 64 }
        if ($timelineLength -lt 1 -or $timelineLength -gt 64) {
            throw ("Scene '{0}' in {1} must keep TimelineTicks in the 1..64 range. Found {2}." -f $sceneKey, $SourcePath, $timelineLength)
        }

        $loopTicks = if ($scene.ContainsKey('LoopTicks')) { [int]$scene['LoopTicks'] } else { 0 }
        if ($loopTicks -lt 0 -or $loopTicks -gt $timelineLength) {
            throw ("Scene '{0}' in {1} must keep LoopTicks in the 0..{2} range. Found {3}." -f $sceneKey, $SourcePath, $timelineLength, $loopTicks)
        }

        $signedYawStep = if ($yawStep -gt 127) { $yawStep - 256 } else { $yawStep }
        $signedPitchStep = if ($pitchStep -gt 127) { $pitchStep - 256 } else { $pitchStep }
        for ($sampleIndex = 0; $sampleIndex -lt 64; $sampleIndex++) {
            $effectiveTick = if ($loopTicks -gt 0) { $sampleIndex % $loopTicks } else { [Math]::Min($sampleIndex, ($timelineLength - 1)) }
            $timelineCameraXs.Add((Format-Hex16Literal $cameraX))
            $timelineCameraYs.Add((Format-Hex16Literal $cameraY))
            $timelineCameraZs.Add((Format-Hex16Literal $cameraZ))
            $timelineProjectScales.Add($projectScale.ToString())
            $timelineYaws.Add((($yawBase + ($effectiveTick * $signedYawStep)) -band 0xFF).ToString())
            $timelinePitches.Add((($pitchBase + ($effectiveTick * $signedPitchStep)) -band 0xFF).ToString())
        }

        if ($scene.ContainsKey('Groups')) {
            $sceneGroups = @($scene['Groups'])
        } else {
            $sceneGroups = @([ordered]@{
                Key = 'main'
                Vertices = $scene['Vertices']
                Faces = $scene['Faces']
                StartTick = 0
                EndTick = ($timelineLength - 1)
                MotionTicks = 0
                Offset = @{}
                OffsetStep = @{}
                YawDegrees = 0.0
                YawStepDegrees = 0.0
            })
        }

        if ($sceneGroups.Count -eq 0) {
            throw ("Geometry scene '{0}' in {1} must define at least one mesh group." -f $sceneKey, $SourcePath)
        }

        $sceneTimelineLengths.Add($timelineLength.ToString())
        $sceneTimelineLoops.Add($loopTicks.ToString())
        $sceneGroupStarts.Add($sceneGroupCount.ToString())
        $sceneGroupCounts.Add($sceneGroups.Count.ToString())

        $sceneVertexOffset = 0
        $sceneFaceOffset = 0
        $sceneVertexCount = 0
        $sceneTriangleCount = 0
        for ($groupIndex = 0; $groupIndex -lt $sceneGroups.Count; $groupIndex++) {
            $group = $sceneGroups[$groupIndex]
            if (-not ($group -is [System.Collections.IDictionary])) {
                throw ("Geometry scene '{0}' group {1} in {2} must be a hashtable." -f $sceneKey, ($groupIndex + 1), $SourcePath)
            }

            $groupKey = if ($group.Contains('Key') -and -not [string]::IsNullOrWhiteSpace([string]$group['Key'])) { [string]$group['Key'] } else { "group{0}" -f ($groupIndex + 1) }
            $groupVertices = @($group['Vertices'])
            $groupFaces = @($group['Faces'])
            if ($groupVertices.Count -eq 0 -or $groupFaces.Count -eq 0) {
                throw ("Geometry scene '{0}' group '{1}' in {2} must define Vertices and Faces." -f $sceneKey, $groupKey, $SourcePath)
            }

            $packedGroup = & $appendGeometry -OwnerKind 'Geometry scene group' -OwnerKey ("{0}/{1}" -f $sceneKey, $groupKey) -Vertices $groupVertices -Faces $groupFaces
            if ($groupIndex -eq 0) {
                $sceneVertexOffset = $packedGroup.VertexOffset
                $sceneFaceOffset = $packedGroup.FaceOffset
            }

            $sceneVertexCount += $groupVertices.Count
            $sceneTriangleCount += $packedGroup.TriangleCount

            $groupStartTick = if ($group.Contains('StartTick')) { [int]$group['StartTick'] } else { 0 }
            $groupEndTick = if ($group.Contains('EndTick')) { [int]$group['EndTick'] } else { ($timelineLength - 1) }
            $groupMotionTicks = if ($group.Contains('MotionTicks')) { [int]$group['MotionTicks'] } else { 0 }
            if ($groupStartTick -lt 0 -or $groupStartTick -ge $timelineLength) {
                throw ("Geometry scene '{0}' group '{1}' in {2} must keep StartTick in the 0..{3} range. Found {4}." -f $sceneKey, $groupKey, $SourcePath, ($timelineLength - 1), $groupStartTick)
            }

            if ($groupEndTick -lt $groupStartTick -or $groupEndTick -ge $timelineLength) {
                throw ("Geometry scene '{0}' group '{1}' in {2} must keep EndTick in the {3}..{4} range. Found {5}." -f $sceneKey, $groupKey, $SourcePath, $groupStartTick, ($timelineLength - 1), $groupEndTick)
            }

            if ($groupMotionTicks -lt 0 -or $groupMotionTicks -gt $timelineLength) {
                throw ("Geometry scene '{0}' group '{1}' in {2} must keep MotionTicks in the 0..{3} range. Found {4}." -f $sceneKey, $groupKey, $SourcePath, $timelineLength, $groupMotionTicks)
            }

            $groupOffset = if ($group.Contains('Offset') -and ($group['Offset'] -is [System.Collections.IDictionary])) { $group['Offset'] } else { @{} }
            $groupOffsetStep = if ($group.Contains('OffsetStep') -and ($group['OffsetStep'] -is [System.Collections.IDictionary])) { $group['OffsetStep'] } else { @{} }
            $groupOffsetX = if ($groupOffset.Contains('X')) { ConvertTo-GeometryFixed88 -Value $groupOffset['X'] -Context ("Scene '{0}' group '{1}' offset X" -f $sceneKey, $groupKey) } else { 0 }
            $groupOffsetY = if ($groupOffset.Contains('Y')) { ConvertTo-GeometryFixed88 -Value $groupOffset['Y'] -Context ("Scene '{0}' group '{1}' offset Y" -f $sceneKey, $groupKey) } else { 0 }
            $groupOffsetZ = if ($groupOffset.Contains('Z')) { ConvertTo-GeometryFixed88 -Value $groupOffset['Z'] -Context ("Scene '{0}' group '{1}' offset Z" -f $sceneKey, $groupKey) } else { 0 }
            $groupOffsetXStep = if ($groupOffsetStep.Contains('X')) { ConvertTo-GeometryFixed88 -Value $groupOffsetStep['X'] -Context ("Scene '{0}' group '{1}' offset-step X" -f $sceneKey, $groupKey) } else { 0 }
            $groupOffsetYStep = if ($groupOffsetStep.Contains('Y')) { ConvertTo-GeometryFixed88 -Value $groupOffsetStep['Y'] -Context ("Scene '{0}' group '{1}' offset-step Y" -f $sceneKey, $groupKey) } else { 0 }
            $groupOffsetZStep = if ($groupOffsetStep.Contains('Z')) { ConvertTo-GeometryFixed88 -Value $groupOffsetStep['Z'] -Context ("Scene '{0}' group '{1}' offset-step Z" -f $sceneKey, $groupKey) } else { 0 }
            $groupYawBase = if ($group.Contains('YawDegrees')) { ConvertTo-GeometryAngleByte -Value $group['YawDegrees'] -Context ("Scene '{0}' group '{1}' yaw" -f $sceneKey, $groupKey) } else { 0 }
            $groupYawStep = if ($group.Contains('YawStepDegrees')) { ConvertTo-GeometryAngleByte -Value $group['YawStepDegrees'] -Context ("Scene '{0}' group '{1}' yaw step" -f $sceneKey, $groupKey) } else { 0 }

            $sceneGroupVertexOffsets.Add($packedGroup.VertexOffset.ToString())
            $sceneGroupVertexCounts.Add($groupVertices.Count.ToString())
            $sceneGroupFaceOffsets.Add($packedGroup.FaceOffset.ToString())
            $sceneGroupFaceCounts.Add($packedGroup.TriangleCount.ToString())
            $sceneGroupStartTicks.Add($groupStartTick.ToString())
            $sceneGroupEndTicks.Add($groupEndTick.ToString())
            $sceneGroupMotionTicks.Add($groupMotionTicks.ToString())
            $sceneGroupOffsetXs.Add((Format-Hex16Literal $groupOffsetX))
            $sceneGroupOffsetYs.Add((Format-Hex16Literal $groupOffsetY))
            $sceneGroupOffsetZs.Add((Format-Hex16Literal $groupOffsetZ))
            $sceneGroupOffsetXSteps.Add((Format-Hex16Literal $groupOffsetXStep))
            $sceneGroupOffsetYSteps.Add((Format-Hex16Literal $groupOffsetYStep))
            $sceneGroupOffsetZSteps.Add((Format-Hex16Literal $groupOffsetZStep))
            $sceneGroupYawBases.Add($groupYawBase.ToString())
            $sceneGroupYawSteps.Add($groupYawStep.ToString())
            $sceneGroupCount += 1
        }

        $lines.Add(("{0}_INDEX EQU {1}" -f $sceneSymbol, $sceneIndex))
        $lines.Add(("{0}_VERTEX_OFFSET EQU {1}" -f $sceneSymbol, $sceneVertexOffset))
        $lines.Add(("{0}_VERTEX_COUNT EQU {1}" -f $sceneSymbol, $sceneVertexCount))
        $lines.Add(("{0}_FACE_OFFSET EQU {1}" -f $sceneSymbol, $sceneFaceOffset))
        $lines.Add(("{0}_FACE_COUNT EQU {1}" -f $sceneSymbol, $sceneTriangleCount))
        $lines.Add(("{0}_VIEW_X EQU {1}" -f $sceneSymbol, $viewX))
        $lines.Add(("{0}_VIEW_Y EQU {1}" -f $sceneSymbol, $viewY))
        $lines.Add(("{0}_VIEW_W EQU {1}" -f $sceneSymbol, $viewW))
        $lines.Add(("{0}_VIEW_H EQU {1}" -f $sceneSymbol, $viewH))
        $lines.Add(("{0}_CAMERA_X EQU {1}" -f $sceneSymbol, (Format-Hex16Literal $cameraX)))
        $lines.Add(("{0}_CAMERA_Y EQU {1}" -f $sceneSymbol, (Format-Hex16Literal $cameraY)))
        $lines.Add(("{0}_CAMERA_Z EQU {1}" -f $sceneSymbol, (Format-Hex16Literal $cameraZ)))
        $lines.Add(("{0}_YAW_BASE EQU {1}" -f $sceneSymbol, $yawBase))
        $lines.Add(("{0}_YAW_STEP EQU {1}" -f $sceneSymbol, $yawStep))
        $lines.Add(("{0}_PITCH_BASE EQU {1}" -f $sceneSymbol, $pitchBase))
        $lines.Add(("{0}_PITCH_STEP EQU {1}" -f $sceneSymbol, $pitchStep))
        $lines.Add(("{0}_PROJECT_SCALE EQU {1}" -f $sceneSymbol, $projectScale))
        $lines.Add('')

        $sceneVertexOffsets.Add($sceneVertexOffset.ToString())
        $sceneVertexCounts.Add($sceneVertexCount.ToString())
        $sceneFaceOffsets.Add($sceneFaceOffset.ToString())
        $sceneFaceCounts.Add($sceneTriangleCount.ToString())
        $sceneViewportXs.Add($viewX.ToString())
        $sceneViewportYs.Add($viewY.ToString())
        $sceneViewportWs.Add($viewW.ToString())
        $sceneViewportHs.Add($viewH.ToString())
        $sceneCameraXs.Add((Format-Hex16Literal $cameraX))
        $sceneCameraYs.Add((Format-Hex16Literal $cameraY))
        $sceneCameraZs.Add((Format-Hex16Literal $cameraZ))
        $sceneYawBases.Add($yawBase.ToString())
        $sceneYawSteps.Add($yawStep.ToString())
        $scenePitchBases.Add($pitchBase.ToString())
        $scenePitchSteps.Add($pitchStep.ToString())
        $sceneProjectScales.Add($projectScale.ToString())
        $loopSuffix = if ($loopTicks -gt 0) { "/loop $loopTicks" } else { '' }
        $sceneSummary.Add(("{0}: {1} groups, {2} ticks{3}, {4} verts, {5} tris, view {6}x{7}+{8},{9}" -f $sceneKey, $sceneGroups.Count, $timelineLength, $loopSuffix, $sceneVertexCount, $sceneTriangleCount, $viewW, $viewH, $viewX, $viewY))
        $sceneFaceSummary.Add(("{0}={1}t/{2}g" -f $sceneKey, $sceneTriangleCount, $sceneGroups.Count))
        $sceneCount += 1
        $totalTriangles += $sceneTriangleCount
    }

    foreach ($meshIndex in 0..($meshes.Count - 1)) {
        $mesh = $meshes[$meshIndex]
        if (-not ($mesh -is [System.Collections.IDictionary])) {
            throw ("Each geometry mesh in {0} must be a hashtable." -f $SourcePath)
        }

        $meshKey = ([string]$mesh['Key']).ToLowerInvariant()
        if ([string]::IsNullOrWhiteSpace($meshKey) -or $meshKey -notmatch '^[a-z0-9_]+$') {
            throw ("Geometry mesh keys in {0} must be lowercase alphanumeric identifiers with underscores. Found '{1}'." -f $SourcePath, $meshKey)
        }

        if ($meshMap.ContainsKey($meshKey)) {
            throw ("Geometry mesh '{0}' is defined more than once in {1}." -f $meshKey, $SourcePath)
        }

        $vertices = @($mesh['Vertices'])
        $faces = @($mesh['Faces'])
        $packedMesh = & $appendGeometry -OwnerKind 'Geometry mesh' -OwnerKey $meshKey -Vertices $vertices -Faces $faces
        $meshSymbol = "GAME3D_MESH_{0}" -f $meshKey.ToUpperInvariant()
        $lines.Add(("{0}_INDEX EQU {1}" -f $meshSymbol, $meshIndex))
        $lines.Add(("{0}_VERTEX_OFFSET EQU {1}" -f $meshSymbol, $packedMesh.VertexOffset))
        $lines.Add(("{0}_VERTEX_COUNT EQU {1}" -f $meshSymbol, $packedMesh.VertexCount))
        $lines.Add(("{0}_FACE_OFFSET EQU {1}" -f $meshSymbol, $packedMesh.FaceOffset))
        $lines.Add(("{0}_FACE_COUNT EQU {1}" -f $meshSymbol, $packedMesh.TriangleCount))
        $lines.Add('')

        $meshVertexOffsets.Add($packedMesh.VertexOffset.ToString())
        $meshVertexCounts.Add($packedMesh.VertexCount.ToString())
        $meshFaceOffsets.Add($packedMesh.FaceOffset.ToString())
        $meshFaceCounts.Add($packedMesh.TriangleCount.ToString())
        $meshSummary.Add(("{0}:{1} tris" -f $meshKey, $packedMesh.TriangleCount))
        $meshMap[$meshKey] = [pscustomobject]@{
            Index = $meshIndex
            TriangleCount = $packedMesh.TriangleCount
        }
        $meshTriangleMap[$meshKey] = $packedMesh.TriangleCount
        $totalTriangles += $packedMesh.TriangleCount
    }

    foreach ($kitIndex in 0..($kits.Count - 1)) {
        $kit = $kits[$kitIndex]
        if (-not ($kit -is [System.Collections.IDictionary])) {
            throw ("Each geometry gameplay kit in {0} must be a hashtable." -f $SourcePath)
        }

        $kitKey = ([string]$kit['Key']).ToLowerInvariant()
        if ($kitKey -ne $expectedKitKeys[$kitIndex]) {
            throw ("Geometry gameplay kit {0} in {1} must use key '{2}' to match the runtime sector order." -f ($kitIndex + 1), $SourcePath, $expectedKitKeys[$kitIndex])
        }

        $materialFields = @('FloorBase', 'FloorTrim', 'WallBase', 'WallTrim', 'WallCap', 'Lane')
        $materialRefs = @{}
        foreach ($field in $materialFields) {
            $materialKey = ([string]$kit[$field]).ToLowerInvariant()
            if ([string]::IsNullOrWhiteSpace($materialKey) -or -not $materialMap.ContainsKey($materialKey)) {
                throw ("Gameplay kit '{0}' in {1} must reference a known material for '{2}'." -f $kitKey, $SourcePath, $field)
            }

            $materialRefs[$field] = $materialMap[$materialKey]
        }

        $meshFields = @('GateMesh', 'TerminalMesh', 'SurgeMesh', 'ShardMesh')
        $meshRefs = @{}
        foreach ($field in $meshFields) {
            $meshKey = ([string]$kit[$field]).ToLowerInvariant()
            if ([string]::IsNullOrWhiteSpace($meshKey) -or -not $meshMap.ContainsKey($meshKey)) {
                throw ("Gameplay kit '{0}' in {1} must reference a known mesh for '{2}'." -f $kitKey, $SourcePath, $field)
            }

            $meshRefs[$field] = $meshMap[$meshKey]
        }

        $camera = $kit['Camera']
        if (-not ($camera -is [System.Collections.IDictionary])) {
            throw ("Gameplay kit '{0}' in {1} must define a Camera block." -f $kitKey, $SourcePath)
        }

        foreach ($cameraField in @('Height', 'Distance', 'LookAhead', 'HeadingNorthYawDegrees', 'HeadingEastYawDegrees', 'HeadingSouthYawDegrees', 'HeadingWestYawDegrees')) {
            if (-not $camera.ContainsKey($cameraField)) {
                throw ("Gameplay kit '{0}' in {1} camera is missing '{2}'." -f $kitKey, $SourcePath, $cameraField)
            }
        }

        $projection = $kit['Projection']
        if (-not ($projection -is [System.Collections.IDictionary])) {
            throw ("Gameplay kit '{0}' in {1} must define a Projection block." -f $kitKey, $SourcePath)
        }

        foreach ($projectionField in @('PitchDegrees', 'ProjectScale')) {
            if (-not $projection.ContainsKey($projectionField)) {
                throw ("Gameplay kit '{0}' in {1} projection is missing '{2}'." -f $kitKey, $SourcePath, $projectionField)
            }
        }

        $structure = $kit['Structure']
        if (-not ($structure -is [System.Collections.IDictionary])) {
            throw ("Gameplay kit '{0}' in {1} must define a Structure block." -f $kitKey, $SourcePath)
        }

        foreach ($structureField in @('NearInset', 'NearWidth', 'NearHeight', 'FarInset', 'FarHeight')) {
            if (-not $structure.ContainsKey($structureField)) {
                throw ("Gameplay kit '{0}' in {1} structure is missing '{2}'." -f $kitKey, $SourcePath, $structureField)
            }
        }

        $shotRigs = $kit['ShotRigs']
        if (-not ($shotRigs -is [System.Collections.IDictionary])) {
            throw ("Gameplay kit '{0}' in {1} must define a ShotRigs block." -f $kitKey, $SourcePath)
        }

        foreach ($shotMode in $shotRigModes) {
            if (-not $shotRigs.ContainsKey($shotMode) -or -not ($shotRigs[$shotMode] -is [System.Collections.IDictionary])) {
                throw ("Gameplay kit '{0}' in {1} must define ShotRigs.{2} as a block." -f $kitKey, $SourcePath, $shotMode)
            }

            foreach ($shotField in @('Height', 'Distance', 'LookAhead', 'PitchDegrees', 'ProjectScale', 'Horizon', 'FocusBiasX', 'FocusBiasZ')) {
                if (-not $shotRigs[$shotMode].ContainsKey($shotField)) {
                    throw ("Gameplay kit '{0}' in {1} shot rig '{2}' is missing '{3}'." -f $kitKey, $SourcePath, $shotMode, $shotField)
                }
            }
        }

        $framing = $kit['Framing']
        if (-not ($framing -is [System.Collections.IDictionary])) {
            throw ("Gameplay kit '{0}' in {1} must define a Framing block." -f $kitKey, $SourcePath)
        }

        foreach ($framingField in @('DoorFrameInset', 'DoorFrameWidth', 'DoorFrameHeight', 'RailInset', 'RailWidth', 'RailHeight', 'CeilingBeamHeight', 'CeilingBeamThickness', 'FarMassInset', 'FarMassWidth', 'FarMassHeight')) {
            if (-not $framing.ContainsKey($framingField)) {
                throw ("Gameplay kit '{0}' in {1} framing is missing '{2}'." -f $kitKey, $SourcePath, $framingField)
            }
        }

        $landmark = $kit['Landmark']
        if (-not ($landmark -is [System.Collections.IDictionary])) {
            throw ("Gameplay kit '{0}' in {1} must define a Landmark block." -f $kitKey, $SourcePath)
        }
        if (-not $landmark.ContainsKey('Mesh')) {
            throw ("Gameplay kit '{0}' in {1} landmark is missing 'Mesh'." -f $kitKey, $SourcePath)
        }

        $atmosphere = $kit['Atmosphere']
        if (-not ($atmosphere -is [System.Collections.IDictionary])) {
            throw ("Gameplay kit '{0}' in {1} must define an Atmosphere block." -f $kitKey, $SourcePath)
        }

        foreach ($atmosphereField in @('BackdropFar', 'BackdropMid', 'BackdropNear', 'HorizonA', 'HorizonB', 'HorizonY', 'WobbleStrength')) {
            if (-not $atmosphere.ContainsKey($atmosphereField)) {
                throw ("Gameplay kit '{0}' in {1} atmosphere is missing '{2}'." -f $kitKey, $SourcePath, $atmosphereField)
            }
        }

        $cameraHeight = ConvertTo-GeometryFixed88 -Value $camera['Height'] -Context ("Gameplay kit '{0}' camera Height" -f $kitKey)
        $cameraDistance = ConvertTo-GeometryFixed88 -Value $camera['Distance'] -Context ("Gameplay kit '{0}' camera Distance" -f $kitKey)
        $cameraLookAhead = ConvertTo-GeometryFixed88 -Value $camera['LookAhead'] -Context ("Gameplay kit '{0}' camera LookAhead" -f $kitKey)
        $cameraNorthYaw = ConvertTo-GeometryAngleByte -Value $camera['HeadingNorthYawDegrees'] -Context ("Gameplay kit '{0}' north yaw" -f $kitKey)
        $cameraEastYaw = ConvertTo-GeometryAngleByte -Value $camera['HeadingEastYawDegrees'] -Context ("Gameplay kit '{0}' east yaw" -f $kitKey)
        $cameraSouthYaw = ConvertTo-GeometryAngleByte -Value $camera['HeadingSouthYawDegrees'] -Context ("Gameplay kit '{0}' south yaw" -f $kitKey)
        $cameraWestYaw = ConvertTo-GeometryAngleByte -Value $camera['HeadingWestYawDegrees'] -Context ("Gameplay kit '{0}' west yaw" -f $kitKey)
        $projectionPitch = ConvertTo-GeometryAngleByte -Value $projection['PitchDegrees'] -Context ("Gameplay kit '{0}' projection pitch" -f $kitKey)
        $projectionScale = [int]$projection['ProjectScale']
        if ($projectionScale -lt 48 -or $projectionScale -gt 160) {
            throw ("Gameplay kit '{0}' in {1} must keep Projection.ProjectScale in the 48..160 range. Found {2}." -f $kitKey, $SourcePath, $projectionScale)
        }
        $nearOccluderInset = ConvertTo-GeometryFixed88 -Value $structure['NearInset'] -Context ("Gameplay kit '{0}' structure NearInset" -f $kitKey)
        $nearOccluderWidth = ConvertTo-GeometryFixed88 -Value $structure['NearWidth'] -Context ("Gameplay kit '{0}' structure NearWidth" -f $kitKey)
        $nearOccluderHeight = ConvertTo-GeometryFixed88 -Value $structure['NearHeight'] -Context ("Gameplay kit '{0}' structure NearHeight" -f $kitKey)
        $farSilhouetteInset = ConvertTo-GeometryFixed88 -Value $structure['FarInset'] -Context ("Gameplay kit '{0}' structure FarInset" -f $kitKey)
        $farSilhouetteHeight = ConvertTo-GeometryFixed88 -Value $structure['FarHeight'] -Context ("Gameplay kit '{0}' structure FarHeight" -f $kitKey)
        $doorFrameInset = ConvertTo-GeometryFixed88 -Value $framing['DoorFrameInset'] -Context ("Gameplay kit '{0}' framing DoorFrameInset" -f $kitKey)
        $doorFrameWidth = ConvertTo-GeometryFixed88 -Value $framing['DoorFrameWidth'] -Context ("Gameplay kit '{0}' framing DoorFrameWidth" -f $kitKey)
        $doorFrameHeight = ConvertTo-GeometryFixed88 -Value $framing['DoorFrameHeight'] -Context ("Gameplay kit '{0}' framing DoorFrameHeight" -f $kitKey)
        $railInset = ConvertTo-GeometryFixed88 -Value $framing['RailInset'] -Context ("Gameplay kit '{0}' framing RailInset" -f $kitKey)
        $railWidth = ConvertTo-GeometryFixed88 -Value $framing['RailWidth'] -Context ("Gameplay kit '{0}' framing RailWidth" -f $kitKey)
        $railHeight = ConvertTo-GeometryFixed88 -Value $framing['RailHeight'] -Context ("Gameplay kit '{0}' framing RailHeight" -f $kitKey)
        $ceilingBeamHeight = ConvertTo-GeometryFixed88 -Value $framing['CeilingBeamHeight'] -Context ("Gameplay kit '{0}' framing CeilingBeamHeight" -f $kitKey)
        $ceilingBeamThickness = ConvertTo-GeometryFixed88 -Value $framing['CeilingBeamThickness'] -Context ("Gameplay kit '{0}' framing CeilingBeamThickness" -f $kitKey)
        $farMassInset = ConvertTo-GeometryFixed88 -Value $framing['FarMassInset'] -Context ("Gameplay kit '{0}' framing FarMassInset" -f $kitKey)
        $farMassWidth = ConvertTo-GeometryFixed88 -Value $framing['FarMassWidth'] -Context ("Gameplay kit '{0}' framing FarMassWidth" -f $kitKey)
        $farMassHeight = ConvertTo-GeometryFixed88 -Value $framing['FarMassHeight'] -Context ("Gameplay kit '{0}' framing FarMassHeight" -f $kitKey)
        $landmarkMeshKey = ([string]$landmark['Mesh']).ToLowerInvariant()
        if ([string]::IsNullOrWhiteSpace($landmarkMeshKey) -or -not $meshMap.ContainsKey($landmarkMeshKey)) {
            throw ("Gameplay kit '{0}' in {1} must reference a known mesh for Landmark.Mesh." -f $kitKey, $SourcePath)
        }

        $horizonY = [int]$atmosphere['HorizonY']
        if ($horizonY -lt 12 -or $horizonY -gt 84) {
            throw ("Gameplay kit '{0}' in {1} must keep Atmosphere.HorizonY in the 12..84 range. Found {2}." -f $kitKey, $SourcePath, $horizonY)
        }

        $wobbleStrength = [int]$atmosphere['WobbleStrength']
        if ($wobbleStrength -lt 0 -or $wobbleStrength -gt 3) {
            throw ("Gameplay kit '{0}' in {1} must keep Atmosphere.WobbleStrength in the 0..3 range. Found {2}." -f $kitKey, $SourcePath, $wobbleStrength)
        }

        $backdropFar = ConvertTo-GeometryPaletteSymbol -Value $atmosphere['BackdropFar'] -Context ("Gameplay kit '{0}' BackdropFar" -f $kitKey)
        $backdropMid = ConvertTo-GeometryPaletteSymbol -Value $atmosphere['BackdropMid'] -Context ("Gameplay kit '{0}' BackdropMid" -f $kitKey)
        $backdropNear = ConvertTo-GeometryPaletteSymbol -Value $atmosphere['BackdropNear'] -Context ("Gameplay kit '{0}' BackdropNear" -f $kitKey)
        $horizonA = ConvertTo-GeometryPaletteSymbol -Value $atmosphere['HorizonA'] -Context ("Gameplay kit '{0}' HorizonA" -f $kitKey)
        $horizonB = ConvertTo-GeometryPaletteSymbol -Value $atmosphere['HorizonB'] -Context ("Gameplay kit '{0}' HorizonB" -f $kitKey)

        $kitSymbol = "GAME3D_KIT_{0}" -f $kitKey.ToUpperInvariant()
        $lines.Add(("{0}_INDEX EQU {1}" -f $kitSymbol, $kitIndex))
        $lines.Add('')

        $kitFloorBaseColor.Add($materialRefs['FloorBase'].Base.ToString())
        $kitFloorBaseDither.Add($materialRefs['FloorBase'].Dither.ToString())
        $kitFloorTrimColor.Add($materialRefs['FloorTrim'].Base.ToString())
        $kitFloorTrimDither.Add($materialRefs['FloorTrim'].Dither.ToString())
        $kitWallBaseColor.Add($materialRefs['WallBase'].Base.ToString())
        $kitWallBaseDither.Add($materialRefs['WallBase'].Dither.ToString())
        $kitWallTrimColor.Add($materialRefs['WallTrim'].Base.ToString())
        $kitWallTrimDither.Add($materialRefs['WallTrim'].Dither.ToString())
        $kitWallCapColor.Add($materialRefs['WallCap'].Base.ToString())
        $kitWallCapDither.Add($materialRefs['WallCap'].Dither.ToString())
        $kitLaneColor.Add($materialRefs['Lane'].Base.ToString())
        $kitLaneDither.Add($materialRefs['Lane'].Dither.ToString())
        $kitGateMesh.Add($meshRefs['GateMesh'].Index.ToString())
        $kitTerminalMesh.Add($meshRefs['TerminalMesh'].Index.ToString())
        $kitSurgeMesh.Add($meshRefs['SurgeMesh'].Index.ToString())
        $kitShardMesh.Add($meshRefs['ShardMesh'].Index.ToString())
        $kitCameraHeight.Add((Format-Hex16Literal $cameraHeight))
        $kitCameraDistance.Add((Format-Hex16Literal $cameraDistance))
        $kitCameraLookAhead.Add((Format-Hex16Literal $cameraLookAhead))
        $kitCameraNorthYaw.Add($cameraNorthYaw.ToString())
        $kitCameraEastYaw.Add($cameraEastYaw.ToString())
        $kitCameraSouthYaw.Add($cameraSouthYaw.ToString())
        $kitCameraWestYaw.Add($cameraWestYaw.ToString())
        $kitProjectionPitch.Add($projectionPitch.ToString())
        $kitProjectionScale.Add($projectionScale.ToString())
        $kitNearOccluderInset.Add((Format-Hex16Literal $nearOccluderInset))
        $kitNearOccluderWidth.Add((Format-Hex16Literal $nearOccluderWidth))
        $kitNearOccluderHeight.Add((Format-Hex16Literal $nearOccluderHeight))
        $kitFarSilhouetteInset.Add((Format-Hex16Literal $farSilhouetteInset))
        $kitFarSilhouetteHeight.Add((Format-Hex16Literal $farSilhouetteHeight))
        $kitBackdropFarColor.Add($backdropFar)
        $kitBackdropMidColor.Add($backdropMid)
        $kitBackdropNearColor.Add($backdropNear)
        $kitHorizonAColor.Add($horizonA)
        $kitHorizonBColor.Add($horizonB)
        $kitHorizonY.Add($horizonY.ToString())
        $kitWobbleStrength.Add($wobbleStrength.ToString())
        foreach ($shotMode in $shotRigModes) {
            $shotRig = $shotRigs[$shotMode]
            $shotPitch = ConvertTo-GeometryAngleByte -Value $shotRig['PitchDegrees'] -Context ("Gameplay kit '{0}' {1} pitch" -f $kitKey, $shotMode)
            $shotProjectScale = [int]$shotRig['ProjectScale']
            if ($shotProjectScale -lt 48 -or $shotProjectScale -gt 160) {
                throw ("Gameplay kit '{0}' in {1} must keep ShotRigs.{2}.ProjectScale in the 48..160 range. Found {3}." -f $kitKey, $SourcePath, $shotMode, $shotProjectScale)
            }

            $shotHorizon = [int]$shotRig['Horizon']
            if ($shotHorizon -lt 12 -or $shotHorizon -gt 84) {
                throw ("Gameplay kit '{0}' in {1} must keep ShotRigs.{2}.Horizon in the 12..84 range. Found {3}." -f $kitKey, $SourcePath, $shotMode, $shotHorizon)
            }

            $kitShotHeight.Add((Format-Hex16Literal (ConvertTo-GeometryFixed88 -Value $shotRig['Height'] -Context ("Gameplay kit '{0}' {1} Height" -f $kitKey, $shotMode))))
            $kitShotDistance.Add((Format-Hex16Literal (ConvertTo-GeometryFixed88 -Value $shotRig['Distance'] -Context ("Gameplay kit '{0}' {1} Distance" -f $kitKey, $shotMode))))
            $kitShotLookAhead.Add((Format-Hex16Literal (ConvertTo-GeometryFixed88 -Value $shotRig['LookAhead'] -Context ("Gameplay kit '{0}' {1} LookAhead" -f $kitKey, $shotMode))))
            $kitShotPitch.Add($shotPitch.ToString())
            $kitShotProjectScale.Add($shotProjectScale.ToString())
            $kitShotHorizon.Add($shotHorizon.ToString())
            $kitShotFocusBiasX.Add((Format-Hex16Literal (ConvertTo-GeometryFixed88 -Value $shotRig['FocusBiasX'] -Context ("Gameplay kit '{0}' {1} FocusBiasX" -f $kitKey, $shotMode))))
            $kitShotFocusBiasZ.Add((Format-Hex16Literal (ConvertTo-GeometryFixed88 -Value $shotRig['FocusBiasZ'] -Context ("Gameplay kit '{0}' {1} FocusBiasZ" -f $kitKey, $shotMode))))
        }

        $kitFrameDoorInset.Add((Format-Hex16Literal $doorFrameInset))
        $kitFrameDoorWidth.Add((Format-Hex16Literal $doorFrameWidth))
        $kitFrameDoorHeight.Add((Format-Hex16Literal $doorFrameHeight))
        $kitFrameRailInset.Add((Format-Hex16Literal $railInset))
        $kitFrameRailWidth.Add((Format-Hex16Literal $railWidth))
        $kitFrameRailHeight.Add((Format-Hex16Literal $railHeight))
        $kitFrameCeilingHeight.Add((Format-Hex16Literal $ceilingBeamHeight))
        $kitFrameCeilingThickness.Add((Format-Hex16Literal $ceilingBeamThickness))
        $kitFrameFarMassInset.Add((Format-Hex16Literal $farMassInset))
        $kitFrameFarMassWidth.Add((Format-Hex16Literal $farMassWidth))
        $kitFrameFarMassHeight.Add((Format-Hex16Literal $farMassHeight))
        $kitLandmarkMesh.Add($meshMap[$landmarkMeshKey].Index.ToString())

        $kitSummary.Add(("{0}: cam h={1} d={2} look={3}, proj p={4} s={5}, horizon={6}, landmark={7}, wobble={8}, props {9}|{10}|{11}|{12}" -f $kitKey, $camera['Height'], $camera['Distance'], $camera['LookAhead'], $projection['PitchDegrees'], $projectionScale, $horizonY, $landmark['Mesh'], $wobbleStrength, $kit['GateMesh'], $kit['TerminalMesh'], $kit['SurgeMesh'], $kit['ShardMesh']))
    }

    $lines.Add(("SCENE3D_COUNT EQU {0}" -f $sceneCount))
    $lines.Add(("SCENE3D_GROUP_COUNT EQU {0}" -f $sceneGroupCount))
    $lines.Add(("SCENE3D_MATERIAL_COUNT EQU {0}" -f $materials.Count))
    $lines.Add(("GAME3D_MESH_COUNT EQU {0}" -f $meshes.Count))
    $lines.Add(("GAME3D_KIT_COUNT EQU {0}" -f $kits.Count))
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_vertex_offset_table' -Directive 'dw' -Values $sceneVertexOffsets.ToArray() -ValuesPerLine 4
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_vertex_count_table' -Directive 'db' -Values $sceneVertexCounts.ToArray() -ValuesPerLine 8
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_face_offset_table' -Directive 'dw' -Values $sceneFaceOffsets.ToArray() -ValuesPerLine 4
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_face_count_table' -Directive 'db' -Values $sceneFaceCounts.ToArray() -ValuesPerLine 8
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_view_x_table' -Directive 'dw' -Values $sceneViewportXs.ToArray() -ValuesPerLine 4
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_view_y_table' -Directive 'dw' -Values $sceneViewportYs.ToArray() -ValuesPerLine 4
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_view_w_table' -Directive 'dw' -Values $sceneViewportWs.ToArray() -ValuesPerLine 4
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_view_h_table' -Directive 'dw' -Values $sceneViewportHs.ToArray() -ValuesPerLine 4
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_camera_x_table' -Directive 'dw' -Values $sceneCameraXs.ToArray() -ValuesPerLine 4
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_camera_y_table' -Directive 'dw' -Values $sceneCameraYs.ToArray() -ValuesPerLine 4
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_camera_z_table' -Directive 'dw' -Values $sceneCameraZs.ToArray() -ValuesPerLine 4
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_yaw_base_table' -Directive 'db' -Values $sceneYawBases.ToArray() -ValuesPerLine 8
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_yaw_step_table' -Directive 'db' -Values $sceneYawSteps.ToArray() -ValuesPerLine 8
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_pitch_base_table' -Directive 'db' -Values $scenePitchBases.ToArray() -ValuesPerLine 8
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_pitch_step_table' -Directive 'db' -Values $scenePitchSteps.ToArray() -ValuesPerLine 8
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_project_scale_table' -Directive 'dw' -Values $sceneProjectScales.ToArray() -ValuesPerLine 4
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_timeline_length_table' -Directive 'db' -Values $sceneTimelineLengths.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'scene3d_timeline_loop_table' -Directive 'db' -Values $sceneTimelineLoops.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'scene3d_group_start_table' -Directive 'db' -Values $sceneGroupStarts.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'scene3d_group_count_table' -Directive 'db' -Values $sceneGroupCounts.ToArray() -ValuesPerLine 8
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_group_vertex_offset_table' -Directive 'dw' -Values $sceneGroupVertexOffsets.ToArray() -ValuesPerLine 4
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_group_vertex_count_table' -Directive 'db' -Values $sceneGroupVertexCounts.ToArray() -ValuesPerLine 8
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_group_face_offset_table' -Directive 'dw' -Values $sceneGroupFaceOffsets.ToArray() -ValuesPerLine 4
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_group_face_count_table' -Directive 'db' -Values $sceneGroupFaceCounts.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'scene3d_group_start_tick_table' -Directive 'db' -Values $sceneGroupStartTicks.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'scene3d_group_end_tick_table' -Directive 'db' -Values $sceneGroupEndTicks.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'scene3d_group_motion_ticks_table' -Directive 'db' -Values $sceneGroupMotionTicks.ToArray() -ValuesPerLine 8
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_group_offset_x_table' -Directive 'dw' -Values $sceneGroupOffsetXs.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'scene3d_group_offset_y_table' -Directive 'dw' -Values $sceneGroupOffsetYs.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'scene3d_group_offset_z_table' -Directive 'dw' -Values $sceneGroupOffsetZs.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'scene3d_group_offset_x_step_table' -Directive 'dw' -Values $sceneGroupOffsetXSteps.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'scene3d_group_offset_y_step_table' -Directive 'dw' -Values $sceneGroupOffsetYSteps.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'scene3d_group_offset_z_step_table' -Directive 'dw' -Values $sceneGroupOffsetZSteps.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'scene3d_group_yaw_base_table' -Directive 'db' -Values $sceneGroupYawBases.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'scene3d_group_yaw_step_table' -Directive 'db' -Values $sceneGroupYawSteps.ToArray() -ValuesPerLine 8
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'scene3d_timeline_camera_x_table' -Directive 'dw' -Values $timelineCameraXs.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'scene3d_timeline_camera_y_table' -Directive 'dw' -Values $timelineCameraYs.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'scene3d_timeline_camera_z_table' -Directive 'dw' -Values $timelineCameraZs.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'scene3d_timeline_project_scale_table' -Directive 'dw' -Values $timelineProjectScales.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'scene3d_timeline_yaw_table' -Directive 'db' -Values $timelineYaws.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'scene3d_timeline_pitch_table' -Directive 'db' -Values $timelinePitches.ToArray() -ValuesPerLine 8
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'game3d_mesh_vertex_offset_table' -Directive 'dw' -Values $meshVertexOffsets.ToArray() -ValuesPerLine 4
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'game3d_mesh_vertex_count_table' -Directive 'db' -Values $meshVertexCounts.ToArray() -ValuesPerLine 8
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'game3d_mesh_face_offset_table' -Directive 'dw' -Values $meshFaceOffsets.ToArray() -ValuesPerLine 4
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'game3d_mesh_face_count_table' -Directive 'db' -Values $meshFaceCounts.ToArray() -ValuesPerLine 8
    $lines.Add('')
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_floor_base_color_table' -Directive 'db' -Values $kitFloorBaseColor.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_floor_base_dither_table' -Directive 'db' -Values $kitFloorBaseDither.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_floor_trim_color_table' -Directive 'db' -Values $kitFloorTrimColor.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_floor_trim_dither_table' -Directive 'db' -Values $kitFloorTrimDither.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_wall_base_color_table' -Directive 'db' -Values $kitWallBaseColor.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_wall_base_dither_table' -Directive 'db' -Values $kitWallBaseDither.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_wall_trim_color_table' -Directive 'db' -Values $kitWallTrimColor.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_wall_trim_dither_table' -Directive 'db' -Values $kitWallTrimDither.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_wall_cap_color_table' -Directive 'db' -Values $kitWallCapColor.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_wall_cap_dither_table' -Directive 'db' -Values $kitWallCapDither.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_lane_color_table' -Directive 'db' -Values $kitLaneColor.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_lane_dither_table' -Directive 'db' -Values $kitLaneDither.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_gate_mesh_table' -Directive 'db' -Values $kitGateMesh.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_terminal_mesh_table' -Directive 'db' -Values $kitTerminalMesh.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_surge_mesh_table' -Directive 'db' -Values $kitSurgeMesh.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_shard_mesh_table' -Directive 'db' -Values $kitShardMesh.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_camera_height_table' -Directive 'dw' -Values $kitCameraHeight.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_camera_distance_table' -Directive 'dw' -Values $kitCameraDistance.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_camera_look_ahead_table' -Directive 'dw' -Values $kitCameraLookAhead.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_heading_north_yaw_table' -Directive 'db' -Values $kitCameraNorthYaw.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_heading_east_yaw_table' -Directive 'db' -Values $kitCameraEastYaw.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_heading_south_yaw_table' -Directive 'db' -Values $kitCameraSouthYaw.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_heading_west_yaw_table' -Directive 'db' -Values $kitCameraWestYaw.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_projection_pitch_table' -Directive 'db' -Values $kitProjectionPitch.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_projection_scale_table' -Directive 'dw' -Values $kitProjectionScale.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_near_occluder_inset_table' -Directive 'dw' -Values $kitNearOccluderInset.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_near_occluder_width_table' -Directive 'dw' -Values $kitNearOccluderWidth.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_near_occluder_height_table' -Directive 'dw' -Values $kitNearOccluderHeight.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_far_silhouette_inset_table' -Directive 'dw' -Values $kitFarSilhouetteInset.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_far_silhouette_height_table' -Directive 'dw' -Values $kitFarSilhouetteHeight.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_backdrop_far_color_table' -Directive 'db' -Values $kitBackdropFarColor.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_backdrop_mid_color_table' -Directive 'db' -Values $kitBackdropMidColor.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_backdrop_near_color_table' -Directive 'db' -Values $kitBackdropNearColor.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_horizon_a_color_table' -Directive 'db' -Values $kitHorizonAColor.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_horizon_b_color_table' -Directive 'db' -Values $kitHorizonBColor.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_horizon_y_table' -Directive 'db' -Values $kitHorizonY.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_wobble_strength_table' -Directive 'db' -Values $kitWobbleStrength.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_shot_height_table' -Directive 'dw' -Values $kitShotHeight.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_shot_distance_table' -Directive 'dw' -Values $kitShotDistance.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_shot_look_ahead_table' -Directive 'dw' -Values $kitShotLookAhead.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_shot_pitch_table' -Directive 'db' -Values $kitShotPitch.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_shot_project_scale_table' -Directive 'dw' -Values $kitShotProjectScale.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_shot_horizon_table' -Directive 'db' -Values $kitShotHorizon.ToArray() -ValuesPerLine 8
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_shot_focus_bias_x_table' -Directive 'dw' -Values $kitShotFocusBiasX.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_shot_focus_bias_z_table' -Directive 'dw' -Values $kitShotFocusBiasZ.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_frame_door_inset_table' -Directive 'dw' -Values $kitFrameDoorInset.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_frame_door_width_table' -Directive 'dw' -Values $kitFrameDoorWidth.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_frame_door_height_table' -Directive 'dw' -Values $kitFrameDoorHeight.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_frame_rail_inset_table' -Directive 'dw' -Values $kitFrameRailInset.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_frame_rail_width_table' -Directive 'dw' -Values $kitFrameRailWidth.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_frame_rail_height_table' -Directive 'dw' -Values $kitFrameRailHeight.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_frame_ceiling_height_table' -Directive 'dw' -Values $kitFrameCeilingHeight.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_frame_ceiling_thickness_table' -Directive 'dw' -Values $kitFrameCeilingThickness.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_frame_far_mass_inset_table' -Directive 'dw' -Values $kitFrameFarMassInset.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_frame_far_mass_width_table' -Directive 'dw' -Values $kitFrameFarMassWidth.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_frame_far_mass_height_table' -Directive 'dw' -Values $kitFrameFarMassHeight.ToArray() -ValuesPerLine 4
    Add-AsmDataLines -Lines $lines -Label 'game3d_kit_landmark_mesh_table' -Directive 'db' -Values $kitLandmarkMesh.ToArray() -ValuesPerLine 8

    Set-Content -LiteralPath $OutputPath -Encoding ascii -Value $lines
    Assert-PathExists -Path $OutputPath -Label 'generated geometry include'

    $texturedMaterials = @($materialMap.Values | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.TextureKey) } | Sort-Object -Property TextureKey, Key)

    return [pscustomobject]@{
        SourcePath = $SourcePath
        OutputPath = $OutputPath
        SceneCount = $sceneCount
        SceneGroupCount = $sceneGroupCount
        MeshCount = $meshes.Count
        KitCount = $kits.Count
        MaterialCount = $materials.Count
        TotalBytes = $payload.Count
        TriangleCount = $totalTriangles
        SceneSummary = ($sceneSummary -join ', ')
        FaceSummary = ($sceneFaceSummary -join ', ')
        MeshSummary = ($meshSummary -join ', ')
        KitSummary = ($kitSummary -join ' | ')
        TexturedMaterialCount = $texturedMaterials.Count
        TextureSummary = if ($texturedMaterials.Count -gt 0) { ((@($texturedMaterials | ForEach-Object { "{0}:{1}/{2}" -f $_.Key, $_.TextureKey, $_.ShadeMode }) -join ', ')) } else { 'none' }
        TextureEntries = @($texturedMaterials)
        MeshTriangleMap = $meshTriangleMap
        BankPayloadBytes = $payload.ToArray()
    }
}

function Get-GameplayGeometryBudgetSummary {
    param(
        [string]$SectorSourcePath,
        [string]$GeometrySourcePath,
        [System.Collections.IDictionary]$MeshTriangleMap,
        [int]$ExpectedMapWidth,
        [int]$ExpectedMapHeight,
        [int]$ExitColumn,
        [int]$ShardCount,
        [int]$FaceBudget,
        [int]$OptionalFaceBudget
    )

    $sectorData = Import-StructuredDataFile -SourcePath $SectorSourcePath -Label 'sector source'
    $geometryData = Import-StructuredDataFile -SourcePath $GeometrySourcePath -Label 'geometry source'
    $sectors = @($sectorData['Sectors'])
    $kits = @($geometryData['GameplayKits'])
    $kitMap = @{}
    foreach ($kit in $kits) {
        $kitKey = ([string]$kit['Key']).ToLowerInvariant()
        $kitMap[$kitKey] = $kit
    }

    $summaryLines = New-Object 'System.Collections.Generic.List[string]'
    $warningLines = New-Object 'System.Collections.Generic.List[string]'

    foreach ($sector in $sectors) {
        $sectorId = [int]$sector['Id']
        $kit = $kitMap[("sector{0}" -f $sectorId)]
        $rules = $sector['Rules']
        $maps = @($sector['Maps'])
        $playMinY = 1
        $playMaxY = $ExpectedMapHeight - 2
        $playRowCount = $playMaxY - $playMinY + 1
        $gateTris = [int]$MeshTriangleMap[([string]$kit['GateMesh']).ToLowerInvariant()]
        $terminalTris = [int]$MeshTriangleMap[([string]$kit['TerminalMesh']).ToLowerInvariant()]
        $surgeTris = [int]$MeshTriangleMap[([string]$kit['SurgeMesh']).ToLowerInvariant()]
        $shardTris = [int]$MeshTriangleMap[([string]$kit['ShardMesh']).ToLowerInvariant()]
        $templateParts = New-Object 'System.Collections.Generic.List[string]'
        $structuralCounts = New-Object 'System.Collections.Generic.List[int]'
        $dynamicPropFaces = $gateTris + ([int]$rules['TerminalCount'] * $terminalTris) + ([int]$rules['SurgeCount'] * $surgeTris) + ($ShardCount * $shardTris)

        foreach ($map in $maps) {
            $rows = @($map['Rows'] | ForEach-Object { [string]$_ })
            $floorTrimRuns = 0
            for ($y = $playMinY; $y -lt $playMaxY; $y++) {
                if ((($y + $sectorId) % 2) -eq 0) {
                    $floorTrimRuns += 1
                }
            }

            $northRuns = 0
            $southRuns = 0
            for ($y = 0; $y -lt $ExpectedMapHeight; $y++) {
                $northInside = $false
                $southInside = $false
                for ($x = 0; $x -lt $ExpectedMapWidth; $x++) {
                    $isWall = $rows[$y][$x] -eq '#'
                    $northVisible = $isWall -and ($y -eq 0 -or $rows[$y - 1][$x] -ne '#')
                    $southVisible = $isWall -and ($y -eq ($ExpectedMapHeight - 1) -or $rows[$y + 1][$x] -ne '#')
                    if ($northVisible) {
                        if (-not $northInside) {
                            $northRuns += 1
                            $northInside = $true
                        }
                    } else {
                        $northInside = $false
                    }

                    if ($southVisible) {
                        if (-not $southInside) {
                            $southRuns += 1
                            $southInside = $true
                        }
                    } else {
                        $southInside = $false
                    }
                }
            }

            $westRuns = 0
            $eastRuns = 0
            for ($x = 0; $x -lt $ExpectedMapWidth; $x++) {
                $westInside = $false
                $eastInside = $false
                for ($y = 0; $y -lt $ExpectedMapHeight; $y++) {
                    $isWall = $rows[$y][$x] -eq '#'
                    $westVisible = $isWall -and ($x -eq 0 -or $rows[$y][$x - 1] -ne '#')
                    $eastVisible = $isWall -and ($x -eq ($ExpectedMapWidth - 1) -or $rows[$y][$x + 1] -ne '#')
                    if ($westVisible) {
                        if (-not $westInside) {
                            $westRuns += 1
                            $westInside = $true
                        }
                    } else {
                        $westInside = $false
                    }

                    if ($eastVisible) {
                        if (-not $eastInside) {
                            $eastRuns += 1
                            $eastInside = $true
                        }
                    } else {
                        $eastInside = $false
                    }
                }
            }

            $gateLaneRuns = 0
            $laneBudget = 0
            $laneRow = 0
            while ($laneRow -lt $ExpectedMapHeight -and $laneBudget -lt 5) {
                if ($rows[$laneRow][$ExitColumn] -eq '#') {
                    $laneRow += 1
                    continue
                }

                $runLength = 0
                while ($laneRow -lt $ExpectedMapHeight -and $laneBudget -lt 5 -and $rows[$laneRow][$ExitColumn] -ne '#') {
                    $laneRow += 1
                    $laneBudget += 1
                    $runLength += 1
                }

                if ($runLength -gt 0) {
                    $gateLaneRuns += 1
                }
            }

            $baseEssentialFaces = 2 + ($playRowCount * 2) + ($gateLaneRuns * 2) + 4 + (([int]$rules['TerminalCount'] + [int]$rules['SurgeCount']) * 4)
            $variantFaceMap = [ordered]@{
                nw = ($baseEssentialFaces + (($northRuns + $westRuns) * 2) + [Math]::Min($OptionalFaceBudget, ($floorTrimRuns * 2) + (($northRuns + $westRuns) * 2)))
                sw = ($baseEssentialFaces + (($southRuns + $westRuns) * 2) + [Math]::Min($OptionalFaceBudget, ($floorTrimRuns * 2) + (($southRuns + $westRuns) * 2)))
                ne = ($baseEssentialFaces + (($northRuns + $eastRuns) * 2) + [Math]::Min($OptionalFaceBudget, ($floorTrimRuns * 2) + (($northRuns + $eastRuns) * 2)))
                se = ($baseEssentialFaces + (($southRuns + $eastRuns) * 2) + [Math]::Min($OptionalFaceBudget, ($floorTrimRuns * 2) + (($southRuns + $eastRuns) * 2)))
            }
            $structuralFaces = ($variantFaceMap.Values | Measure-Object -Maximum).Maximum
            $peakViews = @($variantFaceMap.GetEnumerator() | Where-Object { $_.Value -eq $structuralFaces } | ForEach-Object { $_.Key }) -join '+'
            $variantSummary = @($variantFaceMap.GetEnumerator() | ForEach-Object { "{0}={1}" -f $_.Key, $_.Value }) -join ', '
            $headroom = $FaceBudget - $structuralFaces

            $structuralCounts.Add($structuralFaces)
            $templateParts.Add(("{0}={1} (headroom {2}, peak {3}, optional cap {4}, {5})" -f ([string]$map['Name']), $structuralFaces, $headroom, $peakViews, $OptionalFaceBudget, $variantSummary))
        }

        $minFaces = ($structuralCounts | Measure-Object -Minimum).Minimum
        $maxFaces = ($structuralCounts | Measure-Object -Maximum).Maximum
        $summaryLines.Add(("S{0}: structural {1}-{2}/{3} (headroom {4}-{5}, quadrant-aware wall families, optional trim cap {6}), props {7} tris ({8})" -f $sectorId, $minFaces, $maxFaces, $FaceBudget, ($FaceBudget - $maxFaces), ($FaceBudget - $minFaces), $OptionalFaceBudget, $dynamicPropFaces, ($templateParts -join ', ')))

        if ($maxFaces -gt $FaceBudget) {
            $warningLines.Add(("Sector {0} room kit estimate reaches {1} structural faces, which exceeds the configured runtime face budget of {2}." -f $sectorId, $maxFaces, $FaceBudget))
        }
    }

    return [pscustomobject]@{
        SummaryLines = $summaryLines.ToArray()
        WarningLines = $warningLines.ToArray()
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
        [string]$ReadmeSlotPrefix,
        [string]$ShowcaseDir
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

    $showcaseSummary = New-Object 'System.Collections.Generic.List[string]'
    if (-not [string]::IsNullOrWhiteSpace($ShowcaseDir) -and (Test-Path -LiteralPath $ShowcaseDir)) {
        $showcaseSlots = @(
            [pscustomobject]@{
                Label = 'title'
                Candidates = @('showcase-title.png')
            },
            [pscustomobject]@{
                Label = 'beauty'
                Candidates = @('showcase-beauty.png')
            },
            [pscustomobject]@{
                Label = 'action'
                Candidates = @('showcase-action.png')
            }
        )

        $showcaseAvailable = $true
        $resolvedShowcaseSlots = New-Object 'System.Collections.Generic.List[object]'
        for ($slotIndex = 0; $slotIndex -lt [Math]::Min($ReadmeSlotCount, $showcaseSlots.Count); $slotIndex++) {
            $slotName = $slotNames[$slotIndex]
            $slotConfig = $showcaseSlots[$slotIndex]
            $candidatePath = $null
            foreach ($candidateName in @($slotConfig.Candidates)) {
                $candidateFullPath = Join-Path $ShowcaseDir $candidateName
                if (Test-Path -LiteralPath $candidateFullPath) {
                    $candidatePath = $candidateFullPath
                    break
                }
            }

            if ($null -eq $candidatePath) {
                $showcaseAvailable = $false
                break
            }

            $resolvedShowcaseSlots.Add([pscustomobject]@{
                SlotName = $slotName
                Label = $slotConfig.Label
                CandidatePath = $candidatePath
            })
        }

        if ($showcaseAvailable) {
            foreach ($resolvedSlot in $resolvedShowcaseSlots) {
                $slotPath = Join-Path $BuildDir $resolvedSlot.SlotName
                Copy-Item -LiteralPath $resolvedSlot.CandidatePath -Destination $slotPath -Force
                $showcaseSummary.Add(("{0} [{1}] <- {2}" -f $resolvedSlot.SlotName, $resolvedSlot.Label, ([IO.Path]::GetFileName($resolvedSlot.CandidatePath))))
            }
            Set-Content -LiteralPath $rotationStatePath -Encoding ascii -Value '0'
            return [pscustomobject]@{
                RotationStatePath = $rotationStatePath
                SourceCount = $sourceScreenshots.Count
                RemovedCount = $removed.Count
                RemovedNames = @($removed)
                ReadmeSlots = @($showcaseSummary)
            }
        }
    }

    $preservedSlots = New-Object 'System.Collections.Generic.List[string]'
    foreach ($slotName in $slotNames) {
        $slotPath = Join-Path $BuildDir $slotName
        if (Test-Path -LiteralPath $slotPath) {
            Remove-Item -LiteralPath $slotPath -Force
            $preservedSlots.Add(("{0} [cleared] <- showcase capture incomplete; public slot removed until verified title/beauty/action captures exist" -f $slotName))
        } else {
            $preservedSlots.Add(("{0} [missing] <- showcase capture incomplete; refusing to rotate debug or manual frames into public slots" -f $slotName))
        }
    }
    Set-Content -LiteralPath $rotationStatePath -Encoding ascii -Value '0'
    return [pscustomobject]@{
        RotationStatePath = $rotationStatePath
        SourceCount = $sourceScreenshots.Count
        RemovedCount = $removed.Count
        RemovedNames = @($removed)
        ReadmeSlots = @($preservedSlots)
    }

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
        [string[]]$AudioSummaryLines,
        [string[]]$RenderSummaryLines,
        [string]$DeterministicSeed,
        [string]$OverlayMode,
        [string]$StartMode,
        [string]$StartSector,
        [string]$GeneratedArtSource,
        [string]$GeneratedArtInclude,
        [int]$GeneratedArtCount,
        [int]$GeneratedArtBytes,
        [string]$GeneratedArtSizes,
        [string]$GeneratedGeometrySource,
        [string]$GeneratedGeometryInclude,
        [int]$GeneratedGeometrySceneCount,
        [int]$GeneratedGeometryMeshCount,
        [int]$GeneratedGeometryKitCount,
        [int]$GeneratedGeometryMaterialCount,
        [int]$GeneratedGeometryBytes,
        [int]$GeneratedGeometryTriangles,
        [string]$GeneratedGeometrySummary,
        [string]$GeneratedGeometryMeshSummary,
        [string]$GeneratedGeometryKitSummary,
        [string]$GeneratedGeometryFaceSummary,
        [string[]]$GeneratedContentLines,
        [string[]]$ReplayHarnessLines,
        [string[]]$BalanceHarnessLines,
        [string[]]$RegressionHarnessLines,
        [string[]]$FrontendVerifyLines,
        [string[]]$VmSmokeLines,
        [string[]]$RuntimeVerifyLines,
        [string[]]$ShowcaseCaptureLines,
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
    )

    if ($null -ne $AudioSummaryLines -and @($AudioSummaryLines).Count -gt 0) {
        $lines += @(
            ''
            'Audio Policy'
        )

        foreach ($audioLine in @($AudioSummaryLines)) {
            $lines += ("  {0}" -f $audioLine)
        }
    }

    if ($null -ne $RenderSummaryLines -and @($RenderSummaryLines).Count -gt 0) {
        $lines += @(
            ''
            'Render Path'
        )

        foreach ($renderLine in @($RenderSummaryLines)) {
            $lines += ("  {0}" -f $renderLine)
        }
    }

    $lines += @(
        ''
        'Generated Art'
        ("  Source file: {0}" -f $GeneratedArtSource)
        ("  Generated include: {0}" -f $GeneratedArtInclude)
        ("  Bitmap count: {0}" -f $GeneratedArtCount)
        ("  Pixel data bytes: {0}" -f $GeneratedArtBytes)
        ("  Sizes: {0}" -f $GeneratedArtSizes)
        ''
        'Generated Geometry'
        ("  Source file: {0}" -f $GeneratedGeometrySource)
        ("  Generated include: {0}" -f $GeneratedGeometryInclude)
        ("  Scene count: {0}" -f $GeneratedGeometrySceneCount)
        ("  Mesh count: {0}" -f $GeneratedGeometryMeshCount)
        ("  Gameplay kit count: {0}" -f $GeneratedGeometryKitCount)
        ("  Material count: {0}" -f $GeneratedGeometryMaterialCount)
        ("  Bank bytes: {0}" -f $GeneratedGeometryBytes)
        ("  Triangle count: {0}" -f $GeneratedGeometryTriangles)
        ("  Scene summary: {0}" -f $GeneratedGeometrySummary)
        ("  Mesh summary: {0}" -f $GeneratedGeometryMeshSummary)
        ("  Gameplay kit summary: {0}" -f $GeneratedGeometryKitSummary)
        ("  Face summary: {0}" -f $GeneratedGeometryFaceSummary)
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

    if ($null -ne $FrontendVerifyLines -and @($FrontendVerifyLines).Count -gt 0) {
        $lines += @(
            ''
            'Frontend Verify'
        )

        foreach ($frontendVerifyLine in @($FrontendVerifyLines)) {
            $lines += ("  {0}" -f $frontendVerifyLine)
        }
    }

    if ($null -ne $VmSmokeLines -and @($VmSmokeLines).Count -gt 0) {
        $lines += @(
            ''
            'VM Smoke'
        )

        foreach ($vmSmokeLine in @($VmSmokeLines)) {
            $lines += ("  {0}" -f $vmSmokeLine)
        }
    }

    if ($null -ne $RuntimeVerifyLines -and @($RuntimeVerifyLines).Count -gt 0) {
        $lines += @(
            ''
            'Runtime Verify'
        )

        foreach ($runtimeVerifyLine in @($RuntimeVerifyLines)) {
            $lines += ("  {0}" -f $runtimeVerifyLine)
        }
    }

    if ($null -ne $ShowcaseCaptureLines -and @($ShowcaseCaptureLines).Count -gt 0) {
        $lines += @(
            ''
            'Showcase Capture'
        )

        foreach ($showcaseLine in @($ShowcaseCaptureLines)) {
            $lines += ("  {0}" -f $showcaseLine)
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
$presentationSourcePath = Join-Path $root 'assets\presentation.psd1'
$geometrySourcePath = Join-Path $root 'assets\geometry.psd1'
$machineCodeSourcePath = Join-Path $root 'assets\machine_code.psd1'
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
$audioConfig = Join-Path $buildDir 'audio_config.inc'
$generatedArtPath = Join-Path $buildDir 'generated_art.inc'
$generatedSectorContentPath = Join-Path $buildDir 'generated_sector_content.inc'
$generatedMapsPath = Join-Path $buildDir 'generated_maps.inc'
$generatedDemosPath = Join-Path $buildDir 'generated_demos.inc'
$generatedRuntimeVerifyPath = Join-Path $buildDir 'generated_runtime_verify.inc'
$generatedMusicPath = Join-Path $buildDir 'generated_music.inc'
$generatedPresentationPath = Join-Path $buildDir 'generated_presentation_content.inc'
$generatedGeometryPath = Join-Path $buildDir 'generated_geometry.inc'
$generatedMachineCodePath = Join-Path $buildDir 'generated_machine_code.inc'
$generatedBankLayoutPath = Join-Path $buildDir 'generated_bank_layout.inc'
$machineCodeReportPath = Join-Path $buildDir 'cyberstorm-machine-code-report.txt'
$textureBankReportPath = Join-Path $buildDir 'cyberstorm-texture-bank-report.txt'
$codeBankBinPath = Join-Path $buildDir 'cyberstorm-code-bank.bin'
$textureBankBinPath = Join-Path $buildDir 'cyberstorm-texture-bank.bin'
$mapBankBinPath = Join-Path $buildDir 'cyberstorm-map-bank.bin'
$presentationBankBinPath = Join-Path $buildDir 'cyberstorm-presentation-bank.bin'
$geometryBankBinPath = Join-Path $buildDir 'cyberstorm-geometry-bank.bin'
$stage2BinPath = Join-Path $buildDir 'cyberstorm-stage2.bin'
$bootBinPath = Join-Path $buildDir 'cyberstorm-boot.bin'
$imgPath = Join-Path $buildDir 'cyberstorm.img'
$vfdPath = Join-Path $buildDir 'cyberstorm.vfd'
$reportPath = Join-Path $buildDir 'cyberstorm-build-report.txt'
$replayReportPath = Join-Path $buildDir 'cyberstorm-replay-report.txt'
$balanceReportPath = Join-Path $buildDir 'cyberstorm-balance-report.txt'
$regressionReportPath = Join-Path $buildDir 'cyberstorm-regression-report.txt'
$vmSmokeReportPath = Join-Path $buildDir 'cyberstorm-vm-smoke-report.txt'
$frontendVerifyReportPath = Join-Path $buildDir 'cyberstorm-frontend-verify-report.txt'
$runtimeVerifyReportPath = Join-Path $buildDir 'cyberstorm-runtime-verify-report.txt'
$showcaseReportPath = Join-Path $buildDir 'cyberstorm-showcase-report.txt'
$vmSmokeScript = Join-Path $PSScriptRoot 'vm-smoke.ps1'
$frontendVerifyHarnessScript = Join-Path $PSScriptRoot 'frontend-verify.ps1'
$runtimeVerifyScript = Join-Path $PSScriptRoot 'runtime-verify.ps1'
$showcaseCaptureScript = Join-Path $PSScriptRoot 'capture-showcase.ps1'
$readmeScreenshotArtifacts = 1..$readmeScreenshotCount | ForEach-Object {
    Join-Path $buildDir ("{0}{1}.png" -f $readmeScreenshotPrefix, $_)
}

$seedProvided = $null -ne $DebugSeed
$startSectorProvided = $null -ne $DebugStartSector
$demoIndexProvided = $null -ne $DebugDemoIndex
$frontendScenarioProvided = $null -ne $DebugFrontendScenario
$verifyCorruptDemoProvided = $null -ne $DebugVerifyCorruptDemoIndex
$verifyCorruptFrontendProvided = $null -ne $DebugFrontendCorruptScenario
$renderStageProvided = $null -ne $DebugRenderStage
$render2DOverride = $DebugRender2D.IsPresent
$renderReferenceOverride = $DebugRenderReference.IsPresent
$renderMachineOverride = $DebugRenderMachine.IsPresent -or $DebugRender3D.IsPresent
$renderOverrideCount = @($render2DOverride, $renderReferenceOverride, $renderMachineOverride) | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count
if ($renderOverrideCount -gt 1) {
    throw 'Use only one of -DebugRender2D, -DebugRenderReference, -DebugRenderMachine, or legacy -DebugRender3D.'
}
if ($renderStageProvided -and $render2DOverride) {
    throw '-DebugRenderStage only applies to the 3D gameplay renderer.'
}
$debugProfile = $DebugBuild.IsPresent -or $seedProvided -or $DebugOverlay.IsPresent -or $DebugStartInGame.IsPresent -or $startSectorProvided -or $DebugDemoBoot.IsPresent -or $demoIndexProvided -or $DebugFrontendVerify.IsPresent -or $frontendScenarioProvided -or $DebugRuntimeVerify.IsPresent -or $verifyCorruptDemoProvided -or $verifyCorruptFrontendProvided -or $render2DOverride -or $renderReferenceOverride -or $renderMachineOverride -or $renderStageProvided
$debugSeedValue = if ($seedProvided) { [int]$DebugSeed } else { 0xACE1 }
$debugStartSectorValue = if ($startSectorProvided) { [int]$DebugStartSector } else { 1 }
$debugDemoIndexValue = if ($demoIndexProvided) { [int]$DebugDemoIndex } else { 0 }
$debugFrontendScenarioValue = if ($frontendScenarioProvided) { [int]$DebugFrontendScenario } else { 0 }
$debugVerifyCorruptDemoIndexValue = if ($verifyCorruptDemoProvided) { [int]$DebugVerifyCorruptDemoIndex } else { 255 }
$debugFrontendCorruptScenarioValue = if ($verifyCorruptFrontendProvided) { [int]$DebugFrontendCorruptScenario } else { 255 }
$debugRenderStageValue = if ($renderStageProvided) { [int]$DebugRenderStage } else { 5 }
$legacyGameplayMode = $false
if ($render2DOverride) {
    $sceneRenderModeValue = 0
    $sceneRenderModeName = 'SCENES_2D_ORACLE'
    $gameplayRenderModeValue = 0
    $gameplayRenderModeName = 'GAMEPLAY_2D_ORACLE'
} elseif ($renderReferenceOverride) {
    $sceneRenderModeValue = 1
    $sceneRenderModeName = 'SCENES_3D_REFERENCE'
    $gameplayRenderModeValue = 1
    $gameplayRenderModeName = 'GAMEPLAY_3D_REFERENCE'
} else {
    $sceneRenderModeValue = 2
    $sceneRenderModeName = 'SCENES_3D_MACHINE'
    $gameplayRenderModeValue = 2
    $gameplayRenderModeName = 'GAMEPLAY_3D_MACHINE'
}
$debugConfigLines = @(
    '; generated by scripts/build.ps1'
    ("DEBUG_BUILD EQU {0}" -f ([int]$debugProfile))
    ("DEBUG_FORCE_SEED EQU {0}" -f ([int]$seedProvided))
    ("DEBUG_SEED_VALUE EQU {0}" -f (Format-Hex16Literal $debugSeedValue))
    ("DEBUG_OVERLAY EQU {0}" -f ([int]$DebugOverlay.IsPresent))
    ("DEBUG_START_IN_GAME EQU {0}" -f ([int]$DebugStartInGame.IsPresent))
    ("DEBUG_START_SECTOR EQU {0}" -f $debugStartSectorValue)
    ("DEBUG_DEMO_BOOT EQU {0}" -f ([int]$DebugDemoBoot.IsPresent))
    ("DEBUG_DEMO_INDEX EQU {0}" -f $debugDemoIndexValue)
    ("DEBUG_FRONTEND_VERIFY EQU {0}" -f ([int]$DebugFrontendVerify.IsPresent))
    ("DEBUG_FRONTEND_SCENARIO EQU {0}" -f $debugFrontendScenarioValue)
    ("DEBUG_RUNTIME_VERIFY EQU {0}" -f ([int]$DebugRuntimeVerify.IsPresent))
    ("DEBUG_VERIFY_CORRUPT_DEMO_INDEX EQU {0}" -f $debugVerifyCorruptDemoIndexValue)
    ("DEBUG_FRONTEND_CORRUPT_SCENARIO EQU {0}" -f $debugFrontendCorruptScenarioValue)
    ("DEBUG_LEGACY_GAMEPLAY EQU {0}" -f ([int]$legacyGameplayMode))
    ("DEBUG_SCENE_RENDER_MODE EQU {0}" -f $sceneRenderModeValue)
    ("DEBUG_GAMEPLAY_RENDER_MODE EQU {0}" -f $gameplayRenderModeValue)
    ("DEBUG_RENDER_STAGE EQU {0}" -f $debugRenderStageValue)
)
Set-Content -LiteralPath $debugConfig -Encoding ascii -Value $debugConfigLines
Assert-PathExists -Path $debugConfig -Label 'generated debug config'

$audioModeValue = if ($musicEnabled) { 1 } else { 0 }
$audioModeName = if ($musicEnabled) { 'MUSIC' } else { 'SFX_ONLY' }
$audioConfigLines = @(
    '; generated by scripts/build.ps1'
    'AUDIO_MODE_SFX_ONLY EQU 0'
    'AUDIO_MODE_MUSIC EQU 1'
    'AUDIO_MODE_EXPERIMENTAL_MUSIC EQU 1'
    ("AUDIO_MODE EQU {0}" -f $audioModeValue)
    ("AUDIO_MUSIC_ENABLED EQU {0}" -f ([int]$musicEnabled))
)
Set-Content -LiteralPath $audioConfig -Encoding ascii -Value $audioConfigLines
Assert-PathExists -Path $audioConfig -Label 'generated audio config'

$buildMode = if ($debugProfile) { 'debug' } else { 'release' }
$deterministicSeedText = if ($seedProvided) { (Format-Hex16 $debugSeedValue) } else { 'off' }
$overlayModeText = if ($DebugOverlay.IsPresent) { 'enabled' } else { 'off' }
$startModeText = if ($DebugDemoBoot.IsPresent) { 'direct-to-demo' } elseif ($DebugStartInGame.IsPresent) { 'direct-to-game' } else { 'normal splash/title flow' }
$startSectorText = if ($startSectorProvided) { $debugStartSectorValue.ToString() } else { '1 (default)' }
$audioSummaryLines = @(
    ("Mode: {0}" -f $audioModeName)
    ("Looping music: {0}" -f ($(if ($musicEnabled) { 'enabled in release' } else { 'disabled by -SfxOnly' })))
    'Backend order: SB16 when available, PC speaker fallback otherwise.'
    'Policy: looping themes are the supported release baseline; one-shot SFX still preempt the channel and music resumes underneath.'
)
$renderSummaryLines = @(
    ("Scene renderer: {0}" -f $sceneRenderModeName)
    ("Gameplay renderer: {0}" -f $gameplayRenderModeName)
    ("3D render stage: {0}" -f $debugRenderStageValue)
    'Debug switches: -DebugRender2D uses the oracle path, -DebugRenderReference forces stage-two MASM kernels, and -DebugRenderMachine (or legacy -DebugRender3D) enables the banked raw machine-code rail.'
)

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

Write-Section -Title 'Audio Policy'
foreach ($audioLine in $audioSummaryLines) {
    Write-Host $audioLine
}

Write-Section -Title 'Render Path'
foreach ($renderLine in $renderSummaryLines) {
    Write-Host $renderLine
}

$expectedMapWidth = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'MAP_W'
$expectedMapHeight = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'MAP_H'
$expectedSectorCount = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'TOTAL_SECTORS'
$startX = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'START_X'
$startY = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'START_Y'
$exitCol = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'EXIT_COL'
$exitRow = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'EXIT_ROW'
$safeXMax = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'SAFE_X_MAX'
$safeYMin = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'SAFE_Y_MIN'
$expectedShardPoolCount = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'SHARD_POOL_COUNT'
$enemySpawnStep = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'ENEMY_SPAWN_STEP'
$enemySpawnBase = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'ENEMY_SPAWN_BASE'
$maxEnemies = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'MAX_ENEMIES'
$expectedBannerWidth = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'PRESENT_BANNER_W'
$expectedBannerHeight = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'PRESENT_BANNER_H'
$game3dFaceBudget = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'SCENE3D_MAX_FACES'
$game3dOptionalFaceBudget = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'GAME3D_OPTIONAL_FACE_BUDGET'
$shardCount = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'SHARD_COUNT'

$generatedArt = Write-GeneratedArtInclude -SourcePath $artSourcePath -OutputPath $generatedArtPath
$generatedPresentation = Write-GeneratedPresentationContent `
    -SourcePath $presentationSourcePath `
    -OutputPath $generatedPresentationPath `
    -ExpectedBannerWidth $expectedBannerWidth `
    -ExpectedBannerHeight $expectedBannerHeight
$generatedMachineCode = Write-GeneratedMachineCodeAssets `
    -SourcePath $machineCodeSourcePath `
    -OutputPath $generatedMachineCodePath `
    -BinaryPath $codeBankBinPath `
    -ReportPath $machineCodeReportPath
$generatedGeometry = Write-GeneratedGeometryInclude `
    -SourcePath $geometrySourcePath `
    -OutputPath $generatedGeometryPath
$generatedTextureBank = Write-GeneratedTextureBank `
    -TextureEntries $generatedGeometry.TextureEntries `
    -BinaryPath $textureBankBinPath `
    -ReportPath $textureBankReportPath
$generatedSectors = Write-GeneratedSectorIncludes `
    -SourcePath $sectorSourcePath `
    -SectorOutputPath $generatedSectorContentPath `
    -MapsOutputPath $generatedMapsPath `
    -ExpectedSectorCount $expectedSectorCount `
    -ExpectedMapWidth $expectedMapWidth `
    -ExpectedMapHeight $expectedMapHeight `
    -ExpectedShardPoolCount $expectedShardPoolCount `
    -StartX $startX `
    -StartY $startY `
    -ExitX $exitCol `
    -ExitY $exitRow `
    -SafeXMax $safeXMax `
    -SafeYMin $safeYMin `
    -EnemySpawnStep $enemySpawnStep `
    -EnemySpawnBase $enemySpawnBase `
    -MaxEnemies $maxEnemies
$gameplayGeometryBudget = Get-GameplayGeometryBudgetSummary `
    -SectorSourcePath $sectorSourcePath `
    -GeometrySourcePath $geometrySourcePath `
    -MeshTriangleMap $generatedGeometry.MeshTriangleMap `
    -ExpectedMapWidth $expectedMapWidth `
    -ExpectedMapHeight $expectedMapHeight `
    -ExitColumn $exitCol `
    -ShardCount $shardCount `
    -FaceBudget $game3dFaceBudget `
    -OptionalFaceBudget $game3dOptionalFaceBudget
$generatedDemos = Write-GeneratedDemoInclude `
    -SourcePath $demoSourcePath `
    -OutputPath $generatedDemosPath `
    -ExpectedSectorCount $expectedSectorCount
$demoCount = [int]$generatedDemos.DemoCount
if ($demoIndexProvided -and ($debugDemoIndexValue -lt 0 -or $debugDemoIndexValue -ge $demoCount)) {
    throw ("Debug demo index must be in the range 0..{0}. Received: {1}" -f ($demoCount - 1), $debugDemoIndexValue)
}

if ($verifyCorruptDemoProvided -and ($debugVerifyCorruptDemoIndexValue -lt 0 -or $debugVerifyCorruptDemoIndexValue -ge $demoCount)) {
    throw ("Debug verify corrupt demo index must be in the range 0..{0}. Received: {1}" -f ($demoCount - 1), $debugVerifyCorruptDemoIndexValue)
}

$generatedMusic = Write-GeneratedMusicInclude -SourcePath $musicSourcePath -OutputPath $generatedMusicPath
$codeBankLoadSegment = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'CODE_BANK_SEG'
$textureBankLoadSegment = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'TEXTURE_BANK_SEG'
$mapBankLoadSegment = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'MAP_BANK_SEG'
$presentationBankLoadSegment = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'PRESENT_BANK_SEG'
$geometryBankLoadSegment = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'GEOMETRY_BANK_SEG'
$game3dViewX = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'GAME3D_VIEW_X'
$game3dViewY = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'GAME3D_VIEW_Y'
$game3dViewW = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'GAME3D_VIEW_W'
$game3dViewH = Get-AsmEquValue -SourcePath $constantsSourcePath -Name 'GAME3D_VIEW_H'
[IO.File]::WriteAllBytes($codeBankBinPath, $generatedMachineCode.BankPayloadBytes)
Assert-PathExists -Path $codeBankBinPath -Label 'generated code bank payload'
[IO.File]::WriteAllBytes($textureBankBinPath, $generatedTextureBank.BankPayloadBytes)
Assert-PathExists -Path $textureBankBinPath -Label 'generated texture bank payload'
[IO.File]::WriteAllBytes($mapBankBinPath, $generatedSectors.MapPayloadBytes)
Assert-PathExists -Path $mapBankBinPath -Label 'generated map bank payload'
[IO.File]::WriteAllBytes($presentationBankBinPath, $generatedPresentation.BankPayloadBytes)
Assert-PathExists -Path $presentationBankBinPath -Label 'generated presentation bank payload'
[IO.File]::WriteAllBytes($geometryBankBinPath, $generatedGeometry.BankPayloadBytes)
Assert-PathExists -Path $geometryBankBinPath -Label 'generated geometry bank payload'

Write-Section -Title 'Generated Assets'
Write-Host ("Source  : {0}" -f $generatedArt.SourcePath)
Write-Host ("Include : {0}" -f $generatedArt.OutputPath)
Write-Host ("Bitmaps : {0}" -f $generatedArt.AssetCount)
Write-Host ("Bytes   : {0}" -f $generatedArt.TotalBytes)
Write-Host ("Sizes   : {0}" -f $generatedArt.SizeSummary)
Write-Host ("Code kernels: {0}, tables: {1}, code-bank bytes: {2}" -f $generatedMachineCode.KernelCount, $generatedMachineCode.TableCount, $generatedMachineCode.TotalBytes)
Write-Host ("Texture bank: {0} entries, {1} bytes" -f $generatedTextureBank.TextureCount, $generatedTextureBank.TotalBytes)
Write-Host ("Geometry scenes: {0}, groups: {1}, meshes: {2}, kits: {3}, tris: {4}" -f $generatedGeometry.SceneCount, $generatedGeometry.SceneGroupCount, $generatedGeometry.MeshCount, $generatedGeometry.KitCount, $generatedGeometry.TriangleCount)

$generatedContentLines = @(
    ("Machine-code source: {0}" -f $generatedMachineCode.SourcePath)
    ("Machine-code include: {0}" -f $generatedMachineCode.OutputPath)
    ("Machine-code report: {0}" -f $generatedMachineCode.ReportPath)
    ("Machine-code kernels: {0}" -f $generatedMachineCode.KernelCount)
    ("Machine-code tables: {0}" -f $generatedMachineCode.TableCount)
    ("Code bank bytes: {0}" -f $generatedMachineCode.TotalBytes)
    ("Machine-code summary: {0}" -f $generatedMachineCode.KernelSummary)
    ("Machine-code tables: {0}" -f $generatedMachineCode.TableSummary)
    ("Texture bank report: {0}" -f $generatedTextureBank.ReportPath)
    ("Texture bank bytes: {0}" -f $generatedTextureBank.TotalBytes)
    ("Texture atlas entries: {0}" -f $generatedTextureBank.TextureCount)
    ("Texture atlas summary: {0}" -f $generatedTextureBank.Summary)
    ("Presentation source: {0}" -f $generatedPresentation.SourcePath)
    ("Presentation include: {0}" -f $generatedPresentation.OutputPath)
    ("Presentation assets: {0} ({1}x{2}, {3} bytes each, {4} bytes total)" -f $generatedPresentation.BannerCount, $expectedBannerWidth, $expectedBannerHeight, $generatedPresentation.BannerBytes, $generatedPresentation.TotalBytes)
    ("Presentation layout: {0}" -f $generatedPresentation.BannerSummary)
    ("Geometry source: {0}" -f $generatedGeometry.SourcePath)
    ("Geometry include: {0}" -f $generatedGeometry.OutputPath)
    ("Geometry scenes: {0}" -f $generatedGeometry.SceneCount)
    ("Geometry scene groups: {0}" -f $generatedGeometry.SceneGroupCount)
    ("Geometry meshes: {0}" -f $generatedGeometry.MeshCount)
    ("Geometry gameplay kits: {0}" -f $generatedGeometry.KitCount)
    ("Geometry materials: {0}" -f $generatedGeometry.MaterialCount)
    ("Geometry bank bytes: {0}" -f $generatedGeometry.TotalBytes)
    ("Geometry triangles: {0}" -f $generatedGeometry.TriangleCount)
    ("Geometry summary: {0}" -f $generatedGeometry.SceneSummary)
    ("Geometry mesh summary: {0}" -f $generatedGeometry.MeshSummary)
    ("Geometry gameplay kit summary: {0}" -f $generatedGeometry.KitSummary)
    ("Geometry textured materials: {0}" -f $generatedGeometry.TexturedMaterialCount)
    ("Geometry texture summary: {0}" -f $generatedGeometry.TextureSummary)
    ("Gameplay camera: quadrant-aware chase presets with authored projection, structure depth, horizon bands, and atmosphere")
    ("Gameplay viewport: {0}x{1} at {2},{3}" -f $game3dViewW, $game3dViewH, $game3dViewX, $game3dViewY)
    ("Gameplay room structural headroom: {0}" -f ($gameplayGeometryBudget.SummaryLines -join ' | '))
    ("Sector source: {0}" -f $generatedSectors.SourcePath)
    ("Sector include: {0}" -f $generatedSectors.SectorOutputPath)
    ("Maps include: {0}" -f $generatedSectors.MapsOutputPath)
    ("Sectors: {0}" -f $generatedSectors.SectorCount)
    ("Maps: {0} ({1} each, {2} bytes total)" -f $generatedSectors.MapCount, $generatedSectors.Geometry, $generatedSectors.MapBytes)
    ("Templates: {0}" -f $generatedSectors.TemplateSummary)
    ("Rules: {0}" -f $generatedSectors.RuleSummary)
    ("Anchors: {0}" -f $generatedSectors.AnchorSummary)
    ("Scenarios: {0}" -f $generatedSectors.ScenarioSummary)
    ("Shard pools: {0}" -f $generatedSectors.ShardPoolSummary)
    ("Adventure realm: {0}" -f $generatedSectors.AdventureRealmSummary)
    ("Adventure zones: {0}" -f $generatedSectors.AdventureZoneSummary)
    ("Adventure beats: {0}" -f $generatedSectors.AdventureRouteSummary)
    ("Adventure capture: {0}" -f $generatedSectors.AdventureCaptureSummary)
    ("Demo source: {0}" -f $generatedDemos.SourcePath)
    ("Demo include: {0}" -f $generatedDemos.OutputPath)
    ("Demos: {0}" -f $generatedDemos.DemoCount)
    ("Demo steps: {0}" -f $generatedDemos.StepCount)
    ("Demo summary: {0}" -f $generatedDemos.DemoSummary)
    ("Runtime verify include: {0}" -f $generatedRuntimeVerifyPath)
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
    -GeometrySourcePath $geometrySourcePath `
    -ConstantsSourcePath $constantsSourcePath `
    -SfxOnly:$SfxOnly.IsPresent `
    -ReportPath $replayReportPath
$generatedRuntimeVerify = Write-GeneratedRuntimeVerifyInclude `
    -ReplayResults @($replayHarness.Results) `
    -OutputPath $generatedRuntimeVerifyPath `
    -CorruptDemoIndex $(if ($verifyCorruptDemoProvided) { $debugVerifyCorruptDemoIndexValue } else { $null })
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
        Name = 'Code bank'
        SymbolPrefix = 'CODE_BANK'
        SourcePath = $generatedMachineCode.SourcePath
        BinaryPath = $codeBankBinPath
        LoadSegment = $codeBankLoadSegment
        Bytes = $generatedMachineCode.TotalBytes
    },
    [pscustomobject]@{
        Name = 'Texture bank'
        SymbolPrefix = 'TEXTURE_BANK'
        SourcePath = $geometrySourcePath
        BinaryPath = $textureBankBinPath
        LoadSegment = $textureBankLoadSegment
        Bytes = $generatedTextureBank.TotalBytes
    },
    [pscustomobject]@{
        Name = 'Map bank'
        SymbolPrefix = 'MAP_BANK'
        SourcePath = $generatedSectors.SourcePath
        BinaryPath = $mapBankBinPath
        LoadSegment = $mapBankLoadSegment
        Bytes = $generatedSectors.MapBytes
    },
    [pscustomobject]@{
        Name = 'Presentation bank'
        SymbolPrefix = 'PRESENT_BANK'
        SourcePath = $generatedPresentation.SourcePath
        BinaryPath = $presentationBankBinPath
        LoadSegment = $presentationBankLoadSegment
        Bytes = $generatedPresentation.TotalBytes
    },
    [pscustomobject]@{
        Name = 'Geometry bank'
        SymbolPrefix = 'GEOMETRY_BANK'
        SourcePath = $generatedGeometry.SourcePath
        BinaryPath = $geometryBankBinPath
        LoadSegment = $geometryBankLoadSegment
        Bytes = $generatedGeometry.TotalBytes
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
if ($null -ne $gameplayGeometryBudget.WarningLines -and @($gameplayGeometryBudget.WarningLines).Count -gt 0) {
    $warnings = @($warnings) + @($gameplayGeometryBudget.WarningLines)
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
    -CodeBankBinaryPath $codeBankBinPath `
    -TextureBankBinaryPath $textureBankBinPath `
    -MapBankBinaryPath $mapBankBinPath `
    -PresentationBankBinaryPath $presentationBankBinPath `
    -GeometryBankBinaryPath $geometryBankBinPath `
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

$frontendVerifyArtifacts = @()
if ($FrontendVerify.IsPresent) {
    $frontendVerifyResult = & $frontendVerifyHarnessScript `
        -Assembler $Assembler `
        -AssemblerPath $AssemblerPath `
        -MasmPath $MasmPath `
        -SfxOnly:$SfxOnly.IsPresent `
        -VmName 'CyberStorm' `
        -ReportPath $frontendVerifyReportPath
    $frontendVerifyLines = @(
        ("Report: {0}" -f $frontendVerifyResult.ReportPath)
    ) + @($frontendVerifyResult.SummaryLines)
    $frontendVerifyArtifacts = @($frontendVerifyResult.ArtifactPaths)
} else {
    $frontendVerifyLines = @(
        'Status: skipped (use -FrontendVerify to boot debug-only splash/title/attract verification scenarios in VirtualBox).'
    )
    Set-Content -LiteralPath $frontendVerifyReportPath -Encoding ascii -Value @(
        'CyberStorm Frontend Verification Report'
        ("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'))
        'Status: skipped'
        'Run scripts/build.ps1 -FrontendVerify or scripts/frontend-verify.ps1 to exercise the frontend trust verification lane.'
    )
}

Write-Section -Title 'Frontend Verify'
foreach ($frontendVerifyLine in $frontendVerifyLines) {
    Write-Host $frontendVerifyLine
}

$vmSmokeArtifacts = @()
if ($VmSmoke.IsPresent) {
    $vmSmokeResult = & $vmSmokeScript -ReportPath $vmSmokeReportPath
    $vmSmokeLines = @(
        ("Report: {0}" -f $vmSmokeResult.ReportPath)
    ) + @($vmSmokeResult.SummaryLines)
    $vmSmokeArtifacts = @($vmSmokeResult.ArtifactPaths)
} else {
    $vmSmokeLines = @(
        'Status: skipped (use -VmSmoke to boot the headless VirtualBox smoke path).'
    )
    Set-Content -LiteralPath $vmSmokeReportPath -Encoding ascii -Value @(
        'CyberStorm VM Smoke Report'
        ("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'))
        'Status: skipped'
        'Run scripts/build.ps1 -VmSmoke or scripts/vm-smoke.ps1 to exercise the attract-mode VM smoke lane.'
    )
}

Write-Section -Title 'VM Smoke'
foreach ($vmSmokeLine in $vmSmokeLines) {
    Write-Host $vmSmokeLine
}

$runtimeVerifyArtifacts = @()
if ($RuntimeVerify.IsPresent) {
    $runtimeVerifyResult = & $runtimeVerifyScript `
        -Assembler $Assembler `
        -AssemblerPath $AssemblerPath `
        -MasmPath $MasmPath `
        -SfxOnly:$SfxOnly.IsPresent `
        -VmName 'CyberStorm' `
        -ReportPath $runtimeVerifyReportPath
    $runtimeVerifyLines = @(
        ("Report: {0}" -f $runtimeVerifyResult.ReportPath)
    ) + @($runtimeVerifyResult.SummaryLines)
    $runtimeVerifyArtifacts = @($runtimeVerifyResult.ArtifactPaths)
} else {
    $runtimeVerifyLines = @(
        'Status: skipped (use -RuntimeVerify to boot debug-only replay verification demos in VirtualBox).'
    )
    Set-Content -LiteralPath $runtimeVerifyReportPath -Encoding ascii -Value @(
        'CyberStorm Runtime Verification Report'
        ("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'))
        'Status: skipped'
        'Run scripts/build.ps1 -RuntimeVerify or scripts/runtime-verify.ps1 to exercise the closed-loop replay verification lane.'
    )
}

Write-Section -Title 'Runtime Verify'
foreach ($runtimeVerifyLine in $runtimeVerifyLines) {
    Write-Host $runtimeVerifyLine
}

$showcaseArtifacts = @()
$showcaseSourceSelection = 'Selection: branding uses the title screen, and beauty/action use authored AdventureRealm capture anchors so public shots come from curated in-engine demos rather than ad hoc debug frames.'
if ($CaptureShowcase.IsPresent) {
    $showcaseResult = & $showcaseCaptureScript `
        -Assembler $Assembler `
        -AssemblerPath $AssemblerPath `
        -MasmPath $MasmPath `
        -SfxOnly:$SfxOnly.IsPresent `
        -VmName 'CyberStorm' `
        -ReportPath $showcaseReportPath
    $showcaseCaptureLines = @(
        ("Report: {0}" -f $showcaseResult.ReportPath)
        $showcaseSourceSelection
    ) + @($showcaseResult.SummaryLines)
    $showcaseArtifacts = @($showcaseResult.ArtifactPaths)
} else {
    $showcaseCaptureLines = @(
        'Status: skipped (use -CaptureShowcase to generate deterministic title/beauty/action screenshots).'
        $showcaseSourceSelection
    )
    Set-Content -LiteralPath $showcaseReportPath -Encoding ascii -Value @(
        'CyberStorm Showcase Capture Report'
        ("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'))
        'Status: skipped'
        $showcaseSourceSelection
        'Run scripts/build.ps1 -CaptureShowcase or scripts/capture-showcase.ps1 to generate deterministic public-gallery screenshots.'
    )
}

Write-Section -Title 'Showcase Capture'
foreach ($showcaseLine in $showcaseCaptureLines) {
    Write-Host $showcaseLine
}

$screenshotSync = Sync-ReadmeScreenshots -BuildDir $buildDir -PoolKeepCount $screenshotPoolKeepCount -ReadmeSlotCount $readmeScreenshotCount -ReadmeSlotPrefix $readmeScreenshotPrefix -ShowcaseDir (Join-Path $buildDir 'showcase')
$screenshotHousekeepingText = ("kept {0} source screenshots, removed {1}, README slots now follow the verified showcase-only policy" -f $screenshotSync.SourceCount, $screenshotSync.RemovedCount)

$bootStartOffset = Get-SymbolValue -ObjectModel $bootFlat.ObjectModel -Names @('start', '_start')
$stageStartOffset = Get-SymbolValue -ObjectModel $gameFlat.ObjectModel -Names @('start', '_start')

Write-BuildReport `
    -ReportPath $reportPath `
    -AssemblerName $assemblerTool.Name `
    -ToolPath $assemblerTool.Path `
    -ToolSource $assemblerTool.Source `
    -BuildMode $buildMode `
    -AudioSummaryLines $audioSummaryLines `
    -RenderSummaryLines $renderSummaryLines `
    -DeterministicSeed $deterministicSeedText `
    -OverlayMode $overlayModeText `
    -StartMode $startModeText `
    -StartSector $startSectorText `
    -GeneratedArtSource $generatedArt.SourcePath `
    -GeneratedArtInclude $generatedArt.OutputPath `
    -GeneratedArtCount $generatedArt.AssetCount `
    -GeneratedArtBytes $generatedArt.TotalBytes `
    -GeneratedArtSizes $generatedArt.SizeSummary `
    -GeneratedGeometrySource $generatedGeometry.SourcePath `
    -GeneratedGeometryInclude $generatedGeometry.OutputPath `
    -GeneratedGeometrySceneCount $generatedGeometry.SceneCount `
    -GeneratedGeometryMeshCount $generatedGeometry.MeshCount `
    -GeneratedGeometryKitCount $generatedGeometry.KitCount `
    -GeneratedGeometryMaterialCount $generatedGeometry.MaterialCount `
    -GeneratedGeometryBytes $generatedGeometry.TotalBytes `
    -GeneratedGeometryTriangles $generatedGeometry.TriangleCount `
    -GeneratedGeometrySummary $generatedGeometry.SceneSummary `
    -GeneratedGeometryMeshSummary $generatedGeometry.MeshSummary `
    -GeneratedGeometryKitSummary $generatedGeometry.KitSummary `
    -GeneratedGeometryFaceSummary $generatedGeometry.FaceSummary `
    -GeneratedContentLines $generatedContentLines `
    -ReplayHarnessLines $replayHarnessLines `
    -BalanceHarnessLines $balanceHarnessLines `
    -RegressionHarnessLines $regressionHarnessLines `
    -FrontendVerifyLines $frontendVerifyLines `
    -VmSmokeLines $vmSmokeLines `
    -RuntimeVerifyLines $runtimeVerifyLines `
    -ShowcaseCaptureLines $showcaseCaptureLines `
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
    -ArtifactPaths @($generatedArtPath, $generatedPresentationPath, $generatedGeometryPath, $generatedMachineCodePath, $generatedSectorContentPath, $generatedMapsPath, $generatedDemosPath, $generatedRuntimeVerifyPath, $generatedMusicPath, $machineCodeReportPath, $textureBankReportPath, $replayReportPath, $balanceReportPath, $regressionReportPath, $frontendVerifyReportPath, $vmSmokeReportPath, $runtimeVerifyReportPath, $showcaseReportPath, $generatedBankLayoutPath, $codeBankBinPath, $textureBankBinPath, $mapBankBinPath, $presentationBankBinPath, $geometryBankBinPath, $bootBinPath, $stage2BinPath, $bootList, $gameList, $bootConfig, $debugConfig, $audioConfig, $imgPath, $vfdPath) + $readmeScreenshotArtifacts + @($reportPath, $screenshotSync.RotationStatePath) + $frontendVerifyArtifacts + $vmSmokeArtifacts + $runtimeVerifyArtifacts + $showcaseArtifacts `
    -Layout $layout

Write-Section -Title 'Artifacts'
Write-Host ("Built {0}" -f $imgPath)
Write-Host ("Built {0}" -f $vfdPath)
Write-Host ("Art     {0}" -f $generatedArtPath)
Write-Host ("Present {0}" -f $generatedPresentationPath)
Write-Host ("Geom    {0}" -f $generatedGeometryPath)
Write-Host ("Machine {0}" -f $generatedMachineCodePath)
Write-Host ("Rules   {0}" -f $generatedSectorContentPath)
Write-Host ("Maps    {0}" -f $generatedMapsPath)
Write-Host ("Demos   {0}" -f $generatedDemosPath)
Write-Host ("Verify  {0}" -f $generatedRuntimeVerifyPath)
Write-Host ("Music   {0}" -f $generatedMusicPath)
Write-Host ("MC Rep  {0}" -f $machineCodeReportPath)
Write-Host ("TX Rep  {0}" -f $textureBankReportPath)
Write-Host ("Replay  {0}" -f $replayReportPath)
Write-Host ("Balance {0}" -f $balanceReportPath)
Write-Host ("Regress {0}" -f $regressionReportPath)
Write-Host ("Frontend {0}" -f $frontendVerifyReportPath)
Write-Host ("Smoke   {0}" -f $vmSmokeReportPath)
Write-Host ("Verify  {0}" -f $runtimeVerifyReportPath)
Write-Host ("Showcase {0}" -f $showcaseReportPath)
Write-Host ("Banks   {0}" -f $generatedBankLayoutPath)
Write-Host ("Bank    {0}" -f $codeBankBinPath)
Write-Host ("Bank    {0}" -f $textureBankBinPath)
Write-Host ("Bank    {0}" -f $mapBankBinPath)
Write-Host ("Bank    {0}" -f $presentationBankBinPath)
Write-Host ("Bank    {0}" -f $geometryBankBinPath)
foreach ($readmeShot in $readmeScreenshotArtifacts) {
    Write-Host ("Shot    {0}" -f $readmeShot)
}
Write-Host ("Listing {0}" -f $bootList)
Write-Host ("Listing {0}" -f $gameList)
Write-Host ("Config  {0}" -f $debugConfig)
Write-Host ("Config  {0}" -f $audioConfig)
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
