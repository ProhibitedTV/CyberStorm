param(
    [ValidateSet('masm', 'uasm', 'jwasm')]
    [string]$Assembler = 'masm',
    [string]$AssemblerPath,
    [string]$MasmPath,
    [switch]$ExperimentalMusic,
    [switch]$SfxOnly,
    [string]$VmName = 'CyberStorm',
    [string]$DemoSourcePath = (Join-Path (Join-Path $PSScriptRoot '..') 'assets\demos.psd1'),
    [string]$SectorSourcePath = (Join-Path (Join-Path $PSScriptRoot '..') 'assets\sectors.psd1'),
    [string]$ConstantsSourcePath = (Join-Path (Join-Path $PSScriptRoot '..') 'src\game\constants.inc'),
    [string]$BuildScriptPath = (Join-Path $PSScriptRoot 'build.ps1'),
    [string]$DeployScriptPath = (Join-Path $PSScriptRoot 'deploy-vm.ps1'),
    [string]$VmSmokeScriptPath = (Join-Path $PSScriptRoot 'vm-smoke.ps1'),
    [string]$RuntimeVerifyScriptPath = (Join-Path $PSScriptRoot 'runtime-verify.ps1'),
    [string]$ReportPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm-showcase-report.txt')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($ExperimentalMusic.IsPresent -and $SfxOnly.IsPresent) {
    throw 'Use either -ExperimentalMusic (legacy alias) or -SfxOnly, not both.'
}

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $root 'build'
$artifactDir = Join-Path $buildDir 'showcase'
$vbox = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
$vboxLogPath = Join-Path $root ("deploy\virtualbox\{0}\Logs\VBox.log" -f $VmName)

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

function Invoke-VBoxManage {
    param(
        [string[]]$Arguments,
        [int]$Attempt = 0,
        [int]$TimeoutSeconds = 30
    )

    $capturedLines = New-Object 'System.Collections.Generic.List[string]'
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $vbox @Arguments 2>&1 | ForEach-Object {
            $capturedLines.Add($_.ToString())
        }
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($LASTEXITCODE -eq 0) {
        return $capturedLines.ToArray()
    }

    $message = $capturedLines -join [Environment]::NewLine
    if ($Attempt -lt 3 -and $message -match 'CO_E_SERVER_EXEC_FAILURE|Failed to create the VirtualBox object') {
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            & taskkill /F /IM VBoxSVC.exe /IM VBoxHeadless.exe /IM VirtualBoxVM.exe *>$null
        } finally {
            $ErrorActionPreference = $previousErrorActionPreference
        }
        Start-Sleep -Seconds (2 + ($Attempt * 3))
        return Invoke-VBoxManage -Arguments $Arguments -Attempt ($Attempt + 1) -TimeoutSeconds $TimeoutSeconds
    }

    throw ("VBoxManage failed: {0}`n{1}" -f ($Arguments -join ' '), $message)
}

function Get-VmState {
    param([string]$Name)

    $infoLines = Invoke-VBoxManage -Arguments @('showvminfo', $Name, '--machinereadable') -TimeoutSeconds 20
    $stateLine = $infoLines | Where-Object { $_ -match '^VMState=' } | Select-Object -First 1
    if ($stateLine -and $stateLine -match '^VMState="?([^"]+)"?$') {
        return $Matches[1]
    }

    return 'unknown'
}

function Ensure-VmReadyForCapture {
    param([string]$Name)

    for ($attempt = 0; $attempt -lt 10; $attempt++) {
        $state = Get-VmState -Name $Name
        if ($state -eq 'running') {
            return
        }

        if ($state -eq 'paused') {
            Invoke-VBoxManage -Arguments @('controlvm', $Name, 'resume') -TimeoutSeconds 20 | Out-Null
        }

        Start-Sleep -Milliseconds 500
    }

    throw ("VM '{0}' never reached a capture-ready running state." -f $Name)
}

function Invoke-VmScreenshot {
    param(
        [string]$Name,
        [string]$OutputPath
    )

    if (Test-Path -LiteralPath $OutputPath) {
        Remove-Item -LiteralPath $OutputPath -Force
    }

    for ($attempt = 0; $attempt -lt 5; $attempt++) {
        try {
            Invoke-VBoxManage -Arguments @('controlvm', $Name, 'screenshotpng', $OutputPath) -TimeoutSeconds 45 | Out-Null
        } catch {
            if ($attempt -ge 4) {
                throw
            }
        }

        for ($fileAttempt = 0; $fileAttempt -lt 20; $fileAttempt++) {
            if (Test-Path -LiteralPath $OutputPath) {
                return
            }

            Start-Sleep -Milliseconds 250
        }

        Start-Sleep -Seconds 1
    }

    throw ("VM screenshot was not created: {0}" -f $OutputPath)
}

function Stop-VmIfRunning {
    param([string]$Name)

    try {
        Invoke-VBoxManage -Arguments @('controlvm', $Name, 'poweroff') | Out-Null
        Start-Sleep -Seconds 2
    } catch {
        return
    }
}

function Start-HeadlessVm {
    param([string]$Name)

    Invoke-VBoxManage -Arguments @('startvm', $Name, '--type', 'headless') | Out-Null
    Start-Sleep -Seconds 2
}

function Invoke-DeployVm {
    param([string]$Name)

    & powershell -ExecutionPolicy Bypass -File $DeployScriptPath -VmName $Name | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw ("Deploy script failed for VM '{0}'." -f $Name)
    }
}

function Ensure-VmRegistered {
    param([string]$Name)

    try {
        Invoke-VBoxManage -Arguments @('showvminfo', $Name, '--machinereadable') -TimeoutSeconds 20 | Out-Null
    } catch {
        if ($_.Exception.Message -match 'Could not find a registered machine named|VBOX_E_OBJECT_NOT_FOUND') {
            Invoke-DeployVm -Name $Name
            return
        }

        throw
    }
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
        throw ("Demo '{0}' step is missing a tick count." -f $DemoName)
    }

    $parts = ([string]$Step).Trim() -split '\s+'
    if ($parts.Count -ne 2) {
        throw ("Demo '{0}' step '{1}' must be 'ACTION COUNT'." -f $DemoName, $Step)
    }

    return [int]$parts[1]
}

function Get-CaptureWaitSeconds {
    param($Demo)

    $captureTicks = [int]$Demo.CaptureTicks
    $seconds = 6 + [int][Math]::Ceiling(($captureTicks + 6) / 30.0)
    return [Math]::Max(10, $seconds)
}

function Get-ShowcaseCapturePlan {
    param(
        [string]$SectorSourcePath,
        [string]$DemoSourcePath
    )

    $sectorData = Import-StructuredDataFile -SourcePath $SectorSourcePath -Label 'sector source'
    if (-not $sectorData.ContainsKey('AdventureRealm')) {
        throw ("Sector source does not define AdventureRealm capture data: {0}" -f $SectorSourcePath)
    }

    $realm = $sectorData['AdventureRealm']
    if (-not ($realm -is [System.Collections.IDictionary])) {
        throw ("AdventureRealm in {0} must be a hashtable." -f $SectorSourcePath)
    }

    if (-not $realm.ContainsKey('CaptureAnchors')) {
        throw ("AdventureRealm in {0} is missing CaptureAnchors." -f $SectorSourcePath)
    }

    $captureAnchors = $realm['CaptureAnchors']
    if (-not ($captureAnchors -is [System.Collections.IDictionary])) {
        throw ("AdventureRealm.CaptureAnchors in {0} must be a hashtable." -f $SectorSourcePath)
    }

    $demoData = Import-StructuredDataFile -SourcePath $DemoSourcePath -Label 'demo source'
    if (-not $demoData.ContainsKey('Demos')) {
        throw ("Demo source must define a 'Demos' array: {0}" -f $DemoSourcePath)
    }

    $demos = @($demoData['Demos'])
    $demoIndexById = @{}
    for ($demoIndex = 0; $demoIndex -lt $demos.Count; $demoIndex++) {
        $demo = $demos[$demoIndex]
        $demoId = ([string]$demo['Id']).Trim()
        if (-not [string]::IsNullOrWhiteSpace($demoId) -and -not $demoIndexById.ContainsKey($demoId)) {
            $demoIndexById[$demoId] = $demoIndex
        }
    }

    $plan = New-Object 'System.Collections.Generic.List[object]'
    foreach ($anchorKey in @('Beauty', 'Action')) {
        if (-not $captureAnchors.ContainsKey($anchorKey)) {
            throw ("AdventureRealm.CaptureAnchors in {0} is missing '{1}'." -f $SectorSourcePath, $anchorKey)
        }

        $demoId = ([string]$captureAnchors[$anchorKey]).Trim()
        if (-not $demoIndexById.ContainsKey($demoId)) {
            throw ("AdventureRealm.CaptureAnchors.{0} references missing demo '{1}'." -f $anchorKey, $demoId)
        }

        $demoIndex = [int]$demoIndexById[$demoId]
        $demo = $demos[$demoIndex]
        $expectedRole = $anchorKey.ToLowerInvariant()
        $captureRole = ([string]$demo['CaptureRole']).Trim().ToLowerInvariant()
        if ($captureRole -ne $expectedRole) {
            throw ("Demo '{0}' must use CaptureRole '{1}' to satisfy AdventureRealm.CaptureAnchors.{2}." -f $demoId, $expectedRole, $anchorKey)
        }
        if (($demo.ContainsKey('RuntimeVerify')) -and [bool]$demo['RuntimeVerify']) {
            throw ("Demo '{0}' cannot be used as a public capture anchor because RuntimeVerify is enabled." -f $demoId)
        }

        $plan.Add([pscustomobject]@{
            Anchor = $anchorKey
            Role = $expectedRole
            DemoId = $demoId
            DemoIndex = $demoIndex
            Demo = $demo
        })
    }

    return $plan.ToArray()
}

function Convert-VgaChannel {
    param([int]$Value)
    return [int][Math]::Round(($Value * 255.0) / 63.0)
}

function New-RgbRef {
    param([int]$R, [int]$G, [int]$B)

    return [pscustomobject]@{
        R = (Convert-VgaChannel $R)
        G = (Convert-VgaChannel $G)
        B = (Convert-VgaChannel $B)
    }
}

function Get-ColorDistance {
    param(
        $Color,
        $Reference
    )

    $dr = [double]($Color.R - $Reference.R)
    $dg = [double]($Color.G - $Reference.G)
    $db = [double]($Color.B - $Reference.B)
    return (($dr * $dr) + ($dg * $dg) + ($db * $db))
}

function Get-BitmapPixel {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [int]$X,
        [int]$Y
    )

    return $Bitmap.GetPixel($X, $Y)
}

function Get-LogicalBitmapPixel {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [double]$LogicalX,
        [double]$LogicalY,
        [int]$ScreenW,
        [int]$ScreenH
    )

    $scaledX = [int][Math]::Floor(((($LogicalX + 0.5) * $Bitmap.Width) / $ScreenW))
    $scaledY = [int][Math]::Floor(((($LogicalY + 0.5) * $Bitmap.Height) / $ScreenH))
    $scaledX = [Math]::Max(0, [Math]::Min($Bitmap.Width - 1, $scaledX))
    $scaledY = [Math]::Max(0, [Math]::Min($Bitmap.Height - 1, $scaledY))
    return (Get-BitmapPixel -Bitmap $Bitmap -X $scaledX -Y $scaledY)
}

function Get-StatusFromBitmap {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [int]$MarkerX,
        [int]$MarkerY,
        [int]$MarkerW,
        [int]$MarkerH,
        [int]$ScreenW,
        [int]$ScreenH
    )

    $passRef = New-RgbRef 12 52 58
    $failRef = New-RgbRef 63 18 18
    $passDistance = [double]::PositiveInfinity
    $failDistance = [double]::PositiveInfinity
    for ($logicalY = $MarkerY; $logicalY -lt ($MarkerY + $MarkerH); $logicalY++) {
        for ($logicalX = $MarkerX; $logicalX -lt ($MarkerX + $MarkerW); $logicalX++) {
            $sample = Get-LogicalBitmapPixel -Bitmap $Bitmap -LogicalX $logicalX -LogicalY $logicalY -ScreenW $ScreenW -ScreenH $ScreenH
            $passDistance = [Math]::Min($passDistance, (Get-ColorDistance -Color $sample -Reference $passRef))
            $failDistance = [Math]::Min($failDistance, (Get-ColorDistance -Color $sample -Reference $failRef))
        }
    }

    $closestDistance = [Math]::Min($passDistance, $failDistance)
    if ($closestDistance -gt 20000) {
        return 'UNKNOWN'
    }

    if ($passDistance -le $failDistance) {
        return 'PASS'
    }

    return 'FAIL'
}

function Test-ShowcaseBitmap {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [hashtable]$Geometry
    )

    $luminance = 0.0
    $samples = 0
    for ($logicalY = 24; $logicalY -le 168; $logicalY += 24) {
        for ($logicalX = 24; $logicalX -le 296; $logicalX += 24) {
            $sample = Get-LogicalBitmapPixel -Bitmap $Bitmap -LogicalX $logicalX -LogicalY $logicalY -ScreenW $Geometry.ScreenW -ScreenH $Geometry.ScreenH
            $luminance += ((0.2126 * $sample.R) + (0.7152 * $sample.G) + (0.0722 * $sample.B))
            $samples++
        }
    }

    $averageLuminance = if ($samples -gt 0) { ($luminance / $samples) } else { 0.0 }
    $status = Get-StatusFromBitmap -Bitmap $Bitmap -MarkerX $Geometry.MarkerX -MarkerY $Geometry.MarkerY -MarkerW $Geometry.MarkerW -MarkerH $Geometry.MarkerH -ScreenW $Geometry.ScreenW -ScreenH $Geometry.ScreenH
    return [pscustomobject]@{
        AverageLuminance = [double]$averageLuminance
        VerifyStatus = [string]$status
    }
}

function Assert-ShowcaseBitmap {
    param(
        [string]$ImagePath,
        [string]$Role,
        [hashtable]$Geometry
    )

    $bitmap = [System.Drawing.Bitmap]::FromFile($ImagePath)
    try {
        $analysis = Test-ShowcaseBitmap -Bitmap $bitmap -Geometry $Geometry
    } finally {
        $bitmap.Dispose()
    }

    if ($analysis.AverageLuminance -lt 18.0) {
        throw ("Showcase role '{0}' captured a black or near-black frame: {1}" -f $Role, $ImagePath)
    }

    if ($analysis.VerifyStatus -ne 'UNKNOWN') {
        throw ("Showcase role '{0}' captured a verify/debug scene ({1}): {2}" -f $Role, $analysis.VerifyStatus, $ImagePath)
    }
}

function Invoke-ChildBuild {
    param([string[]]$ExtraArguments)

    $args = New-Object 'System.Collections.Generic.List[string]'
    $args.Add('-ExecutionPolicy')
    $args.Add('Bypass')
    $args.Add('-File')
    $args.Add($BuildScriptPath)
    $args.Add('-AutomationChild')
    $args.Add('-Assembler')
    $args.Add($Assembler)
    if (-not [string]::IsNullOrWhiteSpace($AssemblerPath)) {
        $args.Add('-AssemblerPath')
        $args.Add($AssemblerPath)
    }

    if (-not [string]::IsNullOrWhiteSpace($MasmPath)) {
        $args.Add('-MasmPath')
        $args.Add($MasmPath)
    }

    if ($SfxOnly.IsPresent) {
        $args.Add('-SfxOnly')
    }

    foreach ($argument in @($ExtraArguments)) {
        $args.Add($argument)
    }

    & powershell @args | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw ("Child build failed: powershell {0}" -f ($args -join ' '))
    }
}

function Invoke-DemoCapture {
    param(
        $Demo,
        [int]$DemoIndex,
        [string]$ArtifactDir
    )

    $role = [string]$Demo.CaptureRole
    $reportRole = if ($role -eq 'gameplay') { 'gameplay-demo' } else { $role }
    $demoId = [string]$Demo.Id
    $shotPath = Join-Path $ArtifactDir ("showcase-{0}.png" -f $reportRole)
    $rawShotPath = Join-Path $ArtifactDir ("showcase-{0}-{1}.png" -f $reportRole, $demoId)
    $logPath = Join-Path $ArtifactDir ("showcase-{0}-{1}.log" -f $reportRole, $demoId)

    Stop-VmIfRunning -Name $VmName
    Ensure-VmRegistered -Name $VmName
    Stop-VmIfRunning -Name $VmName
    Invoke-ChildBuild -ExtraArguments @(
        '-DebugBuild',
        '-DebugDemoBoot',
        '-DebugDemoIndex',
        $DemoIndex.ToString()
    )
    Start-HeadlessVm -Name $VmName
    Start-Sleep -Seconds (Get-CaptureWaitSeconds -Demo $Demo)
    Invoke-VmScreenshot -Name $VmName -OutputPath $rawShotPath
    Copy-Item -LiteralPath $rawShotPath -Destination $shotPath -Force
    if (-not (Test-Path -LiteralPath $vboxLogPath)) {
        throw ("VBox log was not found after showcase demo boot: {0}" -f $vboxLogPath)
    }

    Copy-Item -LiteralPath $vboxLogPath -Destination $logPath -Force
    return [pscustomobject]@{
        Role = $reportRole
        SourceRole = $role
        Name = [string]$Demo.Name
        ScreenshotPath = $shotPath
        RawScreenshotPath = $rawShotPath
        LogPath = $logPath
        WaitSeconds = (Get-CaptureWaitSeconds -Demo $Demo)
    }
}

function Invoke-DirectGameplayCapture {
    param(
        [string]$ArtifactDir,
        [string]$Role,
        [int]$WaitSeconds
    )

    $shotPath = Join-Path $ArtifactDir ("showcase-{0}.png" -f $Role)
    $rawShotPath = Join-Path $ArtifactDir ("showcase-{0}-direct.png" -f $Role)
    $logPath = Join-Path $ArtifactDir ("showcase-{0}-direct.log" -f $Role)

    Stop-VmIfRunning -Name $VmName
    Ensure-VmRegistered -Name $VmName
    Stop-VmIfRunning -Name $VmName
    Invoke-ChildBuild -ExtraArguments @(
        '-DebugBuild',
        '-DebugRenderMachine',
        '-DebugRenderStage',
        '5',
        '-DebugStartInGame',
        '-DebugStartSector',
        '1',
        '-DebugSeed',
        '4660'
    )
    Start-HeadlessVm -Name $VmName
    Start-Sleep -Seconds $waitSeconds
    Invoke-VmScreenshot -Name $VmName -OutputPath $rawShotPath
    Copy-Item -LiteralPath $rawShotPath -Destination $shotPath -Force
    if (-not (Test-Path -LiteralPath $vboxLogPath)) {
        throw ("VBox log was not found after direct gameplay boot: {0}" -f $vboxLogPath)
    }

    Copy-Item -LiteralPath $vboxLogPath -Destination $logPath -Force
    return [pscustomobject]@{
        Role = $Role
        Name = $Role.ToUpperInvariant()
        ScreenshotPath = $shotPath
        RawScreenshotPath = $rawShotPath
        LogPath = $logPath
        WaitSeconds = $waitSeconds
        Source = 'direct-to-game release adventure boot'
    }
}

Assert-PathExists -Path $BuildScriptPath -Label 'build script'
Assert-PathExists -Path $DeployScriptPath -Label 'deploy script'
Assert-PathExists -Path $VmSmokeScriptPath -Label 'vm smoke script'
Assert-PathExists -Path $RuntimeVerifyScriptPath -Label 'runtime verify script'
Assert-PathExists -Path $DemoSourcePath -Label 'demo source'
Assert-PathExists -Path $SectorSourcePath -Label 'sector source'
Assert-PathExists -Path $ConstantsSourcePath -Label 'constants source'
Assert-PathExists -Path $vbox -Label 'VBoxManage'
New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null

$geometry = @{
    ScreenW = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SCREEN_W'
    ScreenH = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SCREEN_H'
    MarkerX = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'VERIFY_MARKER_X'
    MarkerY = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'VERIFY_MARKER_Y'
    MarkerW = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'VERIFY_MARKER_W'
    MarkerH = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'VERIFY_MARKER_H'
}
$showcaseCapturePlan = @(Get-ShowcaseCapturePlan -SectorSourcePath $SectorSourcePath -DemoSourcePath $DemoSourcePath)
$showcaseCapturePlanByRole = @{}
foreach ($capturePlanEntry in $showcaseCapturePlan) {
    $showcaseCapturePlanByRole[[string]$capturePlanEntry.Role] = $capturePlanEntry
}

$artifactPaths = New-Object 'System.Collections.Generic.List[string]'
$summaryLines = New-Object 'System.Collections.Generic.List[string]'
$reportLines = New-Object 'System.Collections.Generic.List[string]'
$reportLines.Add('CyberStorm Showcase Capture Report')
$reportLines.Add(("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')))
$reportLines.Add(("Demo source: {0}" -f $DemoSourcePath))
$reportLines.Add('')

$restoreRelease = $true

try {
    Ensure-VmRegistered -Name $VmName
    $runtimeVerifyReport = Join-Path $buildDir 'cyberstorm-runtime-verify-report.txt'
    $runtimeVerifyArgs = @(
        '-Assembler', $Assembler,
        '-RenderMode', '3DMachine',
        '-ReportPath', $runtimeVerifyReport
    )
    if (-not [string]::IsNullOrWhiteSpace($AssemblerPath)) {
        $runtimeVerifyArgs += @('-AssemblerPath', $AssemblerPath)
    }
    if (-not [string]::IsNullOrWhiteSpace($MasmPath)) {
        $runtimeVerifyArgs += @('-MasmPath', $MasmPath)
    }
    if ($SfxOnly.IsPresent) {
        $runtimeVerifyArgs += '-SfxOnly'
    }
    $runtimeVerifyResult = & $RuntimeVerifyScriptPath @runtimeVerifyArgs
    $artifactPaths.Add($runtimeVerifyResult.ReportPath)
    $reportLines.Add('Prerequisite: runtime verify')
    $reportLines.Add(("  Report: {0}" -f $runtimeVerifyResult.ReportPath))
    foreach ($summaryLine in @($runtimeVerifyResult.SummaryLines)) {
        $reportLines.Add(("  {0}" -f $summaryLine))
    }
    $reportLines.Add('')

    $vmSmokeReport = Join-Path $buildDir 'cyberstorm-vm-smoke-report.txt'
    $vmSmokeResult = & $VmSmokeScriptPath -ReportPath $vmSmokeReport
    $titleSource = Join-Path $buildDir 'vm-smoke\cyberstorm-vm-smoke-title.png'
    $titleTarget = Join-Path $artifactDir 'showcase-title.png'
    Copy-Item -LiteralPath $titleSource -Destination $titleTarget -Force
    Assert-ShowcaseBitmap -ImagePath $titleTarget -Role 'title' -Geometry $geometry
    $artifactPaths.Add($titleTarget)
    $summaryLines.Add(("title: {0}" -f $titleTarget))
    $reportLines.Add('Role: title')
    $reportLines.Add(("  Source: release VM smoke title frame"))
    $reportLines.Add(("  Screenshot: {0}" -f $titleTarget))
    $reportLines.Add('')

    $beautyPlan = $showcaseCapturePlanByRole['beauty']
    $beautyCapture = Invoke-DemoCapture -Demo $beautyPlan.Demo -DemoIndex $beautyPlan.DemoIndex -ArtifactDir $artifactDir
    Assert-ShowcaseBitmap -ImagePath $beautyCapture.ScreenshotPath -Role 'beauty' -Geometry $geometry
    $artifactPaths.Add($beautyCapture.ScreenshotPath)
    $artifactPaths.Add($beautyCapture.RawScreenshotPath)
    $artifactPaths.Add($beautyCapture.LogPath)
    $summaryLines.Add(("beauty: {0}" -f $beautyCapture.ScreenshotPath))
    $reportLines.Add('Role: beauty')
    $reportLines.Add(("  Source: AdventureRealm.CaptureAnchors.Beauty -> {0}" -f $beautyPlan.DemoId))
    $reportLines.Add(("  Demo: {0}" -f ([string]$beautyPlan.Demo.Name)))
    $reportLines.Add(("  Wait: {0}s" -f $beautyCapture.WaitSeconds))
    $reportLines.Add(("  Screenshot: {0}" -f $beautyCapture.ScreenshotPath))
    $reportLines.Add(("  Raw screenshot: {0}" -f $beautyCapture.RawScreenshotPath))
    $reportLines.Add(("  VBox log: {0}" -f $beautyCapture.LogPath))
    $reportLines.Add('')

    $actionPlan = $showcaseCapturePlanByRole['action']
    $actionCapture = Invoke-DemoCapture -Demo $actionPlan.Demo -DemoIndex $actionPlan.DemoIndex -ArtifactDir $artifactDir
    Assert-ShowcaseBitmap -ImagePath $actionCapture.ScreenshotPath -Role 'action' -Geometry $geometry
    $artifactPaths.Add($actionCapture.ScreenshotPath)
    $artifactPaths.Add($actionCapture.RawScreenshotPath)
    $artifactPaths.Add($actionCapture.LogPath)
    $summaryLines.Add(("action: {0}" -f $actionCapture.ScreenshotPath))
    $reportLines.Add('Role: action')
    $reportLines.Add(("  Source: AdventureRealm.CaptureAnchors.Action -> {0}" -f $actionPlan.DemoId))
    $reportLines.Add(("  Demo: {0}" -f ([string]$actionPlan.Demo.Name)))
    $reportLines.Add(("  Wait: {0}s" -f $actionCapture.WaitSeconds))
    $reportLines.Add(("  Screenshot: {0}" -f $actionCapture.ScreenshotPath))
    $reportLines.Add(("  Raw screenshot: {0}" -f $actionCapture.RawScreenshotPath))
    $reportLines.Add(("  VBox log: {0}" -f $actionCapture.LogPath))
    $reportLines.Add('')

    $reportLines.Add('README roles')
    $reportLines.Add(("  readme-shot-1.png <- {0}" -f $titleTarget))
    $reportLines.Add(("  readme-shot-2.png <- {0}" -f $beautyCapture.ScreenshotPath))
    $reportLines.Add(("  readme-shot-3.png <- {0}" -f $actionCapture.ScreenshotPath))
} finally {
    Stop-VmIfRunning -Name $VmName
    if ($restoreRelease) {
        Invoke-ChildBuild -ExtraArguments @()
    }
}

Set-Content -LiteralPath $ReportPath -Encoding ascii -Value $reportLines

[pscustomobject]@{
    ReportPath = $ReportPath
    SummaryLines = $summaryLines.ToArray()
    ArtifactPaths = $artifactPaths.ToArray()
}
