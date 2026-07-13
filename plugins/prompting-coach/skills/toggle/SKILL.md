---
name: toggle
description: Turn prompting-coach on or off, or set the coaching commentary language. Usage - /prompting-coach:toggle on | off | lang <code> | status
---

# prompting-coach toggle

Manage the prompting-coach plugin state. The state file is `key=value` lines at
`$HOME/.claude/prompting-coach-data/config` (the primary path). The plugin's UserPromptSubmit
hook reads this file first and falls back to `${CLAUDE_PLUGIN_DATA}/config` only when the
primary file does not exist. The hook reads on every prompt.

## Behavior

Parse the argument (`on`, `off`, `lang <code>`, `status`; no argument = `status`), then run
the matching shell command with the Bash tool and report the resulting state in one line.

Resolve the directory first (same logic in every command):

```sh
DATA_DIR="$HOME/.claude/prompting-coach-data"; mkdir -p "$DATA_DIR"
```

- `on` — keep current `lang` if the file exists, else default `en`:

```sh
lang=$(sed -n 's/^lang=//p' "$DATA_DIR/config" 2>/dev/null); printf 'enabled=1\nlang=%s\n' "${lang:-en}" > "$DATA_DIR/config"
```

- `off`:

```sh
lang=$(sed -n 's/^lang=//p' "$DATA_DIR/config" 2>/dev/null); printf 'enabled=0\nlang=%s\n' "${lang:-en}" > "$DATA_DIR/config"
```

- `lang <code>` — keep current `enabled`, set language (e.g. `th`, `ja`, `pt`):

```sh
en=$(sed -n 's/^enabled=//p' "$DATA_DIR/config" 2>/dev/null); printf 'enabled=%s\nlang=%s\n' "${en:-1}" "<code>" > "$DATA_DIR/config"
```

- `status`:

```sh
cat "$DATA_DIR/config" 2>/dev/null || echo "enabled=1 (default, no config file)"
```

After writing, confirm to the user: current enabled state + language, and note that the
change takes effect from the next prompt (the hook runs per prompt).
