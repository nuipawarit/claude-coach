#!/bin/sh
# UserPromptSubmit hook: inject english-coach enforcement unless disabled.
# POSIX sh only. Fail-open: always exit 0.
DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/english-coach-data}"
CONF="$DATA_DIR/config"
enabled=1
if [ -f "$CONF" ]; then
  while IFS='=' read -r k v; do
    case "$k" in
      enabled) enabled="$v" ;;
    esac
  done < "$CONF"
fi
[ "$enabled" = "0" ] && exit 0
printf '%s' "ENGLISH-COACH ENFORCEMENT: END every response with the english-coach block per the english-coach skill (exact template, the FINAL element of the final message of the turn - never mid-turn while background work is pending). Its skip rules apply (pure slash commands, short acks, pure pastes with zero narration)."
exit 0
