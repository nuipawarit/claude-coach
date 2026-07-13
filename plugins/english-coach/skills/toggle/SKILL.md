---
name: toggle
description: Turn english-coach on or off. Usage - /english-coach:toggle on | off | status
---

# english-coach toggle

Manage the english-coach plugin state. The state file is `key=value` lines at
`$HOME/.claude/english-coach-data/config` (the primary path). The plugin's UserPromptSubmit
hook reads this file first and falls back to `${CLAUDE_PLUGIN_DATA}/config` only when the
primary file does not exist. The hook reads on every prompt.

## Behavior

Parse the argument (`on`, `off`, `status`; no argument = `status`), then run
the matching shell command with the Bash tool and report the resulting state in one line.

Resolve the directory first (same logic in every command):

```sh
DATA_DIR="$HOME/.claude/english-coach-data"; mkdir -p "$DATA_DIR"
```

- `on`:

```sh
printf 'enabled=1\n' > "$DATA_DIR/config"
```

- `off`:

```sh
printf 'enabled=0\n' > "$DATA_DIR/config"
```

- `status`:

```sh
cat "$DATA_DIR/config" 2>/dev/null || echo "enabled=1 (default, no config file)"
```

After writing, confirm to the user: current enabled state, and note that the
change takes effect from the next prompt (the hook runs per prompt).
