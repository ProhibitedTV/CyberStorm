param(
    [ValidateSet('masm', 'uasm', 'jwasm')]
    [string]$Assembler = 'masm',
    [string]$AssemblerPath,
    [string]$MasmPath,
    [switch]$ExperimentalMusic,
    [switch]$SfxOnly,
    [string]$VmName = 'CyberStorm',
    [int]$WaitSeconds = 14,
    [string]$AudioConfigPath,
    [string]$ConstantsSourcePath = (Join-Path (Join-Path $PSScriptRoot '..') 'src\game\constants.inc'),
    [string]$BuildScriptPath = (Join-Path $PSScriptRoot 'build.ps1'),
    [string]$DeployScriptPath = (Join-Path $PSScriptRoot 'deploy-vm.ps1'),
    [string]$ReportPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm-vm-smoke-report.txt')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($ExperimentalMusic.IsPresent -and $SfxOnly.IsPresent) {
    throw 'Use either -ExperimentalMusic (legacy alias) or -SfxOnly, not both.'
}

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $root 'build'
$artifactDir = Join-Path $buildDir 'vm-smoke'
$vbox = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
$diskImage = Join-Path $buildDir 'cyberstorm.img'
$startupScreenshotPath = Join-Path $artifactDir 'cyberstorm-vm-smoke-startup.png'
$titleScreenshotPath = Join-Path $artifactDir 'cyberstorm-vm-smoke-title.png'
$screenshotPath = Join-Path $artifactDir 'cyberstorm-vm-smoke.png'
$logCopyPath = Join-Path $artifactDir 'cyberstorm-vm-smoke.log'
$vboxLogPath = Join-Path $root ("deploy\virtualbox\{0}\Logs\VBox.log" -f $VmName)

. (Join-Path $PSScriptRoot 'vbox-common.ps1')

function Assert-PathExists {
    param(
        [string]$Path,
        [string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw ("Missing {0}: {1}" -f $Label, $Path)
    }
}

function Invoke-ChildBuild {
    param([string[]]$ExtraArguments)

    $args = New-Object 'System.Collections.Generic.List[string]'
    $args.Add('-ExecutionPolicy')
    $args.Add('Bypass')
    $args.Add('-File')
    $args.Add($BuildScriptPath)
    $args.Add('-AutomationChild')
    $args.Add('-Assembler')
    $args.Add($Assembler)
    if (-not [string]::IsNullOrWhiteSpace($AssemblerPath)) {
        $args.Add('-AssemblerPath')
        $args.Add($AssemblerPath)
    }

    if (-not [string]::IsNullOrWhiteSpace($MasmPath)) {
        $args.Add('-MasmPath')
        $args.Add($MasmPath)
    }

    if ($SfxOnly.IsPresent) {
        $args.Add('-SfxOnly')
    }

    foreach ($argument in @($ExtraArguments)) {
        $args.Add($argument)
    }

    & powershell @args | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw ("Child build failed: powershell {0}" -f ($args -join ' '))
    }
}

function Write-SmokeReport {
    param(
        [string]$Path,
        [string[]]$Lines
    )

    Set-Content -LiteralPath $Path -Encoding ascii -Value $Lines
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

function Convert-VgaChannel {
    param([int]$Value)
    return [int][Math]::Round(($Value * 255.0) / 63.0)
}

function New-RgbRef {
    param([int]$R, [int]$G, [int]$B)

    return [pscustomobject]@{
        R = (Convert-VgaChannel $R)
        G = (Convert-VgaChannel $G)
        B = (Convert-VgaChannel $B)
    }
}

function Get-ColorDistance {
    param(
        $Color,
        $Reference
    )

    $dr = [double]($Color.R - $Reference.R)
    $dg = [double]($Color.G - $Reference.G)
    $db = [double]($Color.B - $Reference.B)
    return (($dr * $dr) + ($dg * $dg) + ($db * $db))
}

function Get-BitmapPixel {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [int]$X,
        [int]$Y
    )

    return $Bitmap.GetPixel($X, $Y)
}

function Get-LogicalBitmapPixel {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [double]$LogicalX,
        [double]$LogicalY,
        [int]$ScreenW,
        [int]$ScreenH
    )

    $scaledX = [int][Math]::Floor(((($LogicalX + 0.5) * $Bitmap.Width) / $ScreenW))
    $scaledY = [int][Math]::Floor(((($LogicalY + 0.5) * $Bitmap.Height) / $ScreenH))
    $scaledX = [Math]::Max(0, [Math]::Min($Bitmap.Width - 1, $scaledX))
    $scaledY = [Math]::Max(0, [Math]::Min($Bitmap.Height - 1, $scaledY))
    return (Get-BitmapPixel -Bitmap $Bitmap -X $scaledX -Y $scaledY)
}

function Get-SmokeSentinelStatus {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [hashtable]$Geometry
    )

    $sentinelRef = New-RgbRef $Geometry.R $Geometry.G $Geometry.B
    $matchThreshold = 12000
    $matchingPixels = 0
    $closestDistance = [double]::PositiveInfinity

    for ($logicalY = $Geometry.Y; $logicalY -lt ($Geometry.Y + $Geometry.H); $logicalY++) {
        for ($logicalX = $Geometry.X; $logicalX -lt ($Geometry.X + $Geometry.W); $logicalX++) {
            $sample = Get-LogicalBitmapPixel `
                -Bitmap $Bitmap `
                -LogicalX $logicalX `
                -LogicalY $logicalY `
                -ScreenW $Geometry.ScreenW `
                -ScreenH $Geometry.ScreenH
            $distance = Get-ColorDistance -Color $sample -Reference $sentinelRef
            if ($distance -lt $closestDistance) {
                $closestDistance = $distance
            }

            if ($distance -le $matchThreshold) {
                $matchingPixels++
            }
        }
    }

    $minimumMatches = [Math]::Max(4, [int][Math]::Floor(($Geometry.W * $Geometry.H) / 6))
    return [pscustomobject]@{
        Visible = ($matchingPixels -ge $minimumMatches)
        MatchingPixels = $matchingPixels
        ClosestDistance = [int][Math]::Round($closestDistance)
        MinimumMatches = $minimumMatches
    }
}

function Get-GameplayPresentStrategyStatus {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [hashtable]$Geometry
    )

    $pageFlipRef = New-RgbRef $Geometry.PageFlipR $Geometry.PageFlipG $Geometry.PageFlipB
    $degradedRef = New-RgbRef $Geometry.DegradedR $Geometry.DegradedG $Geometry.DegradedB
    $matchThreshold = 14000
    $pageFlipMatches = 0
    $degradedMatches = 0
    $closestPageFlipDistance = [double]::PositiveInfinity
    $closestDegradedDistance = [double]::PositiveInfinity

    for ($logicalY = $Geometry.Y; $logicalY -lt ($Geometry.Y + $Geometry.H); $logicalY++) {
        for ($logicalX = $Geometry.X; $logicalX -lt ($Geometry.X + $Geometry.W); $logicalX++) {
            $sample = Get-LogicalBitmapPixel `
                -Bitmap $Bitmap `
                -LogicalX $logicalX `
                -LogicalY $logicalY `
                -ScreenW $Geometry.ScreenW `
                -ScreenH $Geometry.ScreenH
            $pageFlipDistance = Get-ColorDistance -Color $sample -Reference $pageFlipRef
            $degradedDistance = Get-ColorDistance -Color $sample -Reference $degradedRef
            if ($pageFlipDistance -lt $closestPageFlipDistance) {
                $closestPageFlipDistance = $pageFlipDistance
            }

            if ($degradedDistance -lt $closestDegradedDistance) {
                $closestDegradedDistance = $degradedDistance
            }

            if ($pageFlipDistance -le $matchThreshold) {
                $pageFlipMatches++
            }

            if ($degradedDistance -le $matchThreshold) {
                $degradedMatches++
            }
        }
    }

    $minimumMatches = [Math]::Max(4, [int][Math]::Floor(($Geometry.W * $Geometry.H) / 6))
    $visible = ($pageFlipMatches -ge $minimumMatches) -or ($degradedMatches -ge $minimumMatches)
    $mode = 'unknown'
    if ($visible) {
        if ($pageFlipMatches -gt $degradedMatches) {
            $mode = 'page-flip'
        } elseif ($degradedMatches -gt $pageFlipMatches) {
            $mode = 'degraded-blit'
        } elseif ($closestPageFlipDistance -le $closestDegradedDistance) {
            $mode = 'page-flip'
        } else {
            $mode = 'degraded-blit'
        }
    }

    return [pscustomobject]@{
        Visible = $visible
        Mode = $mode
        PageFlipMatches = $pageFlipMatches
        DegradedMatches = $degradedMatches
        ClosestPageFlipDistance = [int][Math]::Round($closestPageFlipDistance)
        ClosestDegradedDistance = [int][Math]::Round($closestDegradedDistance)
        MinimumMatches = $minimumMatches
    }
}

function Capture-SmokeWindow {
    param(
        [string]$Label,
        [string]$OutputPath,
        [hashtable]$Geometry
    )

    $lastSample = $null
    $maxCaptureAttempts = 3
    for ($attempt = 1; $attempt -le $maxCaptureAttempts; $attempt++) {
        Invoke-VmScreenshot -Name $VmName -OutputPath $OutputPath -Context ("vm smoke screenshot ({0})" -f $Label.ToLowerInvariant())
        if (-not (Test-Path -LiteralPath $OutputPath)) {
            throw ("{0} screenshot was not created: {1}" -f $Label, $OutputPath)
        }

        $bitmap = [System.Drawing.Bitmap]::FromFile($OutputPath)
        try {
            $lastSample = Get-SmokeSentinelStatus -Bitmap $bitmap -Geometry $Geometry
        } finally {
            $bitmap.Dispose()
        }

        if ($lastSample.Visible) {
            return [pscustomobject]@{
                Label = $Label
                OutputPath = $OutputPath
                Attempt = $attempt
                MatchingPixels = $lastSample.MatchingPixels
                MinimumMatches = $lastSample.MinimumMatches
                ClosestDistance = $lastSample.ClosestDistance
            }
        }

        if ($attempt -lt $maxCaptureAttempts) {
            Start-Sleep -Seconds 1
        }
    }

    throw ("{0} capture never showed the shared smoke sentinel (closest distance {1}, matching pixels {2}/{3})." -f $Label, $lastSample.ClosestDistance, $lastSample.MatchingPixels, $lastSample.MinimumMatches)
}

function Capture-GameplaySmokeWindow {
    param(
        [string]$Label,
        [string]$OutputPath,
        [hashtable]$PageFlipTopGeometry,
        [hashtable]$PageFlipLowerGeometry,
        [hashtable]$PageFlipStrategyGeometry,
        [hashtable]$DegradedTopGeometry,
        [hashtable]$DegradedLowerGeometry,
        [hashtable]$DegradedStrategyGeometry
    )

    $lastPageFlipTopSample = $null
    $lastPageFlipLowerSample = $null
    $lastPageFlipStrategySample = $null
    $lastDegradedTopSample = $null
    $lastDegradedLowerSample = $null
    $lastDegradedStrategySample = $null
    $maxCaptureAttempts = 3
    for ($attempt = 1; $attempt -le $maxCaptureAttempts; $attempt++) {
        Invoke-VmScreenshot -Name $VmName -OutputPath $OutputPath -Context ("vm smoke screenshot ({0})" -f $Label.ToLowerInvariant())
        if (-not (Test-Path -LiteralPath $OutputPath)) {
            throw ("{0} screenshot was not created: {1}" -f $Label, $OutputPath)
        }

        $bitmap = [System.Drawing.Bitmap]::FromFile($OutputPath)
        try {
            $lastPageFlipTopSample = Get-SmokeSentinelStatus -Bitmap $bitmap -Geometry $PageFlipTopGeometry
            $lastPageFlipLowerSample = Get-SmokeSentinelStatus -Bitmap $bitmap -Geometry $PageFlipLowerGeometry
            $lastPageFlipStrategySample = Get-GameplayPresentStrategyStatus -Bitmap $bitmap -Geometry $PageFlipStrategyGeometry
            $lastDegradedTopSample = Get-SmokeSentinelStatus -Bitmap $bitmap -Geometry $DegradedTopGeometry
            $lastDegradedLowerSample = Get-SmokeSentinelStatus -Bitmap $bitmap -Geometry $DegradedLowerGeometry
            $lastDegradedStrategySample = Get-GameplayPresentStrategyStatus -Bitmap $bitmap -Geometry $DegradedStrategyGeometry
        } finally {
            $bitmap.Dispose()
        }

        if ($lastPageFlipTopSample.Visible -and $lastPageFlipLowerSample.Visible -and $lastPageFlipStrategySample.Visible -and $lastPageFlipStrategySample.Mode -eq 'page-flip') {
            return [pscustomobject]@{
                Label = $Label
                OutputPath = $OutputPath
                Attempt = $attempt
                TopMatchingPixels = $lastPageFlipTopSample.MatchingPixels
                TopMinimumMatches = $lastPageFlipTopSample.MinimumMatches
                TopClosestDistance = $lastPageFlipTopSample.ClosestDistance
                LowerMatchingPixels = $lastPageFlipLowerSample.MatchingPixels
                LowerMinimumMatches = $lastPageFlipLowerSample.MinimumMatches
                LowerClosestDistance = $lastPageFlipLowerSample.ClosestDistance
                PresentStrategy = $lastPageFlipStrategySample.Mode
                StrategyVisible = $lastPageFlipStrategySample.Visible
                StrategyMinimumMatches = $lastPageFlipStrategySample.MinimumMatches
                PageFlipMatches = $lastPageFlipStrategySample.PageFlipMatches
                DegradedMatches = $lastPageFlipStrategySample.DegradedMatches
                ClosestPageFlipDistance = $lastPageFlipStrategySample.ClosestPageFlipDistance
                ClosestDegradedDistance = $lastPageFlipStrategySample.ClosestDegradedDistance
            }
        }

        if ($lastDegradedTopSample.Visible -and $lastDegradedLowerSample.Visible -and $lastDegradedStrategySample.Visible -and $lastDegradedStrategySample.Mode -eq 'degraded-blit') {
            return [pscustomobject]@{
                Label = $Label
                OutputPath = $OutputPath
                Attempt = $attempt
                TopMatchingPixels = $lastDegradedTopSample.MatchingPixels
                TopMinimumMatches = $lastDegradedTopSample.MinimumMatches
                TopClosestDistance = $lastDegradedTopSample.ClosestDistance
                LowerMatchingPixels = $lastDegradedLowerSample.MatchingPixels
                LowerMinimumMatches = $lastDegradedLowerSample.MinimumMatches
                LowerClosestDistance = $lastDegradedLowerSample.ClosestDistance
                PresentStrategy = $lastDegradedStrategySample.Mode
                StrategyVisible = $lastDegradedStrategySample.Visible
                StrategyMinimumMatches = $lastDegradedStrategySample.MinimumMatches
                PageFlipMatches = $lastDegradedStrategySample.PageFlipMatches
                DegradedMatches = $lastDegradedStrategySample.DegradedMatches
                ClosestPageFlipDistance = $lastDegradedStrategySample.ClosestPageFlipDistance
                ClosestDegradedDistance = $lastDegradedStrategySample.ClosestDegradedDistance
            }
        }

        if ($attempt -lt $maxCaptureAttempts) {
            Start-Sleep -Seconds 1
        }
    }

    $firstFailingRegion = if (-not $lastPageFlipTopSample.Visible -and -not $lastDegradedTopSample.Visible) {
        'upper gameplay proof'
    } elseif (-not $lastPageFlipLowerSample.Visible -and -not $lastDegradedLowerSample.Visible) {
        'lower gameplay proof'
    } else {
        'present strategy marker'
    }
    $resolvedStrategyMode = if ($lastPageFlipStrategySample.Visible) {
        $lastPageFlipStrategySample.Mode
    } elseif ($lastDegradedStrategySample.Visible) {
        $lastDegradedStrategySample.Mode
    } else {
        'unknown'
    }

    throw ("{0} capture never stabilized the gameplay presenter ({1} failed first; upper {2}/{3} distance {4}; lower {5}/{6} distance {7}; strategy {8} page-flip {9}/{10} distance {11}, degraded {12}/{10} distance {13})." -f `
        $Label, `
        $firstFailingRegion, `
        ([Math]::Max($lastPageFlipTopSample.MatchingPixels, $lastDegradedTopSample.MatchingPixels)), `
        ([Math]::Max($lastPageFlipTopSample.MinimumMatches, $lastDegradedTopSample.MinimumMatches)), `
        ([Math]::Min($lastPageFlipTopSample.ClosestDistance, $lastDegradedTopSample.ClosestDistance)), `
        ([Math]::Max($lastPageFlipLowerSample.MatchingPixels, $lastDegradedLowerSample.MatchingPixels)), `
        ([Math]::Max($lastPageFlipLowerSample.MinimumMatches, $lastDegradedLowerSample.MinimumMatches)), `
        ([Math]::Min($lastPageFlipLowerSample.ClosestDistance, $lastDegradedLowerSample.ClosestDistance)), `
        $resolvedStrategyMode, `
        ([Math]::Max($lastPageFlipStrategySample.PageFlipMatches, $lastDegradedStrategySample.PageFlipMatches)), `
        ([Math]::Max($lastPageFlipStrategySample.MinimumMatches, $lastDegradedStrategySample.MinimumMatches)), `
        ([Math]::Min($lastPageFlipStrategySample.ClosestPageFlipDistance, $lastDegradedStrategySample.ClosestPageFlipDistance)), `
        ([Math]::Max($lastPageFlipStrategySample.DegradedMatches, $lastDegradedStrategySample.DegradedMatches)), `
        ([Math]::Min($lastPageFlipStrategySample.ClosestDegradedDistance, $lastDegradedStrategySample.ClosestDegradedDistance)))
}

if ($WaitSeconds -lt 8) {
    throw 'WaitSeconds must be at least 8 so the smoke path can reach splash -> title timing before the direct gameplay proof boot.'
}

if ([string]::IsNullOrWhiteSpace($AudioConfigPath)) {
    $AudioConfigPath = Join-Path $buildDir 'audio_config.inc'
}

Assert-PathExists -Path $vbox -Label 'VBoxManage'
Assert-PathExists -Path $diskImage -Label 'boot image'
Assert-PathExists -Path $AudioConfigPath -Label 'audio config'
Assert-PathExists -Path $ConstantsSourcePath -Label 'assembly constants source'
Assert-PathExists -Path $BuildScriptPath -Label 'build script'
Assert-PathExists -Path $DeployScriptPath -Label 'deploy script'

New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null

$status = 'PASS'
$summaryLines = @()
$artifactPaths = @($ReportPath, $startupScreenshotPath, $titleScreenshotPath, $screenshotPath, $logCopyPath)
$audioModeValue = Get-AsmEquValue -SourcePath $AudioConfigPath -Name 'AUDIO_MODE'
$audioModeName = if ($audioModeValue -eq 1) { 'MUSIC' } else { 'SFX_ONLY' }
$geometry = @{
    ScreenW = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SCREEN_W'
    ScreenH = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SCREEN_H'
    X = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_SENTINEL_X'
    Y = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_SENTINEL_Y'
    W = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_SENTINEL_W'
    H = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_SENTINEL_H'
    R = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_SENTINEL_R'
    G = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_SENTINEL_G'
    B = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_SENTINEL_B'
}
$gameplayGeometry = @{
    ScreenW = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SCREEN_W'
    ScreenH = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'GAMEPLAY_SCREEN_H'
    X = $geometry.X
    Y = $geometry.Y
    W = $geometry.W
    H = $geometry.H
    R = $geometry.R
    G = $geometry.G
    B = $geometry.B
}
$gameplayTopDegradedGeometry = @{
    ScreenW = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SCREEN_W'
    ScreenH = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SCREEN_H'
    X = $geometry.X
    Y = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_TOP_DEGRADED_Y'
    W = $geometry.W
    H = $geometry.H
    R = $geometry.R
    G = $geometry.G
    B = $geometry.B
}
$gameplayLowerGeometry = @{
    ScreenW = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SCREEN_W'
    ScreenH = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'GAMEPLAY_SCREEN_H'
    X = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_PROOF_X'
    Y = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_PROOF_Y'
    W = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_PROOF_W'
    H = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_PROOF_H'
    R = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_PROOF_R'
    G = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_PROOF_G'
    B = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_PROOF_B'
}
$gameplayLowerDegradedGeometry = @{
    ScreenW = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SCREEN_W'
    ScreenH = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SCREEN_H'
    X = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_PROOF_X'
    Y = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_PROOF_DEGRADED_Y'
    W = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_PROOF_W'
    H = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_PROOF_H'
    R = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_PROOF_R'
    G = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_PROOF_G'
    B = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_PROOF_B'
}
$gameplayStrategyGeometry = @{
    ScreenW = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SCREEN_W'
    ScreenH = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'GAMEPLAY_SCREEN_H'
    X = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_STRATEGY_X'
    Y = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_STRATEGY_Y'
    W = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_STRATEGY_W'
    H = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_STRATEGY_H'
    PageFlipR = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_STRATEGY_PAGE_FLIP_R'
    PageFlipG = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_STRATEGY_PAGE_FLIP_G'
    PageFlipB = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_STRATEGY_PAGE_FLIP_B'
    DegradedR = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_STRATEGY_DEGRADED_R'
    DegradedG = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_STRATEGY_DEGRADED_G'
    DegradedB = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_STRATEGY_DEGRADED_B'
}
$gameplayStrategyDegradedGeometry = @{
    ScreenW = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SCREEN_W'
    ScreenH = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SCREEN_H'
    X = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_STRATEGY_X'
    Y = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_STRATEGY_DEGRADED_Y'
    W = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_STRATEGY_W'
    H = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_STRATEGY_H'
    PageFlipR = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_STRATEGY_PAGE_FLIP_R'
    PageFlipG = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_STRATEGY_PAGE_FLIP_G'
    PageFlipB = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_STRATEGY_PAGE_FLIP_B'
    DegradedR = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_STRATEGY_DEGRADED_R'
    DegradedG = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_STRATEGY_DEGRADED_G'
    DegradedB = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SMOKE_GAMEPLAY_STRATEGY_DEGRADED_B'
}
$startupCaptureSeconds = 2
$titleCaptureSeconds = [Math]::Min(($WaitSeconds - 2), 6)
if ($titleCaptureSeconds -le $startupCaptureSeconds) {
    $titleCaptureSeconds = $startupCaptureSeconds + 1
}
$titleSleepSeconds = $titleCaptureSeconds - $startupCaptureSeconds
$gameplayCaptureSeconds = 3
$restoreRelease = $false
$caughtException = $null

try {
    Stop-VmIfRunning -Name $VmName
    Ensure-VmRegistered -Name $VmName -Context 'vm smoke registration'
    Stop-VmIfRunning -Name $VmName

    Invoke-ChildBuild -ExtraArguments @('-DebugRenderSentinels')
    $restoreRelease = $true
    Invoke-DeployVm -Name $VmName

    Start-HeadlessVm -Name $VmName -Context 'vm smoke startvm'
    Start-Sleep -Seconds $startupCaptureSeconds
    $startupCapture = Capture-SmokeWindow -Label 'Startup' -OutputPath $startupScreenshotPath -Geometry $geometry

    if ($titleSleepSeconds -gt 0) {
        Start-Sleep -Seconds $titleSleepSeconds
    }
    $titleCapture = Capture-SmokeWindow -Label 'Title' -OutputPath $titleScreenshotPath -Geometry $geometry

    Stop-VmIfRunning -Name $VmName
    Invoke-ChildBuild -ExtraArguments @('-DebugRenderSentinels', '-DebugStartInGame')
    Invoke-DeployVm -Name $VmName
    Start-HeadlessVm -Name $VmName -Context 'vm smoke gameplay startvm'
    Start-Sleep -Seconds $gameplayCaptureSeconds

    if (-not (Test-Path -LiteralPath $vboxLogPath)) {
        throw ("VBox log was not found after smoke boot: {0}" -f $vboxLogPath)
    }

    $liveLogLines = Get-Content -LiteralPath $vboxLogPath
    if (@($liveLogLines | Where-Object { $_ -match "Machine state changed to 'Running'" }).Count -eq 0) {
        throw 'VBox log never reported the VM entering the Running state.'
    }

    if (@($liveLogLines | Where-Object { $_ -match 'Booting from Hard Disk|Booting from fixed disk' }).Count -eq 0) {
        throw 'VBox log never reached the hard-disk boot path.'
    }

    $gameplayCapture = Capture-GameplaySmokeWindow `
        -Label 'Gameplay' `
        -OutputPath $screenshotPath `
        -PageFlipTopGeometry $gameplayGeometry `
        -PageFlipLowerGeometry $gameplayLowerGeometry `
        -PageFlipStrategyGeometry $gameplayStrategyGeometry `
        -DegradedTopGeometry $gameplayTopDegradedGeometry `
        -DegradedLowerGeometry $gameplayLowerDegradedGeometry `
        -DegradedStrategyGeometry $gameplayStrategyDegradedGeometry

    Copy-Item -LiteralPath $vboxLogPath -Destination $logCopyPath -Force
    $logLines = Get-Content -LiteralPath $logCopyPath
    $badLogPattern = '(?i)Guru Meditation|triple fault|triple-fault|unrecoverable'
    $badLogMatches = @($logLines | Where-Object { $_ -match $badLogPattern })
    if ($badLogMatches.Count -gt 0) {
        throw ("VBox log contained obvious failure markers: {0}" -f $badLogMatches[0].Trim())
    }

    $sb16ConfigSeen = @($logLines | Where-Object { $_ -match '\[/Devices/sb16/0/\]' }).Count -gt 0
    if (-not $sb16ConfigSeen) {
        throw 'VBox log never reported the SB16 device configuration, so the audio path is not trustworthy.'
    }

    $hostAudioDriver = 'unknown'
    $driverMatchLine = $logLines | Where-Object { $_ -match 'DriverName\s+<string>\s+= "([^"]+)"' } | Select-Object -First 1
    if ($driverMatchLine -and $driverMatchLine -match 'DriverName\s+<string>\s+= "([^"]+)"') {
        $hostAudioDriver = $Matches[1]
    } else {
        $driverMatchLine = $logLines | Where-Object { $_ -match 'Driver <string>\s+= "([^"]+)"' -and $_ -match 'HostAudio' } | Select-Object -First 1
        if ($driverMatchLine -and $driverMatchLine -match 'Driver <string>\s+= "([^"]+)"') {
            $hostAudioDriver = $Matches[1]
        }
    }

    $defaultAudioDriver = 'unknown'
    $defaultDriverLine = $logLines | Where-Object { $_ -match "Audio: Detected default audio driver type is '([^']+)'" } | Select-Object -First 1
    if ($defaultDriverLine -and $defaultDriverLine -match "Audio: Detected default audio driver type is '([^']+)'") {
        $defaultAudioDriver = $Matches[1]
    }

    $summaryLines = @(
        'Status: PASS'
        ("VM: {0}" -f $VmName)
        'Frontend: headless'
        ("Wait: {0}s (targets splash -> title proof, then direct gameplay presenter proof)" -f $WaitSeconds)
        ("Audio mode: {0}" -f $audioModeName)
        ("Audio controller: SB16 via {0} (host default {1})" -f $hostAudioDriver, $defaultAudioDriver)
        ("Smoke sentinel: x={0} y={1} w={2} h={3} rgb=({4},{5},{6})" -f $geometry.X, $geometry.Y, $geometry.W, $geometry.H, $geometry.R, $geometry.G, $geometry.B)
        ("Gameplay proof marker: x={0} y={1} w={2} h={3} rgb=({4},{5},{6})" -f $gameplayLowerGeometry.X, $gameplayLowerGeometry.Y, $gameplayLowerGeometry.W, $gameplayLowerGeometry.H, $gameplayLowerGeometry.R, $gameplayLowerGeometry.G, $gameplayLowerGeometry.B)
        ("Startup render proof: sentinel matched on attempt {0} with {1}/{2} pixels (closest distance {3})." -f $startupCapture.Attempt, $startupCapture.MatchingPixels, $startupCapture.MinimumMatches, $startupCapture.ClosestDistance)
        ("Title render proof: sentinel matched on attempt {0} with {1}/{2} pixels (closest distance {3})." -f $titleCapture.Attempt, $titleCapture.MatchingPixels, $titleCapture.MinimumMatches, $titleCapture.ClosestDistance)
        ("Gameplay present strategy: {0}" -f $gameplayCapture.PresentStrategy)
        ("Gameplay upper proof: matched on attempt {0} with {1}/{2} pixels (closest distance {3})." -f $gameplayCapture.Attempt, $gameplayCapture.TopMatchingPixels, $gameplayCapture.TopMinimumMatches, $gameplayCapture.TopClosestDistance)
        ("Gameplay lower proof: matched on attempt {0} with {1}/{2} pixels (closest distance {3})." -f $gameplayCapture.Attempt, $gameplayCapture.LowerMatchingPixels, $gameplayCapture.LowerMinimumMatches, $gameplayCapture.LowerClosestDistance)
        ("Gameplay strategy proof: page-flip matches {0}/{1} (closest distance {2}); degraded matches {3}/{1} (closest distance {4})." -f $gameplayCapture.PageFlipMatches, $gameplayCapture.StrategyMinimumMatches, $gameplayCapture.ClosestPageFlipDistance, $gameplayCapture.DegradedMatches, $gameplayCapture.ClosestDegradedDistance)
        ("Startup screenshot: {0}" -f $startupScreenshotPath)
        ("Title screenshot: {0}" -f $titleScreenshotPath)
        ("Screenshot: {0}" -f $screenshotPath)
        ("VBox log: {0}" -f $logCopyPath)
    )
} catch {
    $failureKind = Get-VBoxFailureKind -Message $_.Exception.Message
    $status = 'FAIL'
    $summaryLines = @(
        'Status: FAIL'
        ("Failure class: {0}" -f $failureKind)
        ("VM: {0}" -f $VmName)
        ("Wait: {0}s (targets splash -> title proof, then direct gameplay presenter proof)" -f $WaitSeconds)
        ("Audio mode: {0}" -f $audioModeName)
        ("Smoke sentinel: x={0} y={1} w={2} h={3} rgb=({4},{5},{6})" -f $geometry.X, $geometry.Y, $geometry.W, $geometry.H, $geometry.R, $geometry.G, $geometry.B)
        ("Error: {0}" -f $_.Exception.Message)
    )
    $caughtException = $_
} finally {
    Stop-VmIfRunning -Name $VmName
    if ($restoreRelease) {
        try {
            Invoke-ChildBuild -ExtraArguments @()
        } catch {
            $status = 'FAIL'
            $summaryLines += ("Release restore failed: {0}" -f $_.Exception.Message)
            if ($null -eq $caughtException) {
                $caughtException = $_
            }
        }
    }

    Write-SmokeReport -Path $ReportPath -Lines (@(
        'CyberStorm VM Smoke Report'
        ("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'))
    ) + $summaryLines)
}

if ($null -ne $caughtException) {
    throw $caughtException
}

[pscustomobject]@{
    Status = $status
    ReportPath = $ReportPath
    SummaryLines = $summaryLines
    ArtifactPaths = $artifactPaths
}
