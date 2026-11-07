#!/usr/bin/env bash
# crack.sh - GPU password-recovery ladder for a PDF hash (Linux / hashcat)
#
# Recovers a FORGOTTEN password on a PDF you own or are authorized to open.
# Give it a hash extracted by extract-hash.sh (john's pdf2john). It walks a
# ladder of attacks ordered most-likely-first and stops the moment one hits.
#
#   scripts/crack.sh work/hash.txt
#
set -u
HASH="${1:?usage: crack.sh <hash-file> [wordlist]}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
HASHCAT="${HASHCAT:-hashcat}"
WORDLIST="${2:-$REPO/wordlists/rockyou.txt}"
WL2="$REPO/wordlists/rockyou-100k.txt"
MODE="${MODE:-10500}"                     # 10500 = PDF 1.4-1.6; see README
WORK="$(cd "$(dirname "$HASH")" && pwd)"
POT="$WORK/pot.txt"; FOUND="$WORK/FOUND.txt"; LOG="$WORK/progress.log"

[ -f "$WORDLIST" ] || { echo "Wordlist not found: $WORDLIST (run scripts/setup.sh)"; exit 1; }
echo "START $(date -Is)" > "$LOG"

done_yet() { [ -s "$FOUND" ]; }
step() {  # step "desc" args...
  done_yet && return
  local desc="$1"; shift
  echo "---- $(date +%H:%M:%S) $desc" >> "$LOG"
  "$HASHCAT" -m "$MODE" "$HASH" --potfile-path "$POT" -o "$FOUND" --outfile-format 2 \
    -w 3 --status --status-timer 30 "$@" >> "$LOG" 2>&1
  echo "   exit=$?" >> "$LOG"
}

# -- highest yield: human passwords (wordlist, then wordlist + mutation rules) --
step "rockyou straight"            -a 0 "$WORDLIST"
step "rockyou + top10_2025"        -a 0 "$WORDLIST" -r rules/top10_2025.rule
step "rockyou + rockyou-30000"     -a 0 "$WORDLIST" -r rules/rockyou-30000.rule
# -- statistical masks: brute force ordered by real-world character patterns --
step "stat masks rockyou-1-60"     -a 3 masks/rockyou-1-60.hcmask
# -- combinator: two dictionary words joined --
[ -f "$WL2" ] && step "combinator 100k x 100k" -a 1 "$WL2" "$WL2"
# -- plain brute force, growing length, time-capped so stages rotate --
step "brute digits <=8"            -a 3 -i --increment-min 1 --increment-max 8 '?d?d?d?d?d?d?d?d'
step "brute lower <=7"             -a 3 -i --increment-min 1 --increment-max 7 '?l?l?l?l?l?l?l'
step "brute lower+digit 6-8 (2h)"  -1 '?l?d' -a 3 -i --increment-min 6 --increment-max 8 --runtime 7200 '?1?1?1?1?1?1?1?1'
step "brute digits 9-12 (2h)"      -a 3 -i --increment-min 9 --increment-max 12 --runtime 7200 '?d?d?d?d?d?d?d?d?d?d?d?d'
step "stat masks rockyou-2-1800 (2h)" -a 3 --runtime 7200 masks/rockyou-2-1800.hcmask
step "brute any-char <=6 (3h)"     -a 3 -i --increment-min 1 --increment-max 6 --runtime 10800 '?a?a?a?a?a?a'
# -- big rule files last: the long tail --
step "rockyou + d3ad0ne"           -a 0 "$WORDLIST" -r rules/d3ad0ne.rule
step "rockyou + dive"              -a 0 "$WORDLIST" -r rules/dive.rule

if done_yet; then printf '\nCRACKED: %s\n' "$(cat "$FOUND")" | tee -a "$LOG"
else printf '\nEXHAUSTED ladder, not found %s\n' "$(date -Is)" | tee -a "$LOG"; fi
