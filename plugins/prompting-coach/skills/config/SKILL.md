---
name: config
description: Configure prompting-coach. Usage - /prompting-coach:config on | off | status
---

# prompting-coach config

Manage the prompting-coach gate. The state file is `key=value` lines at
`$HOME/.claude/prompting-coach-data/config` (the primary path). The gate hook reads this
file first and falls back to `${CLAUDE_PLUGIN_DATA}/config` only when the primary file
does not exist. The hook reads on every prompt.

The gate is a `command` hook that hands a short rubric to the main model, which judges
the prompt and opens an `AskUserQuestion` chooser when it finds a load-bearing gap. It
costs no extra model call — only the rubric's tokens.

Key: `enabled` (1|0, default 1). There is no `level`: the gate already fires only on
load-bearing gaps, which is what `level=light` meant.

## Behavior

Parse the argument (`on`, `off`, `status`; no argument = `status`), run the matching
shell command with the Bash tool, and report the resulting state in one line. Unknown
argument → reply with the usage line from the description; do not write.

Resolve the directory first (same logic in every command):

```sh
DATA_DIR="$HOME/.claude/prompting-coach-data"; mkdir -p "$DATA_DIR"
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

After writing, confirm the resulting state to the user and note that the change takes
effect from the next prompt (the hook runs per prompt).
