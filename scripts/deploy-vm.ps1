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
$isoImage = Join-Path $root 'build\cyberstorm-expanded.iso'
$vmDiskImage = Join-Path $base ("{0}.vdi" -f $VmName)
$vmFolder = Join-Path $base $VmName

. (Join-Path $PSScriptRoot 'vbox-common.ps1')

function Remove-PathWithRetries {
    param(
        [string]$Path,
        [string]$Label,
        [switch]$Directory
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $lastError = $null
    for ($attempt = 0; $attempt -lt 4; $attempt++) {
        try {
            if ($Directory.IsPresent) {
                Remove-Item -LiteralPath $Path -Recurse -Force
            } else {
                Remove-Item -LiteralPath $Path -Force
            }
            return
        } catch {
            $lastError = $_
            Restart-VBoxBootstrapServices
            Start-Sleep -Seconds (1 + $attempt)
        }
    }

    throw ("Could not remove {0}: {1}`n{2}" -f $Label, $Path, $lastError.Exception.Message)
}

if (-not (Test-Path $vbox)) {
    throw 'VBoxManage.exe was not found in the default Oracle VirtualBox install path.'
}

if (-not (Test-Path $diskImage)) {
    throw "Boot image not found: $diskImage. Run scripts/build.ps1 first."
}

New-Item -ItemType Directory -Force -Path $base | Out-Null

Invoke-VBoxPreflight -Context 'deploy vm preflight'

$vmExists = $false
try {
    Get-VBoxMachineInfoLines -Name $VmName -Context 'deploy vm initial showvminfo' | Out-Null
    $vmExists = $true
} catch {
    $vmExists = $false
}

if ($vmExists) {
    Stop-VmIfRunning -Name $VmName
    try {
        Invoke-VBoxManage -Arguments @('unregistervm', $VmName, '--delete') | Out-Null
    } catch {
        Restart-VBoxBootstrapServices
        Start-Sleep -Seconds 2
        Invoke-VBoxManage -Arguments @('unregistervm', $VmName, '--delete') | Out-Null
    }
}

Remove-PathWithRetries -Path $vmDiskImage -Label 'vm disk image'
Remove-PathWithRetries -Path $vmFolder -Label 'vm folder' -Directory


Invoke-VBoxManage -Arguments @('convertfromraw', $diskImage, $vmDiskImage, '--format', 'VDI') | Out-Null

Invoke-VBoxManage -Arguments @('createvm', '--name', $VmName, '--basefolder', $base, '--ostype', 'Other', '--register')
# Keep the VM audible by default and give the presentation target enough headroom
# for richer banked frontend/gameplay assets while retaining legacy bare-metal I/O.
Invoke-VBoxManage -Arguments @(
    'modifyvm', $VmName,
    '--memory', '256',
    '--vram', '32',
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
if (Test-Path -LiteralPath $isoImage) {
    Invoke-VBoxManage -Arguments @('storageattach', $VmName, '--storagectl', 'IDE', '--port', '1', '--device', '0', '--type', 'dvddrive', '--medium', $isoImage)
}
Get-VBoxMachineInfoLines -Name $VmName -Context 'deploy vm final showvminfo'
