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

# The exits above and the two below (empty session id, unhashable prompt) are the only
# ones that may skip staging a verdict file, because none of them can reach the
# session's staging path. They are safe because inject.sh derives that same path from
# the same payload and bails on the same conditions, so it never asks the model to
# collect a verdict nobody will write. Every later exit MUST stage one -- see
# stage_empty below.

INPUT=$(cat)
SESSION=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("session_id",""))
except Exception: pass' 2>/dev/null)
PROMPT=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("prompt",""))
except Exception: pass' 2>/dev/null)
# An unparsable payload here means display.sh cannot resolve its session either.
[ -n "$SESSION" ] || exit 0

# Stage under a per-turn key so a verdict can never be mistaken for the previous
# turn's. Nothing consumes the file on a fixed schedule any more -- collect.sh runs
# whenever the model gets to it -- so a shared `ready` path would let a slow sidecar
# hand this turn the last turn's block. The prompt is the only per-turn value both
# hooks see, and both derive it from the same payload the same way, so they agree
# without passing state.
HASH=$(printf '%s' "$PROMPT" | python3 -c 'import hashlib,sys
print(hashlib.sha256(sys.stdin.buffer.read()).hexdigest()[:16])' 2>/dev/null)
[ -n "$HASH" ] || exit 0

RUN_DIR="$STATE_DIR/sessions/$SESSION"
mkdir -p "$RUN_DIR" 2>/dev/null || exit 0
READY="$RUN_DIR/ready-$HASH"
RAW="$RUN_DIR/raw-$HASH"
PIDFILE="$RUN_DIR/pid-$HASH"
# Sweep the whole session, not just this key: a turn whose block the model never
# collected would otherwise leave its file behind until SessionEnd.
rm -f "$RUN_DIR"/ready-* "$RUN_DIR"/pid-* "$RUN_DIR"/raw-* 2>/dev/null

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
