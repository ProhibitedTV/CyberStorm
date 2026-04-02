param(
    [string]$VmName = 'CyberStorm',
    [int]$WaitSeconds = 14,
    [string]$AudioConfigPath,
    [string]$ReportPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $root 'build'
$artifactDir = Join-Path $buildDir 'vm-smoke'
$deployScript = Join-Path $PSScriptRoot 'deploy-vm.ps1'
$vbox = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
$floppy = Join-Path $buildDir 'cyberstorm.vfd'

if ([string]::IsNullOrWhiteSpace($AudioConfigPath)) {
    $AudioConfigPath = Join-Path $buildDir 'audio_config.inc'
}

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = Join-Path $buildDir 'cyberstorm-vm-smoke-report.txt'
}

$titleScreenshotPath = Join-Path $artifactDir 'cyberstorm-vm-smoke-title.png'
$screenshotPath = Join-Path $artifactDir 'cyberstorm-vm-smoke.png'
$logCopyPath = Join-Path $artifactDir 'cyberstorm-vm-smoke.log'
$targetPath = Join-Path $root ("deploy\virtualbox\{0}\Logs\VBox.log" -f $VmName)

function Invoke-VBoxManage {
    param(
        [string[]]$Arguments,
        [int]$Attempt = 0
    )

    $captured = New-Object 'System.Collections.Generic.List[string]'
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $vbox @Arguments 2>&1 | ForEach-Object {
            $captured.Add($_.ToString())
        }
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($LASTEXITCODE -eq 0) {
        return $captured.ToArray()
    }

    $message = $captured -join [Environment]::NewLine
    if ($Attempt -lt 3 -and $message -match 'CO_E_SERVER_EXEC_FAILURE|Failed to create the VirtualBox object') {
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            & taskkill /F /IM VBoxSVC.exe /IM VBoxHeadless.exe /IM VirtualBoxVM.exe *>$null
        } finally {
            $ErrorActionPreference = $previousErrorActionPreference
        }
        Start-Sleep -Seconds (2 + ($Attempt * 3))
        return Invoke-VBoxManage -Arguments $Arguments -Attempt ($Attempt + 1)
    }

    throw ("VBoxManage failed: {0}`n{1}" -f ($Arguments -join ' '), $message)
}

function Stop-VmIfRunning {
    param([string]$Name)

    try {
        Invoke-VBoxManage -Arguments @('controlvm', $Name, 'poweroff') | Out-Null
        Start-Sleep -Seconds 2
    } catch {
        return
    }
}

function Start-HeadlessVm {
    param([string]$Name)

    Invoke-VBoxManage -Arguments @('startvm', $Name, '--type', 'headless') | Out-Null
    Start-Sleep -Seconds 2
}

function Invoke-DeployVm {
    param([string]$Name)

    & powershell -ExecutionPolicy Bypass -File $deployScript -VmName $Name | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw ("Deploy script failed for VM '{0}'." -f $Name)
    }
}

function Ensure-VmRegistered {
    param([string]$Name)

    try {
        Invoke-VBoxManage -Arguments @('showvminfo', $Name) | Out-Null
    } catch {
        if ($_.Exception.Message -match 'Could not find a registered machine named|VBOX_E_OBJECT_NOT_FOUND') {
            Invoke-DeployVm -Name $Name
            return
        }

        throw
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

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        throw ("Missing assembly include: {0}" -f $SourcePath)
    }

    $pattern = "^\s*{0}\s+EQU\s+([0-9A-Fa-f]+h|\d+)\s*(?:;.*)?$" -f [regex]::Escape($Name)
    $match = Select-String -LiteralPath $SourcePath -Pattern $pattern | Select-Object -First 1
    if (-not $match) {
        throw ("Could not find '{0} EQU <value>' in {1}" -f $Name, $SourcePath)
    }

    $token = $match.Matches[0].Groups[1].Value
    if ($token -match '^[0-9A-Fa-f]+h$') {
        return [Convert]::ToInt32($token.Substring(0, $token.Length - 1), 16)
    }

    return [int]$token
}

if ($WaitSeconds -lt 8) {
    throw 'WaitSeconds must be at least 8 so the smoke path can reach splash -> title -> attract timing.'
}

if (-not (Test-Path -LiteralPath $vbox)) {
    throw 'VBoxManage.exe was not found in the default Oracle VirtualBox install path.'
}

if (-not (Test-Path -LiteralPath $floppy)) {
    throw "Boot image not found: $floppy. Run scripts/build.ps1 first."
}

if (-not (Test-Path -LiteralPath $AudioConfigPath)) {
    throw "Audio config not found: $AudioConfigPath. Run scripts/build.ps1 first."
}

if (-not (Test-Path -LiteralPath $deployScript)) {
    throw "Deploy script not found: $deployScript"
}

New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null

$status = 'PASS'
$summaryLines = @()
$artifactPaths = @($ReportPath, $titleScreenshotPath, $screenshotPath, $logCopyPath)
$audioModeValue = Get-AsmEquValue -SourcePath $AudioConfigPath -Name 'AUDIO_MODE'
$audioModeName = if ($audioModeValue -eq 1) { 'EXPERIMENTAL_MUSIC' } else { 'SFX_ONLY' }
$titleCaptureSeconds = [Math]::Max(8, ($WaitSeconds - 6))
$attractCaptureSeconds = $WaitSeconds - $titleCaptureSeconds

try {
    Stop-VmIfRunning -Name $VmName
    Ensure-VmRegistered -Name $VmName
    Stop-VmIfRunning -Name $VmName

    Start-HeadlessVm -Name $VmName
    Start-Sleep -Seconds $titleCaptureSeconds
    Invoke-VBoxManage -Arguments @('controlvm', $VmName, 'screenshotpng', $titleScreenshotPath) | Out-Null
    if (-not (Test-Path -LiteralPath $titleScreenshotPath)) {
        throw ("VM smoke title screenshot was not created: {0}" -f $titleScreenshotPath)
    }

    if ($attractCaptureSeconds -gt 0) {
        Start-Sleep -Seconds $attractCaptureSeconds
    }

    if (-not (Test-Path -LiteralPath $targetPath)) {
        throw ("VBox log was not found after smoke boot: {0}" -f $targetPath)
    }

    $liveLogLines = Get-Content -LiteralPath $targetPath
    if (@($liveLogLines | Where-Object { $_ -match "Machine state changed to 'Running'" }).Count -eq 0) {
        throw 'VBox log never reported the VM entering the Running state.'
    }

    if (@($liveLogLines | Where-Object { $_ -match 'Booting from Floppy' }).Count -eq 0) {
        throw 'VBox log never reached the floppy boot path.'
    }

    Invoke-VBoxManage -Arguments @('controlvm', $VmName, 'screenshotpng', $screenshotPath) | Out-Null
    if (-not (Test-Path -LiteralPath $screenshotPath)) {
        throw ("VM smoke screenshot was not created: {0}" -f $screenshotPath)
    }

    Copy-Item -LiteralPath $targetPath -Destination $logCopyPath -Force
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
        ("Splash/title expectation: screenshotpng succeeded after {0}s in the boot -> splash -> title window." -f $titleCaptureSeconds)
        ("Attract expectation: screenshotpng succeeded after the full {0}s smoke window." -f $WaitSeconds)
        ("Title screenshot: {0}" -f $titleScreenshotPath)
        ("Screenshot: {0}" -f $screenshotPath)
        ("VBox log: {0}" -f $logCopyPath)
    )
} catch {
    $status = 'FAIL'
    $summaryLines = @(
        'Status: FAIL'
        ("VM: {0}" -f $VmName)
        ("Wait: {0}s (targets splash -> title -> attract demo)" -f $WaitSeconds)
        ("Audio mode: {0}" -f $audioModeName)
        ("Error: {0}" -f $_.Exception.Message)
    )
    Write-SmokeReport -Path $ReportPath -Lines (@(
        'CyberStorm VM Smoke Report'
        ("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'))
    ) + $summaryLines)
    throw
} finally {
    Stop-VmIfRunning -Name $VmName
}

Write-SmokeReport -Path $ReportPath -Lines (@(
    'CyberStorm VM Smoke Report'
    ("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'))
) + $summaryLines)

[pscustomobject]@{
    Status = $status
    ReportPath = $ReportPath
    SummaryLines = $summaryLines
    ArtifactPaths = $artifactPaths
}
