#!/bin/sh
# UserPromptSubmit hook, synchronous: hand the gate rubric to the main model so it can
# open a real AskUserQuestion chooser instead of a plain blocked-prompt message.
#
# A `prompt` hook cannot do this: it returns only {ok, reason}, and ok=false blocks the
# turn outright. A command hook can read files and ${CLAUDE_PLUGIN_ROOT} is expanded, so
# the policy stays a reviewable file rather than an inlined string.
#
# No sidecar, no network call — the only cost is one sh fork plus the rubric's tokens.
#
# POSIX sh only. Fail-open: always exit 0, print nothing when disabled.

STATE_DIR="$HOME/.claude/prompting-coach-data"
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

POLICY="$CLAUDE_PLUGIN_ROOT/runtime/policy.md"
[ -f "$POLICY" ] || exit 0

python3 -c 'import json,sys
policy = open(sys.argv[1]).read().strip()
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": policy,
}}))' "$POLICY" 2>/dev/null
exit 0
