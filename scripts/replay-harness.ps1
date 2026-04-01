param(
    [string]$SectorSourcePath = (Join-Path (Join-Path $PSScriptRoot '..') 'assets\sectors.psd1'),
    [string]$DemoSourcePath = (Join-Path (Join-Path $PSScriptRoot '..') 'assets\demos.psd1'),
    [string]$ConstantsSourcePath = (Join-Path (Join-Path $PSScriptRoot '..') 'src\game\constants.inc'),
    [string]$ReportPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm-replay-report.txt')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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
    $pattern = "^\s*{0}\s+equ\s+([0-9A-Fa-f]+h|\d+)\s*(?:;.*)?$" -f [regex]::Escape($Name)
    $match = Select-String -LiteralPath $SourcePath -Pattern $pattern | Select-Object -First 1
    if (-not $match) {
        throw ("Could not find numeric '{0} equ <value>' in {1}" -f $Name, $SourcePath)
    }

    $token = $match.Matches[0].Groups[1].Value
    if ($token -match '^[0-9A-Fa-f]+h$') {
        return [Convert]::ToInt32($token.Substring(0, $token.Length - 1), 16)
    }

    return [int]$token
}

function Format-Hex16 {
    param([int]$Value)
    return ("0x{0:X4}" -f ($Value -band 0xFFFF))
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
        'SPOOF_TURNS',
        'SURGE_PLAYER_DAMAGE',
        'ENEMY_SPAWN_STEP',
        'ENEMY_SPAWN_BASE',
        'PULSE_RADIUS',
        'PULSE_RECHARGE_KILLS',
        'SAFE_X_MAX',
        'SAFE_Y_MIN',
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
        'SCORE_WIN_PULSE_BONUS'
    )

    $constants = @{}
    foreach ($name in $constantNames) {
        $constants[$name] = Get-AsmEquValue -SourcePath $SourcePath -Name $name
    }

    $constants['PLAY_MAX_X'] = $constants.MAP_W - 2
    $constants['PLAY_MAX_Y'] = $constants.MAP_H - 2

    return $constants
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
    Load-ReplaySector -State $State -Constants $Constants -Sectors $Sectors
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
        return $maps[0]
    }

    $rngWord = Get-NextRngWord -State $State.Rng
    $selectedIndex = $rngWord % $maps.Count
    return $maps[$selectedIndex]
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

function Place-Terminals {
    param(
        $State,
        $Constants,
        $Sectors
    )

    $rules = Get-SectorRules -Sectors $Sectors -SectorId $State.SectorNum
    for ($i = 0; $i -lt [int]$rules.TerminalCount; $i++) {
        $position = Get-RandomTerminalPosition -State $State -Constants $Constants
        Set-Tile -State $State -Constants $Constants -X $position.X -Y $position.Y -Tile 'TERMINAL'
    }
}

function Place-Shards {
    param(
        $State,
        $Constants
    )

    for ($i = 0; $i -lt $Constants.SHARD_COUNT; $i++) {
        $position = Get-RandomFloorPosition -State $State -Constants $Constants
        Set-Tile -State $State -Constants $Constants -X $position.X -Y $position.Y -Tile 'SHARD'
    }
}

function Place-Surges {
    param(
        $State,
        $Constants,
        $Sectors
    )

    $rules = Get-SectorRules -Sectors $Sectors -SectorId $State.SectorNum
    for ($i = 0; $i -lt [int]$rules.SurgeCount; $i++) {
        $position = Get-RandomFloorPosition -State $State -Constants $Constants
        Set-Tile -State $State -Constants $Constants -X $position.X -Y $position.Y -Tile 'SURGE'
    }
}

function Place-Enemies {
    param(
        $State,
        $Constants,
        $Sectors
    )

    $enemyCount = Get-SectorEnemyCount -State $State -Constants $Constants -Sectors $Sectors
    for ($i = 0; $i -lt $enemyCount; $i++) {
        $position = Get-RandomEnemyPosition -State $State -Constants $Constants
        $enemy = $State.Enemies[$i]
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
    Copy-SectorLayout -State $State -Constants $Constants -Map $map

    $State.PlayerX = $Constants.START_X
    $State.PlayerY = $Constants.START_Y
    $State.ExitX = $Constants.EXIT_COL
    $State.ExitY = $Constants.EXIT_ROW
    Set-ExitLocked -State $State -Constants $Constants
    Place-Terminals -State $State -Constants $Constants -Sectors $Sectors
    Place-Shards -State $State -Constants $Constants
    Place-Surges -State $State -Constants $Constants -Sectors $Sectors
    Place-Enemies -State $State -Constants $Constants -Sectors $Sectors
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

function Run-EnemyTurn {
    param(
        $State,
        $Constants,
        $Sectors
    )

    for ($i = 0; $i -lt $State.Enemies.Count; $i++) {
        Move-Enemy -State $State -Constants $Constants -Sectors $Sectors -EnemyIndex $i
        if ($State.GameState -ne 'PLAYING') {
            break
        }
    }

    if ($State.GameState -eq 'PLAYING' -and $State.SpoofTimer -gt 0) {
        $State.SpoofTimer -= 1
    }
}

function Use-Pulse {
    param(
        $State,
        $Constants
    )

    if ($State.PulseCount -le 0) {
        return $false
    }

    $State.PulseCount -= 1
    Record-SectorPulse -State $State
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
        return $true
    }

    $tile = Get-Tile -State $State -Constants $Constants -X $TargetX -Y $TargetY
    switch ($tile) {
        'WALL' { return $false }
        'EXIT_LOCKED' { return $false }
        'SHARD' {
            Set-Tile -State $State -Constants $Constants -X $TargetX -Y $TargetY -Tile 'FLOOR'
            Commit-PlayerMove -State $State -TargetX $TargetX -TargetY $TargetY
            $State.DataCount += 1
            Award-Score -State $State -Points $Constants.SCORE_SHARD_POINTS
            if ($State.DataCount -ge $Constants.SHARD_COUNT) {
                Open-Exit -State $State -Constants $Constants
            }

            return $true
        }
        'TERMINAL' {
            Set-Tile -State $State -Constants $Constants -X $TargetX -Y $TargetY -Tile 'FLOOR'
            Commit-PlayerMove -State $State -TargetX $TargetX -TargetY $TargetY
            $State.SpoofX = $TargetX
            $State.SpoofY = $TargetY
            $State.SpoofTimer = $Constants.SPOOF_TURNS
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
            return $false
        }
        'SURGE' {
            Set-Tile -State $State -Constants $Constants -X $TargetX -Y $TargetY -Tile 'FLOOR'
            Commit-PlayerMove -State $State -TargetX $TargetX -TargetY $TargetY
            Record-SectorHit -State $State
            $State.ShieldCount -= $Constants.SURGE_PLAYER_DAMAGE
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
            }
        }
        'RIGHT' {
            if ($State.PlayerX -lt $Constants.PLAY_MAX_X) {
                $actionTaken = Attempt-MoveTo -State $State -Constants $Constants -Sectors $Sectors -TargetX ($State.PlayerX + 1) -TargetY $State.PlayerY
            }
        }
        'UP' {
            if ($State.PlayerY -gt $Constants.PLAY_MIN_Y) {
                $actionTaken = Attempt-MoveTo -State $State -Constants $Constants -Sectors $Sectors -TargetX $State.PlayerX -TargetY ($State.PlayerY - 1)
            }
        }
        'DOWN' {
            if ($State.PlayerY -lt $Constants.PLAY_MAX_Y) {
                $actionTaken = Attempt-MoveTo -State $State -Constants $Constants -Sectors $Sectors -TargetX $State.PlayerX -TargetY ($State.PlayerY + 1)
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
        $Sectors
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

    $steps = @($Demo.Steps)
    if ($steps.Count -eq 0) {
        throw ("Demo '{0}' does not define any Steps." -f $name)
    }

    $state = New-ReplayState -Constants $Constants -Sectors $Sectors -StartSector $startSector -Seed $seed
    foreach ($step in $steps) {
        $parsedStep = Get-StepActionKey -Step $step -DemoName $name
        for ($tick = 0; $tick -lt $parsedStep.Count; $tick++) {
            $state.TraceTicks += 1
            Process-ReplayAction -State $state -Constants $Constants -Sectors $Sectors -Action $parsedStep.Action
            if ($state.GameState -ne 'PLAYING') {
                break
            }
        }

        if ($state.GameState -ne 'PLAYING') {
            break
        }
    }

    $observed = Get-ObservedReplayResult -State $state
    $expected = if (($Demo -is [System.Collections.IDictionary]) -and $Demo.ContainsKey('Expected')) { $Demo.Expected } else { $null }
    return [pscustomobject]@{
        Name = $name
        StartSector = $startSector
        Seed = (Format-Hex16 $seed)
        Ticks = $state.TraceTicks
        Observed = $observed
        Signature = (Get-ReplaySignature -Observed $observed)
        SuggestedExpectation = (ConvertTo-ExpectationBlock -Indent '            ' -Observed $observed)
        Mismatches = (Compare-ExpectedReplayResult -DemoName $name -Expected $expected -Observed $observed)
    }
}

$constants = Get-RequiredConstants -SourcePath $ConstantsSourcePath
$sectorSource = Import-StructuredDataFile -SourcePath $SectorSourcePath -Label 'sector source'
$demoSource = Import-StructuredDataFile -SourcePath $DemoSourcePath -Label 'demo source'

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

$reportLines.Add('CyberStorm Replay Harness')
$reportLines.Add(("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')))
$reportLines.Add(("Demo source: {0}" -f $DemoSourcePath))
$reportLines.Add(("Sector source: {0}" -f $SectorSourcePath))
$reportLines.Add(("Scenarios: {0}" -f $demos.Count))
$reportLines.Add('')

foreach ($demo in $demos) {
    $name = if ($demo -is [System.Collections.IDictionary]) { [string]$demo.Name } else { '<invalid demo>' }
    $reportLines.Add(("Demo: {0}" -f $name))
    try {
        $result = Invoke-ReplayScenario -Demo $demo -Constants $constants -Sectors $sectors
        $summaryLines.Add(("{0}: {1}" -f $result.Name, $result.Signature))
        $reportLines.Add(("  Seed: {0}" -f $result.Seed))
        $reportLines.Add(("  Ticks: {0}" -f $result.Ticks))
        $reportLines.Add(("  Signature: {0}" -f $result.Signature))
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
}
