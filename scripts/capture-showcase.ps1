param(
    [ValidateSet('masm', 'uasm', 'jwasm')]
    [string]$Assembler = 'masm',
    [string]$AssemblerPath,
    [string]$MasmPath,
    [switch]$ExperimentalMusic,
    [switch]$SfxOnly,
    [string]$VmName = 'CyberStorm',
    [string]$DemoSourcePath = (Join-Path (Join-Path $PSScriptRoot '..') 'assets\demos.psd1'),
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
    $seconds = 6 + [int][Math]::Ceiling(($captureTicks + 6) / 18.2)
    return [Math]::Max(10, $seconds)
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

    Invoke-ChildBuild -ExtraArguments @(
        '-DebugBuild',
        '-DebugDemoBoot',
        '-DebugDemoIndex',
        $DemoIndex.ToString()
    )

    Stop-VmIfRunning -Name $VmName
    Ensure-VmRegistered -Name $VmName
    Stop-VmIfRunning -Name $VmName
    Start-HeadlessVm -Name $VmName
    Start-Sleep -Seconds (Get-CaptureWaitSeconds -Demo $Demo)
    Invoke-VBoxManage -Arguments @('controlvm', $VmName, 'screenshotpng', $rawShotPath) | Out-Null
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

    Invoke-ChildBuild -ExtraArguments @(
        '-DebugBuild',
        '-DebugRender3D',
        '-DebugStartInGame',
        '-DebugStartSector',
        '1',
        '-DebugSeed',
        '4660'
    )

    Stop-VmIfRunning -Name $VmName
    Ensure-VmRegistered -Name $VmName
    Stop-VmIfRunning -Name $VmName
    Start-HeadlessVm -Name $VmName
    Start-Sleep -Seconds $waitSeconds
    Invoke-VBoxManage -Arguments @('controlvm', $VmName, 'screenshotpng', $rawShotPath) | Out-Null
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
Assert-PathExists -Path $vbox -Label 'VBoxManage'
New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null

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
    $vmSmokeReport = Join-Path $buildDir 'cyberstorm-vm-smoke-report.txt'
    $vmSmokeResult = & $VmSmokeScriptPath -ReportPath $vmSmokeReport
    $titleSource = Join-Path $buildDir 'vm-smoke\cyberstorm-vm-smoke-title.png'
    $titleTarget = Join-Path $artifactDir 'showcase-title.png'
    Copy-Item -LiteralPath $titleSource -Destination $titleTarget -Force
    $artifactPaths.Add($titleTarget)
    $summaryLines.Add(("title: {0}" -f $titleTarget))
    $reportLines.Add('Role: title')
    $reportLines.Add(("  Source: release VM smoke title frame"))
    $reportLines.Add(("  Screenshot: {0}" -f $titleTarget))
    $reportLines.Add('')

    $beautyCapture = Invoke-DirectGameplayCapture -ArtifactDir $artifactDir -Role 'beauty' -WaitSeconds 5
    $artifactPaths.Add($beautyCapture.ScreenshotPath)
    $artifactPaths.Add($beautyCapture.RawScreenshotPath)
    $artifactPaths.Add($beautyCapture.LogPath)
    $summaryLines.Add(("beauty: {0}" -f $beautyCapture.ScreenshotPath))
    $reportLines.Add('Role: beauty')
    $reportLines.Add(("  Source: {0}" -f $beautyCapture.Source))
    $reportLines.Add(("  Wait: {0}s" -f $beautyCapture.WaitSeconds))
    $reportLines.Add(("  Screenshot: {0}" -f $beautyCapture.ScreenshotPath))
    $reportLines.Add(("  Raw screenshot: {0}" -f $beautyCapture.RawScreenshotPath))
    $reportLines.Add(("  VBox log: {0}" -f $beautyCapture.LogPath))
    $reportLines.Add('')

    $actionCapture = Invoke-DirectGameplayCapture -ArtifactDir $artifactDir -Role 'action' -WaitSeconds 12
    $artifactPaths.Add($actionCapture.ScreenshotPath)
    $artifactPaths.Add($actionCapture.RawScreenshotPath)
    $artifactPaths.Add($actionCapture.LogPath)
    $summaryLines.Add(("action: {0}" -f $actionCapture.ScreenshotPath))
    $reportLines.Add('Role: action')
    $reportLines.Add(("  Source: {0}" -f $actionCapture.Source))
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
