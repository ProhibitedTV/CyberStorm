param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$CheckOnly,
    [switch]$SkipHarness
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$runtimePath = Join-Path $RepoRoot 'src\bootx64.asm'
$specPath = Join-Path $RepoRoot 'assets\x64_cover.psd1'
$harnessPath = Join-Path $RepoRoot 'scripts\x64-cover-harness.ps1'
foreach ($requiredPath in @($runtimePath, $specPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Missing required file: $requiredPath"
    }
}

$cover = (Import-PowerShellDataFile -Path $specPath).Cover
$text = Get-Content -Raw -LiteralPath $runtimePath
$hadCrLf = $text.Contains("`r`n")
$text = $text.Replace("`r`n", "`n")

if (-not $text.Contains('UpdateHostilePressure PROC')) {
    throw 'x64 cover requires the integrity-pressure patch first.'
}
if (-not $text.Contains('SelectHostileAttackSource PROC')) {
    throw 'x64 cover is ordered after the attributed hostile-shot patch in the production validation lane.'
}

$marker = 'UpdatePlayerCoverState PROC'
if ($text.Contains($marker)) {
    Write-Host 'x64 visible-cover patch is already present.'
    if (-not $SkipHarness -and (Test-Path -LiteralPath $harnessPath)) {
        & powershell -ExecutionPolicy Bypass -File $harnessPath -RepoRoot $RepoRoot
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    exit 0
}

function Replace-ExactOnce {
    param([string]$Name, [string]$Old, [string]$New)
    $first = $script:text.IndexOf($Old, [System.StringComparison]::Ordinal)
    if ($first -lt 0) { throw "Cover patch anchor '$Name' was not found. Patched bootx64.asm has drifted; inspect before applying." }
    $second = $script:text.IndexOf($Old, $first + $Old.Length, [System.StringComparison]::Ordinal)
    if ($second -ge 0) { throw "Cover patch anchor '$Name' is ambiguous; found more than once." }
    $script:text = $script:text.Substring(0, $first) + $New + $script:text.Substring($first + $Old.Length)
    Write-Host ("Prepared: {0}" -f $Name)
}

$zones = @($cover.Zones)
if ($zones.Count -ne 3) { throw "Expected exactly three visible cover zones; found $($zones.Count)." }
$left = $zones | Where-Object { $_.Id -eq 'front-left-pillar' } | Select-Object -First 1
$right = $zones | Where-Object { $_.Id -eq 'front-right-pillar' } | Select-Object -First 1
$center = $zones | Where-Object { $_.Id -eq 'mid-center-column' } | Select-Object -First 1
if ($null -eq $left -or $null -eq $right -or $null -eq $center) { throw 'Cover zones must contain front-left-pillar, front-right-pillar, and mid-center-column.' }

$constantAnchor = 'ATTACK_EVENT_NONE             equ 0'
$constantIndex = $text.IndexOf($constantAnchor, [System.StringComparison]::Ordinal)
if ($constantIndex -lt 0) { throw 'Cover constants require the attributed-shot runtime constants.' }
$coverConstants = @"
COVER_NONE                    equ 0
COVER_LEFT                    equ $([int]$left.StateId)
COVER_RIGHT                   equ $([int]$right.StateId)
COVER_CENTER                  equ $([int]$center.StateId)
COVER_LEFT_MIN_X              equ $([int]$left.MinX)
COVER_LEFT_MAX_X              equ $([int]$left.MaxX)
COVER_LEFT_MIN_Z              equ $([int]$left.MinZ)
COVER_LEFT_MAX_Z              equ $([int]$left.MaxZ)
COVER_RIGHT_MIN_X             equ $([int]$right.MinX)
COVER_RIGHT_MAX_X             equ $([int]$right.MaxX)
COVER_RIGHT_MIN_Z             equ $([int]$right.MinZ)
COVER_RIGHT_MAX_Z             equ $([int]$right.MaxZ)
COVER_CENTER_MIN_X            equ $([int]$center.MinX)
COVER_CENTER_MAX_X            equ $([int]$center.MaxX)
COVER_CENTER_MIN_Z            equ $([int]$center.MinZ)
COVER_CENTER_MAX_Z            equ $([int]$center.MaxZ)
"@
$text = $text.Substring(0, $constantIndex) + $coverConstants + $text.Substring($constantIndex)
Write-Host 'Prepared: visible-cover constants'

$resetOld = @'
    mov dword ptr [AttackSourceCursor], 0
    mov dword ptr [LastAttackSource], ATTACK_EVENT_NONE
    mov dword ptr [AttackEventTicks], 0
    mov dword ptr [PointerLeftLatch], 0
'@
$resetNew = @'
    mov dword ptr [AttackSourceCursor], 0
    mov dword ptr [LastAttackSource], ATTACK_EVENT_NONE
    mov dword ptr [AttackEventTicks], 0
    mov dword ptr [PlayerCoverState], COVER_NONE
    mov dword ptr [PointerLeftLatch], 0
'@
Replace-ExactOnce -Name 'cover mission reset state' -Old $resetOld -New $resetNew

$dataOld = @'
AttackSourceCursor dd 0
LastAttackSource dd 0
AttackEventTicks dd 0
ShotFlashTicks dd 0
'@
$dataNew = @'
AttackSourceCursor dd 0
LastAttackSource dd 0
AttackEventTicks dd 0
PlayerCoverState dd 0
ShotFlashTicks dd 0
'@
Replace-ExactOnce -Name 'cover runtime state' -Old $dataOld -New $dataNew

$helperOld = 'UpdateHostilePressure PROC'
$helperNew = @'
UpdatePlayerCoverState PROC
    mov dword ptr [PlayerCoverState], COVER_NONE
    mov eax, dword ptr [PlayerWorldX]
    mov ecx, dword ptr [PlayerWorldZ]

    cmp eax, COVER_LEFT_MIN_X
    jl cover_check_right
    cmp eax, COVER_LEFT_MAX_X
    jg cover_check_right
    cmp ecx, COVER_LEFT_MIN_Z
    jl cover_check_right
    cmp ecx, COVER_LEFT_MAX_Z
    jg cover_check_right
    mov dword ptr [PlayerCoverState], COVER_LEFT
    mov eax, COVER_LEFT
    ret

cover_check_right:
    mov eax, dword ptr [PlayerWorldX]
    cmp eax, COVER_RIGHT_MIN_X
    jl cover_check_center
    cmp eax, COVER_RIGHT_MAX_X
    jg cover_check_center
    cmp ecx, COVER_RIGHT_MIN_Z
    jl cover_check_center
    cmp ecx, COVER_RIGHT_MAX_Z
    jg cover_check_center
    mov dword ptr [PlayerCoverState], COVER_RIGHT
    mov eax, COVER_RIGHT
    ret

cover_check_center:
    mov eax, dword ptr [PlayerWorldX]
    cmp eax, COVER_CENTER_MIN_X
    jl cover_state_done
    cmp eax, COVER_CENTER_MAX_X
    jg cover_state_done
    cmp ecx, COVER_CENTER_MIN_Z
    jl cover_state_done
    cmp ecx, COVER_CENTER_MAX_Z
    jg cover_state_done
    mov dword ptr [PlayerCoverState], COVER_CENTER
    mov eax, COVER_CENTER
    ret

cover_state_done:
    xor eax, eax
    ret
UpdatePlayerCoverState ENDP

UpdateHostilePressure PROC
'@
Replace-ExactOnce -Name 'visible cover state resolver' -Old $helperOld -New $helperNew

$coverTickOld = @'
pressure_reboot_tick:
    cmp dword ptr [RebootNoticeTicks], 0
'@
$coverTickNew = @'
pressure_reboot_tick:
    call UpdatePlayerCoverState
    cmp dword ptr [RebootNoticeTicks], 0
'@
Replace-ExactOnce -Name 'refresh cover state every combat tick' -Old $coverTickOld -New $coverTickNew

$pressureOld = @'
pressure_check_engagement:
    mov eax, dword ptr [PlayerWorldZ]
    cmp eax, PRESSURE_ENGAGE_Z
    jl pressure_clear_lock

    cmp dword ptr [EnemyAlive], 0
'@
$pressureNew = @'
pressure_check_engagement:
    mov eax, dword ptr [PlayerWorldZ]
    cmp eax, PRESSURE_ENGAGE_Z
    jl pressure_clear_lock
    cmp dword ptr [PlayerCoverState], COVER_NONE
    jne pressure_clear_lock

    cmp dword ptr [EnemyAlive], 0
'@
Replace-ExactOnce -Name 'cover interrupts hostile exposure' -Old $pressureOld -New $pressureNew

$hudTextOld = "LevelPressureLine db 'HOSTILE LOCK',0"
$hudTextNew = @"
LevelPressureLine db 'HOSTILE LOCK',0
LevelCoverLine db '$($cover.HudText)',0
"@
Replace-ExactOnce -Name 'cover HUD text' -Old $hudTextOld -New $hudTextNew

$hudOld = @'
    cmp dword ptr [DamageFlashTicks], 0
    jne integrity_draw_impact
    mov eax, dword ptr [ExposureTicks]
    cmp eax, PRESSURE_WARN_TICKS
'@
$hudNew = @'
    cmp dword ptr [DamageFlashTicks], 0
    jne integrity_draw_impact
    cmp dword ptr [PlayerCoverState], COVER_NONE
    je integrity_draw_exposure_check
    cmp dword ptr [EnemyAlive], 0
    jne integrity_draw_cover
    cmp dword ptr [SentryLeftAlive], 0
    jne integrity_draw_cover
    cmp dword ptr [SentryRightAlive], 0
    jne integrity_draw_cover
    jmp integrity_draw_exposure_check

integrity_draw_cover:
    mov ecx, 376
    mov edx, 34
    lea r8, LevelCoverLine
    mov r9d, DIAG_OK
    call DrawString
    jmp integrity_draw_done

integrity_draw_exposure_check:
    mov eax, dword ptr [ExposureTicks]
    cmp eax, PRESSURE_WARN_TICKS
'@
Replace-ExactOnce -Name 'cover HUD feedback' -Old $hudOld -New $hudNew

if (([regex]::Matches($text, 'call UpdatePlayerCoverState')).Count -ne 1) { throw 'Expected exactly one cover-state update hook.' }
if (-not $text.Contains('PlayerCoverState dd 0')) { throw 'Prepared source is missing cover runtime state.' }
if (-not $text.Contains("LevelCoverLine db '$($cover.HudText)',0")) { throw 'Prepared source is missing cover HUD feedback.' }
if (-not $text.Contains('cmp dword ptr [PlayerCoverState], COVER_NONE')) { throw 'Prepared source is missing the pressure cover gate.' }

if ($CheckOnly) {
    Write-Host 'Visible-cover patch anchors are valid. No files changed (-CheckOnly).'
    exit 0
}

if ($hadCrLf) { $text = $text.Replace("`n", "`r`n") }
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($runtimePath, $text, $utf8NoBom)
Write-Host "Patched $runtimePath"

if (-not $SkipHarness) {
    if (-not (Test-Path -LiteralPath $harnessPath)) { throw "Missing cover harness after patch: $harnessPath" }
    & powershell -ExecutionPolicy Bypass -File $harnessPath -RepoRoot $RepoRoot
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
