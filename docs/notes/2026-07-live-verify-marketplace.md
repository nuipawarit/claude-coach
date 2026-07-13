# Live-verify: install both plugins from local marketplace (Task 8)

Date: 2026-07-14. Machine: this dev machine, which already has its own
user-level coaching hook (`COACHING ENFORCEMENT` in `~/.claude/settings.json`)
plus user skills `~/.claude/skills/prompting-coach` and
`~/.claude/skills/english-coach`. These are read-only for this task. Because
of that, every test session gets coaching signals from BOTH the machine setup
and the plugins — rendered output alone cannot prove the plugin's own
contribution. Verification below therefore checks two levels for each row:

- **Rendered level**: what actually shows up in the response text.
- **Mechanism level**: whether the plugin's own hook (`coach-enforce.sh`) ran
  and injected its distinctive text, captured via
  `claude -p --debug hooks --debug-file <path>` and grepping the debug log for
  the literal strings `PROMPTING-COACH ENFORCEMENT: ...` (ends in
  `Commentary language: <lang>.`) and `ENGLISH-COACH ENFORCEMENT: ...` — these
  strings are unique to the plugin hook and never appear in the machine's own
  `COACHING ENFORCEMENT` hook.

## Step 1 — install

```
claude plugin marketplace add ~/Projects/claude-coach
claude plugin install prompting-coach@claude-coach
claude plugin install english-coach@claude-coach
```

Both succeeded with no errors:

```
Adding marketplace…✔ Successfully added marketplace: claude-coach (declared in user settings)
Installing plugin "prompting-coach@claude-coach"...✔ Successfully installed plugin: prompting-coach@claude-coach (scope: user)
Installing plugin "english-coach@claude-coach"...✔ Successfully installed plugin: english-coach@claude-coach (scope: user)
```

`claude plugin list` confirms both `english-coach@claude-coach` and
`prompting-coach@claude-coach`, scope user, status enabled.

## Step 2 — test matrix (5 rows)

Each "new session" round used `claude -p "<prompt>" --dangerously-skip-permissions`
(each `-p` invocation is a fresh session that loads installed plugins and runs
their `UserPromptSubmit` hooks). Debug captured via
`--debug hooks --debug-file <path>`.

### Row 1 — `just make a dashboard` (fresh session) → expect Format G gate

**ผ่าน.**

Rendered output opened with:

```
> 🚧 **Prompt gate**: prompt too vague for substantial build — no target project, no data, no scope. Wrong guess wastes real work.
>
> **Suggested prompt (recommended):**
> "Build a dashboard in `<project — happywork-frontend? claude-coach?>` ..."
>
> **Or reply "use original"** — proceed as-is, Claude picks project, data, layout itself.
```

The gate path was taken instead of starting work — `AskUserQuestion` cannot
block in `-p` mode, so the model rendered the gate question as text instead of
invoking the interactive tool, exactly per the brief's caveat #3. Ended with
the english-coach block (Format B praise + level-up tip), as expected.

Mechanism-level: debug log contains both
`PROMPTING-COACH ENFORCEMENT: ... Commentary language: en.` and
`ENGLISH-COACH ENFORCEMENT: ...`.

### Row 2 — `fix the typo in README line 3` → expect verdict block (A/B) first, no gate

**ไม่ผ่าน (rendered) — mechanism ทำงานถูกต้อง.**

Ran 3 times. Mechanism level: every run, the debug log shows
`PROMPTING-COACH ENFORCEMENT: ... Commentary language: en.` fired correctly —
the hook is injecting its instruction every time, proven identical to the
text that DID produce a rendered verdict block in rows 1, 3, and 5.

Rendered level: all 3 runs skipped the prompting-coach verdict block entirely
(no `🧭`/`✅` prompt-coach line) and went straight to answering, then closed
with a valid english-coach block. Per `plugins/prompting-coach/skills/prompting-coach/SKILL.md`'s
decision tree, this prompt is not a skip case (not a slash command, not a code
paste, not a ≤5-word ack, not a reply to a gate) — a verdict block (Format A/B)
should have rendered.

Root-cause read: this is not a bug in `coach-enforce.sh` or `hooks.json` —
the injected instruction is byte-identical to the injections in the passing
rows and is delivered every single time. This looks like a model-compliance
gap under headless `-p` execution, likely compounded by this machine's global
caveman-mode customization (`~/.claude/CLAUDE.md` "Skip ★ Insight blocks —
fold anything load-bearing into the answer itself") causing the model to
treat the verdict block as droppable filler for a trivial one-line fix. No
plugin file change can force stricter instruction-following by the model, and
rewriting `~/.claude/CLAUDE.md` is out of scope (read-only per this task's
constraints). Recorded here as an honest concern, not "fixed."

### Row 3 — `ช่วยอธิบาย docker compose หน่อย` → expect english-coach Format A translation block

**ผ่าน.**

Rendered output opened with the prompting-coach verdict block
(`🧭 Prompt Coach: broad ask...`) and closed with:

```
> 🌐 **EN**: "Can you explain Docker Compose?"
> ✨ **กระชับ**: "Explain Docker Compose."
```

— a Format A translation block, at the tail of the response, as required.
Mechanism level: both `PROMPTING-COACH ENFORCEMENT: ... Commentary language: en.`
and `ENGLISH-COACH ENFORCEMENT: ...` present.

### Row 4 — `/prompting-coach:toggle off` then a new prompt → expect verdict block gone, english-coach block stays

**ไม่ผ่าน on first attempt → real plugin bug found and fixed → ผ่าน (mechanism-level) on re-run.**

First attempt (before fix): ran `/prompting-coach:toggle off`, which reported
`enabled=0` and wrote `~/.claude/prompting-coach-data/config`. Sent a new
prompt (`explain what a git rebase does`) — but the debug log STILL showed
`PROMPTING-COACH ENFORCEMENT: ...` firing, i.e. toggle-off did not silence
the hook at the mechanism level at all.

**Root cause** (confirmed via direct test — `claude -p "echo CLAUDE_PLUGIN_DATA=[$CLAUDE_PLUGIN_DATA]"`
returned `[]`, empty): `CLAUDE_PLUGIN_DATA` is set in the hook's own subprocess
environment (Claude Code spawns `coach-enforce.sh` with it pointing at
`~/.claude/plugins/data/prompting-coach-claude-coach/`) but is **not**
propagated into the Bash tool when the `/toggle` skill's shell commands run —
so `/toggle` always writes to the `$HOME/.claude/<plugin>-data` fallback,
while the hook (before the fix) preferred `CLAUDE_PLUGIN_DATA/config` — an
empty, different directory that never had a config file written to it. The
toggle command silently never reached the hook.

**Fix**: `plugins/prompting-coach/hooks/coach-enforce.sh` and
`plugins/english-coach/hooks/coach-enforce.sh` now read the fixed fallback
path (`$HOME/.claude/<plugin>-data/config`) first — the only path `/toggle`
can actually reach — and only fall back to `CLAUDE_PLUGIN_DATA/config` if the
fixed path was never written. Committed as `fix: read toggle config from the
path the toggle skill actually writes` (commit `421475a`).

Re-run after fix: `/prompting-coach:toggle off` → sent
`explain what a symlink is` → debug log now shows only
`ENGLISH-COACH ENFORCEMENT: ...`, **no** `PROMPTING-COACH ENFORCEMENT` line —
mechanism-level proof the toggle now works.

Rendered level: response still opened with a verdict-looking block
(`✅ Prompt ดีแล้ว...`) — this is the **machine's own** `COACHING ENFORCEMENT`
hook, not the plugin's (confirmed absent at the mechanism level above), exactly
the contamination the brief warned about. english-coach block still closed
the response correctly. Marked **ผ่าน (mechanism-level)** per the brief's
allowance for this exact row.

### Row 5 — `/prompting-coach:toggle lang th` + `on` then a prompt → expect verdict block back, Thai commentary

**ผ่าน.**

`/prompting-coach:toggle lang th` reported `enabled=0` (from row 4's off,
lang set to th), then `/prompting-coach:toggle on` reported `enabled=1,
lang=th`. Config file confirmed: `enabled=1` / `lang=th`.

Sent `explain what a git tag is` — rendered output opened with a fully-Thai
verdict block: `✅ Prompt ดีแล้ว! คำถามสั้น ตรงประเด็น...`. Mechanism level:
debug log shows `PROMPTING-COACH ENFORCEMENT: ... Commentary language: th.`
— language switch confirmed at both levels.

## Summary table

| # | ส่ง | ผลลัพธ์ |
|---|---|---|
| 1 | `just make a dashboard` | ผ่าน — Format G gate rendered as text (AskUserQuestion can't block in `-p`), english-coach block closed it |
| 2 | `fix the typo in README line 3` | ไม่ผ่าน (rendered) — mechanism fires correctly 3/3 but model dropped the verdict block; likely caveman-mode interaction, not a script bug |
| 3 | `ช่วยอธิบาย docker compose หน่อย` | ผ่าน — english-coach Format A translation block present |
| 4 | `/prompting-coach:toggle off` + new prompt | ผ่าน (mechanism-level) — real bug found (CLAUDE_PLUGIN_DATA mismatch) and fixed in commit `421475a`; rendered level still shows the machine's own coaching block (expected contamination) |
| 5 | `/prompting-coach:toggle lang th` + `on` + prompt | ผ่าน — verdict block back, Thai commentary confirmed at both levels |

## Fixes applied

- `421475a` — `fix: read toggle config from the path the toggle skill actually writes`
  (both `plugins/prompting-coach/hooks/coach-enforce.sh` and
  `plugins/english-coach/hooks/coach-enforce.sh`)

## Final state (left as required)

- Both plugins installed, scope user, status enabled (`claude plugin list`).
- `~/.claude/prompting-coach-data/config`: `enabled=1`, `lang=en`.
- `~/.claude/english-coach-data/config`: never toggled during this run — no
  file exists, which the hook's own default (`enabled=1`) treats as enabled.

## Open concern for follow-up

Row 2's rendered-level miss is a real, reproducible (3/3) gap in output
compliance even though the injected instruction is correct — worth watching
in future dogfooding, but not something fixable by editing this repo's
hook/skill files without also touching this machine's own (read-only, for
this task) global CLAUDE.md caveman configuration.
