param(
    [string]$BootConfigPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\boot_config.inc'),
    [string]$BankLayoutPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\generated_bank_layout.inc'),
    [string]$BootBinaryPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm-boot.bin'),
    [string]$Stage2BinaryPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm-stage2.bin'),
    [string]$MapBankBinaryPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm-map-bank.bin'),
    [string]$ImagePath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm.img'),
    [string]$VfdPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm.vfd'),
    [string]$BootListPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\boot.lst'),
    [string]$GameListPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\game.lst'),
    [string]$ReportPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm-regression-report.txt')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$layout = [pscustomobject]@{
    SectorBytes             = 512
    FloppyBytes             = 1474560
    BootCodeLimitBytes      = 510
    Stage2LoadLimitBytes    = 0x10000
    AssetBankLoadLimitBytes = 0x10000
    Stage2StartLba          = 1
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

function Format-Hex32 {
    param([int]$Value)
    return ("0x{0:X8}" -f ($Value -band 0xFFFFFFFF))
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

function Get-FirstDifferenceOffset {
    param(
        [byte[]]$Left,
        [byte[]]$Right
    )

    $limit = [Math]::Min($Left.Length, $Right.Length)
    for ($i = 0; $i -lt $limit; $i++) {
        if ($Left[$i] -ne $Right[$i]) {
            return $i
        }
    }

    if ($Left.Length -ne $Right.Length) {
        return $limit
    }

    return -1
}

function Assert-ByteArraysEqual {
    param(
        [byte[]]$Expected,
        [byte[]]$Actual,
        [string]$Label
    )

    $difference = Get-FirstDifferenceOffset -Left $Expected -Right $Actual
    if ($difference -ge 0) {
        throw ("{0} differ at byte {1}." -f $Label, $difference)
    }
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
                Opcode = ("0x{0:X2}" -f $opcode)
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
                Opcode = ("0x{0:X2}" -f $opcode)
                Description = ("short jmp to {0}" -f (Format-Hex16 $target))
                Warning = $null
            }
        }
        0xEA {
            if ($Stage2Bytes.Length -lt 5) {
                throw 'Stage-two far jump entry is truncated.'
            }

            $offset = [BitConverter]::ToUInt16($Stage2Bytes, 1)
            $segment = [BitConverter]::ToUInt16($Stage2Bytes, 3)
            return [pscustomobject]@{
                Opcode = ("0x{0:X2}" -f $opcode)
                Description = ("far jmp to {0}:{1}" -f (Format-Hex16 $segment), (Format-Hex16 $offset))
                Warning = $null
            }
        }
        default {
            return [pscustomobject]@{
                Opcode = ("0x{0:X2}" -f $opcode)
                Description = ("opcode {0} at byte 0" -f ("0x{0:X2}" -f $opcode))
                Warning = ("Stage-two entry no longer begins with a jump opcode. Byte 0 is {0}; verify the documented offset-0 handoff intentionally stayed executable." -f ("0x{0:X2}" -f $opcode))
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
Assert-PathExists -Path $Stage2BinaryPath -Label 'stage-two binary'
Assert-PathExists -Path $MapBankBinaryPath -Label 'map bank binary'
Assert-PathExists -Path $ImagePath -Label 'disk image'
Assert-PathExists -Path $VfdPath -Label 'floppy image'
Assert-PathExists -Path $BootListPath -Label 'boot listing'
Assert-PathExists -Path $GameListPath -Label 'stage-two listing'

$bootBytes = [IO.File]::ReadAllBytes($BootBinaryPath)
$stage2Bytes = [IO.File]::ReadAllBytes($Stage2BinaryPath)
$mapBankBytes = [IO.File]::ReadAllBytes($MapBankBinaryPath)
$imageBytes = [IO.File]::ReadAllBytes($ImagePath)
$vfdBytes = [IO.File]::ReadAllBytes($VfdPath)

if ($bootBytes.Length -ne $layout.SectorBytes) {
    throw ("Boot binary must be exactly one sector ({0} bytes). Found {1}." -f $layout.SectorBytes, $bootBytes.Length)
}

if ($bootBytes[510] -ne 0x55 -or $bootBytes[511] -ne 0xAA) {
    throw 'Boot binary is missing the 0x55AA signature at byte 510.'
}

if ($stage2Bytes.Length -le 0) {
    throw 'Stage-two binary must not be empty.'
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

$mapBankLba = Get-AsmEquValue -SourcePath $BankLayoutPath -Name 'MAP_BANK_LBA'
$mapBankSectors = Get-AsmEquValue -SourcePath $BankLayoutPath -Name 'MAP_BANK_SECTORS'
$configuredMapBankBytes = Get-AsmEquValue -SourcePath $BankLayoutPath -Name 'MAP_BANK_BYTES'
$mapBankPaddedBytes = Get-AsmEquValue -SourcePath $BankLayoutPath -Name 'MAP_BANK_PADDED_BYTES'

if ($configuredMapBankBytes -ne $mapBankBytes.Length) {
    throw ("MAP_BANK_BYTES says {0}, but cyberstorm-map-bank.bin is {1} bytes." -f $configuredMapBankBytes, $mapBankBytes.Length)
}

if ($mapBankPaddedBytes -ne ($mapBankSectors * $layout.SectorBytes)) {
    throw ("MAP_BANK_PADDED_BYTES says {0}, but MAP_BANK_SECTORS implies {1} bytes." -f $mapBankPaddedBytes, ($mapBankSectors * $layout.SectorBytes))
}

if ($mapBankPaddedBytes -gt $layout.AssetBankLoadLimitBytes) {
    throw ("Map bank occupies {0} padded bytes, which exceeds the current single-segment bank load limit ({1})." -f $mapBankPaddedBytes, $layout.AssetBankLoadLimitBytes)
}

$expectedMapBankLba = $layout.Stage2StartLba + $stage2Sectors
if ($mapBankLba -ne $expectedMapBankLba) {
    throw ("MAP_BANK_LBA says {0}, but the bank should begin immediately after stage two at LBA {1}." -f $mapBankLba, $expectedMapBankLba)
}

if ($imageBytes.Length -ne $layout.FloppyBytes) {
    throw ("cyberstorm.img must be {0} bytes. Found {1}." -f $layout.FloppyBytes, $imageBytes.Length)
}

if ($vfdBytes.Length -ne $layout.FloppyBytes) {
    throw ("cyberstorm.vfd must be {0} bytes. Found {1}." -f $layout.FloppyBytes, $vfdBytes.Length)
}

Assert-ByteArraysEqual -Expected $imageBytes -Actual $vfdBytes -Label 'cyberstorm.img and cyberstorm.vfd'
Assert-ImageRangeMatches -ImageBytes $imageBytes -Offset 0 -ExpectedBytes $bootBytes -Label 'Boot sector image range'
Assert-ImageRangeMatches -ImageBytes $imageBytes -Offset ($layout.Stage2StartLba * $layout.SectorBytes) -ExpectedBytes $stage2Bytes -Label 'Stage-two image range'
Assert-ZeroFill -Bytes $imageBytes -Offset (($layout.Stage2StartLba * $layout.SectorBytes) + $stage2Bytes.Length) -Length ($stage2PaddedBytes - $stage2Bytes.Length) -Label 'Stage-two sector padding'
Assert-ImageRangeMatches -ImageBytes $imageBytes -Offset ($mapBankLba * $layout.SectorBytes) -ExpectedBytes $mapBankBytes -Label 'Map bank image range'
Assert-ZeroFill -Bytes $imageBytes -Offset (($mapBankLba * $layout.SectorBytes) + $mapBankBytes.Length) -Length ($mapBankPaddedBytes - $mapBankBytes.Length) -Label 'Map bank sector padding'

$diskFootprintBytes = $layout.SectorBytes + $stage2PaddedBytes + $mapBankPaddedBytes
Assert-ZeroFill -Bytes $imageBytes -Offset $diskFootprintBytes -Length ($layout.FloppyBytes - $diskFootprintBytes) -Label 'Unused floppy tail'

$entryInfo = Get-StageEntryInfo -Stage2Bytes $stage2Bytes
if ($entryInfo.Warning) {
    $warningLines.Add($entryInfo.Warning)
}

$summaryLines.Add(("Boot sector: 512 bytes, signature 0x55AA, LBA 0 matches both image files"))
$summaryLines.Add(("Stage two: {0} bytes, {1} sectors, GAME_SECTORS matches, entry {2}" -f $stage2Bytes.Length, $stage2Sectors, $entryInfo.Description))
$summaryLines.Add(("Map bank: {0} bytes ({1} padded), {2} sectors, LBA {3}..{4}" -f $mapBankBytes.Length, $mapBankPaddedBytes, $mapBankSectors, $mapBankLba, ($mapBankLba + $mapBankSectors - 1)))
$summaryLines.Add(("Images: .img and .vfd match exactly, unused tail zero-filled from byte {0}" -f $diskFootprintBytes))
$summaryLines.Add(("Diagnostics: boot.lst and game.lst are present for post-failure inspection"))

$reportLines.Add('CyberStorm Regression Harness')
$reportLines.Add(("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')))
$reportLines.Add('')
$reportLines.Add('Contract Checks')
$reportLines.Add(("  Boot sector: 512 bytes, signature 0x55AA, boot code limit still {0} bytes before the signature" -f $layout.BootCodeLimitBytes))
$reportLines.Add(("  Stage2: {0} bytes, {1} sectors, load {2}:{3}, entry {4}" -f $stage2Bytes.Length, $stage2Sectors, (Format-Hex16 $layout.Stage2LoadSegment), (Format-Hex16 $layout.Stage2LoadOffset), $entryInfo.Description))
$reportLines.Add(("  Map bank: {0} bytes ({1} padded), {2} sectors, LBA {3}..{4}" -f $mapBankBytes.Length, $mapBankPaddedBytes, $mapBankSectors, $mapBankLba, ($mapBankLba + $mapBankSectors - 1)))
$reportLines.Add(("  Disk image: {0} bytes, occupied through byte {1}, unused tail zero-filled" -f $layout.FloppyBytes, ($diskFootprintBytes - 1)))
$reportLines.Add('')
$reportLines.Add('Artifacts')
$reportLines.Add(("  Boot binary: {0}" -f $BootBinaryPath))
$reportLines.Add(("  Stage-two binary: {0}" -f $Stage2BinaryPath))
$reportLines.Add(("  Map bank binary: {0}" -f $MapBankBinaryPath))
$reportLines.Add(("  Disk image: {0}" -f $ImagePath))
$reportLines.Add(("  Floppy image: {0}" -f $VfdPath))
$reportLines.Add(("  Listings: {0}, {1}" -f $BootListPath, $GameListPath))
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
