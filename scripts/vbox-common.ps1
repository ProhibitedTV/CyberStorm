function Test-VBoxBootstrapFailureMessage {
    param(
        [AllowNull()]
        [string]$Message
    )

    if ([string]::IsNullOrWhiteSpace($Message)) {
        return $false
    }

    return ($Message -match 'CO_E_SERVER_EXEC_FAILURE|Failed to create the VirtualBox object|RPC server is unavailable|VBoxManage timed out')
}

function Test-VBoxEnvironmentFailureMessage {
    param(
        [AllowNull()]
        [string]$Message
    )

    if ([string]::IsNullOrWhiteSpace($Message)) {
        return $false
    }

    return ($Message -match 'CO_E_SERVER_EXEC_FAILURE|Failed to create the VirtualBox object|RPC server is unavailable|VBoxManage timed out|VBoxManage\.exe was not found|VM ''.+'' never reached a capture-ready running state|VM screenshot was not created|VBox log was not found after|Deploy script failed for VM|Could not find a registered machine named|VBOX_E_OBJECT_NOT_FOUND')
}

function Get-VBoxFailureKind {
    param(
        [AllowNull()]
        [string]$Message
    )

    if (Test-VBoxEnvironmentFailureMessage -Message $Message) {
        return 'ENVIRONMENT'
    }

    return 'CONTENT'
}

function Restart-VBoxBootstrapServices {
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & taskkill /F /IM VBoxSVC.exe /IM VBoxHeadless.exe /IM VirtualBoxVM.exe *>$null
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
}

function ConvertTo-VBoxArgumentString {
    param([string[]]$Arguments)

    $escapedArguments = foreach ($argument in @($Arguments)) {
        if ($null -eq $argument -or $argument.Length -eq 0) {
            '""'
            continue
        }

        if ($argument -notmatch '[\s"]') {
            $argument
            continue
        }

        $escaped = $argument -replace '(\\*)"', '$1$1\"'
        $escaped = $escaped -replace '(\\+)$', '$1$1'
        '"' + $escaped + '"'
    }

    return [string]::Join(' ', $escapedArguments)
}

function Invoke-VBoxManage {
    param(
        [string[]]$Arguments,
        [int]$Attempt = 0,
        [int]$TimeoutSeconds = 30
    )

    $capturedLines = New-Object 'System.Collections.Generic.List[string]'
    $process = $null
    $stdoutTask = $null
    $stderrTask = $null
    $timedOut = $false
    $exitCode = $null

    try {
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $vbox
        $startInfo.Arguments = ConvertTo-VBoxArgumentString -Arguments $Arguments
        $startInfo.UseShellExecute = $false
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        $startInfo.CreateNoWindow = $true

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $startInfo
        $null = $process.Start()
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()

        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $timedOut = $true
            try {
                $process.Kill()
            } catch {
            }
            $process.WaitForExit()
        }

        $stdoutText = $stdoutTask.GetAwaiter().GetResult()
        $stderrText = $stderrTask.GetAwaiter().GetResult()
        foreach ($line in @($stdoutText -split "\r?\n")) {
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                $capturedLines.Add($line)
            }
        }
        foreach ($line in @($stderrText -split "\r?\n")) {
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                $capturedLines.Add($line)
            }
        }
        $exitCode = $process.ExitCode
    } finally {
        if ($process) {
            $process.Dispose()
        }
    }

    if ($timedOut) {
        $capturedLines.Insert(0, ("VBoxManage timed out after {0}s: {1}" -f $TimeoutSeconds, ($Arguments -join ' ')))
    } elseif ($null -ne $exitCode -and $exitCode -eq 0) {
        return $capturedLines.ToArray()
    }

    $message = $capturedLines -join [Environment]::NewLine
    if ($Attempt -lt 3 -and (Test-VBoxBootstrapFailureMessage -Message $message)) {
        Restart-VBoxBootstrapServices
        Start-Sleep -Seconds (2 + ($Attempt * 3))
        return Invoke-VBoxManage -Arguments $Arguments -Attempt ($Attempt + 1) -TimeoutSeconds $TimeoutSeconds
    }

    throw ("VBoxManage failed: {0}`n{1}" -f ($Arguments -join ' '), $message)
}

function Invoke-VBoxPreflight {
    param(
        [string]$Context = 'vbox preflight'
    )

    try {
        Invoke-VBoxManage -Arguments @('list', 'vms') -TimeoutSeconds 20 | Out-Null
    } catch {
        throw ("VBox preflight failed ({0})`n{1}" -f $Context, $_.Exception.Message)
    }
}

function Get-VBoxMachineInfoLines {
    param(
        [string]$Name,
        [string]$Context = 'showvminfo'
    )

    try {
        return (Invoke-VBoxManage -Arguments @('showvminfo', $Name, '--machinereadable') -TimeoutSeconds 20)
    } catch {
        throw ("VBox substep failed ({0})`n{1}" -f $Context, $_.Exception.Message)
    }
}

function Get-VmState {
    param(
        [string]$Name,
        [string]$Context = 'vm state probe'
    )

    $infoLines = Get-VBoxMachineInfoLines -Name $Name -Context $Context
    $stateLine = $infoLines | Where-Object { $_ -match '^VMState=' } | Select-Object -First 1
    if ($stateLine -and $stateLine -match '^VMState="?([^"]+)"?$') {
        return $Matches[1]
    }

    return 'unknown'
}

function Ensure-VmReadyForCapture {
    param(
        [string]$Name,
        [string]$Context = 'capture-ready probe'
    )

    for ($attempt = 0; $attempt -lt 10; $attempt++) {
        $state = Get-VmState -Name $Name -Context ("{0} (attempt {1})" -f $Context, ($attempt + 1))
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
        [string]$OutputPath,
        [string]$Context = 'vm screenshot'
    )

    if (Test-Path -LiteralPath $OutputPath) {
        Remove-Item -LiteralPath $OutputPath -Force
    }

    for ($attempt = 0; $attempt -lt 5; $attempt++) {
        try {
            Ensure-VmReadyForCapture -Name $Name -Context ("{0} capture-ready probe" -f $Context)
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
    param(
        [string]$Name,
        [string]$Context = 'startvm'
    )

    try {
        Invoke-VBoxManage -Arguments @('startvm', $Name, '--type', 'headless') | Out-Null
    } catch {
        throw ("VBox substep failed ({0})`n{1}" -f $Context, $_.Exception.Message)
    }
    Start-Sleep -Seconds 2
}

function Invoke-DeployVm {
    param([string]$Name)

    & powershell -ExecutionPolicy Bypass -File $DeployScriptPath -VmName $Name | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw ("Deploy script failed for VM '{0}'." -f $Name)
    }
}

function Test-VmNeedsEnhancedRedeploy {
    param(
        [string]$Name,
        [string]$Context = 'redeploy probe'
    )

    $infoLines = Get-VBoxMachineInfoLines -Name $Name -Context $Context
    $infoText = $infoLines -join [Environment]::NewLine

    if ($infoText -match 'boot1="floppy"') {
        return $true
    }

    if ($infoText -match 'cyberstorm\.vfd') {
        return $true
    }

    if ($infoText -notmatch 'cyberstorm\.(img|vdi)') {
        return $true
    }

    return $false
}

function Ensure-VmRegistered {
    param(
        [string]$Name,
        [string]$Context = 'vm registration'
    )

    Invoke-VBoxPreflight -Context $Context

    try {
        Get-VBoxMachineInfoLines -Name $Name -Context ("{0} showvminfo" -f $Context) | Out-Null
    } catch {
        if ($_.Exception.Message -match 'Could not find a registered machine named|VBOX_E_OBJECT_NOT_FOUND') {
            Invoke-DeployVm -Name $Name
            return
        }

        throw
    }

    if (Test-VmNeedsEnhancedRedeploy -Name $Name -Context ("{0} redeploy probe" -f $Context)) {
        Invoke-DeployVm -Name $Name
    }
}
