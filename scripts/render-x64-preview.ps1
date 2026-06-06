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
$barCount = [int](Read-U32 20)
$flags = Read-U32 24
$barOffset = [int](Read-U32 28)
$bytesPerColor = [int](Read-U32 32)

if ($version -ne 1) {
    throw "ENGINE64 preview supports payload version 1, found $version."
}
if ($width -ne 640 -or $height -ne 480) {
    throw "ENGINE64 preview expected 640x480, found ${width}x${height}."
}
if ($barCount -lt 1 -or $barCount -gt 16) {
    throw "ENGINE64 preview bar count must be 1..16, found $barCount."
}
if ($bytesPerColor -ne 4) {
    throw "ENGINE64 preview expected 4-byte xRGB colors, found $bytesPerColor."
}
if (($barOffset + ($barCount * 4)) -gt $bytes.Length) {
    throw "ENGINE64 preview color table extends past the payload."
}

Add-Type -AssemblyName System.Drawing

$outputDirectory = Split-Path -Parent $OutputPath
if ($outputDirectory) {
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}

$colors = New-Object 'System.UInt32[]' $barCount
for ($i = 0; $i -lt $barCount; $i++) {
    $colors[$i] = Read-U32 ($barOffset + ($i * 4))
}

$bitmap = New-Object System.Drawing.Bitmap $width, $height, ([System.Drawing.Imaging.PixelFormat]::Format32bppRgb)
$rect = New-Object System.Drawing.Rectangle 0, 0, $width, $height
$lock = $bitmap.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppRgb)

try {
    $stride = [Math]::Abs($lock.Stride)
    $buffer = New-Object byte[] ($stride * $height)
    for ($y = 0; $y -lt $height; $y++) {
        $row = $y * $stride
        for ($x = 0; $x -lt $width; $x++) {
            $bar = [Math]::Min([int](($x * $barCount) / $width), $barCount - 1)
            $color = $colors[$bar]
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

    $panelBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(210, 10, 18, 28))
    $menuBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(220, 18, 38, 50))
    $accentBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 216, 255, 255))
    $textBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 232, 248, 255))
    $mutedBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 136, 184, 216))
    $darkBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 16, 24, 32))

    $titleFont = New-Object System.Drawing.Font 'Segoe UI', 34, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
    $uiFont = New-Object System.Drawing.Font 'Segoe UI', 15, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
    $smallFont = New-Object System.Drawing.Font 'Segoe UI', 12, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)

    $graphics.FillRectangle($panelBrush, 28, 24, 584, 94)
    $graphics.FillRectangle($accentBrush, 42, 84, 348, 5)
    $graphics.DrawString('CYBERSTORM X64', $titleFont, $textBrush, 42, 36)
    $graphics.DrawString('NEON DISTRICT START SCREEN', $uiFont, $mutedBrush, 44, 92)

    $graphics.FillRectangle($menuBrush, 402, 22, 210, 76)
    $graphics.FillRectangle($accentBrush, 416, 56, 92, 24)
    $graphics.DrawString('NEW GAME', $uiFont, $darkBrush, 423, 58)
    $graphics.DrawString('OPTIONS', $uiFont, $textBrush, 514, 58)
    $graphics.DrawString('CREDITS', $uiFont, $textBrush, 514, 78)

    $graphics.FillRectangle($panelBrush, 28, 390, 584, 66)
    $graphics.DrawString('PURE ASSEMBLY / UEFI X64 / SOFTWARE RENDERER', $smallFont, $textBrush, 42, 404)
    $graphics.DrawString('NEW GAME / OPTIONS / CREDITS READY FOR THE PLAYABLE SLICE', $smallFont, $mutedBrush, 42, 428)
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
    Bars = $barCount
    Flags = ('0x{0:X8}' -f $flags)
}
