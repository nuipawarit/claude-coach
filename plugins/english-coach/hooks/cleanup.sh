#!/bin/sh
# SessionEnd hook: drop this session's staging directory, and sweep any dirs left
# behind by sessions that ended without firing this hook (crash, kill -9).
#
# POSIX sh only. Fail-open: always exit 0.

SESSIONS_DIR="$HOME/.claude/english-coach-data/sessions"
[ -d "$SESSIONS_DIR" ] || exit 0

INPUT=$(cat)
SESSION=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("session_id",""))
except Exception: pass' 2>/dev/null)

case "$SESSION" in
  *[!a-zA-Z0-9-]* | "") ;;
  *) rm -rf "$SESSIONS_DIR/$SESSION" 2>/dev/null ;;
esac

find "$SESSIONS_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +1 -exec rm -rf {} + 2>/dev/null
exit 0
