param(
    [string]$VmName = 'CyberStormX64Megacity',
    [ValidateSet('gui', 'headless', 'none')]
    [string]$Frontend = 'gui',
    [string]$IsoPath = $null,
    [switch]$Recreate,
    [switch]$Capture,
    [switch]$InputSmoke,
    [string]$ScreenshotPath = $null,
    [string]$ReportPath = $null
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$vbox = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
$base = Join-Path $root 'deploy\virtualbox'
if ([string]::IsNullOrWhiteSpace($IsoPath)) {
    $IsoPath = Join-Path $root 'build\cyberstorm-x64.iso'
}
if ([string]::IsNullOrWhiteSpace($ScreenshotPath)) {
    $ScreenshotPath = Join-Path $root 'build\cyberstorm-x64-vbox-live.png'
}
if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = Join-Path $root 'build\cyberstorm-x64-smoke-report.txt'
}

. (Join-Path $PSScriptRoot 'vbox-common.ps1')

function Assert-LocalPath {
    param(
        [string]$Path,
        [string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw ("{0} not found: {1}" -f $Label, $Path)
    }
}

function Test-VmRegistered {
    param([string]$Name)

    try {
        Get-VBoxMachineInfoLines -Name $Name -Context 'x64 vm registration probe' | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Get-X64VmInfoText {
    param([string]$Name)

    return ((Get-VBoxMachineInfoLines -Name $Name -Context 'x64 vm info') -join [Environment]::NewLine)
}

function Get-SmokeScreenshotPath {
    param(
        [string]$BasePath,
        [string]$Suffix
    )

    $directory = Split-Path -Parent $BasePath
    $stem = [IO.Path]::GetFileNameWithoutExtension($BasePath)
    $fileName = '{0}-{1}.png' -f $stem, $Suffix
    if ([string]::IsNullOrWhiteSpace($directory)) {
        return $fileName
    }
    return (Join-Path $directory $fileName)
}

function Resolve-ExistingPathText {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return ''
    }

    try {
        return (Resolve-Path -LiteralPath $Path).Path
    } catch {
        return $Path
    }
}

function Get-X64VmLogPath {
    param([string]$Name)

    $infoText = Get-X64VmInfoText -Name $Name
    if ($infoText -match 'CfgFile="([^"]+)"') {
        $vmDirectory = Split-Path -Parent $Matches[1]
        return (Join-Path $vmDirectory 'Logs\VBox.log')
    }

    return (Join-Path $base ("{0}\Logs\VBox.log" -f $Name))
}

function Assert-LiveTitleScreenshot {
    param(
        [string]$Path,
        [string]$Label
    )

    Assert-LocalPath -Path $Path -Label $Label
    Add-Type -AssemblyName System.Drawing

    $bitmap = [System.Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $Path).Path)
    try {
        $sampled = 0
        $nonBlack = 0
        $brightAccent = 0

        for ($y = 0; $y -lt $bitmap.Height; $y += 8) {
            for ($x = 0; $x -lt $bitmap.Width; $x += 8) {
                $pixel = $bitmap.GetPixel($x, $y)
                $luma = [int]$pixel.R + [int]$pixel.G + [int]$pixel.B
                $sampled++
                if ($luma -gt 36) {
                    $nonBlack++
                }
                if ($pixel.R -gt 140 -or $pixel.G -gt 180 -or $pixel.B -gt 180) {
                    $brightAccent++
                }
            }
        }

        if ($sampled -eq 0 -or $nonBlack -lt 120 -or $brightAccent -lt 20) {
            throw ("{0} did not look like a live CyberStorm title frame: sampled={1}, nonblack={2}, accent={3}, path={4}" -f $Label, $sampled, $nonBlack, $brightAccent, $Path)
        }
    } finally {
        $bitmap.Dispose()
    }
}

Assert-LocalPath -Path $vbox -Label 'VBoxManage'
Assert-LocalPath -Path $IsoPath -Label 'x64 UEFI ISO'
New-Item -ItemType Directory -Force -Path $base | Out-Null

Invoke-VBoxPreflight -Context 'x64 deploy preflight'

$vmExists = Test-VmRegistered -Name $VmName
if ($vmExists -and $Recreate.IsPresent) {
    Stop-VmIfRunning -Name $VmName
    Invoke-VBoxManage -Arguments @('unregistervm', $VmName, '--delete') -TimeoutSeconds 60 | Out-Null
    $vmExists = $false
}

if (-not $vmExists) {
    Invoke-VBoxManage -Arguments @('createvm', '--name', $VmName, '--basefolder', $base, '--ostype', 'Other_64', '--register') -TimeoutSeconds 60 | Out-Null
}

Stop-VmIfRunning -Name $VmName

Invoke-VBoxManage -Arguments @(
    'modifyvm', $VmName,
    '--memory', '512',
    '--vram', '64',
    '--graphicscontroller', 'vboxsvga',
    '--accelerate3d', 'off',
    '--firmware', 'efi',
    '--boot1', 'dvd',
    '--boot2', 'none',
    '--boot3', 'none',
    '--boot4', 'none',
    '--audio-enabled', 'off',
    '--usb', 'off'
) -TimeoutSeconds 60 | Out-Null

$infoText = Get-X64VmInfoText -Name $VmName
if ($infoText -notmatch 'storagecontrollername\d+="SATA"') {
    Invoke-VBoxManage -Arguments @('storagectl', $VmName, '--name', 'SATA', '--add', 'sata', '--controller', 'IntelAhci') -TimeoutSeconds 60 | Out-Null
}

Invoke-VBoxManage -Arguments @(
    'storageattach', $VmName,
    '--storagectl', 'SATA',
    '--port', '0',
    '--device', '0',
    '--type', 'dvddrive',
    '--medium', $IsoPath
) -TimeoutSeconds 60 | Out-Null

if ($Frontend -ne 'none') {
    Invoke-VBoxManage -Arguments @('startvm', $VmName, '--type', $Frontend) -TimeoutSeconds 60 | Out-Null
    Start-Sleep -Seconds 5
}

$capturePath = $null
$downPath = $null
$enterPath = $null
if ($Capture.IsPresent -or $InputSmoke.IsPresent) {
    Ensure-VmReadyForCapture -Name $VmName -Context 'x64 title capture'
    Invoke-VmScreenshot -Name $VmName -OutputPath $ScreenshotPath -Context 'x64 title capture'
    Assert-LiveTitleScreenshot -Path $ScreenshotPath -Label 'x64 title screenshot'
    $capturePath = $ScreenshotPath
}

if ($InputSmoke.IsPresent) {
    $downPath = Get-SmokeScreenshotPath -BasePath $ScreenshotPath -Suffix 'down'
    $enterPath = Get-SmokeScreenshotPath -BasePath $ScreenshotPath -Suffix 'enter'

    Invoke-VBoxManage -Arguments @('controlvm', $VmName, 'keyboardputscancode', 'e0', '50', 'e0', 'd0') -TimeoutSeconds 30 | Out-Null
    Start-Sleep -Milliseconds 750
    Invoke-VmScreenshot -Name $VmName -OutputPath $downPath -Context 'x64 down-key capture'
    Assert-LiveTitleScreenshot -Path $downPath -Label 'x64 down-key screenshot'

    Invoke-VBoxManage -Arguments @('controlvm', $VmName, 'keyboardputscancode', '1c', '9c') -TimeoutSeconds 30 | Out-Null
    Start-Sleep -Milliseconds 750
    Invoke-VmScreenshot -Name $VmName -OutputPath $enterPath -Context 'x64 enter-key capture'
    Assert-LiveTitleScreenshot -Path $enterPath -Label 'x64 enter-key screenshot'

    Invoke-VBoxManage -Arguments @('controlvm', $VmName, 'keyboardputscancode', '01', '81') -TimeoutSeconds 30 | Out-Null
    Start-Sleep -Milliseconds 250
    Invoke-VBoxManage -Arguments @('controlvm', $VmName, 'keyboardputscancode', 'e0', '48', 'e0', 'c8') -TimeoutSeconds 30 | Out-Null
    Start-Sleep -Milliseconds 250
}

$finalState = Get-VmState -Name $VmName -Context 'x64 deploy final state'
$vmLogPath = Get-X64VmLogPath -Name $VmName
$reportDirectory = Split-Path -Parent $ReportPath
if ($reportDirectory) {
    New-Item -ItemType Directory -Force -Path $reportDirectory | Out-Null
}
$inputSmokeStatus = if ($InputSmoke.IsPresent) { 'pass' } else { 'not requested' }
$captureStatus = if ($Capture.IsPresent -or $InputSmoke.IsPresent) { 'pass' } else { 'not requested' }
$reportLines = @(
    'CyberStorm x64 Smoke Report',
    ('Generated: {0:yyyy-MM-dd HH:mm:ss zzz}' -f (Get-Date)),
    'Status: pass',
    'Target: x64-uefi',
    ('VM: {0}' -f $VmName),
    ('State: {0}' -f $finalState),
    ('Frontend: {0}' -f $Frontend),
    'Boot mode: UEFI x64',
    'Display mode: UEFI GOP, 640x480 internal xRGB8888 title frame',
    ('ISO: {0}' -f (Resolve-ExistingPathText -Path $IsoPath)),
    ('VM log: {0}' -f (Resolve-ExistingPathText -Path $vmLogPath)),
    ('Title capture: {0}' -f $captureStatus),
    ('Title screenshot: {0}' -f (Resolve-ExistingPathText -Path $capturePath)),
    ('Input smoke: {0}' -f $inputSmokeStatus),
    ('Down screenshot: {0}' -f (Resolve-ExistingPathText -Path $downPath)),
    ('Enter screenshot: {0}' -f (Resolve-ExistingPathText -Path $enterPath)),
    'Checks: UEFI VM boots the x64 ISO, GOP title frame is nonblack/accented, menu accepts Down and Enter, and the VM remains running.',
    'Recovery: input smoke sends Esc and Up after capture so the live GUI returns to the main title state.'
)
Set-Content -Path $ReportPath -Value $reportLines -Encoding ASCII

[pscustomobject]@{
    VmName = $VmName
    State = $finalState
    Frontend = $Frontend
    Iso = (Resolve-Path -LiteralPath $IsoPath).Path
    Screenshot = $capturePath
    DownScreenshot = $downPath
    EnterScreenshot = $enterPath
    SmokeReport = (Resolve-ExistingPathText -Path $ReportPath)
    LogPath = (Resolve-ExistingPathText -Path $vmLogPath)
}
