param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$ScreenshotPath = '',
    [string]$ReportPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ScreenshotPath)) {
    $ScreenshotPath = Join-Path $RepoRoot 'build\cyberstorm-x64-vm-smoke-title.png'
}
if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = Join-Path $RepoRoot 'build\cyberstorm-x64-trace-smoke-report.txt'
}

function Get-SuffixPath {
    param([string]$BasePath, [string]$Suffix)
    $directory = Split-Path -Parent $BasePath
    $stem = [IO.Path]::GetFileNameWithoutExtension($BasePath)
    $name = '{0}-{1}.png' -f $stem, $Suffix
    if ([string]::IsNullOrWhiteSpace($directory)) { return $name }
    return (Join-Path $directory $name)
}

$tracePath = Get-SuffixPath -BasePath $ScreenshotPath -Suffix 'mission-progress'
$traceClearPath = Get-SuffixPath -BasePath $ScreenshotPath -Suffix 'trace-clear'
$completePath = Get-SuffixPath -BasePath $ScreenshotPath -Suffix 'mission-complete'

foreach ($entry in @(
    @{ Path = $tracePath; Label = 'TRACE response' },
    @{ Path = $traceClearPath; Label = 'TRACE clear' },
    @{ Path = $completePath; Label = 'mission complete' }
)) {
    if (-not (Test-Path -LiteralPath $entry.Path)) {
        throw ("Missing {0} screenshot: {1}" -f $entry.Label, $entry.Path)
    }
}

Add-Type -AssemblyName System.Drawing

function Get-Viewport {
    param([System.Drawing.Bitmap]$Bitmap)
    $width = [Math]::Min($Bitmap.Width, 640)
    $height = [Math]::Min($Bitmap.Height, 480)
    return [pscustomobject]@{
        X = [Math]::Max(0, [int](($Bitmap.Width - $width) / 2))
        Y = [Math]::Max(0, [int](($Bitmap.Height - $height) / 2))
        Width = $width
        Height = $height
    }
}

function Compare-InternalRegion {
    param(
        [System.Drawing.Bitmap]$A,
        [System.Drawing.Bitmap]$B,
        [int]$X0,
        [int]$Y0,
        [int]$X1,
        [int]$Y1,
        [int]$Step = 4
    )

    if ($A.Width -ne $B.Width -or $A.Height -ne $B.Height) {
        throw "Screenshot dimensions differ: $($A.Width)x$($A.Height) vs $($B.Width)x$($B.Height)"
    }

    $va = Get-Viewport -Bitmap $A
    $vb = Get-Viewport -Bitmap $B
    if ($va.Width -ne $vb.Width -or $va.Height -ne $vb.Height) {
        throw 'Viewport dimensions differ between screenshots.'
    }

    $sampled = 0
    $different = 0
    $deltaTotal = 0L
    $maxX = [Math]::Min($X1, $va.Width)
    $maxY = [Math]::Min($Y1, $va.Height)

    for ($y = [Math]::Max(0, $Y0); $y -lt $maxY; $y += $Step) {
        for ($x = [Math]::Max(0, $X0); $x -lt $maxX; $x += $Step) {
            $pa = $A.GetPixel($va.X + $x, $va.Y + $y)
            $pb = $B.GetPixel($vb.X + $x, $vb.Y + $y)
            $delta = [Math]::Abs([int]$pa.R - [int]$pb.R) +
                     [Math]::Abs([int]$pa.G - [int]$pb.G) +
                     [Math]::Abs([int]$pa.B - [int]$pb.B)
            $sampled++
            $deltaTotal += $delta
            if ($delta -ge 18) { $different++ }
        }
    }

    return [pscustomobject]@{
        Sampled = $sampled
        Different = $different
        DifferentPercent = if ($sampled -gt 0) { [Math]::Round(($different * 100.0) / $sampled, 2) } else { 0.0 }
        DeltaTotal = $deltaTotal
    }
}

$traceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $tracePath).Hash
$traceClearHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $traceClearPath).Hash
$completeHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $completePath).Hash

$trace = [System.Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $tracePath).Path)
$traceClear = [System.Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $traceClearPath).Path)
$complete = [System.Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $completePath).Path)

try {
    $exitTransition = Compare-InternalRegion -A $trace -B $traceClear -X0 468 -Y0 268 -X1 584 -Y1 392 -Step 3
    $completionTransition = Compare-InternalRegion -A $traceClear -B $complete -X0 150 -Y0 54 -X1 520 -Y1 172 -Step 3
    $wholeTraceToClear = Compare-InternalRegion -A $trace -B $traceClear -X0 0 -Y0 0 -X1 640 -Y1 480 -Step 8
    $wholeClearToComplete = Compare-InternalRegion -A $traceClear -B $complete -X0 0 -Y0 0 -X1 640 -Y1 480 -Step 8

    $checks = @(
        [pscustomobject]@{ Name = 'TRACE and clear captures have distinct hashes'; Passed = ($traceHash -ne $traceClearHash); Detail = "$traceHash -> $traceClearHash" },
        [pscustomobject]@{ Name = 'Clear and complete captures have distinct hashes'; Passed = ($traceClearHash -ne $completeHash); Detail = "$traceClearHash -> $completeHash" },
        [pscustomobject]@{ Name = 'Exit presentation changes when TRACE breaks'; Passed = ($exitTransition.Different -ge 24 -and $exitTransition.DifferentPercent -ge 1.5); Detail = "different=$($exitTransition.Different)/$($exitTransition.Sampled) ($($exitTransition.DifferentPercent)%)" },
        [pscustomobject]@{ Name = 'Objective HUD changes on mission completion'; Passed = ($completionTransition.Different -ge 20 -and $completionTransition.DifferentPercent -ge 0.8); Detail = "different=$($completionTransition.Different)/$($completionTransition.Sampled) ($($completionTransition.DifferentPercent)%)" },
        [pscustomobject]@{ Name = 'TRACE-to-clear frame is not stale'; Passed = ($wholeTraceToClear.Different -ge 16); Detail = "different=$($wholeTraceToClear.Different)/$($wholeTraceToClear.Sampled)" },
        [pscustomobject]@{ Name = 'Clear-to-complete frame is not stale'; Passed = ($wholeClearToComplete.Different -ge 12); Detail = "different=$($wholeClearToComplete.Different)/$($wholeClearToComplete.Sampled)" }
    )

    $failed = @($checks | Where-Object { -not $_.Passed })
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('CyberStorm x64 TRACE Visual Smoke Verification')
    $lines.Add(('Generated: {0:u}' -f (Get-Date).ToUniversalTime()))
    $lines.Add(('TRACE response: {0}' -f (Resolve-Path -LiteralPath $tracePath).Path))
    $lines.Add(('TRACE clear: {0}' -f (Resolve-Path -LiteralPath $traceClearPath).Path))
    $lines.Add(('Mission complete: {0}' -f (Resolve-Path -LiteralPath $completePath).Path))
    $lines.Add('')
    foreach ($check in $checks) {
        $status = if ($check.Passed) { 'PASS' } else { 'FAIL' }
        $lines.Add(('[{0}] {1} - {2}' -f $status, $check.Name, $check.Detail))
    }
    $lines.Add('')
    $lines.Add(('Summary: {0} passed, {1} failed' -f ($checks.Count - $failed.Count), $failed.Count))

    $reportDir = Split-Path -Parent $ReportPath
    if ($reportDir -and -not (Test-Path -LiteralPath $reportDir)) {
        New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
    }
    $lines | Set-Content -Encoding UTF8 -LiteralPath $ReportPath
    $lines | ForEach-Object { Write-Host $_ }

    if ($failed.Count -gt 0) { exit 1 }
} finally {
    $trace.Dispose()
    $traceClear.Dispose()
    $complete.Dispose()
}
