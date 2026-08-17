# claude-coach

Two opinionated coaching plugins for Claude Code:

- **prompting-coach** — a pre-flight gate. Severely under-specified requests open a
  chooser with a concrete rewritten prompt you can accept with one keypress. Prompts that
  are already clear pass straight through.
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

**prompting-coach** is a `command` hook that hands a ~1.2 KB rubric to the model already
running your turn. When it finds a load-bearing gap it opens a real `AskUserQuestion`
chooser:

```
╭──────────────────────────────────────╮
│  Prompt gate                         │
│                                      │
│ ❯ 1. ใช้ prompt ที่แนะนำ (Recommended)   │
│   2. ใช้ prompt เดิม                    │
│   3. Other                            │
╰──────────────────────────────────────╯
```

Option 1's preview holds the rewritten prompt, and "Other" is the edit path. There is no
sidecar and no second model call — the cost is the rubric's tokens, and the gate adds no
measurable latency of its own.

**english-coach** starts evaluating your prompt in a background sidecar the moment you
submit it, and delivers the block at the end of the same turn:

```
Stop says:
✻ English ──────────────────────────────
  EN · Can you explain React Server Components?
  กระชับ · Explain React Server Components.
─────────────────────────────────────────
```

Because the evaluation overlaps the main task, it usually adds no waiting at all — only a
short prompt answered instantly can outrun it. The block is delivered as a top-level
`systemMessage`, so it never enters the main model's context.

## Turning it off

- `/english-coach:config off`
- `/prompting-coach:config off`

Both take effect on your next prompt — each hook reads its config file per prompt.

`/english-coach:config level light` trims the block to corrections and translations only
(no praise, no concise row). prompting-coach has no levels: it already fires only on gaps
where guessing wrong wastes real work.

On Discord (OpenClaw), the `/coach` slash command controls the same knobs plus delivery
(`spoiler|plain|dm`).

## Known limitations

- english-coach needs an interactive session. Its background evaluation is started as an
  async hook, and `claude -p` terminates those child processes when it exits.
- Hooks are POSIX sh plus Python 3 — on Windows they require Git Bash (untested). If
  anything fails, prompts pass through untouched (fail-open).
- Hook output is rendered as dim plain text with no markdown, so english-coach blocks use
  box-drawing rules instead of headings and bold.
- prompting-coach gates only; it emits no per-prompt verdict block. Judging every prompt
  out loud would cost a visible turn on prompts that are already fine.
- english-coach costs one small-model call per prompt. prompting-coach costs none.
