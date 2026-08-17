# claude-coach

Two opinionated coaching plugins for Claude Code:

- **prompting-coach** — a pre-flight gate. Severely under-specified requests are stopped
  before any work starts, with a concrete rewritten prompt you can use instead. Prompts
  that are already clear pass straight through.
- **english-coach** — built for Thai-speaking developers: every response ends with a
  compact English lesson based on the prompt you just wrote (translation, correction
  with a Thai why-tip, or praise plus a more idiomatic phrasing).

## Install

```
/plugin marketplace add nuipawarit/claude-coach
/plugin install prompting-coach@claude-coach
/plugin install english-coach@claude-coach
```

## How it works

Neither plugin loads anything into your main context — the coaching logic runs in
separate small-model calls, not in your session.

**prompting-coach** is a `prompt` hook: a small model reads your prompt before work
begins and either passes it through or blocks with a suggested rewrite. Measured at
roughly one second over baseline.

**english-coach** starts evaluating your prompt in the background the moment you submit
it, and delivers the block at the end of the same turn. Because the evaluation overlaps
the main task, it usually adds no waiting at all — only a short prompt answered
instantly can outrun it.

## Turning it off

- `/english-coach:config off` — takes effect on your next prompt.
- `/prompting-coach:config off` — moves the hook file aside, so it takes effect in your
  **next session**. A `prompt` hook runs with no tools and cannot read a config file, so
  there is no runtime flag to flip.

`/english-coach:config level light` trims the block to corrections and translations only
(no praise, no concise line). prompting-coach has no levels: it already fires only on
gaps where guessing wrong wastes real work.

On Discord (OpenClaw), the `/coach` slash command controls the same knobs plus delivery
(`spoiler|plain|dm`).

## Known limitations

- english-coach needs an interactive session. Its background evaluation is started as an
  async hook, and `claude -p` terminates those child processes when it exits.
- english-coach hooks are POSIX sh plus Python 3 — on Windows they require Git Bash
  (untested). If anything fails, prompts pass through untouched (fail-open).
- prompting-coach gates only; it no longer emits a per-prompt verdict block. A `prompt`
  hook discards its reason when it lets a prompt through, so praise and tune-up feedback
  had nowhere to go.
- Each coach costs one small-model call per prompt.
