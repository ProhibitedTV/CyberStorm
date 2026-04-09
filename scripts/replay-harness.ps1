param(
    [string]$SectorSourcePath = (Join-Path (Join-Path $PSScriptRoot '..') 'assets\sectors.psd1'),
    [string]$DemoSourcePath = (Join-Path (Join-Path $PSScriptRoot '..') 'assets\demos.psd1'),
    [string]$GeometrySourcePath = (Join-Path (Join-Path $PSScriptRoot '..') 'assets\geometry.psd1'),
    [string]$MusicSourcePath = (Join-Path (Join-Path $PSScriptRoot '..') 'assets\music.psd1'),
    [string]$ConstantsSourcePath = (Join-Path (Join-Path $PSScriptRoot '..') 'src\game\constants.inc'),
    [switch]$ExperimentalMusic,
    [switch]$SfxOnly,
    [string]$ReportPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm-replay-report.txt')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($ExperimentalMusic.IsPresent -and $SfxOnly.IsPresent) {
    throw 'Use either -ExperimentalMusic (legacy alias) or -SfxOnly, not both.'
}

$musicEnabled = -not $SfxOnly.IsPresent

function Assert-PathExists {
    param(
        [string]$Path,
        [string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw ("Missing {0}: {1}" -f $Label, $Path)
    }
}

function Import-StructuredDataFile {
    param(
        [string]$SourcePath,
        [string]$Label
    )

    Assert-PathExists -Path $SourcePath -Label $Label

    try {
        $data = Import-PowerShellDataFile -LiteralPath $SourcePath
    } catch {
        $rawText = Get-Content -LiteralPath $SourcePath -Raw
        $data = [scriptblock]::Create($rawText).InvokeReturnAsIs()
    }

    if (-not ($data -is [System.Collections.IDictionary])) {
        throw ("{0} must evaluate to a key/value table: {1}" -f $Label, $SourcePath)
    }

    return $data
}

function Get-AsmEquValue {
    param(
        [string]$SourcePath,
        [string]$Name
    )

    Assert-PathExists -Path $SourcePath -Label 'assembly constants source'
    $pattern = "^\s*{0}\s+equ\s+(-?[0-9A-Fa-f]+h|-?\d+)\s*(?:;.*)?$" -f [regex]::Escape($Name)
    $match = Select-String -LiteralPath $SourcePath -Pattern $pattern | Select-Object -First 1
    if (-not $match) {
        throw ("Could not find numeric '{0} equ <value>' in {1}" -f $Name, $SourcePath)
    }

    $token = $match.Matches[0].Groups[1].Value
    if ($token -match '^-?[0-9A-Fa-f]+h$') {
        $negative = $token.StartsWith('-')
        $digits = if ($negative) { $token.Substring(1, $token.Length - 2) } else { $token.Substring(0, $token.Length - 1) }
        $value = [Convert]::ToInt32($digits, 16)
        if ($negative) {
            return -$value
        }

        return $value
    }

    return [int]$token
}

function Format-Hex16 {
    param([int]$Value)
    return ("0x{0:X4}" -f ($Value -band 0xFFFF))
}

function Get-MusicThemeId {
    param([string]$ThemeKey)

    switch ($ThemeKey.ToLowerInvariant()) {
        'splash' { return 0 }
        'title' { return 1 }
        'run' { return 2 }
        'win' { return 3 }
        'lose' { return 4 }
        default { return 0xFF }
    }
}

function Get-MusicThemeKey {
    param([int]$ThemeId)

    switch ($ThemeId) {
        0 { return 'splash' }
        1 { return 'title' }
        2 { return 'run' }
        3 { return 'win' }
        4 { return 'lose' }
        default { return $null }
    }
}

function Get-MusicThemeKeyForGameState {
    param([string]$GameState)

    switch ($GameState) {
        'SPLASH' { return 'splash' }
        'TITLE' { return 'title' }
        'PLAYING' { return 'run' }
        'WIN' { return 'win' }
        'LOSE' { return 'lose' }
        default { return $null }
    }
}

function Get-MusicNoteId {
    param([string]$NoteKey)

    switch ($NoteKey.ToUpperInvariant()) {
        'REST' { return 0 }
        'G2' { return 1 }
        'A2' { return 2 }
        'C3' { return 3 }
        'D3' { return 4 }
        'E3' { return 5 }
        'F3' { return 6 }
        'G3' { return 7 }
        'A3' { return 8 }
        'C4' { return 9 }
        'D4' { return 10 }
        'E4' { return 11 }
        'F4' { return 12 }
        'G4' { return 13 }
        'LOOP' { return 0xFF }
        default { return $null }
    }
}

function Get-MessageFeedbackTicks {
    param([string]$MessageKey)

    switch ($MessageKey) {
        'BLOCK' { return 5 }
        'NOPULSE' { return 5 }
        'SECTOR' { return 11 }
        'GATE' { return 11 }
        'HIT' { return 11 }
        'KILL' { return 11 }
        'SURGE' { return 11 }
        'TRAP' { return 11 }
        'RECHARGE' { return 11 }
        'SPOOF' { return 11 }
        default { return 7 }
    }
}

function Get-SfxIdForMessage {
    param([string]$MessageKey)

    switch ($MessageKey) {
        'SECTOR' { return 1 }
        'BLOCK' { return 2 }
        'SHARD' { return 3 }
        'GATE' { return 4 }
        'HIT' { return 5 }
        'KILL' { return 6 }
        'PULSE' { return 7 }
        'NOPULSE' { return 8 }
        'SURGE' { return 9 }
        'TRAP' { return 10 }
        'RECHARGE' { return 11 }
        'SPOOF' { return 11 }
        default { return 0 }
    }
}

function Get-SfxDuration {
    param([int]$SoundId)

    switch ($SoundId) {
        4 { return 8 }
        5 { return 7 }
        7 { return 6 }
        9 { return 6 }
        11 { return 6 }
        1 { return 6 }
        12 { return 12 }
        13 { return 12 }
        default { return 4 }
    }
}

function Get-MusicThemeDefinitions {
    param([string]$SourcePath)

    $musicData = Import-StructuredDataFile -SourcePath $SourcePath -Label 'music source'
    if (-not $musicData.ContainsKey('Themes')) {
        throw ("Music source must define a 'Themes' array: {0}" -f $SourcePath)
    }

    $expectedThemeKeys = @('splash', 'title', 'run', 'win', 'lose')
    $themes = @($musicData.Themes)
    if ($themes.Count -ne $expectedThemeKeys.Count) {
        throw ("Music source defined {0} themes, but the runtime expects {1}." -f $themes.Count, $expectedThemeKeys.Count)
    }

    $definitions = @{}
    for ($themeIndex = 0; $themeIndex -lt $themes.Count; $themeIndex++) {
        $theme = $themes[$themeIndex]
        if (-not ($theme -is [System.Collections.IDictionary])) {
            throw ("Each theme in {0} must be a hashtable." -f $SourcePath)
        }

        $themeKey = ([string]$theme.Key).ToLowerInvariant()
        if ($themeKey -ne $expectedThemeKeys[$themeIndex]) {
            throw ("Theme {0} in {1} must use key '{2}' to match the runtime theme order." -f ($themeIndex + 1), $SourcePath, $expectedThemeKeys[$themeIndex])
        }

        $events = @($theme.Events)
        if ($events.Count -eq 0) {
            throw ("Theme '{0}' in {1} did not define any events." -f $themeKey, $SourcePath)
        }

        $parsedEvents = New-Object 'System.Collections.Generic.List[object]'
        for ($eventIndex = 0; $eventIndex -lt $events.Count; $eventIndex++) {
            $entry = ([string]$events[$eventIndex]).Trim()
            if ([string]::IsNullOrWhiteSpace($entry)) {
                throw ("Theme '{0}' in {1} contains a blank event entry." -f $themeKey, $SourcePath)
            }

            $parts = $entry -split '\s+'
            $noteKey = $parts[0].ToUpperInvariant()
            $noteId = Get-MusicNoteId -NoteKey $noteKey
            if ($null -eq $noteId) {
                throw ("Theme '{0}' in {1} used unsupported note '{2}'." -f $themeKey, $SourcePath, $noteKey)
            }

            if ($noteKey -eq 'LOOP') {
                if ($parts.Count -ne 1 -or $eventIndex -ne ($events.Count - 1)) {
                    throw ("Theme '{0}' in {1} must place LOOP as its final event." -f $themeKey, $SourcePath)
                }

                $parsedEvents.Add([pscustomobject]@{
                    NoteId = $noteId
                    Ticks = 0
                })
                continue
            }

            if ($parts.Count -ne 2) {
                throw ("Theme '{0}' event '{1}' in {2} must be 'NOTE TICKS' or 'LOOP'." -f $themeKey, $entry, $SourcePath)
            }

            $ticks = [int]$parts[1]
            if ($ticks -lt 0 -or $ticks -gt 255) {
                throw ("Theme '{0}' note '{1}' in {2} must use a 0..255 tick duration." -f $themeKey, $noteKey, $SourcePath)
            }

            $parsedEvents.Add([pscustomobject]@{
                NoteId = $noteId
                Ticks = $ticks
            })
        }

        $definitions[$themeKey] = $parsedEvents.ToArray()
    }

    return $definitions
}

function Stop-ReplaySfx {
    param($State)

    $State.SoundId = 0
    $State.SoundTimer = 0
    $State.SoundPhase = 0
}

function Start-ReplaySfx {
    param(
        $State,
        [int]$SoundId
    )

    if ($SoundId -eq 0) {
        Stop-ReplaySfx -State $State
        return
    }

    $State.SoundId = $SoundId
    $State.SoundTimer = Get-SfxDuration -SoundId $SoundId
    $State.SoundPhase = 0
}

function Set-ReplayMessageEvent {
    param(
        $State,
        [string]$MessageKey
    )

    $State.MessageId = $MessageKey
    $State.FeedbackTimer = Get-MessageFeedbackTicks -MessageKey $MessageKey
    Start-ReplaySfx -State $State -SoundId (Get-SfxIdForMessage -MessageKey $MessageKey)
}

function Stop-ReplayMusic {
    param($State)

    $State.MusicTheme = 0xFF
    $State.MusicEventIndex = 0
    $State.MusicTicks = 0
    $State.MusicNote = 0
}

function Start-ReplayMusicTheme {
    param(
        $State,
        [int]$ThemeId
    )

    if ($ThemeId -eq 0xFF) {
        Stop-ReplayMusic -State $State
        return
    }

    $State.MusicTheme = $ThemeId
    $State.MusicEventIndex = 0
    $State.MusicTicks = 0
    $State.MusicNote = 0
}

function Sync-ReplayMusicTheme {
    param(
        $State,
        [bool]$MusicEnabled
    )

    if (-not $MusicEnabled) {
        Stop-ReplayMusic -State $State
        return
    }

    $themeKey = Get-MusicThemeKeyForGameState -GameState $State.GameState
    $themeId = if ($null -eq $themeKey) { 0xFF } else { Get-MusicThemeId -ThemeKey $themeKey }
    if ($themeId -ne $State.MusicTheme) {
        Start-ReplayMusicTheme -State $State -ThemeId $themeId
    }
}

function Load-ReplayMusicEvent {
    param(
        $State,
        $MusicThemes
    )

    $themeKey = Get-MusicThemeKey -ThemeId $State.MusicTheme
    if ($null -eq $themeKey -or -not $MusicThemes.ContainsKey($themeKey)) {
        Stop-ReplayMusic -State $State
        return
    }

    $events = @($MusicThemes[$themeKey])
    if ($events.Count -eq 0) {
        Stop-ReplayMusic -State $State
        return
    }

    while ($true) {
        if ($State.MusicEventIndex -ge $events.Count) {
            $State.MusicEventIndex = 0
        }

        $event = $events[$State.MusicEventIndex]
        $State.MusicEventIndex += 1
        if ($event.NoteId -eq 0xFF) {
            $State.MusicEventIndex = 0
            continue
        }

        $State.MusicNote = [int]$event.NoteId
        $State.MusicTicks = [int]$event.Ticks
        return
    }
}

function Update-ReplayMusicTransport {
    param(
        $State,
        $MusicThemes
    )

    if ($State.MusicTheme -eq 0xFF) {
        return
    }

    if ($State.SoundTimer -ne 0) {
        return
    }

    if ($State.MusicTicks -eq 0) {
        Load-ReplayMusicEvent -State $State -MusicThemes $MusicThemes
    }

    if ($State.MusicTicks -eq 0) {
        return
    }

    $State.MusicTicks -= 1
}

function Update-ReplaySfxTransport {
    param($State)

    if ($State.SoundTimer -eq 0) {
        Stop-ReplaySfx -State $State
        return
    }

    $State.SoundPhase = (($State.SoundPhase + 1) -band 0xFF)
    $State.SoundTimer -= 1
    if ($State.SoundTimer -le 0) {
        Stop-ReplaySfx -State $State
    }
}

function Update-ReplayAudio {
    param(
        $State,
        [bool]$MusicEnabled,
        $MusicThemes
    )

    Sync-ReplayMusicTheme -State $State -MusicEnabled $MusicEnabled
    Update-ReplayMusicTransport -State $State -MusicThemes $MusicThemes
    Update-ReplaySfxTransport -State $State
}

function Handle-ReplayStateChangeFeedback {
    param($State)

    switch ($State.GameState) {
        'WIN' {
            $State.FeedbackTimer = 11
            Start-ReplaySfx -State $State -SoundId 12
        }
        'LOSE' {
            $State.FeedbackTimer = 11
            Start-ReplaySfx -State $State -SoundId 13
        }
        'SPLASH' {
            Stop-ReplaySfx -State $State
        }
        'TITLE' {
            Stop-ReplaySfx -State $State
        }
    }
}

function Update-ReplayFeedback {
    param(
        $State,
        [bool]$MusicEnabled,
        $MusicThemes
    )

    if ($State.GameState -ne $State.LastGameState) {
        $State.LastGameState = $State.GameState
        $State.StateTicks = 0
        Handle-ReplayStateChangeFeedback -State $State
    }

    if ($State.StateTicks -lt 255) {
        $State.StateTicks += 1
    }

    if ($State.FeedbackTimer -gt 0) {
        $State.FeedbackTimer -= 1
    }

    Update-ReplayAudio -State $State -MusicEnabled $MusicEnabled -MusicThemes $MusicThemes
}

function Get-RequiredConstants {
    param([string]$SourcePath)

    $constantNames = @(
        'TOTAL_SECTORS',
        'MAP_W',
        'MAP_H',
        'PLAY_MIN_X',
        'PLAY_MIN_Y',
        'START_X',
        'START_Y',
        'EXIT_COL',
        'EXIT_ROW',
        'START_SHIELDS',
        'START_PULSES',
        'MAX_PULSES',
        'SHARD_COUNT',
        'SHARD_POOL_COUNT',
        'SPOOF_TURNS',
        'SURGE_PLAYER_DAMAGE',
        'ENEMY_SPAWN_STEP',
        'ENEMY_SPAWN_BASE',
        'PULSE_RADIUS',
        'PULSE_RECHARGE_KILLS',
        'SAFE_X_MAX',
        'SAFE_Y_MIN',
        'NEAR_THREAT_DISTANCE',
        'ELITE_THREAT_DISTANCE',
        'MAX_ENEMIES',
        'SCORE_SHARD_POINTS',
        'SCORE_KILL_POINTS',
        'SCORE_TRAP_BONUS',
        'SCORE_CHAIN_STEP',
        'SCORE_NO_HIT_BONUS',
        'SCORE_EFFICIENT_PULSE_BONUS',
        'SCORE_EFFICIENT_PULSE_LIMIT',
        'SCORE_FAST_CLEAR_BASE',
        'SCORE_FAST_CLEAR_STEP',
        'SCORE_WIN_SHIELD_BONUS',
        'SCORE_WIN_PULSE_BONUS',
        'SCENE3D_NEAR_Z',
        'GAME3D_VIEW_X',
        'GAME3D_VIEW_Y',
        'GAME3D_VIEW_W',
        'GAME3D_VIEW_H',
        'GAME3D_FLOOR_Y',
        'GAME3D_CAMERA_HORIZON_CENTER_OFFSET',
        'GAME3D_FACE_DEPTH_FAR',
        'GAME3D_PLAYER_LOCATOR_FAR_DEPTH',
        'GAME3D_CUE_EDGE_MARGIN',
        'GAME3D_CUE_FLAG_PLAYER_FALLBACK',
        'GAME3D_CUE_FLAG_EXIT_FALLBACK',
        'GAME3D_CUE_FLAG_SPOOF_FALLBACK',
        'GAME3D_CUE_FLAG_THREAT_FALLBACK'
    )

    $constants = @{}
    foreach ($name in $constantNames) {
        $constants[$name] = Get-AsmEquValue -SourcePath $SourcePath -Name $name
    }

    $constants['PLAY_MAX_X'] = $constants.MAP_W - 2
    $constants['PLAY_MAX_Y'] = $constants.MAP_H - 2

    return $constants
}

function ConvertTo-GeometryFixed88 {
    param([object]$Value)
    return [int][Math]::Round(([double]$Value) * 256.0)
}

function ConvertTo-GeometryAngleByte {
    param([object]$Value)

    $turn = ([double]$Value) % 360.0
    if ($turn -lt 0) {
        $turn += 360.0
    }

    return (([int][Math]::Round(($turn / 360.0) * 256.0)) -band 0xFF)
}

function Get-GameplayKitDefinitions {
    param([string]$SourcePath)

    $geometryData = Import-StructuredDataFile -SourcePath $SourcePath -Label 'geometry source'
    if (-not $geometryData.ContainsKey('GameplayKits')) {
        throw ("Geometry source must define a 'GameplayKits' array: {0}" -f $SourcePath)
    }

    $expectedKitKeys = @('sector1', 'sector2', 'sector3')
    $kits = @($geometryData.GameplayKits)
    if ($kits.Count -ne $expectedKitKeys.Count) {
        throw ("Geometry source defined {0} gameplay kits, but replay expects {1}." -f $kits.Count, $expectedKitKeys.Count)
    }

    $definitions = New-Object 'System.Collections.Generic.List[object]'
    for ($kitIndex = 0; $kitIndex -lt $kits.Count; $kitIndex++) {
        $kit = $kits[$kitIndex]
        if (-not ($kit -is [System.Collections.IDictionary])) {
            throw ("Each gameplay kit in {0} must be a hashtable." -f $SourcePath)
        }

        $kitKey = ([string]$kit.Key).ToLowerInvariant()
        if ($kitKey -ne $expectedKitKeys[$kitIndex]) {
            throw ("Gameplay kit {0} in {1} must use key '{2}'." -f ($kitIndex + 1), $SourcePath, $expectedKitKeys[$kitIndex])
        }

        $camera = $kit.Camera
        $projection = $kit.Projection
        if (-not ($camera -is [System.Collections.IDictionary])) {
            throw ("Gameplay kit '{0}' in {1} must define a Camera block." -f $kitKey, $SourcePath)
        }
        if (-not ($projection -is [System.Collections.IDictionary])) {
            throw ("Gameplay kit '{0}' in {1} must define a Projection block." -f $kitKey, $SourcePath)
        }

        $definitions.Add([pscustomobject]@{
            Key = $kitKey
            CameraHeight = (ConvertTo-GeometryFixed88 $camera.Height)
            CameraDistance = (ConvertTo-GeometryFixed88 $camera.Distance)
            CameraLookAhead = (ConvertTo-GeometryFixed88 $camera.LookAhead)
            HeadingNorthYaw = (ConvertTo-GeometryAngleByte $camera.HeadingNorthYawDegrees)
            HeadingEastYaw = (ConvertTo-GeometryAngleByte $camera.HeadingEastYawDegrees)
            HeadingSouthYaw = (ConvertTo-GeometryAngleByte $camera.HeadingSouthYawDegrees)
            HeadingWestYaw = (ConvertTo-GeometryAngleByte $camera.HeadingWestYawDegrees)
            ProjectionPitch = (ConvertTo-GeometryAngleByte $projection.PitchDegrees)
            ProjectionScale = [int]$projection.ProjectScale
            HorizonY = [int]$kit.Atmosphere.HorizonY
        })
    }

    return $definitions.ToArray()
}

function Get-StepActionKey {
    param(
        $Step,
        [string]$DemoName
    )

    $actionTokenMap = @{
        'WAIT'  = 'WAIT'
        'LEFT'  = 'LEFT'
        'RIGHT' = 'RIGHT'
        'UP'    = 'UP'
        'DOWN'  = 'DOWN'
        'PULSE' = 'PULSE'
        'A'     = 'LEFT'
        'D'     = 'RIGHT'
        'W'     = 'UP'
        'S'     = 'DOWN'
        'C'     = 'PULSE'
    }

    $actionKey = $null
    $repeatCount = $null
    if ($Step -is [System.Collections.IDictionary]) {
        $actionKey = [string]$Step['Action']
        if ($Step.ContainsKey('Ticks')) {
            $repeatCount = [int]$Step['Ticks']
        } elseif ($Step.ContainsKey('Count')) {
            $repeatCount = [int]$Step['Count']
        } elseif ($Step.ContainsKey('Repeat')) {
            $repeatCount = [int]$Step['Repeat']
        }
    } else {
        $parts = ([string]$Step).Trim() -split '\s+'
        if ($parts.Count -ne 2) {
            throw ("Demo '{0}' step '{1}' must be 'ACTION COUNT'." -f $DemoName, $Step)
        }

        $actionKey = $parts[0]
        $repeatCount = [int]$parts[1]
    }

    $actionKey = $actionKey.ToUpperInvariant()
    if (-not $actionTokenMap.ContainsKey($actionKey)) {
        throw ("Demo '{0}' used unsupported action '{1}'." -f $DemoName, $actionKey)
    }

    if ($repeatCount -lt 1 -or $repeatCount -gt 255) {
        throw ("Demo '{0}' action '{1}' must use a repeat count between 1 and 255." -f $DemoName, $actionKey)
    }

    return [pscustomobject]@{
        Action = $actionTokenMap[$actionKey]
        Count = $repeatCount
    }
}

function New-RngState {
    param([int]$Seed)
    return [pscustomobject]@{ Value = ($Seed -band 0xFFFF) }
}

function Get-NextRngWord {
    param($State)

    $value = ($State.Value -shr 1)
    if (($State.Value -band 1) -ne 0) {
        $value = $value -bxor 0xB400
    }

    $State.Value = ($value -band 0xFFFF)
    return $State.Value
}

function Get-RandomX {
    param($State, [int]$PlayMaxX)
    $value = Get-NextRngWord -State $State
    $lowByte = ($value -band 0xFF)
    return (($lowByte % $PlayMaxX) + 1)
}

function Get-RandomY {
    param($State, [int]$PlayMaxY)
    $value = Get-NextRngWord -State $State
    $lowByte = ($value -band 0xFF)
    return (($lowByte % $PlayMaxY) + 1)
}

function New-ReplayState {
    param(
        $Constants,
        $Sectors,
        [int]$StartSector,
        [int]$Seed
    )

    $state = [pscustomobject]@{
        GameState = 'PLAYING'
        SectorNum = 1
        CurrentTemplateIndex = 0
        ShieldCount = $Constants.START_SHIELDS
        PulseCount = $Constants.START_PULSES
        DataCount = 0
        KillCount = 0
        ScoreTotal = 0
        SectorScore = 0
        SectorActions = 0
        SectorHits = 0
        SectorPulsesUsed = 0
        PlayerX = $Constants.START_X
        PlayerY = $Constants.START_Y
        ExitX = $Constants.EXIT_COL
        ExitY = $Constants.EXIT_ROW
        LastPlayerDx = 0
        LastPlayerDy = 0
        SpoofTimer = 0
        SpoofX = $Constants.START_X
        SpoofY = $Constants.START_Y
        ThreatLevel = 0
        ThreatX = $Constants.START_X
        ThreatY = $Constants.START_Y
        LastGameState = '__INIT__'
        StateTicks = 0
        MessageId = 'SECTOR'
        FeedbackTimer = 0
        SoundId = 0
        SoundTimer = 0
        SoundPhase = 0
        MusicTheme = 0xFF
        MusicEventIndex = 0
        MusicTicks = 0
        MusicNote = 0
        Rng = (New-RngState -Seed $Seed)
        MapTiles = (New-Object object[] ($Constants.MAP_W * $Constants.MAP_H))
        Enemies = @()
        CurrentMapName = ''
        SectorScoreTable = @(0, 0, 0)
        TraceTicks = 0
    }

    for ($i = 0; $i -lt $Constants.MAX_ENEMIES; $i++) {
        $state.Enemies += [pscustomobject]@{
            Alive = $false
            X = 0
            Y = 0
            Kind = 'RUSHER'
        }
    }

    Initialize-ReplayRun -State $state -Constants $Constants -Sectors $Sectors -StartSector $StartSector
    return $state
}

function Initialize-ReplayRun {
    param(
        $State,
        $Constants,
        $Sectors,
        [int]$StartSector
    )

    $sector = [Math]::Max(1, [Math]::Min($Constants.TOTAL_SECTORS, $StartSector))
    $State.GameState = 'PLAYING'
    $State.SectorNum = $sector

    $pulseCount = $Constants.START_PULSES
    if ($sector -gt 1) {
        $pulseCount += ($sector - 2)
        if ($pulseCount -gt $Constants.MAX_PULSES) {
            $pulseCount = $Constants.MAX_PULSES
        }
    }

    $State.PulseCount = $pulseCount
    $State.ShieldCount = $Constants.START_SHIELDS
    $State.DataCount = 0
    $State.KillCount = 0
    $State.ScoreTotal = 0
    $State.SectorScore = 0
    $State.SectorActions = 0
    $State.SectorHits = 0
    $State.SectorPulsesUsed = 0
    $State.SectorScoreTable = @(0, 0, 0)
    $State.LastGameState = '__INIT__'
    $State.StateTicks = 0
    $State.MessageId = 'SECTOR'
    $State.FeedbackTimer = 0
    $State.ThreatLevel = 0
    $State.ThreatX = $Constants.START_X
    $State.ThreatY = $Constants.START_Y
    Stop-ReplaySfx -State $State
    Stop-ReplayMusic -State $State
    Load-ReplaySector -State $State -Constants $Constants -Sectors $Sectors
    Set-ReplayMessageEvent -State $State -MessageKey 'SECTOR'
}

function Get-SectorById {
    param(
        $Sectors,
        [int]$SectorId
    )

    $sector = @($Sectors | Where-Object { [int]$_.Id -eq $SectorId }) | Select-Object -First 1
    if (-not $sector) {
        throw ("Missing authored sector with Id {0}." -f $SectorId)
    }

    return $sector
}

function Get-MapIndex {
    param(
        $Constants,
        [int]$X,
        [int]$Y
    )

    return ($Y * $Constants.MAP_W) + $X
}

function Get-Tile {
    param(
        $State,
        $Constants,
        [int]$X,
        [int]$Y
    )

    return $State.MapTiles[(Get-MapIndex -Constants $Constants -X $X -Y $Y)]
}

function Set-Tile {
    param(
        $State,
        $Constants,
        [int]$X,
        [int]$Y,
        [string]$Tile
    )

    $State.MapTiles[(Get-MapIndex -Constants $Constants -X $X -Y $Y)] = $Tile
}

function Find-EnemyIndex {
    param(
        $State,
        [int]$X,
        [int]$Y,
        [int]$IgnoreIndex = -1
    )

    for ($i = 0; $i -lt $State.Enemies.Count; $i++) {
        if ($i -eq $IgnoreIndex) {
            continue
        }

        $enemy = $State.Enemies[$i]
        if (-not $enemy.Alive) {
            continue
        }

        if ($enemy.X -eq $X -and $enemy.Y -eq $Y) {
            return $i
        }
    }

    return -1
}

function Set-CurrentSectorScore {
    param($State)
    $State.SectorScoreTable[$State.SectorNum - 1] = $State.SectorScore
}

function Award-Score {
    param(
        $State,
        [int]$Points
    )

    $State.ScoreTotal = [Math]::Min(0xFFFF, $State.ScoreTotal + $Points)
    $State.SectorScore = [Math]::Min(0xFFFF, $State.SectorScore + $Points)
    Set-CurrentSectorScore -State $State
}

function Award-Kill {
    param(
        $State,
        $Constants
    )

    if ($State.KillCount -lt 99) {
        $State.KillCount += 1
    }

    Award-Score -State $State -Points $Constants.SCORE_KILL_POINTS
}

function Record-SectorAction {
    param($State)
    if ($State.SectorActions -lt 255) {
        $State.SectorActions += 1
    }
}

function Record-SectorHit {
    param($State)
    if ($State.SectorHits -lt 255) {
        $State.SectorHits += 1
    }
}

function Record-SectorPulse {
    param($State)
    if ($State.SectorPulsesUsed -lt 255) {
        $State.SectorPulsesUsed += 1
    }
}

function Reset-SectorMastery {
    param($State)
    $State.SectorScore = 0
    $State.SectorActions = 0
    $State.SectorHits = 0
    $State.SectorPulsesUsed = 0
    Set-CurrentSectorScore -State $State
}

function Finalize-SectorMastery {
    param(
        $State,
        $Constants
    )

    if ($State.SectorHits -eq 0) {
        Award-Score -State $State -Points $Constants.SCORE_NO_HIT_BONUS
    }

    if ($State.SectorPulsesUsed -le $Constants.SCORE_EFFICIENT_PULSE_LIMIT) {
        Award-Score -State $State -Points $Constants.SCORE_EFFICIENT_PULSE_BONUS
    }

    $fastPenalty = $State.SectorActions * $Constants.SCORE_FAST_CLEAR_STEP
    if ($fastPenalty -lt $Constants.SCORE_FAST_CLEAR_BASE) {
        Award-Score -State $State -Points ($Constants.SCORE_FAST_CLEAR_BASE - $fastPenalty)
    }
}

function Award-FinalMasteryBonus {
    param(
        $State,
        $Constants
    )

    Award-Score -State $State -Points ($State.ShieldCount * $Constants.SCORE_WIN_SHIELD_BONUS)
    Award-Score -State $State -Points ($State.PulseCount * $Constants.SCORE_WIN_PULSE_BONUS)
}

function Commit-PlayerMove {
    param(
        $State,
        [int]$TargetX,
        [int]$TargetY
    )

    $State.LastPlayerDx = $TargetX - $State.PlayerX
    $State.LastPlayerDy = $TargetY - $State.PlayerY
    $State.PlayerX = $TargetX
    $State.PlayerY = $TargetY
}

function Get-SectorRules {
    param(
        $Sectors,
        [int]$SectorId
    )

    return (Get-SectorById -Sectors $Sectors -SectorId $SectorId).Rules
}

function Select-SectorMap {
    param(
        $State,
        $Sectors
    )

    $sector = Get-SectorById -Sectors $Sectors -SectorId $State.SectorNum
    $maps = @($sector.Maps)
    if ($maps.Count -eq 0) {
        throw ("Sector {0} does not define any maps." -f $State.SectorNum)
    }

    if ($maps.Count -eq 1) {
        $State.CurrentTemplateIndex = 0
        return $maps[0]
    }

    $rngWord = Get-NextRngWord -State $State.Rng
    $selectedIndex = $rngWord % $maps.Count
    $State.CurrentTemplateIndex = $selectedIndex
    return $maps[$selectedIndex]
}

function Get-GameStateId {
    param([string]$StateName)

    switch ($StateName) {
        'TITLE' { return 0 }
        'PLAYING' { return 1 }
        'WIN' { return 2 }
        'LOSE' { return 3 }
        'SPLASH' { return 4 }
        default { return 0xFF }
    }
}

function Update-RuntimeSignatureByte {
    param(
        [int]$Signature,
        [int]$Value
    )

    $signature = ((($signature -shl 1) -band 0xFFFF) -bor (($signature -shr 15) -band 0x1))
    $signature = ($signature -bxor ($Value -band 0xFF))
    $signature = ($signature + 0x173D) -band 0xFFFF
    return $signature
}

function Update-RuntimeSignatureWord {
    param(
        [int]$Signature,
        [int]$Value
    )

    $signature = Update-RuntimeSignatureByte -Signature $Signature -Value ($Value -band 0xFF)
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value (($Value -shr 8) -band 0xFF)
    return $signature
}

function Get-RuntimeCameraHeading {
    param($State)

    if ($State.LastPlayerDx -gt 0) { return 1 }
    if ($State.LastPlayerDx -lt 0) { return 3 }
    if ($State.LastPlayerDy -gt 0) { return 2 }
    if ($State.LastPlayerDy -lt 0) { return 0 }
    return 1
}

function Get-RuntimeRoomVariant {
    param($State)

    switch (Get-RuntimeCameraHeading -State $State) {
        0 { return 1 }
        1 { return 0 }
        2 { return 2 }
        default { return 3 }
    }
}

function Mul-Fixed88 {
    param(
        [int]$A,
        [int]$B
    )

    return [int](($A * $B) -shr 8)
}

function Get-FixedSinCos {
    param([int]$AngleByte)

    $angle = ($AngleByte -band 0xFF)
    $radians = (($angle / 256.0) * [Math]::PI * 2.0)
    $sinValue = [int][Math]::Round([Math]::Sin($radians) * 256.0)
    $cosValue = [int][Math]::Round([Math]::Cos($radians) * 256.0)
    return [pscustomobject]@{
        Sin = $sinValue
        Cos = $cosValue
    }
}

function Get-GameplayKitForState {
    param(
        $State,
        [object[]]$GameplayKits
    )

    return $GameplayKits[[Math]::Max(0, [Math]::Min($GameplayKits.Count - 1, $State.SectorNum - 1))]
}

function Get-RuntimeHeadingYaw {
    param(
        $State,
        [object[]]$GameplayKits
    )

    $kit = Get-GameplayKitForState -State $State -GameplayKits $GameplayKits
    switch (Get-RuntimeCameraHeading -State $State) {
        0 { return $kit.HeadingNorthYaw }
        2 { return $kit.HeadingSouthYaw }
        3 { return $kit.HeadingWestYaw }
        default { return $kit.HeadingEastYaw }
    }
}

function Get-RuntimeCameraSetup {
    param(
        $State,
        $Constants,
        [object[]]$GameplayKits
    )

    $kit = Get-GameplayKitForState -State $State -GameplayKits $GameplayKits
    $headingYaw = Get-RuntimeHeadingYaw -State $State -GameplayKits $GameplayKits
    $playerWorldX = ($State.PlayerX * 256) + 128 - ($Constants.MAP_W * 128)
    $playerWorldZ = ($State.PlayerY * 256) + 128 - ($Constants.MAP_H * 128)
    $focusX = $playerWorldX
    $focusZ = $playerWorldZ

    if ($State.LastPlayerDx -gt 0) {
        $focusX += $kit.CameraLookAhead
    } elseif ($State.LastPlayerDx -lt 0) {
        $focusX -= $kit.CameraLookAhead
    }

    if ($State.LastPlayerDy -gt 0) {
        $focusZ += $kit.CameraLookAhead
    } elseif ($State.LastPlayerDy -lt 0) {
        $focusZ -= $kit.CameraLookAhead
    }

    $yaw = Get-FixedSinCos -AngleByte $headingYaw
    $camX = $focusX - (Mul-Fixed88 -A $kit.CameraDistance -B $yaw.Sin)
    $camZ = $focusZ - (Mul-Fixed88 -A $kit.CameraDistance -B $yaw.Cos)
    $centerY = $Constants.GAME3D_VIEW_Y + $Constants.GAME3D_CAMERA_HORIZON_CENTER_OFFSET + $kit.HorizonY

    return [pscustomobject]@{
        CamX = $camX
        CamY = $kit.CameraHeight
        CamZ = $camZ
        Yaw = $headingYaw
        CenterX = ($Constants.GAME3D_VIEW_X + [int]($Constants.GAME3D_VIEW_W / 2))
        CenterY = $centerY
        ProjectScale = $kit.ProjectionScale
        Pitch = $kit.ProjectionPitch
        ViewLeft = $Constants.GAME3D_VIEW_X
        ViewTop = $Constants.GAME3D_VIEW_Y
        ViewRight = $Constants.GAME3D_VIEW_X + $Constants.GAME3D_VIEW_W - 1
        ViewBottom = $Constants.GAME3D_VIEW_Y + $Constants.GAME3D_VIEW_H - 1
    }
}

function Project-WorldPoint {
    param(
        [int]$WorldX,
        [int]$WorldY,
        [int]$WorldZ,
        $Camera,
        $Constants
    )

    $relX = $WorldX - $Camera.CamX
    $relY = $WorldY - $Camera.CamY
    $relZ = $WorldZ - $Camera.CamZ

    $yaw = Get-FixedSinCos -AngleByte $Camera.Pitch
    $cameraYaw = Get-FixedSinCos -AngleByte $Camera.Yaw

    $tempX = (Mul-Fixed88 -A $relX -B $cameraYaw.Cos) - (Mul-Fixed88 -A $relZ -B $cameraYaw.Sin)
    $tempZ = (Mul-Fixed88 -A $relX -B $cameraYaw.Sin) + (Mul-Fixed88 -A $relZ -B $cameraYaw.Cos)
    $tempY = (Mul-Fixed88 -A $relY -B $yaw.Cos) - (Mul-Fixed88 -A $tempZ -B $yaw.Sin)
    $depth = (Mul-Fixed88 -A $relY -B $yaw.Sin) + (Mul-Fixed88 -A $tempZ -B $yaw.Cos)

    if ($depth -le $Constants.SCENE3D_NEAR_Z) {
        return [pscustomobject]@{
            Visible = $false
            X = 0
            Y = 0
            Depth = $depth
        }
    }

    $screenX = [int](($tempX * $Camera.ProjectScale) / $depth) + $Camera.CenterX
    $screenY = -[int](($tempY * $Camera.ProjectScale) / $depth) + $Camera.CenterY
    return [pscustomobject]@{
        Visible = $true
        X = $screenX
        Y = $screenY
        Depth = $depth
    }
}

function Project-TileCenter {
    param(
        $State,
        $Constants,
        [object[]]$GameplayKits,
        [int]$TileX,
        [int]$TileY
    )

    $camera = Get-RuntimeCameraSetup -State $State -Constants $Constants -GameplayKits $GameplayKits
    $worldX = ($TileX * 256) + 128 - ($Constants.MAP_W * 128)
    $worldZ = ($TileY * 256) + 128 - ($Constants.MAP_H * 128)
    return Project-WorldPoint -WorldX $worldX -WorldY $Constants.GAME3D_FLOOR_Y -WorldZ $worldZ -Camera $camera -Constants $Constants
}

function Test-CueReady {
    param(
        $Projection,
        $Constants
    )

    if (-not $Projection.Visible) {
        return $false
    }

    if ($Projection.X -lt ($Constants.GAME3D_VIEW_X + $Constants.GAME3D_CUE_EDGE_MARGIN)) {
        return $false
    }
    if ($Projection.X -gt ($Constants.GAME3D_VIEW_X + $Constants.GAME3D_VIEW_W - 1 - $Constants.GAME3D_CUE_EDGE_MARGIN)) {
        return $false
    }
    if ($Projection.Y -lt ($Constants.GAME3D_VIEW_Y + $Constants.GAME3D_CUE_EDGE_MARGIN)) {
        return $false
    }
    if ($Projection.Y -gt ($Constants.GAME3D_VIEW_Y + $Constants.GAME3D_VIEW_H - 1 - $Constants.GAME3D_CUE_EDGE_MARGIN)) {
        return $false
    }

    return $true
}

function Get-RuntimeCueFlags {
    param(
        $State,
        $Constants,
        [object[]]$GameplayKits
    )

    $flags = 0
    $playerProjection = Project-TileCenter -State $State -Constants $Constants -GameplayKits $GameplayKits -TileX $State.PlayerX -TileY $State.PlayerY
    if ((-not $playerProjection.Visible) -or $playerProjection.Depth -gt $Constants.GAME3D_PLAYER_LOCATOR_FAR_DEPTH -or -not (Test-CueReady -Projection $playerProjection -Constants $Constants)) {
        $flags = $flags -bor $Constants.GAME3D_CUE_FLAG_PLAYER_FALLBACK
    }

    $exitProjection = Project-TileCenter -State $State -Constants $Constants -GameplayKits $GameplayKits -TileX $State.ExitX -TileY $State.ExitY
    if (-not (Test-CueReady -Projection $exitProjection -Constants $Constants)) {
        $flags = $flags -bor $Constants.GAME3D_CUE_FLAG_EXIT_FALLBACK
    }

    if ($State.SpoofTimer -gt 0) {
        $spoofProjection = Project-TileCenter -State $State -Constants $Constants -GameplayKits $GameplayKits -TileX $State.SpoofX -TileY $State.SpoofY
        if (-not (Test-CueReady -Projection $spoofProjection -Constants $Constants)) {
            $flags = $flags -bor $Constants.GAME3D_CUE_FLAG_SPOOF_FALLBACK
        }
    }

    if ($State.ThreatLevel -gt 0) {
        $threatProjection = Project-TileCenter -State $State -Constants $Constants -GameplayKits $GameplayKits -TileX $State.ThreatX -TileY $State.ThreatY
        if (-not (Test-CueReady -Projection $threatProjection -Constants $Constants)) {
            $flags = $flags -bor $Constants.GAME3D_CUE_FLAG_THREAT_FALLBACK
        }
    }

    return $flags
}

function Get-RuntimeVerificationSignature {
    param(
        $State,
        $Constants,
        [object[]]$GameplayKits
    )

    $signature = 0xA55A
    $kit = Get-GameplayKitForState -State $State -GameplayKits $GameplayKits
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value (Get-GameStateId -StateName $State.GameState)
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $State.SectorNum
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $State.CurrentTemplateIndex
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $State.PlayerX
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $State.PlayerY
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value (Get-RuntimeCameraHeading -State $State)
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value (Get-RuntimeRoomVariant -State $State)
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $kit.ProjectionPitch
    $signature = Update-RuntimeSignatureWord -Signature $signature -Value $kit.ProjectionScale
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value (Get-RuntimeCueFlags -State $State -Constants $Constants -GameplayKits $GameplayKits)
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $State.ShieldCount
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $State.PulseCount
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $State.DataCount
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $State.KillCount
    $signature = Update-RuntimeSignatureWord -Signature $signature -Value $State.ScoreTotal
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $State.SectorActions
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $State.SectorHits
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $State.SectorPulsesUsed
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $State.SpoofTimer
    return ($signature -band 0xFFFF)
}

function ConvertTo-AnchorPoint {
    param(
        [string]$Token,
        $Constants,
        [string]$Context
    )

    if ([string]::IsNullOrWhiteSpace($Token) -or $Token -notmatch '^\s*(\d+)\s*,\s*(\d+)\s*$') {
        throw ("{0} must use 'x,y' coordinates inside the playable bounds. Received: '{1}'." -f $Context, $Token)
    }

    $x = [int]$Matches[1]
    $y = [int]$Matches[2]
    if ($x -lt $Constants.PLAY_MIN_X -or $x -gt $Constants.PLAY_MAX_X -or $y -lt $Constants.PLAY_MIN_Y -or $y -gt $Constants.PLAY_MAX_Y) {
        throw ("{0} coordinate ({1},{2}) is outside the playable bounds." -f $Context, $x, $y)
    }

    return [pscustomobject]@{
        X = $x
        Y = $y
    }
}

function Get-MapAnchors {
    param(
        $Map,
        $State,
        $Constants,
        $Sectors
    )

    $rules = Get-SectorRules -Sectors $Sectors -SectorId $State.SectorNum
    $enemyBudget = Get-SectorEnemyCount -State $State -Constants $Constants -Sectors $Sectors
    $anchors = if ($Map.ContainsKey('Anchors')) { $Map.Anchors } else { @{} }
    if (-not ($anchors -is [System.Collections.IDictionary])) {
        throw ("Map '{0}' anchors must be a hashtable." -f $Map.Name)
    }

    $occupied = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    $enemyKindLookup = @{
        RUSHER = 'RUSHER'
        FLANKER = 'FLANKER'
        WARDEN = 'WARDEN'
    }
    $terminalAnchors = New-Object 'System.Collections.Generic.List[object]'
    $surgeAnchors = New-Object 'System.Collections.Generic.List[object]'
    $enemyAnchors = New-Object 'System.Collections.Generic.List[object]'
    $rows = @($Map.Rows | ForEach-Object { [string]$_ })

    $terminalEntries = @()
    if ($anchors.ContainsKey('Terminals')) { $terminalEntries += @($anchors['Terminals']) }
    $surgeEntries = @()
    if ($anchors.ContainsKey('Surges')) { $surgeEntries += @($anchors['Surges']) }
    $enemyEntries = @()
    if ($anchors.ContainsKey('Enemies')) { $enemyEntries += @($anchors['Enemies']) }

    if ($terminalEntries.Count -gt [int]$rules.TerminalCount) {
        throw ("Map '{0}' defines {1} terminal anchors, but the sector budget is {2}." -f $Map.Name, $terminalEntries.Count, $rules.TerminalCount)
    }

    if ($surgeEntries.Count -gt [int]$rules.SurgeCount) {
        throw ("Map '{0}' defines {1} surge anchors, but the sector budget is {2}." -f $Map.Name, $surgeEntries.Count, $rules.SurgeCount)
    }

    if ($enemyEntries.Count -gt $enemyBudget) {
        throw ("Map '{0}' defines {1} enemy anchors, but the sector budget is {2}." -f $Map.Name, $enemyEntries.Count, $enemyBudget)
    }

    foreach ($token in $terminalEntries) {
        $anchor = ConvertTo-AnchorPoint -Token ([string]$token) -Constants $Constants -Context ("Terminal anchor in {0}" -f $Map.Name)
        if (([string]$rows[$anchor.Y]).ToCharArray()[$anchor.X] -eq '#') {
            throw ("Terminal anchor ({0},{1}) in map '{2}' must sit on a floor tile." -f $anchor.X, $anchor.Y, $Map.Name)
        }

        if (($anchor.X -eq $Constants.START_X -and $anchor.Y -eq $Constants.START_Y) -or ($anchor.X -eq $Constants.EXIT_COL -and $anchor.Y -eq $Constants.EXIT_ROW)) {
            throw ("Terminal anchor ({0},{1}) in map '{2}' cannot sit on the start or exit tile." -f $anchor.X, $anchor.Y, $Map.Name)
        }

        $anchorKey = ("{0},{1}" -f $anchor.X, $anchor.Y)
        if (-not $occupied.Add($anchorKey)) {
            throw ("Map '{0}' defines multiple anchors on tile ({1},{2})." -f $Map.Name, $anchor.X, $anchor.Y)
        }

        $terminalAnchors.Add($anchor)
    }

    foreach ($token in $surgeEntries) {
        $anchor = ConvertTo-AnchorPoint -Token ([string]$token) -Constants $Constants -Context ("Surge anchor in {0}" -f $Map.Name)
        if (([string]$rows[$anchor.Y]).ToCharArray()[$anchor.X] -eq '#') {
            throw ("Surge anchor ({0},{1}) in map '{2}' must sit on a floor tile." -f $anchor.X, $anchor.Y, $Map.Name)
        }

        if (($anchor.X -eq $Constants.START_X -and $anchor.Y -eq $Constants.START_Y) -or ($anchor.X -eq $Constants.EXIT_COL -and $anchor.Y -eq $Constants.EXIT_ROW)) {
            throw ("Surge anchor ({0},{1}) in map '{2}' cannot sit on the start or exit tile." -f $anchor.X, $anchor.Y, $Map.Name)
        }

        $anchorKey = ("{0},{1}" -f $anchor.X, $anchor.Y)
        if (-not $occupied.Add($anchorKey)) {
            throw ("Map '{0}' defines multiple anchors on tile ({1},{2})." -f $Map.Name, $anchor.X, $anchor.Y)
        }

        $surgeAnchors.Add($anchor)
    }

    foreach ($entry in $enemyEntries) {
        if (-not ($entry -is [System.Collections.IDictionary])) {
            throw ("Enemy anchors in map '{0}' must be hashtables with X, Y, and Kind." -f $Map.Name)
        }

        $x = [int]$entry.X
        $y = [int]$entry.Y
        $kind = ([string]$entry.Kind).Trim().ToUpperInvariant()
        if ($x -lt $Constants.PLAY_MIN_X -or $x -gt $Constants.PLAY_MAX_X -or $y -lt $Constants.PLAY_MIN_Y -or $y -gt $Constants.PLAY_MAX_Y) {
            throw ("Enemy anchor ({0},{1}) in map '{2}' is outside the playable bounds." -f $x, $y, $Map.Name)
        }

        if (([string]$rows[$y]).ToCharArray()[$x] -eq '#') {
            throw ("Enemy anchor ({0},{1}) in map '{2}' must sit on a floor tile." -f $x, $y, $Map.Name)
        }

        if (($x -eq $Constants.START_X -and $y -eq $Constants.START_Y) -or ($x -eq $Constants.EXIT_COL -and $y -eq $Constants.EXIT_ROW)) {
            throw ("Enemy anchor ({0},{1}) in map '{2}' cannot sit on the start or exit tile." -f $x, $y, $Map.Name)
        }

        if ($x -le $Constants.SAFE_X_MAX -and $y -ge $Constants.SAFE_Y_MIN) {
            throw ("Enemy anchor ({0},{1}) in map '{2}' violates the enemy safe-zone contract." -f $x, $y, $Map.Name)
        }

        if (-not $enemyKindLookup.ContainsKey($kind)) {
            throw ("Enemy anchor ({0},{1}) in map '{2}' used unsupported Kind '{3}'." -f $x, $y, $Map.Name, $entry.Kind)
        }

        $anchorKey = ("{0},{1}" -f $x, $y)
        if (-not $occupied.Add($anchorKey)) {
            throw ("Map '{0}' defines multiple anchors on tile ({1},{2})." -f $Map.Name, $x, $y)
        }

        $enemyAnchors.Add([pscustomobject]@{
            X = $x
            Y = $y
            Kind = [string]$enemyKindLookup[$kind]
        })
    }

    return [pscustomobject]@{
        Terminals = $terminalAnchors.ToArray()
        Surges = $surgeAnchors.ToArray()
        Enemies = $enemyAnchors.ToArray()
    }
}

function Get-MapScenario {
    param(
        $Map,
        $Anchors,
        $Constants
    )

    if (-not $Map.ContainsKey('Scenario')) {
        throw ("Map '{0}' is missing its Scenario block." -f $Map.Name)
    }

    $scenario = $Map.Scenario
    if (-not ($scenario -is [System.Collections.IDictionary])) {
        throw ("Map '{0}' scenario must be a hashtable." -f $Map.Name)
    }

    foreach ($requiredKey in @('Name', 'Entry', 'ShardPool')) {
        if (-not $scenario.ContainsKey($requiredKey)) {
            throw ("Map '{0}' scenario is missing '{1}'." -f $Map.Name, $requiredKey)
        }
    }

    $scenarioName = [string]$scenario.Name
    $scenarioEntry = [string]$scenario.Entry
    if ([string]::IsNullOrWhiteSpace($scenarioName)) {
        throw ("Map '{0}' scenario must define a non-empty Name." -f $Map.Name)
    }

    if ([string]::IsNullOrWhiteSpace($scenarioEntry)) {
        throw ("Map '{0}' scenario must define a non-empty Entry." -f $Map.Name)
    }

    $occupied = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    foreach ($anchor in @($Anchors.Terminals) + @($Anchors.Surges) + @($Anchors.Enemies)) {
        [void]$occupied.Add(("{0},{1}" -f $anchor.X, $anchor.Y))
    }

    $poolEntries = @($scenario.ShardPool)
    if ($poolEntries.Count -ne $Constants.SHARD_POOL_COUNT) {
        throw ("Map '{0}' scenario must define exactly {1} shard-pool coordinates." -f $Map.Name, $Constants.SHARD_POOL_COUNT)
    }

    $seenPool = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    $rows = @($Map.Rows | ForEach-Object { [string]$_ })
    $pool = New-Object 'System.Collections.Generic.List[object]'

    foreach ($token in $poolEntries) {
        $point = ConvertTo-AnchorPoint -Token ([string]$token) -Constants $Constants -Context ("Shard pool in {0}" -f $Map.Name)
        if (([string]$rows[$point.Y]).ToCharArray()[$point.X] -eq '#') {
            throw ("Shard-pool coordinate ({0},{1}) in map '{2}' must sit on a floor tile." -f $point.X, $point.Y, $Map.Name)
        }

        if (($point.X -eq $Constants.START_X -and $point.Y -eq $Constants.START_Y) -or ($point.X -eq $Constants.EXIT_COL -and $point.Y -eq $Constants.EXIT_ROW)) {
            throw ("Shard-pool coordinate ({0},{1}) in map '{2}' cannot sit on the start or exit tile." -f $point.X, $point.Y, $Map.Name)
        }

        $key = ("{0},{1}" -f $point.X, $point.Y)
        if ($occupied.Contains($key)) {
            throw ("Shard-pool coordinate ({0},{1}) in map '{2}' overlaps an authored anchor." -f $point.X, $point.Y, $Map.Name)
        }

        if (-not $seenPool.Add($key)) {
            throw ("Map '{0}' scenario defines duplicate shard-pool tile ({1},{2})." -f $Map.Name, $point.X, $point.Y)
        }

        $pool.Add($point)
    }

    return [pscustomobject]@{
        Name = $scenarioName
        Entry = $scenarioEntry
        ShardPool = $pool.ToArray()
    }
}

function Copy-SectorLayout {
    param(
        $State,
        $Constants,
        $Map
    )

    $rows = @($Map.Rows)
    if ($rows.Count -ne $Constants.MAP_H) {
        throw ("Map '{0}' height mismatch: expected {1}, found {2}." -f $Map.Name, $Constants.MAP_H, $rows.Count)
    }

    for ($y = 0; $y -lt $Constants.MAP_H; $y++) {
        $row = [string]$rows[$y]
        if ($row.Length -ne $Constants.MAP_W) {
            throw ("Map '{0}' row {1} width mismatch: expected {2}, found {3}." -f $Map.Name, ($y + 1), $Constants.MAP_W, $row.Length)
        }

        for ($x = 0; $x -lt $Constants.MAP_W; $x++) {
            $tile = if ($row[$x] -eq '#') { 'WALL' } else { 'FLOOR' }
            Set-Tile -State $State -Constants $Constants -X $x -Y $y -Tile $tile
        }
    }
}

function Clear-EnemyTable {
    param($State)

    foreach ($enemy in $State.Enemies) {
        $enemy.Alive = $false
        $enemy.X = 0
        $enemy.Y = 0
        $enemy.Kind = 'RUSHER'
    }
}

function Set-ExitLocked {
    param(
        $State,
        $Constants
    )

    Set-Tile -State $State -Constants $Constants -X $Constants.EXIT_COL -Y $Constants.EXIT_ROW -Tile 'EXIT_LOCKED'
}

function Open-Exit {
    param($State, $Constants)
    Set-Tile -State $State -Constants $Constants -X $State.ExitX -Y $State.ExitY -Tile 'EXIT_OPEN'
}

function Get-SectorEnemyCount {
    param(
        $State,
        $Constants,
        $Sectors
    )

    $rules = Get-SectorRules -Sectors $Sectors -SectorId $State.SectorNum
    return ($State.SectorNum * $Constants.ENEMY_SPAWN_STEP) + $Constants.ENEMY_SPAWN_BASE + [int]$rules.EnemyBonus
}

function Get-RandomFloorPosition {
    param(
        $State,
        $Constants
    )

    while ($true) {
        $x = Get-RandomX -State $State.Rng -PlayMaxX $Constants.PLAY_MAX_X
        $y = Get-RandomY -State $State.Rng -PlayMaxY $Constants.PLAY_MAX_Y
        if (($x -eq $Constants.START_X -and $y -eq $Constants.START_Y) -or ($x -eq $Constants.EXIT_COL -and $y -eq $Constants.EXIT_ROW)) {
            continue
        }

        if ((Get-Tile -State $State -Constants $Constants -X $x -Y $y) -ne 'FLOOR') {
            continue
        }

        return [pscustomobject]@{ X = $x; Y = $y }
    }
}

function Get-RandomTerminalPosition {
    param(
        $State,
        $Constants
    )

    while ($true) {
        $position = Get-RandomFloorPosition -State $State -Constants $Constants
        if ($position.X -le $Constants.SAFE_X_MAX -and $position.Y -ge $Constants.SAFE_Y_MIN) {
            continue
        }

        return $position
    }
}

function Get-RandomEnemyPosition {
    param(
        $State,
        $Constants
    )

    while ($true) {
        $position = Get-RandomFloorPosition -State $State -Constants $Constants
        if ($position.X -le $Constants.SAFE_X_MAX -and $position.Y -ge $Constants.SAFE_Y_MIN) {
            continue
        }

        if ((Find-EnemyIndex -State $State -X $position.X -Y $position.Y) -ge 0) {
            continue
        }

        return $position
    }
}

function Get-RandomShardPosition {
    param(
        $State,
        $Constants
    )

    while ($true) {
        $position = Get-RandomFloorPosition -State $State -Constants $Constants
        if ((Find-EnemyIndex -State $State -X $position.X -Y $position.Y) -ge 0) {
            continue
        }

        return $position
    }
}

function Roll-EnemyKind {
    param(
        $State,
        $Sectors
    )

    $rules = Get-SectorRules -Sectors $Sectors -SectorId $State.SectorNum
    $rngWord = Get-NextRngWord -State $State.Rng
    $lowByte = ($rngWord -band 0xFF)

    if ([int]$rules.WardenThreshold -gt 0 -and $lowByte -lt [int]$rules.WardenThreshold) {
        return 'WARDEN'
    }

    if ($lowByte -lt [int]$rules.FlankerThreshold) {
        return 'FLANKER'
    }

    return 'RUSHER'
}

function Place-AnchoredTerminals {
    param(
        $State,
        $Constants,
        [object[]]$Anchors
    )

    foreach ($anchor in $Anchors) {
        Set-Tile -State $State -Constants $Constants -X $anchor.X -Y $anchor.Y -Tile 'TERMINAL'
    }
}

function Place-Terminals {
    param(
        $State,
        $Constants,
        $Sectors,
        [int]$AnchorCount = 0
    )

    $rules = Get-SectorRules -Sectors $Sectors -SectorId $State.SectorNum
    $remainingCount = [int]$rules.TerminalCount - $AnchorCount
    for ($i = 0; $i -lt $remainingCount; $i++) {
        $position = Get-RandomTerminalPosition -State $State -Constants $Constants
        Set-Tile -State $State -Constants $Constants -X $position.X -Y $position.Y -Tile 'TERMINAL'
    }
}

function Place-ScenarioShards {
    param(
        $State,
        $Constants,
        [object[]]$ShardPool
    )

    $available = New-Object 'System.Collections.Generic.List[object]'
    foreach ($point in $ShardPool) {
        $available.Add($point)
    }

    for ($i = 0; $i -lt $Constants.SHARD_COUNT; $i++) {
        $word = Get-NextRngWord -State $State.Rng
        $index = ($word -band 0xFF) % $available.Count
        $point = $available[$index]
        Set-Tile -State $State -Constants $Constants -X $point.X -Y $point.Y -Tile 'SHARD'
        $available.RemoveAt($index)
    }
}

function Place-AnchoredSurges {
    param(
        $State,
        $Constants,
        [object[]]$Anchors
    )

    foreach ($anchor in $Anchors) {
        Set-Tile -State $State -Constants $Constants -X $anchor.X -Y $anchor.Y -Tile 'SURGE'
    }
}

function Place-Surges {
    param(
        $State,
        $Constants,
        $Sectors,
        [int]$AnchorCount = 0
    )

    $rules = Get-SectorRules -Sectors $Sectors -SectorId $State.SectorNum
    $remainingCount = [int]$rules.SurgeCount - $AnchorCount
    for ($i = 0; $i -lt $remainingCount; $i++) {
        $position = Get-RandomFloorPosition -State $State -Constants $Constants
        Set-Tile -State $State -Constants $Constants -X $position.X -Y $position.Y -Tile 'SURGE'
    }
}

function Get-FreeEnemySlot {
    param($State)

    foreach ($enemy in $State.Enemies) {
        if (-not $enemy.Alive) {
            return $enemy
        }
    }

    throw 'Encounter placement exhausted the enemy table.'
}

function Place-AnchoredEnemies {
    param(
        $State,
        [object[]]$Anchors
    )

    foreach ($anchor in $Anchors) {
        $enemy = Get-FreeEnemySlot -State $State
        $enemy.Alive = $true
        $enemy.X = $anchor.X
        $enemy.Y = $anchor.Y
        $enemy.Kind = [string]$anchor.Kind
    }
}

function Place-Enemies {
    param(
        $State,
        $Constants,
        $Sectors,
        [int]$AnchorCount = 0
    )

    $enemyCount = (Get-SectorEnemyCount -State $State -Constants $Constants -Sectors $Sectors) - $AnchorCount
    for ($i = 0; $i -lt $enemyCount; $i++) {
        $position = Get-RandomEnemyPosition -State $State -Constants $Constants
        $enemy = Get-FreeEnemySlot -State $State
        $enemy.Alive = $true
        $enemy.X = $position.X
        $enemy.Y = $position.Y
        $enemy.Kind = Roll-EnemyKind -State $State -Sectors $Sectors
    }
}

function Load-ReplaySector {
    param(
        $State,
        $Constants,
        $Sectors
    )

    if ($State.SectorNum -ne 1 -and $State.PulseCount -lt $Constants.MAX_PULSES) {
        $State.PulseCount += 1
    }

    $State.DataCount = 0
    $State.LastPlayerDx = 0
    $State.LastPlayerDy = 0
    $State.SpoofTimer = 0
    $State.SpoofX = $Constants.START_X
    $State.SpoofY = $Constants.START_Y
    Reset-SectorMastery -State $State
    Clear-EnemyTable -State $State

    $map = Select-SectorMap -State $State -Sectors $Sectors
    $State.CurrentMapName = [string]$map.Name
    $anchors = Get-MapAnchors -Map $map -State $State -Constants $Constants -Sectors $Sectors
    $scenario = Get-MapScenario -Map $map -Anchors $anchors -Constants $Constants
    Copy-SectorLayout -State $State -Constants $Constants -Map $map

    $State.PlayerX = $Constants.START_X
    $State.PlayerY = $Constants.START_Y
    $State.ExitX = $Constants.EXIT_COL
    $State.ExitY = $Constants.EXIT_ROW
    Set-ExitLocked -State $State -Constants $Constants
    Place-AnchoredTerminals -State $State -Constants $Constants -Anchors $anchors.Terminals
    Place-AnchoredSurges -State $State -Constants $Constants -Anchors $anchors.Surges
    Place-AnchoredEnemies -State $State -Anchors $anchors.Enemies
    Place-ScenarioShards -State $State -Constants $Constants -ShardPool $scenario.ShardPool
    Place-Terminals -State $State -Constants $Constants -Sectors $Sectors -AnchorCount $anchors.Terminals.Count
    Place-Surges -State $State -Constants $Constants -Sectors $Sectors -AnchorCount $anchors.Surges.Count
    Place-Enemies -State $State -Constants $Constants -Sectors $Sectors -AnchorCount $anchors.Enemies.Count
}

function Get-ProjectedPlayerTarget {
    param(
        $State,
        $Constants
    )

    $targetX = $State.PlayerX
    $targetY = $State.PlayerY
    if ($State.LastPlayerDx -ne 0) {
        $candidateX = $targetX + $State.LastPlayerDx
        if ($candidateX -ge $Constants.PLAY_MIN_X -and $candidateX -le $Constants.PLAY_MAX_X) {
            $targetX = $candidateX
        }
    }

    if ($State.LastPlayerDy -ne 0) {
        $candidateY = $targetY + $State.LastPlayerDy
        if ($candidateY -ge $Constants.PLAY_MIN_Y -and $candidateY -le $Constants.PLAY_MAX_Y) {
            $targetY = $candidateY
        }
    }

    return [pscustomobject]@{
        X = $targetX
        Y = $targetY
    }
}

function Get-EnemyTargetDelta {
    param(
        $Enemy,
        [int]$TargetX,
        [int]$TargetY
    )

    return [pscustomobject]@{
        Dx = [Math]::Abs($TargetX - $Enemy.X)
        Dy = [Math]::Abs($TargetY - $Enemy.Y)
    }
}

function Try-EnemyStep {
    param(
        $State,
        $Constants,
        [int]$EnemyIndex,
        [int]$TargetX,
        [int]$TargetY
    )

    $enemy = $State.Enemies[$EnemyIndex]
    if ($TargetX -eq $State.PlayerX -and $TargetY -eq $State.PlayerY) {
        Record-SectorHit -State $State
        $State.ShieldCount -= 1
        $enemy.Alive = $false
        Set-ReplayMessageEvent -State $State -MessageKey 'HIT'
        if ($State.ShieldCount -le 0) {
            $State.GameState = 'LOSE'
        }

        return $true
    }

    $tile = Get-Tile -State $State -Constants $Constants -X $TargetX -Y $TargetY
    if ($tile -in @('WALL', 'EXIT_LOCKED', 'EXIT_OPEN')) {
        return $false
    }

    if ((Find-EnemyIndex -State $State -X $TargetX -Y $TargetY -IgnoreIndex $EnemyIndex) -ge 0) {
        return $false
    }

    if ($tile -eq 'SURGE') {
        Set-Tile -State $State -Constants $Constants -X $TargetX -Y $TargetY -Tile 'FLOOR'
        $enemy.Alive = $false
        Award-Kill -State $State -Constants $Constants
        Award-Score -State $State -Points $Constants.SCORE_TRAP_BONUS
        Set-ReplayMessageEvent -State $State -MessageKey 'TRAP'
        return $true
    }

    $enemy.X = $TargetX
    $enemy.Y = $TargetY
    return $true
}

function Move-EnemyTowardTarget {
    param(
        $State,
        $Constants,
        [int]$EnemyIndex,
        [int]$TargetX,
        [int]$TargetY,
        [switch]$PreferVertical
    )

    $enemy = $State.Enemies[$EnemyIndex]
    $steps = @()

    if ($PreferVertical.IsPresent) {
        if ($enemy.Y -ne $TargetY) {
            $directionY = if ($enemy.Y -lt $TargetY) { 1 } else { -1 }
            $steps += [pscustomobject]@{ X = $enemy.X; Y = ($enemy.Y + $directionY) }
        }

        if ($enemy.X -ne $TargetX) {
            $directionX = if ($enemy.X -lt $TargetX) { 1 } else { -1 }
            $steps += [pscustomobject]@{ X = ($enemy.X + $directionX); Y = $enemy.Y }
        }
    } else {
        if ($enemy.X -ne $TargetX) {
            $directionX = if ($enemy.X -lt $TargetX) { 1 } else { -1 }
            $steps += [pscustomobject]@{ X = ($enemy.X + $directionX); Y = $enemy.Y }
        }

        if ($enemy.Y -ne $TargetY) {
            $directionY = if ($enemy.Y -lt $TargetY) { 1 } else { -1 }
            $steps += [pscustomobject]@{ X = $enemy.X; Y = ($enemy.Y + $directionY) }
        }
    }

    foreach ($step in $steps) {
        if (Try-EnemyStep -State $State -Constants $Constants -EnemyIndex $EnemyIndex -TargetX $step.X -TargetY $step.Y) {
            return
        }
    }
}

function Move-Enemy {
    param(
        $State,
        $Constants,
        $Sectors,
        [int]$EnemyIndex
    )

    $enemy = $State.Enemies[$EnemyIndex]
    if (-not $enemy.Alive) {
        return
    }

    $targetX = $State.PlayerX
    $targetY = $State.PlayerY
    $preferVertical = $false

    if ($State.SpoofTimer -gt 0) {
        $targetX = $State.ExitX
        $targetY = $State.ExitY
        $delta = Get-EnemyTargetDelta -Enemy $enemy -TargetX $targetX -TargetY $targetY
        $preferVertical = ($delta.Dy -ge $delta.Dx)
    } elseif ($enemy.Kind -eq 'FLANKER') {
        $projected = Get-ProjectedPlayerTarget -State $State -Constants $Constants
        $targetX = $projected.X
        $targetY = $projected.Y
        $delta = Get-EnemyTargetDelta -Enemy $enemy -TargetX $targetX -TargetY $targetY
        $preferVertical = ($delta.Dy -ge $delta.Dx)
    } elseif ($enemy.Kind -eq 'WARDEN') {
        $playerDelta = Get-EnemyTargetDelta -Enemy $enemy -TargetX $State.PlayerX -TargetY $State.PlayerY
        $distance = $playerDelta.Dx + $playerDelta.Dy
        $engageDistance = [int](Get-SectorRules -Sectors $Sectors -SectorId $State.SectorNum).WardenEngageDistance
        if ($distance -le $engageDistance) {
            if ($State.SectorNum -eq 3) {
                $projected = Get-ProjectedPlayerTarget -State $State -Constants $Constants
                $targetX = $projected.X
                $targetY = $projected.Y
            } else {
                $targetX = $State.PlayerX
                $targetY = $State.PlayerY
            }
        } else {
            $targetX = $State.ExitX
            $targetY = $State.ExitY
        }

        $delta = Get-EnemyTargetDelta -Enemy $enemy -TargetX $targetX -TargetY $targetY
        $preferVertical = ($delta.Dy -ge $delta.Dx)
    }

    Move-EnemyTowardTarget -State $State -Constants $Constants -EnemyIndex $EnemyIndex -TargetX $targetX -TargetY $targetY -PreferVertical:$preferVertical
}

function Clear-EnemyPressure {
    param($State)
    $State.ThreatLevel = 0
}

function Get-EnemyPlayerDelta {
    param($State, $Enemy)

    return [pscustomobject]@{
        Dx = [Math]::Abs($State.PlayerX - $Enemy.X)
        Dy = [Math]::Abs($State.PlayerY - $Enemy.Y)
    }
}

function Evaluate-EnemyThreat {
    param(
        $State,
        $Constants,
        $Enemy
    )

    $delta = Get-EnemyPlayerDelta -State $State -Enemy $Enemy
    $distance = $delta.Dx + $delta.Dy
    if ($distance -le $Constants.NEAR_THREAT_DISTANCE) {
        if ($Enemy.Kind -eq 'WARDEN' -and $State.SectorNum -eq 3) {
            return 2
        }

        return 1
    }

    if ($Enemy.Kind -eq 'WARDEN' -and $State.SectorNum -eq 3 -and $distance -le $Constants.ELITE_THREAT_DISTANCE) {
        return 2
    }

    return 0
}

function Update-EnemyPressure {
    param(
        $State,
        $Constants
    )

    Clear-EnemyPressure -State $State
    foreach ($enemy in $State.Enemies) {
        if (-not $enemy.Alive) {
            continue
        }

        $threat = Evaluate-EnemyThreat -State $State -Constants $Constants -Enemy $enemy
        if ($threat -le $State.ThreatLevel) {
            continue
        }

        $State.ThreatLevel = $threat
        $State.ThreatX = $enemy.X
        $State.ThreatY = $enemy.Y
        if ($threat -eq 2) {
            break
        }
    }
}

function Run-EnemyTurn {
    param(
        $State,
        $Constants,
        $Sectors
    )

    Clear-EnemyPressure -State $State
    for ($i = 0; $i -lt $State.Enemies.Count; $i++) {
        Move-Enemy -State $State -Constants $Constants -Sectors $Sectors -EnemyIndex $i
        if ($State.GameState -ne 'PLAYING') {
            break
        }
    }

    if ($State.GameState -eq 'PLAYING') {
        Update-EnemyPressure -State $State -Constants $Constants
        if ($State.SpoofTimer -gt 0) {
            $State.SpoofTimer -= 1
        }
    }
}

function Use-Pulse {
    param(
        $State,
        $Constants
    )

    if ($State.PulseCount -le 0) {
        Set-ReplayMessageEvent -State $State -MessageKey 'NOPULSE'
        return $false
    }

    $State.PulseCount -= 1
    Record-SectorPulse -State $State
    Set-ReplayMessageEvent -State $State -MessageKey 'PULSE'
    $kills = 0
    foreach ($enemy in $State.Enemies) {
        if (-not $enemy.Alive) {
            continue
        }

        if ([Math]::Abs($enemy.X - $State.PlayerX) -gt $Constants.PULSE_RADIUS) {
            continue
        }

        if ([Math]::Abs($enemy.Y - $State.PlayerY) -gt $Constants.PULSE_RADIUS) {
            continue
        }

        $enemy.Alive = $false
        Award-Kill -State $State -Constants $Constants
        $kills += 1
    }

    if ($kills -gt 1) {
        Award-Score -State $State -Points (($kills - 1) * $Constants.SCORE_CHAIN_STEP)
    }

    if ($kills -ge $Constants.PULSE_RECHARGE_KILLS -and $State.PulseCount -lt $Constants.MAX_PULSES) {
        $State.PulseCount += 1
        Set-ReplayMessageEvent -State $State -MessageKey 'RECHARGE'
    }

    return $true
}

function Attempt-MoveTo {
    param(
        $State,
        $Constants,
        $Sectors,
        [int]$TargetX,
        [int]$TargetY
    )

    $enemyIndex = Find-EnemyIndex -State $State -X $TargetX -Y $TargetY
    if ($enemyIndex -ge 0) {
        $State.Enemies[$enemyIndex].Alive = $false
        Award-Kill -State $State -Constants $Constants
        Commit-PlayerMove -State $State -TargetX $TargetX -TargetY $TargetY
        Set-ReplayMessageEvent -State $State -MessageKey 'KILL'
        return $true
    }

    $tile = Get-Tile -State $State -Constants $Constants -X $TargetX -Y $TargetY
    switch ($tile) {
        'WALL' {
            Set-ReplayMessageEvent -State $State -MessageKey 'BLOCK'
            return $false
        }
        'EXIT_LOCKED' {
            Set-ReplayMessageEvent -State $State -MessageKey 'BLOCK'
            return $false
        }
        'SHARD' {
            Set-Tile -State $State -Constants $Constants -X $TargetX -Y $TargetY -Tile 'FLOOR'
            Commit-PlayerMove -State $State -TargetX $TargetX -TargetY $TargetY
            $State.DataCount += 1
            Award-Score -State $State -Points $Constants.SCORE_SHARD_POINTS
            if ($State.DataCount -ge $Constants.SHARD_COUNT) {
                Open-Exit -State $State -Constants $Constants
                Set-ReplayMessageEvent -State $State -MessageKey 'GATE'
            } else {
                Set-ReplayMessageEvent -State $State -MessageKey 'SHARD'
            }

            return $true
        }
        'TERMINAL' {
            Set-Tile -State $State -Constants $Constants -X $TargetX -Y $TargetY -Tile 'FLOOR'
            Commit-PlayerMove -State $State -TargetX $TargetX -TargetY $TargetY
            $State.SpoofX = $TargetX
            $State.SpoofY = $TargetY
            $State.SpoofTimer = $Constants.SPOOF_TURNS
            Set-ReplayMessageEvent -State $State -MessageKey 'SPOOF'
            return $true
        }
        'EXIT_OPEN' {
            Record-SectorAction -State $State
            Finalize-SectorMastery -State $State -Constants $Constants
            if ($State.SectorNum -eq $Constants.TOTAL_SECTORS) {
                Award-FinalMasteryBonus -State $State -Constants $Constants
                $State.GameState = 'WIN'
                return $false
            }

            $State.SectorNum += 1
            Load-ReplaySector -State $State -Constants $Constants -Sectors $Sectors
            Set-ReplayMessageEvent -State $State -MessageKey 'SECTOR'
            return $false
        }
        'SURGE' {
            Set-Tile -State $State -Constants $Constants -X $TargetX -Y $TargetY -Tile 'FLOOR'
            Commit-PlayerMove -State $State -TargetX $TargetX -TargetY $TargetY
            Record-SectorHit -State $State
            $State.ShieldCount -= $Constants.SURGE_PLAYER_DAMAGE
            Set-ReplayMessageEvent -State $State -MessageKey 'SURGE'
            if ($State.ShieldCount -le 0) {
                $State.GameState = 'LOSE'
            }

            return $true
        }
        default {
            Commit-PlayerMove -State $State -TargetX $TargetX -TargetY $TargetY
            return $true
        }
    }
}

function Process-ReplayAction {
    param(
        $State,
        $Constants,
        $Sectors,
        [string]$Action
    )

    if ($State.GameState -ne 'PLAYING') {
        return
    }

    $actionTaken = $false
    switch ($Action) {
        'WAIT' {
            return
        }
        'PULSE' {
            $actionTaken = Use-Pulse -State $State -Constants $Constants
        }
        'LEFT' {
            if ($State.PlayerX -gt $Constants.PLAY_MIN_X) {
                $actionTaken = Attempt-MoveTo -State $State -Constants $Constants -Sectors $Sectors -TargetX ($State.PlayerX - 1) -TargetY $State.PlayerY
            } else {
                Set-ReplayMessageEvent -State $State -MessageKey 'BLOCK'
            }
        }
        'RIGHT' {
            if ($State.PlayerX -lt $Constants.PLAY_MAX_X) {
                $actionTaken = Attempt-MoveTo -State $State -Constants $Constants -Sectors $Sectors -TargetX ($State.PlayerX + 1) -TargetY $State.PlayerY
            } else {
                Set-ReplayMessageEvent -State $State -MessageKey 'BLOCK'
            }
        }
        'UP' {
            if ($State.PlayerY -gt $Constants.PLAY_MIN_Y) {
                $actionTaken = Attempt-MoveTo -State $State -Constants $Constants -Sectors $Sectors -TargetX $State.PlayerX -TargetY ($State.PlayerY - 1)
            } else {
                Set-ReplayMessageEvent -State $State -MessageKey 'BLOCK'
            }
        }
        'DOWN' {
            if ($State.PlayerY -lt $Constants.PLAY_MAX_Y) {
                $actionTaken = Attempt-MoveTo -State $State -Constants $Constants -Sectors $Sectors -TargetX $State.PlayerX -TargetY ($State.PlayerY + 1)
            } else {
                Set-ReplayMessageEvent -State $State -MessageKey 'BLOCK'
            }
        }
        default {
            throw ("Unsupported replay action '{0}'." -f $Action)
        }
    }

    if ($State.GameState -eq 'PLAYING' -and $actionTaken) {
        Record-SectorAction -State $State
        Run-EnemyTurn -State $State -Constants $Constants -Sectors $Sectors
    }
}

function Get-AliveEnemyCount {
    param($State)
    return @($State.Enemies | Where-Object { $_.Alive }).Count
}

function Get-ObservedReplayResult {
    param($State)

    return [ordered]@{
        State = $State.GameState
        Sector = $State.SectorNum
        Map = $State.CurrentMapName
        Player = ("{0},{1}" -f $State.PlayerX, $State.PlayerY)
        Shields = $State.ShieldCount
        Pulses = $State.PulseCount
        Data = $State.DataCount
        Kills = $State.KillCount
        AliveEnemies = (Get-AliveEnemyCount -State $State)
        Score = $State.ScoreTotal
        Actions = $State.SectorActions
        Hits = $State.SectorHits
        PulsesUsed = $State.SectorPulsesUsed
        Spoof = $State.SpoofTimer
        Sound = $State.SoundId
        SoundTimer = $State.SoundTimer
        MusicTheme = $State.MusicTheme
        MusicTicks = $State.MusicTicks
        MusicNote = $State.MusicNote
        Rng = (Format-Hex16 $State.Rng.Value)
    }
}

function Get-ReplaySignature {
    param($Observed)

    return ("{0}|S{1}|{2}|P{3}|H{4}|C{5}|D{6}|K{7}|E{8}|SCORE{9}|A{10}|HITS{11}|PU{12}|SP{13}|RNG{14}" -f `
        $Observed.State,
        $Observed.Sector,
        $Observed.Map,
        $Observed.Player,
        $Observed.Shields,
        $Observed.Pulses,
        $Observed.Data,
        $Observed.Kills,
        $Observed.AliveEnemies,
        $Observed.Score,
        $Observed.Actions,
        $Observed.Hits,
        $Observed.PulsesUsed,
        $Observed.Spoof,
        $Observed.Rng)
}

function ConvertTo-ExpectationBlock {
    param(
        [string]$Indent,
        $Observed
    )

    return @(
        ("{0}Expected = @{{" -f $Indent)
        ("{0}    State = '{1}'" -f $Indent, $Observed.State)
        ("{0}    Sector = {1}" -f $Indent, $Observed.Sector)
        ("{0}    Map = '{1}'" -f $Indent, $Observed.Map)
        ("{0}    Player = '{1}'" -f $Indent, $Observed.Player)
        ("{0}    Shields = {1}" -f $Indent, $Observed.Shields)
        ("{0}    Pulses = {1}" -f $Indent, $Observed.Pulses)
        ("{0}    Data = {1}" -f $Indent, $Observed.Data)
        ("{0}    Kills = {1}" -f $Indent, $Observed.Kills)
        ("{0}    AliveEnemies = {1}" -f $Indent, $Observed.AliveEnemies)
        ("{0}    Score = {1}" -f $Indent, $Observed.Score)
        ("{0}    Actions = {1}" -f $Indent, $Observed.Actions)
        ("{0}    Hits = {1}" -f $Indent, $Observed.Hits)
        ("{0}    PulsesUsed = {1}" -f $Indent, $Observed.PulsesUsed)
        ("{0}    Spoof = {1}" -f $Indent, $Observed.Spoof)
        ("{0}    Rng = {1}" -f $Indent, $Observed.Rng)
        ("{0}}}" -f $Indent)
    )
}

function Compare-ExpectedReplayResult {
    param(
        [string]$DemoName,
        $Expected,
        $Observed
    )

    $requiredKeys = @(
        'State',
        'Sector',
        'Map',
        'Player',
        'Shields',
        'Pulses',
        'Data',
        'Kills',
        'AliveEnemies',
        'Score',
        'Actions',
        'Hits',
        'PulsesUsed',
        'Spoof',
        'Rng'
    )

    $issues = New-Object 'System.Collections.Generic.List[string]'
    if (-not ($Expected -is [System.Collections.IDictionary])) {
        $issues.Add(("Demo '{0}' is missing its Expected replay result block." -f $DemoName))
        return $issues.ToArray()
    }

    foreach ($key in $requiredKeys) {
        if (-not $Expected.ContainsKey($key)) {
            $issues.Add(("Demo '{0}' is missing Expected.{1}." -f $DemoName, $key))
            continue
        }

        if ($key -eq 'Rng') {
            $expectedValue = if ($Expected[$key] -is [int]) { Format-Hex16 $Expected[$key] } else { [string]$Expected[$key] }
        } else {
            $expectedValue = [string]$Expected[$key]
        }

        $observedValue = [string]$Observed[$key]
        if ($expectedValue -ne $observedValue) {
            $issues.Add(("Demo '{0}' Expected.{1} = '{2}', observed '{3}'." -f $DemoName, $key, $expectedValue, $observedValue))
        }
    }

    return $issues.ToArray()
}

function Invoke-ReplayScenario {
    param(
        $Demo,
        $Constants,
        $Sectors,
        [object[]]$GameplayKits,
        [bool]$MusicEnabled,
        $MusicThemes
    )

    $name = [string]$Demo.Name
    if ([string]::IsNullOrWhiteSpace($name)) {
        throw 'Replay demo is missing its Name.'
    }

    $startSector = [int]$Demo.StartSector
    if ($startSector -lt 1 -or $startSector -gt $Constants.TOTAL_SECTORS) {
        throw ("Demo '{0}' must use StartSector 1..{1}." -f $name, $Constants.TOTAL_SECTORS)
    }

    $seed = [int]$Demo.Seed
    if ($seed -lt 0 -or $seed -gt 0xFFFF) {
        throw ("Demo '{0}' must use a 16-bit seed." -f $name)
    }

    $demoId = if (($Demo -is [System.Collections.IDictionary]) -and $Demo.ContainsKey('Id')) { [string]$Demo.Id } else { '' }
    if ([string]::IsNullOrWhiteSpace($demoId)) {
        throw ("Demo '{0}' must define a stable Id." -f $name)
    }

    $captureRole = if (($Demo -is [System.Collections.IDictionary]) -and $Demo.ContainsKey('CaptureRole')) { [string]$Demo.CaptureRole } else { '' }
    if ([string]::IsNullOrWhiteSpace($captureRole)) {
        throw ("Demo '{0}' must define a CaptureRole." -f $name)
    }

    $captureTicks = if (($Demo -is [System.Collections.IDictionary]) -and $Demo.ContainsKey('CaptureTicks')) { [int]$Demo.CaptureTicks } else { -1 }
    if ($captureTicks -lt 0 -or $captureTicks -gt 255) {
        throw ("Demo '{0}' must define CaptureTicks in the 0..255 range." -f $name)
    }

    $steps = @($Demo.Steps)
    if ($steps.Count -eq 0) {
        throw ("Demo '{0}' does not define any Steps." -f $name)
    }

    $state = New-ReplayState -Constants $Constants -Sectors $Sectors -StartSector $startSector -Seed $seed
    $captureRuntimeCheckpoints = if (($Demo -is [System.Collections.IDictionary]) -and $Demo.ContainsKey('RuntimeCheckpoints')) { [bool]$Demo['RuntimeCheckpoints'] } else { $true }
    $checkpointSignatures = New-Object 'System.Collections.Generic.List[int]'
    foreach ($step in $steps) {
        $parsedStep = Get-StepActionKey -Step $step -DemoName $name
        for ($tick = 0; $tick -lt $parsedStep.Count; $tick++) {
            $state.TraceTicks += 1
            Update-ReplayFeedback -State $state -MusicEnabled $MusicEnabled -MusicThemes $MusicThemes
            Process-ReplayAction -State $state -Constants $Constants -Sectors $Sectors -Action $parsedStep.Action
            if ($captureRuntimeCheckpoints -and $parsedStep.Action -ne 'WAIT') {
                $checkpointSignatures.Add((Get-RuntimeVerificationSignature -State $state -Constants $Constants -GameplayKits $GameplayKits))
            }
            if ($state.GameState -ne 'PLAYING') {
                break
            }
        }

        if ($state.GameState -ne 'PLAYING') {
            break
        }
    }

    if ($state.GameState -in @('WIN', 'LOSE')) {
        Update-ReplayFeedback -State $state -MusicEnabled $MusicEnabled -MusicThemes $MusicThemes
    }

    $observed = Get-ObservedReplayResult -State $state
    $expected = if (($Demo -is [System.Collections.IDictionary]) -and $Demo.ContainsKey('Expected')) { $Demo.Expected } else { $null }
    return [pscustomobject]@{
        Id = $demoId
        Name = $name
        StartSector = $startSector
        Seed = (Format-Hex16 $seed)
        CaptureRole = $captureRole
        CaptureTicks = $captureTicks
        Ticks = $state.TraceTicks
        Observed = $observed
        Signature = (Get-ReplaySignature -Observed $observed)
        RuntimeFinalSignature = (Get-RuntimeVerificationSignature -State $state -Constants $Constants -GameplayKits $GameplayKits)
        CheckpointSignatures = $checkpointSignatures.ToArray()
        SuggestedExpectation = (ConvertTo-ExpectationBlock -Indent '            ' -Observed $observed)
        Mismatches = (Compare-ExpectedReplayResult -DemoName $name -Expected $expected -Observed $observed)
    }
}

$constants = Get-RequiredConstants -SourcePath $ConstantsSourcePath
$gameplayKits = Get-GameplayKitDefinitions -SourcePath $GeometrySourcePath
$sectorSource = Import-StructuredDataFile -SourcePath $SectorSourcePath -Label 'sector source'
$demoSource = Import-StructuredDataFile -SourcePath $DemoSourcePath -Label 'demo source'
$musicThemes = Get-MusicThemeDefinitions -SourcePath $MusicSourcePath

if (-not $sectorSource.ContainsKey('Sectors')) {
    throw ("Sector source must define a 'Sectors' array: {0}" -f $SectorSourcePath)
}

if (-not $demoSource.ContainsKey('Demos')) {
    throw ("Demo source must define a 'Demos' array: {0}" -f $DemoSourcePath)
}

$sectors = @($sectorSource.Sectors)
$demos = @($demoSource.Demos)
if ($demos.Count -eq 0) {
    throw ("Demo source must define at least one demo: {0}" -f $DemoSourcePath)
}

$reportLines = New-Object 'System.Collections.Generic.List[string]'
$summaryLines = New-Object 'System.Collections.Generic.List[string]'
$warningLines = New-Object 'System.Collections.Generic.List[string]'
$failureLines = New-Object 'System.Collections.Generic.List[string]'
$results = New-Object 'System.Collections.Generic.List[object]'

$reportLines.Add('CyberStorm Replay Harness')
$reportLines.Add(("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')))
$reportLines.Add(("Demo source: {0}" -f $DemoSourcePath))
$reportLines.Add(("Sector source: {0}" -f $SectorSourcePath))
$reportLines.Add(("Music source: {0}" -f $MusicSourcePath))
$reportLines.Add(("Audio mode: {0}" -f $(if ($musicEnabled) { 'MUSIC' } else { 'SFX_ONLY' })))
$reportLines.Add(("Scenarios: {0}" -f $demos.Count))
$reportLines.Add('')

foreach ($demo in $demos) {
    $name = if ($demo -is [System.Collections.IDictionary]) { [string]$demo.Name } else { '<invalid demo>' }
    $reportLines.Add(("Demo: {0}" -f $name))
    try {
        $result = Invoke-ReplayScenario -Demo $demo -Constants $constants -Sectors $sectors -GameplayKits $gameplayKits -MusicEnabled $musicEnabled -MusicThemes $musicThemes
        $results.Add($result)
        $summaryLines.Add(("{0}: {1}" -f $result.Name, $result.Signature))
        $reportLines.Add(("  Id: {0}" -f $result.Id))
        $reportLines.Add(("  Seed: {0}" -f $result.Seed))
        $reportLines.Add(("  Capture: role={0} ticks={1}" -f $result.CaptureRole, $result.CaptureTicks))
        $reportLines.Add(("  Ticks: {0}" -f $result.Ticks))
        $reportLines.Add(("  Signature: {0}" -f $result.Signature))
        $reportLines.Add(("  Runtime final signature: {0}" -f (Format-Hex16 $result.RuntimeFinalSignature)))
        $reportLines.Add(("  Runtime checkpoints: {0}" -f $result.CheckpointSignatures.Count))
        $reportLines.Add(("  Observed: state={0} sector={1} map={2} player={3} shields={4} pulses={5} data={6} kills={7} alive={8} score={9} actions={10} hits={11} pulses-used={12} spoof={13} rng={14}" -f `
                $result.Observed.State,
                $result.Observed.Sector,
                $result.Observed.Map,
                $result.Observed.Player,
                $result.Observed.Shields,
                $result.Observed.Pulses,
                $result.Observed.Data,
                $result.Observed.Kills,
                $result.Observed.AliveEnemies,
                $result.Observed.Score,
                $result.Observed.Actions,
                $result.Observed.Hits,
                $result.Observed.PulsesUsed,
                $result.Observed.Spoof,
                $result.Observed.Rng))
        $reportLines.Add(("  Audio: sound={0} timer={1} theme={2} ticks={3} note={4}" -f `
                $result.Observed.Sound,
                $result.Observed.SoundTimer,
                $result.Observed.MusicTheme,
                $result.Observed.MusicTicks,
                $result.Observed.MusicNote))

        if (@($result.Mismatches).Count -eq 0) {
            $reportLines.Add('  Status: PASS')
        } else {
            $reportLines.Add('  Status: FAIL')
            foreach ($mismatch in @($result.Mismatches)) {
                $reportLines.Add(("  Mismatch: {0}" -f $mismatch))
                $failureLines.Add($mismatch)
            }

            $reportLines.Add('  Suggested Expected block:')
            foreach ($line in $result.SuggestedExpectation) {
                $reportLines.Add($line)
            }
        }
    } catch {
        $failureMessage = ("Demo '{0}' failed to simulate: {1}" -f $name, $_.Exception.Message)
        $failureLines.Add($failureMessage)
        $reportLines.Add('  Status: ERROR')
        $reportLines.Add(("  Error: {0}" -f $_.Exception.Message))
    }

    $reportLines.Add('')
}

$reportLines.Add('Warnings')
if ($warningLines.Count -eq 0) {
    $reportLines.Add('  none')
} else {
    foreach ($warning in $warningLines) {
        $reportLines.Add(("  {0}" -f $warning))
    }
}

Set-Content -LiteralPath $ReportPath -Encoding ascii -Value $reportLines

if ($failureLines.Count -gt 0) {
    throw ("Replay harness found {0} failure(s). See {1} for observed states and suggested Expected blocks." -f $failureLines.Count, $ReportPath)
}

return [pscustomobject]@{
    ReportPath = $ReportPath
    ScenarioCount = $demos.Count
    SummaryLines = $summaryLines.ToArray()
    WarningLines = $warningLines.ToArray()
    Results = $results.ToArray()
}
