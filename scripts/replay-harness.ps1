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
        'MAP_W',
        'MAP_H',
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
        'TILE_EXIT_LOCKED',
        'TILE_EXIT_OPEN'
    )

    $constants = @{}
    foreach ($name in $constantNames) {
        $constants[$name] = Get-AsmEquValue -SourcePath $SourcePath -Name $name
    }

    return $constants
}

function Get-GameplayKitDefinitions {
    param([string]$SourcePath)

    $geometryData = Import-StructuredDataFile -SourcePath $SourcePath -Label 'geometry source'
    if (-not $geometryData.ContainsKey('GameplayKits')) {
        throw ("Geometry source must define a 'GameplayKits' array: {0}" -f $SourcePath)
    }

    $expectedKitKeys = @('sector1', 'sector2', 'sector3')
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
        Portal = [pscustomobject]@{
            X = [int](([string]$realm.Portal -split ',')[0])
            Y = [int](([string]$realm.Portal -split ',')[1])
        }
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

    $exitProjection = Project-TileCenter -RuntimeState $RuntimeState -Constants $Constants -GameplayKits $GameplayKits -TileX $AdventureRealm.Portal.X -TileY $AdventureRealm.Portal.Y
    if (-not (Test-CueReady -Projection $exitProjection -Constants $Constants)) {
        $flags = $flags -bor $Constants.GAME3D_CUE_FLAG_EXIT_FALLBACK
    }

    return $flags
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

    return [pscustomobject]@{
        Name = [string]$Demo.Name
        StateId = (Get-StateId -Constants $Constants -StateName ([string]$Expected.State))
        Sector = if ($Expected.ContainsKey('Sector')) { [int]$Expected.Sector } else { [int]$Demo.StartSector }
        TemplateIndex = if ($Expected.ContainsKey('TemplateIndex')) { [int]$Expected.TemplateIndex } else { 0 }
        Player = $player
        HeadingId = (Get-HeadingId -Constants $Constants -HeadingName $headingName)
        Yaw = (Get-YawFromHeading -Constants $Constants -HeadingName $headingName)
        ShotMode = $shotMode
        ShotReason = $shotReason
        ShotSubject = $shotSubject
        ShotFrameVariant = $frameVariant
        ShieldCount = if ($Expected.ContainsKey('Shields')) { [int]$Expected.Shields } else { 5 }
        PulseCount = if ($Expected.ContainsKey('Pulses')) { [int]$Expected.Pulses } else { 0 }
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

    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.StateId
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.Sector
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.TemplateIndex
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.Player.X
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.Player.Y
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.HeadingId
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value (Get-RoomVariantFromHeading -Constants $Constants -HeadingId $RuntimeState.HeadingId)
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
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.ExitTile
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.KillCount
    $signature = Update-RuntimeSignatureWord -Signature $signature -Value $RuntimeState.Score
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.Actions
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.Hits
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.PulsesUsed
    $signature = Update-RuntimeSignatureByte -Signature $signature -Value $RuntimeState.SpoofTimer
    return ($signature -band 0xFFFF)
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

    $runtimeState = Build-RuntimeStateFromExpected -Demo $demo -Expected $demo.Expected -Constants $constants -AdventureRealm $adventureRealm
    $signature = Get-RuntimeVerificationSignature -RuntimeState $runtimeState -Constants $constants -GameplayKits $geometryKits -AdventureRealm $adventureRealm
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
    $reportLines.Add(("  State: {0}" -f $demo.Expected.State))
    $reportLines.Add(("  Player: {0}" -f $demo.Expected.Player))
    $reportLines.Add(("  Heading: {0}" -f $(if ($demo.Expected.ContainsKey('Heading')) { $demo.Expected.Heading } else { 'EAST' })))
    $reportLines.Add(("  Objectives: {0}/{1}" -f $(if ($demo.Expected.ContainsKey('Objectives')) { $demo.Expected.Objectives } else { 0 }), $(if ($demo.Expected.ContainsKey('ObjectivesTotal')) { $demo.Expected.ObjectivesTotal } else { $adventureRealm.ObjectivesTotal })))
    $reportLines.Add(("  Portal: {0}" -f $(if ($demo.Expected.ContainsKey('Portal')) { $demo.Expected.Portal } else { 'LOCKED' })))
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
