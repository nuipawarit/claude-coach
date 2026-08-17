---
name: config
description: Configure prompting-coach. Usage - /prompting-coach:config on | off | status
---

# prompting-coach config

Manage the prompting-coach gate. The gate is a `prompt` hook: a small model judges the
prompt before any work starts, adding roughly a second and nothing to the main context.

**Why `off` uninstalls the hook instead of setting a flag:** a `prompt` hook runs with
no tools, so it cannot read a config file, and a preceding command hook cannot suppress
it (both verified live on 2.1.233 — the prompt hook still ran and could not see the
command hook's output). The only way to turn the gate off is to remove the hook itself.

`lang` and `level` are gone. The gate emits its improved prompt in the user's own
language automatically, and it already fires only on load-bearing gaps — which is what
`level=light` meant.

## Behavior

Parse the argument (`on`, `off`, `status`; no argument = `status`), run the matching
shell command with the Bash tool, and report the resulting state in one line. Unknown
argument → reply with the usage line from the description; do not write.

Resolve the plugin directory first (same logic in every command):

```sh
PLUGIN_DIR=$(ls -d "$HOME"/.claude/plugins/cache/claude-coach/prompting-coach/*/ 2>/dev/null | sort -V | tail -1)
HOOKS="$PLUGIN_DIR/hooks/hooks.json"
DISABLED="$PLUGIN_DIR/hooks/hooks.json.disabled"
```

- `off`:

```sh
[ -f "$HOOKS" ] && mv "$HOOKS" "$DISABLED"; echo "gate off"
```

- `on`:

```sh
[ -f "$DISABLED" ] && mv "$DISABLED" "$HOOKS"; echo "gate on"
```

- `status`:

```sh
if [ -f "$HOOKS" ]; then echo "gate on"; else echo "gate off"; fi
```

After the command, tell the user the resulting state and that it takes effect in the
next session — hook files are read at session start, not per prompt.
