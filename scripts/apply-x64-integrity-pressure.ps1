param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$CheckOnly,
    [switch]$SkipHarness
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$runtimePath = Join-Path $RepoRoot 'src\bootx64.asm'
$specPath = Join-Path $RepoRoot 'assets\x64_combat.psd1'
$harnessPath = Join-Path $RepoRoot 'scripts\x64-integrity-harness.ps1'
foreach ($requiredPath in @($runtimePath, $specPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Missing required file: $requiredPath"
    }
}

$combat = (Import-PowerShellDataFile -Path $specPath).Combat
$text = Get-Content -Raw -LiteralPath $runtimePath
$hadCrLf = $text.Contains("`r`n")
$text = $text.Replace("`r`n", "`n")

$marker = 'UpdateHostilePressure PROC'
$rankMarker = "LevelRankLine db 'RANK C',0"
if ($text.Contains($marker)) {
    if (-not $text.Contains($rankMarker)) {
        throw 'An older Integrity Pressure patch is present without mission-rank support. Restore/rebase bootx64.asm, then apply the current codemod so the runtime remains deterministic.'
    }
    Write-Host 'x64 Integrity Pressure + mission-rank patch is already present.'
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
        throw "Patch anchor '$Name' was not found. bootx64.asm has drifted; inspect before applying."
    }
    $second = $script:text.IndexOf($Old, $first + $Old.Length, [System.StringComparison]::Ordinal)
    if ($second -ge 0) {
        throw "Patch anchor '$Name' is ambiguous; found more than once."
    }

    $script:text = $script:text.Substring(0, $first) + $New + $script:text.Substring($first + $Old.Length)
    Write-Host ("Prepared: {0}" -f $Name)
}

function Replace-ExactCount {
    param([string]$Name, [string]$Old, [string]$New, [int]$ExpectedCount)

    $count = ([regex]::Matches($script:text, [regex]::Escape($Old))).Count
    if ($count -ne $ExpectedCount) {
        throw "Patch anchor '$Name' expected $ExpectedCount occurrence(s), found $count."
    }
    $script:text = $script:text.Replace($Old, $New)
    Write-Host ("Prepared: {0} ({1} occurrence(s))" -f $Name, $count)
}

$constantOld = @'
PLAYER_WORLD_MAX_Z            equ 000001A4h
CROSSHAIR_MIN_X               equ 00000050h
'@
$constantNew = @"
PLAYER_WORLD_MAX_Z            equ 000001A4h
PLAYER_INTEGRITY_MAX          equ $([int]$combat.IntegrityMax)
PRESSURE_ENGAGE_Z             equ $([int]$combat.EngageWorldZ)
PRESSURE_INITIAL_GRACE_TICKS  equ $([int]$combat.InitialGraceTicks)
PRESSURE_MOVE_GRACE_TICKS     equ $([int]$combat.MoveGraceTicks)
PRESSURE_EXPOSURE_TICKS       equ $([int]$combat.ExposureTicksPerHit)
PRESSURE_WARN_TICKS           equ $([int]$combat.ExposureWarningTicks)
PRESSURE_DAMAGE_COOLDOWN      equ $([int]$combat.DamageCooldownTicks)
PRESSURE_DAMAGE_FLASH_TICKS   equ $([int]$combat.DamageFlashTicks)
PRESSURE_REBOOT_NOTICE_TICKS  equ $([int]$combat.RebootNoticeTicks)
RANK_A_INTEGRITY              equ $([int]$combat.Rank.ARequiresIntegrity)
RANK_A_SHOTS_PER_HIT          equ $([int]$combat.Rank.AMaxShotsPerHit)
RANK_B_INTEGRITY              equ $([int]$combat.Rank.BRequiresIntegrity)
RANK_B_SHOTS_PER_HIT          equ $([int]$combat.Rank.BMaxShotsPerHit)
RANK_DEFAULT_CHAR             equ '$($combat.Rank.DefaultRank)'
CROSSHAIR_MIN_X               equ 00000050h
"@
Replace-ExactOnce -Name 'integrity and rank tuning constants' -Old $constantOld -New $constantNew

$inputOld = @'
    call UpdateLevelObjective
    or r13d, eax
    inc dword ptr [LevelPulseTicks]
'@
$inputNew = @'
    call UpdateLevelObjective
    or r13d, eax
    call UpdateHostilePressure
    or r13d, eax
    inc dword ptr [LevelPulseTicks]
'@
Replace-ExactOnce -Name 'pressure input tick' -Old $inputOld -New $inputNew

$resetOld = @'
    mov dword ptr [MissionHits], 0
    mov dword ptr [LevelPulseTicks], 0
    mov dword ptr [PointerLeftLatch], 0
'@
$resetNew = @'
    mov dword ptr [MissionHits], 0
    mov dword ptr [LevelPulseTicks], 0
    mov dword ptr [PlayerIntegrity], PLAYER_INTEGRITY_MAX
    mov dword ptr [ExposureTicks], 0
    mov dword ptr [MovementGraceTicks], PRESSURE_INITIAL_GRACE_TICKS
    mov dword ptr [DamageCooldownTicks], 0
    mov dword ptr [DamageFlashTicks], 0
    mov dword ptr [RebootNoticeTicks], 0
    mov dword ptr [PressureLastX], 0
    mov dword ptr [PressureLastZ], 0
    mov dword ptr [PointerLeftLatch], 0
'@
Replace-ExactOnce -Name 'mission integrity reset' -Old $resetOld -New $resetNew

$formatOld = @'
    mov ecx, dword ptr [MissionHits]
    lea rdx, LevelStatusLine + 16
    mov r8d, 4
    call WriteHex32

    add rsp, 20h
'@
$formatNew = @'
    mov ecx, dword ptr [MissionHits]
    lea rdx, LevelStatusLine + 16
    mov r8d, 4
    call WriteHex32

    mov eax, dword ptr [PlayerIntegrity]
    add al, '0'
    mov byte ptr [LevelStatusLine + 25], al

    ; Completion rank rewards clean movement and accuracy using stats the x64
    ; slice already tracks. No division is needed: compare shots against simple
    ; hit multiples for predictable bare-metal behavior.
    mov al, RANK_DEFAULT_CHAR
    cmp dword ptr [ObjectiveState], 3
    jb format_rank_store
    cmp dword ptr [MissionShots], 0
    je format_rank_store

    cmp dword ptr [PlayerIntegrity], PLAYER_INTEGRITY_MAX
    jne format_rank_a_check
    mov ecx, dword ptr [MissionShots]
    cmp ecx, dword ptr [MissionHits]
    jne format_rank_a_check
    mov al, 'S'
    jmp format_rank_store

format_rank_a_check:
    cmp dword ptr [PlayerIntegrity], RANK_A_INTEGRITY
    jb format_rank_b_check
    mov ecx, dword ptr [MissionHits]
    imul ecx, RANK_A_SHOTS_PER_HIT
    cmp ecx, dword ptr [MissionShots]
    jb format_rank_b_check
    mov al, 'A'
    jmp format_rank_store

format_rank_b_check:
    cmp dword ptr [PlayerIntegrity], RANK_B_INTEGRITY
    jb format_rank_store
    mov ecx, dword ptr [MissionHits]
    imul ecx, RANK_B_SHOTS_PER_HIT
    cmp ecx, dword ptr [MissionShots]
    jb format_rank_store
    mov al, 'B'

format_rank_store:
    mov byte ptr [LevelRankLine + 5], al

    add rsp, 20h
'@
Replace-ExactOnce -Name 'integrity and completion-rank HUD formatter' -Old $formatOld -New $formatNew

Replace-ExactOnce `
    -Name 'integrity and rank HUD text' `
    -Old "LevelStatusLine db 'SHOTS 0000 HITS 0000',0" `
    -New @"
LevelStatusLine db 'SHOTS 0000 HITS 0000 INT 3',0
LevelPressureLine db 'HOSTILE LOCK',0
LevelImpactLine db 'INTEGRITY HIT',0
LevelRebootLine db 'LINK RESET',0
LevelRankLine db 'RANK $($combat.Rank.DefaultRank)',0
"@

$dataOld = @'
ObjectiveState dd 0
ShotFlashTicks dd 0
'@
$dataNew = @'
ObjectiveState dd 0
PlayerIntegrity dd 3
ExposureTicks dd 0
MovementGraceTicks dd 0
DamageCooldownTicks dd 0
DamageFlashTicks dd 0
RebootNoticeTicks dd 0
PressureLastX dd 0
PressureLastZ dd 0
ShotFlashTicks dd 0
'@
Replace-ExactOnce -Name 'integrity runtime state' -Old $dataOld -New $dataNew

$helperOld = 'UpdateHostileObjective PROC'
$helperNew = @'
UpdateHostilePressure PROC
    ; Presentation timers run independently of combat pressure.
    cmp dword ptr [DamageFlashTicks], 0
    je pressure_reboot_tick
    dec dword ptr [DamageFlashTicks]
pressure_reboot_tick:
    cmp dword ptr [RebootNoticeTicks], 0
    je pressure_detect_move
    dec dword ptr [RebootNoticeTicks]

pressure_detect_move:
    mov eax, dword ptr [PlayerWorldX]
    cmp eax, dword ptr [PressureLastX]
    jne pressure_player_moved
    mov eax, dword ptr [PlayerWorldZ]
    cmp eax, dword ptr [PressureLastZ]
    jne pressure_player_moved

    cmp dword ptr [DamageCooldownTicks], 0
    je pressure_check_grace
    dec dword ptr [DamageCooldownTicks]
    mov dword ptr [ExposureTicks], 0
    xor eax, eax
    ret

pressure_check_grace:
    cmp dword ptr [MovementGraceTicks], 0
    je pressure_check_engagement
    dec dword ptr [MovementGraceTicks]
    mov dword ptr [ExposureTicks], 0
    xor eax, eax
    ret

pressure_check_engagement:
    mov eax, dword ptr [PlayerWorldZ]
    cmp eax, PRESSURE_ENGAGE_Z
    jl pressure_clear_lock

    cmp dword ptr [EnemyAlive], 0
    jne pressure_build_lock
    cmp dword ptr [SentryLeftAlive], 0
    jne pressure_build_lock
    cmp dword ptr [SentryRightAlive], 0
    jne pressure_build_lock
    jmp pressure_clear_lock

pressure_build_lock:
    inc dword ptr [ExposureTicks]
    mov eax, dword ptr [ExposureTicks]
    cmp eax, PRESSURE_EXPOSURE_TICKS
    jb pressure_no_redraw

    mov dword ptr [ExposureTicks], 0
    mov dword ptr [DamageCooldownTicks], PRESSURE_DAMAGE_COOLDOWN
    mov dword ptr [DamageFlashTicks], PRESSURE_DAMAGE_FLASH_TICKS
    cmp dword ptr [PlayerIntegrity], 0
    jle pressure_integrity_fail
    dec dword ptr [PlayerIntegrity]
    cmp dword ptr [PlayerIntegrity], 0
    jle pressure_integrity_fail
    mov eax, 1
    ret

pressure_integrity_fail:
    ; Keep the first failure state cheap and legible: reboot LEVEL 01 using its
    ; existing deterministic reset path, then leave a short HUD notice.
    call StartFirstLevel
    mov dword ptr [RebootNoticeTicks], PRESSURE_REBOOT_NOTICE_TICKS
    mov dword ptr [DamageFlashTicks], PRESSURE_DAMAGE_FLASH_TICKS
    mov eax, 1
    ret

pressure_player_moved:
    mov eax, dword ptr [PlayerWorldX]
    mov dword ptr [PressureLastX], eax
    mov eax, dword ptr [PlayerWorldZ]
    mov dword ptr [PressureLastZ], eax
    mov dword ptr [ExposureTicks], 0
    mov dword ptr [MovementGraceTicks], PRESSURE_MOVE_GRACE_TICKS
    xor eax, eax
    ret

pressure_clear_lock:
    mov dword ptr [ExposureTicks], 0
pressure_no_redraw:
    xor eax, eax
    ret
UpdateHostilePressure ENDP

DrawIntegrityThreat PROC
    sub rsp, 20h

    cmp dword ptr [ObjectiveState], 3
    jae integrity_draw_rank
    cmp dword ptr [RebootNoticeTicks], 0
    jne integrity_draw_reboot
    cmp dword ptr [DamageFlashTicks], 0
    jne integrity_draw_impact
    mov eax, dword ptr [ExposureTicks]
    cmp eax, PRESSURE_WARN_TICKS
    jb integrity_draw_done

    mov ecx, 376
    mov edx, 34
    lea r8, LevelPressureLine
    mov r9d, DIAG_WARN
    call DrawString
    jmp integrity_draw_done

integrity_draw_impact:
    mov ecx, 376
    mov edx, 34
    lea r8, LevelImpactLine
    mov r9d, 00FF4058h
    call DrawString
    jmp integrity_draw_done

integrity_draw_reboot:
    mov ecx, 376
    mov edx, 34
    lea r8, LevelRebootLine
    mov r9d, 00FF4058h
    call DrawString
    jmp integrity_draw_done

integrity_draw_rank:
    mov ecx, 376
    mov edx, 34
    lea r8, LevelRankLine
    mov r9d, DIAG_OK
    call DrawString

integrity_draw_done:
    add rsp, 20h
    ret
DrawIntegrityThreat ENDP

UpdateHostileObjective PROC
'@
Replace-ExactOnce -Name 'integrity pressure and rank runtime' -Old $helperOld -New $helperNew

$statusDrawOld = @'
    lea r8, LevelStatusLine
    mov r9d, DIAG_WARN
    call DrawString
'@
$statusDrawNew = @'
    lea r8, LevelStatusLine
    mov r9d, DIAG_WARN
    call DrawString
    call DrawIntegrityThreat
'@
Replace-ExactCount -Name 'integrity threat/rank HUD hook' -Old $statusDrawOld -New $statusDrawNew -ExpectedCount 2

$runtimeCalls = ([regex]::Matches($text, 'call UpdateHostilePressure')).Count
$hudCalls = ([regex]::Matches($text, 'call DrawIntegrityThreat')).Count
if ($runtimeCalls -ne 1) {
    throw "Expected one UpdateHostilePressure call after patch preparation; found $runtimeCalls."
}
if ($hudCalls -ne 2) {
    throw "Expected two DrawIntegrityThreat calls after patch preparation; found $hudCalls."
}
if (-not $text.Contains("LevelStatusLine db 'SHOTS 0000 HITS 0000 INT 3',0")) {
    throw 'Prepared source is missing the integrity HUD field.'
}
if (-not $text.Contains($rankMarker)) {
    throw 'Prepared source is missing the mission-rank HUD field.'
}
if (-not $text.Contains('pressure_integrity_fail:')) {
    throw 'Prepared source is missing the integrity failure path.'
}
if (-not $text.Contains('format_rank_a_check:') -or -not $text.Contains('format_rank_b_check:')) {
    throw 'Prepared source is missing the completion-rank calculation.'
}

if ($CheckOnly) {
    Write-Host 'Integrity pressure + mission-rank patch anchors are valid. No files changed (-CheckOnly).'
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
        throw "Missing integrity harness after patch: $harnessPath"
    }
    & powershell -ExecutionPolicy Bypass -File $harnessPath -RepoRoot $RepoRoot
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
