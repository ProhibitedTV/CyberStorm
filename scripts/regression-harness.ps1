param(
    [string]$BootConfigPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\boot_config.inc'),
    [string]$BankLayoutPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\generated_bank_layout.inc'),
    [string]$BootBinaryPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm-boot.bin'),
    [string]$BootstrapBinaryPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm-bootstrap.bin'),
    [string]$Stage2BinaryPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm-stage2.bin'),
    [string]$CodeBankBinaryPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm-code-bank.bin'),
    [string]$TextureBankBinaryPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm-texture-bank.bin'),
    [string]$TextureBankBBinaryPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm-texture-bank-b.bin'),
    [string]$MapBankBinaryPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm-map-bank.bin'),
    [string]$PresentationBankBinaryPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm-presentation-bank.bin'),
    [string]$GeometryBankBinaryPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm-geometry-bank.bin'),
    [string]$ImagePath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm.img'),
    [string]$BootListPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\boot.lst'),
    [string]$BootstrapListPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\bootstrap.lst'),
    [string]$GameListPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\game.lst'),
    [string]$ReportPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm-regression-report.txt')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$layout = [pscustomobject]@{
    SectorBytes             = 512
    BootCodeLimitBytes      = 510
    Stage2LoadLimitBytes    = 0x10000
    AssetBankLoadLimitBytes = 0x10000
    BootstrapStartLba       = 1
    BootstrapLoadSegment    = 0x0800
    Stage2LoadSegment       = 0x1000
    Stage2LoadOffset        = 0x0000
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

function Get-AsmEquValue {
    param(
        [string]$SourcePath,
        [string]$Name
    )

    Assert-PathExists -Path $SourcePath -Label 'assembly include'
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

function Format-Hex16 {
    param([int]$Value)
    return ("0x{0:X4}" -f ($Value -band 0xFFFF))
}

function Get-SectorCount {
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

    return [int][Math]::Ceiling($ByteCount / $SectorBytes)
}

function Assert-ImageRangeMatches {
    param(
        [byte[]]$ImageBytes,
        [int]$Offset,
        [byte[]]$ExpectedBytes,
        [string]$Label
    )

    if (($Offset + $ExpectedBytes.Length) -gt $ImageBytes.Length) {
        throw ("{0} exceeds the image bounds at byte {1}." -f $Label, $Offset)
    }

    for ($i = 0; $i -lt $ExpectedBytes.Length; $i++) {
        if ($ImageBytes[$Offset + $i] -ne $ExpectedBytes[$i]) {
            throw ("{0} differ from the image at byte {1}." -f $Label, ($Offset + $i))
        }
    }
}

function Assert-ZeroFill {
    param(
        [byte[]]$Bytes,
        [int]$Offset,
        [int]$Length,
        [string]$Label
    )

    if ($Length -le 0) {
        return
    }

    if (($Offset + $Length) -gt $Bytes.Length) {
        throw ("{0} zero-fill range exceeds bounds at byte {1}." -f $Label, $Offset)
    }

    for ($i = 0; $i -lt $Length; $i++) {
        if ($Bytes[$Offset + $i] -ne 0) {
            throw ("{0} zero-fill failed at byte {1}." -f $Label, ($Offset + $i))
        }
    }
}

function Get-StageEntryInfo {
    param([byte[]]$Stage2Bytes)

    if ($Stage2Bytes.Length -lt 1) {
        throw 'Stage-two binary is empty.'
    }

    $opcode = [int]$Stage2Bytes[0]
    switch ($opcode) {
        0xE9 {
            if ($Stage2Bytes.Length -lt 3) {
                throw 'Stage-two near jump entry is truncated.'
            }

            $disp = [BitConverter]::ToInt16($Stage2Bytes, 1)
            $target = 3 + $disp
            if ($target -lt 0 -or $target -ge $Stage2Bytes.Length) {
                throw ("Stage-two entry jump target is outside the payload: {0}" -f (Format-Hex16 $target))
            }

            return [pscustomobject]@{
                Description = ("near jmp to {0}" -f (Format-Hex16 $target))
                Warning = $null
            }
        }
        0xEB {
            if ($Stage2Bytes.Length -lt 2) {
                throw 'Stage-two short jump entry is truncated.'
            }

            $disp = [sbyte]$Stage2Bytes[1]
            $target = 2 + $disp
            if ($target -lt 0 -or $target -ge $Stage2Bytes.Length) {
                throw ("Stage-two short entry jump target is outside the payload: {0}" -f (Format-Hex16 $target))
            }

            return [pscustomobject]@{
                Description = ("short jmp to {0}" -f (Format-Hex16 $target))
                Warning = $null
            }
        }
        default {
            return [pscustomobject]@{
                Description = ("opcode 0x{0:X2} at byte 0" -f $opcode)
                Warning = ("Stage-two entry no longer begins with a jump opcode. Byte 0 is 0x{0:X2}; verify the documented offset-0 handoff intentionally stayed executable." -f $opcode)
            }
        }
    }
}

$warningLines = New-Object 'System.Collections.Generic.List[string]'
$summaryLines = New-Object 'System.Collections.Generic.List[string]'
$reportLines = New-Object 'System.Collections.Generic.List[string]'

Assert-PathExists -Path $BootConfigPath -Label 'boot config include'
Assert-PathExists -Path $BankLayoutPath -Label 'bank layout include'
Assert-PathExists -Path $BootBinaryPath -Label 'boot binary'
Assert-PathExists -Path $BootstrapBinaryPath -Label 'bootstrap binary'
Assert-PathExists -Path $Stage2BinaryPath -Label 'stage-two binary'
Assert-PathExists -Path $CodeBankBinaryPath -Label 'code bank binary'
Assert-PathExists -Path $TextureBankBinaryPath -Label 'texture bank binary'
Assert-PathExists -Path $TextureBankBBinaryPath -Label 'texture bank B binary'
Assert-PathExists -Path $MapBankBinaryPath -Label 'map bank binary'
Assert-PathExists -Path $PresentationBankBinaryPath -Label 'presentation bank binary'
Assert-PathExists -Path $GeometryBankBinaryPath -Label 'geometry bank binary'
Assert-PathExists -Path $ImagePath -Label 'disk image'
Assert-PathExists -Path $BootListPath -Label 'boot listing'
Assert-PathExists -Path $BootstrapListPath -Label 'bootstrap listing'
Assert-PathExists -Path $GameListPath -Label 'stage-two listing'

$bootBytes = [IO.File]::ReadAllBytes($BootBinaryPath)
$bootstrapBytes = [IO.File]::ReadAllBytes($BootstrapBinaryPath)
$stage2Bytes = [IO.File]::ReadAllBytes($Stage2BinaryPath)
$codeBankBytes = [IO.File]::ReadAllBytes($CodeBankBinaryPath)
$textureBankBytes = [IO.File]::ReadAllBytes($TextureBankBinaryPath)
$textureBankBBytes = [IO.File]::ReadAllBytes($TextureBankBBinaryPath)
$mapBankBytes = [IO.File]::ReadAllBytes($MapBankBinaryPath)
$presentationBankBytes = [IO.File]::ReadAllBytes($PresentationBankBinaryPath)
$geometryBankBytes = [IO.File]::ReadAllBytes($GeometryBankBinaryPath)
$imageBytes = [IO.File]::ReadAllBytes($ImagePath)

if ($bootBytes.Length -ne $layout.SectorBytes) {
    throw ("Boot binary must be exactly one sector ({0} bytes). Found {1}." -f $layout.SectorBytes, $bootBytes.Length)
}

if ($bootBytes[510] -ne 0x55 -or $bootBytes[511] -ne 0xAA) {
    throw 'Boot binary is missing the 0x55AA signature at byte 510.'
}

$bootstrapSectors = Get-SectorCount -ByteCount $bootstrapBytes.Length -SectorBytes $layout.SectorBytes
$bootstrapPaddedBytes = $bootstrapSectors * $layout.SectorBytes
$configuredBootstrapSectors = Get-AsmEquValue -SourcePath $BootConfigPath -Name 'BOOTSTRAP_SECTORS'
if ($configuredBootstrapSectors -ne $bootstrapSectors) {
    throw ("BOOTSTRAP_SECTORS says {0}, but the bootstrap binary needs {1} sectors." -f $configuredBootstrapSectors, $bootstrapSectors)
}

$stage2Sectors = Get-SectorCount -ByteCount $stage2Bytes.Length -SectorBytes $layout.SectorBytes
$stage2PaddedBytes = $stage2Sectors * $layout.SectorBytes
if ($stage2PaddedBytes -gt $layout.Stage2LoadLimitBytes) {
    throw ("Stage-two occupies {0} padded bytes, which exceeds the single-segment load contract ({1})." -f $stage2PaddedBytes, $layout.Stage2LoadLimitBytes)
}

$configuredStage2Sectors = Get-AsmEquValue -SourcePath $BootConfigPath -Name 'GAME_SECTORS'
if ($configuredStage2Sectors -ne $stage2Sectors) {
    throw ("GAME_SECTORS says {0}, but the stage-two binary needs {1} sectors." -f $configuredStage2Sectors, $stage2Sectors)
}

$configuredStage2Lba = Get-AsmEquValue -SourcePath $BootConfigPath -Name 'STAGE2_LBA'
$expectedStage2Lba = $layout.BootstrapStartLba + $bootstrapSectors
if ($configuredStage2Lba -ne $expectedStage2Lba) {
    throw ("STAGE2_LBA says {0}, but the stage-two payload should begin at LBA {1}." -f $configuredStage2Lba, $expectedStage2Lba)
}

$bankDescriptors = @(
    [pscustomobject]@{ Name = 'Code bank'; Symbol = 'CODE_BANK'; Bytes = $codeBankBytes; Path = $CodeBankBinaryPath },
    [pscustomobject]@{ Name = 'Texture bank A'; Symbol = 'TEXTURE_BANK'; Bytes = $textureBankBytes; Path = $TextureBankBinaryPath },
    [pscustomobject]@{ Name = 'Texture bank B'; Symbol = 'TEXTURE_BANK_B'; Bytes = $textureBankBBytes; Path = $TextureBankBBinaryPath },
    [pscustomobject]@{ Name = 'Map bank'; Symbol = 'MAP_BANK'; Bytes = $mapBankBytes; Path = $MapBankBinaryPath },
    [pscustomobject]@{ Name = 'Presentation bank'; Symbol = 'PRESENT_BANK'; Bytes = $presentationBankBytes; Path = $PresentationBankBinaryPath },
    [pscustomobject]@{ Name = 'Geometry bank'; Symbol = 'GEOMETRY_BANK'; Bytes = $geometryBankBytes; Path = $GeometryBankBinaryPath }
)

$resolvedBanks = New-Object 'System.Collections.Generic.List[object]'
$expectedBankLba = $configuredStage2Lba + $stage2Sectors
foreach ($bankDescriptor in $bankDescriptors) {
    $configuredBytes = Get-AsmEquValue -SourcePath $BankLayoutPath -Name ("{0}_BYTES" -f $bankDescriptor.Symbol)
    $bankLba = Get-AsmEquValue -SourcePath $BankLayoutPath -Name ("{0}_LBA" -f $bankDescriptor.Symbol)
    $bankSectors = Get-AsmEquValue -SourcePath $BankLayoutPath -Name ("{0}_SECTORS" -f $bankDescriptor.Symbol)
    $bankPaddedBytes = Get-AsmEquValue -SourcePath $BankLayoutPath -Name ("{0}_PADDED_BYTES" -f $bankDescriptor.Symbol)

    if ($configuredBytes -ne $bankDescriptor.Bytes.Length) {
        throw ("{0}_BYTES says {1}, but {2} is {3} bytes." -f $bankDescriptor.Symbol, $configuredBytes, [IO.Path]::GetFileName($bankDescriptor.Path), $bankDescriptor.Bytes.Length)
    }

    if ($bankPaddedBytes -ne ($bankSectors * $layout.SectorBytes)) {
        throw ("{0}_PADDED_BYTES says {1}, but {0}_SECTORS implies {2} bytes." -f $bankDescriptor.Symbol, $bankPaddedBytes, ($bankSectors * $layout.SectorBytes))
    }

    if ($bankPaddedBytes -gt $layout.AssetBankLoadLimitBytes) {
        throw ("{0} occupies {1} padded bytes, which exceeds the current single-segment bank load limit ({2})." -f $bankDescriptor.Name, $bankPaddedBytes, $layout.AssetBankLoadLimitBytes)
    }

    if ($bankLba -ne $expectedBankLba) {
        throw ("{0}_LBA says {1}, but the bank should begin at LBA {2}." -f $bankDescriptor.Symbol, $bankLba, $expectedBankLba)
    }

    $resolvedBanks.Add([pscustomobject]@{
        Name = $bankDescriptor.Name
        Bytes = $bankDescriptor.Bytes
        Path = $bankDescriptor.Path
        Lba = $bankLba
        Sectors = $bankSectors
        PaddedBytes = $bankPaddedBytes
    })

    $expectedBankLba = $bankLba + $bankSectors
}

Assert-ImageRangeMatches -ImageBytes $imageBytes -Offset 0 -ExpectedBytes $bootBytes -Label 'Boot sector image range'
Assert-ImageRangeMatches -ImageBytes $imageBytes -Offset ($layout.BootstrapStartLba * $layout.SectorBytes) -ExpectedBytes $bootstrapBytes -Label 'Bootstrap image range'
Assert-ZeroFill -Bytes $imageBytes -Offset (($layout.BootstrapStartLba * $layout.SectorBytes) + $bootstrapBytes.Length) -Length ($bootstrapPaddedBytes - $bootstrapBytes.Length) -Label 'Bootstrap sector padding'
Assert-ImageRangeMatches -ImageBytes $imageBytes -Offset ($configuredStage2Lba * $layout.SectorBytes) -ExpectedBytes $stage2Bytes -Label 'Stage-two image range'
Assert-ZeroFill -Bytes $imageBytes -Offset (($configuredStage2Lba * $layout.SectorBytes) + $stage2Bytes.Length) -Length ($stage2PaddedBytes - $stage2Bytes.Length) -Label 'Stage-two sector padding'
foreach ($bank in $resolvedBanks.ToArray()) {
    Assert-ImageRangeMatches -ImageBytes $imageBytes -Offset ($bank.Lba * $layout.SectorBytes) -ExpectedBytes $bank.Bytes -Label ("{0} image range" -f $bank.Name)
    Assert-ZeroFill -Bytes $imageBytes -Offset (($bank.Lba * $layout.SectorBytes) + $bank.Bytes.Length) -Length ($bank.PaddedBytes - $bank.Bytes.Length) -Label ("{0} sector padding" -f $bank.Name)
}

$resolvedBankArray = $resolvedBanks.ToArray()
$diskFootprintBytes = $layout.SectorBytes + $bootstrapPaddedBytes + $stage2PaddedBytes + ((@($resolvedBankArray) | Measure-Object -Property PaddedBytes -Sum).Sum)
Assert-ZeroFill -Bytes $imageBytes -Offset $diskFootprintBytes -Length ($imageBytes.Length - $diskFootprintBytes) -Label 'Unused HDD tail'

$entryInfo = Get-StageEntryInfo -Stage2Bytes $stage2Bytes
if ($entryInfo.Warning) {
    $warningLines.Add($entryInfo.Warning)
}

$summaryLines.Add("Boot sector: 512 bytes, signature 0x55AA, LBA 0 matches the disk image")
$summaryLines.Add(("Bootstrap: {0} bytes, {1} sectors, LBA {2}..{3}" -f $bootstrapBytes.Length, $bootstrapSectors, $layout.BootstrapStartLba, ($layout.BootstrapStartLba + $bootstrapSectors - 1)))
$summaryLines.Add(("Stage two: {0} bytes, {1} sectors, STAGE2_LBA matches, entry {2}" -f $stage2Bytes.Length, $stage2Sectors, $entryInfo.Description))
foreach ($bank in $resolvedBankArray) {
    $summaryLines.Add(("{0}: {1} bytes ({2} padded), {3} sectors, LBA {4}..{5}" -f $bank.Name, $bank.Bytes.Length, $bank.PaddedBytes, $bank.Sectors, $bank.Lba, ($bank.Lba + $bank.Sectors - 1)))
}
$summaryLines.Add(("Disk image: {0} bytes, occupied through byte {1}, unused tail zero-filled" -f $imageBytes.Length, ($diskFootprintBytes - 1)))
$summaryLines.Add('Diagnostics: boot.lst, bootstrap.lst, and game.lst are present for post-failure inspection')

$reportLines.Add('CyberStorm Regression Harness')
$reportLines.Add(("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')))
$reportLines.Add('')
$reportLines.Add('Contract Checks')
$reportLines.Add(("  Boot sector: 512 bytes, signature 0x55AA, boot code limit still {0} bytes before the signature" -f $layout.BootCodeLimitBytes))
$reportLines.Add(("  Bootstrap: {0} bytes, {1} sectors, load {2}:0000, LBA {3}..{4}" -f $bootstrapBytes.Length, $bootstrapSectors, (Format-Hex16 $layout.BootstrapLoadSegment), $layout.BootstrapStartLba, ($layout.BootstrapStartLba + $bootstrapSectors - 1)))
$reportLines.Add(("  Stage2: {0} bytes, {1} sectors, load {2}:{3}, entry {4}" -f $stage2Bytes.Length, $stage2Sectors, (Format-Hex16 $layout.Stage2LoadSegment), (Format-Hex16 $layout.Stage2LoadOffset), $entryInfo.Description))
foreach ($bank in $resolvedBankArray) {
    $reportLines.Add(("  {0}: {1} bytes ({2} padded), {3} sectors, LBA {4}..{5}" -f $bank.Name, $bank.Bytes.Length, $bank.PaddedBytes, $bank.Sectors, $bank.Lba, ($bank.Lba + $bank.Sectors - 1)))
}
$reportLines.Add(("  Disk image: {0} bytes, occupied through byte {1}, unused tail zero-filled" -f $imageBytes.Length, ($diskFootprintBytes - 1)))
$reportLines.Add('')
$reportLines.Add('Artifacts')
$reportLines.Add(("  Boot binary: {0}" -f $BootBinaryPath))
$reportLines.Add(("  Bootstrap binary: {0}" -f $BootstrapBinaryPath))
$reportLines.Add(("  Stage-two binary: {0}" -f $Stage2BinaryPath))
foreach ($bank in $resolvedBankArray) {
    $reportLines.Add(("  {0}: {1}" -f $bank.Name, $bank.Path))
}
$reportLines.Add(("  Disk image: {0}" -f $ImagePath))
$reportLines.Add(("  Listings: {0}, {1}, {2}" -f $BootListPath, $BootstrapListPath, $GameListPath))
$reportLines.Add('')
$reportLines.Add('Warnings')
if ($warningLines.Count -eq 0) {
    $reportLines.Add('  none')
} else {
    foreach ($warning in $warningLines) {
        $reportLines.Add(("  {0}" -f $warning))
    }
}

Set-Content -LiteralPath $ReportPath -Encoding ascii -Value $reportLines

return [pscustomobject]@{
    ReportPath = $ReportPath
    SummaryLines = $summaryLines.ToArray()
    WarningLines = $warningLines.ToArray()
}
