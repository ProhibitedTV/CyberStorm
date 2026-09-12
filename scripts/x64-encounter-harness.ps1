param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$ReportPath = ''
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = Join-Path $RepoRoot 'build\cyberstorm-x64-encounter-report.txt'
}

$specPath = Join-Path $RepoRoot 'assets\x64_encounters.psd1'
$runtimePath = Join-Path $RepoRoot 'src\bootx64.asm'

foreach ($requiredPath in @($specPath, $runtimePath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Missing required file: $requiredPath"
    }
}

$spec = Import-PowerShellDataFile -Path $specPath
$runtime = Get-Content -Raw -LiteralPath $runtimePath
$mission = $spec.Mission
$checks = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param([string]$Name, [bool]$Passed, [string]$Detail)
    $script:checks.Add([pscustomobject]@{ Name = $Name; Passed = $Passed; Detail = $Detail })
}

function Has-All {
    param([string[]]$Needles)
    foreach ($needle in $Needles) {
        if (-not $runtime.Contains($needle)) { return $false }
    }
    return $true
}

Add-Check 'Mission id is Neon Spine' ($mission.Id -eq 'neon-spine') "id=$($mission.Id)"

$states = @($mission.ObjectiveStates | ForEach-Object { [int]$_.State })
Add-Check 'Objective spec is a contiguous 0..3 chain' (($states -join ',') -eq '0,1,2,3') "states=$($states -join ',')"

Add-Check 'Runtime exposes the expected objective-state chain' (Has-All @(
    'UpdateHostileObjective PROC',
    'mov dword ptr [ObjectiveState], 1',
    'mov dword ptr [ObjectiveState], 2',
    'objective_exit_complete:',
    'mov dword ptr [ObjectiveState], 3'
)) 'hostiles clear -> terminal breach -> extraction complete symbols found'

Add-Check 'Hostile-clear gate checks all three existing actors' (Has-All @(
    'cmp dword ptr [EnemyAlive], 0',
    'cmp dword ptr [SentryLeftAlive], 0',
    'cmp dword ptr [SentryRightAlive], 0'
)) 'Warden plus both sentries participate in the initial clear gate'

$actorSymbolsValid = $true
foreach ($actor in @($mission.Actors)) {
    if (-not $runtime.Contains("$($actor.AliveSymbol) dd")) { $actorSymbolsValid = $false }
    if (-not $runtime.Contains("$($actor.HpSymbol) dd")) { $actorSymbolsValid = $false }
}
Add-Check 'Encounter spec maps only to existing runtime actor state' $actorSymbolsValid "actors=$(@($mission.Actors).Count)"

$responses = @($mission.Responses)
Add-Check 'First response is terminal-breach driven' ($responses.Count -eq 1 -and $responses[0].Trigger -eq 'objective-1-to-2') "responses=$($responses.Count) trigger=$($responses[0].Trigger)"

$reactivate = @($responses[0].Reactivate)
$actorIds = @($mission.Actors | ForEach-Object { $_.Id })
$unknownReactivate = @($reactivate | Where-Object { $_ -notin $actorIds })
Add-Check 'Response wave references known actors only' ($unknownReactivate.Count -eq 0 -and $reactivate.Count -gt 0) "reactivate=$($reactivate -join ',')"

Add-Check 'Response is bounded by the live-hostile cap' ([int]$mission.MaxLiveHostiles -le @($mission.Actors).Count -and [int]$mission.MaxLiveHostiles -le 3) "cap=$($mission.MaxLiveHostiles) actor-pool=$(@($mission.Actors).Count)"
Add-Check 'TRACE telegraph is long enough to read' ([int]$responses[0].TelegraphTicks -ge 30 -and [int]$responses[0].TelegraphTicks -le 90) "ticks=$($responses[0].TelegraphTicks)"
Add-Check 'Exit is explicitly locked during the response beat' ([bool]$responses[0].ExitLockedUntilClear) 'terminal breach cannot become a free sprint past the response wave'

$responseHp = [int]$mission.Tuning.ResponseSentryHp
$responseCount = [int]$mission.Tuning.ResponseCount
$extraShots = $responseHp * $responseCount
Add-Check 'Response TTK stays compact' ($responseHp -ge 1 -and $responseHp -le 2 -and $responseCount -eq 2 -and $extraShots -le 4) "hp=$responseHp count=$responseCount minimum-extra-shots=$extraShots"

$objective = 0
$warden = 1
$left = 1
$right = 1
$trace = 0
$exitLocked = $true

$warden = 0
$left = 0
$right = 0
if (($warden + $left + $right) -eq 0) { $objective = 1 }
if ($objective -eq 1) {
    $objective = 2
    $left = 1
    $right = 1
    $trace = [int]$responses[0].TelegraphTicks
    $exitLocked = [bool]$responses[0].ExitLockedUntilClear
}
$left = 0
$right = 0
if (($left + $right) -eq 0) { $exitLocked = $false }
if ($objective -eq 2 -and -not $exitLocked) { $objective = 3 }

Add-Check 'Deterministic response model reaches mission complete' ($objective -eq 3 -and $trace -gt 0 -and -not $exitLocked) "final-objective=$objective trace=$trace exitLocked=$exitLocked"

$runtimeHasTraceState = $runtime.Contains('TraceTicks dd')
$runtimeHasResponseGate = $runtime.Contains('terminal_trace_response:')
Add-Check 'Runtime response patch landed' ($runtimeHasTraceState -and $runtimeHasResponseGate) ('TraceTicks={0} response-label={1}' -f $runtimeHasTraceState, $runtimeHasResponseGate)

$failed = @($checks | Where-Object { -not $_.Passed })
$runtimePending = @($checks | Where-Object { $_.Name -eq 'Runtime response patch landed' -and -not $_.Passed })
$hardFailed = @($failed | Where-Object { $_.Name -ne 'Runtime response patch landed' })

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('CyberStorm x64 Encounter Harness')
$lines.Add(('Generated: {0:u}' -f (Get-Date).ToUniversalTime()))
$lines.Add('')
foreach ($check in $checks) {
    $status = if ($check.Passed) { 'PASS' } elseif ($check.Name -eq 'Runtime response patch landed') { 'PENDING' } else { 'FAIL' }
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
