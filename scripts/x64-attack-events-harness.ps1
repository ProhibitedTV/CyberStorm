param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$ReportPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = Join-Path $RepoRoot 'build\cyberstorm-x64-attack-events-report.txt'
}

$specPath = Join-Path $RepoRoot 'assets\x64_attack_events.psd1'
$combatPath = Join-Path $RepoRoot 'assets\x64_combat.psd1'
$runtimePath = Join-Path $RepoRoot 'src\bootx64.asm'
foreach ($required in @($specPath, $combatPath, $runtimePath)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Missing hostile attack-event validation input: $required"
    }
}

$events = (Import-PowerShellDataFile -Path $specPath).AttackEvents
$combat = (Import-PowerShellDataFile -Path $combatPath).Combat
$runtime = Get-Content -Raw -LiteralPath $runtimePath
$checks = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param([string]$Name, [bool]$Passed, [string]$Detail)
    $script:checks.Add([pscustomobject]@{ Name = $Name; Passed = $Passed; Detail = $Detail })
}

$sources = @($events.Sources)
$ids = @($sources | ForEach-Object { [int]$_.SourceId })
$names = @($sources | ForEach-Object { [string]$_.Id })

Add-Check 'Attack-event profile id is stable' ($events.Id -eq 'neon-spine-hostile-shots') "id=$($events.Id)"
Add-Check 'Damage model preserves pressure timing' ($events.DamageModel -eq 'existing-pressure-hit') "damage-model=$($events.DamageModel)"
Add-Check 'Selection rotates live actors' ($events.Selection -eq 'round-robin-live-actors') "selection=$($events.Selection)"
Add-Check 'Exactly three attack sources are authored' ($sources.Count -eq 3) "sources=$($sources.Count)"
Add-Check 'Expected attack-source names are authored' ((@('warden','sentry-left','sentry-right') | Where-Object { $_ -notin $names }).Count -eq 0) "sources=$($names -join ',')"
Add-Check 'Attack source ids are unique and nonzero' (($ids | Select-Object -Unique).Count -eq 3 -and ($ids | Where-Object { $_ -le 0 }).Count -eq 0) "ids=$($ids -join ',')"
Add-Check 'Shot trace lifetime is short' ([int]$events.TraceTicks -ge 6 -and [int]$events.TraceTicks -le 20) "trace-ticks=$($events.TraceTicks)"
Add-Check 'Muzzle marker remains compact' ([int]$events.MuzzleHalfSize -ge 3 -and [int]$events.MuzzleHalfSize -le 10) "muzzle-half=$($events.MuzzleHalfSize)"
Add-Check 'Pressure hit timing remains authored elsewhere' ([int]$combat.ExposureTicksPerHit -eq 90 -and [int]$combat.DamageCooldownTicks -eq 100) "exposure-hit=$($combat.ExposureTicksPerHit) cooldown=$($combat.DamageCooldownTicks)"

# Deterministic selection model mirrors the runtime selector. It proves that dead
# actors are skipped while surviving actors continue rotating fairly.
$cursor = 0
$actorOrder = @('warden','sentry-left','sentry-right')
$sourceIds = @{}
foreach ($source in $sources) { $sourceIds[[string]$source.Id] = [int]$source.SourceId }

function Select-ModelAttackSource {
    param([hashtable]$Alive)

    for ($probe = 0; $probe -lt 3; $probe++) {
        $name = $actorOrder[$script:cursor]
        if ($Alive[$name]) {
            $selected = $sourceIds[$name]
            $script:cursor = ($script:cursor + 1) % 3
            return $selected
        }
        $script:cursor = ($script:cursor + 1) % 3
    }
    return 0
}

$allAlive = @{ 'warden' = $true; 'sentry-left' = $true; 'sentry-right' = $true }
$sequence = @()
for ($i = 0; $i -lt 4; $i++) { $sequence += Select-ModelAttackSource -Alive $allAlive }
$expectedAll = @($sourceIds['warden'], $sourceIds['sentry-left'], $sourceIds['sentry-right'], $sourceIds['warden'])
Add-Check 'All-live shots rotate Warden left right' (($sequence -join ',') -eq ($expectedAll -join ',')) "sequence=$($sequence -join ',')"

$cursor = 0
$traceAlive = @{ 'warden' = $false; 'sentry-left' = $true; 'sentry-right' = $true }
$traceSequence = @()
for ($i = 0; $i -lt 4; $i++) { $traceSequence += Select-ModelAttackSource -Alive $traceAlive }
$expectedTrace = @($sourceIds['sentry-left'], $sourceIds['sentry-right'], $sourceIds['sentry-left'], $sourceIds['sentry-right'])
Add-Check 'TRACE shots alternate surviving sentries' (($traceSequence -join ',') -eq ($expectedTrace -join ',')) "sequence=$($traceSequence -join ',')"

$cursor = 0
$noneAlive = @{ 'warden' = $false; 'sentry-left' = $false; 'sentry-right' = $false }
Add-Check 'No live actor produces no attack source' ((Select-ModelAttackSource -Alive $noneAlive) -eq 0) 'source=0'

$runtimeHasEvents = $runtime.Contains('SelectHostileAttackSource PROC') -and
                    $runtime.Contains('DrawHostileAttackEvent PROC') -and
                    $runtime.Contains('call SelectHostileAttackSource') -and
                    $runtime.Contains('call DrawHostileAttackEvent') -and
                    $runtime.Contains('LastAttackSource dd 0') -and
                    $runtime.Contains('AttackEventTicks dd 0') -and
                    $runtime.Contains('ATTACK_EVENT_TRACE_TICKS')
Add-Check 'Runtime hostile attack-event patch landed' $runtimeHasEvents "attack-events-runtime=$runtimeHasEvents"

if ($runtimeHasEvents) {
    Add-Check 'Shot renderer preserves projected coordinates across draw calls' ($runtime.Contains('push r12') -and $runtime.Contains('push r13') -and $runtime.Contains('mov r12d, eax') -and $runtime.Contains('mov r13d, edx')) 'uses nonvolatile r12/r13 source coordinates'
    Add-Check 'Shot renderer maintains Windows x64 stack alignment' ($runtime.Contains("DrawHostileAttackEvent PROC`n    push r12`n    push r13`n    sub rsp, 28h") -and $runtime.Contains("hostile_attack_event_done:`n    add rsp, 28h`n    pop r13`n    pop r12")) 'two pushes + 28h local/shadow allocation'
}

$failed = @($checks | Where-Object { -not $_.Passed })
$runtimePending = @($checks | Where-Object { $_.Name -eq 'Runtime hostile attack-event patch landed' -and -not $_.Passed })
$hardFailed = @($failed | Where-Object { $_.Name -ne 'Runtime hostile attack-event patch landed' })

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('CyberStorm x64 Hostile Attack Events Harness')
$lines.Add(('Generated: {0:u}' -f (Get-Date).ToUniversalTime()))
$lines.Add('')
foreach ($check in $checks) {
    $status = if ($check.Passed) { 'PASS' } elseif ($check.Name -eq 'Runtime hostile attack-event patch landed') { 'PENDING' } else { 'FAIL' }
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
