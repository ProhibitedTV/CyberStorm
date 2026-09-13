param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$ReportPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = Join-Path $RepoRoot 'build\cyberstorm-x64-attack-codemod-report.txt'
}

$runtimeSource = Join-Path $RepoRoot 'src\bootx64.asm'
$combatSpec = Join-Path $RepoRoot 'assets\x64_combat.psd1'
$attackSpec = Join-Path $RepoRoot 'assets\x64_attack_presentation.psd1'
$eventSpec = Join-Path $RepoRoot 'assets\x64_attack_events.psd1'
$coverSpec = Join-Path $RepoRoot 'assets\x64_cover.psd1'
$tracePatch = Join-Path $RepoRoot 'scripts\apply-x64-breach-response.ps1'
$integrityPatch = Join-Path $RepoRoot 'scripts\apply-x64-integrity-pressure.ps1'
$attackPatch = Join-Path $RepoRoot 'scripts\apply-x64-attack-presentation.ps1'
$eventPatch = Join-Path $RepoRoot 'scripts\apply-x64-attack-events.ps1'
$coverPatch = Join-Path $RepoRoot 'scripts\apply-x64-cover.ps1'

foreach ($required in @($runtimeSource, $combatSpec, $attackSpec, $eventSpec, $coverSpec, $tracePatch, $integrityPatch, $attackPatch, $eventPatch, $coverPatch)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Missing hostile combat codemod input: $required"
    }
}

$workRoot = Join-Path $RepoRoot 'build\x64-attack-codemod'
if (Test-Path -LiteralPath $workRoot) {
    Remove-Item -LiteralPath $workRoot -Recurse -Force
}
$srcDir = Join-Path $workRoot 'src'
$assetDir = Join-Path $workRoot 'assets'
New-Item -ItemType Directory -Force -Path $srcDir | Out-Null
New-Item -ItemType Directory -Force -Path $assetDir | Out-Null
Copy-Item -LiteralPath $runtimeSource -Destination (Join-Path $srcDir 'bootx64.asm') -Force
Copy-Item -LiteralPath $combatSpec -Destination (Join-Path $assetDir 'x64_combat.psd1') -Force
Copy-Item -LiteralPath $attackSpec -Destination (Join-Path $assetDir 'x64_attack_presentation.psd1') -Force
Copy-Item -LiteralPath $eventSpec -Destination (Join-Path $assetDir 'x64_attack_events.psd1') -Force
Copy-Item -LiteralPath $coverSpec -Destination (Join-Path $assetDir 'x64_cover.psd1') -Force

function Invoke-Codemod {
    param([string]$ScriptPath)
    & powershell -ExecutionPolicy Bypass -File $ScriptPath -RepoRoot $workRoot -SkipHarness
    if ($LASTEXITCODE -ne 0) {
        throw "Codemod failed in hostile-combat sandbox: $ScriptPath exit=$LASTEXITCODE"
    }
}

# Production dependency order: encounter response -> integrity/rank -> lock/impact
# presentation -> attributed hostile shot events -> visible geometry cover.
Invoke-Codemod -ScriptPath $tracePatch
Invoke-Codemod -ScriptPath $integrityPatch
Invoke-Codemod -ScriptPath $attackPatch
Invoke-Codemod -ScriptPath $eventPatch
Invoke-Codemod -ScriptPath $coverPatch

$patchedPath = Join-Path $srcDir 'bootx64.asm'
$text = Get-Content -Raw -LiteralPath $patchedPath

$checks = [ordered]@{
    TraceHelper = $text.Contains('terminal_trace_response:')
    IntegrityHelper = $text.Contains('UpdateHostilePressure PROC')
    AttackPresentationHelper = $text.Contains('DrawHostileAttackPresentation PROC')
    AttackPresentationHook = (([regex]::Matches($text, 'call DrawHostileAttackPresentation')).Count -eq 1)
    AttackSourceSelector = $text.Contains('SelectHostileAttackSource PROC')
    AttackEventRenderer = $text.Contains('DrawHostileAttackEvent PROC')
    AttackSourceCall = (([regex]::Matches($text, 'call SelectHostileAttackSource')).Count -eq 1)
    AttackEventDrawCall = (([regex]::Matches($text, 'call DrawHostileAttackEvent')).Count -eq 1)
    CoverResolver = $text.Contains('UpdatePlayerCoverState PROC')
    CoverUpdateCall = (([regex]::Matches($text, 'call UpdatePlayerCoverState')).Count -eq 1)
    CoverState = $text.Contains('PlayerCoverState dd 0')
    CoverHud = $text.Contains("LevelCoverLine db 'SIGNAL MASKED',0")
    WardenProjection = $text.Contains('ATTACK_WARDEN_X')
    LeftProjection = $text.Contains('ATTACK_LEFT_X')
    RightProjection = $text.Contains('ATTACK_RIGHT_X')
    EventState = ($text.Contains('LastAttackSource dd 0') -and $text.Contains('AttackEventTicks dd 0'))
    EventStackAlignment = $text.Contains("DrawHostileAttackEvent PROC`n    push r12`n    push r13`n    sub rsp, 28h")
    ImpactPath = $text.Contains('hostile_attack_draw_impact:')
    RankStillPresent = $text.Contains("LevelRankLine db 'RANK C',0")
    TraceStillPresent = $text.Contains("LevelObjectiveExitLine db 'BREAK TRACE / REACH EXIT',0")
}
$failed = @($checks.GetEnumerator() | Where-Object { -not $_.Value } | ForEach-Object { $_.Key })
if ($failed.Count -gt 0) {
    throw "Hostile combat codemod composition failed: $($failed -join ', ')"
}

$firstHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $patchedPath).Hash
Invoke-Codemod -ScriptPath $attackPatch
Invoke-Codemod -ScriptPath $eventPatch
Invoke-Codemod -ScriptPath $coverPatch
$secondHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $patchedPath).Hash
$idempotent = $firstHash -eq $secondHash
if (-not $idempotent) {
    throw 'Reapplying hostile presentation/events/cover changed bootx64.asm.'
}

$reportDir = Split-Path -Parent $ReportPath
if ($reportDir -and -not (Test-Path -LiteralPath $reportDir)) {
    New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('CyberStorm x64 Hostile Combat Codemod Harness')
$lines.Add(('Generated: {0:u}' -f (Get-Date).ToUniversalTime()))
$lines.Add('')
foreach ($entry in $checks.GetEnumerator()) {
    $status = if ($entry.Value) { 'PASS' } else { 'FAIL' }
    $lines.Add(('[{0}] {1}' -f $status, $entry.Key))
}
$lines.Add(('[{0}] DownstreamCombatCodemodsIdempotent - before={1} after={2}' -f $(if ($idempotent) { 'PASS' } else { 'FAIL' }), $firstHash, $secondHash))
$lines.Add('')
$lines.Add('Summary: TRACE + integrity/rank + hostile lock presentation + attributed shot events + visible cover compose in production order, and all downstream combat codemods are idempotent.')
$lines | Set-Content -Encoding UTF8 -LiteralPath $ReportPath
$lines | ForEach-Object { Write-Host $_ }

Remove-Item -LiteralPath $workRoot -Recurse -Force
