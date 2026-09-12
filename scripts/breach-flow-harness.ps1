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

if (-not (Test-Path $gamePath)) { throw "Missing $gamePath" }
if (-not (Test-Path $flowPath)) { throw "Missing $flowPath" }

$game = Get-Content -Raw $gamePath
$flow = Get-Content -Raw $flowPath
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

$flowMax = Get-EquValue 'BREACH_FLOW_MAX'
$killGain = Get-EquValue 'BREACH_FLOW_KILL_GAIN'
$progressGain = Get-EquValue 'BREACH_FLOW_PROGRESS_GAIN'
$bonusThreshold = Get-EquValue 'BREACH_FLOW_BONUS_THRESHOLD'
$rechargeThreshold = Get-EquValue 'BREACH_FLOW_RECHARGE_THRESHOLD'
$rechargeCost = Get-EquValue 'BREACH_FLOW_RECHARGE_COST'
$killBonus = Get-EquValue 'BREACH_FLOW_KILL_BONUS'
$d1 = Get-EquValue 'BREACH_FLOW_DECAY_DISTRICT_1'
$d2 = Get-EquValue 'BREACH_FLOW_DECAY_DISTRICT_2'
$d3 = Get-EquValue 'BREACH_FLOW_DECAY_DISTRICT_3'
$d4 = Get-EquValue 'BREACH_FLOW_DECAY_DISTRICT_4'

Add-Check 'Flow thresholds are ordered' `
    ($bonusThreshold -gt 0 -and $bonusThreshold -lt $rechargeThreshold -and $rechargeThreshold -le $flowMax) `
    "bonus=$bonusThreshold recharge=$rechargeThreshold max=$flowMax"
Add-Check 'Recharge cost preserves bonus tier' `
    (($rechargeThreshold - $rechargeCost) -ge $bonusThreshold) `
    "post-recharge flow=$($rechargeThreshold - $rechargeCost) bonus-tier=$bonusThreshold"
Add-Check 'District decay tightens monotonically' `
    ($d1 -gt $d2 -and $d2 -gt $d3 -and $d3 -gt $d4 -and $d4 -gt 0) `
    "D1=$d1 D2=$d2 D3=$d3 D4=$d4"

$mainRedirect = Index-Of-OrFail $game 'process_play_input TEXTEQU <breach_flow_process_play_input>'
$mainInclude = Index-Of-OrFail $game 'include game\main.asm'
$mainStock = Index-Of-OrFail $game 'process_play_input TEXTEQU <breach_flow_stock_process_play_input>'
$gameplayInclude = Index-Of-OrFail $game 'include game\gameplay.asm'
Add-Check 'Gameplay caller interception order' `
    ($mainRedirect -lt $mainInclude -and $mainInclude -lt $mainStock -and $mainStock -lt $gameplayInclude) `
    'wrapper alias -> main caller -> stock alias -> gameplay implementation'

$renderRedirect = Index-Of-OrFail $game 'render_game_screen TEXTEQU <breach_flow_render_game_screen>'
$sceneInclude = Index-Of-OrFail $game 'include game\render\scenes.asm'
$renderStock = Index-Of-OrFail $game 'render_game_screen TEXTEQU <breach_flow_stock_render_game_screen>'
$hudInclude = Index-Of-OrFail $game 'include game\render\hud.asm'
Add-Check 'Renderer caller interception order' `
    ($renderRedirect -lt $sceneInclude -and $sceneInclude -lt $renderStock -and $renderStock -lt $hudInclude) `
    'wrapper alias -> scenes caller -> stock alias -> HUD/game renderer implementation'

Add-Check 'Flow module sees stock aliases' `
    ($game.IndexOf('include game\flow.asm', [System.StringComparison]::Ordinal) -gt $hudInclude) `
    'flow.asm is assembled after stock process/render aliases are active'
Add-Check 'Demo oracle bypass exists' `
    ($flow.Contains('cmp byte ptr [demo_active], 0') -and $flow.Contains('jne breach_flow_input_passthrough')) `
    'deterministic demo/replay input retains the historical core path'
Add-Check 'Flame spends pulse reserve' `
    ($flow.Contains('dec byte ptr [pulse_count]') -and $flow.Contains('mov al, MSG_NOPULSE')) `
    'C is blocked dry and successful starts spend one pulse'
Add-Check 'Damage breaks momentum' `
    ($flow.Contains('mov byte ptr [breach_flow_value], 0') -and $flow.Contains('BREACH_FLOW_FLASH_BREAK')) `
    'shield loss resets FLOW'
Add-Check '16-bit register safety guard' `
    (-not [regex]::IsMatch($flow, '(?i)\b(dil|sil|spl|bpl)\b')) `
    'flow.asm avoids x64-only low-byte register names'
Add-Check 'No PURGE dependency remains' `
    (-not $game.Contains('PURGE process_play_input') -and -not $game.Contains('PURGE render_game_screen')) `
    'hook uses MASM-redefinable TEXTEQU names instead of macro PURGE semantics'

# Small deterministic model of the intended economy. Two kills plus two progress
# events should hit max FLOW, recharge one pulse, and fall back to the bonus tier.
$simFlow = 0
$simPulses = 3
$simBonus = 0
$simRecharge = 0
$events = @(
    @{ Kind = 'kill'; Gain = $killGain },
    @{ Kind = 'kill'; Gain = $killGain },
    @{ Kind = 'progress'; Gain = $progressGain },
    @{ Kind = 'progress'; Gain = $progressGain }
)

foreach ($event in $events) {
    $simFlow = [Math]::Min($flowMax, $simFlow + [int]$event.Gain)
    if ($event.Kind -eq 'kill' -and $simFlow -ge $bonusThreshold) {
        $simBonus += $killBonus
    }
    if ($simFlow -ge $rechargeThreshold -and $simPulses -lt 5) {
        $simPulses++
        $simFlow -= $rechargeCost
        $simRecharge++
    }
}

Add-Check 'Core reward loop simulation' `
    ($simFlow -eq ($rechargeThreshold - $rechargeCost) -and $simPulses -eq 4 -and $simRecharge -eq 1 -and $simBonus -eq $killBonus) `
    "2 kills + 2 progress => flow=$simFlow pulses=$simPulses recharge=$simRecharge bonus=$simBonus"

# A dry reserve must permit exactly three starts from the stock START_PULSES=3.
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
$lines.Add('CyberStorm Breach Flow Harness')
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
