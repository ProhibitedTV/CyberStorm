param(
    [string]$SectorSourcePath = (Join-Path (Join-Path $PSScriptRoot '..') 'assets\sectors.psd1'),
    [string]$DemoSourcePath = (Join-Path (Join-Path $PSScriptRoot '..') 'assets\demos.psd1'),
    [string]$GeometrySourcePath = (Join-Path (Join-Path $PSScriptRoot '..') 'assets\geometry.psd1'),
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

function Get-RequiredConstants {
    param([string]$SourcePath)

    $constantNames = @(
        'STATE_TITLE',
        'STATE_PLAYING',
        'STATE_WIN',
        'STATE_LOSE',
        'START_SHIELDS',
        'MAP_W',
        'MAP_H',
        'PLAY_MIN_X',
        'PLAY_MIN_Y',
        'GAME3D_FLOOR_Y',
        'SCENE3D_NEAR_Z',
        'GAME3D_VIEW_X',
        'GAME3D_VIEW_Y',
        'GAME3D_VIEW_W',
        'GAME3D_VIEW_H',
        'GAME3D_CAMERA_HORIZON_CENTER_OFFSET',
        'GAME3D_PLAYER_LOCATOR_FAR_DEPTH',
        'GAME3D_CUE_EDGE_MARGIN',
        'GAME3D_CUE_FLAG_PLAYER_FALLBACK',
        'GAME3D_CUE_FLAG_EXIT_FALLBACK',
        'GAME3D_CUE_FLAG_SPOOF_FALLBACK',
        'GAME3D_CUE_FLAG_THREAT_FALLBACK',
        'GAME3D_SHOT_BASE_CHASE',
        'GAME3D_SHOT_MOVE_SETTLE',
        'GAME3D_SHOT_SECTOR_ENTRY',
        'GAME3D_SHOT_ENEMY_REVEAL',
        'GAME3D_SHOT_INTERACTION',
        'GAME3D_SHOT_WARDEN_PRESSURE',
        'GAME3D_SHOT_END_BEAT',
        'GAME3D_SHOT_REASON_NONE',
        'GAME3D_SHOT_REASON_MOVE',
        'GAME3D_SHOT_REASON_SECTOR',
        'GAME3D_SHOT_REASON_REVEAL',
        'GAME3D_SHOT_REASON_TERMINAL',
        'GAME3D_SHOT_REASON_GATE',
        'GAME3D_SHOT_REASON_WARDEN',
        'GAME3D_SHOT_REASON_WIN',
        'GAME3D_SHOT_REASON_LOSE',
        'GAME3D_FRAME_VARIANT_NONE',
        'GAME3D_FRAME_VARIANT_RAIL',
        'GAME3D_FRAME_VARIANT_DOOR',
        'GAME3D_FRAME_VARIANT_CEILING',
        'GAME3D_FRAME_VARIANT_FAR_MASS',
        'GAME3D_FRAME_VARIANT_LANDMARK',
        'GAME3D_SHOT_MOVE_IN',
        'GAME3D_SHOT_MOVE_HOLD',
        'GAME3D_SHOT_MOVE_OUT',
        'GAME3D_SHOT_SECTOR_HOLD',
        'GAME3D_SHOT_SECTOR_OUT',
        'GAME3D_SHOT_REVEAL_IN',
        'GAME3D_SHOT_REVEAL_HOLD',
        'GAME3D_SHOT_REVEAL_OUT',
        'GAME3D_SHOT_INTERACTION_IN',
        'GAME3D_SHOT_INTERACTION_HOLD',
        'GAME3D_SHOT_INTERACTION_OUT',
        'GAME3D_SHOT_WARDEN_IN',
        'GAME3D_SHOT_WARDEN_HOLD',
        'GAME3D_SHOT_WARDEN_OUT',
        'GAME3D_SHOT_END_IN',
        'GAME3D_SHOT_END_HOLD',
        'GAME3D_HEADING_NORTH',
        'GAME3D_HEADING_EAST',
        'GAME3D_HEADING_SOUTH',
        'GAME3D_HEADING_WEST',
        'GAME3D_ROOM_VARIANT_NORTHWEST',
        'GAME3D_ROOM_VARIANT_SOUTHWEST',
        'GAME3D_ROOM_VARIANT_NORTHEAST',
        'GAME3D_ROOM_VARIANT_SOUTHEAST',
        'GAME3D_YAW_SOUTH',
        'GAME3D_YAW_EAST',
        'GAME3D_YAW_NORTH',
        'GAME3D_YAW_WEST',
        'CAMPAIGN_DISTRICT_COUNT',
        'ADVENTURE_TURN_STEP',
        'ADVENTURE_MOVE_SPEED',
        'ADVENTURE_BACK_SPEED',
        'ADVENTURE_CHARGE_SPEED',
        'ADVENTURE_JUMP_VEL',
        'ADVENTURE_GRAVITY',
        'ADVENTURE_GLIDE_FALL_LIMIT',
        'ADVENTURE_CHARGE_TICKS',
        'ADVENTURE_FLAME_TICKS',
        'ADVENTURE_ENEMY_STEP_TICKS',
        'ADVENTURE_HAZARD_COOLDOWN',
        'ADVENTURE_INTRO_TICKS',
        'START_PULSES',
        'MAX_PULSES',
        'ENEMY_RUSHER',
        'ENEMY_FLANKER',
        'ENEMY_WARDEN',
        'THREAT_NONE',
        'THREAT_NEAR',
        'THREAT_ELITE',
        'NEAR_THREAT_DISTANCE',
        'ELITE_THREAT_DISTANCE',
        'SCORE_SHARD_POINTS',
        'SCORE_KILL_POINTS',
        'SCORE_TRAP_BONUS',
        'SCORE_CHAIN_STEP',
        'MSG_SECTOR',
        'MSG_BLOCK',
        'MSG_SHARD',
        'MSG_GATE',
        'MSG_HIT',
        'MSG_KILL',
        'MSG_PULSE',
        'MSG_NOPULSE',
        'MSG_SURGE',
        'MSG_TRAP',
        'MSG_RECHARGE',
        'MSG_SPOOF',
        'MSG_KEY',
        'FEEDBACK_TICKS_MINOR',
        'FEEDBACK_TICKS_STANDARD',
        'FEEDBACK_TICKS_MAJOR',
        'TILE_EXIT_LOCKED',
        'TILE_EXIT_OPEN',
        'TILE_FLOOR',
        'TILE_WALL',
        'TILE_SHARD',
        'TILE_SURGE',
        'TILE_TERMINAL',
        'TILE_KEY'
    )

    $constants = @{}
    foreach ($name in $constantNames) {
        $constants[$name] = Get-AsmEquValue -SourcePath $SourcePath -Name $name
    }

    $constants['PLAY_MAX_X'] = $constants.MAP_W - 2
    $constants['PLAY_MAX_Y'] = $constants.MAP_H - 2
    $constants['GAME3D_WORLD_ORIGIN_X'] = $constants.MAP_W * 128
    $constants['GAME3D_WORLD_ORIGIN_Z'] = $constants.MAP_H * 128

    return $constants
}

function Get-GameplayKitDefinitions {
    param([string]$SourcePath)

    $geometryData = Import-StructuredDataFile -SourcePath $SourcePath -Label 'geometry source'
    if (-not $geometryData.ContainsKey('GameplayKits')) {
        throw ("Geometry source must define a 'GameplayKits' array: {0}" -f $SourcePath)
    }

    $expectedKitKeys = @('sector1', 'sector2', 'sector3', 'sector4')
    $shotModeKeys = @('BaseChase', 'MoveSettle', 'SectorEntry', 'EnemyReveal', 'Interaction', 'WardenPressure', 'EndBeat')
    $definitions = New-Object 'System.Collections.Generic.List[object]'
    $kits = @($geometryData.GameplayKits)
    if ($kits.Count -ne $expectedKitKeys.Count) {
        throw ("Geometry source defined {0} gameplay kits, but replay expects {1}." -f $kits.Count, $expectedKitKeys.Count)
    }

    for ($kitIndex = 0; $kitIndex -lt $kits.Count; $kitIndex++) {
        $kit = $kits[$kitIndex]
        $kitKey = ([string]$kit.Key).ToLowerInvariant()
        if ($kitKey -ne $expectedKitKeys[$kitIndex]) {
            throw ("Gameplay kit {0} in {1} must use key '{2}'." -f ($kitIndex + 1), $SourcePath, $expectedKitKeys[$kitIndex])
        }

        $parsedShotRigs = @{}
        foreach ($shotMode in $shotModeKeys) {
            $rig = $kit.ShotRigs[$shotMode]
            $parsedShotRigs[$shotMode] = [pscustomobject]@{
                Height = (ConvertTo-GeometryFixed88 $rig.Height)
                Distance = (ConvertTo-GeometryFixed88 $rig.Distance)
                LookAhead = (ConvertTo-GeometryFixed88 $rig.LookAhead)
                Pitch = (ConvertTo-GeometryAngleByte $rig.PitchDegrees)
                ProjectScale = [int]$rig.ProjectScale
                Horizon = [int]$rig.Horizon
                FocusBiasX = (ConvertTo-GeometryFixed88 $rig.FocusBiasX)
                FocusBiasZ = (ConvertTo-GeometryFixed88 $rig.FocusBiasZ)
            }
        }

        $definitions.Add([pscustomobject]@{
            Key = $kitKey
            ShotRigs = $parsedShotRigs
        })
    }

    return $definitions.ToArray()
}

function Get-AdventureRealmDefinition {
    param([string]$SourcePath)

    $sectorData = Import-StructuredDataFile -SourcePath $SourcePath -Label 'sector source'
    if (-not $sectorData.ContainsKey('AdventureRealm')) {
        throw ("Sector source must define an AdventureRealm block: {0}" -f $SourcePath)
    }

    $realm = $sectorData.AdventureRealm
    return [pscustomobject]@{
        Start = (Parse-Coord -Token ([string]$realm.Start) -Context 'AdventureRealm.Start')
        Portal = [pscustomobject]@{
            X = [int](([string]$realm.Portal -split ',')[0])
            Y = [int](([string]$realm.Portal -split ',')[1])
        }
        RequiredGems = [int]$realm.RequiredGems
        Rows = @([string[]]$realm.Rows)
        Gems = @(@($realm.Gems) | ForEach-Object { Parse-Coord -Token ([string]$_) -Context 'AdventureRealm.Gems entry' })
        Switches = @(@($realm.Switches) | ForEach-Object { Parse-Coord -Token ([string]$_) -Context 'AdventureRealm.Switches entry' })
        Hazards = @(@($realm.Hazards) | ForEach-Object { Parse-Coord -Token ([string]$_) -Context 'AdventureRealm.Hazards entry' })
        Key = @(@($realm.Key) | ForEach-Object { Parse-Coord -Token ([string]$_) -Context 'AdventureRealm.Key entry' })
        Enemies = @(@($realm.Enemies) | ForEach-Object {
                [pscustomobject]@{
                    X = [int]$_.X
                    Y = [int]$_.Y
                    Kind = [string]$_.Kind
                }
            })
        ObjectivesTotal = (@($realm.Switches)).Count + (@($realm.Key)).Count
    }
}

function Parse-Coord {
    param(
        [string]$Token,
        [string]$Context
    )

    if ([string]::IsNullOrWhiteSpace($Token) -or $Token -notmatch '^\s*(\d+)\s*,\s*(\d+)\s*$') {
        throw ("{0} must use 'x,y' coordinates. Received '{1}'." -f $Context, $Token)
    }

    return [pscustomobject]@{
        X = [int]$Matches[1]
        Y = [int]$Matches[2]
    }
}

function Get-StateId {
    param($Constants, [string]$StateName)

    switch ($StateName.ToUpperInvariant()) {
        'TITLE' { return $Constants.STATE_TITLE }
        'PLAYING' { return $Constants.STATE_PLAYING }
        'WIN' { return $Constants.STATE_WIN }
        'LOSE' { return $Constants.STATE_LOSE }
        default { throw ("Unsupported state '{0}'." -f $StateName) }
    }
}

function Get-HeadingId {
    param($Constants, [string]$HeadingName)

    switch ($HeadingName.ToUpperInvariant()) {
        'NORTH' { return $Constants.GAME3D_HEADING_NORTH }
        'SOUTH' { return $Constants.GAME3D_HEADING_SOUTH }
        'WEST' { return $Constants.GAME3D_HEADING_WEST }
        default { return $Constants.GAME3D_HEADING_EAST }
    }
}

function Get-YawFromHeading {
    param($Constants, [string]$HeadingName)

    switch ($HeadingName.ToUpperInvariant()) {
        'NORTH' { return $Constants.GAME3D_YAW_NORTH }
        'SOUTH' { return $Constants.GAME3D_YAW_SOUTH }
        'WEST' { return $Constants.GAME3D_YAW_WEST }
        default { return $Constants.GAME3D_YAW_EAST }
    }
}

function Get-RoomVariantFromHeading {
    param($Constants, [int]$HeadingId)

    switch ($HeadingId) {
        { $_ -eq $Constants.GAME3D_HEADING_NORTH } { return $Constants.GAME3D_ROOM_VARIANT_SOUTHWEST }
        { $_ -eq $Constants.GAME3D_HEADING_EAST } { return $Constants.GAME3D_ROOM_VARIANT_NORTHWEST }
        { $_ -eq $Constants.GAME3D_HEADING_SOUTH } { return $Constants.GAME3D_ROOM_VARIANT_NORTHEAST }
        default { return $Constants.GAME3D_ROOM_VARIANT_SOUTHEAST }
    }
}

function Get-ShotModeId {
    param($Constants, [string]$ShotModeName)

    switch ($ShotModeName.ToUpperInvariant()) {
        'MOVESETTLE' { return $Constants.GAME3D_SHOT_MOVE_SETTLE }
        'SECTORENTRY' { return $Constants.GAME3D_SHOT_SECTOR_ENTRY }
        'ENEMYREVEAL' { return $Constants.GAME3D_SHOT_ENEMY_REVEAL }
        'INTERACTION' { return $Constants.GAME3D_SHOT_INTERACTION }
        'WARDENPRESSURE' { return $Constants.GAME3D_SHOT_WARDEN_PRESSURE }
        'ENDBEAT' { return $Constants.GAME3D_SHOT_END_BEAT }
        default { return $Constants.GAME3D_SHOT_BASE_CHASE }
    }
}

function Get-ShotReasonId {
    param($Constants, [string]$ShotReasonName)

    switch ($ShotReasonName.ToUpperInvariant()) {
        'MOVE' { return $Constants.GAME3D_SHOT_REASON_MOVE }
        'SECTOR' { return $Constants.GAME3D_SHOT_REASON_SECTOR }
        'REVEAL' { return $Constants.GAME3D_SHOT_REASON_REVEAL }
        'TERMINAL' { return $Constants.GAME3D_SHOT_REASON_TERMINAL }
        'GATE' { return $Constants.GAME3D_SHOT_REASON_GATE }
        'WARDEN' { return $Constants.GAME3D_SHOT_REASON_WARDEN }
        'WIN' { return $Constants.GAME3D_SHOT_REASON_WIN }
        'LOSE' { return $Constants.GAME3D_SHOT_REASON_LOSE }
        default { return $Constants.GAME3D_SHOT_REASON_NONE }
    }
}

function Get-FrameVariantId {
    param($Constants, [string]$FrameVariantName)

    switch ($FrameVariantName.ToUpperInvariant()) {
        'RAIL' { return $Constants.GAME3D_FRAME_VARIANT_RAIL }
        'DOOR' { return $Constants.GAME3D_FRAME_VARIANT_DOOR }
        'CEILING' { return $Constants.GAME3D_FRAME_VARIANT_CEILING }
        'FARMASS' { return $Constants.GAME3D_FRAME_VARIANT_FAR_MASS }
        'LANDMARK' { return $Constants.GAME3D_FRAME_VARIANT_LANDMARK }
        default { return $Constants.GAME3D_FRAME_VARIANT_NONE }
    }
}

function Get-DefaultFrameVariant {
    param($Constants, [int]$ShotModeId)

    switch ($ShotModeId) {
        { $_ -eq $Constants.GAME3D_SHOT_SECTOR_ENTRY } { return $Constants.GAME3D_FRAME_VARIANT_LANDMARK }
        { $_ -eq $Constants.GAME3D_SHOT_END_BEAT } { return $Constants.GAME3D_FRAME_VARIANT_LANDMARK }
        default { return $Constants.GAME3D_FRAME_VARIANT_NONE }
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
    return [pscustomobject]@{
        Sin = [int][Math]::Round([Math]::Sin($radians) * 256.0)
        Cos = [int][Math]::Round([Math]::Cos($radians) * 256.0)
    }
}

function Get-GameplayKitForSector {
    param(
        [object[]]$GameplayKits,
        [int]$Sector
    )

    return $GameplayKits[[Math]::Max(0, [Math]::Min($GameplayKits.Count - 1, $Sector - 1))]
}

function Get-ShotRigKeyForMode {
    param($Constants, [int]$ShotModeId)

    switch ($ShotModeId) {
        { $_ -eq $Constants.GAME3D_SHOT_MOVE_SETTLE } { return 'MoveSettle' }
        { $_ -eq $Constants.GAME3D_SHOT_SECTOR_ENTRY } { return 'SectorEntry' }
        { $_ -eq $Constants.GAME3D_SHOT_ENEMY_REVEAL } { return 'EnemyReveal' }
        { $_ -eq $Constants.GAME3D_SHOT_INTERACTION } { return 'Interaction' }
        { $_ -eq $Constants.GAME3D_SHOT_WARDEN_PRESSURE } { return 'WardenPressure' }
        { $_ -eq $Constants.GAME3D_SHOT_END_BEAT } { return 'EndBeat' }
        default { return 'BaseChase' }
    }
}

function Get-RuntimeCameraSetup {
    param(
        $RuntimeState,
        $Constants,
        [object[]]$GameplayKits
    )

    $kit = Get-GameplayKitForSector -GameplayKits $GameplayKits -Sector $RuntimeState.Sector
    $rig = $kit.ShotRigs[(Get-ShotRigKeyForMode -Constants $Constants -ShotModeId $RuntimeState.ShotMode)]
    $focusX = ($RuntimeState.Player.X * 256) + 128 - ($Constants.MAP_W * 128)
    $focusZ = ($RuntimeState.Player.Y * 256) + 128 - ($Constants.MAP_H * 128)
    $yaw = Get-FixedSinCos -AngleByte $RuntimeState.Yaw

    if ($RuntimeState.ShotMode -eq $Constants.GAME3D_SHOT_BASE_CHASE) {
        $focusX += (Mul-Fixed88 -A $rig.LookAhead -B $yaw.Sin)
        $focusZ += (Mul-Fixed88 -A $rig.LookAhead -B $yaw.Cos)
    } else {
        $focusX = ($RuntimeState.ShotSubject.X * 256) + 128 - ($Constants.MAP_W * 128) + $rig.FocusBiasX
        $focusZ = ($RuntimeState.ShotSubject.Y * 256) + 128 - ($Constants.MAP_H * 128) + $rig.FocusBiasZ
    }

    return [pscustomobject]@{
        CamX = ($focusX - (Mul-Fixed88 -A $rig.Distance -B $yaw.Sin))
        CamY = $rig.Height
        CamZ = ($focusZ - (Mul-Fixed88 -A $rig.Distance -B $yaw.Cos))
        Yaw = $RuntimeState.Yaw
        Pitch = $rig.Pitch
        ProjectScale = $rig.ProjectScale
        CenterX = ($Constants.GAME3D_VIEW_X + [int]($Constants.GAME3D_VIEW_W / 2))
        CenterY = ($Constants.GAME3D_VIEW_Y + $Constants.GAME3D_CAMERA_HORIZON_CENTER_OFFSET + $rig.Horizon)
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
    $cameraYaw = Get-FixedSinCos -AngleByte $Camera.Yaw
    $cameraPitch = Get-FixedSinCos -AngleByte $Camera.Pitch

    $tempX = (Mul-Fixed88 -A $relX -B $cameraYaw.Cos) - (Mul-Fixed88 -A $relZ -B $cameraYaw.Sin)
    $tempZ = (Mul-Fixed88 -A $relX -B $cameraYaw.Sin) + (Mul-Fixed88 -A $relZ -B $cameraYaw.Cos)
    $tempY = (Mul-Fixed88 -A $relY -B $cameraPitch.Cos) - (Mul-Fixed88 -A $tempZ -B $cameraPitch.Sin)
    $depth = (Mul-Fixed88 -A $relY -B $cameraPitch.Sin) + (Mul-Fixed88 -A $tempZ -B $cameraPitch.Cos)

    if ($depth -le $Constants.SCENE3D_NEAR_Z) {
        return [pscustomobject]@{
            Visible = $false
            X = 0
            Y = 0
            Depth = $depth
        }
    }

    if ($depth -lt 128) {
        $slopeLimit = $depth * 256
        if (([Math]::Abs($tempX) -gt $slopeLimit) -or ([Math]::Abs($tempY) -gt $slopeLimit)) {
            return [pscustomobject]@{
                Visible = $false
                X = 0
                Y = 0
                Depth = $depth
            }
        }
    }

    return [pscustomobject]@{
        Visible = $true
        X = ([int](($tempX * $Camera.ProjectScale) / $depth) + $Camera.CenterX)
        Y = (-[int](($tempY * $Camera.ProjectScale) / $depth) + $Camera.CenterY)
        Depth = $depth
    }
}

function Project-TileCenter {
    param(
        $RuntimeState,
        $Constants,
        [object[]]$GameplayKits,
        [int]$TileX,
        [int]$TileY
    )

    $camera = Get-RuntimeCameraSetup -RuntimeState $RuntimeState -Constants $Constants -GameplayKits $GameplayKits
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
        $RuntimeState,
        $Constants,
        [object[]]$GameplayKits,
        $AdventureRealm
    )

    $flags = 0
    $playerProjection = Project-TileCenter -RuntimeState $RuntimeState -Constants $Constants -GameplayKits $GameplayKits -TileX $RuntimeState.Player.X -TileY $RuntimeState.Player.Y
    if ((-not $playerProjection.Visible) -or $playerProjection.Depth -gt $Constants.GAME3D_PLAYER_LOCATOR_FAR_DEPTH -or -not (Test-CueReady -Projection $playerProjection -Constants $Constants)) {
        $flags = $flags -bor $Constants.GAME3D_CUE_FLAG_PLAYER_FALLBACK
    }

    $exitX = if ($RuntimeState.PSObject.Properties.Name -contains 'ExitX') { [int]$RuntimeState.ExitX } else { [int]$AdventureRealm.Portal.X }
    $exitY = if ($RuntimeState.PSObject.Properties.Name -contains 'ExitY') { [int]$RuntimeState.ExitY } else { [int]$AdventureRealm.Portal.Y }
    $exitProjection = Project-TileCenter -RuntimeState $RuntimeState -Constants $Constants -GameplayKits $GameplayKits -TileX $exitX -TileY $exitY
    if (-not (Test-CueReady -Projection $exitProjection -Constants $Constants)) {
        $flags = $flags -bor $Constants.GAME3D_CUE_FLAG_EXIT_FALLBACK
    }

    if (($RuntimeState.PSObject.Properties.Name -contains 'SpoofTimer') -and [int]$RuntimeState.SpoofTimer -gt 0) {
        $spoofProjection = Project-TileCenter -RuntimeState $RuntimeState -Constants $Constants -GameplayKits $GameplayKits -TileX ([int]$RuntimeState.SpoofX) -TileY ([int]$RuntimeState.SpoofY)
        if (-not (Test-CueReady -Projection $spoofProjection -Constants $Constants)) {
            $flags = $flags -bor $Constants.GAME3D_CUE_FLAG_SPOOF_FALLBACK
        }
    }

    if (($RuntimeState.PSObject.Properties.Name -contains 'ThreatLevel') -and [int]$RuntimeState.ThreatLevel -ne $Constants.THREAT_NONE) {
        $threatProjection = Project-TileCenter -RuntimeState $RuntimeState -Constants $Constants -GameplayKits $GameplayKits -TileX ([int]$RuntimeState.ThreatX) -TileY ([int]$RuntimeState.ThreatY)
        if (-not (Test-CueReady -Projection $threatProjection -Constants $Constants)) {
            $flags = $flags -bor $Constants.GAME3D_CUE_FLAG_THREAT_FALLBACK
        }
    }

    return $flags
}

function Get-AdventureHeadingIdFromYaw {
    param($Constants, [int]$Yaw)

    $yawByte = ($Yaw -band 0xFF)
    if ($yawByte -lt 32) { return $Constants.GAME3D_HEADING_SOUTH }
    if ($yawByte -lt 96) { return $Constants.GAME3D_HEADING_EAST }
    if ($yawByte -lt 160) { return $Constants.GAME3D_HEADING_NORTH }
    if ($yawByte -lt 224) { return $Constants.GAME3D_HEADING_WEST }
    return $Constants.GAME3D_HEADING_SOUTH
}

function Get-StartPulseCountForSector {
    param(
        $Constants,
        [int]$Sector
    )

    $sectorId = [Math]::Max(1, [Math]::Min([int]$Sector, [int]$Constants.CAMPAIGN_DISTRICT_COUNT))
    $pulseCount = [int]$Constants.START_PULSES
    if ($sectorId -gt 1) {
        $pulseCount += ($sectorId - 1)
    }

    return [Math]::Min($pulseCount, [int]$Constants.MAX_PULSES)
}

function Build-RuntimeStateFromExpected {
    param(
        $Demo,
        $Expected,
        $Constants,
        $AdventureRealm
    )

    $headingName = if ($Expected.ContainsKey('Heading')) { [string]$Expected.Heading } else { 'EAST' }
    $player = Parse-Coord -Token ([string]$Expected.Player) -Context ("Expected.Player for {0}" -f $Demo.Name)
    $shotSubject = if ($Expected.ContainsKey('ShotSubject')) {
        Parse-Coord -Token ([string]$Expected.ShotSubject) -Context ("Expected.ShotSubject for {0}" -f $Demo.Name)
    } else {
        $player
    }
    $shotMode = if ($Expected.ContainsKey('ShotMode')) { Get-ShotModeId -Constants $Constants -ShotModeName ([string]$Expected.ShotMode) } else { $Constants.GAME3D_SHOT_BASE_CHASE }
    $shotReason = if ($Expected.ContainsKey('ShotReason')) { Get-ShotReasonId -Constants $Constants -ShotReasonName ([string]$Expected.ShotReason) } else { $Constants.GAME3D_SHOT_REASON_NONE }
    $frameVariant = if ($Expected.ContainsKey('ShotFrameVariant')) { Get-FrameVariantId -Constants $Constants -FrameVariantName ([string]$Expected.ShotFrameVariant) } else { Get-DefaultFrameVariant -Constants $Constants -ShotModeId $shotMode }
    $portalState = if ($Expected.ContainsKey('Portal')) { ([string]$Expected.Portal).ToUpperInvariant() } else { 'LOCKED' }
    $sector = if ($Expected.ContainsKey('Sector')) { [int]$Expected.Sector } else { [int]$Demo.StartSector }
    $pulseCount = if ($Expected.ContainsKey('Pulses')) { [int]$Expected.Pulses } else { Get-StartPulseCountForSector -Constants $Constants -Sector $sector }

    return [pscustomobject]@{
        Name = [string]$Demo.Name
        StateId = (Get-StateId -Constants $Constants -StateName ([string]$Expected.State))
        Sector = $sector
        TemplateIndex = if ($Expected.ContainsKey('TemplateIndex')) { [int]$Expected.TemplateIndex } else { 0 }
        Player = $player
        HeadingId = (Get-HeadingId -Constants $Constants -HeadingName $headingName)
        Yaw = (Get-YawFromHeading -Constants $Constants -HeadingName $headingName)
        ShotMode = $shotMode
        ShotReason = $shotReason
        ShotSubject = $shotSubject
        ShotFrameVariant = $frameVariant
        ShieldCount = if ($Expected.ContainsKey('Shields')) { [int]$Expected.Shields } else { [int]$Constants.START_SHIELDS }
        PulseCount = $pulseCount
        DataCount = if ($Expected.ContainsKey('Data')) { [int]$Expected.Data } else { 0 }
        ObjectivesDone = if ($Expected.ContainsKey('Objectives')) { [int]$Expected.Objectives } else { 0 }
        ObjectivesTotal = if ($Expected.ContainsKey('ObjectivesTotal')) { [int]$Expected.ObjectivesTotal } else { [int]$AdventureRealm.ObjectivesTotal }
        KeyCollected = if ($Expected.ContainsKey('Key')) { [int][bool]$Expected.Key } else { 0 }
        ExitTile = if ($portalState -eq 'OPEN') { $Constants.TILE_EXIT_OPEN } else { $Constants.TILE_EXIT_LOCKED }
        KillCount = if ($Expected.ContainsKey('Kills')) { [int]$Expected.Kills } else { 0 }
        Score = if ($Expected.ContainsKey('Score')) { [int]$Expected.Score } else { 0 }
        Actions = if ($Expected.ContainsKey('Actions')) { [int]$Expected.Actions } else { 0 }
        Hits = if ($Expected.ContainsKey('Hits')) { [int]$Expected.Hits } else { 0 }
        PulsesUsed = if ($Expected.ContainsKey('PulsesUsed')) { [int]$Expected.PulsesUsed } else { 0 }
        SpoofTimer = if ($Expected.ContainsKey('Spoof')) { [int]$Expected.Spoof } else { 0 }
    }
}

function Get-RuntimeVerificationSignature {
    param(
        $RuntimeState,
        $Constants,
        [object[]]$GameplayKits,
        $AdventureRealm
    )

    $signature = 0xA55A
    $cueFlags = Get-RuntimeCueFlags -RuntimeState $RuntimeState -Constants $Constants -GameplayKits $GameplayKits -AdventureRealm $AdventureRealm
    $kit = Get-GameplayKitForSector -GameplayKits $GameplayKits -Sector $RuntimeState.Sector
    $shotRig = $kit.ShotRigs[(Get-ShotRigKeyForMode -Constants $Constants -ShotModeId $RuntimeState.ShotMode)]
    $headingId = if ($RuntimeState.PSObject.Properties.Name -contains 'Yaw') {
        Get-AdventureHeadingIdFromYaw -Constants $Constants -Yaw ([int]$RuntimeState.Yaw)
    } else {
        [int]$RuntimeState.HeadingId
    }
    $exitTile = if (($RuntimeState.PSObject.Properties.Name -contains 'Map') -and ($RuntimeState.PSObject.Properties.Name -contains 'ExitX') -and ($RuntimeState.PSObject.Properties.Name -contains 'ExitY')) {
        Get-MapTile -Map $RuntimeState.Map -Constants $Constants -X ([int]$RuntimeState.ExitX) -Y ([int]$RuntimeState.ExitY)
    } else {
        [int]$RuntimeState.ExitTile
    }

    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.StateId
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.Sector
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.TemplateIndex
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.Player.X
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.Player.Y
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $headingId
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value (Get-RoomVariantFromHeading -Constants $Constants -HeadingId $headingId)
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $shotRig.Pitch
    $signature = Update-RuntimeSignatureWord -Signature $signature -Value $shotRig.ProjectScale
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $cueFlags
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.ShotMode
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.ShotReason
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.ShotSubject.X
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.ShotSubject.Y
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.ShotFrameVariant
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.ShieldCount
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.PulseCount
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.DataCount
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.ObjectivesDone
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.ObjectivesTotal
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.KeyCollected
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $exitTile
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.KillCount
    $signature = Update-RuntimeSignatureWord -Signature $signature -Value $RuntimeState.Score
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.Actions
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.Hits
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.PulsesUsed
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.SpoofTimer
    return ($signature -band 0xFFFF)
}

function Get-AdventureEnemyFingerprint {
    param(
        $State,
        [int]$EnemyIndex
    )

    if (($EnemyIndex -lt 0) -or ($EnemyIndex -ge $State.Enemies.Count)) {
        return 0
    }

    $enemy = $State.Enemies[$EnemyIndex]
    if (-not $enemy.Alive) {
        return 0
    }

    $fingerprint = 0x8000
    $fingerprint = $fingerprint -bor ((([int]$enemy.Kind) -band 0x03) -shl 12)
    $fingerprint = $fingerprint -bor ((([int]$enemy.X) -band 0x1F) -shl 6)
    $fingerprint = $fingerprint -bor ((([int]$enemy.Y) -band 0x3F))
    return ($fingerprint -band 0xFFFF)
}

function Get-AdventureAutonomousDiagnostics {
    param($State)

    return [pscustomobject]@{
        IntroTimer = [int]$State.IntroTimer
        EnemyTick = [int]$State.EnemyTick
        ThreatLevel = [int]$State.ThreatLevel
        ThreatX = [int]$State.ThreatX
        ThreatY = [int]$State.ThreatY
        Enemy0 = (Get-AdventureEnemyFingerprint -State $State -EnemyIndex 0)
        Enemy1 = (Get-AdventureEnemyFingerprint -State $State -EnemyIndex 1)
        Enemy2 = (Get-AdventureEnemyFingerprint -State $State -EnemyIndex 2)
    }
}

function Get-StepActionName {
    param(
        $Step,
        [string]$DemoName
    )

    if ($Step -is [System.Collections.IDictionary]) {
        if (-not $Step.ContainsKey('Action')) {
            throw ("Demo '{0}' step is missing an Action value." -f $DemoName)
        }

        return ([string]$Step['Action']).Trim().ToUpperInvariant()
    }

    $parts = ([string]$Step).Trim() -split '\s+'
    if ($parts.Count -ne 2) {
        throw ("Demo '{0}' step '{1}' must be 'ACTION COUNT'." -f $DemoName, $Step)
    }

    return $parts[0].Trim().ToUpperInvariant()
}

function Get-MapIndex {
    param(
        $Constants,
        [int]$X,
        [int]$Y
    )

    return (($Y * $Constants.MAP_W) + $X)
}

function Get-MapTile {
    param(
        [int[]]$Map,
        $Constants,
        [int]$X,
        [int]$Y
    )

    return [int]$Map[(Get-MapIndex -Constants $Constants -X $X -Y $Y)]
}

function Set-MapTile {
    param(
        [int[]]$Map,
        $Constants,
        [int]$X,
        [int]$Y,
        [int]$Tile
    )

    $Map[(Get-MapIndex -Constants $Constants -X $X -Y $Y)] = ($Tile -band 0xFF)
}

function Get-AdventureEnemyKindId {
    param($Constants, [string]$Kind)

    switch ($Kind.ToUpperInvariant()) {
        'FLANKER' { return $Constants.ENEMY_FLANKER }
        'WARDEN' { return $Constants.ENEMY_WARDEN }
        default { return $Constants.ENEMY_RUSHER }
    }
}

function Get-AdventureShotDuration {
    param($Constants, [int]$ShotMode)

    switch ($ShotMode) {
        { $_ -eq $Constants.GAME3D_SHOT_MOVE_SETTLE } { return ($Constants.GAME3D_SHOT_MOVE_IN + $Constants.GAME3D_SHOT_MOVE_HOLD + $Constants.GAME3D_SHOT_MOVE_OUT) }
        { $_ -eq $Constants.GAME3D_SHOT_SECTOR_ENTRY } { return ($Constants.GAME3D_SHOT_SECTOR_HOLD + $Constants.GAME3D_SHOT_SECTOR_OUT) }
        { $_ -eq $Constants.GAME3D_SHOT_ENEMY_REVEAL } { return ($Constants.GAME3D_SHOT_REVEAL_IN + $Constants.GAME3D_SHOT_REVEAL_HOLD + $Constants.GAME3D_SHOT_REVEAL_OUT) }
        { $_ -eq $Constants.GAME3D_SHOT_INTERACTION } { return ($Constants.GAME3D_SHOT_INTERACTION_IN + $Constants.GAME3D_SHOT_INTERACTION_HOLD + $Constants.GAME3D_SHOT_INTERACTION_OUT) }
        { $_ -eq $Constants.GAME3D_SHOT_WARDEN_PRESSURE } { return ($Constants.GAME3D_SHOT_WARDEN_IN + $Constants.GAME3D_SHOT_WARDEN_HOLD + $Constants.GAME3D_SHOT_WARDEN_OUT) }
        { $_ -eq $Constants.GAME3D_SHOT_END_BEAT } { return ($Constants.GAME3D_SHOT_END_IN + $Constants.GAME3D_SHOT_END_HOLD) }
        default { return 0 }
    }
}

function Get-AdventureShotFrameVariant {
    param($Constants, [int]$ShotMode)

    switch ($ShotMode) {
        { $_ -eq $Constants.GAME3D_SHOT_MOVE_SETTLE } { return $Constants.GAME3D_FRAME_VARIANT_RAIL }
        { $_ -eq $Constants.GAME3D_SHOT_SECTOR_ENTRY } { return $Constants.GAME3D_FRAME_VARIANT_LANDMARK }
        { $_ -eq $Constants.GAME3D_SHOT_ENEMY_REVEAL } { return $Constants.GAME3D_FRAME_VARIANT_DOOR }
        { $_ -eq $Constants.GAME3D_SHOT_INTERACTION } { return $Constants.GAME3D_FRAME_VARIANT_DOOR }
        { $_ -eq $Constants.GAME3D_SHOT_WARDEN_PRESSURE } { return $Constants.GAME3D_FRAME_VARIANT_CEILING }
        { $_ -eq $Constants.GAME3D_SHOT_END_BEAT } { return $Constants.GAME3D_FRAME_VARIANT_LANDMARK }
        default { return $Constants.GAME3D_FRAME_VARIANT_NONE }
    }
}

function Get-MessageFeedbackTicks {
    param($Constants, [int]$MessageId)

    switch ($MessageId) {
        { $_ -eq $Constants.MSG_SECTOR } { return $Constants.FEEDBACK_TICKS_MAJOR }
        { $_ -eq $Constants.MSG_BLOCK } { return $Constants.FEEDBACK_TICKS_MINOR }
        { $_ -eq $Constants.MSG_NOPULSE } { return $Constants.FEEDBACK_TICKS_MINOR }
        { $_ -eq $Constants.MSG_GATE } { return $Constants.FEEDBACK_TICKS_MAJOR }
        { $_ -eq $Constants.MSG_HIT } { return $Constants.FEEDBACK_TICKS_MAJOR }
        { $_ -eq $Constants.MSG_KILL } { return $Constants.FEEDBACK_TICKS_MAJOR }
        { $_ -eq $Constants.MSG_SURGE } { return $Constants.FEEDBACK_TICKS_MAJOR }
        { $_ -eq $Constants.MSG_TRAP } { return $Constants.FEEDBACK_TICKS_MAJOR }
        { $_ -eq $Constants.MSG_RECHARGE } { return $Constants.FEEDBACK_TICKS_MAJOR }
        { $_ -eq $Constants.MSG_SPOOF } { return $Constants.FEEDBACK_TICKS_MAJOR }
        { $_ -eq $Constants.MSG_KEY } { return $Constants.FEEDBACK_TICKS_MAJOR }
        default { return $Constants.FEEDBACK_TICKS_STANDARD }
    }
}

function Set-AdventureMessageEvent {
    param(
        $State,
        $Constants,
        [int]$MessageId
    )

    $State.MessageId = ($MessageId -band 0xFF)
    $State.FeedbackTimer = Get-MessageFeedbackTicks -Constants $Constants -MessageId $MessageId
}

function Award-AdventureScore {
    param(
        $State,
        [int]$Amount
    )

    $State.Score = [Math]::Min(0xFFFF, ([int]$State.Score + $Amount))
}

function Award-AdventureKill {
    param(
        $State,
        $Constants
    )

    $State.KillCount = [Math]::Min(99, ([int]$State.KillCount + 1))
    Award-AdventureScore -State $State -Amount $Constants.SCORE_KILL_POINTS
}

function Clear-AdventureActiveShot {
    param(
        $State,
        $Constants
    )

    $State.ShotMode = $Constants.GAME3D_SHOT_BASE_CHASE
    $State.ShotReason = $Constants.GAME3D_SHOT_REASON_NONE
    $State.ShotTick = 0
    $State.ShotDuration = 0
    $State.ShotFrameVariant = $Constants.GAME3D_FRAME_VARIANT_NONE
    $State.ShotSubject.X = [int]$State.Player.X
    $State.ShotSubject.Y = [int]$State.Player.Y
}

function Start-AdventureShot {
    param(
        $State,
        $Constants,
        [int]$ShotMode,
        [int]$ShotReason,
        [int]$SubjectX,
        [int]$SubjectY
    )

    if (($State.EndStatePending -ne 0) -and ($ShotMode -ne $Constants.GAME3D_SHOT_END_BEAT)) {
        return
    }

    $State.ShotMode = ($ShotMode -band 0xFF)
    $State.ShotReason = ($ShotReason -band 0xFF)
    $State.ShotTick = 0
    $State.ShotDuration = Get-AdventureShotDuration -Constants $Constants -ShotMode $ShotMode
    $State.ShotSubject.X = $SubjectX
    $State.ShotSubject.Y = $SubjectY
    $State.ShotFrameVariant = Get-AdventureShotFrameVariant -Constants $Constants -ShotMode $ShotMode
}

function Start-AdventureEndBeatShot {
    param(
        $State,
        $Constants,
        [int]$TargetState
    )

    if ($State.EndStatePending -ne 0) {
        return
    }

    $State.EndStatePending = ($TargetState -band 0xFF)
    $shotReason = if ($TargetState -eq $Constants.STATE_WIN) { $Constants.GAME3D_SHOT_REASON_WIN } else { $Constants.GAME3D_SHOT_REASON_LOSE }
    Start-AdventureShot -State $State -Constants $Constants -ShotMode $Constants.GAME3D_SHOT_END_BEAT -ShotReason $shotReason -SubjectX ([int]$State.Player.X) -SubjectY ([int]$State.Player.Y)
}

function Update-AdventureShotState {
    param(
        $State,
        $Constants
    )

    if ($State.StateId -ne $Constants.STATE_PLAYING) {
        return
    }

    if (($State.ShotMode -eq $Constants.GAME3D_SHOT_BASE_CHASE) -and ($State.EndStatePending -eq 0)) {
        return
    }

    if ($State.ShotTick -lt 255) {
        $State.ShotTick++
    }

    if ($State.ShotTick -lt $State.ShotDuration) {
        return
    }

    if ($State.EndStatePending -ne 0) {
        $targetState = [int]$State.EndStatePending
        $State.EndStatePending = 0
        Clear-AdventureActiveShot -State $State -Constants $Constants
        $State.StateId = $targetState
        return
    }

    Clear-AdventureActiveShot -State $State -Constants $Constants
}

function Update-AdventureRuntimeFeedback {
    param(
        $State,
        $Constants
    )

    Update-AdventureShotState -State $State -Constants $Constants
    if ($State.StateId -ne $State.LastGameState) {
        $State.LastGameState = [int]$State.StateId
        $State.StateTicks = 0
    }

    if ($State.StateTicks -lt 255) {
        $State.StateTicks++
    }

    if ($State.FeedbackTimer -gt 0) {
        $State.FeedbackTimer--
    }
}

function New-AdventureMap {
    param(
        $Constants,
        $AdventureRealm
    )

    $map = New-Object 'int[]' ($Constants.MAP_W * $Constants.MAP_H)
    for ($y = 0; $y -lt $AdventureRealm.Rows.Count; $y++) {
        $row = [string]$AdventureRealm.Rows[$y]
        for ($x = 0; $x -lt $row.Length; $x++) {
            $tile = if ($row[$x] -eq '#') { $Constants.TILE_WALL } else { $Constants.TILE_FLOOR }
            Set-MapTile -Map $map -Constants $Constants -X $x -Y $y -Tile $tile
        }
    }

    Set-MapTile -Map $map -Constants $Constants -X $AdventureRealm.Portal.X -Y $AdventureRealm.Portal.Y -Tile $Constants.TILE_EXIT_LOCKED
    foreach ($coord in @($AdventureRealm.Gems)) {
        Set-MapTile -Map $map -Constants $Constants -X $coord.X -Y $coord.Y -Tile $Constants.TILE_SHARD
    }
    foreach ($coord in @($AdventureRealm.Switches)) {
        Set-MapTile -Map $map -Constants $Constants -X $coord.X -Y $coord.Y -Tile $Constants.TILE_TERMINAL
    }
    foreach ($coord in @($AdventureRealm.Key)) {
        Set-MapTile -Map $map -Constants $Constants -X $coord.X -Y $coord.Y -Tile $Constants.TILE_KEY
    }
    foreach ($coord in @($AdventureRealm.Hazards)) {
        Set-MapTile -Map $map -Constants $Constants -X $coord.X -Y $coord.Y -Tile $Constants.TILE_SURGE
    }

    return $map
}

function Get-AdventureWorldPositionFromTile {
    param(
        $Constants,
        [int]$TileX,
        [int]$TileY
    )

    return [pscustomobject]@{
        X = (($TileX * 256) + 128 - ($Constants.MAP_W * 128))
        Z = (($TileY * 256) + 128 - ($Constants.MAP_H * 128))
    }
}

function New-AdventureRuntimeState {
    param(
        $Demo,
        $Constants,
        $AdventureRealm
    )

    $sector = if ($Demo.PSObject.Properties.Name -contains 'StartSector') { [int]$Demo.StartSector } else { 1 }
    $map = New-AdventureMap -Constants $Constants -AdventureRealm $AdventureRealm
    $player = [pscustomobject]@{
        X = [int]$AdventureRealm.Start.X
        Y = [int]$AdventureRealm.Start.Y
    }
    $playerWorld = Get-AdventureWorldPositionFromTile -Constants $Constants -TileX $player.X -TileY $player.Y
    $enemies = New-Object 'System.Collections.Generic.List[object]'
    foreach ($enemy in @($AdventureRealm.Enemies)) {
        $enemies.Add([pscustomobject]@{
            Alive = $true
            X = [int]$enemy.X
            Y = [int]$enemy.Y
            Kind = (Get-AdventureEnemyKindId -Constants $Constants -Kind ([string]$enemy.Kind))
        })
    }

    $state = [pscustomobject]@{
        Name = [string]$Demo.Name
        StateId = $Constants.STATE_PLAYING
        Sector = $sector
        TemplateIndex = 0
        Player = $player
        Yaw = $Constants.GAME3D_YAW_EAST
        ShotMode = $Constants.GAME3D_SHOT_BASE_CHASE
        ShotReason = $Constants.GAME3D_SHOT_REASON_NONE
        ShotTick = 0
        ShotDuration = 0
        ShotSubject = [pscustomobject]@{
            X = [int]$player.X
            Y = [int]$player.Y
        }
        ShotFrameVariant = $Constants.GAME3D_FRAME_VARIANT_NONE
        ShieldCount = $Constants.START_SHIELDS
        PulseCount = (Get-StartPulseCountForSector -Constants $Constants -Sector $sector)
        DataCount = 0
        ObjectivesDone = 0
        ObjectivesTotal = [int]$AdventureRealm.ObjectivesTotal
        KeyCollected = 0
        ExitX = [int]$AdventureRealm.Portal.X
        ExitY = [int]$AdventureRealm.Portal.Y
        ExitTile = $Constants.TILE_EXIT_LOCKED
        KillCount = 0
        Score = 0
        Actions = 0
        Hits = 0
        PulsesUsed = 0
        SpoofTimer = 0
        SpoofX = [int]$player.X
        SpoofY = [int]$player.Y
        ThreatLevel = $Constants.THREAT_NONE
        ThreatX = [int]$player.X
        ThreatY = [int]$player.Y
        LastPlayerDx = 0
        LastPlayerDy = 0
        MessageId = $Constants.MSG_SECTOR
        FeedbackTimer = (Get-MessageFeedbackTicks -Constants $Constants -MessageId $Constants.MSG_SECTOR)
        LastGameState = 0xFF
        StateTicks = 0
        EndStatePending = 0
        RngState = [int]$Demo.Seed
        IntroTimer = $Constants.ADVENTURE_INTRO_TICKS
        ChargeTimer = 0
        FlameTimer = 0
        EnemyTick = 0
        HazardTimer = 0
        PlayerWorldX = [int]$playerWorld.X
        PlayerWorldY = [int]$Constants.GAME3D_FLOOR_Y
        PlayerWorldZ = [int]$playerWorld.Z
        PlayerVelY = 0
        PlayerGrounded = $true
        Map = $map
        Enemies = $enemies
        DemoActive = $true
        DemoActionCode = 'END'
        DemoActionTicks = 0
        DemoActionIndex = 0
    }

    Start-AdventureShot -State $state -Constants $Constants -ShotMode $Constants.GAME3D_SHOT_SECTOR_ENTRY -ShotReason $Constants.GAME3D_SHOT_REASON_SECTOR -SubjectX ([int]($Constants.MAP_W / 2)) -SubjectY ([int]($Constants.MAP_H / 2))
    return $state
}

function New-DemoActionTape {
    param($Demo)

    $steps = New-Object 'System.Collections.Generic.List[object]'
    foreach ($step in @($Demo.Steps)) {
        $steps.Add([pscustomobject]@{
            Action = (Get-StepActionName -Step $step -DemoName ([string]$Demo.Name))
            Ticks = (Get-StepRepeatCount -Step $step -DemoName ([string]$Demo.Name))
        })
    }

    return $steps
}

function Load-NextAdventureDemoAction {
    param(
        $State,
        [System.Collections.Generic.List[object]]$ActionTape
    )

    if ($State.DemoActionIndex -ge $ActionTape.Count) {
        $State.DemoActionCode = 'END'
        $State.DemoActionTicks = 0
        return
    }

    $action = $ActionTape[$State.DemoActionIndex]
    $State.DemoActionIndex++
    $State.DemoActionCode = [string]$action.Action
    $State.DemoActionTicks = [int]$action.Ticks
}

function New-AdventureInputState {
    return [pscustomobject]@{
        PressedEnter = $false
        PressedC = $false
        PressedSpace = $false
        PressedShift = $false
        KeyW = $false
        KeyA = $false
        KeyS = $false
        KeyD = $false
        KeySpace = $false
    }
}

function Get-AdventureInputForAction {
    param([string]$Action)

    $controlState = New-AdventureInputState
    switch ($Action) {
        'FORWARD' { $controlState.KeyW = $true }
        'BACK' { $controlState.KeyS = $true }
        'TURNLEFT' { $controlState.KeyA = $true }
        'LEFT' { $controlState.KeyA = $true }
        'TURNRIGHT' { $controlState.KeyD = $true }
        'RIGHT' { $controlState.KeyD = $true }
        'FLAME' { $controlState.PressedC = $true }
        'PULSE' { $controlState.PressedC = $true }
        'JUMP' { $controlState.PressedSpace = $true; $controlState.KeySpace = $true }
        'GLIDE' { $controlState.KeySpace = $true }
        'CHARGE' { $controlState.PressedShift = $true }
        'ENTER' { $controlState.PressedEnter = $true }
        default { }
    }

    return $controlState
}

function Find-AdventureEnemyAt {
    param(
        $State,
        [int]$X,
        [int]$Y,
        $ExcludeIndex
    )

    for ($enemyIndex = 0; $enemyIndex -lt $State.Enemies.Count; $enemyIndex++) {
        if (($null -ne $ExcludeIndex) -and ($enemyIndex -eq [int]$ExcludeIndex)) {
            continue
        }

        $enemy = $State.Enemies[$enemyIndex]
        if ((-not $enemy.Alive) -or ($enemy.X -ne $X) -or ($enemy.Y -ne $Y)) {
            continue
        }

        return $enemyIndex
    }

    return -1
}

function Get-AdventureWorldToTile {
    param(
        $Constants,
        [int]$WorldX,
        [int]$WorldZ
    )

    return [pscustomobject]@{
        X = (($WorldX + $Constants.GAME3D_WORLD_ORIGIN_X) -shr 8)
        Y = (($WorldZ + $Constants.GAME3D_WORLD_ORIGIN_Z) -shr 8)
    }
}

function Test-AdventureTryMoveToWorld {
    param(
        $State,
        $Constants,
        [int]$WorldX,
        [int]$WorldZ
    )

    $tile = Get-AdventureWorldToTile -Constants $Constants -WorldX $WorldX -WorldZ $WorldZ
    if (($tile.X -lt $Constants.PLAY_MIN_X) -or ($tile.X -gt $Constants.PLAY_MAX_X) -or ($tile.Y -lt $Constants.PLAY_MIN_Y) -or ($tile.Y -gt $Constants.PLAY_MAX_Y)) {
        return $false
    }

    $tileValue = Get-MapTile -Map $State.Map -Constants $Constants -X $tile.X -Y $tile.Y
    if (($tileValue -eq $Constants.TILE_WALL) -or ($tileValue -eq $Constants.TILE_EXIT_LOCKED)) {
        return $false
    }

    $enemyIndex = Find-AdventureEnemyAt -State $State -X $tile.X -Y $tile.Y -ExcludeIndex $null
    if ($enemyIndex -lt 0) {
        return $true
    }

    if ($State.ChargeTimer -le 0) {
        return $false
    }

    return ($State.Enemies[$enemyIndex].Kind -ne $Constants.ENEMY_FLANKER)
}

function Update-AdventureActiveChunk {
    param($State)
}

function Get-AdventureMoveSpeed {
    param(
        $State,
        $Constants,
        $ControlState
    )

    if ($State.ChargeTimer -gt 0) {
        return $Constants.ADVENTURE_CHARGE_SPEED
    }
    if ($ControlState.KeyW) {
        return $Constants.ADVENTURE_MOVE_SPEED
    }
    if ($ControlState.KeyS) {
        return -$Constants.ADVENTURE_BACK_SPEED
    }

    return 0
}

function Adventure-SyncPlayerTileFromWorld {
    param(
        $State,
        $Constants
    )

    $oldX = [int]$State.Player.X
    $oldY = [int]$State.Player.Y
    $tile = Get-AdventureWorldToTile -Constants $Constants -WorldX ([int]$State.PlayerWorldX) -WorldZ ([int]$State.PlayerWorldZ)
    $State.Player.X = [int]$tile.X
    $State.Player.Y = [int]$tile.Y
    $State.LastPlayerDx = ([int]$State.Player.X - $oldX)
    $State.LastPlayerDy = ([int]$State.Player.Y - $oldY)
    Update-AdventureActiveChunk -State $State
}

function Adventure-TickTimers {
    param($State)

    if ($State.ChargeTimer -gt 0) { $State.ChargeTimer-- }
    if ($State.FlameTimer -gt 0) { $State.FlameTimer-- }
    if ($State.HazardTimer -gt 0) { $State.HazardTimer-- }
    if ($State.IntroTimer -gt 0) { $State.IntroTimer-- }
}

function Adventure-HandleTurn {
    param(
        $State,
        $Constants,
        $ControlState
    )

    if ($ControlState.KeyA) {
        if ($ControlState.KeyD) {
            return
        }

        $State.Yaw = (($State.Yaw - $Constants.ADVENTURE_TURN_STEP) -band 0xFF)
        return
    }

    if ($ControlState.KeyD) {
        $State.Yaw = (($State.Yaw + $Constants.ADVENTURE_TURN_STEP) -band 0xFF)
    }
}

function Adventure-HandleJump {
    param(
        $State,
        $Constants,
        $ControlState
    )

    if ($ControlState.PressedSpace -and $State.PlayerGrounded) {
        $State.PlayerVelY = $Constants.ADVENTURE_JUMP_VEL
        $State.PlayerGrounded = $false
    }
}

function Adventure-HandleCharge {
    param(
        $State,
        $Constants,
        $ControlState
    )

    if ($ControlState.PressedShift -and $State.PlayerGrounded -and ($State.ChargeTimer -eq 0)) {
        $State.ChargeTimer = $Constants.ADVENTURE_CHARGE_TICKS
    }
}

function Adventure-CheckPortalReady {
    param(
        $State,
        $Constants,
        $AdventureRealm
    )

    $exitTile = Get-MapTile -Map $State.Map -Constants $Constants -X ([int]$State.ExitX) -Y ([int]$State.ExitY)
    if ($exitTile -eq $Constants.TILE_EXIT_OPEN) {
        $State.ExitTile = $Constants.TILE_EXIT_OPEN
        return
    }
    if ($State.DataCount -lt $AdventureRealm.RequiredGems) {
        return
    }
    if ($State.ObjectivesDone -lt $State.ObjectivesTotal) {
        return
    }

    Set-MapTile -Map $State.Map -Constants $Constants -X ([int]$State.ExitX) -Y ([int]$State.ExitY) -Tile $Constants.TILE_EXIT_OPEN
    $State.ExitTile = $Constants.TILE_EXIT_OPEN
    Set-AdventureMessageEvent -State $State -Constants $Constants -MessageId $Constants.MSG_GATE
}

function Adventure-FlameHitTile {
    param(
        $State,
        $Constants,
        $AdventureRealm,
        [int]$TileX,
        [int]$TileY
    )

    if (($TileX -lt $Constants.PLAY_MIN_X) -or ($TileX -gt $Constants.PLAY_MAX_X) -or ($TileY -lt $Constants.PLAY_MIN_Y) -or ($TileY -gt $Constants.PLAY_MAX_Y)) {
        return $false
    }

    $tileValue = Get-MapTile -Map $State.Map -Constants $Constants -X $TileX -Y $TileY
    if ($tileValue -eq $Constants.TILE_TERMINAL) {
        Set-MapTile -Map $State.Map -Constants $Constants -X $TileX -Y $TileY -Tile $Constants.TILE_FLOOR
        $State.ObjectivesDone++
        Set-AdventureMessageEvent -State $State -Constants $Constants -MessageId $Constants.MSG_SPOOF
        Adventure-CheckPortalReady -State $State -Constants $Constants -AdventureRealm $AdventureRealm
        return $true
    }

    $enemyIndex = Find-AdventureEnemyAt -State $State -X $TileX -Y $TileY -ExcludeIndex $null
    if ($enemyIndex -lt 0) {
        return $false
    }

    if ($State.Enemies[$enemyIndex].Kind -ne $Constants.ENEMY_FLANKER) {
        return $false
    }

    $State.Enemies[$enemyIndex].Alive = $false
    Award-AdventureKill -State $State -Constants $Constants
    Set-AdventureMessageEvent -State $State -Constants $Constants -MessageId $Constants.MSG_KILL
    return $true
}

function Adventure-GetForwardTargetTile {
    param(
        $State,
        $Constants
    )

    $headingId = Get-AdventureHeadingIdFromYaw -Constants $Constants -Yaw ([int]$State.Yaw)
    $stepX = 0
    $stepY = 0
    switch ($headingId) {
        { $_ -eq $Constants.GAME3D_HEADING_SOUTH } { $stepY = 1 }
        { $_ -eq $Constants.GAME3D_HEADING_EAST } { $stepX = 1 }
        { $_ -eq $Constants.GAME3D_HEADING_NORTH } { $stepY = -1 }
        default { $stepX = -1 }
    }

    return [pscustomobject]@{
        X = ([int]$State.Player.X + $stepX)
        Y = ([int]$State.Player.Y + $stepY)
    }
}

function Adventure-HandleFlame {
    param(
        $State,
        $Constants,
        $AdventureRealm,
        $ControlState
    )

    if ((-not $ControlState.PressedC) -or ($State.FlameTimer -ne 0)) {
        return
    }

    $State.FlameTimer = $Constants.ADVENTURE_FLAME_TICKS
    if (Adventure-FlameHitTile -State $State -Constants $Constants -AdventureRealm $AdventureRealm -TileX ([int]$State.Player.X) -TileY ([int]$State.Player.Y)) {
        return
    }

    $forward = Adventure-GetForwardTargetTile -State $State -Constants $Constants
    [void](Adventure-FlameHitTile -State $State -Constants $Constants -AdventureRealm $AdventureRealm -TileX $forward.X -TileY $forward.Y)
}

function Adventure-HandleMovement {
    param(
        $State,
        $Constants,
        $ControlState
    )

    $speed = Get-AdventureMoveSpeed -State $State -Constants $Constants -ControlState $ControlState
    if ($speed -eq 0) {
        return
    }

    $sinCos = Get-FixedSinCos -AngleByte ([int]$State.Yaw)
    $deltaX = Mul-Fixed88 -A $speed -B $sinCos.Sin
    $deltaZ = Mul-Fixed88 -A $speed -B $sinCos.Cos

    $candidateX = [int]$State.PlayerWorldX + $deltaX
    $candidateZ = [int]$State.PlayerWorldZ
    if (Test-AdventureTryMoveToWorld -State $State -Constants $Constants -WorldX $candidateX -WorldZ $candidateZ) {
        $State.PlayerWorldX = $candidateX
        $State.PlayerWorldZ = $candidateZ
    }

    $candidateX = [int]$State.PlayerWorldX
    $candidateZ = [int]$State.PlayerWorldZ + $deltaZ
    if (Test-AdventureTryMoveToWorld -State $State -Constants $Constants -WorldX $candidateX -WorldZ $candidateZ) {
        $State.PlayerWorldX = $candidateX
        $State.PlayerWorldZ = $candidateZ
    }
}

function Adventure-ApplyVerticalMotion {
    param(
        $State,
        $Constants,
        $ControlState
    )

    if (-not $State.PlayerGrounded) {
        if (($State.PlayerVelY -lt $Constants.ADVENTURE_GLIDE_FALL_LIMIT) -and $ControlState.KeySpace) {
            $State.PlayerVelY = $Constants.ADVENTURE_GLIDE_FALL_LIMIT
        }

        $State.PlayerWorldY += $State.PlayerVelY
        $State.PlayerVelY -= $Constants.ADVENTURE_GRAVITY
        if ($State.PlayerWorldY -le $Constants.GAME3D_FLOOR_Y) {
            $State.PlayerWorldY = $Constants.GAME3D_FLOOR_Y
            $State.PlayerVelY = 0
            $State.PlayerGrounded = $true
        }
        return
    }

    $State.PlayerWorldY = $Constants.GAME3D_FLOOR_Y
    $State.PlayerVelY = 0
}

function Adventure-CollectGemIfPresent {
    param(
        $State,
        $Constants,
        $AdventureRealm
    )

    $tile = Get-MapTile -Map $State.Map -Constants $Constants -X ([int]$State.Player.X) -Y ([int]$State.Player.Y)
    if ($tile -ne $Constants.TILE_SHARD) {
        return
    }

    Set-MapTile -Map $State.Map -Constants $Constants -X ([int]$State.Player.X) -Y ([int]$State.Player.Y) -Tile $Constants.TILE_FLOOR
    $State.DataCount++
    Award-AdventureScore -State $State -Amount $Constants.SCORE_SHARD_POINTS
    Set-AdventureMessageEvent -State $State -Constants $Constants -MessageId $Constants.MSG_SHARD
    Adventure-CheckPortalReady -State $State -Constants $Constants -AdventureRealm $AdventureRealm
}

function Adventure-CollectKeyIfPresent {
    param(
        $State,
        $Constants,
        $AdventureRealm
    )

    $tile = Get-MapTile -Map $State.Map -Constants $Constants -X ([int]$State.Player.X) -Y ([int]$State.Player.Y)
    if ($tile -ne $Constants.TILE_KEY) {
        return
    }

    Set-MapTile -Map $State.Map -Constants $Constants -X ([int]$State.Player.X) -Y ([int]$State.Player.Y) -Tile $Constants.TILE_FLOOR
    $State.KeyCollected = 1
    $State.ObjectivesDone++
    Set-AdventureMessageEvent -State $State -Constants $Constants -MessageId $Constants.MSG_KEY
    Adventure-CheckPortalReady -State $State -Constants $Constants -AdventureRealm $AdventureRealm
}

function Record-AdventureHit {
    param($State)

    $State.Hits = [Math]::Min(255, ([int]$State.Hits + 1))
}

function Adventure-ApplyHazardIfPresent {
    param(
        $State,
        $Constants
    )

    if ((-not $State.PlayerGrounded) -or ($State.HazardTimer -ne 0)) {
        return
    }

    $tile = Get-MapTile -Map $State.Map -Constants $Constants -X ([int]$State.Player.X) -Y ([int]$State.Player.Y)
    if ($tile -ne $Constants.TILE_SURGE) {
        return
    }

    $State.HazardTimer = $Constants.ADVENTURE_HAZARD_COOLDOWN
    Record-AdventureHit -State $State
    $State.ShieldCount--
    Set-AdventureMessageEvent -State $State -Constants $Constants -MessageId $Constants.MSG_SURGE
    if ($State.ShieldCount -le 0) {
        $State.ShieldCount = 0
        Start-AdventureEndBeatShot -State $State -Constants $Constants -TargetState $Constants.STATE_LOSE
    }
}

function Adventure-CheckChargeContact {
    param(
        $State,
        $Constants
    )

    $enemyIndex = Find-AdventureEnemyAt -State $State -X ([int]$State.Player.X) -Y ([int]$State.Player.Y) -ExcludeIndex $null
    if (($enemyIndex -lt 0) -or ($State.ChargeTimer -eq 0)) {
        return
    }

    if ($State.Enemies[$enemyIndex].Kind -eq $Constants.ENEMY_FLANKER) {
        return
    }

    $State.Enemies[$enemyIndex].Alive = $false
    Award-AdventureKill -State $State -Constants $Constants
    Set-AdventureMessageEvent -State $State -Constants $Constants -MessageId $Constants.MSG_KILL
}

function Adventure-TryEnterPortal {
    param(
        $State,
        $Constants,
        $ControlState
    )

    if (-not $ControlState.PressedEnter) {
        return
    }

    $tile = Get-MapTile -Map $State.Map -Constants $Constants -X ([int]$State.Player.X) -Y ([int]$State.Player.Y)
    if ($tile -ne $Constants.TILE_EXIT_OPEN) {
        return
    }

    Start-AdventureEndBeatShot -State $State -Constants $Constants -TargetState $Constants.STATE_WIN
}

function Get-ProjectedAdventurePlayerTarget {
    param(
        $State,
        $Constants
    )

    $targetX = [int]$State.Player.X
    $targetY = [int]$State.Player.Y

    if ($State.LastPlayerDx -ne 0) {
        $candidateX = $targetX + [int]$State.LastPlayerDx
        if (($candidateX -ge $Constants.PLAY_MIN_X) -and ($candidateX -le $Constants.PLAY_MAX_X)) {
            $targetX = $candidateX
        }
    }

    if ($State.LastPlayerDy -ne 0) {
        $candidateY = $targetY + [int]$State.LastPlayerDy
        if (($candidateY -ge $Constants.PLAY_MIN_Y) -and ($candidateY -le $Constants.PLAY_MAX_Y)) {
            $targetY = $candidateY
        }
    }

    return [pscustomobject]@{
        X = $targetX
        Y = $targetY
    }
}

function Get-AdventureDistanceDelta {
    param(
        [int]$FromX,
        [int]$FromY,
        [int]$TargetX,
        [int]$TargetY
    )

    return [pscustomobject]@{
        Dx = [Math]::Abs($TargetX - $FromX)
        Dy = [Math]::Abs($TargetY - $FromY)
    }
}

function Get-AdventureThreatValue {
    param(
        $State,
        $Constants,
        $Enemy
    )

    $delta = Get-AdventureDistanceDelta -FromX ([int]$Enemy.X) -FromY ([int]$Enemy.Y) -TargetX ([int]$State.Player.X) -TargetY ([int]$State.Player.Y)
    $distance = ($delta.Dx + $delta.Dy)
    if ($distance -le $Constants.NEAR_THREAT_DISTANCE) {
        if (($Enemy.Kind -eq $Constants.ENEMY_WARDEN) -and ($State.Sector -eq 3)) {
            return $Constants.THREAT_ELITE
        }

        return $Constants.THREAT_NEAR
    }

    if (($Enemy.Kind -eq $Constants.ENEMY_WARDEN) -and ($State.Sector -eq 3) -and ($distance -le $Constants.ELITE_THREAT_DISTANCE)) {
        return $Constants.THREAT_ELITE
    }

    return $Constants.THREAT_NONE
}

function Update-AdventureEnemyPressure {
    param(
        $State,
        $Constants
    )

    $State.ThreatLevel = $Constants.THREAT_NONE
    for ($enemyIndex = 0; $enemyIndex -lt $State.Enemies.Count; $enemyIndex++) {
        $enemy = $State.Enemies[$enemyIndex]
        if (-not $enemy.Alive) {
            continue
        }

        $threat = Get-AdventureThreatValue -State $State -Constants $Constants -Enemy $enemy
        if ($threat -le $State.ThreatLevel) {
            continue
        }

        $State.ThreatLevel = $threat
        $State.ThreatX = [int]$enemy.X
        $State.ThreatY = [int]$enemy.Y
        if ($State.ThreatLevel -eq $Constants.THREAT_ELITE) {
            break
        }
    }
}

function Invoke-AdventureEnemyStep {
    param(
        $State,
        $Constants,
        [int]$EnemyIndex,
        [int]$TargetX,
        [int]$TargetY,
        [ValidateSet('Horizontal', 'Vertical')] [string]$Axis
    )

    $enemy = $State.Enemies[$EnemyIndex]
    $destX = [int]$enemy.X
    $destY = [int]$enemy.Y

    if ($Axis -eq 'Horizontal') {
        if ($enemy.X -eq $TargetX) {
            return $false
        }

        $destX += $(if ($enemy.X -lt $TargetX) { 1 } else { -1 })
    } else {
        if ($enemy.Y -eq $TargetY) {
            return $false
        }

        $destY += $(if ($enemy.Y -lt $TargetY) { 1 } else { -1 })
    }

    if (($destX -eq $State.Player.X) -and ($destY -eq $State.Player.Y)) {
        Record-AdventureHit -State $State
        $State.ShieldCount--
        $enemy.Alive = $false
        Set-AdventureMessageEvent -State $State -Constants $Constants -MessageId $Constants.MSG_HIT
        if ($State.ShieldCount -le 0) {
            $State.ShieldCount = 0
            Start-AdventureEndBeatShot -State $State -Constants $Constants -TargetState $Constants.STATE_LOSE
        }
        return $true
    }

    $tile = Get-MapTile -Map $State.Map -Constants $Constants -X $destX -Y $destY
    if (($tile -eq $Constants.TILE_WALL) -or ($tile -eq $Constants.TILE_EXIT_LOCKED) -or ($tile -eq $Constants.TILE_EXIT_OPEN)) {
        return $false
    }

    if ($tile -eq $Constants.TILE_SURGE) {
        Set-MapTile -Map $State.Map -Constants $Constants -X $destX -Y $destY -Tile $Constants.TILE_FLOOR
        $enemy.Alive = $false
        Award-AdventureKill -State $State -Constants $Constants
        Award-AdventureScore -State $State -Amount $Constants.SCORE_TRAP_BONUS
        Set-AdventureMessageEvent -State $State -Constants $Constants -MessageId $Constants.MSG_TRAP
        return $true
    }

    if ((Find-AdventureEnemyAt -State $State -X $destX -Y $destY -ExcludeIndex $EnemyIndex) -ge 0) {
        return $false
    }

    $enemy.X = $destX
    $enemy.Y = $destY
    return $true
}

function Move-AdventureEnemy {
    param(
        $State,
        $Constants,
        [int]$EnemyIndex
    )

    $enemy = $State.Enemies[$EnemyIndex]
    $target = $null
    if ($State.SpoofTimer -gt 0) {
        $target = [pscustomobject]@{ X = [int]$State.ExitX; Y = [int]$State.ExitY }
    } elseif ($enemy.Kind -eq $Constants.ENEMY_FLANKER) {
        $target = Get-ProjectedAdventurePlayerTarget -State $State -Constants $Constants
    } elseif ($enemy.Kind -eq $Constants.ENEMY_WARDEN) {
        $playerDelta = Get-AdventureDistanceDelta -FromX ([int]$enemy.X) -FromY ([int]$enemy.Y) -TargetX ([int]$State.Player.X) -TargetY ([int]$State.Player.Y)
        $distance = ($playerDelta.Dx + $playerDelta.Dy)
        if ($distance -le 6) {
            if ($State.Sector -eq 3) {
                $target = Get-ProjectedAdventurePlayerTarget -State $State -Constants $Constants
            } else {
                $target = [pscustomobject]@{ X = [int]$State.Player.X; Y = [int]$State.Player.Y }
            }
        } else {
            $target = [pscustomobject]@{ X = [int]$State.ExitX; Y = [int]$State.ExitY }
        }
    } else {
        $target = [pscustomobject]@{ X = [int]$State.Player.X; Y = [int]$State.Player.Y }
    }

    $delta = Get-AdventureDistanceDelta -FromX ([int]$enemy.X) -FromY ([int]$enemy.Y) -TargetX ([int]$target.X) -TargetY ([int]$target.Y)
    if ($delta.Dy -ge $delta.Dx) {
        if (Invoke-AdventureEnemyStep -State $State -Constants $Constants -EnemyIndex $EnemyIndex -TargetX $target.X -TargetY $target.Y -Axis 'Vertical') {
            return
        }
        [void](Invoke-AdventureEnemyStep -State $State -Constants $Constants -EnemyIndex $EnemyIndex -TargetX $target.X -TargetY $target.Y -Axis 'Horizontal')
        return
    }

    if (Invoke-AdventureEnemyStep -State $State -Constants $Constants -EnemyIndex $EnemyIndex -TargetX $target.X -TargetY $target.Y -Axis 'Horizontal') {
        return
    }
    [void](Invoke-AdventureEnemyStep -State $State -Constants $Constants -EnemyIndex $EnemyIndex -TargetX $target.X -TargetY $target.Y -Axis 'Vertical')
}

function Adventure-MaybeStepEnemies {
    param(
        $State,
        $Constants
    )

    if (($State.IntroTimer -ne 0) -or ($State.StateId -ne $Constants.STATE_PLAYING) -or ($State.EndStatePending -ne 0)) {
        return
    }

    $State.EnemyTick++
    if ($State.EnemyTick -lt $Constants.ADVENTURE_ENEMY_STEP_TICKS) {
        return
    }

    $State.EnemyTick = 0
    $State.ThreatLevel = $Constants.THREAT_NONE
    for ($enemyIndex = 0; $enemyIndex -lt $State.Enemies.Count; $enemyIndex++) {
        if (-not $State.Enemies[$enemyIndex].Alive) {
            continue
        }

        Move-AdventureEnemy -State $State -Constants $Constants -EnemyIndex $enemyIndex
        if ($State.StateId -ne $Constants.STATE_PLAYING) {
            return
        }
    }

    Update-AdventureEnemyPressure -State $State -Constants $Constants
    if ($State.SpoofTimer -gt 0) {
        $State.SpoofTimer--
    }
}

function Process-AdventurePlayInput {
    param(
        $State,
        $Constants,
        $AdventureRealm,
        $ControlState
    )

    if ($State.StateId -ne $Constants.STATE_PLAYING) {
        return
    }

    Adventure-TickTimers -State $State
    if ($State.EndStatePending -ne 0) {
        return
    }

    Adventure-HandleTurn -State $State -Constants $Constants -ControlState $ControlState
    Adventure-HandleJump -State $State -Constants $Constants -ControlState $ControlState
    Adventure-HandleCharge -State $State -Constants $Constants -ControlState $ControlState
    Adventure-HandleFlame -State $State -Constants $Constants -AdventureRealm $AdventureRealm -ControlState $ControlState
    Adventure-HandleMovement -State $State -Constants $Constants -ControlState $ControlState
    Adventure-ApplyVerticalMotion -State $State -Constants $Constants -ControlState $ControlState
    Adventure-SyncPlayerTileFromWorld -State $State -Constants $Constants
    Adventure-CollectGemIfPresent -State $State -Constants $Constants -AdventureRealm $AdventureRealm
    Adventure-CollectKeyIfPresent -State $State -Constants $Constants -AdventureRealm $AdventureRealm
    Adventure-ApplyHazardIfPresent -State $State -Constants $Constants
    Adventure-CheckChargeContact -State $State -Constants $Constants
    Adventure-CheckPortalReady -State $State -Constants $Constants -AdventureRealm $AdventureRealm
    Adventure-TryEnterPortal -State $State -Constants $Constants -ControlState $ControlState
    Adventure-MaybeStepEnemies -State $State -Constants $Constants
}

function Update-AdventureDemoFrontendState {
    param(
        $State,
        $Constants
    )

    if (-not $State.DemoActive) {
        return $true
    }

    if ((($State.StateId -eq $Constants.STATE_WIN) -or ($State.StateId -eq $Constants.STATE_LOSE)) -and ($State.LastGameState -eq $State.StateId)) {
        $State.DemoActive = $false
        return $true
    }

    return $false
}

function Process-AdventureDemoInput {
    param(
        $State,
        $Constants,
        $AdventureRealm,
        [System.Collections.Generic.List[object]]$ActionTape
    )

    if ($State.DemoActionTicks -eq 0) {
        Load-NextAdventureDemoAction -State $State -ActionTape $ActionTape
    }

    if (($State.DemoActionCode -eq 'END') -or ($State.DemoActionTicks -eq 0)) {
        $State.DemoActive = $false
        return $true
    }

    $controlState = Get-AdventureInputForAction -Action ([string]$State.DemoActionCode)
    Process-AdventurePlayInput -State $State -Constants $Constants -AdventureRealm $AdventureRealm -ControlState $controlState
    $State.DemoActionTicks--
    return (-not $State.DemoActive)
}

function Invoke-AdventureDemoSimulation {
    param(
        $Demo,
        $Constants,
        [object[]]$GameplayKits,
        $AdventureRealm
    )

    $state = New-AdventureRuntimeState -Demo $Demo -Constants $Constants -AdventureRealm $AdventureRealm
    $actionTape = New-DemoActionTape -Demo $Demo
    $maxTicks = (Get-DemoTotalTicks -Demo $Demo) + 180

    for ($tickIndex = 0; $tickIndex -lt $maxTicks; $tickIndex++) {
        if (Update-AdventureDemoFrontendState -State $state -Constants $Constants) {
            break
        }

        Update-AdventureRuntimeFeedback -State $state -Constants $Constants
        if (($state.StateId -eq $Constants.STATE_PLAYING) -and $state.DemoActive) {
            if (Process-AdventureDemoInput -State $state -Constants $Constants -AdventureRealm $AdventureRealm -ActionTape $actionTape) {
                break
            }
        }
    }

    $state.ExitTile = Get-MapTile -Map $state.Map -Constants $Constants -X ([int]$state.ExitX) -Y ([int]$state.ExitY)
    return $state
}

function Get-StepRepeatCount {
    param(
        $Step,
        [string]$DemoName
    )

    if ($Step -is [System.Collections.IDictionary]) {
        if ($Step.ContainsKey('Ticks')) { return [int]$Step['Ticks'] }
        if ($Step.ContainsKey('Count')) { return [int]$Step['Count'] }
        if ($Step.ContainsKey('Repeat')) { return [int]$Step['Repeat'] }
        throw ("Demo '{0}' step is missing a repeat/tick count." -f $DemoName)
    }

    $parts = ([string]$Step).Trim() -split '\s+'
    if ($parts.Count -ne 2) {
        throw ("Demo '{0}' step '{1}' must be 'ACTION COUNT'." -f $DemoName, $Step)
    }

    return [int]$parts[1]
}

function Get-DemoTotalTicks {
    param($Demo)

    $ticks = 0
    foreach ($step in @($Demo.Steps)) {
        $ticks += Get-StepRepeatCount -Step $step -DemoName ([string]$Demo.Name)
    }

    return $ticks
}

Assert-PathExists -Path $DemoSourcePath -Label 'demo source'
Assert-PathExists -Path $GeometrySourcePath -Label 'geometry source'
Assert-PathExists -Path $SectorSourcePath -Label 'sector source'
Assert-PathExists -Path $ConstantsSourcePath -Label 'constants source'

$constants = Get-RequiredConstants -SourcePath $ConstantsSourcePath
$geometryKits = Get-GameplayKitDefinitions -SourcePath $GeometrySourcePath
$adventureRealm = Get-AdventureRealmDefinition -SourcePath $SectorSourcePath
$demoData = Import-StructuredDataFile -SourcePath $DemoSourcePath -Label 'demo source'
$demos = @($demoData.Demos)
if ($demos.Count -eq 0) {
    throw ("Demo source must define at least one demo: {0}" -f $DemoSourcePath)
}

$results = New-Object 'System.Collections.Generic.List[object]'
$summaryLines = New-Object 'System.Collections.Generic.List[string]'
$reportLines = New-Object 'System.Collections.Generic.List[string]'
$reportLines.Add('CyberStorm Replay Harness Report')
$reportLines.Add(("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')))
$reportLines.Add(("Source: {0}" -f $DemoSourcePath))
$reportLines.Add(("Mode: {0}" -f $(if ($SfxOnly.IsPresent) { 'SFX_ONLY' } else { 'MUSIC' })))
$reportLines.Add('')

for ($demoIndex = 0; $demoIndex -lt $demos.Count; $demoIndex++) {
    $demo = $demos[$demoIndex]
    if (-not ($demo -is [System.Collections.IDictionary])) {
        throw ("Each demo in {0} must be a hashtable." -f $DemoSourcePath)
    }
    if (-not $demo.ContainsKey('Expected') -or -not ($demo.Expected -is [System.Collections.IDictionary])) {
        throw ("Demo '{0}' in {1} must define an Expected block for adventure verification." -f $demo.Name, $DemoSourcePath)
    }

    $runtimeState = Invoke-AdventureDemoSimulation -Demo $demo -Constants $constants -GameplayKits $geometryKits -AdventureRealm $adventureRealm
    $signature = Get-RuntimeVerificationSignature -RuntimeState $runtimeState -Constants $constants -GameplayKits $geometryKits -AdventureRealm $adventureRealm
    $diagnostics = Get-AdventureAutonomousDiagnostics -State $runtimeState
    $stepTicks = 0
    foreach ($step in @($demo.Steps)) {
        $stepTicks += Get-StepRepeatCount -Step $step -DemoName ([string]$demo.Name)
    }

    $results.Add([pscustomobject]@{
        Name = [string]$demo.Name
        RuntimeFinalSignature = $signature
        CheckpointSignatures = @()
    })
    $summaryLines.Add(("{0}: final {1}" -f $demo.Name, (Format-Hex16 $signature)))

    $reportLines.Add(("Demo {0}: {1}" -f ($demoIndex + 1), $demo.Name))
    $reportLines.Add(("  Id: {0}" -f $demo.Id))
    $reportLines.Add(("  Ticks: {0}" -f $stepTicks))
    $reportLines.Add(("  State: {0}" -f $(switch ($runtimeState.StateId) { $constants.STATE_WIN { 'WIN' } $constants.STATE_LOSE { 'LOSE' } default { 'PLAYING' } })))
    $reportLines.Add(("  Player: {0},{1}" -f $runtimeState.Player.X, $runtimeState.Player.Y))
    $reportLines.Add(("  HeadingId: {0}" -f (Get-AdventureHeadingIdFromYaw -Constants $constants -Yaw $runtimeState.Yaw)))
    $reportLines.Add(("  Objectives: {0}/{1}" -f $runtimeState.ObjectivesDone, $runtimeState.ObjectivesTotal))
    $reportLines.Add(("  PortalTile: {0}" -f $runtimeState.ExitTile))
    $reportLines.Add(("  Score/Kills/Hits: {0}/{1}/{2}" -f $runtimeState.Score, $runtimeState.KillCount, $runtimeState.Hits))
    $reportLines.Add(("  Shot: mode={0} reason={1} tick={2} subject={3},{4} frame={5}" -f $runtimeState.ShotMode, $runtimeState.ShotReason, $runtimeState.ShotTick, $runtimeState.ShotSubject.X, $runtimeState.ShotSubject.Y, $runtimeState.ShotFrameVariant))
    $reportLines.Add(("  CueFlags: {0}" -f (Get-RuntimeCueFlags -RuntimeState $runtimeState -Constants $constants -GameplayKits $geometryKits -AdventureRealm $adventureRealm)))
    $reportLines.Add(("  Autonomous: intro={0} enemyTick={1} threat={2} tile={3},{4}" -f $diagnostics.IntroTimer, $diagnostics.EnemyTick, $diagnostics.ThreatLevel, $diagnostics.ThreatX, $diagnostics.ThreatY))
    $reportLines.Add(("  EnemySlots: e0={0} e1={1} e2={2}" -f (Format-Hex16 $diagnostics.Enemy0), (Format-Hex16 $diagnostics.Enemy1), (Format-Hex16 $diagnostics.Enemy2)))
    $reportLines.Add(("  Final signature: {0}" -f (Format-Hex16 $signature)))
    $reportLines.Add('')
}

Set-Content -LiteralPath $ReportPath -Encoding ascii -Value $reportLines

return [pscustomobject]@{
    ReportPath = $ReportPath
    ScenarioCount = $results.Count
    SummaryLines = $summaryLines.ToArray()
    WarningLines = @()
    Results = $results.ToArray()
}
