param(
    [Parameter(Mandatory = $true)]
    [string]$BootImagePath,
    [Parameter(Mandatory = $true)]
    [string]$PackDirectoryPath,
    [Parameter(Mandatory = $true)]
    [string]$ManifestPath,
    [Parameter(Mandatory = $true)]
    [string]$IsoPath,
    [string]$VolumeId = 'CYBERSTORM_EXPANDED'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sectorBytes = 2048

function Assert-PathExists {
    param(
        [string]$Path,
        [string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw ("Missing {0}: {1}" -f $Label, $Path)
    }
}

function Set-AsciiField {
    param(
        [byte[]]$Bytes,
        [int]$Offset,
        [int]$Length,
        [string]$Value
    )

    $encoded = [Text.Encoding]::ASCII.GetBytes($Value)
    $limit = [Math]::Min($Length, $encoded.Length)
    for ($i = 0; $i -lt $Length; $i++) {
        $Bytes[$Offset + $i] = 0x20
    }
    [Array]::Copy($encoded, 0, $Bytes, $Offset, $limit)
}

function Set-UInt16Le {
    param([byte[]]$Bytes, [int]$Offset, [int]$Value)
    $Bytes[$Offset] = [byte]($Value -band 0xFF)
    $Bytes[$Offset + 1] = [byte](($Value -shr 8) -band 0xFF)
}

function Set-UInt16Be {
    param([byte[]]$Bytes, [int]$Offset, [int]$Value)
    $Bytes[$Offset] = [byte](($Value -shr 8) -band 0xFF)
    $Bytes[$Offset + 1] = [byte]($Value -band 0xFF)
}

function Set-UInt32Le {
    param([byte[]]$Bytes, [int]$Offset, [uint32]$Value)
    $Bytes[$Offset] = [byte]($Value -band 0xFF)
    $Bytes[$Offset + 1] = [byte](($Value -shr 8) -band 0xFF)
    $Bytes[$Offset + 2] = [byte](($Value -shr 16) -band 0xFF)
    $Bytes[$Offset + 3] = [byte](($Value -shr 24) -band 0xFF)
}

function Set-UInt32Be {
    param([byte[]]$Bytes, [int]$Offset, [uint32]$Value)
    $Bytes[$Offset] = [byte](($Value -shr 24) -band 0xFF)
    $Bytes[$Offset + 1] = [byte](($Value -shr 16) -band 0xFF)
    $Bytes[$Offset + 2] = [byte](($Value -shr 8) -band 0xFF)
    $Bytes[$Offset + 3] = [byte]($Value -band 0xFF)
}

function Set-UInt16Both {
    param([byte[]]$Bytes, [int]$Offset, [int]$Value)
    Set-UInt16Le -Bytes $Bytes -Offset $Offset -Value $Value
    Set-UInt16Be -Bytes $Bytes -Offset ($Offset + 2) -Value $Value
}

function Set-UInt32Both {
    param([byte[]]$Bytes, [int]$Offset, [uint32]$Value)
    Set-UInt32Le -Bytes $Bytes -Offset $Offset -Value $Value
    Set-UInt32Be -Bytes $Bytes -Offset ($Offset + 4) -Value $Value
}

function New-IsoTimestamp {
    $now = [DateTime]::UtcNow
    return [byte[]]@(
        [byte]($now.Year - 1900),
        [byte]$now.Month,
        [byte]$now.Day,
        [byte]$now.Hour,
        [byte]$now.Minute,
        [byte]$now.Second,
        [byte]0
    )
}

function New-IsoDirectoryRecord {
    param(
        [uint32]$ExtentLba,
        [uint32]$DataLength,
        [byte]$Flags,
        [byte[]]$FileId
    )

    $recordLength = 33 + $FileId.Length
    if (($FileId.Length % 2) -eq 0) {
        $recordLength++
    }

    $record = New-Object byte[] $recordLength
    $record[0] = [byte]$recordLength
    $record[1] = 0
    Set-UInt32Both -Bytes $record -Offset 2 -Value $ExtentLba
    Set-UInt32Both -Bytes $record -Offset 10 -Value $DataLength
    $stamp = New-IsoTimestamp
    [Array]::Copy($stamp, 0, $record, 18, $stamp.Length)
    $record[25] = $Flags
    $record[26] = 0
    $record[27] = 0
    Set-UInt16Both -Bytes $record -Offset 28 -Value 1
    $record[32] = [byte]$FileId.Length
    [Array]::Copy($FileId, 0, $record, 33, $FileId.Length)
    return $record
}

function Write-Sector {
    param(
        [IO.FileStream]$Stream,
        [int]$Lba,
        [byte[]]$Bytes
    )

    if ($Bytes.Length -gt $sectorBytes) {
        throw ("Sector payload is too large: {0} bytes" -f $Bytes.Length)
    }

    $Stream.Position = [int64]$Lba * $sectorBytes
    $Stream.Write($Bytes, 0, $Bytes.Length)
    if ($Bytes.Length -lt $sectorBytes) {
        $pad = New-Object byte[] ($sectorBytes - $Bytes.Length)
        $Stream.Write($pad, 0, $pad.Length)
    }
}

function Write-FileExtent {
    param(
        [IO.FileStream]$Stream,
        [int]$Lba,
        [string]$Path
    )

    $input = [IO.File]::OpenRead($Path)
    try {
        $Stream.Position = [int64]$Lba * $sectorBytes
        $buffer = New-Object byte[] (1024 * 1024)
        while (($read = $input.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $Stream.Write($buffer, 0, $read)
        }

        $remainder = $input.Length % $sectorBytes
        if ($remainder -ne 0) {
            $pad = New-Object byte[] ($sectorBytes - $remainder)
            $Stream.Write($pad, 0, $pad.Length)
        }
    } finally {
        $input.Dispose()
    }
}

function New-PrimaryVolumeDescriptor {
    param(
        [int]$TotalSectors,
        [int]$PathTableLba,
        [int]$PathTableMLba,
        [int]$RootDirLba,
        [int]$RootDirBytes,
        [string]$VolumeId
    )

    $pvd = New-Object byte[] $sectorBytes
    $pvd[0] = 1
    [Array]::Copy([Text.Encoding]::ASCII.GetBytes('CD001'), 0, $pvd, 1, 5)
    $pvd[6] = 1
    Set-AsciiField -Bytes $pvd -Offset 8 -Length 32 -Value 'CYBERSTORM'
    Set-AsciiField -Bytes $pvd -Offset 40 -Length 32 -Value $VolumeId.ToUpperInvariant()
    Set-UInt32Both -Bytes $pvd -Offset 80 -Value ([uint32]$TotalSectors)
    Set-UInt16Both -Bytes $pvd -Offset 120 -Value 1
    Set-UInt16Both -Bytes $pvd -Offset 124 -Value 1
    Set-UInt16Both -Bytes $pvd -Offset 128 -Value $sectorBytes
    Set-UInt32Both -Bytes $pvd -Offset 132 -Value 10
    Set-UInt32Le -Bytes $pvd -Offset 140 -Value ([uint32]$PathTableLba)
    Set-UInt32Le -Bytes $pvd -Offset 144 -Value 0
    Set-UInt32Be -Bytes $pvd -Offset 148 -Value ([uint32]$PathTableMLba)
    Set-UInt32Be -Bytes $pvd -Offset 152 -Value 0
    $rootRecord = New-IsoDirectoryRecord -ExtentLba ([uint32]$RootDirLba) -DataLength ([uint32]$RootDirBytes) -Flags 2 -FileId ([byte[]]@(0))
    [Array]::Copy($rootRecord, 0, $pvd, 156, $rootRecord.Length)
    return $pvd
}

function New-BootRecordDescriptor {
    param([int]$BootCatalogLba)

    $descriptor = New-Object byte[] $sectorBytes
    $descriptor[0] = 0
    [Array]::Copy([Text.Encoding]::ASCII.GetBytes('CD001'), 0, $descriptor, 1, 5)
    $descriptor[6] = 1
    Set-AsciiField -Bytes $descriptor -Offset 7 -Length 32 -Value 'EL TORITO SPECIFICATION'
    Set-UInt32Le -Bytes $descriptor -Offset 71 -Value ([uint32]$BootCatalogLba)
    return $descriptor
}

function New-TerminatorDescriptor {
    $descriptor = New-Object byte[] $sectorBytes
    $descriptor[0] = 255
    [Array]::Copy([Text.Encoding]::ASCII.GetBytes('CD001'), 0, $descriptor, 1, 5)
    $descriptor[6] = 1
    return $descriptor
}

function New-BootCatalog {
    param([int]$BootImageLba)

    $catalog = New-Object byte[] $sectorBytes
    $catalog[0] = 1
    $catalog[1] = 0
    [Array]::Copy([Text.Encoding]::ASCII.GetBytes('CyberStorm expanded boot'), 0, $catalog, 4, 24)
    $catalog[30] = 0x55
    $catalog[31] = 0xAA

    $sum = 0
    for ($i = 0; $i -lt 32; $i += 2) {
        $sum = ($sum + [BitConverter]::ToUInt16($catalog, $i)) -band 0xFFFF
    }
    $checksum = ((0x10000 - $sum) -band 0xFFFF)
    Set-UInt16Le -Bytes $catalog -Offset 28 -Value $checksum

    $catalog[32] = 0x88
    $catalog[33] = 4
    Set-UInt16Le -Bytes $catalog -Offset 34 -Value 0
    $catalog[36] = 0
    $catalog[37] = 0
    Set-UInt16Le -Bytes $catalog -Offset 38 -Value 1
    Set-UInt32Le -Bytes $catalog -Offset 40 -Value ([uint32]$BootImageLba)
    return $catalog
}

function New-PathTable {
    param(
        [int]$RootDirLba,
        [switch]$BigEndian
    )

    $pathTable = New-Object byte[] 10
    $pathTable[0] = 1
    $pathTable[1] = 0
    if ($BigEndian.IsPresent) {
        Set-UInt32Be -Bytes $pathTable -Offset 2 -Value ([uint32]$RootDirLba)
        Set-UInt16Be -Bytes $pathTable -Offset 6 -Value 1
    } else {
        Set-UInt32Le -Bytes $pathTable -Offset 2 -Value ([uint32]$RootDirLba)
        Set-UInt16Le -Bytes $pathTable -Offset 6 -Value 1
    }
    $pathTable[8] = 0
    $pathTable[9] = 0
    return $pathTable
}

Assert-PathExists -Path $BootImagePath -Label 'expanded boot image'
Assert-PathExists -Path $PackDirectoryPath -Label 'expanded pack directory'
Assert-PathExists -Path $ManifestPath -Label 'expanded manifest'

$files = @(
    [pscustomobject]@{ Id = 'CYBERSTM.IMG;1'; Path = $BootImagePath; Label = 'boot image' },
    [pscustomobject]@{ Id = 'PACKDIR.BIN;1'; Path = $PackDirectoryPath; Label = 'pack directory' },
    [pscustomobject]@{ Id = 'MANIFEST.TXT;1'; Path = $ManifestPath; Label = 'manifest' }
)

$bootCatalogLba = 19
$pathTableLba = 20
$pathTableMLba = 21
$rootDirLba = 22
$nextLba = 23

foreach ($file in $files) {
    $length = (Get-Item -LiteralPath $file.Path).Length
    $sectors = [int][Math]::Ceiling($length / $sectorBytes)
    Add-Member -InputObject $file -NotePropertyName Lba -NotePropertyValue $nextLba
    Add-Member -InputObject $file -NotePropertyName Length -NotePropertyValue ([uint32]$length)
    Add-Member -InputObject $file -NotePropertyName Sectors -NotePropertyValue $sectors
    $nextLba += $sectors
}

$totalSectors = $nextLba
$rootSector = New-Object byte[] $sectorBytes
$cursor = 0
foreach ($record in @(
    (New-IsoDirectoryRecord -ExtentLba ([uint32]$rootDirLba) -DataLength ([uint32]$sectorBytes) -Flags 2 -FileId ([byte[]]@(0))),
    (New-IsoDirectoryRecord -ExtentLba ([uint32]$rootDirLba) -DataLength ([uint32]$sectorBytes) -Flags 2 -FileId ([byte[]]@(1)))
)) {
    [Array]::Copy($record, 0, $rootSector, $cursor, $record.Length)
    $cursor += $record.Length
}

foreach ($file in $files) {
    $record = New-IsoDirectoryRecord -ExtentLba ([uint32]$file.Lba) -DataLength ([uint32]$file.Length) -Flags 0 -FileId ([Text.Encoding]::ASCII.GetBytes($file.Id))
    if (($cursor + $record.Length) -gt $sectorBytes) {
        throw 'Root directory sector overflowed.'
    }
    [Array]::Copy($record, 0, $rootSector, $cursor, $record.Length)
    $cursor += $record.Length
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $IsoPath) | Out-Null
$stream = [IO.File]::Open($IsoPath, [IO.FileMode]::Create, [IO.FileAccess]::ReadWrite)
try {
    $stream.SetLength([int64]$totalSectors * $sectorBytes)
    Write-Sector -Stream $stream -Lba 16 -Bytes (New-PrimaryVolumeDescriptor -TotalSectors $totalSectors -PathTableLba $pathTableLba -PathTableMLba $pathTableMLba -RootDirLba $rootDirLba -RootDirBytes $sectorBytes -VolumeId $VolumeId)
    Write-Sector -Stream $stream -Lba 17 -Bytes (New-BootRecordDescriptor -BootCatalogLba $bootCatalogLba)
    Write-Sector -Stream $stream -Lba 18 -Bytes (New-TerminatorDescriptor)
    Write-Sector -Stream $stream -Lba $bootCatalogLba -Bytes (New-BootCatalog -BootImageLba $files[0].Lba)
    Write-Sector -Stream $stream -Lba $pathTableLba -Bytes (New-PathTable -RootDirLba $rootDirLba)
    Write-Sector -Stream $stream -Lba $pathTableMLba -Bytes (New-PathTable -RootDirLba $rootDirLba -BigEndian)
    Write-Sector -Stream $stream -Lba $rootDirLba -Bytes $rootSector
    foreach ($file in $files) {
        Write-FileExtent -Stream $stream -Lba $file.Lba -Path $file.Path
    }
} finally {
    $stream.Dispose()
}

return [pscustomobject]@{
    IsoPath = $IsoPath
    VolumeId = $VolumeId
    SectorBytes = $sectorBytes
    TotalSectors = $totalSectors
    TotalBytes = (Get-Item -LiteralPath $IsoPath).Length
    BootCatalogLba = $bootCatalogLba
    BootImageLba = $files[0].Lba
    FileSummary = ($files | ForEach-Object { "{0}: LBA {1}, {2} bytes" -f $_.Id, $_.Lba, $_.Length })
}
