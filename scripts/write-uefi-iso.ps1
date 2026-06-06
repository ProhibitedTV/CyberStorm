param(
    [Parameter(Mandatory = $true)]
    [string]$EfiApplicationPath,
    [Parameter(Mandatory = $true)]
    [string]$IsoPath,
    [string[]]$PayloadPath = @(),
    [string]$VolumeId = 'CYBERSTORM_X64'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sectorBytes = 2048
$fatSectorBytes = 512

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

function Write-BytesExtent {
    param(
        [IO.FileStream]$Stream,
        [int]$Lba,
        [byte[]]$Bytes
    )

    $Stream.Position = [int64]$Lba * $sectorBytes
    $Stream.Write($Bytes, 0, $Bytes.Length)
    $remainder = $Bytes.Length % $sectorBytes
    if ($remainder -ne 0) {
        $pad = New-Object byte[] ($sectorBytes - $remainder)
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
    param(
        [int]$BootImageLba,
        [int]$BootImageVirtualSectors
    )

    $catalog = New-Object byte[] $sectorBytes
    $catalog[0] = 1
    $catalog[1] = 0xEF
    [Array]::Copy([Text.Encoding]::ASCII.GetBytes('CyberStorm x64 UEFI boot'), 0, $catalog, 4, 24)
    $catalog[30] = 0x55
    $catalog[31] = 0xAA

    $sum = 0
    for ($i = 0; $i -lt 32; $i += 2) {
        $sum = ($sum + [BitConverter]::ToUInt16($catalog, $i)) -band 0xFFFF
    }
    $checksum = ((0x10000 - $sum) -band 0xFFFF)
    Set-UInt16Le -Bytes $catalog -Offset 28 -Value $checksum

    $catalog[32] = 0x88
    $catalog[33] = 0
    Set-UInt16Le -Bytes $catalog -Offset 34 -Value 0
    $catalog[36] = 0
    $catalog[37] = 0
    Set-UInt16Le -Bytes $catalog -Offset 38 -Value $BootImageVirtualSectors
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

function Set-Fat12Entry {
    param(
        [byte[]]$Fat,
        [int]$Cluster,
        [int]$Value
    )

    $offset = [int][Math]::Floor(($Cluster * 3) / 2)
    if (($Cluster % 2) -eq 0) {
        $Fat[$offset] = [byte]($Value -band 0xFF)
        $Fat[$offset + 1] = [byte](($Fat[$offset + 1] -band 0xF0) -bor (($Value -shr 8) -band 0x0F))
    } else {
        $Fat[$offset] = [byte](($Fat[$offset] -band 0x0F) -bor (($Value -shl 4) -band 0xF0))
        $Fat[$offset + 1] = [byte](($Value -shr 4) -band 0xFF)
    }
}

function New-FatDirectoryEntry {
    param(
        [string]$Name,
        [byte]$Attributes,
        [int]$FirstCluster,
        [uint32]$Size
    )

    $entry = New-Object byte[] 32
    Set-AsciiField -Bytes $entry -Offset 0 -Length 11 -Value $Name
    $entry[11] = $Attributes
    Set-UInt16Le -Bytes $entry -Offset 26 -Value $FirstCluster
    Set-UInt32Le -Bytes $entry -Offset 28 -Value $Size
    return $entry
}

function ConvertTo-Fat83Name {
    param([string]$Path)

    $leaf = (Split-Path -Leaf $Path).ToUpperInvariant()
    $name = [IO.Path]::GetFileNameWithoutExtension($leaf)
    $extension = [IO.Path]::GetExtension($leaf).TrimStart('.')
    $name = ($name -replace '[^A-Z0-9_]', '')
    $extension = ($extension -replace '[^A-Z0-9_]', '')
    if ([string]::IsNullOrWhiteSpace($name) -or $name.Length -gt 8 -or $extension.Length -gt 3) {
        throw ("Payload file must use an 8.3 FAT-compatible name: {0}" -f $leaf)
    }

    return ("{0,-8}{1,-3}" -f $name, $extension)
}

function Copy-FatDirectoryEntry {
    param(
        [byte[]]$Directory,
        [int]$Index,
        [byte[]]$Entry
    )

    [Array]::Copy($Entry, 0, $Directory, $Index * 32, 32)
}

function New-EfiFatImage {
    param(
        [string]$EfiApplicationPath,
        [object[]]$PayloadFiles = @()
    )

    Assert-PathExists -Path $EfiApplicationPath -Label 'UEFI application'
    $efiBytes = [IO.File]::ReadAllBytes($EfiApplicationPath)

    $totalSectors = 2880
    $sectorsPerCluster = 1
    $reservedSectors = 1
    $fatCount = 2
    $rootEntries = 224
    $sectorsPerFat = 9
    $rootDirSectors = [int](($rootEntries * 32) / $fatSectorBytes)
    $firstFatSector = $reservedSectors
    $firstRootSector = $reservedSectors + ($fatCount * $sectorsPerFat)
    $firstDataSector = $firstRootSector + $rootDirSectors

    $fatFiles = New-Object 'System.Collections.Generic.List[object]'
    $nextFileCluster = 4
    foreach ($file in @(
        [pscustomobject]@{
            FatName = 'BOOTX64 EFI'
            Path = $EfiApplicationPath
            Bytes = $efiBytes
            RootEntry = $false
        }
    ) + @($PayloadFiles)) {
        $bytes = if ($null -ne $file.Bytes) { $file.Bytes } else { [IO.File]::ReadAllBytes($file.Path) }
        $clusterCount = [int][Math]::Ceiling($bytes.Length / ($fatSectorBytes * $sectorsPerCluster))
        if ($clusterCount -lt 1) {
            $clusterCount = 1
        }

        $fatFiles.Add([pscustomobject]@{
            FatName = $file.FatName
            Path = $file.Path
            Bytes = $bytes
            RootEntry = [bool]$file.RootEntry
            FirstCluster = $nextFileCluster
            ClusterCount = $clusterCount
        })
        $nextFileCluster += $clusterCount
    }

    $maxDataClusters = $totalSectors - $firstDataSector
    if (($nextFileCluster - 2) -gt $maxDataClusters) {
        $bytesRequired = ($nextFileCluster - 2) * $fatSectorBytes
        throw ("x64 FAT boot image payloads are too large: {0} bytes required" -f $bytesRequired)
    }

    $image = New-Object byte[] ($totalSectors * $fatSectorBytes)
    $image[0] = 0xEB
    $image[1] = 0x3C
    $image[2] = 0x90
    Set-AsciiField -Bytes $image -Offset 3 -Length 8 -Value 'CYBERUEF'
    Set-UInt16Le -Bytes $image -Offset 11 -Value $fatSectorBytes
    $image[13] = [byte]$sectorsPerCluster
    Set-UInt16Le -Bytes $image -Offset 14 -Value $reservedSectors
    $image[16] = [byte]$fatCount
    Set-UInt16Le -Bytes $image -Offset 17 -Value $rootEntries
    Set-UInt16Le -Bytes $image -Offset 19 -Value $totalSectors
    $image[21] = 0xF0
    Set-UInt16Le -Bytes $image -Offset 22 -Value $sectorsPerFat
    Set-UInt16Le -Bytes $image -Offset 24 -Value 18
    Set-UInt16Le -Bytes $image -Offset 26 -Value 2
    Set-UInt32Le -Bytes $image -Offset 28 -Value 0
    Set-UInt32Le -Bytes $image -Offset 32 -Value 0
    $image[36] = 0
    $image[37] = 0
    $image[38] = 0x29
    Set-UInt32Le -Bytes $image -Offset 39 -Value 0x43535964
    Set-AsciiField -Bytes $image -Offset 43 -Length 11 -Value 'CYBERX64'
    Set-AsciiField -Bytes $image -Offset 54 -Length 8 -Value 'FAT12'
    $image[510] = 0x55
    $image[511] = 0xAA

    $fat = New-Object byte[] ($sectorsPerFat * $fatSectorBytes)
    $fat[0] = 0xF0
    $fat[1] = 0xFF
    $fat[2] = 0xFF
    Set-Fat12Entry -Fat $fat -Cluster 2 -Value 0xFFF
    Set-Fat12Entry -Fat $fat -Cluster 3 -Value 0xFFF
    foreach ($file in $fatFiles) {
        for ($i = 0; $i -lt $file.ClusterCount; $i++) {
            $cluster = $file.FirstCluster + $i
            $next = if ($i -eq ($file.ClusterCount - 1)) { 0xFFF } else { $cluster + 1 }
            Set-Fat12Entry -Fat $fat -Cluster $cluster -Value $next
        }
    }

    [Array]::Copy($fat, 0, $image, $firstFatSector * $fatSectorBytes, $fat.Length)
    [Array]::Copy($fat, 0, $image, ($firstFatSector + $sectorsPerFat) * $fatSectorBytes, $fat.Length)

    $rootDirectory = New-Object byte[] ($rootDirSectors * $fatSectorBytes)
    Copy-FatDirectoryEntry -Directory $rootDirectory -Index 0 -Entry (New-FatDirectoryEntry -Name 'EFI' -Attributes 0x10 -FirstCluster 2 -Size 0)
    $rootIndex = 1
    foreach ($file in $fatFiles | Where-Object { $_.RootEntry }) {
        Copy-FatDirectoryEntry -Directory $rootDirectory -Index $rootIndex -Entry (New-FatDirectoryEntry -Name $file.FatName -Attributes 0x20 -FirstCluster $file.FirstCluster -Size ([uint32]$file.Bytes.Length))
        $rootIndex++
    }
    [Array]::Copy($rootDirectory, 0, $image, $firstRootSector * $fatSectorBytes, $rootDirectory.Length)

    $efiDirectory = New-Object byte[] $fatSectorBytes
    Copy-FatDirectoryEntry -Directory $efiDirectory -Index 0 -Entry (New-FatDirectoryEntry -Name '.' -Attributes 0x10 -FirstCluster 2 -Size 0)
    Copy-FatDirectoryEntry -Directory $efiDirectory -Index 1 -Entry (New-FatDirectoryEntry -Name '..' -Attributes 0x10 -FirstCluster 0 -Size 0)
    Copy-FatDirectoryEntry -Directory $efiDirectory -Index 2 -Entry (New-FatDirectoryEntry -Name 'BOOT' -Attributes 0x10 -FirstCluster 3 -Size 0)
    [Array]::Copy($efiDirectory, 0, $image, ($firstDataSector + 0) * $fatSectorBytes, $efiDirectory.Length)

    $bootDirectory = New-Object byte[] $fatSectorBytes
    Copy-FatDirectoryEntry -Directory $bootDirectory -Index 0 -Entry (New-FatDirectoryEntry -Name '.' -Attributes 0x10 -FirstCluster 3 -Size 0)
    Copy-FatDirectoryEntry -Directory $bootDirectory -Index 1 -Entry (New-FatDirectoryEntry -Name '..' -Attributes 0x10 -FirstCluster 2 -Size 0)
    $bootFile = $fatFiles[0]
    Copy-FatDirectoryEntry -Directory $bootDirectory -Index 2 -Entry (New-FatDirectoryEntry -Name 'BOOTX64 EFI' -Attributes 0x20 -FirstCluster $bootFile.FirstCluster -Size ([uint32]$efiBytes.Length))
    [Array]::Copy($bootDirectory, 0, $image, ($firstDataSector + 1) * $fatSectorBytes, $bootDirectory.Length)

    foreach ($file in $fatFiles) {
        $fileOffset = ($firstDataSector + ($file.FirstCluster - 2)) * $fatSectorBytes
        [Array]::Copy($file.Bytes, 0, $image, $fileOffset, $file.Bytes.Length)
    }

    return [pscustomobject]@{
        Bytes = $image
        TotalSectors = $totalSectors
        SectorBytes = $fatSectorBytes
        FileBytes = $efiBytes.Length
        FileFirstCluster = $bootFile.FirstCluster
        FileClusterCount = $bootFile.ClusterCount
        PayloadSummary = @($fatFiles | Where-Object { $_.RootEntry } | ForEach-Object {
            "{0}: cluster {1}, {2} bytes" -f $_.FatName.Trim(), $_.FirstCluster, $_.Bytes.Length
        })
    }
}

Assert-PathExists -Path $EfiApplicationPath -Label 'UEFI application'

$payloadFiles = @()
foreach ($path in @($PayloadPath)) {
    Assert-PathExists -Path $path -Label 'x64 ISO payload'
    $payloadFiles += [pscustomobject]@{
        FatName = ConvertTo-Fat83Name -Path $path
        Path = $path
        Bytes = [IO.File]::ReadAllBytes($path)
        RootEntry = $true
    }
}

$efiFatImage = New-EfiFatImage -EfiApplicationPath $EfiApplicationPath -PayloadFiles $payloadFiles
$files = @(
    [pscustomobject]@{ Id = 'EFIBOOT.IMG;1'; Bytes = $efiFatImage.Bytes; Path = $null; Label = 'EFI FAT boot image' },
    [pscustomobject]@{ Id = 'BOOTX64.EFI;1'; Bytes = $null; Path = $EfiApplicationPath; Label = 'UEFI application' }
)
foreach ($payload in $payloadFiles) {
    $files += [pscustomobject]@{
        Id = ("{0};1" -f (Split-Path -Leaf $payload.Path).ToUpperInvariant())
        Bytes = $payload.Bytes
        Path = $null
        Label = 'x64 payload'
    }
}

$bootCatalogLba = 19
$pathTableLba = 20
$pathTableMLba = 21
$rootDirLba = 22
$nextLba = 23

foreach ($file in $files) {
    $length = if ($null -ne $file.Bytes) { $file.Bytes.Length } else { (Get-Item -LiteralPath $file.Path).Length }
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
    Write-Sector -Stream $stream -Lba $bootCatalogLba -Bytes (New-BootCatalog -BootImageLba $files[0].Lba -BootImageVirtualSectors $efiFatImage.TotalSectors)
    Write-Sector -Stream $stream -Lba $pathTableLba -Bytes (New-PathTable -RootDirLba $rootDirLba)
    Write-Sector -Stream $stream -Lba $pathTableMLba -Bytes (New-PathTable -RootDirLba $rootDirLba -BigEndian)
    Write-Sector -Stream $stream -Lba $rootDirLba -Bytes $rootSector
    foreach ($file in $files) {
        if ($null -ne $file.Bytes) {
            Write-BytesExtent -Stream $stream -Lba $file.Lba -Bytes $file.Bytes
        } else {
            Write-FileExtent -Stream $stream -Lba $file.Lba -Path $file.Path
        }
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
    BootImageBytes = $efiFatImage.Bytes.Length
    BootImageVirtualSectors = $efiFatImage.TotalSectors
    EfiApplicationBytes = $efiFatImage.FileBytes
    FatPayloadSummary = $efiFatImage.PayloadSummary
    FileSummary = ($files | ForEach-Object { "{0}: LBA {1}, {2} bytes" -f $_.Id, $_.Lba, $_.Length })
}
