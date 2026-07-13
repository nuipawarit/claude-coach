# claude-coach

Two opinionated coaching plugins for Claude Code:

- **prompting-coach** — every prompt you send gets a one-glance verdict against
  Anthropic's prompting best practices; severely under-specified requests get a
  confirm-first gate before any work starts. Commentary defaults to English and is
  configurable (`/prompting-coach:toggle lang th`).
- **english-coach** — built for Thai-speaking developers: every response ends with a
  compact English lesson based on the prompt you just wrote (translation, correction
  with a Thai why-tip, or praise plus a more idiomatic phrasing).

## Install

```
/plugin marketplace add nuipawarit/claude-coach
/plugin install prompting-coach@claude-coach
/plugin install english-coach@claude-coach
```

## How it works / Turning it off

Each plugin ships a UserPromptSubmit hook, so coaching runs on every turn by design.
Silence it anytime: /prompting-coach:toggle off · /english-coach:toggle off

## Known limitations

- Hooks are POSIX sh scripts - on Windows they require Git Bash (untested); if the hook
  fails, prompts pass through untouched (fail-open) and skills remain manually invocable.
- Coaching adds a small number of output tokens to each turn.
