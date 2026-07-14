#!/bin/sh
# UserPromptSubmit hook: inject english-coach enforcement unless disabled.
# POSIX sh only. Fail-open: always exit 0.
FALLBACK_DIR="$HOME/.claude/english-coach-data"
CONF="$FALLBACK_DIR/config"
# The config skill's Bash-tool commands run without CLAUDE_PLUGIN_DATA set
# (verified: empty in that context) so it always writes to FALLBACK_DIR.
# Read from there first so config state actually takes effect; only fall
# back to CLAUDE_PLUGIN_DATA/config if the fixed path has never been written.
# Forward-compat only: nothing writes here today (config writes the primary path).
[ -f "$CONF" ] || CONF="${CLAUDE_PLUGIN_DATA:-$FALLBACK_DIR}/config"
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
LIGHT=""
[ "$level" = "light" ] && LIGHT=" LIGHT LEVEL: skip praise lines, skip the ✨ line, skip Format C entirely; Format A/B still apply with mandatory 🎯."
printf '%s' "ENGLISH-COACH ENFORCEMENT: END every response with the english-coach block per the english-coach skill (exact template, the FINAL element of the final message of the turn - never mid-turn while background work is pending). Its skip rules apply (pure slash commands, short acks, pure pastes with zero narration).${LIGHT}"
exit 0
