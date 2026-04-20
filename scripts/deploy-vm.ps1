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
$diskImage = Join-Path $root 'build\cyberstorm.img'
$vmDiskImage = Join-Path $base ("{0}.vdi" -f $VmName)
$vmFolder = Join-Path $base $VmName

. (Join-Path $PSScriptRoot 'vbox-common.ps1')

if (-not (Test-Path $vbox)) {
    throw 'VBoxManage.exe was not found in the default Oracle VirtualBox install path.'
}

if (-not (Test-Path $diskImage)) {
    throw "Boot image not found: $diskImage. Run scripts/build.ps1 first."
}

New-Item -ItemType Directory -Force -Path $base | Out-Null

$vmExists = $false
try {
    Get-VBoxMachineInfoLines -Name $VmName | Out-Null
    $vmExists = $true
} catch {
    $vmExists = $false
}

if ($vmExists) {
    Invoke-VBoxManage -Arguments @('unregistervm', $VmName, '--delete') | Out-Null
}

if (Test-Path -LiteralPath $vmDiskImage) {
    Remove-Item -LiteralPath $vmDiskImage -Force
}

if (Test-Path -LiteralPath $vmFolder) {
    Remove-Item -LiteralPath $vmFolder -Recurse -Force
}

Invoke-VBoxManage -Arguments @('convertfromraw', $diskImage, $vmDiskImage, '--format', 'VDI') | Out-Null

Invoke-VBoxManage -Arguments @('createvm', '--name', $VmName, '--basefolder', $base, '--ostype', 'Other', '--register')
# Keep the VM audible by default and expose a guest-visible legacy sound device
# that the bare-metal runtime can program directly.
Invoke-VBoxManage -Arguments @(
    'modifyvm', $VmName,
    '--memory', '64',
    '--vram', '16',
    '--graphicscontroller', 'vboxsvga',
    '--monitorcount', '1',
    '--accelerate3d', 'off',
    '--boot1', 'disk',
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
Invoke-VBoxManage -Arguments @('storagectl', $VmName, '--name', 'IDE', '--add', 'ide')
Invoke-VBoxManage -Arguments @('storageattach', $VmName, '--storagectl', 'IDE', '--port', '0', '--device', '0', '--type', 'hdd', '--medium', $vmDiskImage)
Get-VBoxMachineInfoLines -Name $VmName
