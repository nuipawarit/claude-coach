#!/bin/sh
# SessionEnd hook: drop this session's staging directory, sweep any dirs left behind
# by sessions that ended without firing this hook (crash, kill -9), and release stale
# plugin-cache pins.
#
# POSIX sh only. Fail-open: always exit 0.

STATE_DIR="$HOME/.claude/english-coach-data"
SESSIONS_DIR="$STATE_DIR/sessions"

# Reap plugin-cache refcount files left by sessions that died without releasing them.
# Claude Code pins each cached plugin version with .in_use/<pid> while a session holds
# it. A hard-killed session never removes its file, so the version stays pinned forever
# and its disk footprint is never reclaimed -- measured 21 dead pids against 2 live.
#
# `ps -p`, not `kill -0`: kill reports EPERM as failure, so it would call any pid
# outside our uid dead and unpin a version that is still in use.
reap_stale_pins() {
  [ -n "$CLAUDE_PLUGIN_ROOT" ] || return 0
  versions_dir=$(dirname "$CLAUDE_PLUGIN_ROOT")
  [ -d "$versions_dir" ] || return 0

  for vdir in "$versions_dir"/*; do
    [ -d "$vdir" ] || continue
    # Never touch the version this session is running from.
    [ "$vdir" = "$CLAUDE_PLUGIN_ROOT" ] && continue

    for pidfile in "$vdir"/.in_use/*; do
      [ -f "$pidfile" ] || continue
      pid=${pidfile##*/}
      case "$pid" in
        '' | *[!0-9]*) continue ;;
      esac
      ps -p "$pid" >/dev/null 2>&1 || rm -f "$pidfile" 2>/dev/null
    done

    # Remove the version tree only when Claude Code has marked it orphaned, that mark
    # is over a day old, and nothing pins it any more. Checking the pins last keeps a
    # version a session claimed mid-sweep.
    [ -f "$vdir/.orphaned_at" ] || continue
    [ -n "$(find "$vdir/.orphaned_at" -mtime +0 2>/dev/null)" ] || continue
    # Count only numeric pidfiles. Non-pid junk (.DS_Store, editor temp files) is never
    # reaped above, so counting it here would pin the version permanently.
    pinned=0
    for pidfile in "$vdir"/.in_use/*; do
      [ -f "$pidfile" ] || continue
      pid=${pidfile##*/}
      case "$pid" in
        '' | *[!0-9]*) continue ;;
      esac
      pinned=1
      break
    done
    [ "$pinned" = 0 ] && rm -rf "$vdir" 2>/dev/null
  done
}

reap_stale_pins

[ -d "$SESSIONS_DIR" ] || exit 0

INPUT=$(cat)
SESSION=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("session_id",""))
except Exception: pass' 2>/dev/null)

case "$SESSION" in
  *[!a-zA-Z0-9-]* | "") ;;
  *) rm -rf "$SESSIONS_DIR/$SESSION" 2>/dev/null ;;
esac

find "$SESSIONS_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +1 -exec rm -rf {} + 2>/dev/null
exit 0
