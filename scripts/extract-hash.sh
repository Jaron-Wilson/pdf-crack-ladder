#!/usr/bin/env bash
# Extract the hashcat-ready hash from a PDF using john's pdf2john.
#   scripts/extract-hash.sh locked.pdf > work/hash.txt
set -u
PDF="${1:?usage: extract-hash.sh <file.pdf>}"
for c in pdf2john pdf2john.pl; do command -v "$c" >/dev/null && { "$c" "$PDF" | sed 's/^[^:]*://'; exit 0; }; done
echo "pdf2john not found. Install john (e.g. 'sudo apt install john'), or use John the Ripper's run/pdf2john.pl." >&2
exit 1
