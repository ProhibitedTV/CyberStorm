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

& $vbox startvm $VmName --type $Frontend
