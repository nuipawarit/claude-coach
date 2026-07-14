<div align="center">

# 📣 claude-coach

**A coach on every prompt you send Claude Code — in the terminal and on Discord.**

[![site: live](https://img.shields.io/badge/site-live-2ea44f)](https://nuipawarit.github.io/claude-coach)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-8A63D2)](https://docs.claude.com/en/docs/claude-code/overview)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow)](./LICENSE)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)](#contributing)

[**Install**](#quick-start) · [**Configure**](#configure) · [**How it works**](#how-it-works) · [**Discord**](#on-discord-openclaw) · [**Live demo ↗**](https://nuipawarit.github.io/claude-coach)

</div>

---

Two opinionated coaching plugins that ride along on every turn. **prompting-coach**
grades each prompt against Anthropic's prompting best practices; **english-coach**
turns the same prompt into a bite-sized English lesson for Thai-speaking developers.
Both run automatically through a `UserPromptSubmit` hook — nothing to remember, no
wrapper command, no account. The coaching runs entirely inside your own Claude Code
session, and the same experience ships for Discord via [OpenClaw](#on-discord-openclaw).

```text
> 🧭 Prompting tune-up
> Gap: "make the API better" has no target — name what "better" means.
> Sharper prompt: "Make GET /users paginate at 50 items with a cursor."
> Principle: a concrete success criterion beats a vague adjective.

…Claude does the work…

──────────────────────────────
🇬🇧 English coach
You wrote: "ช่วยแก้ endpoint users หน่อย"
→ "Could you help me fix the users endpoint?"
💡 more idiomatic: "Mind taking a look at the users endpoint?"
```

<details>
<summary><strong>See the correction &amp; praise variants →</strong></summary>

```text
# You wrote broken English → correction + a Thai why-tip
🇬🇧 English coach
"i cant found the bug in this function"
→ "I can't find the bug in this function."
📝 หลัง can't ใช้ V.1 (find) ไม่ใช่ V.2 (found)

# You wrote it correctly → praise + a native-level upgrade
🇬🇧 English coach ✅ ประโยคถูกต้องแล้ว!
🎯 native: "I can't track down the bug in this function."
```

</details>

## Highlights

- ⚡ **Zero-friction** — fires on every turn via a hook; no command to remember.
- 🧭 **Prompt quality, live** — a one-glance verdict, plus a confirm-first gate that stops under-specified work *before* it starts.
- 🇬🇧 **English micro-lessons** — translation, correction with a Thai why-tip, or a native-level upgrade — tuned for Thai-speaking devs.
- 🔒 **Fully local** — hooks and skills run inside your session. No telemetry, no external calls, nothing leaves your machine.
- 🎚️ **Dial it in** — `off` / `on`, `light` / `full`, `TH` / `EN` — per plugin, anytime.
- 💬 **Discord too** — the same coaching via [OpenClaw](#on-discord-openclaw), with spoiler / plain / DM delivery.

## The two coaches

- **prompting-coach** — every prompt gets a one-glance verdict against Anthropic's
  prompting best practices. A clear-but-improvable prompt gets a tune-up (the single
  highest-leverage gap + a sharper rewrite); a severely under-specified request on
  substantial work gets a confirm-first gate *before* any work starts. Commentary
  defaults to English and is configurable (`/prompting-coach:config lang th`).
- **english-coach** — every response ends with a compact lesson based on the prompt
  you just wrote: a Thai prompt becomes natural English, an English prompt with
  mistakes is corrected with a Thai why-tip, and an already-correct prompt earns
  praise plus a more idiomatic phrasing.

## Quick start

```text
/plugin marketplace add nuipawarit/claude-coach
/plugin install prompting-coach@claude-coach
/plugin install english-coach@claude-coach
```

The two plugins are independent — install one or both.

## Configure

Both plugins are on by default. Every knob is a slash command:

| Command | Effect |
| --- | --- |
| `/prompting-coach:config off` · `/english-coach:config off` | Silence a coach |
| `/prompting-coach:config on` · `/english-coach:config on` | Turn it back on |
| `/…:config level light` | Load-bearing gaps / corrections only — no praise |
| `/…:config level full` | Full coaching, including praise (default) |
| `/prompting-coach:config lang th` | Switch prompting-coach commentary to Thai |
| `/…:config status` | Show current settings |

## How it works

Each plugin registers one `UserPromptSubmit` hook — a POSIX `sh` script that reads your
config (`~/.claude/<plugin>-data/config`) and injects the coaching instructions for that
turn. The heavy lifting lives in versioned **skills**, so the behavior is auditable and
editable in the repo, not baked into a binary.

The hook is **fail-open**: it always exits `0`. If anything goes wrong, your prompt
passes through untouched and the skills stay manually invocable — coaching never blocks
your work. And because every part runs locally in your Claude Code session, **your
prompts are never sent anywhere**.

## On Discord (OpenClaw)

The same coaching runs on Discord via [OpenClaw](https://github.com/openclaw/openclaw).
There, one `/coach` slash command controls the same on/off and level knobs **plus how
feedback is delivered** — `spoiler` (hidden behind a click), `plain`, or `dm`. Setup
files live in [`openclaw/`](./openclaw).

## FAQ

<details>
<summary><strong>Does it slow Claude down?</strong></summary>

Barely. Per prompt it runs one tiny local `sh` script (10-second timeout, fail-open) —
no network round-trip. The only real cost is a few extra output tokens per turn for the
verdict and the lesson.
</details>

<details>
<summary><strong>Will it nag on trivial messages?</strong></summary>

No. Skip rules cover slash commands, short acknowledgements, and pure code/error pastes.
Set `level light` to drop praise entirely and only surface load-bearing gaps.
</details>

<details>
<summary><strong>Can I install just one plugin?</strong></summary>

Yes — they're fully independent. Install `prompting-coach`, `english-coach`, or both.
</details>

<details>
<summary><strong>Where do my prompts go?</strong></summary>

Nowhere. The hooks and skills execute locally inside your Claude Code session. There is
no telemetry and no external service — remove the plugins and every trace is gone.
</details>

## Requirements

- **Claude Code** with plugin marketplace support (for the CLI plugins).
- **POSIX `sh`** for the hook scripts — present on macOS and Linux; on Windows they need
  Git Bash (untested). If a hook fails it fails *open*, so nothing breaks either way.

## Contributing

Issues and PRs are welcome. The layout is small:

<details>
<summary><strong>Repo layout</strong></summary>

```text
plugins/            the two Claude Code plugins (hooks + skills)
  prompting-coach/
  english-coach/
openclaw/           Discord (OpenClaw) coaching: /coach skill + patch
site/               landing page deployed to GitHub Pages
docs/               design notes and references
.claude-plugin/     marketplace manifest
```

</details>

If a coaching rule feels wrong, open an issue with the prompt and the output you
expected — the skills are plain Markdown and easy to tune.

## License

[MIT](./LICENSE) © nhui
