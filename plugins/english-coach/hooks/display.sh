#!/bin/sh
# Stop hook, synchronous: deliver the staged coaching block in THIS turn.
#
# The prefetch normally finishes while the main task is still running, so this
# usually reads a file that is already there and adds no measurable delay. The
# bounded wait only matters when the main task finished faster than the sidecar.
#
# POSIX sh only. Fail-open: always exit 0.

STATE_DIR="$HOME/.claude/english-coach-data"

# Read the same config the prefetch reads. When disabled, the prefetch stages no
# verdict at all, so without this check the wait loop below would burn its full cap
# on every turn -- a disabled plugin would cost more than an enabled one.
CONF="$STATE_DIR/config"
[ -f "$CONF" ] || CONF="${CLAUDE_PLUGIN_DATA:-$STATE_DIR}/config"
enabled=1
if [ -f "$CONF" ]; then
  CR=$(printf '\r')
  while IFS='=' read -r k v || [ -n "$k" ]; do
    v=${v%"$CR"}
    case "$k" in
      enabled) enabled="$v" ;;
    esac
  done < "$CONF"
fi
[ "$enabled" = "0" ] && exit 0

command -v python3 >/dev/null 2>&1 || exit 0

INPUT=$(cat)
SESSION=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("session_id",""))
except Exception: pass' 2>/dev/null)
[ -n "$SESSION" ] || exit 0

RUN_DIR="$STATE_DIR/sessions/$SESSION"
READY="$RUN_DIR/ready"
PIDFILE="$RUN_DIR/pid"

# 0.05s x 700 = 35s, comfortably inside the hook's own 45s timeout. The cap is only
# reached when the sidecar is genuinely still working; a dead prefetch is detected in
# well under a second by the liveness check below.
#
# `ps -p` rather than `kill -0`: kill reports EPERM as failure, so it calls any pid
# outside our own uid dead. That misread would abandon a live evaluation.
i=0
while [ ! -f "$READY" ] && [ "$i" -lt 700 ]; do
  if [ -f "$PIDFILE" ]; then
    PREFETCH_PID=$(cat "$PIDFILE" 2>/dev/null)
    case "$PREFETCH_PID" in
      '' | *[!0-9]*) break ;;
    esac
    ps -p "$PREFETCH_PID" >/dev/null 2>&1 || break
  elif [ "$i" -gt 60 ]; then
    # No pidfile after 3s: the prefetch never started (async dispatch dropped it,
    # config disabled between hooks) or it finished without staging a verdict. The
    # grace period covers a prefetch still forking its way to the pidfile write.
    break
  fi
  sleep 0.05
  i=$((i + 1))
done

[ -f "$READY" ] || exit 0
BLOCK=$(cat "$READY")
rm -f "$READY" 2>/dev/null
[ -n "$BLOCK" ] || exit 0

# Top-level systemMessage: shown to the user, kept out of the main model's context.
#
# The renderer prints "Stop says: " immediately before the content on the same line, so
# the block is prefixed with a newline to keep that label off the box's first row.
printf '%s' "$BLOCK" | python3 -c 'import json,sys
print(json.dumps({"systemMessage": "\n" + sys.stdin.read()}))' 2>/dev/null
exit 0
