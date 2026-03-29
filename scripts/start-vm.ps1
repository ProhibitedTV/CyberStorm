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

if ($Frontend -eq 'headless') {
    Write-Warning 'Headless is fine for smoke tests, but use the default GUI frontend if you want to hear CyberStorm live.'
}

& $vbox startvm $VmName --type $Frontend
