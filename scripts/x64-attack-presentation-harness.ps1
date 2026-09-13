param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$ReportPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = Join-Path $RepoRoot 'build\cyberstorm-x64-attack-presentation-report.txt'
}

$specPath = Join-Path $RepoRoot 'assets\x64_attack_presentation.psd1'
$combatPath = Join-Path $RepoRoot 'assets\x64_combat.psd1'
$runtimePath = Join-Path $RepoRoot 'src\bootx64.asm'
foreach ($required in @($specPath, $combatPath, $runtimePath)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Missing hostile attack presentation input: $required"
    }
}

$presentation = (Import-PowerShellDataFile -Path $specPath).Presentation
$combat = (Import-PowerShellDataFile -Path $combatPath).Combat
$runtime = Get-Content -Raw -LiteralPath $runtimePath
$checks = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param([string]$Name, [bool]$Passed, [string]$Detail)
    $script:checks.Add([pscustomobject]@{ Name = $Name; Passed = $Passed; Detail = $Detail })
}

function Has-All {
    param([string[]]$Needles)
    foreach ($needle in $Needles) {
        if (-not $runtime.Contains($needle)) { return $false }
    }
    return $true
}

Add-Check 'Presentation profile targets Neon Spine integrity' ($presentation.Id -eq 'neon-spine-hostile-fire' -and $presentation.RequiresCombatProfile -eq $combat.Id) "presentation=$($presentation.Id) combat=$($combat.Id)"
Add-Check 'Runtime exposes projection and line primitives' (Has-All @('ProjectLevelPoint3D PROC', 'DrawGopLine PROC')) 'world points can be projected into screen-space telegraphs'
Add-Check 'Runtime exposes all three threat actors' (Has-All @('EnemyAlive dd', 'SentryLeftAlive dd', 'SentryRightAlive dd')) 'warden and both sentry alive symbols found'

$targetX = [int]$presentation.LockTargetX
$targetY = [int]$presentation.LockTargetY
Add-Check 'Lock target sits inside the 640x480 gameplay viewport' ($targetX -ge 160 -and $targetX -le 480 -and $targetY -ge 120 -and $targetY -le 360) "target=$targetX,$targetY"

$impactInset = [int]$presentation.ImpactInset
$impactCross = [int]$presentation.ImpactCrossHalfSize
Add-Check 'Impact frame geometry is bounded' ($impactInset -ge 8 -and $impactInset -le 48 -and $impactCross -ge 12 -and $impactCross -le 64) "inset=$impactInset crossHalf=$impactCross"

$pulseMask = [int]$presentation.PulseMask
$isPowerOfTwo = $pulseMask -gt 0 -and (($pulseMask -band ($pulseMask - 1)) -eq 0)
Add-Check 'Lock pulse mask is a single animation bit' $isPowerOfTwo "mask=$pulseMask"

$sources = @($presentation.Sources)
$ids = @($sources | ForEach-Object { $_.Id })
Add-Check 'Exactly three authored hostile sources are present' ($sources.Count -eq 3 -and (($ids -join ',') -eq 'warden,sentry-left,sentry-right')) "sources=$($ids -join ',')"

$warden = $sources | Where-Object { $_.Id -eq 'warden' } | Select-Object -First 1
$left = $sources | Where-Object { $_.Id -eq 'sentry-left' } | Select-Object -First 1
$right = $sources | Where-Object { $_.Id -eq 'sentry-right' } | Select-Object -First 1
$wardenInside = ([int]$warden.X -ge -54 -and [int]$warden.X -le 54 -and [int]$warden.Y -ge -22 -and [int]$warden.Y -le 88 -and [int]$warden.Z -ge 174 -and [int]$warden.Z -le 252)
$leftInside = ([int]$left.X -ge -126 -and [int]$left.X -le -74 -and [int]$left.Y -ge -18 -and [int]$left.Y -le 56 -and [int]$left.Z -ge 282 -and [int]$left.Z -le 356)
$rightInside = ([int]$right.X -ge 74 -and [int]$right.X -le 126 -and [int]$right.Y -ge -18 -and [int]$right.Y -le 56 -and [int]$right.Z -ge 282 -and [int]$right.Z -le 356)
Add-Check 'Authored lock sources sit inside rendered actor volumes' ($wardenInside -and $leftInside -and $rightInside) "warden=$wardenInside left=$leftInside right=$rightInside"

Add-Check 'Base actor geometry anchors still match the authored source bounds' (Has-All @(
    'DRAW_LEVEL_BOX_FILLED -54, -22, 174, 54, 88, 252',
    'DRAW_LEVEL_BOX_FILLED -126, -18, 294, -74, 56, 356',
    'DRAW_LEVEL_BOX_FILLED 74, -18, 294, 126, 56, 356'
)) 'presentation points remain tied to current Warden/sentry meshes'

# Deterministic presentation-state model. The visual layer is intentionally
# downstream of the combat state: it cannot create damage or advance exposure.
function Resolve-PresentationMode {
    param([int]$Objective, [int]$Exposure, [int]$DamageFlash, [int]$WarningTicks)
    if ($Objective -ge 3) { return 'none' }
    if ($DamageFlash -gt 0) { return 'impact' }
    if ($Exposure -ge $WarningTicks) { return 'lock' }
    return 'none'
}

$warning = [int]$combat.ExposureWarningTicks
Add-Check 'No telegraph appears before warning threshold' ((Resolve-PresentationMode -Objective 0 -Exposure ($warning - 1) -DamageFlash 0 -WarningTicks $warning) -eq 'none') "warning=$warning"
Add-Check 'Warning threshold resolves to lock presentation' ((Resolve-PresentationMode -Objective 0 -Exposure $warning -DamageFlash 0 -WarningTicks $warning) -eq 'lock') "warning=$warning"
Add-Check 'Damage feedback overrides lock presentation' ((Resolve-PresentationMode -Objective 0 -Exposure $warning -DamageFlash 1 -WarningTicks $warning) -eq 'impact') 'impact is visually stronger than acquisition'
Add-Check 'Mission-complete state suppresses combat presentation' ((Resolve-PresentationMode -Objective 3 -Exposure $warning -DamageFlash 1 -WarningTicks $warning) -eq 'none') 'rank/completion view remains clean'

$runtimeHasPresentation = Has-All @(
    'DrawHostileAttackPresentation PROC',
    'call DrawHostileAttackPresentation',
    'hostile_attack_draw_impact:',
    'ATTACK_WARDEN_X',
    'ATTACK_LEFT_X',
    'ATTACK_RIGHT_X'
)
Add-Check 'Runtime hostile attack presentation patch landed' $runtimeHasPresentation "presentation-runtime=$runtimeHasPresentation"

$failed = @($checks | Where-Object { -not $_.Passed })
$pending = @($checks | Where-Object { $_.Name -eq 'Runtime hostile attack presentation patch landed' -and -not $_.Passed })
$hardFailed = @($failed | Where-Object { $_.Name -ne 'Runtime hostile attack presentation patch landed' })

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('CyberStorm x64 Hostile Attack Presentation Harness')
$lines.Add(('Generated: {0:u}' -f (Get-Date).ToUniversalTime()))
$lines.Add('')
foreach ($check in $checks) {
    $status = if ($check.Passed) { 'PASS' } elseif ($check.Name -eq 'Runtime hostile attack presentation patch landed') { 'PENDING' } else { 'FAIL' }
    $lines.Add(('[{0}] {1} - {2}' -f $status, $check.Name, $check.Detail))
}
$lines.Add('')
$lines.Add(('Summary: {0} passed, {1} hard failed, {2} pending runtime integration' -f ($checks.Count - $failed.Count), $hardFailed.Count, $pending.Count))

$reportDir = Split-Path -Parent $ReportPath
if ($reportDir -and -not (Test-Path -LiteralPath $reportDir)) {
    New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
}
$lines | Set-Content -Encoding UTF8 -LiteralPath $ReportPath
$lines | ForEach-Object { Write-Host $_ }

if ($hardFailed.Count -gt 0) { exit 1 }
