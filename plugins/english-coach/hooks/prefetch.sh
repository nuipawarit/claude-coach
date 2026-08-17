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
command -v python3 >/dev/null 2>&1 || exit 0

# These two exits are the only ones that may skip staging a verdict file, because
# neither can reach the session's staging path: the config is not yet parsed into a
# session id, and without python3 there is nothing to parse it with. display.sh bails
# on both conditions by itself, so it never waits on a verdict nobody will write.
# Every later exit MUST stage one -- see stage_empty below.

INPUT=$(cat)
SESSION=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("session_id",""))
except Exception: pass' 2>/dev/null)
PROMPT=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("prompt",""))
except Exception: pass' 2>/dev/null)
# An unparsable payload here means display.sh cannot resolve its session either.
[ -n "$SESSION" ] || exit 0

RUN_DIR="$STATE_DIR/sessions/$SESSION"
mkdir -p "$RUN_DIR" 2>/dev/null || exit 0
READY="$RUN_DIR/ready"
RAW="$RUN_DIR/raw"
PIDFILE="$RUN_DIR/pid"
rm -f "$READY" 2>/dev/null

# Publish our pid so display.sh can tell "still evaluating" from "died mid-run" and
# stop waiting on a verdict that is never coming.
echo $$ > "$PIDFILE" 2>/dev/null

# Stage an empty verdict and stop. Every exit past this point goes through here.
stage_empty() {
  : > "$READY"
  rm -f "$PIDFILE" 2>/dev/null
  exit 0
}

# Nothing to evaluate: an image-only or attachment-only turn carries no prompt text.
[ -n "$PROMPT" ] || stage_empty
command -v claude >/dev/null 2>&1 || stage_empty

POLICY="$CLAUDE_PLUGIN_ROOT/runtime/policy.md"
[ -f "$POLICY" ] || stage_empty

PAYLOAD=$(printf '%s' "$PROMPT" | python3 -c 'import json,sys
print(json.dumps({"prompt": sys.stdin.read(), "level": sys.argv[1]}))' "$level" 2>/dev/null)
[ -n "$PAYLOAD" ] || stage_empty

# No --model: the sidecar inherits the small fast model. Binding a model id here
# breaks on any setup that routes through a proxy with non-standard ids.
printf '%s\n\n<evaluation_input>%s</evaluation_input>' "$(cat "$POLICY")" "$PAYLOAD" \
  | claude -p --setting-sources '' --output-format json > "$RAW" 2>/dev/null

# Always write READY, even on failure or skip. An absent file is indistinguishable
# from "still running", which would make the Stop hook burn its full wait cap on
# every skipped turn.
python3 "$CLAUDE_PLUGIN_ROOT/hooks/parse-result.py" "$RAW" "$READY" 2>/dev/null
[ -f "$READY" ] || : > "$READY"
rm -f "$RAW" "$PIDFILE" 2>/dev/null
exit 0
