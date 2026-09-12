param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$CheckOnly,
    [switch]$SkipHarness
)

$ErrorActionPreference = 'Stop'

$runtimePath = Join-Path $RepoRoot 'src\bootx64.asm'
$harnessPath = Join-Path $RepoRoot 'scripts\x64-encounter-harness.ps1'

if (-not (Test-Path -LiteralPath $runtimePath)) {
    throw "Missing runtime source: $runtimePath"
}

$text = Get-Content -Raw -LiteralPath $runtimePath
$hadCrLf = $text.Contains("`r`n")
$text = $text.Replace("`r`n", "`n")

$marker = 'terminal_trace_response:'
if ($text.Contains($marker)) {
    Write-Host 'x64 Breach Response patch is already present.'
    if (-not $SkipHarness -and (Test-Path -LiteralPath $harnessPath)) {
        & powershell -ExecutionPolicy Bypass -File $harnessPath -RepoRoot $RepoRoot
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    exit 0
}

function Replace-ExactOnce {
    param(
        [string]$Name,
        [string]$Old,
        [string]$New
    )

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

$helperOld = @'
ReturnToTitle ENDP

UpdateHostileObjective PROC
'@
$helperNew = @'
ReturnToTitle ENDP

StartTerminalTraceResponse PROC
terminal_trace_response:
    ; First x64 response beat deliberately reuses the existing side-sentry slots.
    ; Their rendering, hit testing, HUD pips, and shadows are already proven.
    mov dword ptr [SentryLeftHp], 1
    mov dword ptr [SentryLeftAlive], 1
    mov dword ptr [SentryRightHp], 1
    mov dword ptr [SentryRightAlive], 1
    mov dword ptr [HitFlashTicks], 10
    ret
StartTerminalTraceResponse ENDP

UpdateHostileObjective PROC
'@
Replace-ExactOnce -Name 'response helper' -Old $helperOld -New $helperNew

$fireOld = @'
fire_terminal_hit:
    inc dword ptr [MissionHits]
    mov dword ptr [HitFlashTicks], 10
    mov dword ptr [ObjectiveState], 2

fire_done:
'@
$fireNew = @'
fire_terminal_hit:
    inc dword ptr [MissionHits]
    mov dword ptr [HitFlashTicks], 10
    mov dword ptr [ObjectiveState], 2
    call StartTerminalTraceResponse

fire_done:
'@
Replace-ExactOnce -Name 'fired terminal breach response' -Old $fireOld -New $fireNew

$proximityOld = @'
objective_terminal_breach:
    mov dword ptr [ObjectiveState], 2
    mov dword ptr [HitFlashTicks], 10
    mov ecx, 1
    jmp objective_done
'@
$proximityNew = @'
objective_terminal_breach:
    mov dword ptr [ObjectiveState], 2
    mov dword ptr [HitFlashTicks], 10
    call StartTerminalTraceResponse
    mov ecx, 1
    jmp objective_done
'@
Replace-ExactOnce -Name 'proximity terminal breach response' -Old $proximityOld -New $proximityNew

$exitOld = @'
objective_exit_complete:
    mov dword ptr [ObjectiveState], 3
    mov dword ptr [HitFlashTicks], 12
    mov ecx, 1
'@
$exitNew = @'
objective_exit_complete:
    ; TRACE response gate: extraction stays locked until both rebooted sentries are down.
    cmp dword ptr [SentryLeftAlive], 0
    jne objective_done
    cmp dword ptr [SentryRightAlive], 0
    jne objective_done
    mov dword ptr [ObjectiveState], 3
    mov dword ptr [HitFlashTicks], 12
    mov ecx, 1
'@
Replace-ExactOnce -Name 'response extraction gate' -Old $exitOld -New $exitNew

$exitVisualOld = @'
    cmp dword ptr [ObjectiveState], 2
    jb draw_exit_locked
    FILL_GOP_RECT 492, 294, 74, 82, 000B1924h
'@
$exitVisualNew = @'
    cmp dword ptr [ObjectiveState], 2
    jb draw_exit_locked
    ; TRACE response visual gate: do not paint an open exit while response sentries live.
    cmp dword ptr [SentryLeftAlive], 0
    jne draw_exit_locked
    cmp dword ptr [SentryRightAlive], 0
    jne draw_exit_locked
    FILL_GOP_RECT 492, 294, 74, 82, 000B1924h
'@
Replace-ExactOnce -Name 'response exit visual gate' -Old $exitVisualOld -New $exitVisualNew

$exitLabelOld = @'
    lea r8, LevelExitLine
    mov r9d, DIAG_MUTED
    cmp dword ptr [ObjectiveState], 2
    jb draw_exit_label
    mov r9d, DIAG_OK
draw_exit_label:
'@
$exitLabelNew = @'
    lea r8, LevelExitLine
    mov r9d, DIAG_MUTED
    cmp dword ptr [ObjectiveState], 2
    jb draw_exit_label
    cmp dword ptr [SentryLeftAlive], 0
    jne draw_exit_label
    cmp dword ptr [SentryRightAlive], 0
    jne draw_exit_label
    mov r9d, DIAG_OK
draw_exit_label:
'@
Replace-ExactOnce -Name 'response exit label state' -Old $exitLabelOld -New $exitLabelNew

Replace-ExactOnce `
    -Name 'TRACE objective prompt' `
    -Old "LevelObjectiveExitLine db 'REACH EXIT GATE',0" `
    -New "LevelObjectiveExitLine db 'BREAK TRACE / REACH EXIT',0"

Replace-ExactOnce `
    -Name 'TRACE status read' `
    -Old "LevelExitOpenLine db 'EXIT ROUTE OPEN',0" `
    -New "LevelExitOpenLine db 'TRACE RESPONSE',0"

Replace-ExactOnce `
    -Name 'mission loop tagline' `
    -Old "LevelLoopLine db 'DOWN WARDEN BREACH EXTRACT',0" `
    -New "LevelLoopLine db 'DOWN WARDEN BREACH TRACE EXTRACT',0"

$callCount = ([regex]::Matches($text, 'call StartTerminalTraceResponse')).Count
if ($callCount -ne 2) {
    throw "Expected exactly two response calls after patch preparation; found $callCount."
}
if (-not $text.Contains('; TRACE response gate: extraction stays locked until both rebooted sentries are down.')) {
    throw 'Prepared source is missing the extraction-gate marker.'
}
if (-not $text.Contains('; TRACE response visual gate: do not paint an open exit while response sentries live.')) {
    throw 'Prepared source is missing the visual exit-gate marker.'
}
if (-not $text.Contains("LevelObjectiveExitLine db 'BREAK TRACE / REACH EXIT',0")) {
    throw 'Prepared source is missing the TRACE objective prompt.'
}
if (-not $text.Contains("LevelExitOpenLine db 'TRACE RESPONSE',0")) {
    throw 'Prepared source is missing the TRACE status read.'
}

if ($CheckOnly) {
    Write-Host 'Patch anchors are valid. No files changed (-CheckOnly).'
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
        throw "Missing encounter harness after patch: $harnessPath"
    }
    & powershell -ExecutionPolicy Bypass -File $harnessPath -RepoRoot $RepoRoot
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
