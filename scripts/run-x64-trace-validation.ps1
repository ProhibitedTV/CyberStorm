param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$X64AssemblerPath,
    [string]$X64LinkerPath,
    [switch]$CheckOnly,
    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Step {
    param(
        [string]$Label,
        [scriptblock]$Action
    )
    Write-Host ''
    Write-Host ("== {0} ==" -f $Label)
    & $Action
    if ($LASTEXITCODE -is [int] -and $LASTEXITCODE -ne 0) {
        throw ("{0} failed with exit code {1}." -f $Label, $LASTEXITCODE)
    }
}

$runtimePatch = Join-Path $RepoRoot 'scripts\apply-x64-breach-response.ps1'
$smokePatch = Join-Path $RepoRoot 'scripts\apply-x64-response-smoke.ps1'
$encounterHarness = Join-Path $RepoRoot 'scripts\x64-encounter-harness.ps1'
$buildScript = Join-Path $RepoRoot 'scripts\build.ps1'
$visualVerify = Join-Path $RepoRoot 'scripts\x64-response-smoke-verify.ps1'

foreach ($required in @($runtimePatch, $smokePatch, $encounterHarness, $buildScript, $visualVerify)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Missing TRACE validation component: $required"
    }
}

if ($CheckOnly) {
    Invoke-Step -Label 'Check runtime response patch anchors' -Action {
        & powershell -ExecutionPolicy Bypass -File $runtimePatch -RepoRoot $RepoRoot -CheckOnly -SkipHarness
    }
    Invoke-Step -Label 'Check VM response-smoke patch anchors' -Action {
        & powershell -ExecutionPolicy Bypass -File $smokePatch -RepoRoot $RepoRoot -CheckOnly
    }
    Write-Host ''
    Write-Host 'TRACE patch anchors are valid. No source files changed.'
    exit 0
}

Invoke-Step -Label 'Apply x64 TRACE runtime patch' -Action {
    & powershell -ExecutionPolicy Bypass -File $runtimePatch -RepoRoot $RepoRoot -SkipHarness
}

Invoke-Step -Label 'Apply x64 TRACE VM smoke extension' -Action {
    & powershell -ExecutionPolicy Bypass -File $smokePatch -RepoRoot $RepoRoot
}

Invoke-Step -Label 'Validate x64 encounter state machine' -Action {
    & powershell -ExecutionPolicy Bypass -File $encounterHarness -RepoRoot $RepoRoot
}

if ($SkipBuild) {
    Write-Host ''
    Write-Host 'Skipped x64 build/VM smoke by request. Source and encounter validation completed.'
    exit 0
}

Invoke-Step -Label 'Build x64 and run VirtualBox gameplay smoke' -Action {
    $args = @(
        '-ExecutionPolicy', 'Bypass',
        '-File', $buildScript,
        '-Target', 'x64-uefi',
        '-VmSmoke'
    )
    if (-not [string]::IsNullOrWhiteSpace($X64AssemblerPath)) {
        $args += @('-X64AssemblerPath', $X64AssemblerPath)
    }
    if (-not [string]::IsNullOrWhiteSpace($X64LinkerPath)) {
        $args += @('-X64LinkerPath', $X64LinkerPath)
    }
    & powershell @args
}

Invoke-Step -Label 'Verify TRACE visual state transitions' -Action {
    & powershell -ExecutionPolicy Bypass -File $visualVerify -RepoRoot $RepoRoot
}

Write-Host ''
Write-Host 'x64 TRACE validation passed: source patch, encounter model, VM gameplay smoke, and visual state-transition gates are green.'
