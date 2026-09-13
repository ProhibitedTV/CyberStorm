param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'

$deployPath = Join-Path $RepoRoot 'scripts\deploy-x64-vm.ps1'
if (-not (Test-Path -LiteralPath $deployPath)) {
    throw "Missing x64 VM deploy script: $deployPath"
}

$text = Get-Content -Raw -LiteralPath $deployPath
$hadCrLf = $text.Contains("`r`n")
$text = $text.Replace("`r`n", "`n")

$marker = '# TRACE response smoke: backtrack to the proven sentry firing positions.'
if ($text.Contains($marker)) {
    Write-Host 'x64 TRACE response smoke extension is already present.'
    exit 0
}

function Replace-ExactOnce {
    param(
        [string]$Name,
        [string]$Old,
        [string]$New
    )

    $first = $script:text.IndexOf($Old, [System.StringComparison]::Ordinal)
    if ($first -lt 0) {
        throw "Smoke patch anchor '$Name' was not found. deploy-x64-vm.ps1 has drifted; inspect before applying."
    }
    $second = $script:text.IndexOf($Old, $first + $Old.Length, [System.StringComparison]::Ordinal)
    if ($second -ge 0) {
        throw "Smoke patch anchor '$Name' is ambiguous; found more than once."
    }

    $script:text = $script:text.Substring(0, $first) + $New + $script:text.Substring($first + $Old.Length)
    Write-Host ("Prepared: {0}" -f $Name)
}

$pathVarsOld = @'
$hostilesPath = $null
$missionPath = $null
$missionCompletePath = $null
$afterEscPath = $null
'@
$pathVarsNew = @'
$hostilesPath = $null
$missionPath = $null
$traceClearPath = $null
$missionCompletePath = $null
$afterEscPath = $null
'@
Replace-ExactOnce -Name 'TRACE clear screenshot variable' -Old $pathVarsOld -New $pathVarsNew

$pathInitOld = @'
    $hostilesPath = Get-SmokeScreenshotPath -BasePath $ScreenshotPath -Suffix 'hostiles-clear'
    $missionPath = Get-SmokeScreenshotPath -BasePath $ScreenshotPath -Suffix 'mission-progress'
    $missionCompletePath = Get-SmokeScreenshotPath -BasePath $ScreenshotPath -Suffix 'mission-complete'
'@
$pathInitNew = @'
    $hostilesPath = Get-SmokeScreenshotPath -BasePath $ScreenshotPath -Suffix 'hostiles-clear'
    $missionPath = Get-SmokeScreenshotPath -BasePath $ScreenshotPath -Suffix 'mission-progress'
    $traceClearPath = Get-SmokeScreenshotPath -BasePath $ScreenshotPath -Suffix 'trace-clear'
    $missionCompletePath = Get-SmokeScreenshotPath -BasePath $ScreenshotPath -Suffix 'mission-complete'
'@
Replace-ExactOnce -Name 'TRACE clear screenshot path' -Old $pathInitOld -New $pathInitNew

$missionSequenceOld = @'
    Invoke-X64KeyTap -Name $VmName -ScanCodes @('1e', '9e') -Count 12 -DelayMilliseconds 220
    Invoke-X64KeyTap -Name $VmName -ScanCodes @('11', '91') -Count 12 -DelayMilliseconds 220
    Start-Sleep -Milliseconds 1200
    Invoke-X64GatedScreenshot -Name $VmName -OutputPath $missionPath -Context 'x64 mission-progress capture' -Label 'x64 mission-progress screenshot' -FrameKind gameplay

    Invoke-X64KeyTap -Name $VmName -ScanCodes @('20', 'a0') -Count 13 -DelayMilliseconds 220
    Invoke-X64KeyTap -Name $VmName -ScanCodes @('11', '91') -Count 2 -DelayMilliseconds 220
'@
$missionSequenceNew = @'
    Invoke-X64KeyTap -Name $VmName -ScanCodes @('1e', '9e') -Count 12 -DelayMilliseconds 220
    Invoke-X64KeyTap -Name $VmName -ScanCodes @('11', '91') -Count 12 -DelayMilliseconds 220
    Start-Sleep -Milliseconds 1200
    Invoke-X64GatedScreenshot -Name $VmName -OutputPath $missionPath -Context 'x64 TRACE response capture' -Label 'x64 TRACE response screenshot' -FrameKind gameplay

    # TRACE response smoke: backtrack to the proven sentry firing positions.
    # The original smoke already demonstrates that A4/fire and D10/fire clear
    # the left/right sentry slots. Reuse that path after the terminal reboots
    # those exact actors rather than introducing screenshot-only debug cheats.
    Invoke-X64KeyTap -Name $VmName -ScanCodes @('1f', '9f') -Count 12 -DelayMilliseconds 220
    Invoke-X64KeyTap -Name $VmName -ScanCodes @('20', 'a0') -Count 12 -DelayMilliseconds 220
    Invoke-X64KeyTap -Name $VmName -ScanCodes @('1e', '9e') -Count 4 -DelayMilliseconds 220
    Invoke-X64KeyTap -Name $VmName -ScanCodes @('1c', '9c') -Count 1 -DelayMilliseconds 320
    Invoke-X64KeyTap -Name $VmName -ScanCodes @('20', 'a0') -Count 10 -DelayMilliseconds 220
    Invoke-X64KeyTap -Name $VmName -ScanCodes @('1c', '9c') -Count 1 -DelayMilliseconds 320
    Start-Sleep -Milliseconds 900
    Invoke-X64GatedScreenshot -Name $VmName -OutputPath $traceClearPath -Context 'x64 TRACE clear capture' -Label 'x64 TRACE clear screenshot' -FrameKind gameplay

    # Return through the known terminal route, then take the existing extraction
    # movement. If the response gate is working, mission completion can only land
    # after the two rebooted sentries have been cleared above.
    Invoke-X64KeyTap -Name $VmName -ScanCodes @('1e', '9e') -Count 12 -DelayMilliseconds 220
    Invoke-X64KeyTap -Name $VmName -ScanCodes @('11', '91') -Count 12 -DelayMilliseconds 220
    Invoke-X64KeyTap -Name $VmName -ScanCodes @('20', 'a0') -Count 13 -DelayMilliseconds 220
    Invoke-X64KeyTap -Name $VmName -ScanCodes @('11', '91') -Count 2 -DelayMilliseconds 220
'@
Replace-ExactOnce -Name 'TRACE response gameplay sequence' -Old $missionSequenceOld -New $missionSequenceNew

$reportOld = @'
    ('Hostiles clear screenshot: {0}' -f (Resolve-ExistingPathText -Path $hostilesPath)),
    ('Mission progress screenshot: {0}' -f (Resolve-ExistingPathText -Path $missionPath)),
    ('Mission complete screenshot: {0}' -f (Resolve-ExistingPathText -Path $missionCompletePath)),
'@
$reportNew = @'
    ('Hostiles clear screenshot: {0}' -f (Resolve-ExistingPathText -Path $hostilesPath)),
    ('TRACE response screenshot: {0}' -f (Resolve-ExistingPathText -Path $missionPath)),
    ('TRACE clear screenshot: {0}' -f (Resolve-ExistingPathText -Path $traceClearPath)),
    ('Mission complete screenshot: {0}' -f (Resolve-ExistingPathText -Path $missionCompletePath)),
'@
Replace-ExactOnce -Name 'TRACE smoke report lines' -Old $reportOld -New $reportNew

$resultOld = @'
    HostilesClearScreenshot = $hostilesPath
    MissionProgressScreenshot = $missionPath
    MissionCompleteScreenshot = $missionCompletePath
'@
$resultNew = @'
    HostilesClearScreenshot = $hostilesPath
    MissionProgressScreenshot = $missionPath
    TraceResponseScreenshot = $missionPath
    TraceClearScreenshot = $traceClearPath
    MissionCompleteScreenshot = $missionCompletePath
'@
Replace-ExactOnce -Name 'TRACE smoke result paths' -Old $resultOld -New $resultNew

if (([regex]::Matches($text, [regex]::Escape($marker))).Count -ne 1) {
    throw 'Prepared smoke source does not contain exactly one TRACE response marker.'
}
if (-not $text.Contains("-Suffix 'trace-clear'")) {
    throw 'Prepared smoke source is missing the trace-clear capture path.'
}
if (-not $text.Contains('TraceClearScreenshot = $traceClearPath')) {
    throw 'Prepared smoke source is missing the trace-clear result property.'
}

if ($CheckOnly) {
    Write-Host 'TRACE response smoke anchors are valid. No files changed (-CheckOnly).'
    exit 0
}

if ($hadCrLf) {
    $text = $text.Replace("`n", "`r`n")
}
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($deployPath, $text, $utf8NoBom)
Write-Host "Patched $deployPath"
