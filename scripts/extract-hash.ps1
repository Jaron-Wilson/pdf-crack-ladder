# Extract the hashcat-ready hash from a PDF using john's pdf2john.pl.
#   python .\john\run\pdf2john.py locked.pdf    (or the bundled pdf2john.pl via perl)
# Point $P2J at your John the Ripper pdf2john script.
param([Parameter(Mandatory=$true)][string]$Pdf, [string]$P2J = "pdf2john.pl")
if (Get-Command perl -ErrorAction SilentlyContinue) {
  (perl $P2J $Pdf) -replace '^[^:]*:', ''
} else {
  Write-Error "Need perl + John the Ripper's pdf2john.pl (or run pdf2john.py with Python). See README."
}
