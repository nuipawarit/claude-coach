# Coach Skills Rollout — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** นำ prompting-coach + english-coach ออกเป็น plugin marketplace สาธารณะ (Track 1) และติดตั้งใช้เองบน Discord ผ่าน OpenClaw บน Mac (Track 2)

**Architecture:** repo เดียว (`~/Projects/claude-coach`) เป็นทั้ง marketplace + ที่เก็บ asset ของฝั่ง OpenClaw; enforcement ฝั่ง Claude Code ใช้ UserPromptSubmit hook ต่อ plugin + config ใน data dir, ฝั่ง OpenClaw ใช้ section ใน AGENTS.md + skills ฉบับ Discord (block ห่อ spoiler `||...||` เป็นข้อความท้ายแยก)

**Tech Stack:** Claude Code plugins (marketplace.json / plugin.json / hooks.json / SKILL.md), POSIX sh, OpenClaw (claude-cli runtime, Discord channel), git

**Spec:** `docs/superpowers/specs/2026-07-14-coach-skills-rollout-design.md` — อ่าน §3 (การตัดสินใจ), §4, §5 ก่อนเริ่ม

## Global Constraints

- **Verify แบบ live-verify ทุก task** — ไม่ใช้ TDD (ผู้ใช้เลือกแล้ว งานเป็น config/markdown; "มันคอมไพล์ได้/ไฟล์ถูกสร้าง" ไม่นับ ต้องเห็นพฤติกรรมจริง)
- **Git:** ห้าม commit ลง `main` ตรงๆ — งานทั้งหมดอยู่บน feature branch (`feat/marketplace-v1`, `feat/openclaw-discord`); merge เข้า `main` ด้วย `--no-ff` เมื่อจบ phase และ **หยุดถามก่อน push/tag เสมอ**; commit trailer ใช้มาตรฐานของ session ที่รัน
- **Secrets:** `DISCORD_BOT_TOKEN` อยู่ใน env เท่านั้น ห้ามอยู่ในไฟล์ที่ commit / ห้ามวางใน chat
- **Hook scripts:** POSIX sh ล้วน (ห้าม bash-ism, jq, node) และ fail-open — error ใดๆ ต้อง exit 0 ไม่ block prompt ผู้ใช้
- **Frontmatter `description` ของ skill ฝั่ง marketplace ≤ 300 ตัวอักษร** (listing budget ของเครื่องผู้ใช้อื่น)
- **Coaching block ฝั่ง Discord:** ข้อความแยกต่อท้ายเสมอ, ห่อ `||...||` คู่เดียวทั้งก้อน, ≤ 5 บรรทัด, ห้าม blockquote/ตาราง/heading
- **Version:** เริ่ม `0.1.0`, semver, bump ทุก release
- **License:** MIT
- **ภาษา:** เนื้อหา plugin ฝั่ง marketplace เป็นอังกฤษ (english-coach คง commentary ไทยตาม design เดิม); asset ฝั่ง OpenClaw เป็นไทย; code/commands/paths อังกฤษ verbatim
- **Source skills ต้นทาง (read-only ห้ามแก้):** `~/.claude/skills/prompting-coach/SKILL.md`, `~/.claude/skills/english-coach/SKILL.md`

---

## Phase 0 — ยืนยันข้อเท็จจริง + สกัด core

### Task 1: ยืนยันรายละเอียด API ที่ spec ติดธงไว้

**Files:**
- Create: `docs/notes/2026-07-api-verification.md`

**Interfaces:**
- Produces: ไฟล์ note ที่ task หลังอ้าง — คำตอบ 5 ข้อพร้อม URL ที่มา

- [ ] **Step 1: สร้าง branch**

```bash
cd ~/Projects/claude-coach && git checkout -b feat/marketplace-v1
```

- [ ] **Step 2: ตรวจ docs แล้วตอบ 5 ข้อ ลงไฟล์ note**

ใช้ WebFetch กับหน้าเหล่านี้ (ลิสต์อยู่ใน spec §9):
1. `${CLAUDE_PLUGIN_DATA}` มีจริงไหม + ค่า default path — จาก code.claude.com/docs/en/plugins-reference (ถ้าไม่มี: hook ใช้ fallback ที่ฝังไว้แล้วใน script ของ Task 5 ได้เลย ไม่ต้องแก้ design)
2. รูปแบบ slash เรียก skill ใน plugin — `/prompting-coach:toggle` ใช่ไหม — จาก docs/en/skills + plugins-reference
3. config key ตั้ง model ต่อ agent ของ OpenClaw (จะตั้งเป็น Sonnet) — จาก docs.openclaw.ai
4. คำสั่ง health-check ของ OpenClaw daemon (เช่น `openclaw status` หรือเทียบเท่า) — จาก docs.openclaw.ai/install
5. วิธีส่ง env (`DISCORD_BOT_TOKEN`) ให้ daemon ที่รันเป็น LaunchAgent — จาก docs.openclaw.ai/channels/discord (เช่น `launchctl setenv` หรือกลไก config ของ OpenClaw เอง)

รูปแบบไฟล์ note: หัวข้อละ 1 bullet — คำตอบ + URL + วันที่เช็ค

- [ ] **Step 3: Verify**

อ่านทวน: ทั้ง 5 ข้อมีคำตอบชัด ไม่มีข้อไหนว่าง ถ้าข้อไหน docs ไม่ระบุ ให้เขียน "ไม่พบใน docs — ใช้ fallback: <ระบุ>" พร้อมเหตุผล

- [ ] **Step 4: Commit**

```bash
git add docs/notes/2026-07-api-verification.md
git commit -m "docs: verify plugin data dir, slash naming, and openclaw config facts"
```

### Task 2: prompting-coach ฉบับ marketplace (EN default + config ภาษา)

**Files:**
- Create: `plugins/prompting-coach/skills/prompting-coach/SKILL.md`
- Read (source): `~/.claude/skills/prompting-coach/SKILL.md`

**Interfaces:**
- Produces: skill ที่อ่านบรรทัด `Commentary language: <lang>` ที่ hook (Task 5) inject; ชื่อ skill `prompting-coach`

- [ ] **Step 1: อ่าน source ทั้งไฟล์ แล้วเขียนฉบับใหม่ตามกติกาแปลงนี้ (ทำครบทุกข้อ)**

R1 — frontmatter ใหม่ (ใช้ตามนี้ตรงๆ):

```yaml
---
name: prompting-coach
description: Evaluate the user's newest prompt against Anthropic prompting best practices BEFORE any work; open the response with a compact verdict block (Format A/B), or gate a severely under-specified substantial request via AskUserQuestion (Format G). Enforced every turn by this plugin's hook.
---
```

R2 — แทนที่ section "Language of the Coaching Output" ทั้ง section ด้วย:

```markdown
## Language of the Coaching Output

Coaching commentary (verdict lines, gate questions, option descriptions) is written in the
language given by the hook-injected line `Commentary language: <lang>` (default `en`).
The improved prompt (gate preview or the `✍️ Try this` line) is ALWAYS written in the
user's own language — prompting effectiveness is language-independent, and the user must
be able to actually type it. Technical terms, principle names, file paths, and identifiers
stay in English verbatim regardless of language.
```

R3 — template labels เปลี่ยนเป็นอังกฤษ: `✍️ **ลองแบบนี้**` → `✍️ **Try this**`; ข้อความไทยใน template/ตัวอย่างของ Format A/B/G ทั้งหมดแปลเป็นอังกฤษธรรมชาติ (โครง blockquote + emoji + 📐 principle line คงเดิมเป๊ะ)

R4 — คำแปลมาตรฐานของวลีไทยที่โผล่ซ้ำใน Principle Catalog / examples:
- "ทำ X ให้หน่อย" → "just make X" · "ช่วยดู X หน่อย" → "take a look at X"
- "แก้เลย" → "fix it directly" · "แค่วิเคราะห์ ยังไม่ต้องแก้" → "analyze only, don't change anything yet"
- "ใส่ให้ครบ ทำเกินระดับพื้นฐาน" → "include everything relevant — go beyond the basics"
- "ห้ามใช้ X" → "don't use X" · "ทุก section" → "ALL sections"
วลีไทยอื่นนอกลิสต์: แปลเป็นอังกฤษธรรมชาติเองให้หมด — ห้ามเหลืออักษรไทยในไฟล์นี้เลย (ตรวจใน Step 2)

R5 — เนื้อหาที่คงเดิมทุกตัวอักษร: Decision Tree, Gate Rubric + caps, Effectiveness Checklist, Session Noise Control, Skip Rules, Edge Cases, "What this skill does NOT do", Sources (URL เดิม)

R6 — ห้ามอ้างถึง english-coach ตรงตัว — section interop ใช้คำว่า "a language-coaching skill" (source ใช้คำนี้อยู่แล้ว — คงไว้)

- [ ] **Step 2: Verify — ไม่มีอักษรไทยหลงเหลือ**

```bash
grep -P '[\x{0E00}-\x{0E7F}]' plugins/prompting-coach/skills/prompting-coach/SKILL.md | head
```
Expected: ไม่มี output · และ `description` ≤ 300 chars: `awk '/^description:/{print length($0)}' plugins/prompting-coach/skills/prompting-coach/SKILL.md` — expected ≤ 315 (รวมคำว่า description:)

- [ ] **Step 3: Commit**

```bash
git add plugins/prompting-coach/skills/prompting-coach/SKILL.md
git commit -m "feat: add prompting-coach marketplace edition (EN default, config language)"
```

### Task 3: english-coach ฉบับ marketplace (Thai-first คงเดิม)

**Files:**
- Create: `plugins/english-coach/skills/english-coach/SKILL.md`
- Read (source): `~/.claude/skills/english-coach/SKILL.md`

- [ ] **Step 1: คัดลอก source ทั้งไฟล์ โดยแก้เฉพาะ 2 จุด**

1. frontmatter ใหม่:

```yaml
---
name: english-coach
description: For Thai-speaking users - append an English-learning block at the END of every response. Translates Thai prompts to corrected English (Format A), corrects English errors with a Thai why-tip (Format B), or praises correct English and offers an idiomatic upgrade (Format C). Enforced by this plugin's hook.
---
```

2. สแกนหา reference ถึงสภาพแวดล้อมเครื่องต้นทาง (path `~/.claude/settings.json`, ชื่อ hook เครื่องหลัก, caveman) — จากการ audit ตอน brainstorm: **ไม่มี** — ถ้าเจอให้ตัดออกและจดไว้ใน commit message

- [ ] **Step 2: Verify**

```bash
diff <(sed '1,5d' ~/.claude/skills/english-coach/SKILL.md) <(sed '1,5d' plugins/english-coach/skills/english-coach/SKILL.md)
```
Expected: ต่างกันเฉพาะบรรทัด frontmatter ที่แก้ (ถ้า frontmatter เกิน 5 บรรทัด ปรับ `sed` ช่วงให้ครอบ) — เนื้อ body ต้องเหมือนเดิมทุกบรรทัด

- [ ] **Step 3: Commit**

```bash
git add plugins/english-coach/skills/english-coach/SKILL.md
git commit -m "feat: add english-coach marketplace edition (Thai-first)"
```

---

## Phase 1 — Marketplace repo

### Task 4: โครง marketplace + manifest ทั้งหมด

**Files:**
- Create: `.claude-plugin/marketplace.json`
- Create: `plugins/prompting-coach/.claude-plugin/plugin.json`
- Create: `plugins/english-coach/.claude-plugin/plugin.json`
- Create: `LICENSE`

**Interfaces:**
- Produces: ชื่อ marketplace `claude-coach`; ชื่อ plugin `prompting-coach`, `english-coach` — Task 8 ใช้ติดตั้ง

- [ ] **Step 1: เขียน `.claude-plugin/marketplace.json`**

```json
{
  "name": "claude-coach",
  "owner": { "name": "nhui" },
  "plugins": [
    {
      "name": "prompting-coach",
      "source": "./plugins/prompting-coach",
      "description": "Prompt-quality coach: verdict block on every response, pre-flight gate for under-specified requests. Turn off anytime with /prompting-coach:toggle off",
      "category": "productivity",
      "keywords": ["prompting", "coaching", "best-practices"]
    },
    {
      "name": "english-coach",
      "source": "./plugins/english-coach",
      "description": "English coaching for Thai developers: every prompt becomes a mini English lesson appended to the response. Turn off anytime with /english-coach:toggle off",
      "category": "learning",
      "keywords": ["english", "thai", "language-learning", "coaching"]
    }
  ]
}
```

- [ ] **Step 2: เขียน `plugins/prompting-coach/.claude-plugin/plugin.json`**

```json
{
  "name": "prompting-coach",
  "version": "0.1.0",
  "description": "Coach for prompt quality - evaluates every prompt against Anthropic's prompting best practices, opens responses with a compact verdict, and gates severely under-specified requests before work starts.",
  "author": { "name": "nhui" },
  "license": "MIT",
  "keywords": ["prompting", "coaching", "best-practices", "hooks"]
}
```

- [ ] **Step 3: เขียน `plugins/english-coach/.claude-plugin/plugin.json`**

```json
{
  "name": "english-coach",
  "version": "0.1.0",
  "description": "English coaching for Thai-speaking developers - appends a compact English-learning block to every response: translation, correction with Thai tips, or praise with idiomatic upgrades.",
  "author": { "name": "nhui" },
  "license": "MIT",
  "keywords": ["english", "thai", "language-learning", "coaching", "hooks"]
}
```

- [ ] **Step 4: เขียน `LICENSE`** — MIT license มาตรฐาน copyright `2026 nhui`

- [ ] **Step 5: Verify โครงถูกตำแหน่ง**

```bash
find . -path ./.git -prune -o -type f -print | sort
```
Expected เห็นครบ: `./.claude-plugin/marketplace.json`, `./plugins/<ทั้งสอง>/.claude-plugin/plugin.json`, SKILL.md ×2 จาก Task 2-3, LICENSE, docs/ — และ **ไม่มี** `skills/` หรือ `hooks/` อยู่ใต้ `.claude-plugin/` (กติกา layout จาก spec §4.1)

- [ ] **Step 6: Commit**

```bash
git add .claude-plugin plugins/*/.claude-plugin LICENSE
git commit -m "feat: add marketplace and plugin manifests"
```

### Task 5: Enforcement hooks ทั้งสอง plugin

**Files:**
- Create: `plugins/prompting-coach/hooks/hooks.json`
- Create: `plugins/prompting-coach/hooks/coach-enforce.sh`
- Create: `plugins/english-coach/hooks/hooks.json`
- Create: `plugins/english-coach/hooks/coach-enforce.sh`

**Interfaces:**
- Consumes: ผล Task 1 ข้อ 1 (`${CLAUDE_PLUGIN_DATA}` — script มี fallback ในตัวแล้ว ใช้ได้ทั้งสองกรณี)
- Produces: config format `key=value` ที่ Task 6 (toggle) เขียน — keys: `enabled` (`1`/`0`), `lang` (code เช่น `en`, `th`) · data dir: `${CLAUDE_PLUGIN_DATA:-$HOME/.claude/<plugin-name>-data}`

- [ ] **Step 1: เขียน `plugins/prompting-coach/hooks/hooks.json`**

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "sh \"${CLAUDE_PLUGIN_ROOT}/hooks/coach-enforce.sh\"",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: เขียน `plugins/prompting-coach/hooks/coach-enforce.sh`**

```sh
#!/bin/sh
# UserPromptSubmit hook: inject prompting-coach enforcement unless disabled.
# POSIX sh only. Fail-open: always exit 0.
DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/prompting-coach-data}"
CONF="$DATA_DIR/config"
enabled=1
lang=en
if [ -f "$CONF" ]; then
  while IFS='=' read -r k v; do
    case "$k" in
      enabled) enabled="$v" ;;
      lang) lang="$v" ;;
    esac
  done < "$CONF"
fi
[ "$enabled" = "0" ] && exit 0
printf '%s' "PROMPTING-COACH ENFORCEMENT: (1) BEFORE starting any work on this prompt, run the prompting-coach skill's pre-flight evaluation - a severe, load-bearing gap on substantial work means the Format G gate (AskUserQuestion) BEFORE any work; its skip rules and Gate Rubric apply. (2) When no gate fires, OPEN the response with the prompting-coach verdict block (Format A or B, exact template) as the FIRST element - omitted only when a skip rule applies. Commentary language: ${lang}."
exit 0
```

- [ ] **Step 3: เขียนฝั่ง english-coach — `hooks.json` เหมือน Step 1 ทุกตัวอักษร ส่วน `coach-enforce.sh`:**

```sh
#!/bin/sh
# UserPromptSubmit hook: inject english-coach enforcement unless disabled.
# POSIX sh only. Fail-open: always exit 0.
DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/english-coach-data}"
CONF="$DATA_DIR/config"
enabled=1
if [ -f "$CONF" ]; then
  while IFS='=' read -r k v; do
    case "$k" in
      enabled) enabled="$v" ;;
    esac
  done < "$CONF"
fi
[ "$enabled" = "0" ] && exit 0
printf '%s' "ENGLISH-COACH ENFORCEMENT: END every response with the english-coach block per the english-coach skill (exact template, the FINAL element of the final message of the turn - never mid-turn while background work is pending). Its skip rules apply (pure slash commands, short acks, pure pastes with zero narration)."
exit 0
```

- [ ] **Step 4: ทำ executable + live-verify script ตรงๆ**

```bash
chmod +x plugins/*/hooks/coach-enforce.sh
sh plugins/prompting-coach/hooks/coach-enforce.sh
```
Expected: ข้อความ enforcement ลงท้าย `Commentary language: en.`

```bash
mkdir -p /tmp/pc-data && printf 'enabled=0\n' > /tmp/pc-data/config
CLAUDE_PLUGIN_DATA=/tmp/pc-data sh plugins/prompting-coach/hooks/coach-enforce.sh
```
Expected: ไม่มี output, exit 0

```bash
printf 'enabled=1\nlang=th\n' > /tmp/pc-data/config
CLAUDE_PLUGIN_DATA=/tmp/pc-data sh plugins/prompting-coach/hooks/coach-enforce.sh
```
Expected: ลงท้าย `Commentary language: th.` — ทดสอบฝั่ง english-coach แบบเดียวกัน (on/off)

- [ ] **Step 5: Commit**

```bash
git add plugins/*/hooks
git commit -m "feat: add per-plugin UserPromptSubmit enforcement hooks"
```

### Task 6: Toggle skills ทั้งสอง plugin

**Files:**
- Create: `plugins/prompting-coach/skills/toggle/SKILL.md`
- Create: `plugins/english-coach/skills/toggle/SKILL.md`

**Interfaces:**
- Consumes: config format + data dir จาก Task 5 (ต้องตรงกันเป๊ะ)
- Consumes: ผล Task 1 ข้อ 2 — ถ้ารูปแบบ slash จริงต่างจาก `/prompting-coach:toggle` ให้แก้ข้อความ Usage ในไฟล์ + README (Task 7) ให้ตรงของจริง

- [ ] **Step 1: เขียน `plugins/prompting-coach/skills/toggle/SKILL.md`**

````markdown
---
name: toggle
description: Turn prompting-coach on or off, or set the coaching commentary language. Usage - /prompting-coach:toggle on | off | lang <code> | status
---

# prompting-coach toggle

Manage the prompting-coach plugin state. The state file is `key=value` lines at
`${CLAUDE_PLUGIN_DATA}/config`, falling back to `$HOME/.claude/prompting-coach-data/config`
when `CLAUDE_PLUGIN_DATA` is not set. The plugin's UserPromptSubmit hook reads this file
on every prompt.

## Behavior

Parse the argument (`on`, `off`, `lang <code>`, `status`; no argument = `status`), then run
the matching shell command with the Bash tool and report the resulting state in one line.

Resolve the directory first (same logic in every command):

```sh
DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/prompting-coach-data}"; mkdir -p "$DATA_DIR"
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
````

- [ ] **Step 2: เขียน `plugins/english-coach/skills/toggle/SKILL.md`** — โครงเดียวกับ Step 1 โดยเปลี่ยน: ชื่อ plugin ในข้อความเป็น english-coach, data dir fallback เป็น `$HOME/.claude/english-coach-data`, **ตัด subcommand `lang` ออกทั้งหมด** (english-coach เป็น Thai-first ไม่มี config ภาษา — Usage เหลือ `on | off | status` และไฟล์ config มีแค่บรรทัด `enabled=`)

- [ ] **Step 3: Verify เนื้อไฟล์**

```bash
grep -c 'prompting-coach-data' plugins/prompting-coach/skills/toggle/SKILL.md
grep -c 'english-coach-data' plugins/english-coach/skills/toggle/SKILL.md
grep -c 'lang' plugins/english-coach/skills/toggle/SKILL.md
```
Expected: ≥1, ≥1, `0` (ฝั่ง english-coach ต้องไม่เหลือเรื่อง lang)

- [ ] **Step 4: Commit**

```bash
git add plugins/*/skills/toggle
git commit -m "feat: add per-plugin toggle skills"
```

### Task 7: README + validate ทั้ง repo

**Files:**
- Create: `README.md`

- [ ] **Step 1: เขียน `README.md` (อังกฤษ) — เนื้อหาต้องครบหัวข้อเหล่านี้**

```markdown
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

/plugin marketplace add <github-owner>/claude-coach
/plugin install prompting-coach@claude-coach
/plugin install english-coach@claude-coach

## How it works / Turning it off

Each plugin ships a UserPromptSubmit hook, so coaching runs on every turn by design.
Silence it anytime: /prompting-coach:toggle off · /english-coach:toggle off

## Known limitations

- Hooks are POSIX sh scripts - on Windows they require Git Bash (untested); if the hook
  fails, prompts pass through untouched (fail-open) and skills remain manually invocable.
- Coaching adds a small number of output tokens to each turn.
```

แทน `<github-owner>` ด้วย GitHub username จริง ณ ตอน push (ถ้ายังไม่ push ให้คงไว้แล้วจดใน Task 9)
ปรับชื่อคำสั่ง toggle ให้ตรงผล Task 1 ข้อ 2 ทั้งไฟล์

- [ ] **Step 2: Validate ทั้ง repo**

```bash
claude plugin validate . --strict
```
Expected: ผ่าน ไม่มี error/warning — ถ้า fail: แก้ตามข้อความ error แล้วรันซ้ำจนผ่าน (ห้ามข้าม)

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add marketplace README"
```

### Task 8: Live-verify ติดตั้งจริงจาก local

**Files:** ไม่มีไฟล์ใหม่ (แก้ bug ที่เจอ = แก้ไฟล์เดิม + commit แยก)

- [ ] **Step 1: เพิ่ม marketplace จาก local path + ติดตั้งทั้งสอง plugin**

ในเซสชัน Claude Code (เครื่องนี้):
```
/plugin marketplace add ~/Projects/claude-coach
/plugin install prompting-coach@claude-coach
/plugin install english-coach@claude-coach
```
Expected: ติดตั้งสำเร็จทั้งคู่ ไม่มี error

- [ ] **Step 2: เปิด "เซสชันใหม่" แล้วยิงชุดทดสอบ — สังเกตผลจริงทีละข้อ**

| ส่ง | ต้องเห็น |
|---|---|
| `just make a dashboard` (เซสชันเปล่า) | Format G gate (AskUserQuestion) ก่อนเริ่มงาน — เพราะ deliverable กว้างบนงานใหญ่ |
| `fix the typo in README line 3` | verdict block (Format A/B) เป็น element แรก แล้วค่อยทำงาน — ไม่ gate |
| `ช่วยอธิบาย docker compose หน่อย` | ท้าย response มี english-coach block Format A (แปล EN) |
| `/prompting-coach:toggle off` แล้วส่ง prompt ใหม่ | verdict block หาย; english-coach block ยังอยู่ |
| `/prompting-coach:toggle lang th` + `on` แล้วส่ง prompt | verdict block กลับมา commentary เป็นไทย |

- [ ] **Step 3: บันทึกผล + แก้ที่พัง**

ผลแต่ละข้อจดลง `docs/notes/2026-07-live-verify-marketplace.md` (ผ่าน/ไม่ผ่าน + อาการ) — ข้อที่ไม่ผ่าน: แก้ไฟล์ที่เกี่ยว, commit เป็น `fix: ...` ราย issue, รันข้อนั้นซ้ำจนผ่านครบทุกแถว

- [ ] **Step 4: Commit note**

```bash
git add docs/notes/2026-07-live-verify-marketplace.md
git commit -m "docs: record marketplace live-verify results"
```

### Task 9: Merge เข้า main + จุดหยุดถาม push

- [ ] **Step 1: ตรวจก่อน merge**

```bash
claude plugin validate . --strict && git status --porcelain
```
Expected: validate ผ่าน + working tree สะอาด

- [ ] **Step 2: Merge --no-ff**

```bash
git checkout main
git merge --no-ff feat/marketplace-v1 -m "merge: marketplace v0.1.0 - prompting-coach + english-coach plugins"
```

- [ ] **Step 3: หยุด — ถามผู้ใช้ก่อนเสมอ (ห้ามทำเอง):**

ถาม 2 เรื่องผ่าน AskUserQuestion: (1) สร้าง GitHub repo + push เลยไหม (ต้องได้ GitHub username → อัปเดต `<github-owner>` ใน README ก่อน push) (2) tag `v0.1.0` เลยไหม — ทำตามคำตอบเท่านั้น

---

## Phase 2 — OpenClaw + Discord (branch ใหม่: `feat/openclaw-discord`)

### Task 10: Asset ฝั่ง OpenClaw ในตัว repo

**Files:**
- Create: `openclaw/AGENTS-coaching-section.md`
- Create: `openclaw/skills/prompting-coach-discord/SKILL.md`
- Create: `openclaw/skills/english-coach-discord/SKILL.md`
- Create: `openclaw/discord.patch.json5`
- Read (source): SKILL.md ฉบับ marketplace จาก Task 2-3

**Interfaces:**
- Produces: ไฟล์ทั้งหมดที่ Task 13 จะ copy ไป workspace — ชื่อ skill `prompting-coach-discord`, `english-coach-discord`

- [ ] **Step 1: สร้าง branch จาก main (หลัง Task 9 merge แล้ว)**

```bash
git checkout main && git checkout -b feat/openclaw-discord
```

- [ ] **Step 2: เขียน `openclaw/AGENTS-coaching-section.md` (จะถูก append เข้า AGENTS.md ของ workspace ใน Task 13) — ใช้ตามนี้ตรงๆ**

```markdown
## Coaching ทุกข้อความ (english-coach + prompting-coach)

1. ทุกข้อความ natural language ของผู้ใช้ → ทำ english-coach block ตาม skill
   `english-coach-discord` (Format A/B/C ตาม decision tree ในนั้น)
2. เฉพาะข้อความที่เป็นการสั่งงาน (ขอให้ทำ/สร้าง/วิเคราะห์/ค้น/แก้อะไรให้) → เพิ่มบรรทัด 🧭
   ตาม skill `prompting-coach-discord` — แชตสนทนาทั่วไปไม่มี prompt ให้โค้ช ห้ามใส่
3. Coaching ทั้งหมดส่งเป็น "ข้อความแยกต่างหาก" ต่อท้ายคำตอบหลักเสมอ (ข้อความที่สอง)
   ห่อทั้งก้อนใน spoiler `||...||` คู่เดียว
4. Block รวม ≤ 5 บรรทัด · ห้าม blockquote (`>`) · ห้ามตาราง · ห้าม heading — Discord render เพี้ยน
5. ข้าม coaching เมื่อ: ข้อความ ≤ 2 คำ (ok/ครับ/👍), สติกเกอร์/ไฟล์/ลิงก์ล้วนไม่มีข้อความ,
   หรือข้อความที่เป็นการตอบคำถามที่ bot เพิ่งถาม
```

- [ ] **Step 3: เขียน skill ฉบับ Discord สองตัว — แปลงจากฉบับ marketplace ด้วยกติกานี้**

`openclaw/skills/english-coach-discord/SKILL.md`:
- frontmatter: `name: english-coach-discord`, `description:` (ไทย สั้น): `โค้ชภาษาอังกฤษจากทุกข้อความแชตของผู้ใช้ — แปล/แก้/ชม พร้อมรูปแบบ block สำหรับ Discord (spoiler, ≤5 บรรทัด)`
- เนื้อหา: คัดจากฉบับ marketplace (Task 3) โดยแทน template ทุก Format จาก blockquote เป็น spoiler รูปนี้:

```
||🌐 EN: "<corrected English translation>"
✨ "<shorter version>"
🎯 "<more idiomatic version>" — <เหตุผลไทยสั้น>||
```

(Format B ใช้บรรทัด `คุณเขียน:` / `แก้ไข:` / `💡 <tip ไทย>` แบบไม่มี `>` นำ; Format C ใช้ `✅ <คำชมไทย>` — ทุกแบบห่อ `||...||` ทั้งก้อนเดียวเสมอ, ≤ 5 บรรทัด)
- ตัวอย่างในไฟล์เปลี่ยนเป็นบริบทแชต (ถามตารางนัด, เล่าเรื่องวันนี้, สั่ง bot เช็คของ) อย่างน้อย 3 ตัวอย่างครบ Format A/B/C
- Skip rules คงเดิม + เพิ่มข้อจาก AGENTS section ข้อ 5

`openclaw/skills/prompting-coach-discord/SKILL.md`:
- frontmatter: `name: prompting-coach-discord`, `description:` (ไทย): `โค้ชคุณภาพคำสั่งงานที่ผู้ใช้พิมพ์ถึง bot — ชี้ gap เดียวที่คุ้มสุด + ตัวอย่าง prompt ที่ดีกว่า เฉพาะข้อความสั่งงาน`
- เนื้อหาย่อจากฉบับ marketplace: เก็บ Effectiveness Checklist + Principle Catalog; **ตัด Format G gate ทิ้งทั้ง section** (บนแชตไม่มี AskUserQuestion — ห้ามหยุดรอ ให้ตอบไปเลยพร้อมโค้ช); output เหลือบรรทัดเดียวรูปนี้ (เป็นบรรทัดแรกใน spoiler block ร่วมกับ english-coach):

```
🧭 <gap สั้นๆ ภาษาไทย>: "<ตัวอย่าง prompt ที่ดีกว่า ภาษาเดียวกับผู้ใช้>"
```

- [ ] **Step 4: เขียน `openclaw/discord.patch.json5`**

```json5
{
  channels: {
    discord: {
      enabled: true,
      token: { source: "env", provider: "default", id: "DISCORD_BOT_TOKEN" },
      dmPolicy: "pairing",
      groupPolicy: "allowlist"
    }
  }
}
```

- [ ] **Step 5: Verify + Commit**

```bash
grep -c '||' openclaw/skills/english-coach-discord/SKILL.md   # expected ≥ 2 (มี template spoiler)
grep -c 'Format G' openclaw/skills/prompting-coach-discord/SKILL.md   # expected 0
git add openclaw && git commit -m "feat: add openclaw workspace assets (AGENTS section, discord skills, channel patch)"
```

### Task 11: ติดตั้ง OpenClaw daemon บน Mac

**Files:** ไม่มีไฟล์ใน repo (การกระทำบนเครื่อง) — ผลจดลง `docs/notes/2026-07-openclaw-install.md`

**Interfaces:**
- Consumes: Task 1 ข้อ 3 (model config key), ข้อ 4 (health-check command)

- [ ] **Step 1: ติดตั้ง + onboard**

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
openclaw onboard --install-daemon
```
ระหว่าง onboard: เลือก provider **"Claude CLI"** (reuse Claude Max login ของเครื่องนี้ — ห้ามใส่ API key) และตั้ง model เป็น Sonnet ด้วย config key ที่ยืนยันใน Task 1 ข้อ 3

- [ ] **Step 2: Verify daemon จริง**

```bash
launchctl list | grep -i openclaw
```
Expected: มีบรรทัด LaunchAgent พร้อม PID · แล้วรัน health-check command จาก Task 1 ข้อ 4 — expected: gateway running/healthy

- [ ] **Step 3: จด note + commit**

```bash
git add docs/notes/2026-07-openclaw-install.md
git commit -m "docs: record openclaw daemon install result"
```

### Task 12: Discord bot + เชื่อม channel (มีจุดรอผู้ใช้)

**Files:** ไม่มีไฟล์ใหม่ — ใช้ `openclaw/discord.patch.json5` จาก Task 10

- [ ] **Step 1: จุดรอผู้ใช้ — แจ้งให้ผู้ใช้ทำเอง แล้วหยุดรอจนยืนยันเสร็จ:**

1. เข้า https://discord.com/developers/applications → New Application ตั้งชื่อ (เช่น "nhui coach")
2. เมนู Bot → Reset Token → คัดลอก token เก็บเอง (**ห้ามวางใน chat**)
3. เปิด **MESSAGE CONTENT INTENT** ในหน้า Bot
4. ตั้ง env ให้ daemon เห็น ด้วยกลไกที่ยืนยันใน Task 1 ข้อ 5 (เช่น `launchctl setenv DISCORD_BOT_TOKEN <token>` แล้ว restart daemon — ผู้ใช้รันเองในเครื่อง)

- [ ] **Step 2: Apply patch + restart**

```bash
openclaw config patch --file ~/Projects/claude-coach/openclaw/discord.patch.json5
```
แล้ว restart daemon ตามวิธีของ OpenClaw (จาก docs ที่เช็คใน Task 1)

- [ ] **Step 3: Verify การเชื่อม**

ผู้ใช้เปิด Discord: bot ต้องขึ้น Online · ส่ง DM หาแล้วทำ pairing ตาม flow `dmPolicy: "pairing"` — expected: bot ตอบกลับได้ใน DM

### Task 13: Deploy asset เข้า workspace + live-verify บน Discord จริง

**Files:** copy จาก `openclaw/` ไป workspace ของ OpenClaw (path จริงยืนยันจาก `openclaw onboard` output ใน Task 11 — ค่า default ตาม docs คือ workspace ใต้ `~/.openclaw/`)

- [ ] **Step 1: Copy**

```bash
WS=<workspace path จาก Task 11>
mkdir -p "$WS/skills"
cp -R ~/Projects/claude-coach/openclaw/skills/prompting-coach-discord "$WS/skills/"
cp -R ~/Projects/claude-coach/openclaw/skills/english-coach-discord "$WS/skills/"
cat ~/Projects/claude-coach/openclaw/AGENTS-coaching-section.md >> "$WS/AGENTS.md"
```
แล้ว restart daemon/session ให้ AGENTS.md โหลดใหม่ (โหลดครั้งเดียวตอน session start — spec §5.2)

- [ ] **Step 2: Live-verify — ผู้ใช้ส่ง DM สามแบบ สังเกตของจริง**

| ส่งใน DM | ต้องเห็น |
|---|---|
| `วันนี้เหนื่อยมากเลย` | ข้อความตอบปกติ + ข้อความที่สองเป็น spoiler เดียว มี 🌐 EN (ไม่มีบรรทัด 🧭) |
| `ช่วยสรุปว่าพรุ่งนี้ผมต้องทำอะไรบ้าง` | ข้อความที่สอง spoiler มีทั้ง 🧭 (โค้ช prompt) และ 🌐 EN |
| `Can you check my calendar tomorrow?` | spoiler มี ✅ ชม หรือแก้ไวยากรณ์ (Format C/B) เป็นไทย |

เช็คเพิ่ม: กด spoiler แล้วเปิดอ่านได้ปกติ, block ≤ 5 บรรทัด, ไม่มี `>` หรือตารางโผล่, ข้อความหลักไม่โดนปน block

- [ ] **Step 3: แก้ที่พัง + จด + commit**

อาการที่พัง: แก้ไฟล์ใน `openclaw/` ของ repo → copy ทับ → restart → ทดสอบซ้ำ (แก้ที่ source ใน repo เสมอ ไม่แก้ตรงที่ workspace เพื่อให้ repo เป็น source of truth) · ผลจดลง `docs/notes/2026-07-live-verify-discord.md`

```bash
git add docs/notes/2026-07-live-verify-discord.md openclaw
git commit -m "docs: record discord live-verify results"
```

- [ ] **Step 4: Merge + จุดหยุดถาม**

```bash
git checkout main
git merge --no-ff feat/openclaw-discord -m "merge: openclaw discord coaching v1"
```
แล้วหยุดถามผู้ใช้: push ไหม (ถ้า repo ขึ้น GitHub แล้วจาก Task 9)

### Task 14 (OPTIONAL — ทำเมื่อผู้ใช้สั่งเท่านั้น): ย้ายเครื่องหลักมาใช้ plugin ตัวเอง

- [ ] **Step 1:** ติดตั้งจาก marketplace ตัวเอง (Task 8 ทำไว้แล้ว — ตรวจว่ายัง installed)
- [ ] **Step 2:** ลบของเดิมเพื่อกันซ้ำซ้อน: ย้าย `~/.claude/skills/prompting-coach` + `~/.claude/skills/english-coach` ไป backup (`~/.claude/skills-backup-2026-07/`) และลบ echo COACHING ENFORCEMENT ออกจาก `UserPromptSubmit` hooks ใน `~/.claude/settings.json` (เก็บ hook อื่นไว้ครบ)
- [ ] **Step 3: Live-verify:** เซสชันใหม่ — verdict block + english block ยังทำงานครบเหมือนเดิม (คราวนี้มาจาก plugin) · rollback = ย้าย backup กลับ + คืนบรรทัด echo

---

## Self-review (ทำแล้ว)

- ครอบ spec: §4.1→Task 4, §4.2→Task 5+6, §4.3→Task 2+3, §4.4→Task 4, §4.5→Task 7+8+9, §5.1→Task 11+12, §5.2/5.3→Task 10, §5.4→Task 10, §6 optional row→Task 14, §7 ธง verify→Task 1
- Placeholder scan: `<github-owner>` (รอ username จริงตอน push — จุดถามอยู่ Task 9), `<workspace path จาก Task 11>`, `<token>` (ผู้ใช้ถือเอง) — ทั้งหมดเป็นค่าที่ต้องมาจากคนหรือ runtime พร้อมจุดได้มาระบุชัด ไม่ใช่ TBD
- ชื่อสอดคล้อง: config keys `enabled`/`lang`, data dirs `prompting-coach-data`/`english-coach-data`, skill names `toggle`, `*-discord` — ตรงกันทุก task ที่อ้าง
