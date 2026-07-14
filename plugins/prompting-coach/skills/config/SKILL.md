---
name: config
description: Configure prompting-coach. Usage - /prompting-coach:config on | off | level full|light | lang <code> | status
---

# prompting-coach config

Manage the prompting-coach plugin state. The state file is `key=value` lines at
`$HOME/.claude/prompting-coach-data/config` (the primary path). The plugin's UserPromptSubmit
hook reads this file first and falls back to `${CLAUDE_PLUGIN_DATA}/config` only when the
primary file does not exist. The hook reads on every prompt.

Keys: `enabled` (1|0, default 1), `lang` (commentary language code, default en),
`level` (full|light, default full). `level=light` = emit the verdict block only for
load-bearing gaps (a wrong guess wastes real work); skip Format B praise blocks.

## Behavior

Parse the argument (`on`, `off`, `level full|light`, `lang <code>`, `status`;
no argument = `status`), then run the matching shell command with the Bash tool and report
the resulting state in one line. Unknown argument → reply with the usage line from the
description; do not write.

Resolve the directory first (same logic in every command):

```sh
DATA_DIR="$HOME/.claude/prompting-coach-data"; mkdir -p "$DATA_DIR"
```

Read current values first (same pattern in every write command):

```sh
en=$(sed -n 's/^enabled=//p' "$DATA_DIR/config" 2>/dev/null)
lang=$(sed -n 's/^lang=//p' "$DATA_DIR/config" 2>/dev/null)
lvl=$(sed -n 's/^level=//p' "$DATA_DIR/config" 2>/dev/null)
```

- `on`:

```sh
printf 'enabled=1\nlang=%s\nlevel=%s\n' "${lang:-en}" "${lvl:-full}" > "$DATA_DIR/config"
```

- `off`:

```sh
printf 'enabled=0\nlang=%s\nlevel=%s\n' "${lang:-en}" "${lvl:-full}" > "$DATA_DIR/config"
```

- `level <value>` where `<value>` is `full` or `light`:

```sh
printf 'enabled=%s\nlang=%s\nlevel=%s\n' "${en:-1}" "${lang:-en}" "<value>" > "$DATA_DIR/config"
```

- `lang <code>` (e.g. `th`, `ja`, `pt`):

```sh
printf 'enabled=%s\nlang=%s\nlevel=%s\n' "${en:-1}" "<code>" "${lvl:-full}" > "$DATA_DIR/config"
```

- `status`:

```sh
cat "$DATA_DIR/config" 2>/dev/null || echo "enabled=1 lang=en level=full (default, no config file)"
```

After writing, confirm to the user: current enabled state + lang + level, and note that
the change takes effect from the next prompt (the hook runs per prompt).
