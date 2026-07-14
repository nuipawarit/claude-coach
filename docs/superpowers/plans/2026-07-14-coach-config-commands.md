# Coach Config Commands Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** เพิ่ม slash command ปรับแต่ง coaching skills — `/coach` บน Discord (OpenClaw) และ `/english-coach:config` + `/prompting-coach:config` บน Claude CLI — persist ข้าม session ทั้งสองฝั่ง

**Architecture:** ฝั่ง OpenClaw = workspace skill `user-invocable: true` (ลงทะเบียนเป็น Discord slash command อัตโนมัติ, reply ephemeral by default) เขียนไฟล์ `key=value` ที่ `~/.openclaw/workspace/coach-config`; AGENTS.md coaching section อ่านไฟล์นี้ก่อนทำ coaching ทุกข้อความ ฝั่ง CLI = ขยาย skill `toggle` เดิมเป็น `config` (เพิ่ม key `level`) โดย hook `coach-enforce.sh` อ่าน key แล้วปรับข้อความ enforcement

**Tech Stack:** OpenClaw workspace skills (SKILL.md), Claude Code plugin skills + UserPromptSubmit hooks (POSIX sh), Docker compose deploy

**Testing mode (ตกลงกับผู้ใช้แล้ว):** live-verify — ห้ามใช้ TDD; พิสูจน์ด้วยการรันจริง

## Global Constraints

- Spec: `docs/superpowers/specs/2026-07-14-coach-config-commands-design.md`
- ทุกคำสั่ง docker compose ต้องมี `-f docker-compose.yml -f docker-compose.extra.yml` เสมอ (ไม่งั้น container ไม่มี claude binary → `write EPIPE`)
- Hook scripts: POSIX sh เท่านั้น, fail-open (`exit 0` เสมอ), รองรับ CRLF + ไฟล์ไม่มี trailing newline (pattern เดิม)
- ห้าม commit/push จนกว่า live-verify ผ่านครบ — จบงาน: commit + push ทั้งหมดรวมของค้าง 4 ไฟล์ two-spoiler (ผู้ใช้อนุมัติ 2026-07-14)
- ห้ามรัน test suite ทั้ง project
- Browser verify: dispatch implementer เท่านั้น (main ห้ามแตะ chrome-devtools), serialize ทีละ dispatch, ทุก dispatch prompt ต้องมีบรรทัด dialog-handling verbatim: "If a chrome-devtools call stalls or times out, call handle_dialog first, then retry once; if still stuck, stop browser work and report state." + budget ~50 tool calls
- Discord spoiler ตรวจระดับ DOM ผ่าน `evaluate_script` อ่าน `span.spoilerContent` (คลิก reveal ไม่ได้)
- เมื่อ format เปลี่ยน ให้ส่ง `/new` ใน Discord ก่อน verify (กัน history mimicry)
- Defaults ทุก knob: `prompt_coach=on`, `english_coach=on`, `level=full`, `delivery=spoiler`; CLI: `enabled=1`, `level=full`, (prompting) `lang=en`

---

### Task 1: OpenClaw skill `/coach` (repo source)

**Files:**
- Create: `openclaw/skills/coach/SKILL.md`

**Interfaces:**
- Produces: ไฟล์ config `~/.openclaw/workspace/coach-config` รูปแบบ `key=value` 4 keys: `prompt_coach`, `english_coach`, `level`, `delivery` — Task 2/3 อ้าง key เหล่านี้ตรงตัว

- [ ] **Step 1: เขียนไฟล์ skill**

เนื้อหาเต็มของ `openclaw/skills/coach/SKILL.md`:

````markdown
---
name: coach
description: ปรับแต่ง coaching (prompting-coach + english-coach) — /coach status | prompt on|off | english on|off | level full|light | delivery spoiler|plain|dm
user-invocable: true
disable-model-invocation: true
---

# coach — config command

จัดการไฟล์ config ของ coaching skills: `coach-config` ที่ root ของ workspace
(path เดียวกับ AGENTS.md) รูปแบบ `key=value` บรรทัดละคู่ 4 keys เสมอ:

```
prompt_coach=on
english_coach=on
level=full
delivery=spoiler
```

## Grammar

| Command | ผล |
|---|---|
| `/coach` หรือ `/coach status` | รายงานค่าปัจจุบันทุก key |
| `/coach prompt on\|off` | ตั้ง `prompt_coach` |
| `/coach english on\|off` | ตั้ง `english_coach` |
| `/coach level full\|light` | ตั้ง `level` |
| `/coach delivery spoiler\|plain\|dm` | ตั้ง `delivery` |

## Behavior

1. Parse argument ตาม grammar ข้างบน — argument ไม่ตรง grammar (key ผิด, ค่าผิด,
   เกิน 2 คำ) → ตอบ usage 1 บรรทัด: `usage: /coach status | prompt on|off | english on|off | level full|light | delivery spoiler|plain|dm` ห้ามแก้ไฟล์
2. `status`: อ่าน `coach-config` — ไฟล์ไม่มี → รายงาน default ทุก key พร้อมหมายเหตุ
   `(default — ยังไม่มีไฟล์ config)` ตอบ key ละบรรทัด
3. คำสั่งตั้งค่า: อ่านไฟล์เดิมถ้ามี → เปลี่ยนเฉพาะ key ที่สั่ง → เขียนกลับ**ครบทั้ง 4 keys**
   (key ที่ไม่เคยตั้งใช้ default) → ตอบยืนยัน 1 บรรทัด เช่น `level=light แล้ว — มีผลตั้งแต่ข้อความถัดไป`
4. ห้ามทำอย่างอื่น: ไม่แตะไฟล์อื่น ไม่ตอบคำถามอื่น ไม่ใส่ coaching block ใน reply ของ command นี้
````

- [ ] **Step 2: ตรวจ frontmatter ถูก syntax**

Run: `python3 -c "import pathlib,re; t=pathlib.Path('openclaw/skills/coach/SKILL.md').read_text(); m=re.match(r'^---\n(.*?)\n---\n', t, re.S); assert m and 'name: coach' in m.group(1) and 'user-invocable: true' in m.group(1); print('frontmatter OK')"`
Expected: `frontmatter OK`

---

### Task 2: AGENTS coaching section — rule 0 (config read)

**Files:**
- Modify: `openclaw/AGENTS-coaching-section.md` (แทรกก่อน rule 1 เดิม)

**Interfaces:**
- Consumes: ไฟล์ `coach-config` + keys จาก Task 1

- [ ] **Step 1: แทรก rule 0**

แทรก block นี้ระหว่างบรรทัดหัวข้อ `## Coaching ทุกข้อความ (english-coach + prompting-coach)` กับ rule `1.` เดิม:

```markdown
0. ก่อนสร้าง coaching block ทุกครั้ง: อ่านไฟล์ `coach-config` ที่ root ของ workspace
   (ไฟล์ไม่มี/อ่านไม่ได้ = default: prompt_coach=on, english_coach=on, level=full,
   delivery=spoiler — ห้าม error)
   - `prompt_coach=off` → ไม่มี 🧭 block · `english_coach=off` → ไม่มี english block
     · ทั้งคู่ off → ตอบปกติ ไม่มี coaching เลย
   - `level=light` → 🧭 เฉพาะ gap ที่ load-bearing จริง (เดาผิดแล้วงานเสีย — gap
     เล็กน้อยข้าม block); english block ตัดบรรทัด ✨ และคำชมทั้งหมด, Format C
     ข้ามทั้งก้อน (Format A/B ยังทำงาน 🎯 ยังบังคับ)
   - `delivery=plain` → เนื้อหา block เดิมทุกบรรทัดแต่ไม่ห่อ `||...||`
     · `delivery=dm` → คำตอบหลักส่งที่ช่องเดิมตามปกติ ส่วน coaching ทุก section
     ส่งเป็น DM แยกถึงผู้ใช้ (message tool) ขึ้นต้นด้วย quote ข้อความต้นทาง
     `> <ข้อความผู้ใช้>` — ส่ง DM ไม่ได้ → fallback เป็น spoiler ในข้อความหลัก
     พร้อมบรรทัดแจ้งสั้นๆ ว่า DM ล้มเหลว
```

> **หมายเหตุ (superseded):** bullet `delivery=dm` ในบล็อกข้างบนเป็นฉบับก่อนแก้ — live-verify พบ bug คำตอบหลักหายเมื่อเปิด dm mode จึง harden ข้อความแล้ว ใช้ฉบับจริงจาก `openclaw/AGENTS-coaching-section.md` (บังคับคำตอบหลักเต็มเสมอ ห้ามแทนที่ด้วยข้อความยืนยันการส่ง) เป็น source of truth

- [ ] **Step 2: ตรวจว่า rule เดิม 1-7 ยังอยู่ครบ**

Run: `grep -c '^[0-9]\.' openclaw/AGENTS-coaching-section.md`
Expected: `8`

---

### Task 3: Discord SKILL.md ×2 — config awareness

**Files:**
- Modify: `openclaw/skills/prompting-coach-discord/SKILL.md` (ต่อท้าย intro paragraph)
- Modify: `openclaw/skills/english-coach-discord/SKILL.md` (ต่อท้าย intro paragraph)

**Interfaces:**
- Consumes: keys จาก Task 1, พฤติกรรมจาก rule 0 (Task 2)

- [ ] **Step 1: เพิ่ม section ใน prompting-coach-discord/SKILL.md**

แทรกหลัง intro paragraph (ก่อน `## Chat rule — never gate, always answer`):

```markdown
## Config awareness

การเปิด/ปิดและรูปแบบ ควบคุมด้วยไฟล์ `coach-config` ตาม AGENTS section rule 0:
`prompt_coach=off` → ไม่มี block นี้ทั้งก้อน · `level=light` → โค้ชเฉพาะ gap ที่
load-bearing จริง (gap เล็กน้อย = ไม่มี block) · `delivery` เปลี่ยนเฉพาะการห่อ/ช่องทางส่ง
(spoiler/plain/dm) — เนื้อหา 3 บรรทัดคงเดิมทุกกรณี
```

- [ ] **Step 2: เพิ่ม section ใน english-coach-discord/SKILL.md**

แทรกหลัง intro paragraph (ก่อน `## When to trigger`):

```markdown
## Config awareness

การเปิด/ปิดและรูปแบบ ควบคุมด้วยไฟล์ `coach-config` ตาม AGENTS section rule 0:
`english_coach=off` → ไม่มี block นี้ทั้งก้อน · `level=light` → ตัดบรรทัด ✨ และคำชม
ทั้งหมด, Format C ข้ามทั้งก้อน — Format A/B ยังทำงานและ 🎯 ยังบังคับ · `delivery`
เปลี่ยนเฉพาะการห่อ/ช่องทางส่ง (spoiler/plain/dm) — เนื้อหา block คงเดิม
```

- [ ] **Step 3: ตรวจทั้งสองไฟล์มี section**

Run: `grep -l '## Config awareness' openclaw/skills/*/SKILL.md`
Expected: ทั้งสอง path

---

### Task 4: Deploy + live-verify บน Discord

**Files:**
- Deploy เท่านั้น (คัดลอกจาก repo ไป `~/.openclaw/workspace/`)

**Interfaces:**
- Consumes: ทุกไฟล์จาก Task 1-3

- [ ] **Step 1: Deploy skills + AGENTS section**

```bash
mkdir -p ~/.openclaw/workspace/skills/coach
cp openclaw/skills/coach/SKILL.md ~/.openclaw/workspace/skills/coach/SKILL.md
cp openclaw/skills/prompting-coach-discord/SKILL.md ~/.openclaw/workspace/skills/prompting-coach-discord/SKILL.md
cp openclaw/skills/english-coach-discord/SKILL.md ~/.openclaw/workspace/skills/english-coach-discord/SKILL.md
python3 - <<'EOF'
import pathlib
agents = pathlib.Path.home() / '.openclaw/workspace/AGENTS.md'
text = agents.read_text()
marker = '## Coaching ทุกข้อความ'
idx = text.find(marker)
assert idx != -1, 'marker not found'
new_section = pathlib.Path('openclaw/AGENTS-coaching-section.md').read_text()
agents.write_text(text[:idx] + new_section)
EOF
```

(script นี้ assume ว่า coaching section เป็น section สุดท้ายของ `~/.openclaw/workspace/AGENTS.md` — ทุกอย่างหลัง marker ถูกแทนที่ทั้งหมด; เป็นจริงใน workspace ปัจจุบัน)

- [ ] **Step 2: Restart gateway + health poll**

```bash
cd ~/Projects/openclaw && docker compose -f docker-compose.yml -f docker-compose.extra.yml restart openclaw-gateway
for i in {1..12}; do sleep 5; curl -fsS http://127.0.0.1:18789/healthz && curl -fsS http://127.0.0.1:18789/readyz && break; done
```

Expected: `{"ok":true,...}` + `{"ready":true}`

- [ ] **Step 3: Verify command registration + status (implementer dispatch, browser)**

Dispatch implementer (sonnet, serialized, dialog line verbatim, budget ~50 calls): ใน Discord DM ของ bot —
1. พิมพ์ `/coach` ใน message box → command picker ต้องแสดง command `coach` พร้อม description
2. ส่ง `/coach status` → reply (ephemeral) รายงาน 4 keys ค่า default
3. รายงานผลเป็นข้อความ (ห้ามส่ง screenshot กลับ main)

Expected: command โผล่ + status ตอบ default ครบ — ถ้า command ไม่โผล่: รอ 1-2 นาที (Discord global command propagation) แล้ว reload (Ctrl+R) ก่อนสรุป fail

- [ ] **Step 4: Verify knobs — level/off/on (dispatch เดียวกันต่อ หรือ dispatch ใหม่)**

1. `/coach level light` → เช็คไฟล์ host: `cat ~/.openclaw/workspace/coach-config` มี `level=light` (main รันเองได้ — ไม่ใช่ browser งาน)
2. ส่ง `/new` แล้วส่งข้อความไทยธรรมดา (เช่น `วันนี้อากาศดีจัง`) → english spoiler ต้องไม่มีบรรทัด ✨/คำชม (ตรวจ DOM `span.spoilerContent`)
3. `/coach english off` → `/new` → ส่งข้อความไทย → ไม่มี english block เลย
4. `/coach english on` + `/coach level full` → คืนค่า

- [ ] **Step 5: Verify delivery=dm**

1. `/coach delivery dm` → `/new` → ส่งข้อความสั่งงานสั้น → คำตอบหลักอยู่ช่องเดิม + coaching มาเป็น DM แยก quote ข้อความต้นทาง
2. ถ้า DM ไม่มา: ตรวจว่า fallback spoiler ทำงาน + มีบรรทัดแจ้ง — บันทึกผลจริงลง note (อย่าฝืน)
3. `/coach delivery spoiler` คืนค่า

- [ ] **Step 6: Regression — spec สอง spoiler เดิม**

`/new` → ส่งข้อความสั่งงาน (เช่น `ช่วยคิดเมนูมื้อเย็นให้หน่อย`) → สอง spoiler แยก section + bold labels ครบตาม spec ปัจจุบัน (DOM level)

- [ ] **Step 7: บันทึกผลลง note**

ต่อท้าย `docs/notes/2026-07-live-verify-discord.md`: ผลทุกข้อ รวม dm ได้/ไม่ได้ + fallback

---

### Task 5: CLI config skill ×2 (rename toggle → config)

**Files:**
- Create: `plugins/english-coach/skills/config/SKILL.md`
- Create: `plugins/prompting-coach/skills/config/SKILL.md`
- Delete: `plugins/english-coach/skills/toggle/` และ `plugins/prompting-coach/skills/toggle/`

**Interfaces:**
- Produces: ไฟล์ config `$HOME/.claude/<plugin>-data/config` — english: keys `enabled`,`level`; prompting: keys `enabled`,`lang`,`level` — Task 6 hooks อ่าน key เหล่านี้ตรงตัว

- [ ] **Step 1: เขียน `plugins/english-coach/skills/config/SKILL.md`**

````markdown
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

- `level full` / `level light` — keep current `enabled` (substitute the chosen value):

```sh
en=$(sed -n 's/^enabled=//p' "$DATA_DIR/config" 2>/dev/null); printf 'enabled=%s\nlevel=%s\n' "${en:-1}" "light" > "$DATA_DIR/config"
```

- `status`:

```sh
cat "$DATA_DIR/config" 2>/dev/null || echo "enabled=1 level=full (default, no config file)"
```

After writing, confirm to the user: current enabled state + level, and note that the
change takes effect from the next prompt (the hook runs per prompt).
````

- [ ] **Step 2: เขียน `plugins/prompting-coach/skills/config/SKILL.md`**

````markdown
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

- `level full` / `level light` (substitute the chosen value):

```sh
printf 'enabled=%s\nlang=%s\nlevel=%s\n' "${en:-1}" "${lang:-en}" "light" > "$DATA_DIR/config"
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
````

- [ ] **Step 3: ลบ skill toggle เดิม**

```bash
git rm -r plugins/english-coach/skills/toggle plugins/prompting-coach/skills/toggle
```

(ยัง**ไม่ commit** — `git rm` แค่ stage; commit รวมตอนจบตาม Global Constraints)

- [ ] **Step 4: ตรวจโครง**

Run: `ls plugins/english-coach/skills plugins/prompting-coach/skills`
Expected: มี `config` (+skill หลัก) ไม่มี `toggle`

---

### Task 6: Hooks ×2 — อ่าน `level`

**Files:**
- Modify: `plugins/english-coach/hooks/coach-enforce.sh`
- Modify: `plugins/prompting-coach/hooks/coach-enforce.sh`

**Interfaces:**
- Consumes: key `level` จากไฟล์ config (Task 5)

- [ ] **Step 1: english-coach hook — เนื้อหาใหม่ทั้งไฟล์**

```sh
#!/bin/sh
# UserPromptSubmit hook: inject english-coach enforcement unless disabled.
# POSIX sh only. Fail-open: always exit 0.
FALLBACK_DIR="$HOME/.claude/english-coach-data"
CONF="$FALLBACK_DIR/config"
# The config skill's Bash-tool commands run without CLAUDE_PLUGIN_DATA set
# (verified: empty in that context) so it always writes to FALLBACK_DIR.
# Read from there first so config state actually takes effect; only fall
# back to CLAUDE_PLUGIN_DATA/config if the fixed path has never been written.
# Forward-compat only: nothing writes here today (config writes the primary path).
[ -f "$CONF" ] || CONF="${CLAUDE_PLUGIN_DATA:-$FALLBACK_DIR}/config"
enabled=1
level=full
if [ -f "$CONF" ]; then
  CR=$(printf '\r')
  while IFS='=' read -r k v || [ -n "$k" ]; do
    v=${v%"$CR"}
    case "$k" in
      enabled) enabled="$v" ;;
      level) level="$v" ;;
    esac
  done < "$CONF"
fi
[ "$enabled" = "0" ] && exit 0
LIGHT=""
[ "$level" = "light" ] && LIGHT=" LIGHT LEVEL: skip praise lines, skip the ✨ line, skip Format C entirely; Format A/B still apply with mandatory 🎯."
printf '%s' "ENGLISH-COACH ENFORCEMENT: END every response with the english-coach block per the english-coach skill (exact template, the FINAL element of the final message of the turn - never mid-turn while background work is pending). Its skip rules apply (pure slash commands, short acks, pure pastes with zero narration).${LIGHT}"
exit 0
```

- [ ] **Step 2: prompting-coach hook — เนื้อหาใหม่ทั้งไฟล์**

```sh
#!/bin/sh
# UserPromptSubmit hook: inject prompting-coach enforcement unless disabled.
# POSIX sh only. Fail-open: always exit 0.
FALLBACK_DIR="$HOME/.claude/prompting-coach-data"
CONF="$FALLBACK_DIR/config"
# The config skill's Bash-tool commands run without CLAUDE_PLUGIN_DATA set
# (verified: empty in that context) so it always writes to FALLBACK_DIR.
# Read from there first so config state actually takes effect; only fall
# back to CLAUDE_PLUGIN_DATA/config if the fixed path has never been written.
# Forward-compat only: nothing writes here today (config writes the primary path).
[ -f "$CONF" ] || CONF="${CLAUDE_PLUGIN_DATA:-$FALLBACK_DIR}/config"
enabled=1
lang=en
level=full
if [ -f "$CONF" ]; then
  CR=$(printf '\r')
  while IFS='=' read -r k v || [ -n "$k" ]; do
    v=${v%"$CR"}
    case "$k" in
      enabled) enabled="$v" ;;
      lang) lang="$v" ;;
      level) level="$v" ;;
    esac
  done < "$CONF"
fi
[ "$enabled" = "0" ] && exit 0
LIGHT=""
[ "$level" = "light" ] && LIGHT=" LIGHT LEVEL: emit the verdict block only for load-bearing gaps (a wrong guess wastes real work); skip Format B praise blocks."
printf '%s' "PROMPTING-COACH ENFORCEMENT: (1) BEFORE starting any work on this prompt, run the prompting-coach skill's pre-flight evaluation - a severe, load-bearing gap on substantial work means the Format G gate (AskUserQuestion) BEFORE any work; its skip rules and Gate Rubric apply. (2) When no gate fires, OPEN the response with the prompting-coach verdict block (Format A or B, exact template) as the FIRST element - omitted only when a skip rule applies. Commentary language: ${lang}.${LIGHT}"
exit 0
```

- [ ] **Step 3: Live-verify hooks ด้วย temp HOME (deterministic, ไม่ใช่ test suite)**

```bash
TMP=$(mktemp -d)
mkdir -p "$TMP/.claude/english-coach-data" "$TMP/.claude/prompting-coach-data"
printf 'enabled=1\nlevel=light\n' > "$TMP/.claude/english-coach-data/config"
printf 'enabled=1\nlang=th\nlevel=light\n' > "$TMP/.claude/prompting-coach-data/config"
HOME="$TMP" sh plugins/english-coach/hooks/coach-enforce.sh; echo
HOME="$TMP" sh plugins/prompting-coach/hooks/coach-enforce.sh; echo
printf 'enabled=0\nlevel=light\n' > "$TMP/.claude/english-coach-data/config"
HOME="$TMP" sh plugins/english-coach/hooks/coach-enforce.sh; echo "exit=$? output above should be empty"
printf 'enabled=1\nlevel=full' > "$TMP/.claude/prompting-coach-data/config"   # no trailing newline on purpose
HOME="$TMP" sh plugins/prompting-coach/hooks/coach-enforce.sh; echo
rm -rf "$TMP"
```

Expected: (1) english มี `LIGHT LEVEL: skip praise` ต่อท้าย (2) prompting มี `Commentary language: th.` + `LIGHT LEVEL:` (3) enabled=0 → output ว่าง exit 0 (4) ไฟล์ไม่มี trailing newline → ยังอ่าน level=full ได้ ไม่มี LIGHT

---

### Task 7: README + SKILL.md หลัก — level docs

**Files:**
- Modify: `README.md` (บรรทัด 8 และ 24 — จุดที่อ้าง toggle)
- Modify: `plugins/english-coach/skills/english-coach/SKILL.md` (เพิ่ม section Level)
- Modify: `plugins/prompting-coach/skills/prompting-coach/SKILL.md` (เพิ่ม section Level)

- [ ] **Step 1: README**

- บรรทัด `configurable (\`/prompting-coach:toggle lang th\`).` → `configurable (\`/prompting-coach:config lang th\`).`
- บรรทัด `Silence it anytime: /prompting-coach:toggle off · /english-coach:toggle off` → `Silence it anytime: /prompting-coach:config off · /english-coach:config off`
- เพิ่มย่อหน้าสั้นถัดจากบรรทัดนั้น:

```markdown
Fine-tune both plugins: `/prompting-coach:config level light` · `/english-coach:config level light`
(light = load-bearing gaps / real corrections only, no praise). On Discord (OpenClaw), the
`/coach` slash command controls the same knobs plus delivery (`spoiler|plain|dm`).
```

- [ ] **Step 2: english-coach SKILL.md — เพิ่มก่อน section `## Skip Rules`**

```markdown
## Level (จาก config)

Hook ส่งคำว่า `LIGHT LEVEL` มาใน enforcement เมื่อผู้ใช้ตั้ง `level=light` ผ่าน
`/english-coach:config level light`: ตัดบรรทัด ✨ และคำชมทั้งหมด, Format C ข้ามทั้งก้อน —
Format A/B ยังทำงานตามปกติและ 🎯 ยังบังคับ ไม่มีคำว่า `LIGHT LEVEL` = full ตาม spec เดิมครบ
```

- [ ] **Step 3: prompting-coach SKILL.md — เพิ่มก่อน section `## Session Noise Control`**

```markdown
## Level (จาก config)

Hook ส่งคำว่า `LIGHT LEVEL` มาใน enforcement เมื่อผู้ใช้ตั้ง `level=light` ผ่าน
`/prompting-coach:config level light`: emit verdict block เฉพาะ gap ที่ load-bearing จริง
(เดาผิดแล้วงานเสีย) และข้าม Format B (praise) ทั้งหมด — Gate Rubric ทำงานตามเดิม
ไม่มีคำว่า `LIGHT LEVEL` = full ตาม spec เดิมครบ
```

- [ ] **Step 4: ตรวจไม่เหลือการอ้าง toggle**

Run: `grep -rn 'toggle' README.md plugins/ || echo 'no toggle refs'`
Expected: `no toggle refs`

---

### Task 8: Final — commit + push

**Files:** ทั้งหมดจาก Task 1-7 + ของค้าง 4 ไฟล์ two-spoiler จากรอบก่อน

- [ ] **Step 1: ตรวจ live-verify ผ่านครบ** — Task 4 ทุก step + Task 6 Step 3 ต้อง PASS ก่อน (ถ้า dm mode fail แบบ fallback ทำงานถูก = ยอมรับได้ บันทึกใน note แล้ว)

- [ ] **Step 2: Commit**

```bash
git add -A ':!site'
git commit -m "feat: coach config commands (/coach on Discord, /<plugin>:config on CLI) + two-spoiler coaching format"
```

(commit message ต้องลงท้ายด้วย trailers Co-Authored-By/Claude-Session ตามมาตรฐาน session; `site/` ห้าม commit ตามคำสั่งเดิมของผู้ใช้)

- [ ] **Step 3: Push**

```bash
git push origin main
```

Expected: main ขึ้น origin ครบ (รวม merge commit เก่าที่ค้าง 1 commit)

- [ ] **Step 4: อัปเดต memory** — `claude-coach-rollout-state.md`: Phase 2 เสร็จ, coach config commands แล้ว, dm mode ผล verify จริง
