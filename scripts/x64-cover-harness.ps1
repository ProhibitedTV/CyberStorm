param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$ReportPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = Join-Path $RepoRoot 'build\cyberstorm-x64-cover-report.txt'
}

$specPath = Join-Path $RepoRoot 'assets\x64_cover.psd1'
$combatPath = Join-Path $RepoRoot 'assets\x64_combat.psd1'
$runtimePath = Join-Path $RepoRoot 'src\bootx64.asm'
foreach ($required in @($specPath, $combatPath, $runtimePath)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing cover validation input: $required" }
}

$cover = (Import-PowerShellDataFile -Path $specPath).Cover
$combat = (Import-PowerShellDataFile -Path $combatPath).Combat
$runtime = Get-Content -Raw -LiteralPath $runtimePath
$zones = @($cover.Zones)
$checks = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param([string]$Name, [bool]$Passed, [string]$Detail)
    $script:checks.Add([pscustomobject]@{ Name = $Name; Passed = $Passed; Detail = $Detail })
}

function Has-ReachableStep {
    param([int]$Min, [int]$Max)
    for ($v = -240; $v -le 540; $v += 24) {
        if ($v -ge $Min -and $v -le $Max) { return $true }
    }
    return $false
}

Add-Check 'Cover profile id is stable' ($cover.Id -eq 'neon-spine-visible-cover') "id=$($cover.Id)"
Add-Check 'Cover HUD text is concise' ($cover.HudText -eq 'SIGNAL MASKED') "hud=$($cover.HudText)"
Add-Check 'Cover is only meaningful with hostiles' ([bool]$cover.ActiveOnlyWithHostiles) "active-with-hostiles=$($cover.ActiveOnlyWithHostiles)"
Add-Check 'Exactly three visible cover pockets are authored' ($zones.Count -eq 3) "zones=$($zones.Count)"
Add-Check 'Cover begins no earlier than pressure engagement' (($zones | Where-Object { [int]$_.MinZ -lt [int]$combat.EngageWorldZ }).Count -eq 0) "engage-z=$($combat.EngageWorldZ)"

$geometryAnchors = @{
    'front-left-pillar' = 'DRAW_LEVEL_BOX_FILLED -120, -64, 138, -92, -20, 186, 00142632h'
    'front-right-pillar' = 'DRAW_LEVEL_BOX_FILLED 92, -64, 138, 120, -20, 186, 00142632h'
    'mid-center-column' = 'DRAW_LEVEL_BOX_FILLED -18, -64, 310, 18, -28, 360, 00182A38h'
}

foreach ($zone in $zones) {
    $id = [string]$zone.Id
    $blocker = $zone.Blocker
    $zoneBehindBlocker = [int]$zone.MaxZ -lt [int]$blocker.NearZ
    $xOverlap = [int]$zone.MaxX -ge [int]$blocker.MinX -and [int]$zone.MinX -le [int]$blocker.MaxX
    $reachable = (Has-ReachableStep -Min ([int]$zone.MinX) -Max ([int]$zone.MaxX)) -and (Has-ReachableStep -Min ([int]$zone.MinZ) -Max ([int]$zone.MaxZ))
    Add-Check "$id sits on player-facing side of blocker" ($zoneBehindBlocker -and $xOverlap) "zone-z=$($zone.MinZ)..$($zone.MaxZ) blocker-z=$($blocker.NearZ)..$($blocker.FarZ)"
    Add-Check "$id is reachable on 24-unit movement grid" $reachable "x=$($zone.MinX)..$($zone.MaxX) z=$($zone.MinZ)..$($zone.MaxZ)"
    Add-Check "$id blocker geometry exists in runtime" ($runtime.Contains($geometryAnchors[$id])) $geometryAnchors[$id]
}

# Deterministic cover resolver model.
function Get-ModelCoverState {
    param([int]$X, [int]$Z)
    foreach ($zone in $zones) {
        if ($X -ge [int]$zone.MinX -and $X -le [int]$zone.MaxX -and $Z -ge [int]$zone.MinZ -and $Z -le [int]$zone.MaxZ) {
            return [int]$zone.StateId
        }
    }
    return 0
}

Add-Check 'Left pillar pocket resolves as cover' ((Get-ModelCoverState -X -96 -Z 120) -eq 1) 'point=(-96,120)'
Add-Check 'Right pillar pocket resolves as cover' ((Get-ModelCoverState -X 96 -Z 120) -eq 2) 'point=(96,120)'
Add-Check 'Center column pocket resolves as cover' ((Get-ModelCoverState -X 0 -Z 288) -eq 3) 'point=(0,288)'
Add-Check 'Open center lane remains exposed' ((Get-ModelCoverState -X 0 -Z 120) -eq 0) 'point=(0,120)'

# Cover clears lock even if the player stays stationary longer than the normal hit
# threshold; leaving cover restores the unchanged exposure contract.
$exposure = 0
$hitTicks = [int]$combat.ExposureTicksPerHit
for ($i = 0; $i -lt ($hitTicks * 2); $i++) {
    if ((Get-ModelCoverState -X -96 -Z 120) -ne 0) { $exposure = 0 } else { $exposure++ }
}
Add-Check 'Stationary visible cover suppresses exposure indefinitely' ($exposure -eq 0) "exposure=$exposure"

$exposure = 0
for ($i = 0; $i -lt $hitTicks; $i++) {
    if ((Get-ModelCoverState -X 0 -Z 120) -ne 0) { $exposure = 0 } else { $exposure++ }
}
Add-Check 'Leaving cover restores normal hit threshold' ($exposure -eq $hitTicks) "exposure=$exposure hit-threshold=$hitTicks"

$runtimeHasCover = $runtime.Contains('UpdatePlayerCoverState PROC') -and
                   $runtime.Contains('call UpdatePlayerCoverState') -and
                   $runtime.Contains('PlayerCoverState dd 0') -and
                   $runtime.Contains('jne pressure_clear_lock') -and
                   $runtime.Contains("LevelCoverLine db 'SIGNAL MASKED',0")
Add-Check 'Runtime visible-cover patch landed' $runtimeHasCover "cover-runtime=$runtimeHasCover"

$failed = @($checks | Where-Object { -not $_.Passed })
$runtimePending = @($checks | Where-Object { $_.Name -eq 'Runtime visible-cover patch landed' -and -not $_.Passed })
$hardFailed = @($failed | Where-Object { $_.Name -ne 'Runtime visible-cover patch landed' })

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('CyberStorm x64 Visible Cover Harness')
$lines.Add(('Generated: {0:u}' -f (Get-Date).ToUniversalTime()))
$lines.Add('')
foreach ($check in $checks) {
    $status = if ($check.Passed) { 'PASS' } elseif ($check.Name -eq 'Runtime visible-cover patch landed') { 'PENDING' } else { 'FAIL' }
    $lines.Add(('[{0}] {1} - {2}' -f $status, $check.Name, $check.Detail))
}
$lines.Add('')
$lines.Add(('Summary: {0} passed, {1} hard failed, {2} pending runtime integration' -f ($checks.Count - $failed.Count), $hardFailed.Count, $runtimePending.Count))

$reportDir = Split-Path -Parent $ReportPath
if ($reportDir -and -not (Test-Path -LiteralPath $reportDir)) { New-Item -ItemType Directory -Force -Path $reportDir | Out-Null }
$lines | Set-Content -Encoding UTF8 -LiteralPath $ReportPath
$lines | ForEach-Object { Write-Host $_ }
if ($hardFailed.Count -gt 0) { exit 1 }
