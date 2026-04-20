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

function Capture-SmokeWindow {
    param(
        [string]$Label,
        [string]$OutputPath,
        [hashtable]$Geometry
    )

    $lastSample = $null
    $maxCaptureAttempts = 3
    for ($attempt = 1; $attempt -le $maxCaptureAttempts; $attempt++) {
        Invoke-VmScreenshot -Name $VmName -OutputPath $OutputPath
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

if ($WaitSeconds -lt 8) {
    throw 'WaitSeconds must be at least 8 so the smoke path can reach splash -> title -> attract timing.'
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
$startupCaptureSeconds = 2
$titleCaptureSeconds = [Math]::Min(($WaitSeconds - 2), 6)
if ($titleCaptureSeconds -le $startupCaptureSeconds) {
    $titleCaptureSeconds = $startupCaptureSeconds + 1
}
$titleSleepSeconds = $titleCaptureSeconds - $startupCaptureSeconds
$attractCaptureSeconds = $WaitSeconds - $titleCaptureSeconds
$restoreRelease = $false
$caughtException = $null

try {
    Stop-VmIfRunning -Name $VmName
    Ensure-VmRegistered -Name $VmName
    Stop-VmIfRunning -Name $VmName

    Invoke-ChildBuild -ExtraArguments @('-DebugRenderSentinels')
    $restoreRelease = $true
    Invoke-DeployVm -Name $VmName

    Start-HeadlessVm -Name $VmName
    Start-Sleep -Seconds $startupCaptureSeconds
    $startupCapture = Capture-SmokeWindow -Label 'Startup' -OutputPath $startupScreenshotPath -Geometry $geometry

    if ($titleSleepSeconds -gt 0) {
        Start-Sleep -Seconds $titleSleepSeconds
    }
    $titleCapture = Capture-SmokeWindow -Label 'Title' -OutputPath $titleScreenshotPath -Geometry $geometry

    if ($attractCaptureSeconds -gt 0) {
        Start-Sleep -Seconds $attractCaptureSeconds
    }

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

    $attractCapture = Capture-SmokeWindow -Label 'Attract' -OutputPath $screenshotPath -Geometry $geometry

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
        ("Wait: {0}s (targets splash -> title -> attract demo)" -f $WaitSeconds)
        ("Audio mode: {0}" -f $audioModeName)
        ("Audio controller: SB16 via {0} (host default {1})" -f $hostAudioDriver, $defaultAudioDriver)
        ("Smoke sentinel: x={0} y={1} w={2} h={3} rgb=({4},{5},{6})" -f $geometry.X, $geometry.Y, $geometry.W, $geometry.H, $geometry.R, $geometry.G, $geometry.B)
        ("Startup render proof: sentinel matched on attempt {0} with {1}/{2} pixels (closest distance {3})." -f $startupCapture.Attempt, $startupCapture.MatchingPixels, $startupCapture.MinimumMatches, $startupCapture.ClosestDistance)
        ("Title render proof: sentinel matched on attempt {0} with {1}/{2} pixels (closest distance {3})." -f $titleCapture.Attempt, $titleCapture.MatchingPixels, $titleCapture.MinimumMatches, $titleCapture.ClosestDistance)
        ("Attract render proof: sentinel matched on attempt {0} with {1}/{2} pixels (closest distance {3})." -f $attractCapture.Attempt, $attractCapture.MatchingPixels, $attractCapture.MinimumMatches, $attractCapture.ClosestDistance)
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
        ("Wait: {0}s (targets splash -> title -> attract demo)" -f $WaitSeconds)
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
