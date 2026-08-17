#!/bin/sh
# UserPromptSubmit hook, async: evaluate the user's prompt with a Haiku sidecar
# while the main task runs, and stage the result for the Stop hook to display.
#
# Async is what makes this free: the evaluation overlaps the main task instead of
# following it. The prompt is already known at turn start, so nothing has to wait.
#
# POSIX sh only. Fail-open: always exit 0, print nothing on stdout.

STATE_DIR="$HOME/.claude/english-coach-data"
CONF="$STATE_DIR/config"
[ -f "$CONF" ] || CONF="${CLAUDE_PLUGIN_DATA:-$STATE_DIR}/config"

enabled=1
level=full
if [ -f "$CONF" ]; then
  CR=$(printf '\r')
  while IFS='=' read -r k v || [ -n "$k" ]; do
    v=${v%"$CR"}
    case "$k" in
      enabled) enabled="$v" ;;
      level) level="$v" ;;
    esac
  done < "$CONF"
fi
[ "$enabled" = "0" ] && exit 0

command -v claude >/dev/null 2>&1 || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

INPUT=$(cat)
SESSION=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("session_id",""))
except Exception: pass' 2>/dev/null)
PROMPT=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("prompt",""))
except Exception: pass' 2>/dev/null)
[ -n "$SESSION" ] || exit 0
[ -n "$PROMPT" ] || exit 0

RUN_DIR="$STATE_DIR/sessions/$SESSION"
mkdir -p "$RUN_DIR" 2>/dev/null || exit 0
READY="$RUN_DIR/ready"
RAW="$RUN_DIR/raw"
rm -f "$READY" 2>/dev/null

POLICY="$CLAUDE_PLUGIN_ROOT/runtime/policy.md"
[ -f "$POLICY" ] || { : > "$READY"; exit 0; }

PAYLOAD=$(printf '%s' "$PROMPT" | python3 -c 'import json,sys
print(json.dumps({"prompt": sys.stdin.read(), "level": sys.argv[1]}))' "$level" 2>/dev/null)
[ -n "$PAYLOAD" ] || { : > "$READY"; exit 0; }

# No --model: the sidecar inherits the small fast model. Binding a model id here
# breaks on any setup that routes through a proxy with non-standard ids.
printf '%s\n\n<evaluation_input>%s</evaluation_input>' "$(cat "$POLICY")" "$PAYLOAD" \
  | claude -p --setting-sources '' --output-format json > "$RAW" 2>/dev/null

# Always write READY, even on failure or skip. An absent file is indistinguishable
# from "still running", which would make the Stop hook burn its full wait cap on
# every skipped turn.
python3 "$CLAUDE_PLUGIN_ROOT/hooks/parse-result.py" "$RAW" "$READY" 2>/dev/null
[ -f "$READY" ] || : > "$READY"
rm -f "$RAW" 2>/dev/null
exit 0
