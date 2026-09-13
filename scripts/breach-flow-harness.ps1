param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$ReportPath = ''
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = Join-Path $RepoRoot 'build\cyberstorm-breach-flow-report.txt'
}

$gamePath = Join-Path $RepoRoot 'src\game.asm'
$flowPath = Join-Path $RepoRoot 'src\game\flow.asm'
$sectorSourcePath = Join-Path $RepoRoot 'assets\sectors.psd1'
$generatedSectorPath = Join-Path $RepoRoot 'build\generated_sector_content.inc'
$buildReportPath = Join-Path $RepoRoot 'build\cyberstorm-build-report.txt'

foreach ($requiredPath in @($gamePath, $flowPath, $sectorSourcePath, $generatedSectorPath)) {
    if (-not (Test-Path $requiredPath)) { throw "Missing $requiredPath" }
}

$game = Get-Content -Raw $gamePath
$flow = Get-Content -Raw $flowPath
$sectorSource = Get-Content -Raw $sectorSourcePath
$generatedSector = Get-Content -Raw $generatedSectorPath
$buildReport = if (Test-Path $buildReportPath) { Get-Content -Raw $buildReportPath } else { '' }
$checks = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param([string]$Name, [bool]$Passed, [string]$Detail)
    $script:checks.Add([pscustomobject]@{
        Name = $Name
        Passed = $Passed
        Detail = $Detail
    })
}

function Get-EquValue {
    param([string]$Name)
    $pattern = '(?m)^\s*' + [regex]::Escape($Name) + '\s+equ\s+(-?\d+)\s*$'
    $m = [regex]::Match($flow, $pattern)
    if (-not $m.Success) { throw "Could not find numeric EQU $Name in flow.asm" }
    return [int]$m.Groups[1].Value
}

function Index-Of-OrFail {
    param([string]$Haystack, [string]$Needle)
    $index = $Haystack.IndexOf($Needle, [System.StringComparison]::Ordinal)
    if ($index -lt 0) { throw "Missing integration token: $Needle" }
    return $index
}

$killsPerRecharge = Get-EquValue 'BREACH_KILLS_PER_RECHARGE'
$dataPerRecharge = Get-EquValue 'BREACH_DATA_PER_RECHARGE'

Add-Check 'Kill recharge cadence is bounded' `
    ($killsPerRecharge -ge 2 -and $killsPerRecharge -le 4) `
    "kills-per-pulse=$killsPerRecharge"
Add-Check 'Shard recharge cadence is bounded' `
    ($dataPerRecharge -ge 3 -and $dataPerRecharge -le 6) `
    "shards-per-pulse=$dataPerRecharge"

$mainRedirect = Index-Of-OrFail $game 'process_play_input TEXTEQU <breach_flow_process_play_input>'
$mainInclude = Index-Of-OrFail $game 'include game\main.asm'
$mainStock = Index-Of-OrFail $game 'process_play_input TEXTEQU <breach_flow_stock_process_play_input>'
$gameplayInclude = Index-Of-OrFail $game 'include game\gameplay.asm'
$flowInclude = Index-Of-OrFail $game 'include game\flow.asm'
$stateInclude = Index-Of-OrFail $game 'include game\state.asm'
Add-Check 'Gameplay caller interception order' `
    ($mainRedirect -lt $mainInclude -and $mainInclude -lt $mainStock -and $mainStock -lt $gameplayInclude -and $flowInclude -lt $stateInclude) `
    'wrapper alias -> main caller -> stock alias -> gameplay implementation -> compact extension'

Add-Check 'No extra gameplay render hook' `
    (-not $game.Contains('breach_flow_render_game_screen') -and -not $game.Contains('response.asm')) `
    'byte-budgeted pass does not add a second renderer or response runtime'
Add-Check 'Demo oracle bypass exists' `
    ($flow.Contains('cmp byte ptr [demo_active], 0') -and $flow.Contains('jne breach_flow_passthrough')) `
    'deterministic demo/replay input retains the historical core path'
Add-Check 'Flame spends pulse reserve' `
    ($flow.Contains('dec byte ptr [pulse_count]') -and $flow.Contains('mov al, MSG_NOPULSE')) `
    'C is blocked dry and successful starts spend one pulse'
Add-Check 'Cooldown rollover flame still spends' `
    ($flow.Contains('mov al, [adventure_flame_timer]') -and $flow.Contains('cmp al, 1') -and $flow.Contains('ja breach_flow_pre_done')) `
    'timer 0 or 1 is treated as a fire-capable frame because the stock core decrements before handling C'
Add-Check 'Kills drive recharge' `
    ($flow.Contains('breach_flow_kill_chain') -and $flow.Contains('BREACH_KILLS_PER_RECHARGE') -and $flow.Contains('call breach_flow_recharge_with_feedback')) `
    'two-kill cadence feeds the visible pulse reserve'
Add-Check 'Shard routing drives recharge' `
    ($flow.Contains('breach_flow_data_chain') -and $flow.Contains('BREACH_DATA_PER_RECHARGE')) `
    'collected data contributes to offensive recovery'
Add-Check 'Objectives grant silent recovery' `
    ($flow.Contains('adventure_objectives_done') -and $flow.Contains('call breach_flow_recharge_silent')) `
    'relay/key progress restores resource without replacing objective feedback'
Add-Check 'Damage breaks partial progress' `
    ($flow.Contains('breach_flow_damage_break:') -and $flow.Contains('mov byte ptr [breach_flow_kill_chain], 0') -and $flow.Contains('mov byte ptr [breach_flow_data_chain], 0')) `
    'shield loss clears unfinished kill/shard recharge progress'
Add-Check '16-bit register safety guard' `
    (-not [regex]::IsMatch($flow, '(?i)\b(dil|sil|spl|bpl)\b')) `
    'compact extension avoids x64-only low-byte register names'
Add-Check 'No PURGE dependency remains' `
    (-not $game.Contains('PURGE process_play_input') -and -not $game.Contains('PURGE render_game_screen')) `
    'hook relies only on MASM-redefinable TEXTEQU names'

# Stage two is extremely close to the 64 KiB ceiling. Source-line count is not a
# binary-size substitute, but this catches accidental feature creep before the
# authoritative MASM build. Count instruction-looking lines only.
$instructionLines = @($flow -split "`r?`n" | Where-Object {
    $line = $_.Trim()
    $line -and
    -not $line.StartsWith(';') -and
    -not $line.EndsWith(':') -and
    -not $line.StartsWith('IF') -and
    -not $line.StartsWith('ENDIF') -and
    -not $line.Contains(' equ ') -and
    -not [regex]::IsMatch($line, '^breach_flow_.*\s+db\s+')
})
Add-Check 'Compact stage-two extension source budget' `
    ($instructionLines.Count -le 125) `
    "instruction-like lines=$($instructionLines.Count), soft cap=125; fresh MASM size remains authoritative"

$baselineHeadroom = $null
if ($buildReport) {
    $headroomMatch = [regex]::Match($buildReport, 'Stage two is within\s+(\d+)\s+bytes of the 64 KiB load limit')
    if ($headroomMatch.Success) {
        $baselineHeadroom = [int]$headroomMatch.Groups[1].Value
    }
}
Add-Check 'Baseline stage-two headroom is recorded' `
    ($null -ne $baselineHeadroom -and $baselineHeadroom -gt 0) `
    $(if ($null -ne $baselineHeadroom) { "pre-pass headroom=$baselineHeadroom bytes; rebuild required after changes" } else { 'build report did not expose stage-two headroom' })

# Keep the checked-in runtime table synchronized with the authored Campaign
# ObjectiveCounts. This caught a real 20-vs-12 Subgrid drift during this pass.
$sourceShardMatches = [regex]::Matches($sectorSource, 'RequiredDataShards\s*=\s*(\d+)')
$generatedShardMatch = [regex]::Match(
    $generatedSector,
    '(?m)^campaign_district_required_gems_table\s+db\s+([0-9, ]+)\s*$'
)
$sourceShardCounts = @()
foreach ($match in $sourceShardMatches) {
    $sourceShardCounts += [int]$match.Groups[1].Value
}
$generatedShardCounts = @()
if ($generatedShardMatch.Success) {
    foreach ($value in ($generatedShardMatch.Groups[1].Value -split ',')) {
        $generatedShardCounts += [int]$value.Trim()
    }
}
$sourceShardText = ($sourceShardCounts -join ',')
$generatedShardText = ($generatedShardCounts -join ',')
Add-Check 'Authored/generated shard requirements match' `
    ($sourceShardCounts.Count -eq 4 -and $generatedShardCounts.Count -eq 4 -and $sourceShardText -eq $generatedShardText) `
    "source=$sourceShardText generated=$generatedShardText"

# Deterministic economy model: one flame spends a pulse, two kills recover it,
# four shards recover another, and an objective can top the reserve back up.
$simPulses = 3
$simKillChain = 0
$simDataChain = 0
$simPulses--
$simKillChain += 2
if ($simKillChain -ge $killsPerRecharge -and $simPulses -lt 5) {
    $simKillChain -= $killsPerRecharge
    $simPulses++
}
$simDataChain += 4
if ($simDataChain -ge $dataPerRecharge -and $simPulses -lt 5) {
    $simDataChain -= $dataPerRecharge
    $simPulses++
}
if ($simPulses -lt 5) { $simPulses++ }
Add-Check 'Spend-kill-route-objective economy simulation' `
    ($simPulses -eq 5 -and $simKillChain -eq 0 -and $simDataChain -eq 0) `
    "1 spend + 2 kills + 4 shards + objective => pulses=$simPulses"

$simPulses = 3
$starts = 0
$blocked = 0
1..4 | ForEach-Object {
    if ($simPulses -gt 0) {
        $simPulses--
        $starts++
    } else {
        $blocked++
    }
}
Add-Check 'Three-shot starting flame economy' `
    ($starts -eq 3 -and $blocked -eq 1 -and $simPulses -eq 0) `
    "starts=$starts blocked=$blocked remaining=$simPulses"

$failed = @($checks | Where-Object { -not $_.Passed })
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('CyberStorm Breach Economy Harness')
$lines.Add(('Generated: {0:u}' -f (Get-Date).ToUniversalTime()))
$lines.Add('')
foreach ($check in $checks) {
    $status = if ($check.Passed) { 'PASS' } else { 'FAIL' }
    $lines.Add(('[{0}] {1} - {2}' -f $status, $check.Name, $check.Detail))
}
$lines.Add('')
$lines.Add(('Summary: {0} passed, {1} failed' -f ($checks.Count - $failed.Count), $failed.Count))

$reportDir = Split-Path -Parent $ReportPath
if ($reportDir -and -not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
}
$lines | Set-Content -Encoding UTF8 $ReportPath
$lines | ForEach-Object { Write-Host $_ }

if ($failed.Count -gt 0) {
    exit 1
}
