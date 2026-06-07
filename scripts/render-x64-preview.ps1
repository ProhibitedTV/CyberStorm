param(
    [Parameter(Mandatory = $true)]
    [string]$Engine64BinaryPath,
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Engine64BinaryPath)) {
    throw "ENGINE64 payload not found: $Engine64BinaryPath"
}

$bytes = [IO.File]::ReadAllBytes($Engine64BinaryPath)
if ($bytes.Length -lt 96) {
    throw "ENGINE64 payload is too small for the preview header."
}

$magic = [Text.Encoding]::ASCII.GetString($bytes, 0, 8)
if ($magic -ne 'CS64ENG0') {
    throw "ENGINE64 preview expected CS64ENG0 magic, found '$magic'."
}

function Read-U32 {
    param([int]$Offset)
    return [BitConverter]::ToUInt32($bytes, $Offset)
}

$version = Read-U32 8
$width = [int](Read-U32 12)
$height = [int](Read-U32 16)
$paletteCount = [int](Read-U32 20)
$flags = Read-U32 24
$paletteOffset = [int](Read-U32 28)
$bytesPerColor = [int](Read-U32 32)
$modelTableOffset = [int](Read-U32 56)
$modelCount = [int](Read-U32 60)
$modelRecordBytes = [int](Read-U32 64)

if ($version -ne 1) {
    throw "ENGINE64 preview supports payload version 1, found $version."
}
if ($width -ne 640 -or $height -ne 480) {
    throw "ENGINE64 preview expected 640x480, found ${width}x${height}."
}
if ($paletteCount -lt 1 -or $paletteCount -gt 16) {
    throw "ENGINE64 preview palette count must be 1..16, found $paletteCount."
}
if ($bytesPerColor -ne 4) {
    throw "ENGINE64 preview expected 4-byte xRGB colors, found $bytesPerColor."
}
if (($paletteOffset + ($paletteCount * 4)) -gt $bytes.Length) {
    throw "ENGINE64 preview palette table extends past the payload."
}
if ($modelCount -lt 0 -or $modelCount -gt 8) {
    throw "ENGINE64 preview model count must be 0..8, found $modelCount."
}

$modelNames = New-Object 'System.Collections.Generic.List[string]'
if ($modelCount -gt 0) {
    if ($modelRecordBytes -ne 32) {
        throw "ENGINE64 preview expected 32-byte model records, found $modelRecordBytes."
    }

    $modelTableEnd = [int64]$modelTableOffset + ([int64]$modelCount * [int64]$modelRecordBytes)
    if ($modelTableOffset -lt 96 -or $modelTableEnd -gt $bytes.Length) {
        throw "ENGINE64 preview model table extends past the payload."
    }

    for ($modelIndex = 0; $modelIndex -lt $modelCount; $modelIndex++) {
        $recordOffset = $modelTableOffset + ($modelIndex * $modelRecordBytes)
        $name = ([Text.Encoding]::ASCII.GetString($bytes, $recordOffset, 8)).Trim()
        if ([string]::IsNullOrWhiteSpace($name)) {
            throw "ENGINE64 preview model $modelIndex has an empty name."
        }

        $vertexOffset = [int](Read-U32 ($recordOffset + 8))
        $vertexCount = [int](Read-U32 ($recordOffset + 12))
        $faceOffset = [int](Read-U32 ($recordOffset + 16))
        $faceCount = [int](Read-U32 ($recordOffset + 20))

        if ($vertexCount -lt 1 -or $vertexCount -gt 64) {
            throw "ENGINE64 preview model $name vertex count must be 1..64, found $vertexCount."
        }
        if ($faceCount -lt 1 -or $faceCount -gt 128) {
            throw "ENGINE64 preview model $name face count must be 1..128, found $faceCount."
        }

        $vertexEnd = [int64]$vertexOffset + ([int64]$vertexCount * 6)
        $faceEnd = [int64]$faceOffset + ([int64]$faceCount * 4)
        if ($vertexOffset -lt 96 -or $vertexEnd -gt $bytes.Length) {
            throw "ENGINE64 preview model $name vertex table extends past the payload."
        }
        if ($faceOffset -lt 96 -or $faceEnd -gt $bytes.Length) {
            throw "ENGINE64 preview model $name face table extends past the payload."
        }

        for ($faceIndex = 0; $faceIndex -lt $faceCount; $faceIndex++) {
            $faceBase = $faceOffset + ($faceIndex * 4)
            $a = [int]$bytes[$faceBase]
            $b = [int]$bytes[$faceBase + 1]
            $c = [int]$bytes[$faceBase + 2]
            $material = [int]$bytes[$faceBase + 3]

            if ($a -ge $vertexCount -or $b -ge $vertexCount -or $c -ge $vertexCount) {
                throw "ENGINE64 preview model $name face $faceIndex references a missing vertex."
            }
            if ($a -eq $b -or $b -eq $c -or $a -eq $c) {
                throw "ENGINE64 preview model $name face $faceIndex is degenerate."
            }
            if ($material -ge $paletteCount) {
                throw "ENGINE64 preview model $name face $faceIndex references palette index $material, but only $paletteCount entries exist."
            }
        }

        $modelNames.Add($name)
    }
}

Add-Type -AssemblyName System.Drawing

$outputDirectory = Split-Path -Parent $OutputPath
if ($outputDirectory) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}

$colors = New-Object 'System.UInt32[]' $paletteCount
for ($i = 0; $i -lt $paletteCount; $i++) {
    $colors[$i] = Read-U32 ($paletteOffset + ($i * 4))
}

function New-XrgbColor {
    param([uint32]$Value, [byte]$Alpha = 255)
    return [System.Drawing.Color]::FromArgb($Alpha, [byte](($Value -shr 16) -band 0xFF), [byte](($Value -shr 8) -band 0xFF), [byte]($Value -band 0xFF))
}

$bitmap = New-Object System.Drawing.Bitmap $width, $height, ([System.Drawing.Imaging.PixelFormat]::Format32bppRgb)
$rect = New-Object System.Drawing.Rectangle 0, 0, $width, $height
$lock = $bitmap.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppRgb)

try {
    $stride = [Math]::Abs($lock.Stride)
    $buffer = New-Object byte[] ($stride * $height)
    for ($y = 0; $y -lt $height; $y++) {
        $row = $y * $stride
        $color = if ($y -lt 122) {
            $colors[0]
        }
        elseif ($y -lt 246) {
            $colors[[Math]::Min(1, $colors.Length - 1)]
        }
        elseif ($y -lt 330) {
            [uint32]0x000B1924
        }
        else {
            [uint32]0x00101016
        }
        for ($x = 0; $x -lt $width; $x++) {
            $offset = $row + ($x * 4)
            $buffer[$offset] = [byte]($color -band 0xFF)
            $buffer[$offset + 1] = [byte](($color -shr 8) -band 0xFF)
            $buffer[$offset + 2] = [byte](($color -shr 16) -band 0xFF)
            $buffer[$offset + 3] = 0
        }
    }
    [Runtime.InteropServices.Marshal]::Copy($buffer, 0, $lock.Scan0, $buffer.Length)
}
finally {
    $bitmap.UnlockBits($lock)
}

$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
try {
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

    $panelBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 7, 11, 18))
    $menuBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(246, 7, 11, 18))
    $roadBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 8, 8, 14))
    $fogBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(110, 24, 72, 94))
    $accentBrush = New-Object System.Drawing.SolidBrush (New-XrgbColor 0x00D8FFFF)
    $amberBrush = New-Object System.Drawing.SolidBrush (New-XrgbColor 0x00FFE66D)
    $redBrush = New-Object System.Drawing.SolidBrush (New-XrgbColor 0x00FF4058)
    $textBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 232, 248, 255))
    $mutedBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 136, 184, 216))
    $darkBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 7, 11, 18))
    $skylineBrushA = New-Object System.Drawing.SolidBrush (New-XrgbColor 0x00030A10)
    $skylineBrushB = New-Object System.Drawing.SolidBrush (New-XrgbColor 0x00081018)
    $shipBrush = New-Object System.Drawing.SolidBrush (New-XrgbColor 0x00101820)
    $shipDarkBrush = New-Object System.Drawing.SolidBrush (New-XrgbColor 0x00030A10)
    $greenBrush = New-Object System.Drawing.SolidBrush (New-XrgbColor 0x0020D060)
    $blueBrush = New-Object System.Drawing.SolidBrush (New-XrgbColor 0x003080D0)
    $magentaBrush = New-Object System.Drawing.SolidBrush (New-XrgbColor 0x00FF90FF)
    $purpleBrush = New-Object System.Drawing.SolidBrush (New-XrgbColor 0x00A020B0)

    $cyanPen = New-Object System.Drawing.Pen (New-XrgbColor 0x00D8FFFF), 2
    $bluePen = New-Object System.Drawing.Pen (New-XrgbColor 0x003080D0), 2
    $magentaPen = New-Object System.Drawing.Pen (New-XrgbColor 0x00FF90FF), 2
    $amberPen = New-Object System.Drawing.Pen (New-XrgbColor 0x00FFE66D), 2

    $titleFont = New-Object System.Drawing.Font 'Segoe UI', 44, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
    $uiFont = New-Object System.Drawing.Font 'Segoe UI', 15, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
    $smallFont = New-Object System.Drawing.Font 'Segoe UI', 12, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)

    $graphics.FillRectangle($fogBrush, 0, 264, 640, 24)
    $graphics.FillRectangle($roadBrush, 0, 288, 640, 192)
    $graphics.DrawLine($cyanPen, 0, 286, 640, 286)
    $graphics.DrawLine($bluePen, 0, 304, 640, 304)
    $graphics.DrawLine($magentaPen, 0, 326, 640, 326)
    $graphics.DrawLine($amberPen, 0, 356, 640, 356)
    $graphics.DrawLine($magentaPen, 0, 392, 640, 392)
    $graphics.DrawLine($cyanPen, 0, 436, 640, 436)
    foreach ($x in 20, 132, 260, 380, 508, 628) {
        $pen = if ($x -eq 20 -or $x -eq 628) { $bluePen } elseif ($x -eq 260 -or $x -eq 380) { $cyanPen } else { $magentaPen }
        $graphics.DrawLine($pen, 320, 286, $x, 480)
    }
    $graphics.DrawLine($bluePen, 320, 286, 320, 480)

    $graphics.FillRectangle($skylineBrushA, 42, 140, 62, 148)
    $graphics.FillRectangle($skylineBrushB, 114, 104, 68, 184)
    $graphics.FillRectangle($skylineBrushB, 196, 168, 44, 120)
    $graphics.FillRectangle($skylineBrushA, 272, 154, 96, 86)
    $graphics.FillRectangle($skylineBrushA, 454, 122, 72, 166)
    $graphics.FillRectangle($skylineBrushB, 540, 158, 56, 130)
    $graphics.FillRectangle($accentBrush, 62, 198, 10, 42)
    $graphics.FillRectangle($amberBrush, 84, 176, 8, 28)
    $graphics.FillRectangle($greenBrush, 132, 188, 9, 54)
    $graphics.FillRectangle($redBrush, 160, 126, 12, 32)
    $graphics.FillRectangle($accentBrush, 292, 176, 54, 10)
    $graphics.FillRectangle($amberBrush, 462, 156, 44, 8)
    $graphics.FillRectangle($magentaBrush, 486, 190, 9, 54)
    $graphics.FillRectangle($redBrush, 552, 198, 12, 48)
    $graphics.FillRectangle($skylineBrushB, 224, 330, 3, 150)
    $graphics.FillRectangle($skylineBrushB, 442, 330, 3, 150)

    $graphics.FillRectangle($shipDarkBrush, 272, 222, 64, 18)
    $graphics.FillRectangle($shipBrush, 310, 206, 112, 32)
    $graphics.FillRectangle($shipDarkBrush, 408, 218, 42, 14)
    $graphics.FillRectangle($magentaBrush, 248, 238, 204, 4)
    $graphics.FillRectangle($accentBrush, 334, 216, 42, 8)
    $graphics.FillRectangle($amberBrush, 378, 226, 18, 6)
    $graphics.FillRectangle($redBrush, 292, 244, 26, 3)
    $graphics.FillRectangle($redBrush, 404, 244, 26, 3)
    $graphics.DrawLine($cyanPen, 96, 288, 544, 288)
    $graphics.FillRectangle($amberBrush, 286, 258, 78, 6)

    $graphics.FillRectangle($panelBrush, 28, 24, 374, 112)
    $graphics.FillRectangle($accentBrush, 42, 88, 286, 5)
    $graphics.FillRectangle($amberBrush, 42, 96, 192, 2)
    $graphics.DrawString('CYBERSTORM', $titleFont, $purpleBrush, 44, 38)
    $graphics.DrawString('CYBERSTORM', $titleFont, $textBrush, 42, 34)
    $graphics.DrawString('NEON DISTRICT', $uiFont, $mutedBrush, 44, 106)

    $graphics.FillRectangle($menuBrush, 404, 22, 212, 136)
    $graphics.FillRectangle($accentBrush, 408, 28, 4, 124)
    $graphics.FillRectangle($magentaBrush, 416, 150, 184, 2)
    $graphics.DrawString('SELECT', $smallFont, $mutedBrush, 424, 32)
    $graphics.DrawString('ON', $smallFont, $amberBrush, 560, 32)
    $graphics.FillRectangle($accentBrush, 420, 54, 152, 24)
    $graphics.FillRectangle($magentaBrush, 414, 60, 4, 12)
    $graphics.DrawString('NEW GAME', $uiFont, $darkBrush, 428, 58)
    $graphics.DrawString('OPTIONS', $uiFont, $textBrush, 428, 90)
    $graphics.DrawString('CREDITS', $uiFont, $textBrush, 428, 122)

    $graphics.FillRectangle($panelBrush, 28, 402, 412, 52)
    $graphics.FillRectangle($magentaBrush, 28, 404, 412, 2)
    $graphics.DrawString('W S SELECT  ENTER GO', $smallFont, $textBrush, 42, 414)
    $graphics.DrawString('ESC BACK  OPTIONS  CREDITS', $smallFont, $mutedBrush, 42, 436)
}
finally {
    $graphics.Dispose()
}

$bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bitmap.Dispose()

$item = Get-Item -LiteralPath $OutputPath
[pscustomobject]@{
    Path = $item.FullName
    Bytes = $item.Length
    Width = $width
    Height = $height
    PaletteEntries = $paletteCount
    ModelEntries = $modelCount
    ModelNames = ($modelNames -join ',')
    Flags = ('0x{0:X8}' -f $flags)
}
