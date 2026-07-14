---
name: config
description: Configure english-coach. Usage - /english-coach:config on | off | level full|light | status
---

# english-coach config

Manage the english-coach plugin state. The state file is `key=value` lines at
`$HOME/.claude/english-coach-data/config` (the primary path). The plugin's UserPromptSubmit
hook reads this file first and falls back to `${CLAUDE_PLUGIN_DATA}/config` only when the
primary file does not exist. The hook reads on every prompt.

Keys: `enabled` (1|0, default 1), `level` (full|light, default full).
`level=light` = corrections and translations only: skip praise lines, skip the ✨ line,
skip Format C entirely; Format A/B still apply with mandatory 🎯.

## Behavior

Parse the argument (`on`, `off`, `level full|light`, `status`; no argument = `status`),
then run the matching shell command with the Bash tool and report the resulting state in
one line. Unknown argument → reply with the usage line from the description; do not write.

Resolve the directory first (same logic in every command):

```sh
DATA_DIR="$HOME/.claude/english-coach-data"; mkdir -p "$DATA_DIR"
```

- `on` — keep current `level` if the file exists, else default `full`:

```sh
lvl=$(sed -n 's/^level=//p' "$DATA_DIR/config" 2>/dev/null); printf 'enabled=1\nlevel=%s\n' "${lvl:-full}" > "$DATA_DIR/config"
```

- `off`:

```sh
lvl=$(sed -n 's/^level=//p' "$DATA_DIR/config" 2>/dev/null); printf 'enabled=0\nlevel=%s\n' "${lvl:-full}" > "$DATA_DIR/config"
```

- `level <value>` where `<value>` is `full` or `light` — keep current `enabled`:

```sh
en=$(sed -n 's/^enabled=//p' "$DATA_DIR/config" 2>/dev/null); printf 'enabled=%s\nlevel=%s\n' "${en:-1}" "<value>" > "$DATA_DIR/config"
```

- `status`:

```sh
cat "$DATA_DIR/config" 2>/dev/null || echo "enabled=1 level=full (default, no config file)"
```

After writing, confirm to the user: current enabled state + level, and note that the
change takes effect from the next prompt (the hook runs per prompt).
