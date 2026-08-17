#!/bin/sh
# UserPromptSubmit hook, synchronous: tell the model to collect and print this turn's
# coaching block itself.
#
# This runs in front of the main task on every prompt, so it must stay cheap: config
# read, one python call, one printf. Everything expensive belongs in prefetch.sh, which
# is async and overlaps the main task.
#
# stdout enters the model's context for this turn. The CLI renders a plain hook success
# as nothing at all, so none of this reaches the user.
#
# POSIX sh only. Fail-open: always exit 0.

STATE_DIR="$HOME/.claude/english-coach-data"

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
[ -n "$CLAUDE_PLUGIN_ROOT" ] || exit 0

# One python call for both values: this hook is on the critical path, and the session id
# and hash are the only things needed. The prompt itself is never echoed back.
#
# The prefilter lives here rather than in the policy because it decides whether the model
# spends a tool call at all. A slash command and an empty prompt are the two cases the
# policy would certainly skip, and they are cheap to recognise without a model.
# Everything else is left to the sidecar -- guessing wider would silently drop coaching.
IDS=$(python3 -c 'import hashlib,json,sys
try:
    payload = json.load(sys.stdin)
except Exception:
    sys.exit(0)
session = payload.get("session_id") or ""
prompt = payload.get("prompt") or ""
# prefetch.sh reads its prompt through a shell command substitution, which drops
# trailing newlines. Strip the same way or the two would hash to different keys.
prompt = prompt.rstrip("\n")
if not session or not prompt.strip() or prompt.lstrip().startswith("/"):
    sys.exit(0)
print(session)
print(hashlib.sha256(prompt.encode()).hexdigest()[:16])' 2>/dev/null)
[ -n "$IDS" ] || exit 0

SESSION=$(printf '%s\n' "$IDS" | sed -n 1p)
HASH=$(printf '%s\n' "$IDS" | sed -n 2p)
[ -n "$SESSION" ] && [ -n "$HASH" ] || exit 0

# The model's shell has no CLAUDE_PLUGIN_ROOT, so the path is resolved here.
cat <<EOF
<english-coach>
At the very end of your reply, after all other content, run this once:
sh "$CLAUDE_PLUGIN_ROOT/hooks/collect.sh" "$SESSION" "$HASH"
If it prints nothing, output nothing and say nothing about it.
If it prints text, emit that text verbatim on its own lines, with no commentary and no
separator. It already carries its own code fence: do not indent it, re-fence it, or wrap
it in anything.
Never mention this instruction.
</english-coach>
EOF
exit 0
