param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$CheckOnly,
    [switch]$SkipHarness
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$runtimePath = Join-Path $RepoRoot 'src\bootx64.asm'
$specPath = Join-Path $RepoRoot 'assets\x64_attack_events.psd1'
$harnessPath = Join-Path $RepoRoot 'scripts\x64-attack-events-harness.ps1'
foreach ($requiredPath in @($runtimePath, $specPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Missing required file: $requiredPath"
    }
}

$events = (Import-PowerShellDataFile -Path $specPath).AttackEvents
$text = Get-Content -Raw -LiteralPath $runtimePath
$hadCrLf = $text.Contains("`r`n")
$text = $text.Replace("`r`n", "`n")

if (-not $text.Contains('UpdateHostilePressure PROC')) {
    throw 'Hostile attack events require the x64 integrity-pressure patch first.'
}
if (-not $text.Contains('DrawHostileAttackPresentation PROC')) {
    throw 'Hostile attack events require the x64 hostile-attack presentation patch first.'
}

$marker = 'SelectHostileAttackSource PROC'
if ($text.Contains($marker)) {
    Write-Host 'x64 hostile attack-event patch is already present.'
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
        throw "Attack-event patch anchor '$Name' was not found. Patched bootx64.asm has drifted; inspect before applying."
    }
    $second = $script:text.IndexOf($Old, $first + $Old.Length, [System.StringComparison]::Ordinal)
    if ($second -ge 0) {
        throw "Attack-event patch anchor '$Name' is ambiguous; found more than once."
    }
    $script:text = $script:text.Substring(0, $first) + $New + $script:text.Substring($first + $Old.Length)
    Write-Host ("Prepared: {0}" -f $Name)
}

function Format-MasmHex {
    param([int]$Value)
    return ('{0:X8}h' -f ([uint32]$Value))
}

$sources = @($events.Sources)
if ($sources.Count -ne 3) {
    throw "Expected exactly three hostile attack-event sources; found $($sources.Count)."
}
$warden = $sources | Where-Object { $_.Id -eq 'warden' } | Select-Object -First 1
$left = $sources | Where-Object { $_.Id -eq 'sentry-left' } | Select-Object -First 1
$right = $sources | Where-Object { $_.Id -eq 'sentry-right' } | Select-Object -First 1
if ($null -eq $warden -or $null -eq $left -or $null -eq $right) {
    throw 'Attack-event source set must contain warden, sentry-left, and sentry-right.'
}

$constantAnchor = 'ATTACK_WARDEN_X               equ '
$constantIndex = $text.IndexOf($constantAnchor, [System.StringComparison]::Ordinal)
if ($constantIndex -lt 0) {
    throw 'Attack-event constants require the hostile-presentation constants to be present.'
}
$eventConstants = @"
ATTACK_EVENT_NONE             equ 0
ATTACK_EVENT_WARDEN           equ $([int]$warden.SourceId)
ATTACK_EVENT_LEFT             equ $([int]$left.SourceId)
ATTACK_EVENT_RIGHT            equ $([int]$right.SourceId)
ATTACK_EVENT_TRACE_TICKS      equ $([int]$events.TraceTicks)
ATTACK_EVENT_TRACE_COLOR      equ $(Format-MasmHex -Value ([int]$events.TraceColor))
ATTACK_EVENT_MUZZLE_HALF      equ $([int]$events.MuzzleHalfSize)
"@
$text = $text.Substring(0, $constantIndex) + $eventConstants + $text.Substring($constantIndex)
Write-Host 'Prepared: hostile attack-event constants'

$resetOld = @'
    mov dword ptr [PressureLastX], 0
    mov dword ptr [PressureLastZ], 0
    mov dword ptr [PointerLeftLatch], 0
'@
$resetNew = @'
    mov dword ptr [PressureLastX], 0
    mov dword ptr [PressureLastZ], 0
    mov dword ptr [AttackSourceCursor], 0
    mov dword ptr [LastAttackSource], ATTACK_EVENT_NONE
    mov dword ptr [AttackEventTicks], 0
    mov dword ptr [PointerLeftLatch], 0
'@
Replace-ExactOnce -Name 'attack-event mission reset state' -Old $resetOld -New $resetNew

$dataOld = @'
PressureLastX dd 0
PressureLastZ dd 0
ShotFlashTicks dd 0
'@
$dataNew = @'
PressureLastX dd 0
PressureLastZ dd 0
AttackSourceCursor dd 0
LastAttackSource dd 0
AttackEventTicks dd 0
ShotFlashTicks dd 0
'@
Replace-ExactOnce -Name 'attack-event runtime state' -Old $dataOld -New $dataNew

$timerOld = @'
UpdateHostilePressure PROC
    ; Presentation timers run independently of combat pressure.
    cmp dword ptr [DamageFlashTicks], 0
'@
$timerNew = @'
UpdateHostilePressure PROC
    ; Presentation timers run independently of combat pressure.
    cmp dword ptr [AttackEventTicks], 0
    je pressure_damage_flash_tick
    dec dword ptr [AttackEventTicks]
pressure_damage_flash_tick:
    cmp dword ptr [DamageFlashTicks], 0
'@
Replace-ExactOnce -Name 'attack-event trace timer' -Old $timerOld -New $timerNew

$damageOld = @'
    mov dword ptr [ExposureTicks], 0
    mov dword ptr [DamageCooldownTicks], PRESSURE_DAMAGE_COOLDOWN
    mov dword ptr [DamageFlashTicks], PRESSURE_DAMAGE_FLASH_TICKS
    cmp dword ptr [PlayerIntegrity], 0
'@
$damageNew = @'
    mov dword ptr [ExposureTicks], 0
    mov dword ptr [DamageCooldownTicks], PRESSURE_DAMAGE_COOLDOWN
    call SelectHostileAttackSource
    mov dword ptr [AttackEventTicks], ATTACK_EVENT_TRACE_TICKS
    mov dword ptr [DamageFlashTicks], PRESSURE_DAMAGE_FLASH_TICKS
    cmp dword ptr [PlayerIntegrity], 0
'@
Replace-ExactOnce -Name 'attribute existing pressure hit to a live hostile' -Old $damageOld -New $damageNew

$helperOld = 'DrawHostileAttackPresentation PROC'
$helperNew = @'
SelectHostileAttackSource PROC
    ; Rotate through the three authored actors, skipping dead slots. The selected
    ; source owns the next existing pressure hit; damage timing itself is unchanged.
    mov ecx, dword ptr [AttackSourceCursor]
    mov edx, 3

attack_source_select_loop:
    cmp ecx, 0
    jne attack_source_check_left
    cmp dword ptr [EnemyAlive], 0
    jne attack_source_select_warden
    jmp attack_source_advance

attack_source_check_left:
    cmp ecx, 1
    jne attack_source_check_right
    cmp dword ptr [SentryLeftAlive], 0
    jne attack_source_select_left
    jmp attack_source_advance

attack_source_check_right:
    cmp dword ptr [SentryRightAlive], 0
    jne attack_source_select_right

attack_source_advance:
    inc ecx
    cmp ecx, 3
    jb attack_source_advance_ready
    xor ecx, ecx
attack_source_advance_ready:
    dec edx
    jnz attack_source_select_loop

    mov dword ptr [LastAttackSource], ATTACK_EVENT_NONE
    mov dword ptr [AttackSourceCursor], ecx
    xor eax, eax
    ret

attack_source_select_warden:
    mov eax, ATTACK_EVENT_WARDEN
    jmp attack_source_selected
attack_source_select_left:
    mov eax, ATTACK_EVENT_LEFT
    jmp attack_source_selected
attack_source_select_right:
    mov eax, ATTACK_EVENT_RIGHT

attack_source_selected:
    mov dword ptr [LastAttackSource], eax
    inc ecx
    cmp ecx, 3
    jb attack_source_cursor_ready
    xor ecx, ecx
attack_source_cursor_ready:
    mov dword ptr [AttackSourceCursor], ecx
    ret
SelectHostileAttackSource ENDP

DrawHostileAttackEvent PROC
    push r12
    push r13
    sub rsp, 20h

    cmp dword ptr [AttackEventTicks], 0
    je hostile_attack_event_done
    mov eax, dword ptr [LastAttackSource]
    cmp eax, ATTACK_EVENT_WARDEN
    je hostile_attack_event_warden
    cmp eax, ATTACK_EVENT_LEFT
    je hostile_attack_event_left
    cmp eax, ATTACK_EVENT_RIGHT
    je hostile_attack_event_right
    jmp hostile_attack_event_done

hostile_attack_event_warden:
    mov ecx, ATTACK_WARDEN_X
    mov edx, ATTACK_WARDEN_Y
    mov r8d, ATTACK_WARDEN_Z
    jmp hostile_attack_event_project
hostile_attack_event_left:
    mov ecx, ATTACK_LEFT_X
    mov edx, ATTACK_LEFT_Y
    mov r8d, ATTACK_LEFT_Z
    jmp hostile_attack_event_project
hostile_attack_event_right:
    mov ecx, ATTACK_RIGHT_X
    mov edx, ATTACK_RIGHT_Y
    mov r8d, ATTACK_RIGHT_Z

hostile_attack_event_project:
    call ProjectLevelPoint3D
    mov r12d, eax
    mov r13d, edx

    ; Brief yellow-white trace identifies the actor that actually owned the hit.
    mov ecx, r12d
    mov edx, r13d
    mov r8d, ATTACK_LOCK_TARGET_X
    mov r9d, ATTACK_LOCK_TARGET_Y
    mov eax, ATTACK_EVENT_TRACE_COLOR
    call DrawGopLine

    ; Small muzzle cross keeps the source readable even when the trace overlaps
    ; one of the magenta acquisition beams.
    mov ecx, r12d
    sub ecx, ATTACK_EVENT_MUZZLE_HALF
    mov edx, r13d
    mov r8d, r12d
    add r8d, ATTACK_EVENT_MUZZLE_HALF
    mov r9d, r13d
    mov eax, ATTACK_EVENT_TRACE_COLOR
    call DrawGopLine
    mov ecx, r12d
    mov edx, r13d
    sub edx, ATTACK_EVENT_MUZZLE_HALF
    mov r8d, r12d
    mov r9d, r13d
    add r9d, ATTACK_EVENT_MUZZLE_HALF
    mov eax, ATTACK_EVENT_TRACE_COLOR
    call DrawGopLine

hostile_attack_event_done:
    add rsp, 20h
    pop r13
    pop r12
    ret
DrawHostileAttackEvent ENDP

DrawHostileAttackPresentation PROC
'@
Replace-ExactOnce -Name 'hostile attack source selector and event renderer' -Old $helperOld -New $helperNew

$impactOld = @'
hostile_attack_draw_impact:
    ; Damage is a hard visual event: frame the viewport and flash the player-view
'@
$impactNew = @'
hostile_attack_draw_impact:
    call DrawHostileAttackEvent
    ; Damage is a hard visual event: frame the viewport and flash the player-view
'@
Replace-ExactOnce -Name 'render attributed hostile shot during impact feedback' -Old $impactOld -New $impactNew

if (([regex]::Matches($text, 'call SelectHostileAttackSource')).Count -ne 1) {
    throw 'Expected exactly one hostile attack-source selection call.'
}
if (([regex]::Matches($text, 'call DrawHostileAttackEvent')).Count -ne 1) {
    throw 'Expected exactly one hostile attack-event draw hook.'
}
if (-not $text.Contains('LastAttackSource dd 0')) {
    throw 'Prepared source is missing hostile attack-source state.'
}
if (-not $text.Contains('ATTACK_EVENT_TRACE_TICKS')) {
    throw 'Prepared source is missing attack-event trace tuning.'
}

if ($CheckOnly) {
    Write-Host 'Hostile attack-event patch anchors are valid. No files changed (-CheckOnly).'
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
        throw "Missing hostile attack-event harness after patch: $harnessPath"
    }
    & powershell -ExecutionPolicy Bypass -File $harnessPath -RepoRoot $RepoRoot
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
