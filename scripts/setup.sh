#!/usr/bin/env bash
# Download rockyou + a 100k slice into wordlists/. hashcat ships its own rules/ and masks/.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"; cd "$REPO/wordlists"
if [ ! -f rockyou.txt ]; then
  echo "Fetching rockyou.txt ..."
  curl -fsSL -o rockyou.txt https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt
fi
head -100000 rockyou.txt > rockyou-100k.txt
echo "wordlists ready:"; wc -l rockyou.txt rockyou-100k.txt
echo "Install hashcat (https://hashcat.net/hashcat/) and John the Ripper (for pdf2john). The"
echo "rules/ and masks/ the ladder uses (top10_2025, d3ad0ne, dive, rockyou-*.hcmask) ship with hashcat;"
echo "run crack.sh from inside the hashcat folder, or copy its rules/ and masks/ next to the hash."
