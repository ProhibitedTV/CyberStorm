param(
    [string]$VmName = 'CyberStorm'
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

New-Item -ItemType Directory -Force -Path $base | Out-Null

& $vbox unregistervm $VmName --delete 2>$null | Out-Null
& $vbox createvm --name $VmName --basefolder $base --ostype Other --register
& $vbox modifyvm $VmName --memory 32 --vram 8 --boot1 floppy --boot2 none --boot3 none --boot4 none --audio-driver none
& $vbox storagectl $VmName --name Floppy --add floppy
& $vbox storageattach $VmName --storagectl Floppy --port 0 --device 0 --type fdd --medium $floppy
& $vbox showvminfo $VmName
