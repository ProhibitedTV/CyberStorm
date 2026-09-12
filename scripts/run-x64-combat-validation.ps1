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
    param([string]$Label, [scriptblock]$Action)
    Write-Host ''
    Write-Host ("== {0} ==" -f $Label)
    & $Action
    if ($LASTEXITCODE -is [int] -and $LASTEXITCODE -ne 0) {
        throw ("{0} failed with exit code {1}." -f $Label, $LASTEXITCODE)
    }
}

$tracePatch = Join-Path $RepoRoot 'scripts\apply-x64-breach-response.ps1'
$integrityPatch = Join-Path $RepoRoot 'scripts\apply-x64-integrity-pressure.ps1'
$smokePatch = Join-Path $RepoRoot 'scripts\apply-x64-response-smoke.ps1'
$encounterHarness = Join-Path $RepoRoot 'scripts\x64-encounter-harness.ps1'
$integrityHarness = Join-Path $RepoRoot 'scripts\x64-integrity-harness.ps1'
$buildScript = Join-Path $RepoRoot 'scripts\build.ps1'
$visualVerify = Join-Path $RepoRoot 'scripts\x64-response-smoke-verify.ps1'

foreach ($required in @($tracePatch, $integrityPatch, $smokePatch, $encounterHarness, $integrityHarness, $buildScript, $visualVerify)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Missing x64 combat validation component: $required"
    }
}

if ($CheckOnly) {
    Invoke-Step -Label 'Check TRACE runtime patch anchors' -Action {
        & powershell -ExecutionPolicy Bypass -File $tracePatch -RepoRoot $RepoRoot -CheckOnly -SkipHarness
    }
    Invoke-Step -Label 'Check integrity runtime patch anchors' -Action {
        & powershell -ExecutionPolicy Bypass -File $integrityPatch -RepoRoot $RepoRoot -CheckOnly -SkipHarness
    }
    Invoke-Step -Label 'Check TRACE VM-smoke patch anchors' -Action {
        & powershell -ExecutionPolicy Bypass -File $smokePatch -RepoRoot $RepoRoot -CheckOnly
    }
    Write-Host ''
    Write-Host 'x64 combat patch anchors are valid. No source files changed.'
    exit 0
}

Invoke-Step -Label 'Apply x64 TRACE response patch' -Action {
    & powershell -ExecutionPolicy Bypass -File $tracePatch -RepoRoot $RepoRoot -SkipHarness
}

Invoke-Step -Label 'Apply x64 integrity pressure patch' -Action {
    & powershell -ExecutionPolicy Bypass -File $integrityPatch -RepoRoot $RepoRoot -SkipHarness
}

Invoke-Step -Label 'Apply x64 TRACE VM-smoke extension' -Action {
    & powershell -ExecutionPolicy Bypass -File $smokePatch -RepoRoot $RepoRoot
}

Invoke-Step -Label 'Validate x64 TRACE encounter state machine' -Action {
    & powershell -ExecutionPolicy Bypass -File $encounterHarness -RepoRoot $RepoRoot
}

Invoke-Step -Label 'Validate x64 integrity pressure model' -Action {
    & powershell -ExecutionPolicy Bypass -File $integrityHarness -RepoRoot $RepoRoot
}

if ($SkipBuild) {
    Write-Host ''
    Write-Host 'Skipped x64 build/VM smoke by request. Source patches and deterministic combat harnesses passed.'
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
Write-Host 'x64 combat validation passed: TRACE response, integrity pressure, deterministic models, x64 build, VM gameplay smoke, and visual transition gates are green.'
