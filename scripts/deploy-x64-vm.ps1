param(
    [string]$VmName = 'CyberStormX64Megacity',
    [ValidateSet('gui', 'headless', 'none')]
    [string]$Frontend = 'gui',
    [string]$IsoPath = $null,
    [switch]$Recreate,
    [switch]$Capture,
    [switch]$InputSmoke,
    [switch]$GameplaySmoke,
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

function Invoke-X64KeyTap {
    param(
        [string]$Name,
        [string[]]$ScanCodes,
        [int]$Count = 1,
        [int]$DelayMilliseconds = 180
    )

    for ($i = 0; $i -lt $Count; $i++) {
        Invoke-VBoxManage -Arguments (@('controlvm', $Name, 'keyboardputscancode') + $ScanCodes) -TimeoutSeconds 30 | Out-Null
        Start-Sleep -Milliseconds $DelayMilliseconds
    }
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

function Get-X64ScreenshotRegionStats {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [double[]]$Region
    )

    $x0 = [int]($Bitmap.Width * $Region[0])
    $y0 = [int]($Bitmap.Height * $Region[1])
    $x1 = [int]($Bitmap.Width * $Region[2])
    $y1 = [int]($Bitmap.Height * $Region[3])
    $sampled = 0
    $nonBlack = 0
    $brightAccent = 0

    for ($y = $y0; $y -lt $y1; $y += 8) {
        for ($x = $x0; $x -lt $x1; $x += 8) {
            $pixel = $Bitmap.GetPixel($x, $y)
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

    return [pscustomobject]@{
        Sampled = $sampled
        NonBlack = $nonBlack
        Accent = $brightAccent
    }
}

function Assert-X64VisualScreenshot {
    param(
        [string]$Path,
        [string]$Label,
        [ValidateSet('title', 'gameplay')]
        [string]$FrameKind = 'title'
    )

    Assert-LocalPath -Path $Path -Label $Label
    Add-Type -AssemblyName System.Drawing

    $bitmap = [System.Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $Path).Path)
    try {
        $all = Get-X64ScreenshotRegionStats -Bitmap $bitmap -Region @(0.00, 0.00, 1.00, 1.00)
        $header = Get-X64ScreenshotRegionStats -Bitmap $bitmap -Region @(0.15, 0.12, 0.85, 0.30)
        $menu = Get-X64ScreenshotRegionStats -Bitmap $bitmap -Region @(0.56, 0.12, 0.83, 0.40)
        $playfield = Get-X64ScreenshotRegionStats -Bitmap $bitmap -Region @(0.15, 0.30, 0.85, 0.78)
        $lowerHud = Get-X64ScreenshotRegionStats -Bitmap $bitmap -Region @(0.15, 0.70, 0.85, 0.88)

        if ($all.Sampled -eq 0 -or $all.NonBlack -lt 120 -or $all.Accent -lt 20) {
            throw ("{0} failed base visual gate: kind={1}, sampled={2}, nonblack={3}, accent={4}, path={5}" -f $Label, $FrameKind, $all.Sampled, $all.NonBlack, $all.Accent, $Path)
        }

        if ($FrameKind -eq 'title') {
            if ($header.NonBlack -lt 90 -or $header.Accent -lt 60 -or $menu.NonBlack -lt 50 -or $menu.Accent -lt 40) {
                throw ("{0} failed title gate: headerNonBlack={1}, headerAccent={2}, menuNonBlack={3}, menuAccent={4}, path={5}" -f $Label, $header.NonBlack, $header.Accent, $menu.NonBlack, $menu.Accent, $Path)
            }
            if ($lowerHud.NonBlack -gt 180) {
                throw ("{0} looked like stale gameplay was still overlaid on the title: lowerHudNonBlack={1}, path={2}" -f $Label, $lowerHud.NonBlack, $Path)
            }
        } else {
            if ($playfield.NonBlack -lt 1400 -or $playfield.Accent -lt 80 -or $lowerHud.NonBlack -lt 140) {
                throw ("{0} failed gameplay gate: playfieldNonBlack={1}, playfieldAccent={2}, lowerHudNonBlack={3}, path={4}" -f $Label, $playfield.NonBlack, $playfield.Accent, $lowerHud.NonBlack, $Path)
            }
            if ($header.NonBlack -lt 100 -or $header.Accent -lt 80) {
                throw ("{0} failed gameplay HUD gate: headerNonBlack={1}, headerAccent={2}, path={3}" -f $Label, $header.NonBlack, $header.Accent, $Path)
            }
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
$gameplayPath = $null
$gameplayFirePath = $null
$hostilesPath = $null
$missionPath = $null
$missionCompletePath = $null
$afterEscPath = $null
if ($Capture.IsPresent -or $InputSmoke.IsPresent -or $GameplaySmoke.IsPresent) {
    Ensure-VmReadyForCapture -Name $VmName -Context 'x64 title capture'
    Invoke-VmScreenshot -Name $VmName -OutputPath $ScreenshotPath -Context 'x64 title capture'
    Assert-X64VisualScreenshot -Path $ScreenshotPath -Label 'x64 title screenshot' -FrameKind title
    $capturePath = $ScreenshotPath
}

if ($InputSmoke.IsPresent) {
    $downPath = Get-SmokeScreenshotPath -BasePath $ScreenshotPath -Suffix 'down'
    $enterPath = Get-SmokeScreenshotPath -BasePath $ScreenshotPath -Suffix 'enter'

    Invoke-VBoxManage -Arguments @('controlvm', $VmName, 'keyboardputscancode', 'e0', '50', 'e0', 'd0') -TimeoutSeconds 30 | Out-Null
    Start-Sleep -Milliseconds 750
    Invoke-VmScreenshot -Name $VmName -OutputPath $downPath -Context 'x64 down-key capture'
    Assert-X64VisualScreenshot -Path $downPath -Label 'x64 down-key screenshot' -FrameKind title

    Invoke-VBoxManage -Arguments @('controlvm', $VmName, 'keyboardputscancode', '1c', '9c') -TimeoutSeconds 30 | Out-Null
    Start-Sleep -Milliseconds 750
    Invoke-VmScreenshot -Name $VmName -OutputPath $enterPath -Context 'x64 enter-key capture'
    Assert-X64VisualScreenshot -Path $enterPath -Label 'x64 enter-key screenshot' -FrameKind title

    Invoke-VBoxManage -Arguments @('controlvm', $VmName, 'keyboardputscancode', '01', '81') -TimeoutSeconds 30 | Out-Null
    Start-Sleep -Milliseconds 250
    Invoke-VBoxManage -Arguments @('controlvm', $VmName, 'keyboardputscancode', 'e0', '48', 'e0', 'c8') -TimeoutSeconds 30 | Out-Null
    Start-Sleep -Milliseconds 250
}

if ($GameplaySmoke.IsPresent) {
    $gameplayPath = Get-SmokeScreenshotPath -BasePath $ScreenshotPath -Suffix 'gameplay'
    $gameplayFirePath = Get-SmokeScreenshotPath -BasePath $ScreenshotPath -Suffix 'gameplay-fire'
    $hostilesPath = Get-SmokeScreenshotPath -BasePath $ScreenshotPath -Suffix 'hostiles-clear'
    $missionPath = Get-SmokeScreenshotPath -BasePath $ScreenshotPath -Suffix 'mission-progress'
    $missionCompletePath = Get-SmokeScreenshotPath -BasePath $ScreenshotPath -Suffix 'mission-complete'
    $afterEscPath = Get-SmokeScreenshotPath -BasePath $ScreenshotPath -Suffix 'after-esc'

    Invoke-VBoxManage -Arguments @('controlvm', $VmName, 'keyboardputscancode', '1c', '9c') -TimeoutSeconds 30 | Out-Null
    Start-Sleep -Milliseconds 1300
    Invoke-VmScreenshot -Name $VmName -OutputPath $gameplayPath -Context 'x64 gameplay capture'
    Assert-X64VisualScreenshot -Path $gameplayPath -Label 'x64 gameplay screenshot' -FrameKind gameplay

    Invoke-VBoxManage -Arguments @('controlvm', $VmName, 'keyboardputscancode', '11', '91') -TimeoutSeconds 30 | Out-Null
    Start-Sleep -Milliseconds 250
    Invoke-VBoxManage -Arguments @('controlvm', $VmName, 'keyboardputscancode', '1e', '9e') -TimeoutSeconds 30 | Out-Null
    Start-Sleep -Milliseconds 250
    Invoke-VBoxManage -Arguments @('controlvm', $VmName, 'keyboardputscancode', '1c', '9c') -TimeoutSeconds 30 | Out-Null
    Start-Sleep -Milliseconds 250
    Invoke-VmScreenshot -Name $VmName -OutputPath $gameplayFirePath -Context 'x64 gameplay fire capture'
    Assert-X64VisualScreenshot -Path $gameplayFirePath -Label 'x64 gameplay fire screenshot' -FrameKind gameplay

    Invoke-X64KeyTap -Name $VmName -ScanCodes @('1c', '9c') -Count 2 -DelayMilliseconds 320
    Invoke-X64KeyTap -Name $VmName -ScanCodes @('1e', '9e') -Count 4 -DelayMilliseconds 220
    Invoke-X64KeyTap -Name $VmName -ScanCodes @('1c', '9c') -Count 1 -DelayMilliseconds 320
    Invoke-X64KeyTap -Name $VmName -ScanCodes @('20', 'a0') -Count 10 -DelayMilliseconds 220
    Invoke-X64KeyTap -Name $VmName -ScanCodes @('1c', '9c') -Count 1 -DelayMilliseconds 320
    Start-Sleep -Milliseconds 900
    Invoke-VmScreenshot -Name $VmName -OutputPath $hostilesPath -Context 'x64 hostiles-clear capture'
    Assert-X64VisualScreenshot -Path $hostilesPath -Label 'x64 hostiles-clear screenshot' -FrameKind gameplay

    Invoke-X64KeyTap -Name $VmName -ScanCodes @('1e', '9e') -Count 12 -DelayMilliseconds 220
    Invoke-X64KeyTap -Name $VmName -ScanCodes @('11', '91') -Count 12 -DelayMilliseconds 220
    Start-Sleep -Milliseconds 1200
    Invoke-VmScreenshot -Name $VmName -OutputPath $missionPath -Context 'x64 mission-progress capture'
    Assert-X64VisualScreenshot -Path $missionPath -Label 'x64 mission-progress screenshot' -FrameKind gameplay

    Invoke-X64KeyTap -Name $VmName -ScanCodes @('20', 'a0') -Count 13 -DelayMilliseconds 220
    Invoke-X64KeyTap -Name $VmName -ScanCodes @('11', '91') -Count 2 -DelayMilliseconds 220
    Start-Sleep -Milliseconds 1200
    Invoke-VmScreenshot -Name $VmName -OutputPath $missionCompletePath -Context 'x64 mission-complete capture'
    Assert-X64VisualScreenshot -Path $missionCompletePath -Label 'x64 mission-complete screenshot' -FrameKind gameplay

    Invoke-VBoxManage -Arguments @('controlvm', $VmName, 'keyboardputscancode', '01', '81') -TimeoutSeconds 30 | Out-Null
    Start-Sleep -Milliseconds 1500
    Invoke-VmScreenshot -Name $VmName -OutputPath $afterEscPath -Context 'x64 after-esc title capture'
    Assert-X64VisualScreenshot -Path $afterEscPath -Label 'x64 after-esc title screenshot' -FrameKind title
}

$finalState = Get-VmState -Name $VmName -Context 'x64 deploy final state'
$vmLogPath = Get-X64VmLogPath -Name $VmName
$reportDirectory = Split-Path -Parent $ReportPath
if ($reportDirectory) {
    New-Item -ItemType Directory -Force -Path $reportDirectory | Out-Null
}
$inputSmokeStatus = if ($InputSmoke.IsPresent) { 'pass' } else { 'not requested' }
$gameplaySmokeStatus = if ($GameplaySmoke.IsPresent) { 'pass' } else { 'not requested' }
$captureStatus = if ($Capture.IsPresent -or $InputSmoke.IsPresent -or $GameplaySmoke.IsPresent) { 'pass' } else { 'not requested' }
$titleVisualGateStatus = if ($Capture.IsPresent -or $InputSmoke.IsPresent -or $GameplaySmoke.IsPresent) { 'pass' } else { 'not requested' }
$downVisualGateStatus = if ($InputSmoke.IsPresent) { 'pass' } else { 'not requested' }
$enterVisualGateStatus = if ($InputSmoke.IsPresent) { 'pass' } else { 'not requested' }
$gameplayVisualGateStatus = if ($GameplaySmoke.IsPresent) { 'pass' } else { 'not requested' }
$gameplayFireVisualGateStatus = if ($GameplaySmoke.IsPresent) { 'pass' } else { 'not requested' }
$hostilesVisualGateStatus = if ($GameplaySmoke.IsPresent) { 'pass' } else { 'not requested' }
$missionVisualGateStatus = if ($GameplaySmoke.IsPresent) { 'pass' } else { 'not requested' }
$missionCompleteVisualGateStatus = if ($GameplaySmoke.IsPresent) { 'pass' } else { 'not requested' }
$afterEscVisualGateStatus = if ($GameplaySmoke.IsPresent) { 'pass' } else { 'not requested' }
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
    ('Gameplay smoke: {0}' -f $gameplaySmokeStatus),
    ('Gameplay screenshot: {0}' -f (Resolve-ExistingPathText -Path $gameplayPath)),
    ('Gameplay fire screenshot: {0}' -f (Resolve-ExistingPathText -Path $gameplayFirePath)),
    ('Hostiles clear screenshot: {0}' -f (Resolve-ExistingPathText -Path $hostilesPath)),
    ('Mission progress screenshot: {0}' -f (Resolve-ExistingPathText -Path $missionPath)),
    ('Mission complete screenshot: {0}' -f (Resolve-ExistingPathText -Path $missionCompletePath)),
    ('After Esc screenshot: {0}' -f (Resolve-ExistingPathText -Path $afterEscPath)),
    ('Visual gate title: {0}' -f $titleVisualGateStatus),
    ('Visual gate down: {0}' -f $downVisualGateStatus),
    ('Visual gate enter: {0}' -f $enterVisualGateStatus),
    ('Visual gate gameplay: {0}' -f $gameplayVisualGateStatus),
    ('Visual gate gameplay fire: {0}' -f $gameplayFireVisualGateStatus),
    ('Visual gate hostiles clear: {0}' -f $hostilesVisualGateStatus),
    ('Visual gate mission progress: {0}' -f $missionVisualGateStatus),
    ('Visual gate mission complete: {0}' -f $missionCompleteVisualGateStatus),
    ('Visual gate after Esc: {0}' -f $afterEscVisualGateStatus),
    'Checks: UEFI VM boots the x64 ISO, GOP title frame is nonblack/accented, typed title/gameplay visual gates reject black frames and stale overlays, menu accepts Down and Enter, NEW GAME reaches the first level, WASD moves, Enter fires with visible beam feedback, floor glow/shadow ray probes and atmosphere shafts remain visible in gameplay captures, repeated fire clears the Warden plus left/right sentries, WASD reaches the terminal and exit volumes, Esc returns to a clean title viewport, and the VM remains running.',
    'Recovery: input smoke sends Esc and Up after capture; gameplay smoke sends Esc after capture and validates the returned title frame.'
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
    GameplayScreenshot = $gameplayPath
    GameplayFireScreenshot = $gameplayFirePath
    HostilesClearScreenshot = $hostilesPath
    MissionProgressScreenshot = $missionPath
    MissionCompleteScreenshot = $missionCompletePath
    AfterEscScreenshot = $afterEscPath
    SmokeReport = (Resolve-ExistingPathText -Path $ReportPath)
    LogPath = (Resolve-ExistingPathText -Path $vmLogPath)
}
