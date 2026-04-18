function Test-VBoxBootstrapFailureMessage {
    param(
        [AllowNull()]
        [string]$Message
    )

    if ([string]::IsNullOrWhiteSpace($Message)) {
        return $false
    }

    return ($Message -match 'CO_E_SERVER_EXEC_FAILURE|Failed to create the VirtualBox object|RPC server is unavailable')
}

function Test-VBoxEnvironmentFailureMessage {
    param(
        [AllowNull()]
        [string]$Message
    )

    if ([string]::IsNullOrWhiteSpace($Message)) {
        return $false
    }

    return ($Message -match 'CO_E_SERVER_EXEC_FAILURE|Failed to create the VirtualBox object|RPC server is unavailable|VBoxManage\.exe was not found|VM ''.+'' never reached a capture-ready running state|VM screenshot was not created|VBox log was not found after|Deploy script failed for VM|Could not find a registered machine named|VBOX_E_OBJECT_NOT_FOUND')
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
    if ($Attempt -lt 3 -and (Test-VBoxBootstrapFailureMessage -Message $message)) {
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
            Ensure-VmReadyForCapture -Name $Name
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
