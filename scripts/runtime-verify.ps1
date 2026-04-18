param(
    [ValidateSet('masm', 'uasm', 'jwasm')]
    [string]$Assembler = 'masm',
    [string]$AssemblerPath,
    [string]$MasmPath,
    [switch]$ExperimentalMusic,
    [switch]$SfxOnly,
    [ValidateSet('2D', '3DReference', '3DMachine')]
    [string]$RenderMode = '3DReference',
    [ValidateRange(0, 5)]
    [Nullable[int]]$RenderStage,
    [string]$DemoFilter,
    [string]$VmName = 'CyberStorm',
    [string]$DemoSourcePath = (Join-Path (Join-Path $PSScriptRoot '..') 'assets\demos.psd1'),
    [string]$ConstantsSourcePath = (Join-Path (Join-Path $PSScriptRoot '..') 'src\game\constants.inc'),
    [string]$BuildScriptPath = (Join-Path $PSScriptRoot 'build.ps1'),
    [string]$DeployScriptPath = (Join-Path $PSScriptRoot 'deploy-vm.ps1'),
    [string]$ReportPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm-runtime-verify-report.txt')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($ExperimentalMusic.IsPresent -and $SfxOnly.IsPresent) {
    throw 'Use either -ExperimentalMusic (legacy alias) or -SfxOnly, not both.'
}

if (($RenderMode -eq '2D') -and ($null -ne $RenderStage)) {
    throw '-RenderStage only applies to -RenderMode 3DReference or 3DMachine.'
}

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $root 'build'
$artifactDir = Join-Path $buildDir 'runtime-verify'
$vbox = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
$vboxLogPath = Join-Path $root ("deploy\virtualbox\{0}\Logs\VBox.log" -f $VmName)

. (Join-Path $PSScriptRoot 'vbox-common.ps1')

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

function Get-DemoTotalTicks {
    param($Demo)

    $ticks = 0
    foreach ($step in @($Demo.Steps)) {
        $ticks += Get-StepRepeatCount -Step $step -DemoName ([string]$Demo.Name)
    }

    return $ticks
}

function Get-WaitSecondsForDemo {
    param(
        $Demo,
        [switch]$RuntimeVerify
    )

    $ticks = Get-DemoTotalTicks -Demo $Demo
    $extraTicks = if ($RuntimeVerify.IsPresent) { 30 } else { 8 }
    $seconds = 6 + [int][Math]::Ceiling(($ticks + $extraTicks) / 30.0)
    return [Math]::Max(30, $seconds)
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
            $sample = Get-LogicalBitmapPixel `
                -Bitmap $Bitmap `
                -LogicalX $logicalX `
                -LogicalY $logicalY `
                -ScreenW $ScreenW `
                -ScreenH $ScreenH
            $passDistance = [Math]::Min($passDistance, (Get-ColorDistance -Color $sample -Reference $passRef))
            $failDistance = [Math]::Min($failDistance, (Get-ColorDistance -Color $sample -Reference $failRef))
        }
    }
    $closestDistance = [Math]::Min($passDistance, $failDistance)
    $status = 'UNKNOWN'
    if ($closestDistance -le 20000) {
        if ($passDistance -le $failDistance) {
            $status = 'PASS'
        } else {
            $status = 'FAIL'
        }
    }

    return [pscustomobject]@{
        Status = $status
        PassDistance = [int][Math]::Round($passDistance)
        FailDistance = [int][Math]::Round($failDistance)
        ClosestDistance = [int][Math]::Round($closestDistance)
    }
}

function Get-SignatureFromBitmap {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [int]$StartX,
        [int]$StartY,
        [int]$BitSize,
        [int]$BitPitch,
        [int]$ScreenW,
        [int]$ScreenH
    )

    $onRef = New-RgbRef 63 63 63
    $offRef = New-RgbRef 8 14 22
    $value = 0
    for ($bitIndex = 0; $bitIndex -lt 16; $bitIndex++) {
        $sample = Get-LogicalBitmapPixel `
            -Bitmap $Bitmap `
            -LogicalX ($StartX + ($bitIndex * $BitPitch) + ($BitSize / 2.0)) `
            -LogicalY ($StartY + ($BitSize / 2.0)) `
            -ScreenW $ScreenW `
            -ScreenH $ScreenH
        $isSet = (Get-ColorDistance -Color $sample -Reference $onRef) -lt (Get-ColorDistance -Color $sample -Reference $offRef)
        if ($isSet) {
            $value = $value -bor (0x8000 -shr $bitIndex)
        }
    }

    return $value
}

function Format-Hex16 {
    param([int]$Value)
    return ("0x{0:X4}" -f ($Value -band 0xFFFF))
}

function Get-RuntimeVerifyFailureReason {
    param([int]$Code)

    switch ($Code -band 0xFFFF) {
        0 { return 'NONE' }
        1 { return 'TIMEOUT' }
        2 { return 'EARLY END' }
        3 { return 'DIVERGED' }
        default { return ("UNKNOWN({0})" -f (Format-Hex16 $Code)) }
    }
}

function Get-RenderLabel {
    param(
        [string]$Mode,
        [Nullable[int]]$Stage
    )

    if ($Mode -eq '2D') {
        return '2d'
    }

    if ($Mode -eq '3DReference') {
        if ($null -ne $Stage) {
            return ("3dref-stage{0}" -f ([int]$Stage))
        }

        return '3dref'
    }

    if ($null -ne $Stage) {
        return ("3dmc-stage{0}" -f ([int]$Stage))
    }

    return '3dmc'
}

function Get-HostReplayBlock {
    param(
        [string]$ReportPath,
        [string]$DemoId
    )

    if (-not (Test-Path -LiteralPath $ReportPath)) {
        return @()
    }

    $lines = Get-Content -LiteralPath $ReportPath
    $currentBlock = New-Object 'System.Collections.Generic.List[string]'
    foreach ($line in $lines) {
        if ($line -match '^Demo \d+: ') {
            if (($currentBlock.Count -gt 0) -and ($currentBlock | Where-Object { $_ -eq ("  Id: {0}" -f $DemoId) })) {
                return $currentBlock.ToArray()
            }

            $currentBlock.Clear()
        }

        if ($currentBlock.Count -gt 0 -or $line -match '^Demo \d+: ') {
            $currentBlock.Add($line)
        }

        if (($line -eq '') -and ($currentBlock.Count -gt 0)) {
            if ($currentBlock | Where-Object { $_ -eq ("  Id: {0}" -f $DemoId) }) {
                return $currentBlock.ToArray()
            }

            $currentBlock.Clear()
        }
    }

    if (($currentBlock.Count -gt 0) -and ($currentBlock | Where-Object { $_ -eq ("  Id: {0}" -f $DemoId) })) {
        return $currentBlock.ToArray()
    }

    return @()
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

function Invoke-RuntimeVerifyRun {
    param(
        $Demo,
        [int]$DemoIndex,
        [switch]$CorruptExpectation,
        [string]$ArtifactDir,
        [hashtable]$Geometry,
        [string]$RenderMode,
        [Nullable[int]]$RenderStage,
        [string]$ReplayReportPath
    )

    $suffix = if ($CorruptExpectation.IsPresent) { 'fail' } else { 'pass' }
    $demoId = [string]$Demo.Id
    $renderLabel = Get-RenderLabel -Mode $RenderMode -Stage $RenderStage
    $shotPath = Join-Path $ArtifactDir ("runtime-verify-{0}-{1}-{2}.png" -f $renderLabel, $demoId, $suffix)
    $logPath = Join-Path $ArtifactDir ("runtime-verify-{0}-{1}-{2}.log" -f $renderLabel, $demoId, $suffix)

    $buildArgs = @(
        '-DebugBuild',
        '-DebugDemoBoot',
        '-DebugRuntimeVerify',
        '-DebugDemoIndex',
        $DemoIndex.ToString()
    )
    if ($RenderMode -eq '2D') {
        $buildArgs += '-DebugRender2D'
    } elseif ($RenderMode -eq '3DReference') {
        $buildArgs += '-DebugRenderReference'
    } else {
        $buildArgs += '-DebugRenderMachine'
        if ($null -ne $RenderStage) {
            $buildArgs += @('-DebugRenderStage', $RenderStage.ToString())
        }
    }
    if ($CorruptExpectation.IsPresent) {
        $buildArgs += @('-DebugVerifyCorruptDemoIndex', $DemoIndex.ToString())
    }

    Stop-VmIfRunning -Name $VmName
    Ensure-VmRegistered -Name $VmName
    Stop-VmIfRunning -Name $VmName
    Invoke-ChildBuild -ExtraArguments $buildArgs
    $hostReplayBlock = Get-HostReplayBlock -ReportPath $ReplayReportPath -DemoId $demoId
    $expectedStatus = if ($CorruptExpectation.IsPresent) { 'FAIL' } else { 'PASS' }
    $initialWaitSeconds = Get-WaitSecondsForDemo -Demo $Demo -RuntimeVerify
    $retryDelaySeconds = 6
    $maxCaptureAttempts = 4
    $totalWaitSeconds = $initialWaitSeconds
    $statusSample = $null
    $expectedSignature = 0
    $observedSignature = 0
    $failureReasonCode = 0
    $failureReason = 'NONE'
    $markerResolved = $false

    Start-HeadlessVm -Name $VmName
    Start-Sleep -Seconds $initialWaitSeconds
    for ($attempt = 1; $attempt -le $maxCaptureAttempts; $attempt++) {
        if ($attempt -gt 1) {
            Start-Sleep -Seconds $retryDelaySeconds
            $totalWaitSeconds += $retryDelaySeconds
        }

        Invoke-VmScreenshot -Name $VmName -OutputPath $shotPath
        if (-not (Test-Path -LiteralPath $vboxLogPath)) {
            throw ("VBox log was not found after runtime verification boot: {0}" -f $vboxLogPath)
        }

        Copy-Item -LiteralPath $vboxLogPath -Destination $logPath -Force
        $bitmap = [System.Drawing.Bitmap]::FromFile($shotPath)
        try {
            $statusSample = Get-StatusFromBitmap `
                -Bitmap $bitmap `
                -MarkerX $Geometry.MarkerX `
                -MarkerY $Geometry.MarkerY `
                -MarkerW $Geometry.MarkerW `
                -MarkerH $Geometry.MarkerH `
                -ScreenW $Geometry.ScreenW `
                -ScreenH $Geometry.ScreenH
            if ($statusSample.Status -ne 'UNKNOWN') {
                $expectedSignature = Get-SignatureFromBitmap `
                    -Bitmap $bitmap `
                    -StartX $Geometry.BitsX `
                    -StartY $Geometry.ExpectBitsY `
                    -BitSize $Geometry.BitSize `
                    -BitPitch $Geometry.BitPitch `
                    -ScreenW $Geometry.ScreenW `
                    -ScreenH $Geometry.ScreenH
                $observedSignature = Get-SignatureFromBitmap `
                    -Bitmap $bitmap `
                    -StartX $Geometry.BitsX `
                    -StartY $Geometry.ObsBitsY `
                    -BitSize $Geometry.BitSize `
                    -BitPitch $Geometry.BitPitch `
                    -ScreenW $Geometry.ScreenW `
                    -ScreenH $Geometry.ScreenH
                $failureReasonCode = Get-SignatureFromBitmap `
                    -Bitmap $bitmap `
                    -StartX $Geometry.BitsX `
                    -StartY $Geometry.ReasonBitsY `
                    -BitSize $Geometry.BitSize `
                    -BitPitch $Geometry.BitPitch `
                    -ScreenW $Geometry.ScreenW `
                    -ScreenH $Geometry.ScreenH
                $failureReason = Get-RuntimeVerifyFailureReason -Code $failureReasonCode
            }
        } finally {
            $bitmap.Dispose()
        }

        if ($statusSample.Status -ne 'UNKNOWN') {
            $markerResolved = $true
            break
        }
    }

    if ($null -eq $statusSample -or $statusSample.Status -eq 'UNKNOWN') {
        $statusSample = [pscustomobject]@{
            Status = 'FAIL'
            PassDistance = if ($null -eq $statusSample) { -1 } else { $statusSample.PassDistance }
            FailDistance = if ($null -eq $statusSample) { -1 } else { $statusSample.FailDistance }
            ClosestDistance = if ($null -eq $statusSample) { -1 } else { $statusSample.ClosestDistance }
        }
        $failureReasonCode = 1
        $failureReason = Get-RuntimeVerifyFailureReason -Code $failureReasonCode
    }

    $status = [string]$statusSample.Status

    return [pscustomobject]@{
        Name = [string]$Demo.Name
        Id = $demoId
        RenderMode = $RenderMode
        RenderStage = if ($null -ne $RenderStage) { [int]$RenderStage } else { $null }
        Status = $status
        ExpectedStatus = $expectedStatus
        StatusMatched = ($status -eq $expectedStatus)
        FailureReason = $failureReason
        FailureReasonCode = (Format-Hex16 $failureReasonCode)
        MarkerResolved = $markerResolved
        ClosestDistance = [int]$statusSample.ClosestDistance
        PassDistance = [int]$statusSample.PassDistance
        FailDistance = [int]$statusSample.FailDistance
        ExpectedSignature = (Format-Hex16 $expectedSignature)
        ObservedSignature = (Format-Hex16 $observedSignature)
        ScreenshotPath = $shotPath
        LogPath = $logPath
        WaitSeconds = $totalWaitSeconds
        HostReplayBlock = @($hostReplayBlock)
    }
}

Assert-PathExists -Path $BuildScriptPath -Label 'build script'
Assert-PathExists -Path $DeployScriptPath -Label 'deploy script'
Assert-PathExists -Path $vbox -Label 'VBoxManage'
Assert-PathExists -Path $DemoSourcePath -Label 'demo source'
Assert-PathExists -Path $ConstantsSourcePath -Label 'constants source'
New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null
$replayReportPath = Join-Path $buildDir 'cyberstorm-replay-report.txt'

$geometry = @{
    ScreenW = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SCREEN_W'
    ScreenH = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'SCREEN_H'
    MarkerX = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'VERIFY_MARKER_X'
    MarkerY = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'VERIFY_MARKER_Y'
    MarkerW = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'VERIFY_MARKER_W'
    MarkerH = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'VERIFY_MARKER_H'
    BitsX = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'VERIFY_BITS_X'
    ExpectBitsY = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'VERIFY_EXPECT_BITS_Y'
    ObsBitsY = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'VERIFY_OBS_BITS_Y'
    ReasonBitsY = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'VERIFY_REASON_BITS_Y'
    BitSize = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'VERIFY_BIT_SIZE'
    BitPitch = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'VERIFY_BIT_PITCH'
}

$demoSource = Import-StructuredDataFile -SourcePath $DemoSourcePath -Label 'demo source'
$demos = @($demoSource.Demos)
if ($demos.Count -eq 0) {
    throw ("Demo source must define at least one demo: {0}" -f $DemoSourcePath)
}

$runtimeDemos = New-Object 'System.Collections.Generic.List[object]'
for ($demoIndex = 0; $demoIndex -lt $demos.Count; $demoIndex++) {
    $demo = $demos[$demoIndex]
    $runtimeVerifyEnabled = if (($demo -is [System.Collections.IDictionary]) -and $demo.ContainsKey('RuntimeVerify')) { [bool]$demo['RuntimeVerify'] } else { $false }
    if ($runtimeVerifyEnabled) {
        $runtimeDemos.Add([pscustomobject]@{
            DemoIndex = $demoIndex
            Demo = $demo
        })
    }
}

if ($runtimeDemos.Count -eq 0) {
    throw ("Demo source must mark at least one demo with RuntimeVerify = `$true: {0}" -f $DemoSourcePath)
}

$runtimeDemos = @($runtimeDemos | Sort-Object @{ Expression = { [int]$_.Demo.StartSector } }, @{ Expression = { [int]$_.DemoIndex } })
if (-not [string]::IsNullOrWhiteSpace($DemoFilter)) {
    $runtimeDemos = @($runtimeDemos | Where-Object { [string]$_.Demo.Id -eq $DemoFilter })
    if ($runtimeDemos.Count -eq 0) {
        throw ("No runtime verify demo matched DemoFilter '{0}'." -f $DemoFilter)
    }
}

$summaryLines = New-Object 'System.Collections.Generic.List[string]'
$artifactPaths = New-Object 'System.Collections.Generic.List[string]'
$lines = New-Object 'System.Collections.Generic.List[string]'
$lines.Add('CyberStorm Runtime Verification Report')
$lines.Add(("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')))
$lines.Add(("Demo source: {0}" -f $DemoSourcePath))
$lines.Add(("Render mode: {0}" -f $RenderMode))
if ($null -ne $RenderStage) {
    $lines.Add(("Render stage: {0}" -f ([int]$RenderStage)))
}
if (-not [string]::IsNullOrWhiteSpace($DemoFilter)) {
    $lines.Add(("Demo filter: {0}" -f $DemoFilter))
}
$lines.Add('')

$runtimeResults = New-Object 'System.Collections.Generic.List[object]'
$status = 'PASS'
$failureKind = $null
$caughtException = $null
$restoreRelease = $true

try {
    try {
        Ensure-VmRegistered -Name $VmName
        foreach ($runtimeDemo in $runtimeDemos) {
            $result = Invoke-RuntimeVerifyRun -Demo $runtimeDemo.Demo -DemoIndex ([int]$runtimeDemo.DemoIndex) -ArtifactDir $artifactDir -Geometry $geometry -RenderMode $RenderMode -RenderStage $RenderStage -ReplayReportPath $replayReportPath
            $runtimeResults.Add($result)
            $artifactPaths.Add($result.ScreenshotPath)
            $artifactPaths.Add($result.LogPath)
            $summaryLines.Add(("{0}: {1} {2} [{3}] (expected {4}; reason {5}; wait {6}s; marker {7}/{8}/{9}; exp {10} / obs {11})" -f $result.Name, $result.Status, $result.Id, (Get-RenderLabel -Mode $result.RenderMode -Stage $result.RenderStage), $result.ExpectedStatus, $result.FailureReason, $result.WaitSeconds, $result.ClosestDistance, $result.PassDistance, $result.FailDistance, $result.ExpectedSignature, $result.ObservedSignature))
            $lines.Add(("Demo: {0}" -f $result.Name))
            $lines.Add(("  Id: {0}" -f $result.Id))
            $lines.Add(("  Render: {0}" -f (Get-RenderLabel -Mode $result.RenderMode -Stage $result.RenderStage)))
            $lines.Add(("  Status: {0}" -f $result.Status))
            $lines.Add(("  Expected status: {0}" -f $result.ExpectedStatus))
            $lines.Add(("  Status match: {0}" -f $(if ($result.StatusMatched) { 'YES' } else { 'NO' })))
            $lines.Add(("  Failure reason: {0}" -f $result.FailureReason))
            $lines.Add(("  Failure reason code: {0}" -f $result.FailureReasonCode))
            $lines.Add(("  Wait: {0}s" -f $result.WaitSeconds))
            $lines.Add(("  Marker resolved: {0}" -f $(if ($result.MarkerResolved) { 'YES' } else { 'NO' })))
            $lines.Add(("  Marker closest distance: {0}" -f $result.ClosestDistance))
            $lines.Add(("  Marker pass distance: {0}" -f $result.PassDistance))
            $lines.Add(("  Marker fail distance: {0}" -f $result.FailDistance))
            $lines.Add(("  Expected signature: {0}" -f $result.ExpectedSignature))
            $lines.Add(("  Observed signature: {0}" -f $result.ObservedSignature))
            $lines.Add(("  Screenshot: {0}" -f $result.ScreenshotPath))
            $lines.Add(("  VBox log: {0}" -f $result.LogPath))
            if ($result.HostReplayBlock.Count -gt 0) {
                $lines.Add('  Host diagnostics:')
                foreach ($hostLine in $result.HostReplayBlock) {
                    $lines.Add(("    {0}" -f $hostLine.TrimEnd()))
                }
            }
            $lines.Add('')
        }

        if ([string]::IsNullOrWhiteSpace($DemoFilter)) {
            $forcedFail = Invoke-RuntimeVerifyRun -Demo $runtimeDemos[0].Demo -DemoIndex ([int]$runtimeDemos[0].DemoIndex) -CorruptExpectation -ArtifactDir $artifactDir -Geometry $geometry -RenderMode $RenderMode -RenderStage $RenderStage -ReplayReportPath $replayReportPath
            $artifactPaths.Add($forcedFail.ScreenshotPath)
            $artifactPaths.Add($forcedFail.LogPath)
            $summaryLines.Add(("Forced mismatch: {0} [{1}] (expected {2}; reason {3}; wait {4}s; marker {5}/{6}/{7}; exp {8} / obs {9})" -f $forcedFail.Status, (Get-RenderLabel -Mode $forcedFail.RenderMode -Stage $forcedFail.RenderStage), $forcedFail.ExpectedStatus, $forcedFail.FailureReason, $forcedFail.WaitSeconds, $forcedFail.ClosestDistance, $forcedFail.PassDistance, $forcedFail.FailDistance, $forcedFail.ExpectedSignature, $forcedFail.ObservedSignature))
            $lines.Add('Forced mismatch demo')
            $lines.Add(("  Demo: {0}" -f $forcedFail.Name))
            $lines.Add(("  Render: {0}" -f (Get-RenderLabel -Mode $forcedFail.RenderMode -Stage $forcedFail.RenderStage)))
            $lines.Add(("  Status: {0}" -f $forcedFail.Status))
            $lines.Add(("  Expected status: {0}" -f $forcedFail.ExpectedStatus))
            $lines.Add(("  Status match: {0}" -f $(if ($forcedFail.StatusMatched) { 'YES' } else { 'NO' })))
            $lines.Add(("  Failure reason: {0}" -f $forcedFail.FailureReason))
            $lines.Add(("  Failure reason code: {0}" -f $forcedFail.FailureReasonCode))
            $lines.Add(("  Wait: {0}s" -f $forcedFail.WaitSeconds))
            $lines.Add(("  Marker resolved: {0}" -f $(if ($forcedFail.MarkerResolved) { 'YES' } else { 'NO' })))
            $lines.Add(("  Marker closest distance: {0}" -f $forcedFail.ClosestDistance))
            $lines.Add(("  Marker pass distance: {0}" -f $forcedFail.PassDistance))
            $lines.Add(("  Marker fail distance: {0}" -f $forcedFail.FailDistance))
            $lines.Add(("  Expected signature: {0}" -f $forcedFail.ExpectedSignature))
            $lines.Add(("  Observed signature: {0}" -f $forcedFail.ObservedSignature))
            $lines.Add(("  Screenshot: {0}" -f $forcedFail.ScreenshotPath))
            $lines.Add(("  VBox log: {0}" -f $forcedFail.LogPath))
        }
    } finally {
        Stop-VmIfRunning -Name $VmName
        if ($restoreRelease) {
            Invoke-ChildBuild -ExtraArguments @()
        }
    }

    $statusMismatches = @($runtimeResults | Where-Object { -not $_.StatusMatched })
    if ($statusMismatches.Count -eq 1) {
        $focusedRepro = ("powershell -ExecutionPolicy Bypass -File .\scripts\runtime-verify.ps1 -DemoFilter {0}" -f $statusMismatches[0].Id)
        $lines.Add('')
        $lines.Add('Focused repro')
        $lines.Add(("  {0}" -f $focusedRepro))
        $summaryLines.Add(("Focused repro: {0}" -f $focusedRepro))
    }

    if ($statusMismatches.Count -gt 0) {
        $summary = @($statusMismatches | ForEach-Object { "{0} expected {1} but observed {2} ({3})" -f $_.Id, $_.ExpectedStatus, $_.Status, $_.FailureReason })
        if ($statusMismatches.Count -eq 1) {
            $summary += ("Focused repro: powershell -ExecutionPolicy Bypass -File .\scripts\runtime-verify.ps1 -DemoFilter {0}" -f $statusMismatches[0].Id)
        }
        throw ("Runtime verify status mismatches detected.`n{0}" -f ($summary -join [Environment]::NewLine))
    }

    $summaryLines.Insert(0, 'Status: PASS')
} catch {
    $status = 'FAIL'
    $caughtException = $_
    $failureKind = Get-VBoxFailureKind -Message $_.Exception.Message
    $summaryLines.Insert(0, ("Error: {0}" -f $_.Exception.Message))
    $summaryLines.Insert(0, ("Failure class: {0}" -f $failureKind))
    $summaryLines.Insert(0, 'Status: FAIL')
} finally {
    $statusLines = New-Object 'System.Collections.Generic.List[string]'
    $statusLines.Add(("Status: {0}" -f $status))
    if ($status -ne 'PASS') {
        $statusLines.Add(("Failure class: {0}" -f $failureKind))
        $statusLines.Add(("Error: {0}" -f $caughtException.Exception.Message))
    }
    $statusLines.Add('')
    for ($statusIndex = $statusLines.Count - 1; $statusIndex -ge 0; $statusIndex--) {
        $lines.Insert(3, $statusLines[$statusIndex])
    }

    Set-Content -LiteralPath $ReportPath -Encoding ascii -Value $lines
}

if ($null -ne $caughtException) {
    throw $caughtException
}

[pscustomobject]@{
    ReportPath = $ReportPath
    SummaryLines = $summaryLines.ToArray()
    ArtifactPaths = $artifactPaths.ToArray()
}
