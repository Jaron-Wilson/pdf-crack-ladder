# Kill a stuck run and relaunch crack.ps1 detached (survives the SSH session).
param([Parameter(Mandatory=$true)][string]$Hash, [string]$HashcatDir = ".")
$here = $PSScriptRoot
Stop-Process -Name hashcat -Force -ErrorAction SilentlyContinue
Get-CimInstance Win32_Process |
  Where-Object { $_.Name -eq "powershell.exe" -and $_.CommandLine -match "crack.ps1" } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep 3
Get-ChildItem "$HashcatDir\*.restore" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Remove-Item "$HashcatDir\hashcat.pid" -ErrorAction SilentlyContinue
$cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$here\crack.ps1`" -Hash `"$Hash`""
$r = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine=$cmd}
"relaunched pid=$($r.ProcessId) rv=$($r.ReturnValue)"
