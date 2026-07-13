#!/bin/sh
# UserPromptSubmit hook: inject prompting-coach enforcement unless disabled.
# POSIX sh only. Fail-open: always exit 0.
DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/prompting-coach-data}"
CONF="$DATA_DIR/config"
enabled=1
lang=en
if [ -f "$CONF" ]; then
  while IFS='=' read -r k v; do
    case "$k" in
      enabled) enabled="$v" ;;
      lang) lang="$v" ;;
    esac
  done < "$CONF"
fi
[ "$enabled" = "0" ] && exit 0
printf '%s' "PROMPTING-COACH ENFORCEMENT: (1) BEFORE starting any work on this prompt, run the prompting-coach skill's pre-flight evaluation - a severe, load-bearing gap on substantial work means the Format G gate (AskUserQuestion) BEFORE any work; its skip rules and Gate Rubric apply. (2) When no gate fires, OPEN the response with the prompting-coach verdict block (Format A or B, exact template) as the FIRST element - omitted only when a skip rule applies. Commentary language: ${lang}."
exit 0
