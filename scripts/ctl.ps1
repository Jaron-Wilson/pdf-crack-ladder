# Tiny control helper: status | stop | watch
param([string]$action = "status", [string]$work = "work")
switch ($action) {
  "status" {
    if (Test-Path "$work\FOUND.txt") { "CRACKED: " + (Get-Content "$work\FOUND.txt" -Raw).Trim() }
    elseif (Test-Path "$work\progress.log") { Get-Content "$work\progress.log" -Tail 20 }
    else { "no run yet" }
  }
  "stop"  { Stop-Process -Name hashcat -Force -ErrorAction SilentlyContinue; "stopped" }
  "watch" { Get-Content "$work\progress.log" -Wait -Tail 20 }
  default { "usage: ctl.ps1 [status|stop|watch]" }
}
