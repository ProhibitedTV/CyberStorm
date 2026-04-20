$vbox = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
$DeployScriptPath = Join-Path (Get-Location).Path 'scripts\deploy-vm.ps1'
. .\scripts\vbox-common.ps1
$VmName = 'CyberStorm'
$root = (Get-Location).Path
$shotDir = Join-Path $root 'build\manual-title-start'
New-Item -ItemType Directory -Force -Path $shotDir | Out-Null
Stop-VmIfRunning -Name $VmName
Ensure-VmRegistered -Name $VmName
Stop-VmIfRunning -Name $VmName
Invoke-DeployVm -Name $VmName
Start-HeadlessVm -Name $VmName
$points = @(2, 4, 6, 8, 10)
$elapsed = 0
foreach ($point in $points) {
    $sleep = [Math]::Max(0, $point - $elapsed)
    if ($sleep -gt 0) { Start-Sleep -Seconds $sleep }
    $elapsed = $point
    $path = Join-Path $shotDir ("title-start-$point`s.png")
    Invoke-VmScreenshot -Name $VmName -OutputPath $path
    Write-Output $path
}
Stop-VmIfRunning -Name $VmName
