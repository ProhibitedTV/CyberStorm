param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$ReportPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = Join-Path $RepoRoot 'build\cyberstorm-x64-codemod-composition-report.txt'
}

$runtimeSource = Join-Path $RepoRoot 'src\bootx64.asm'
$combatSpec = Join-Path $RepoRoot 'assets\x64_combat.psd1'
$tracePatch = Join-Path $RepoRoot 'scripts\apply-x64-breach-response.ps1'
$integrityPatch = Join-Path $RepoRoot 'scripts\apply-x64-integrity-pressure.ps1'

foreach ($required in @($runtimeSource, $combatSpec, $tracePatch, $integrityPatch)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Missing codemod composition input: $required"
    }
}

$workRoot = Join-Path $RepoRoot 'build\x64-codemod-composition'
if (Test-Path -LiteralPath $workRoot) {
    Remove-Item -LiteralPath $workRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $workRoot | Out-Null

$results = New-Object System.Collections.Generic.List[object]

function Invoke-CheckedPowerShell {
    param([string]$ScriptPath, [string]$SandboxRoot)
    & powershell -ExecutionPolicy Bypass -File $ScriptPath -RepoRoot $SandboxRoot -SkipHarness
    if ($LASTEXITCODE -ne 0) {
        throw "Codemod failed: $ScriptPath (sandbox $SandboxRoot), exit $LASTEXITCODE"
    }
}

function New-CodemodSandbox {
    param([string]$Name)

    $root = Join-Path $workRoot $Name
    $src = Join-Path $root 'src'
    $assets = Join-Path $root 'assets'
    New-Item -ItemType Directory -Force -Path $src | Out-Null
    New-Item -ItemType Directory -Force -Path $assets | Out-Null
    Copy-Item -LiteralPath $runtimeSource -Destination (Join-Path $src 'bootx64.asm') -Force
    Copy-Item -LiteralPath $combatSpec -Destination (Join-Path $assets 'x64_combat.psd1') -Force
    return $root
}

function Assert-PatchedRuntime {
    param([string]$SandboxRoot, [string]$OrderName)

    $path = Join-Path $SandboxRoot 'src\bootx64.asm'
    $text = Get-Content -Raw -LiteralPath $path
    $traceCalls = ([regex]::Matches($text, 'call StartTerminalTraceResponse')).Count
    $pressureCalls = ([regex]::Matches($text, 'call UpdateHostilePressure')).Count
    $threatCalls = ([regex]::Matches($text, 'call DrawIntegrityThreat')).Count

    $checks = [ordered]@{
        TraceHelper = $text.Contains('terminal_trace_response:')
        IntegrityHelper = $text.Contains('UpdateHostilePressure PROC')
        TraceCalls = ($traceCalls -eq 2)
        PressureCall = ($pressureCalls -eq 1)
        ThreatHudCalls = ($threatCalls -eq 2)
        TracePrompt = $text.Contains("LevelObjectiveExitLine db 'BREAK TRACE / REACH EXIT',0")
        IntegrityHud = $text.Contains("LevelStatusLine db 'SHOTS 0000 HITS 0000 INT 3',0")
        RankHud = $text.Contains("LevelRankLine db 'RANK C',0")
        RankLogic = ($text.Contains('format_rank_a_check:') -and $text.Contains('format_rank_b_check:'))
        TraceGate = $text.Contains('; TRACE response gate: extraction stays locked until both rebooted sentries are down.')
        IntegrityFail = $text.Contains('pressure_integrity_fail:')
    }

    $failed = @($checks.GetEnumerator() | Where-Object { -not $_.Value } | ForEach-Object { $_.Key })
    $results.Add([pscustomobject]@{
        Order = $OrderName
        Passed = ($failed.Count -eq 0)
        Failed = ($failed -join ',')
        TraceCalls = $traceCalls
        PressureCalls = $pressureCalls
        ThreatCalls = $threatCalls
    })

    if ($failed.Count -gt 0) {
        throw "Codemod composition failed for $OrderName: $($failed -join ', ')"
    }
}

# TRACE then integrity.
$traceFirst = New-CodemodSandbox -Name 'trace-then-integrity'
Invoke-CheckedPowerShell -ScriptPath $tracePatch -SandboxRoot $traceFirst
Invoke-CheckedPowerShell -ScriptPath $integrityPatch -SandboxRoot $traceFirst
Assert-PatchedRuntime -SandboxRoot $traceFirst -OrderName 'trace-then-integrity'

# Reapply both to prove idempotency.
Invoke-CheckedPowerShell -ScriptPath $tracePatch -SandboxRoot $traceFirst
Invoke-CheckedPowerShell -ScriptPath $integrityPatch -SandboxRoot $traceFirst
Assert-PatchedRuntime -SandboxRoot $traceFirst -OrderName 'trace-then-integrity-reapplied'

# Integrity then TRACE.
$integrityFirst = New-CodemodSandbox -Name 'integrity-then-trace'
Invoke-CheckedPowerShell -ScriptPath $integrityPatch -SandboxRoot $integrityFirst
Invoke-CheckedPowerShell -ScriptPath $tracePatch -SandboxRoot $integrityFirst
Assert-PatchedRuntime -SandboxRoot $integrityFirst -OrderName 'integrity-then-trace'

# Reapply both to prove idempotency in the opposite order as well.
Invoke-CheckedPowerShell -ScriptPath $integrityPatch -SandboxRoot $integrityFirst
Invoke-CheckedPowerShell -ScriptPath $tracePatch -SandboxRoot $integrityFirst
Assert-PatchedRuntime -SandboxRoot $integrityFirst -OrderName 'integrity-then-trace-reapplied'

$reportDir = Split-Path -Parent $ReportPath
if ($reportDir -and -not (Test-Path -LiteralPath $reportDir)) {
    New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('CyberStorm x64 Codemod Composition Harness')
$lines.Add(('Generated: {0:u}' -f (Get-Date).ToUniversalTime()))
$lines.Add('')
foreach ($result in $results) {
    $status = if ($result.Passed) { 'PASS' } else { 'FAIL' }
    $lines.Add(('[{0}] {1} - traceCalls={2} pressureCalls={3} threatHudCalls={4} failed={5}' -f $status, $result.Order, $result.TraceCalls, $result.PressureCalls, $result.ThreatCalls, $result.Failed))
}
$lines.Add('')
$lines.Add('Summary: TRACE and integrity/rank codemods compose in both orders and remain idempotent on reapplication.')
$lines | Set-Content -Encoding UTF8 -LiteralPath $ReportPath
$lines | ForEach-Object { Write-Host $_ }

Remove-Item -LiteralPath $workRoot -Recurse -Force
