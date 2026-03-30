param(
    [string]$VmName = 'CyberStorm',
    [ValidateSet('gui', 'headless')]
    [string]$Frontend = 'gui'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$vbox = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
if (-not (Test-Path $vbox)) {
    throw 'VBoxManage.exe was not found in the default Oracle VirtualBox install path.'
}

function Invoke-VBoxManage {
    param([string[]]$Arguments)

    & $vbox @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw ("VBoxManage failed: {0}" -f ($Arguments -join ' '))
    }
}

if ($Frontend -eq 'headless') {
    Write-Warning 'Headless is fine for smoke tests, but use the default GUI frontend if you want to hear CyberStorm live.'
}

Invoke-VBoxManage -Arguments @('startvm', $VmName, '--type', $Frontend)
