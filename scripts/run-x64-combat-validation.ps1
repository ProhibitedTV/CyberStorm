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
$attackPatch = Join-Path $RepoRoot 'scripts\apply-x64-attack-presentation.ps1'
$attackEventPatch = Join-Path $RepoRoot 'scripts\apply-x64-attack-events.ps1'
$coverPatch = Join-Path $RepoRoot 'scripts\apply-x64-cover.ps1'
$smokePatch = Join-Path $RepoRoot 'scripts\apply-x64-response-smoke.ps1'
$compositionHarness = Join-Path $RepoRoot 'scripts\x64-codemod-composition-harness.ps1'
$attackCompositionHarness = Join-Path $RepoRoot 'scripts\x64-attack-codemod-harness.ps1'
$encounterHarness = Join-Path $RepoRoot 'scripts\x64-encounter-harness.ps1'
$integrityHarness = Join-Path $RepoRoot 'scripts\x64-integrity-harness.ps1'
$attackHarness = Join-Path $RepoRoot 'scripts\x64-attack-presentation-harness.ps1'
$attackEventHarness = Join-Path $RepoRoot 'scripts\x64-attack-events-harness.ps1'
$coverHarness = Join-Path $RepoRoot 'scripts\x64-cover-harness.ps1'
$buildScript = Join-Path $RepoRoot 'scripts\build.ps1'
$visualVerify = Join-Path $RepoRoot 'scripts\x64-response-smoke-verify.ps1'

foreach ($required in @(
    $tracePatch,
    $integrityPatch,
    $attackPatch,
    $attackEventPatch,
    $coverPatch,
    $smokePatch,
    $compositionHarness,
    $attackCompositionHarness,
    $encounterHarness,
    $integrityHarness,
    $attackHarness,
    $attackEventHarness,
    $coverHarness,
    $buildScript,
    $visualVerify
)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Missing x64 combat validation component: $required"
    }
}

Invoke-Step -Label 'Validate TRACE/integrity codemod composition' -Action {
    & powershell -ExecutionPolicy Bypass -File $compositionHarness -RepoRoot $RepoRoot
}

Invoke-Step -Label 'Validate downstream hostile-combat codemod composition' -Action {
    & powershell -ExecutionPolicy Bypass -File $attackCompositionHarness -RepoRoot $RepoRoot
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
    Write-Host 'x64 combat codemods compose and all base-source patch anchors are valid. Hostile presentation/event/cover anchors were validated against a throwaway patched runtime. No checkout source files changed.'
    exit 0
}

Invoke-Step -Label 'Apply x64 TRACE response patch' -Action {
    & powershell -ExecutionPolicy Bypass -File $tracePatch -RepoRoot $RepoRoot -SkipHarness
}

Invoke-Step -Label 'Apply x64 integrity pressure + rank patch' -Action {
    & powershell -ExecutionPolicy Bypass -File $integrityPatch -RepoRoot $RepoRoot -SkipHarness
}

Invoke-Step -Label 'Apply x64 hostile attack presentation patch' -Action {
    & powershell -ExecutionPolicy Bypass -File $attackPatch -RepoRoot $RepoRoot -SkipHarness
}

Invoke-Step -Label 'Apply x64 hostile attack-event attribution patch' -Action {
    & powershell -ExecutionPolicy Bypass -File $attackEventPatch -RepoRoot $RepoRoot -SkipHarness
}

Invoke-Step -Label 'Apply x64 visible-cover patch' -Action {
    & powershell -ExecutionPolicy Bypass -File $coverPatch -RepoRoot $RepoRoot -SkipHarness
}

Invoke-Step -Label 'Apply x64 TRACE VM-smoke extension' -Action {
    & powershell -ExecutionPolicy Bypass -File $smokePatch -RepoRoot $RepoRoot
}

Invoke-Step -Label 'Validate x64 TRACE encounter state machine' -Action {
    & powershell -ExecutionPolicy Bypass -File $encounterHarness -RepoRoot $RepoRoot
}

Invoke-Step -Label 'Validate x64 integrity pressure + rank model' -Action {
    & powershell -ExecutionPolicy Bypass -File $integrityHarness -RepoRoot $RepoRoot
}

Invoke-Step -Label 'Validate x64 hostile attack presentation' -Action {
    & powershell -ExecutionPolicy Bypass -File $attackHarness -RepoRoot $RepoRoot
}

Invoke-Step -Label 'Validate x64 hostile attack-event attribution' -Action {
    & powershell -ExecutionPolicy Bypass -File $attackEventHarness -RepoRoot $RepoRoot
}

Invoke-Step -Label 'Validate x64 visible cover pockets' -Action {
    & powershell -ExecutionPolicy Bypass -File $coverHarness -RepoRoot $RepoRoot
}

if ($SkipBuild) {
    Write-Host ''
    Write-Host 'Skipped x64 build/VM smoke by request. Codemod composition, runtime patches, and deterministic combat/presentation/event/cover harnesses passed.'
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
Write-Host 'x64 combat validation passed: codemod composition, TRACE response, integrity pressure, completion rank, projected hostile lock presentation, attributed hostile shot events, visible geometry cover, deterministic models, x64 build, VM gameplay smoke, and visual transition gates are green.'
