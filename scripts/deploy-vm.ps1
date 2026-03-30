param(
    [string]$VmName = 'CyberStorm',
    [ValidateSet('default', 'null', 'dsound', 'was')]
    [string]$AudioDriver = 'default'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$vbox = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
$base = Join-Path $root 'deploy\virtualbox'
$floppy = Join-Path $root 'build\cyberstorm.vfd'

if (-not (Test-Path $vbox)) {
    throw 'VBoxManage.exe was not found in the default Oracle VirtualBox install path.'
}

if (-not (Test-Path $floppy)) {
    throw "Boot image not found: $floppy. Run scripts/build.ps1 first."
}

function Invoke-VBoxManage {
    param([string[]]$Arguments)

    & $vbox @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw ("VBoxManage failed: {0}" -f ($Arguments -join ' '))
    }
}

New-Item -ItemType Directory -Force -Path $base | Out-Null

$vmExists = $false
try {
    Invoke-VBoxManage -Arguments @('showvminfo', $VmName) 2>$null | Out-Null
    $vmExists = ($LASTEXITCODE -eq 0)
} catch {
    $vmExists = $false
}

if ($vmExists) {
    Invoke-VBoxManage -Arguments @('unregistervm', $VmName, '--delete') | Out-Null
}

Invoke-VBoxManage -Arguments @('createvm', '--name', $VmName, '--basefolder', $base, '--ostype', 'Other', '--register')
# Keep the VM audible by default and expose a guest-visible legacy sound device
# that the bare-metal runtime can program directly.
Invoke-VBoxManage -Arguments @(
    'modifyvm', $VmName,
    '--memory', '32',
    '--vram', '8',
    '--boot1', 'floppy',
    '--boot2', 'none',
    '--boot3', 'none',
    '--boot4', 'none',
    '--audio-enabled', 'on',
    '--audio-controller', 'sb16',
    '--audio-codec', 'sb16',
    '--audio-driver', $AudioDriver,
    '--audio-in', 'off',
    '--audio-out', 'on'
)
Invoke-VBoxManage -Arguments @('storagectl', $VmName, '--name', 'Floppy', '--add', 'floppy')
Invoke-VBoxManage -Arguments @('storageattach', $VmName, '--storagectl', 'Floppy', '--port', '0', '--device', '0', '--type', 'fdd', '--medium', $floppy)
Invoke-VBoxManage -Arguments @('showvminfo', $VmName)
