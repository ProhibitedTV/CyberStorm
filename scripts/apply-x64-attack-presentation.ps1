param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$CheckOnly,
    [switch]$SkipHarness
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$runtimePath = Join-Path $RepoRoot 'src\bootx64.asm'
$specPath = Join-Path $RepoRoot 'assets\x64_attack_presentation.psd1'
$harnessPath = Join-Path $RepoRoot 'scripts\x64-attack-presentation-harness.ps1'
foreach ($requiredPath in @($runtimePath, $specPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Missing required file: $requiredPath"
    }
}

$presentation = (Import-PowerShellDataFile -Path $specPath).Presentation
$text = Get-Content -Raw -LiteralPath $runtimePath
$hadCrLf = $text.Contains("`r`n")
$text = $text.Replace("`r`n", "`n")

if (-not $text.Contains('UpdateHostilePressure PROC')) {
    throw 'Hostile attack presentation requires the x64 integrity-pressure patch first. Apply scripts\apply-x64-integrity-pressure.ps1 before this codemod.'
}

$marker = 'DrawHostileAttackPresentation PROC'
if ($text.Contains($marker)) {
    Write-Host 'x64 hostile attack presentation patch is already present.'
    if (-not $SkipHarness -and (Test-Path -LiteralPath $harnessPath)) {
        & powershell -ExecutionPolicy Bypass -File $harnessPath -RepoRoot $RepoRoot
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    exit 0
}

function Replace-ExactOnce {
    param([string]$Name, [string]$Old, [string]$New)

    $first = $script:text.IndexOf($Old, [System.StringComparison]::Ordinal)
    if ($first -lt 0) {
        throw "Patch anchor '$Name' was not found. Patched bootx64.asm has drifted; inspect before applying."
    }
    $second = $script:text.IndexOf($Old, $first + $Old.Length, [System.StringComparison]::Ordinal)
    if ($second -ge 0) {
        throw "Patch anchor '$Name' is ambiguous; found more than once."
    }
    $script:text = $script:text.Substring(0, $first) + $New + $script:text.Substring($first + $Old.Length)
    Write-Host ("Prepared: {0}" -f $Name)
}

function Format-MasmHex {
    param([int]$Value)
    return ('{0:X8}h' -f ([uint32]$Value))
}

$sources = @($presentation.Sources)
if ($sources.Count -ne 3) {
    throw "Expected exactly three authored hostile presentation sources; found $($sources.Count)."
}
$warden = $sources | Where-Object { $_.Id -eq 'warden' } | Select-Object -First 1
$left = $sources | Where-Object { $_.Id -eq 'sentry-left' } | Select-Object -First 1
$right = $sources | Where-Object { $_.Id -eq 'sentry-right' } | Select-Object -First 1
if ($null -eq $warden -or $null -eq $left -or $null -eq $right) {
    throw 'Attack presentation source set must contain warden, sentry-left, and sentry-right.'
}

$constantOld = 'CROSSHAIR_MIN_X               equ 00000050h'
$constantNew = @"
ATTACK_LOCK_TARGET_X          equ $([int]$presentation.LockTargetX)
ATTACK_LOCK_TARGET_Y          equ $([int]$presentation.LockTargetY)
ATTACK_LOCK_COLOR             equ $(Format-MasmHex -Value ([int]$presentation.LockColor))
ATTACK_LOCK_PULSE_COLOR       equ $(Format-MasmHex -Value ([int]$presentation.LockPulseColor))
ATTACK_IMPACT_COLOR           equ $(Format-MasmHex -Value ([int]$presentation.ImpactColor))
ATTACK_IMPACT_INSET           equ $([int]$presentation.ImpactInset)
ATTACK_IMPACT_CROSS_HALF      equ $([int]$presentation.ImpactCrossHalfSize)
ATTACK_PULSE_MASK             equ $([int]$presentation.PulseMask)
ATTACK_WARDEN_X               equ $([int]$warden.X)
ATTACK_WARDEN_Y               equ $([int]$warden.Y)
ATTACK_WARDEN_Z               equ $([int]$warden.Z)
ATTACK_LEFT_X                 equ $([int]$left.X)
ATTACK_LEFT_Y                 equ $([int]$left.Y)
ATTACK_LEFT_Z                 equ $([int]$left.Z)
ATTACK_RIGHT_X                equ $([int]$right.X)
ATTACK_RIGHT_Y                equ $([int]$right.Y)
ATTACK_RIGHT_Z                equ $([int]$right.Z)
CROSSHAIR_MIN_X               equ 00000050h
"@
Replace-ExactOnce -Name 'hostile attack presentation constants' -Old $constantOld -New $constantNew

$helperOld = @'
DrawIntegrityThreat PROC
    sub rsp, 20h

    cmp dword ptr [ObjectiveState], 3
'@
$helperNew = @'
DrawHostileAttackPresentation PROC
    sub rsp, 20h

    cmp dword ptr [ObjectiveState], 3
    jae hostile_attack_draw_done

    cmp dword ptr [DamageFlashTicks], 0
    jne hostile_attack_draw_impact

    mov eax, dword ptr [ExposureTicks]
    cmp eax, PRESSURE_WARN_TICKS
    jb hostile_attack_draw_done

    ; Each live actor projects its authored weapon point into the current view.
    ; The beams converge on the player-view center, making the existing lock-on
    ; pressure readable as hostile intent instead of an unexplained HUD timer.
    cmp dword ptr [EnemyAlive], 0
    je hostile_attack_draw_left
    mov ecx, ATTACK_WARDEN_X
    mov edx, ATTACK_WARDEN_Y
    mov r8d, ATTACK_WARDEN_Z
    call ProjectLevelPoint3D
    mov ecx, eax
    mov r8d, ATTACK_LOCK_TARGET_X
    mov r9d, ATTACK_LOCK_TARGET_Y
    mov eax, ATTACK_LOCK_COLOR
    call DrawGopLine

hostile_attack_draw_left:
    cmp dword ptr [SentryLeftAlive], 0
    je hostile_attack_draw_right
    mov ecx, ATTACK_LEFT_X
    mov edx, ATTACK_LEFT_Y
    mov r8d, ATTACK_LEFT_Z
    call ProjectLevelPoint3D
    mov ecx, eax
    mov r8d, ATTACK_LOCK_TARGET_X
    mov r9d, ATTACK_LOCK_TARGET_Y
    mov eax, ATTACK_LOCK_COLOR
    call DrawGopLine

hostile_attack_draw_right:
    cmp dword ptr [SentryRightAlive], 0
    je hostile_attack_draw_bracket
    mov ecx, ATTACK_RIGHT_X
    mov edx, ATTACK_RIGHT_Y
    mov r8d, ATTACK_RIGHT_Z
    call ProjectLevelPoint3D
    mov ecx, eax
    mov r8d, ATTACK_LOCK_TARGET_X
    mov r9d, ATTACK_LOCK_TARGET_Y
    mov eax, ATTACK_LOCK_COLOR
    call DrawGopLine

hostile_attack_draw_bracket:
    ; Four corner marks make lock state readable even when the hostile source is
    ; near an edge of the viewport. The inner marks pulse on the existing level
    ; animation counter without introducing another timer.
    mov ecx, ATTACK_LOCK_TARGET_X - 28
    mov edx, ATTACK_LOCK_TARGET_Y - 22
    mov r8d, ATTACK_LOCK_TARGET_X - 12
    mov r9d, ATTACK_LOCK_TARGET_Y - 22
    mov eax, ATTACK_LOCK_COLOR
    call DrawGopLine
    mov ecx, ATTACK_LOCK_TARGET_X + 12
    mov edx, ATTACK_LOCK_TARGET_Y - 22
    mov r8d, ATTACK_LOCK_TARGET_X + 28
    mov r9d, ATTACK_LOCK_TARGET_Y - 22
    mov eax, ATTACK_LOCK_COLOR
    call DrawGopLine
    mov ecx, ATTACK_LOCK_TARGET_X - 28
    mov edx, ATTACK_LOCK_TARGET_Y + 22
    mov r8d, ATTACK_LOCK_TARGET_X - 12
    mov r9d, ATTACK_LOCK_TARGET_Y + 22
    mov eax, ATTACK_LOCK_COLOR
    call DrawGopLine
    mov ecx, ATTACK_LOCK_TARGET_X + 12
    mov edx, ATTACK_LOCK_TARGET_Y + 22
    mov r8d, ATTACK_LOCK_TARGET_X + 28
    mov r9d, ATTACK_LOCK_TARGET_Y + 22
    mov eax, ATTACK_LOCK_COLOR
    call DrawGopLine

    mov eax, dword ptr [LevelPulseTicks]
    test eax, ATTACK_PULSE_MASK
    jnz hostile_attack_draw_done
    mov ecx, ATTACK_LOCK_TARGET_X - 12
    mov edx, ATTACK_LOCK_TARGET_Y
    mov r8d, ATTACK_LOCK_TARGET_X + 12
    mov r9d, ATTACK_LOCK_TARGET_Y
    mov eax, ATTACK_LOCK_PULSE_COLOR
    call DrawGopLine
    mov ecx, ATTACK_LOCK_TARGET_X
    mov edx, ATTACK_LOCK_TARGET_Y - 12
    mov r8d, ATTACK_LOCK_TARGET_X
    mov r9d, ATTACK_LOCK_TARGET_Y + 12
    mov eax, ATTACK_LOCK_PULSE_COLOR
    call DrawGopLine
    jmp hostile_attack_draw_done

hostile_attack_draw_impact:
    ; Damage is a hard visual event: frame the viewport and flash the player-view
    ; center. This makes integrity loss legible even when the HUD text is missed.
    mov ecx, ATTACK_IMPACT_INSET
    mov edx, ATTACK_IMPACT_INSET
    mov r8d, 640 - ATTACK_IMPACT_INSET
    mov r9d, ATTACK_IMPACT_INSET
    mov eax, ATTACK_IMPACT_COLOR
    call DrawGopLine
    mov ecx, 640 - ATTACK_IMPACT_INSET
    mov edx, ATTACK_IMPACT_INSET
    mov r8d, 640 - ATTACK_IMPACT_INSET
    mov r9d, 480 - ATTACK_IMPACT_INSET
    mov eax, ATTACK_IMPACT_COLOR
    call DrawGopLine
    mov ecx, 640 - ATTACK_IMPACT_INSET
    mov edx, 480 - ATTACK_IMPACT_INSET
    mov r8d, ATTACK_IMPACT_INSET
    mov r9d, 480 - ATTACK_IMPACT_INSET
    mov eax, ATTACK_IMPACT_COLOR
    call DrawGopLine
    mov ecx, ATTACK_IMPACT_INSET
    mov edx, 480 - ATTACK_IMPACT_INSET
    mov r8d, ATTACK_IMPACT_INSET
    mov r9d, ATTACK_IMPACT_INSET
    mov eax, ATTACK_IMPACT_COLOR
    call DrawGopLine

    mov ecx, ATTACK_LOCK_TARGET_X - ATTACK_IMPACT_CROSS_HALF
    mov edx, ATTACK_LOCK_TARGET_Y
    mov r8d, ATTACK_LOCK_TARGET_X + ATTACK_IMPACT_CROSS_HALF
    mov r9d, ATTACK_LOCK_TARGET_Y
    mov eax, ATTACK_IMPACT_COLOR
    call DrawGopLine
    mov ecx, ATTACK_LOCK_TARGET_X
    mov edx, ATTACK_LOCK_TARGET_Y - ATTACK_IMPACT_CROSS_HALF
    mov r8d, ATTACK_LOCK_TARGET_X
    mov r9d, ATTACK_LOCK_TARGET_Y + ATTACK_IMPACT_CROSS_HALF
    mov eax, ATTACK_IMPACT_COLOR
    call DrawGopLine

hostile_attack_draw_done:
    add rsp, 20h
    ret
DrawHostileAttackPresentation ENDP

DrawIntegrityThreat PROC
    sub rsp, 20h

    call DrawHostileAttackPresentation

    cmp dword ptr [ObjectiveState], 3
'@
Replace-ExactOnce -Name 'hostile attack telegraph and impact renderer' -Old $helperOld -New $helperNew

if (([regex]::Matches($text, 'call DrawHostileAttackPresentation')).Count -ne 1) {
    throw 'Expected exactly one hostile attack presentation draw hook.'
}
if (-not $text.Contains('hostile_attack_draw_impact:')) {
    throw 'Prepared source is missing the hostile impact presentation path.'
}
if (-not $text.Contains('ATTACK_WARDEN_X')) {
    throw 'Prepared source is missing authored hostile attack source constants.'
}

if ($CheckOnly) {
    Write-Host 'Hostile attack presentation patch anchors are valid. No files changed (-CheckOnly).'
    exit 0
}

if ($hadCrLf) {
    $text = $text.Replace("`n", "`r`n")
}
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($runtimePath, $text, $utf8NoBom)
Write-Host "Patched $runtimePath"

if (-not $SkipHarness) {
    if (-not (Test-Path -LiteralPath $harnessPath)) {
        throw "Missing hostile attack presentation harness after patch: $harnessPath"
    }
    & powershell -ExecutionPolicy Bypass -File $harnessPath -RepoRoot $RepoRoot
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
