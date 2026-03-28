param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$srcDir = Join-Path $root 'src'
$buildDir = Join-Path $root 'build'

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

$mlCandidates = @(
    'C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.40.33807\bin\Hostx64\x86\ml.exe',
    'C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.40.33807\bin\Hostx86\x86\ml.exe',
    'C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\bin\Hostx64\x86\ml.exe',
    'C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\bin\Hostx86\x86\ml.exe'
)

$ml = $mlCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $ml) {
    throw 'Could not find ml.exe. Install MASM via Visual Studio Build Tools or update scripts/build.ps1.'
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

function Read-CoffName {
    param(
        [byte[]]$Bytes,
        [int]$Offset,
        [int]$StringTableOffset
    )

    $firstDword = Read-UInt32Le $Bytes $Offset
    $secondDword = Read-UInt32Le $Bytes ($Offset + 4)

    if ($firstDword -eq 0 -and $secondDword -ne 0) {
        $nameBytes = New-Object System.Collections.Generic.List[byte]
        $cursor = $StringTableOffset + $secondDword
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

function Get-CoffFlatBinary {
    param(
        [string]$ObjectPath,
        [string]$SectionPrefix = '.text'
    )

    $bytes = [IO.File]::ReadAllBytes($ObjectPath)
    $sectionCount = Read-UInt16Le $bytes 2
    $symbolTableOffset = [int](Read-UInt32Le $bytes 8)
    $symbolCount = [int](Read-UInt32Le $bytes 12)
    $optionalHeaderSize = Read-UInt16Le $bytes 16
    $sectionTableOffset = 20 + $optionalHeaderSize
    $stringTableOffset = $symbolTableOffset + ($symbolCount * 18)

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

    $targetSection = $sections | Where-Object { $_.Name.StartsWith($SectionPrefix) } | Select-Object -First 1
    if (-not $targetSection) {
        throw "Could not find a section starting with '$SectionPrefix' in $ObjectPath."
    }

    $symbolsByIndex = @{}
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
        $symbolIndex += 1 + $symbol.AuxCount
    }

    $flat = New-Object byte[] $targetSection.SizeOfRawData
    [Array]::Copy($bytes, $targetSection.PointerToRawData, $flat, 0, $targetSection.SizeOfRawData)

    for ($i = 0; $i -lt $targetSection.NumberOfRelocations; $i++) {
        $offset = $targetSection.PointerToRelocations + ($i * 10)
        $virtualAddress = [int](Read-UInt32Le $bytes $offset)
        $symbolIndex = [int](Read-UInt32Le $bytes ($offset + 4))
        $relocationType = Read-UInt16Le $bytes ($offset + 8)

        if (-not $symbolsByIndex.ContainsKey($symbolIndex)) {
            throw "Relocation referenced missing symbol index $symbolIndex in $ObjectPath."
        }

        $symbol = $symbolsByIndex[$symbolIndex]
        switch ($relocationType) {
            0x0001 {
                $current = Read-UInt16Le $flat $virtualAddress
                Write-UInt16Le $flat $virtualAddress ($current + $symbol.Value)
            }
            default {
                throw ("Unsupported relocation type 0x{0:X4} for symbol '{1}' in {2}" -f $relocationType, $symbol.Name, $ObjectPath)
            }
        }
    }

    return $flat
}

function Invoke-Masm {
    param(
        [string]$SourcePath,
        [string]$ObjectPath,
        [string[]]$IncludePaths = @()
    )

    $args = @('/nologo', '/c', '/coff', '/Fo', $ObjectPath)
    foreach ($includePath in $IncludePaths) {
        $args += "/I$includePath"
    }
    $args += $SourcePath

    & $ml @args
    if ($LASTEXITCODE -ne 0) {
        throw "MASM failed for $SourcePath"
    }
}

$gameAsm = Join-Path $srcDir 'game.asm'
$bootAsm = Join-Path $srcDir 'boot.asm'
$gameObj = Join-Path $buildDir 'game.obj'
$bootObj = Join-Path $buildDir 'boot.obj'

Invoke-Masm -SourcePath $gameAsm -ObjectPath $gameObj
$gameBin = Get-CoffFlatBinary -ObjectPath $gameObj
[IO.File]::WriteAllBytes((Join-Path $buildDir 'cyberstorm-stage2.bin'), $gameBin)

$gameSectorCount = [int][Math]::Ceiling($gameBin.Length / 512.0)
if ($gameSectorCount -lt 1) {
    throw 'Stage two was empty.'
}

$bootConfig = Join-Path $buildDir 'boot_config.inc'
Set-Content -Path $bootConfig -Encoding ascii -NoNewline -Value ("GAME_SECTORS EQU {0}`r`n" -f $gameSectorCount)

Invoke-Masm -SourcePath $bootAsm -ObjectPath $bootObj -IncludePaths @($buildDir)
$bootBin = Get-CoffFlatBinary -ObjectPath $bootObj
if ($bootBin.Length -gt 510) {
    throw "Bootloader is too large: $($bootBin.Length) bytes."
}

$bootSector = New-Object byte[] 512
[Array]::Copy($bootBin, 0, $bootSector, 0, $bootBin.Length)
$bootSector[510] = 0x55
$bootSector[511] = 0xAA

[IO.File]::WriteAllBytes((Join-Path $buildDir 'cyberstorm-boot.bin'), $bootSector)

$floppy = New-Object byte[] 1474560
[Array]::Copy($bootSector, 0, $floppy, 0, $bootSector.Length)
[Array]::Copy($gameBin, 0, $floppy, 512, $gameBin.Length)

$imgPath = Join-Path $buildDir 'cyberstorm.img'
$vfdPath = Join-Path $buildDir 'cyberstorm.vfd'
[IO.File]::WriteAllBytes($imgPath, $floppy)
[IO.File]::WriteAllBytes($vfdPath, $floppy)

Write-Host ("Built {0}" -f $imgPath)
Write-Host ("Built {0}" -f $vfdPath)
Write-Host ("Boot sector: {0} bytes" -f $bootBin.Length)
Write-Host ("Stage two:  {0} bytes ({1} sectors)" -f $gameBin.Length, $gameSectorCount)
