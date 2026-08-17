#!/bin/sh
# SessionEnd hook: release stale plugin-cache pins.
#
# Claude Code pins each cached plugin version with .in_use/<pid> while a session holds
# it. A hard-killed session never removes its file, so the version stays pinned forever
# and its disk footprint is never reclaimed -- measured 19 dead pids against 2 live.
#
# This plugin keeps no per-session state, so pin reaping is all there is to do. The
# logic is duplicated in english-coach's cleanup rather than shared: plugins are
# installed independently and cannot reference each other's files.
#
# POSIX sh only. Fail-open: always exit 0.

[ -n "$CLAUDE_PLUGIN_ROOT" ] || exit 0
VERSIONS_DIR=$(dirname "$CLAUDE_PLUGIN_ROOT")
[ -d "$VERSIONS_DIR" ] || exit 0

for vdir in "$VERSIONS_DIR"/*; do
  [ -d "$vdir" ] || continue
  # Never touch the version this session is running from.
  [ "$vdir" = "$CLAUDE_PLUGIN_ROOT" ] && continue

  # `ps -p`, not `kill -0`: kill reports EPERM as failure, so it would call any pid
  # outside our uid dead and unpin a version that is still in use.
  for pidfile in "$vdir"/.in_use/*; do
    [ -f "$pidfile" ] || continue
    pid=${pidfile##*/}
    case "$pid" in
      '' | *[!0-9]*) continue ;;
    esac
    ps -p "$pid" >/dev/null 2>&1 || rm -f "$pidfile" 2>/dev/null
  done

  # Remove the version tree only when Claude Code has marked it orphaned, that mark is
  # over a day old, and nothing pins it any more. Checking the pins last keeps a
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

exit 0
