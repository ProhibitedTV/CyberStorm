param(
    [string]$SectorSourcePath = (Join-Path (Join-Path $PSScriptRoot '..') 'assets\sectors.psd1'),
    [string]$ConstantsSourcePath = (Join-Path (Join-Path $PSScriptRoot '..') 'src\game\constants.inc'),
    [string]$ReportPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm-balance-report.txt')
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

function Get-BoardFromRows {
    param([string[]]$Rows)

    $board = @()
    foreach ($row in $Rows) {
        $chars = New-Object char[] $row.Length
        for ($i = 0; $i -lt $row.Length; $i++) {
            $chars[$i] = if ($row[$i] -eq '#') { '#' } else { '.' }
        }
        $board += ,$chars
    }

    return ,$board
}

function Get-BoardTile {
    param($Board, [int]$X, [int]$Y)
    return [char]$Board[$Y][$X]
}

function Set-BoardTile {
    param($Board, [int]$X, [int]$Y, [char]$Value)
    $Board[$Y][$X] = $Value
}

function Test-WalkableTile {
    param($Board, [int]$X, [int]$Y)
    return ((Get-BoardTile -Board $Board -X $X -Y $Y) -ne '#')
}

function Get-WalkableNeighborCount {
    param($Board, [int]$X, [int]$Y, [int]$MapW, [int]$MapH)

    $count = 0
    foreach ($delta in @(
        @{ X = 1; Y = 0 },
        @{ X = -1; Y = 0 },
        @{ X = 0; Y = 1 },
        @{ X = 0; Y = -1 }
    )) {
        $nx = $X + $delta.X
        $ny = $Y + $delta.Y
        if ($nx -lt 0 -or $nx -ge $MapW -or $ny -lt 0 -or $ny -ge $MapH) {
            continue
        }

        if (Test-WalkableTile -Board $Board -X $nx -Y $ny) {
            $count += 1
        }
    }

    return $count
}

function Get-MapMetrics {
    param(
        [string[]]$Rows,
        [int]$MapW,
        [int]$MapH,
        [int]$StartX,
        [int]$StartY,
        [int]$ExitX,
        [int]$ExitY,
        [int]$SafeXMax,
        [int]$SafeYMin
    )

    $board = Get-BoardFromRows -Rows $Rows
    if (-not (Test-WalkableTile -Board $board -X $StartX -Y $StartY)) {
        throw ("Map start tile is blocked at ({0},{1})." -f $StartX, $StartY)
    }

    if (-not (Test-WalkableTile -Board $board -X $ExitX -Y $ExitY)) {
        throw ("Map exit tile is blocked at ({0},{1})." -f $ExitX, $ExitY)
    }

    $queue = New-Object 'System.Collections.Generic.Queue[int]'
    $distance = New-Object int[] ($MapW * $MapH)
    for ($i = 0; $i -lt $distance.Length; $i++) {
        $distance[$i] = -1
    }

    $startIndex = ($StartY * $MapW) + $StartX
    $exitIndex = ($ExitY * $MapW) + $ExitX
    $distance[$startIndex] = 0
    $queue.Enqueue($startIndex)

    while ($queue.Count -gt 0) {
        $index = $queue.Dequeue()
        $x = $index % $MapW
        $y = [int](($index - $x) / $MapW)
        foreach ($delta in @(
            @{ X = 1; Y = 0 },
            @{ X = -1; Y = 0 },
            @{ X = 0; Y = 1 },
            @{ X = 0; Y = -1 }
        )) {
            $nx = $x + $delta.X
            $ny = $y + $delta.Y
            if ($nx -lt 0 -or $nx -ge $MapW -or $ny -lt 0 -or $ny -ge $MapH) {
                continue
            }

            if (-not (Test-WalkableTile -Board $board -X $nx -Y $ny)) {
                continue
            }

            $neighborIndex = ($ny * $MapW) + $nx
            if ($distance[$neighborIndex] -ne -1) {
                continue
            }

            $distance[$neighborIndex] = $distance[$index] + 1
            $queue.Enqueue($neighborIndex)
        }
    }

    $pathLength = $distance[$exitIndex]
    if ($pathLength -lt 0) {
        throw ("Map has no walkable path from start ({0},{1}) to exit ({2},{3})." -f $StartX, $StartY, $ExitX, $ExitY)
    }

    $openTiles = 0
    $branchTiles = 0
    $floorPool = 0
    $terminalSafePool = 0
    $enemySafePool = 0
    for ($y = 0; $y -lt $MapH; $y++) {
        for ($x = 0; $x -lt $MapW; $x++) {
            if (-not (Test-WalkableTile -Board $board -X $x -Y $y)) {
                continue
            }

            $openTiles += 1
            if ((Get-WalkableNeighborCount -Board $board -X $x -Y $y -MapW $MapW -MapH $MapH) -ge 3) {
                $branchTiles += 1
            }

            if (($x -eq $StartX -and $y -eq $StartY) -or ($x -eq $ExitX -and $y -eq $ExitY)) {
                continue
            }

            $floorPool += 1
            $inSafeZone = ($x -le $SafeXMax -and $y -ge $SafeYMin)
            if (-not $inSafeZone) {
                $terminalSafePool += 1
                $enemySafePool += 1
            }
        }
    }

    return [pscustomobject]@{
        OpenTiles = $openTiles
        BranchTiles = $branchTiles
        PathLength = $pathLength
        FloorPool = $floorPool
        TerminalSafePool = $terminalSafePool
        EnemySafePool = $enemySafePool
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

function Find-RandomFloorPosition {
    param(
        $Board,
        $State,
        [int]$StartX,
        [int]$StartY,
        [int]$ExitX,
        [int]$ExitY,
        [int]$PlayMaxX,
        [int]$PlayMaxY,
        [int]$RetryLimit
    )

    for ($attempt = 1; $attempt -le $RetryLimit; $attempt++) {
        $x = Get-RandomX -State $State -PlayMaxX $PlayMaxX
        $y = Get-RandomY -State $State -PlayMaxY $PlayMaxY
        if ($x -eq $StartX -and $y -eq $StartY) {
            continue
        }

        if ($x -eq $ExitX -and $y -eq $ExitY) {
            continue
        }

        if ((Get-BoardTile -Board $Board -X $x -Y $y) -ne '.') {
            continue
        }

        return [pscustomobject]@{
            X = $x
            Y = $y
            Attempts = $attempt
        }
    }

    throw ("Random floor placement exceeded retry limit ({0})." -f $RetryLimit)
}

function Find-RandomTerminalPosition {
    param(
        $Board,
        $State,
        [int]$StartX,
        [int]$StartY,
        [int]$ExitX,
        [int]$ExitY,
        [int]$PlayMaxX,
        [int]$PlayMaxY,
        [int]$SafeXMax,
        [int]$SafeYMin,
        [int]$RetryLimit
    )

    for ($attempt = 1; $attempt -le $RetryLimit; $attempt++) {
        $candidate = Find-RandomFloorPosition `
            -Board $Board `
            -State $State `
            -StartX $StartX `
            -StartY $StartY `
            -ExitX $ExitX `
            -ExitY $ExitY `
            -PlayMaxX $PlayMaxX `
            -PlayMaxY $PlayMaxY `
            -RetryLimit $RetryLimit
        if ($candidate.X -le $SafeXMax -and $candidate.Y -ge $SafeYMin) {
            continue
        }

        $candidate | Add-Member -NotePropertyName Attempts -NotePropertyValue $attempt -Force
        return $candidate
    }

    throw ("Random terminal placement exceeded retry limit ({0})." -f $RetryLimit)
}

function Find-RandomEnemyPosition {
    param(
        $Board,
        $EnemyPositions,
        $State,
        [int]$StartX,
        [int]$StartY,
        [int]$ExitX,
        [int]$ExitY,
        [int]$PlayMaxX,
        [int]$PlayMaxY,
        [int]$SafeXMax,
        [int]$SafeYMin,
        [int]$RetryLimit
    )

    for ($attempt = 1; $attempt -le $RetryLimit; $attempt++) {
        $candidate = Find-RandomFloorPosition `
            -Board $Board `
            -State $State `
            -StartX $StartX `
            -StartY $StartY `
            -ExitX $ExitX `
            -ExitY $ExitY `
            -PlayMaxX $PlayMaxX `
            -PlayMaxY $PlayMaxY `
            -RetryLimit $RetryLimit
        if ($candidate.X -le $SafeXMax -and $candidate.Y -ge $SafeYMin) {
            continue
        }

        $occupied = $false
        foreach ($position in $EnemyPositions) {
            if ($position.X -eq $candidate.X -and $position.Y -eq $candidate.Y) {
                $occupied = $true
                break
            }
        }

        if ($occupied) {
            continue
        }

        $candidate | Add-Member -NotePropertyName Attempts -NotePropertyValue $attempt -Force
        return $candidate
    }

    throw ("Random enemy placement exceeded retry limit ({0})." -f $RetryLimit)
}

function Get-EnemyKind {
    param(
        $State,
        [int]$FlankerThreshold,
        [int]$WardenThreshold
    )

    $roll = (Get-NextRngWord -State $State) -band 0xFF
    if ($WardenThreshold -gt 0 -and $roll -lt $WardenThreshold) {
        return 'Warden'
    }

    if ($roll -lt $FlankerThreshold) {
        return 'Flanker'
    }

    return 'Rusher'
}

function Invoke-ScenarioSweep {
    param(
        [string[]]$Rows,
        [int]$Seed,
        [int]$StartX,
        [int]$StartY,
        [int]$ExitX,
        [int]$ExitY,
        [int]$PlayMaxX,
        [int]$PlayMaxY,
        [int]$SafeXMax,
        [int]$SafeYMin,
        [int]$ShardCount,
        [int]$SurgeCount,
        [int]$TerminalCount,
        [int]$EnemyCount,
        [int]$FlankerThreshold,
        [int]$WardenThreshold,
        [int]$RetryLimit
    )

    $board = Get-BoardFromRows -Rows $Rows
    Set-BoardTile -Board $board -X $ExitX -Y $ExitY -Value 'X'
    $state = New-RngState -Seed $Seed
    $enemyPositions = New-Object 'System.Collections.Generic.List[object]'
    $kindCounts = @{
        Rusher = 0
        Flanker = 0
        Warden = 0
    }

    $worstAttempts = 0

    foreach ($index in 1..$TerminalCount) {
        $terminal = Find-RandomTerminalPosition `
            -Board $board `
            -State $state `
            -StartX $StartX `
            -StartY $StartY `
            -ExitX $ExitX `
            -ExitY $ExitY `
            -PlayMaxX $PlayMaxX `
            -PlayMaxY $PlayMaxY `
            -SafeXMax $SafeXMax `
            -SafeYMin $SafeYMin `
            -RetryLimit $RetryLimit
        if ($terminal.Attempts -gt $worstAttempts) { $worstAttempts = $terminal.Attempts }
        Set-BoardTile -Board $board -X $terminal.X -Y $terminal.Y -Value 'T'
    }

    foreach ($index in 1..$ShardCount) {
        $shard = Find-RandomFloorPosition `
            -Board $board `
            -State $state `
            -StartX $StartX `
            -StartY $StartY `
            -ExitX $ExitX `
            -ExitY $ExitY `
            -PlayMaxX $PlayMaxX `
            -PlayMaxY $PlayMaxY `
            -RetryLimit $RetryLimit
        if ($shard.Attempts -gt $worstAttempts) { $worstAttempts = $shard.Attempts }
        Set-BoardTile -Board $board -X $shard.X -Y $shard.Y -Value 'D'
    }

    foreach ($index in 1..$SurgeCount) {
        $surge = Find-RandomFloorPosition `
            -Board $board `
            -State $state `
            -StartX $StartX `
            -StartY $StartY `
            -ExitX $ExitX `
            -ExitY $ExitY `
            -PlayMaxX $PlayMaxX `
            -PlayMaxY $PlayMaxY `
            -RetryLimit $RetryLimit
        if ($surge.Attempts -gt $worstAttempts) { $worstAttempts = $surge.Attempts }
        Set-BoardTile -Board $board -X $surge.X -Y $surge.Y -Value 'U'
    }

    foreach ($index in 1..$EnemyCount) {
        $enemy = Find-RandomEnemyPosition `
            -Board $board `
            -EnemyPositions $enemyPositions `
            -State $state `
            -StartX $StartX `
            -StartY $StartY `
            -ExitX $ExitX `
            -ExitY $ExitY `
            -PlayMaxX $PlayMaxX `
            -PlayMaxY $PlayMaxY `
            -SafeXMax $SafeXMax `
            -SafeYMin $SafeYMin `
            -RetryLimit $RetryLimit
        if ($enemy.Attempts -gt $worstAttempts) { $worstAttempts = $enemy.Attempts }
        $kind = Get-EnemyKind -State $state -FlankerThreshold $FlankerThreshold -WardenThreshold $WardenThreshold
        $kindCounts[$kind] += 1
        $enemy | Add-Member -NotePropertyName Kind -NotePropertyValue $kind
        $enemyPositions.Add($enemy)
    }

    $nearestEnemyDistance = if ($enemyPositions.Count -eq 0) {
        0
    } else {
        ($enemyPositions | ForEach-Object {
            [Math]::Abs($_.X - $StartX) + [Math]::Abs($_.Y - $StartY)
        } | Measure-Object -Minimum).Minimum
    }

    return [pscustomobject]@{
        WorstAttempts = $worstAttempts
        NearestEnemyDistance = [int]$nearestEnemyDistance
        RusherCount = $kindCounts.Rusher
        FlankerCount = $kindCounts.Flanker
        WardenCount = $kindCounts.Warden
    }
}

function Format-Percent {
    param(
        [int]$Count,
        [int]$Total
    )

    if ($Total -le 0) {
        return '0%'
    }

    return ("{0}%" -f [Math]::Round(($Count * 100.0) / $Total, 1))
}

Assert-PathExists -Path $SectorSourcePath -Label 'sector source'
Assert-PathExists -Path $ConstantsSourcePath -Label 'constants source'
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ReportPath) | Out-Null

$constants = @{
    MAP_W = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'MAP_W'
    MAP_H = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'MAP_H'
    START_X = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'START_X'
    START_Y = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'START_Y'
    EXIT_COL = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'EXIT_COL'
    EXIT_ROW = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'EXIT_ROW'
    SAFE_X_MAX = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SAFE_X_MAX'
    SAFE_Y_MIN = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SAFE_Y_MIN'
    SHARD_COUNT = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SHARD_COUNT'
    ENEMY_SPAWN_STEP = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'ENEMY_SPAWN_STEP'
    ENEMY_SPAWN_BASE = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'ENEMY_SPAWN_BASE'
    MAX_ENEMIES = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'MAX_ENEMIES'
    TOTAL_SECTORS = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'TOTAL_SECTORS'
}
$constants.PLAY_MAX_X = $constants.MAP_W - 2
$constants.PLAY_MAX_Y = $constants.MAP_H - 2

$seeds = @(0x1234, 0xACE1, 0xBEEF, 0x0F0F)
$retryLimit = 2048
$warningLines = New-Object 'System.Collections.Generic.List[string]'
$summaryLines = New-Object 'System.Collections.Generic.List[string]'
$reportLines = New-Object 'System.Collections.Generic.List[string]'

$reportLines.Add('CyberStorm Balance Harness')
$reportLines.Add(("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')))
$reportLines.Add(("Sector source: {0}" -f $SectorSourcePath))
$reportLines.Add(("Seeds: {0}" -f (($seeds | ForEach-Object { ('0x{0:X4}' -f $_) }) -join ', ')))
$reportLines.Add(("Retry limit: {0}" -f $retryLimit))
$reportLines.Add('')

$sectorData = Import-StructuredDataFile -SourcePath $SectorSourcePath -Label 'sector source'
$sectors = @($sectorData['Sectors'] | Sort-Object { [int]$_.Id })
if ($sectors.Count -ne $constants.TOTAL_SECTORS) {
    throw ("Balance harness expected {0} sectors, but the source defined {1}." -f $constants.TOTAL_SECTORS, $sectors.Count)
}

$enemyCountBySector = New-Object 'System.Collections.Generic.List[int]'
$surgeCountBySector = New-Object 'System.Collections.Generic.List[int]'
$scenarioCount = 0
$staticMapCount = 0

$summaryLines.Add(("Seeds: {0}" -f (($seeds | ForEach-Object { ('0x{0:X4}' -f $_) }) -join ', ')))
$summaryLines.Add(("Scenarios: {0} deterministic spawn sweeps" -f ($sectors | ForEach-Object { @($_.Maps).Count * $seeds.Count } | Measure-Object -Sum).Sum))

for ($sectorIndex = 0; $sectorIndex -lt $sectors.Count; $sectorIndex++) {
    $sector = $sectors[$sectorIndex]
    $sectorId = [int]$sector['Id']
    $title = [string]$sector['Title']
    $rules = $sector['Rules']
    $maps = @($sector['Maps'])
    $enemyCount = ($sectorId * $constants.ENEMY_SPAWN_STEP) + $constants.ENEMY_SPAWN_BASE + [int]$rules['EnemyBonus']
    $surgeCount = [int]$rules['SurgeCount']
    $terminalCount = [int]$rules['TerminalCount']
    $flankerThreshold = [int]$rules['FlankerThreshold']
    $wardenThreshold = [int]$rules['WardenThreshold']

    if ($enemyCount -gt $constants.MAX_ENEMIES) {
        throw ("Sector {0} enemy count ({1}) exceeds MAX_ENEMIES ({2})." -f $sectorId, $enemyCount, $constants.MAX_ENEMIES)
    }

    if ($wardenThreshold -gt 0 -and $flankerThreshold -lt $wardenThreshold) {
        throw ("Sector {0} has WardenThreshold {1}, but FlankerThreshold {2}. Warden threshold must not exceed flanker threshold." -f $sectorId, $wardenThreshold, $flankerThreshold)
    }

    $enemyCountBySector.Add($enemyCount)
    $surgeCountBySector.Add($surgeCount)

    $pathMin = [int]::MaxValue
    $pathMax = 0
    $branchMin = [int]::MaxValue
    $branchMax = 0
    $slackMin = [int]::MaxValue
    $terminalSafeMin = [int]::MaxValue
    $enemySafeMin = [int]::MaxValue
    $worstAttempts = 0
    $nearestEnemyMin = [int]::MaxValue
    $nearestEnemyMax = 0
    $rusherTotal = 0
    $flankerTotal = 0
    $wardenTotal = 0

    $reportLines.Add(("Sector {0}: {1}" -f $sectorId, $title))
    $reportLines.Add(("  Rules: surge={0} terminal={1} enemy={2} flank<{3} warden<{4}" -f $surgeCount, $terminalCount, $enemyCount, $flankerThreshold, $wardenThreshold))

    foreach ($map in $maps) {
        $rows = @($map['Rows'] | ForEach-Object { [string]$_ })
        $mapName = [string]$map['Name']
        $static = Get-MapMetrics `
            -Rows $rows `
            -MapW $constants.MAP_W `
            -MapH $constants.MAP_H `
            -StartX $constants.START_X `
            -StartY $constants.START_Y `
            -ExitX $constants.EXIT_COL `
            -ExitY $constants.EXIT_ROW `
            -SafeXMax $constants.SAFE_X_MAX `
            -SafeYMin $constants.SAFE_Y_MIN

        $requiredPlacements = $constants.SHARD_COUNT + $surgeCount + $terminalCount + $enemyCount
        $slack = $static.FloorPool - $requiredPlacements
        if ($slack -lt 0) {
            throw ("Map '{0}' in sector {1} does not have enough floor capacity for dynamic placements. Slack: {2}" -f $mapName, $sectorId, $slack)
        }

        if ($static.TerminalSafePool -lt $terminalCount) {
            throw ("Map '{0}' in sector {1} does not have enough terminal-safe tiles for {2} terminals." -f $mapName, $sectorId, $terminalCount)
        }

        if ($static.EnemySafePool -lt $enemyCount) {
            throw ("Map '{0}' in sector {1} does not have enough enemy-safe tiles for {2} enemies." -f $mapName, $sectorId, $enemyCount)
        }

        if ($slack -lt 12) {
            $warningLines.Add(("Sector {0} map '{1}' has low placement slack ({2} tiles)." -f $sectorId, $mapName, $slack))
        }

        $pathMin = [Math]::Min($pathMin, $static.PathLength)
        $pathMax = [Math]::Max($pathMax, $static.PathLength)
        $branchMin = [Math]::Min($branchMin, $static.BranchTiles)
        $branchMax = [Math]::Max($branchMax, $static.BranchTiles)
        $slackMin = [Math]::Min($slackMin, $slack)
        $terminalSafeMin = [Math]::Min($terminalSafeMin, $static.TerminalSafePool)
        $enemySafeMin = [Math]::Min($enemySafeMin, $static.EnemySafePool)
        $staticMapCount += 1

        $reportLines.Add(("  Map {0}: path={1} open={2} branches={3} slack={4} terminal-safe={5} enemy-safe={6}" -f $mapName, $static.PathLength, $static.OpenTiles, $static.BranchTiles, $slack, $static.TerminalSafePool, $static.EnemySafePool))

        foreach ($seed in $seeds) {
            $scenario = Invoke-ScenarioSweep `
                -Rows $rows `
                -Seed $seed `
                -StartX $constants.START_X `
                -StartY $constants.START_Y `
                -ExitX $constants.EXIT_COL `
                -ExitY $constants.EXIT_ROW `
                -PlayMaxX $constants.PLAY_MAX_X `
                -PlayMaxY $constants.PLAY_MAX_Y `
                -SafeXMax $constants.SAFE_X_MAX `
                -SafeYMin $constants.SAFE_Y_MIN `
                -ShardCount $constants.SHARD_COUNT `
                -SurgeCount $surgeCount `
                -TerminalCount $terminalCount `
                -EnemyCount $enemyCount `
                -FlankerThreshold $flankerThreshold `
                -WardenThreshold $wardenThreshold `
                -RetryLimit $retryLimit
            $scenarioCount += 1
            $worstAttempts = [Math]::Max($worstAttempts, $scenario.WorstAttempts)
            $nearestEnemyMin = [Math]::Min($nearestEnemyMin, $scenario.NearestEnemyDistance)
            $nearestEnemyMax = [Math]::Max($nearestEnemyMax, $scenario.NearestEnemyDistance)
            $rusherTotal += $scenario.RusherCount
            $flankerTotal += $scenario.FlankerCount
            $wardenTotal += $scenario.WardenCount
        }
    }

    if ($worstAttempts -gt 64) {
        $warningLines.Add(("Sector {0} deterministic placement needed up to {1} retries in one placement call." -f $sectorId, $worstAttempts))
    }

    if ($nearestEnemyMin -le 3) {
        $warningLines.Add(("Sector {0} deterministic sweep spawned an enemy within distance {1} of the start." -f $sectorId, $nearestEnemyMin))
    }

    $enemyTotal = $rusherTotal + $flankerTotal + $wardenTotal
    $summaryLines.Add(("S{0} {1}: path {2}-{3}, branches {4}-{5}, slack>={6}, terminal-safe>={7}, enemy-safe>={8}, nearest enemy {9}-{10}, mix R {11} F {12} W {13}" -f `
            $sectorId,
            $title,
            $pathMin,
            $pathMax,
            $branchMin,
            $branchMax,
            $slackMin,
            $terminalSafeMin,
            $enemySafeMin,
            $nearestEnemyMin,
            $nearestEnemyMax,
            (Format-Percent -Count $rusherTotal -Total $enemyTotal),
            (Format-Percent -Count $flankerTotal -Total $enemyTotal),
            (Format-Percent -Count $wardenTotal -Total $enemyTotal)))

    $reportLines.Add(("  Sweep: scenarios={0} worst-retries={1} nearest-enemy={2}-{3} mix=R {4} / F {5} / W {6}" -f `
            ($maps.Count * $seeds.Count),
            $worstAttempts,
            $nearestEnemyMin,
            $nearestEnemyMax,
            (Format-Percent -Count $rusherTotal -Total $enemyTotal),
            (Format-Percent -Count $flankerTotal -Total $enemyTotal),
            (Format-Percent -Count $wardenTotal -Total $enemyTotal)))
    $reportLines.Add('')
}

for ($i = 1; $i -lt $enemyCountBySector.Count; $i++) {
    if ($enemyCountBySector[$i] -lt $enemyCountBySector[$i - 1]) {
        $warningLines.Add(("Enemy count dropped from sector {0} to sector {1} ({2} -> {3})." -f $i, ($i + 1), $enemyCountBySector[$i - 1], $enemyCountBySector[$i]))
    }

    if ($surgeCountBySector[$i] -lt $surgeCountBySector[$i - 1]) {
        $warningLines.Add(("Surge density dropped from sector {0} to sector {1} ({2} -> {3})." -f $i, ($i + 1), $surgeCountBySector[$i - 1], $surgeCountBySector[$i]))
    }
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

return [pscustomobject]@{
    SourcePath = $SectorSourcePath
    ReportPath = $ReportPath
    SeedSummary = (($seeds | ForEach-Object { ('0x{0:X4}' -f $_) }) -join ', ')
    StaticMapCount = $staticMapCount
    ScenarioCount = $scenarioCount
    SummaryLines = $summaryLines.ToArray()
    WarningLines = $warningLines.ToArray()
}
