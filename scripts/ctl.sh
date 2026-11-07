#!/usr/bin/env bash
# Tiny control helper: status | stop | watch
set -u
WORK="${WORK:-work}"
case "${1:-status}" in
  status) [ -s "$WORK/FOUND.txt" ] && echo "CRACKED: $(cat "$WORK/FOUND.txt")" || tail -n 20 "$WORK/progress.log" 2>/dev/null || echo "no run yet";;
  stop)   pkill -f hashcat && echo "stopped" || echo "nothing running";;
  watch)  tail -f "$WORK/progress.log";;
  *) echo "usage: ctl.sh [status|stop|watch]";;
esac
