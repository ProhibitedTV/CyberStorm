param(
    [ValidateSet('masm', 'uasm', 'jwasm')]
    [string]$Assembler = 'masm',
    [string]$AssemblerPath,
    [string]$MasmPath,
    [switch]$ExperimentalMusic,
    [switch]$SfxOnly,
    [string]$VmName = 'CyberStorm',
    [string]$ConstantsSourcePath = (Join-Path (Join-Path $PSScriptRoot '..') 'src\game\constants.inc'),
    [string]$BuildScriptPath = (Join-Path $PSScriptRoot 'build.ps1'),
    [string]$DeployScriptPath = (Join-Path $PSScriptRoot 'deploy-vm.ps1'),
    [string]$ReportPath = (Join-Path (Join-Path $PSScriptRoot '..') 'build\cyberstorm-frontend-verify-report.txt')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($ExperimentalMusic.IsPresent -and $SfxOnly.IsPresent) {
    throw 'Use either -ExperimentalMusic (legacy alias) or -SfxOnly, not both.'
}

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $root 'build'
$artifactDir = Join-Path $buildDir 'frontend-verify'
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
        [int]$Attempt = 0
    )

    $captured = New-Object 'System.Collections.Generic.List[string]'
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $vbox @Arguments 2>&1 | ForEach-Object {
            $captured.Add($_.ToString())
        }
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($LASTEXITCODE -eq 0) {
        return $captured.ToArray()
    }

    $message = $captured -join [Environment]::NewLine
    if ($Attempt -lt 3 -and $message -match 'CO_E_SERVER_EXEC_FAILURE|Failed to create the VirtualBox object') {
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            & taskkill /F /IM VBoxSVC.exe /IM VBoxHeadless.exe /IM VirtualBoxVM.exe *>$null
        } finally {
            $ErrorActionPreference = $previousErrorActionPreference
        }
        Start-Sleep -Seconds (2 + ($Attempt * 3))
        return Invoke-VBoxManage -Arguments $Arguments -Attempt ($Attempt + 1)
    }

    throw ("VBoxManage failed: {0}`n{1}" -f ($Arguments -join ' '), $message)
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
        Invoke-VBoxManage -Arguments @('showvminfo', $Name) | Out-Null
    } catch {
        if ($_.Exception.Message -match 'Could not find a registered machine named|VBOX_E_OBJECT_NOT_FOUND') {
            Invoke-DeployVm -Name $Name
            return
        }

        throw
    }
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
    if ($closestDistance -gt 20000) {
        return 'UNKNOWN'
    }

    if ($passDistance -le $failDistance) {
        return 'PASS'
    }

    return 'FAIL'
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

function Format-FrontendTerminalState {
    param(
        [int]$Signature,
        [hashtable]$StateNames
    )

    $stateValue = $Signature -band 0x00FF
    $parts = New-Object 'System.Collections.Generic.List[string]'
    if ($StateNames.ContainsKey($stateValue)) {
        $parts.Add($StateNames[$stateValue])
    } else {
        $parts.Add(("STATE_{0}" -f $stateValue))
    }

    if (($Signature -band 0x0100) -ne 0) {
        $parts.Add('demo')
    }

    if (($Signature -band 0x0200) -ne 0) {
        $parts.Add('guard')
    }

    return ($parts -join ' + ')
}

function Invoke-FrontendVerifyRun {
    param(
        [pscustomobject]$Scenario,
        [switch]$CorruptExpectation,
        [string]$ArtifactDir,
        [hashtable]$Geometry,
        [hashtable]$StateNames
    )

    $suffix = if ($CorruptExpectation.IsPresent) { 'fail' } else { 'pass' }
    $shotPath = Join-Path $ArtifactDir ("frontend-verify-{0}-{1}.png" -f $Scenario.Id, $suffix)
    $logPath = Join-Path $ArtifactDir ("frontend-verify-{0}-{1}.log" -f $Scenario.Id, $suffix)

    $buildArgs = @(
        '-DebugBuild',
        '-DebugFrontendVerify',
        '-DebugFrontendScenario',
        $Scenario.Number.ToString()
    )
    if ($CorruptExpectation.IsPresent) {
        $buildArgs += @('-DebugFrontendCorruptScenario', $Scenario.Number.ToString())
    }

    Stop-VmIfRunning -Name $VmName
    Ensure-VmRegistered -Name $VmName
    Stop-VmIfRunning -Name $VmName
    Invoke-ChildBuild -ExtraArguments $buildArgs
    Start-HeadlessVm -Name $VmName
    $maxCaptureAttempts = 4
    $retryDelaySeconds = 2
    $totalWaitSeconds = $Scenario.WaitSeconds
    $status = 'UNKNOWN'
    $expectedSignature = 0
    $observedSignature = 0

    Start-Sleep -Seconds $Scenario.WaitSeconds
    for ($attempt = 1; $attempt -le $maxCaptureAttempts; $attempt++) {
        if ($attempt -gt 1) {
            Start-Sleep -Seconds $retryDelaySeconds
            $totalWaitSeconds += $retryDelaySeconds
        }

        Invoke-VBoxManage -Arguments @('controlvm', $VmName, 'screenshotpng', $shotPath) | Out-Null
        if (-not (Test-Path -LiteralPath $vboxLogPath)) {
            throw ("VBox log was not found after frontend verification boot: {0}" -f $vboxLogPath)
        }

        Copy-Item -LiteralPath $vboxLogPath -Destination $logPath -Force
        $bitmap = [System.Drawing.Bitmap]::FromFile($shotPath)
        try {
            $status = Get-StatusFromBitmap `
                -Bitmap $bitmap `
                -MarkerX $Geometry.MarkerX `
                -MarkerY $Geometry.MarkerY `
                -MarkerW $Geometry.MarkerW `
                -MarkerH $Geometry.MarkerH `
                -ScreenW $Geometry.ScreenW `
                -ScreenH $Geometry.ScreenH
            if ($status -ne 'UNKNOWN') {
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
            }
        } finally {
            $bitmap.Dispose()
        }

        if ($status -ne 'UNKNOWN') {
            break
        }
    }

    if ($status -eq 'UNKNOWN') {
        throw ("Frontend verify scenario '{0}' never reached a verify scene after {1}s." -f $Scenario.Name, $totalWaitSeconds)
    }

    $expectedStatus = if ($CorruptExpectation.IsPresent) { 'FAIL' } else { 'PASS' }
    if ($status -ne $expectedStatus) {
        throw ("Frontend verify scenario '{0}' reported {1}, expected {2}." -f $Scenario.Name, $status, $expectedStatus)
    }

    return [pscustomobject]@{
        Name = $Scenario.Name
        Id = $Scenario.Id
        Status = $status
        ExpectedStatus = $expectedStatus
        ExpectedSignature = (Format-Hex16 $expectedSignature)
        ObservedSignature = (Format-Hex16 $observedSignature)
        ExpectedTerminal = (Format-FrontendTerminalState -Signature $expectedSignature -StateNames $StateNames)
        ObservedTerminal = (Format-FrontendTerminalState -Signature $observedSignature -StateNames $StateNames)
        ScreenshotPath = $shotPath
        LogPath = $logPath
        WaitSeconds = $totalWaitSeconds
    }
}

Assert-PathExists -Path $BuildScriptPath -Label 'build script'
Assert-PathExists -Path $DeployScriptPath -Label 'deploy script'
Assert-PathExists -Path $vbox -Label 'VBoxManage'
Assert-PathExists -Path $ConstantsSourcePath -Label 'constants source'
New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null

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
    BitSize = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'VERIFY_BIT_SIZE'
    BitPitch = Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'VERIFY_BIT_PITCH'
}

$stateNames = @{
    (Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'STATE_TITLE') = 'TITLE'
    (Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'STATE_PLAYING') = 'PLAYING'
    (Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'STATE_WIN') = 'WIN'
    (Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'STATE_LOSE') = 'LOSE'
    (Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'STATE_SPLASH') = 'SPLASH'
    (Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'STATE_VERIFY_PASS') = 'VERIFY_PASS'
    (Get-AsmEquValue -SourcePath $ConstantsSourcePath -Name 'STATE_VERIFY_FAIL') = 'VERIFY_FAIL'
}

$scenarios = @(
    [pscustomobject]@{ Number = 1; Id = 'splash-to-title'; Name = 'SPLASH TO TITLE'; WaitSeconds = 8 }
    [pscustomobject]@{ Number = 2; Id = 'title-to-start'; Name = 'TITLE TO START'; WaitSeconds = 8 }
    [pscustomobject]@{ Number = 3; Id = 'title-to-attract'; Name = 'TITLE TO ATTRACT'; WaitSeconds = 10 }
)

$summaryLines = New-Object 'System.Collections.Generic.List[string]'
$artifactPaths = New-Object 'System.Collections.Generic.List[string]'
$lines = New-Object 'System.Collections.Generic.List[string]'
$lines.Add('CyberStorm Frontend Verification Report')
$lines.Add(("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')))
$lines.Add(("Constants source: {0}" -f $ConstantsSourcePath))
$lines.Add('')

$restoreRelease = $true

try {
    Ensure-VmRegistered -Name $VmName
    foreach ($scenario in $scenarios) {
        $result = Invoke-FrontendVerifyRun -Scenario $scenario -ArtifactDir $artifactDir -Geometry $geometry -StateNames $stateNames
        $artifactPaths.Add($result.ScreenshotPath)
        $artifactPaths.Add($result.LogPath)
        $summaryLines.Add(("{0}: {1} ({2} -> {3})" -f $result.Name, $result.Status, $result.ExpectedTerminal, $result.ObservedTerminal))
        $lines.Add(("Scenario: {0}" -f $result.Name))
        $lines.Add(("  Id: {0}" -f $result.Id))
        $lines.Add(("  Status: {0}" -f $result.Status))
        $lines.Add(("  Wait: {0}s" -f $result.WaitSeconds))
        $lines.Add(("  Expected terminal: {0}" -f $result.ExpectedTerminal))
        $lines.Add(("  Observed terminal: {0}" -f $result.ObservedTerminal))
        $lines.Add(("  Expected signature: {0}" -f $result.ExpectedSignature))
        $lines.Add(("  Observed signature: {0}" -f $result.ObservedSignature))
        $lines.Add(("  Screenshot: {0}" -f $result.ScreenshotPath))
        $lines.Add(("  VBox log: {0}" -f $result.LogPath))
        $lines.Add('')
    }

    $forcedFail = Invoke-FrontendVerifyRun -Scenario $scenarios[0] -CorruptExpectation -ArtifactDir $artifactDir -Geometry $geometry -StateNames $stateNames
    $artifactPaths.Add($forcedFail.ScreenshotPath)
    $artifactPaths.Add($forcedFail.LogPath)
    $summaryLines.Add(("Forced mismatch: {0} ({1} -> {2})" -f $forcedFail.Status, $forcedFail.ExpectedTerminal, $forcedFail.ObservedTerminal))
    $lines.Add('Forced mismatch scenario')
    $lines.Add(("  Scenario: {0}" -f $forcedFail.Name))
    $lines.Add(("  Status: {0}" -f $forcedFail.Status))
    $lines.Add(("  Expected terminal: {0}" -f $forcedFail.ExpectedTerminal))
    $lines.Add(("  Observed terminal: {0}" -f $forcedFail.ObservedTerminal))
    $lines.Add(("  Expected signature: {0}" -f $forcedFail.ExpectedSignature))
    $lines.Add(("  Observed signature: {0}" -f $forcedFail.ObservedSignature))
    $lines.Add(("  Screenshot: {0}" -f $forcedFail.ScreenshotPath))
    $lines.Add(("  VBox log: {0}" -f $forcedFail.LogPath))
} finally {
    Stop-VmIfRunning -Name $VmName
    if ($restoreRelease) {
        Invoke-ChildBuild -ExtraArguments @()
    }
}

Set-Content -LiteralPath $ReportPath -Encoding ascii -Value $lines

[pscustomobject]@{
    ReportPath = $ReportPath
    SummaryLines = $summaryLines.ToArray()
    ArtifactPaths = $artifactPaths.ToArray()
}
