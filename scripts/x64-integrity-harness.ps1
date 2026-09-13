param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$ReportPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = Join-Path $RepoRoot 'build\cyberstorm-x64-integrity-report.txt'
}

$specPath = Join-Path $RepoRoot 'assets\x64_combat.psd1'
$runtimePath = Join-Path $RepoRoot 'src\bootx64.asm'
foreach ($requiredPath in @($specPath, $runtimePath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Missing required file: $requiredPath"
    }
}

$spec = Import-PowerShellDataFile -Path $specPath
$combat = $spec.Combat
$rank = $combat.Rank
$runtime = Get-Content -Raw -LiteralPath $runtimePath
$checks = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param([string]$Name, [bool]$Passed, [string]$Detail)
    $script:checks.Add([pscustomobject]@{ Name = $Name; Passed = $Passed; Detail = $Detail })
}

function Runtime-HasAll {
    param([string[]]$Needles)
    foreach ($needle in $Needles) {
        if (-not $runtime.Contains($needle)) { return $false }
    }
    return $true
}

$tickUsec = [int]$combat.TickUsec
$integrityMax = [int]$combat.IntegrityMax
$engageZ = [int]$combat.EngageWorldZ
$initialGrace = [int]$combat.InitialGraceTicks
$moveGrace = [int]$combat.MoveGraceTicks
$exposureHit = [int]$combat.ExposureTicksPerHit
$warningTicks = [int]$combat.ExposureWarningTicks
$damageCooldown = [int]$combat.DamageCooldownTicks
$damageFlash = [int]$combat.DamageFlashTicks
$rebootTicks = [int]$combat.RebootNoticeTicks
$rankAIntegrity = [int]$rank.ARequiresIntegrity
$rankAMaxShotsPerHit = [int]$rank.AMaxShotsPerHit
$rankBIntegrity = [int]$rank.BRequiresIntegrity
$rankBMaxShotsPerHit = [int]$rank.BMaxShotsPerHit
$rankDefault = [string]$rank.DefaultRank

Add-Check 'Combat profile is Neon Spine integrity' ($combat.Id -eq 'neon-spine-integrity') "id=$($combat.Id)"
Add-Check 'Runtime input cadence matches combat spec' ($runtime.Contains("INPUT_POLL_STALL_USEC         equ $tickUsec")) "tick-usec=$tickUsec"
Add-Check 'Existing movement is discrete and detectable' (Runtime-HasAll @('game_move_up:', 'game_move_down:', 'game_move_left:', 'game_move_right:', 'add eax, 24', 'sub eax, 24')) 'movement uses existing 24-unit world steps'
Add-Check 'Existing hostile actor state is available' (Runtime-HasAll @('EnemyAlive dd', 'SentryLeftAlive dd', 'SentryRightAlive dd')) 'warden and both sentry alive flags found'
Add-Check 'Mission restart seam exists' (Runtime-HasAll @('StartFirstLevel PROC', 'mov dword ptr [ObjectiveState], 0', 'StartFirstLevel ENDP')) 'zero integrity can reuse the existing level reset path'

Add-Check 'Integrity is intentionally compact' ($integrityMax -eq 3) "integrity-max=$integrityMax"
Add-Check 'Engagement starts after the spawn pocket' ($engageZ -ge 72 -and $engageZ -le 144) "engage-z=$engageZ"
Add-Check 'Initial grace protects boot-in play' ($initialGrace -ge 180 -and $initialGrace -le 400) ('ticks={0} ms={1}' -f $initialGrace, ($initialGrace * $tickUsec / 1000))
Add-Check 'Movement grace is responsive, not permanent' ($moveGrace -ge 25 -and $moveGrace -le 70) ('ticks={0} ms={1}' -f $moveGrace, ($moveGrace * $tickUsec / 1000))
Add-Check 'Exposure warning precedes damage' ($warningTicks -gt 0 -and $warningTicks -lt $exposureHit) "warn=$warningTicks hit=$exposureHit"
Add-Check 'Stationary exposure window is readable' ($exposureHit -ge 70 -and $exposureHit -le 140) ('ticks={0} ms={1}' -f $exposureHit, ($exposureHit * $tickUsec / 1000))
Add-Check 'Damage cooldown prevents burst deletion' ($damageCooldown -ge 70 -and $damageCooldown -le 180) ('ticks={0} ms={1}' -f $damageCooldown, ($damageCooldown * $tickUsec / 1000))
Add-Check 'Feedback timers are bounded' ($damageFlash -ge 12 -and $damageFlash -le 50 -and $rebootTicks -ge 60 -and $rebootTicks -le 180) "damage-flash=$damageFlash reboot=$rebootTicks"
Add-Check 'Failure restarts the level' ($combat.FailAction -eq 'restart-level') "fail-action=$($combat.FailAction)"

# The existing VM response smoke pauses roughly 1.2 seconds after its final
# movement into the terminal beat. Keep grace + exposure above that so the smoke
# tests the encounter rather than accidentally becoming a damage-timing test.
$smokePauseTicks = [int][Math]::Ceiling(1200000 / $tickUsec)
Add-Check 'Current TRACE smoke pause stays below first damage window' (($moveGrace + $exposureHit) -gt $smokePauseTicks) "grace+exposure=$($moveGrace + $exposureHit) smoke-pause=$smokePauseTicks"

# Rank tuning is intentionally simple enough to compute without division.
Add-Check 'Mission rank defaults are ordered' ([bool]$rank.SRequiresFullIntegrity -and [bool]$rank.SRequiresPerfectAccuracy -and $rankAIntegrity -eq $integrityMax -and $rankAMaxShotsPerHit -eq 2 -and $rankBIntegrity -eq 2 -and $rankBMaxShotsPerHit -eq 3 -and $rankDefault -eq 'C') "S=perfect/full A=int$rankAIntegrity <=${rankAMaxShotsPerHit}x B=int$rankBIntegrity <=${rankBMaxShotsPerHit}x default=$rankDefault"

function Get-MissionRank {
    param([int]$Integrity, [int]$Shots, [int]$Hits)

    if ($Shots -gt 0 -and $Integrity -eq $integrityMax -and $Shots -eq $Hits) {
        return 'S'
    }
    if ($Integrity -ge $rankAIntegrity -and ($Hits * $rankAMaxShotsPerHit) -ge $Shots) {
        return 'A'
    }
    if ($Integrity -ge $rankBIntegrity -and ($Hits * $rankBMaxShotsPerHit) -ge $Shots) {
        return 'B'
    }
    return $rankDefault
}

Add-Check 'Perfect clean run earns S' ((Get-MissionRank -Integrity 3 -Shots 7 -Hits 7) -eq 'S') 'integrity=3 shots=7 hits=7'
Add-Check 'Clean >=50% run earns A' ((Get-MissionRank -Integrity 3 -Shots 10 -Hits 6) -eq 'A') 'integrity=3 shots=10 hits=6'
Add-Check 'Damaged >=33% run earns B' ((Get-MissionRank -Integrity 2 -Shots 18 -Hits 7) -eq 'B') 'integrity=2 shots=18 hits=7'
Add-Check 'Sloppy low-integrity run earns C' ((Get-MissionRank -Integrity 1 -Shots 30 -Hits 7) -eq 'C') 'integrity=1 shots=30 hits=7'

# Deterministic pressure model. This mirrors the intended runtime patch:
# movement clears exposure, grace blocks accumulation, no hostiles means no lock,
# and sustained stationary exposure costs exactly one integrity at a time.
$integrity = $integrityMax
$exposure = 0
$grace = $initialGrace
$cooldown = 0
$playerZ = 0
$hostiles = 3
$restarts = 0

function Step-PressureModel {
    param([bool]$Moved)

    if ($Moved) {
        $script:exposure = 0
        $script:grace = $moveGrace
        return
    }
    if ($script:cooldown -gt 0) {
        $script:cooldown--
        $script:exposure = 0
        return
    }
    if ($script:grace -gt 0) {
        $script:grace--
        $script:exposure = 0
        return
    }
    if ($script:playerZ -lt $engageZ -or $script:hostiles -le 0) {
        $script:exposure = 0
        return
    }

    $script:exposure++
    if ($script:exposure -lt $exposureHit) { return }

    $script:exposure = 0
    $script:cooldown = $damageCooldown
    $script:integrity--
    if ($script:integrity -le 0) {
        $script:restarts++
        $script:integrity = $integrityMax
        $script:exposure = 0
        $script:grace = $initialGrace
        $script:cooldown = 0
        $script:playerZ = 0
        $script:hostiles = 3
    }
}

# Spawn pocket never hurts the player.
$grace = 0
for ($i = 0; $i -lt ($exposureHit * 2); $i++) { Step-PressureModel -Moved:$false }
Add-Check 'Spawn pocket is pressure-safe' ($integrity -eq $integrityMax -and $exposure -eq 0) "integrity=$integrity exposure=$exposure"

# Move into combat, then stand still long enough to take exactly one hit.
$playerZ = $engageZ
Step-PressureModel -Moved:$true
for ($i = 0; $i -lt $moveGrace; $i++) { Step-PressureModel -Moved:$false }
for ($i = 0; $i -lt $exposureHit; $i++) { Step-PressureModel -Moved:$false }
Add-Check 'Standing exposed costs one integrity' ($integrity -eq ($integrityMax - 1) -and $cooldown -eq $damageCooldown) "integrity=$integrity cooldown=$cooldown"

# Movement during a partial lock clears it and refreshes grace.
$cooldown = 0
$grace = 0
$exposure = [Math]::Max(1, $warningTicks)
Step-PressureModel -Moved:$true
Add-Check 'Movement breaks hostile lock' ($exposure -eq 0 -and $grace -eq $moveGrace) "exposure=$exposure grace=$grace"

# No live actors means no pressure even deep in the level.
$hostiles = 0
$grace = 0
$exposure = $warningTicks
for ($i = 0; $i -lt ($exposureHit + 10); $i++) { Step-PressureModel -Moved:$false }
Add-Check 'Clearing hostiles removes pressure' ($exposure -eq 0) "exposure=$exposure"

# Three deliberate hits should use the existing restart path.
$hostiles = 1
$playerZ = $engageZ
$integrity = $integrityMax
$restarts = 0
$grace = 0
$cooldown = 0
for ($hit = 0; $hit -lt $integrityMax; $hit++) {
    $playerZ = $engageZ
    $hostiles = 1
    $grace = 0
    $cooldown = 0
    for ($i = 0; $i -lt $exposureHit; $i++) { Step-PressureModel -Moved:$false }
}
Add-Check 'Zero integrity restarts exactly once' ($restarts -eq 1 -and $integrity -eq $integrityMax -and $playerZ -eq 0) "restarts=$restarts integrity=$integrity playerZ=$playerZ"

$runtimeHasPressure = Runtime-HasAll @(
    'UpdateHostilePressure PROC',
    'call UpdateHostilePressure',
    'PlayerIntegrity dd',
    'ExposureTicks dd',
    "LevelStatusLine db 'SHOTS 0000 HITS 0000 INT 3',0",
    'LevelPressureLine db',
    "LevelRankLine db 'RANK C',0",
    'format_rank_a_check:',
    'format_rank_b_check:',
    'DrawIntegrityThreat PROC'
)
Add-Check 'Runtime integrity/rank patch landed' $runtimeHasPressure "pressure-rank-runtime=$runtimeHasPressure"

$failed = @($checks | Where-Object { -not $_.Passed })
$runtimePending = @($checks | Where-Object { $_.Name -eq 'Runtime integrity/rank patch landed' -and -not $_.Passed })
$hardFailed = @($failed | Where-Object { $_.Name -ne 'Runtime integrity/rank patch landed' })

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('CyberStorm x64 Integrity Pressure + Mission Rank Harness')
$lines.Add(('Generated: {0:u}' -f (Get-Date).ToUniversalTime()))
$lines.Add('')
foreach ($check in $checks) {
    $status = if ($check.Passed) { 'PASS' } elseif ($check.Name -eq 'Runtime integrity/rank patch landed') { 'PENDING' } else { 'FAIL' }
    $lines.Add(('[{0}] {1} - {2}' -f $status, $check.Name, $check.Detail))
}
$lines.Add('')
$lines.Add(('Summary: {0} passed, {1} hard failed, {2} pending runtime integration' -f ($checks.Count - $failed.Count), $hardFailed.Count, $runtimePending.Count))

$reportDir = Split-Path -Parent $ReportPath
if ($reportDir -and -not (Test-Path -LiteralPath $reportDir)) {
    New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
}
$lines | Set-Content -Encoding UTF8 -LiteralPath $ReportPath
$lines | ForEach-Object { Write-Host $_ }

if ($hardFailed.Count -gt 0) { exit 1 }
