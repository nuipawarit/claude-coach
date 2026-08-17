#!/bin/sh
# Stop hook, synchronous: deliver the staged coaching block in THIS turn.
#
# The prefetch normally finishes while the main task is still running, so this
# usually reads a file that is already there and adds no measurable delay. The
# bounded wait only matters when the main task finished faster than the sidecar.
#
# POSIX sh only. Fail-open: always exit 0.

STATE_DIR="$HOME/.claude/english-coach-data"
INPUT=$(cat)
SESSION=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("session_id",""))
except Exception: pass' 2>/dev/null)
[ -n "$SESSION" ] || exit 0

RUN_DIR="$STATE_DIR/sessions/$SESSION"
READY="$RUN_DIR/ready"

# 0.05s x 700 = 35s, comfortably inside the hook's own 45s timeout.
i=0
while [ ! -f "$READY" ] && [ "$i" -lt 700 ]; do
  sleep 0.05
  i=$((i + 1))
done

[ -f "$READY" ] || exit 0
BLOCK=$(cat "$READY")
rm -f "$READY" 2>/dev/null
[ -n "$BLOCK" ] || exit 0

# Top-level systemMessage: shown to the user, kept out of the main model's context.
printf '%s' "$BLOCK" | python3 -c 'import json,sys
print(json.dumps({"systemMessage": sys.stdin.read()}))' 2>/dev/null
exit 0
