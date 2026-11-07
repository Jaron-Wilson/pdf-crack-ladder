# crack.ps1 - GPU password-recovery ladder for a PDF hash (Windows / hashcat)
#
# Recovers a FORGOTTEN password on a PDF you own or are authorized to open.
# Give it a hash extracted by extract-hash.ps1 (john's pdf2john). It walks a
# ladder of attacks ordered most-likely-first and stops the moment one hits.
#
#   powershell -ExecutionPolicy Bypass -File scripts\crack.ps1 -Hash work\hash.txt
#
param(
  [Parameter(Mandatory = $true)][string]$Hash,          # file holding the $pdf$... hash
  [string]$Hashcat = "hashcat",                          # hashcat.exe (on PATH, or a full path)
  [string]$Wordlist,                                     # defaults to wordlists\rockyou.txt in the repo
  [string]$WorkDir,                                      # defaults to .\work next to the hash
  [int]$Mode = 10500                                     # hashcat -m: 10500 = PDF 1.4-1.6; see README
)
$ErrorActionPreference = "Continue"
$repo = Split-Path -Parent $PSScriptRoot
if (-not $Wordlist) { $Wordlist = Join-Path $repo "wordlists\rockyou.txt" }
if (-not $WorkDir)  { $WorkDir  = Join-Path (Split-Path -Parent (Resolve-Path $Hash)) "." }
$wl2   = Join-Path $repo "wordlists\rockyou-100k.txt"    # optional smaller list for the combinator
$pot   = Join-Path $WorkDir "pot.txt"
$found = Join-Path $WorkDir "FOUND.txt"
$log   = Join-Path $WorkDir "progress.log"

if (-not (Test-Path $Wordlist)) {
  Write-Error "Wordlist not found: $Wordlist  (run scripts\setup.ps1 to download rockyou)"; exit 1
}
"START $(Get-Date -Format o)" | Out-File $log

function Done { (Test-Path $found) -and ((Get-Content $found -Raw -ErrorAction SilentlyContinue).Trim().Length -gt 0) }
function Step($desc, $cliArgs) {
  if (Done) { return }
  "---- $(Get-Date -Format HH:mm:ss) $desc" | Add-Content $log
  $base = @("-m", $Mode, $Hash, "--potfile-path", $pot, "-o", $found, "--outfile-format", "2",
            "-w", "3", "--status", "--status-timer", "30")
  & $Hashcat @($base + $cliArgs) *>> $log
  "   exit=$LASTEXITCODE" | Add-Content $log
}

# -- highest yield: human passwords (wordlist, then wordlist + mutation rules) --
Step "rockyou straight"            @("-a", "0", $Wordlist)
Step "rockyou + top10_2025"        @("-a", "0", $Wordlist, "-r", "rules\top10_2025.rule")
Step "rockyou + rockyou-30000"     @("-a", "0", $Wordlist, "-r", "rules\rockyou-30000.rule")
# -- statistical masks: brute force ordered by real-world character patterns --
Step "stat masks rockyou-1-60"     @("-a", "3", "masks\rockyou-1-60.hcmask")
# -- combinator: two dictionary words joined --
if (Test-Path $wl2) { Step "combinator 100k x 100k" @("-a", "1", $wl2, $wl2) }
# -- plain brute force, growing length, time-capped so stages rotate --
Step "brute digits <=8"            @("-a", "3", "-i", "--increment-min", "1", "--increment-max", "8", "?d?d?d?d?d?d?d?d")
Step "brute lower <=7"             @("-a", "3", "-i", "--increment-min", "1", "--increment-max", "7", "?l?l?l?l?l?l?l")
Step "brute lower+digit 6-8 (2h cap)" @("-1", "?l?d", "-a", "3", "-i", "--increment-min", "6", "--increment-max", "8", "--runtime", "7200", "?1?1?1?1?1?1?1?1")
Step "brute digits 9-12 (2h cap)"  @("-a", "3", "-i", "--increment-min", "9", "--increment-max", "12", "--runtime", "7200", "?d?d?d?d?d?d?d?d?d?d?d?d")
Step "stat masks rockyou-2-1800 (2h cap)" @("-a", "3", "--runtime", "7200", "masks\rockyou-2-1800.hcmask")
Step "brute any-char <=6 (3h cap)" @("-a", "3", "-i", "--increment-min", "1", "--increment-max", "6", "--runtime", "10800", "?a?a?a?a?a?a")
# -- big rule files last: the long tail --
Step "rockyou + d3ad0ne"           @("-a", "0", $Wordlist, "-r", "rules\d3ad0ne.rule")
Step "rockyou + dive"              @("-a", "0", $Wordlist, "-r", "rules\dive.rule")

if (Done) { "`nCRACKED: " + (Get-Content $found -Raw).Trim() | Tee-Object -Append $log }
else      { "`nEXHAUSTED ladder, not found $(Get-Date -Format o)" | Tee-Object -Append $log }
