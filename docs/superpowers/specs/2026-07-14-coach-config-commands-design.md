# Design: Coach config commands (Discord/OpenClaw + Claude CLI)

**วันที่:** 2026-07-14
**สถานะ:** อนุมัติแล้ว (brainstorming session)
**Testing mode:** live-verify (ตกลงกับผู้ใช้แล้ว — ห้าม TDD auto-start)

## เป้าหมาย

เพิ่ม slash command สำหรับปรับแต่ง coaching skills ได้ละเอียดทั้งสองฝั่ง:

- **Discord/OpenClaw:** command `/coach` — เปิด/ปิดราย skill, ปรับระดับความเข้ม, เลือกรูปแบบการส่ง block
- **Claude CLI:** command ราย plugin `/english-coach:config`, `/prompting-coach:config` — เปิด/ปิด + ปรับระดับ

การตั้งค่า persist ข้าม session/restart ทั้งสองฝั่ง (durable)

## ข้อเท็จจริงจาก OpenClaw docs (ยืนยัน 2026-07-14)

- Skill ที่ `user-invocable: true` ถูกลงทะเบียนเป็น **slash command จริง** บน Discord — `commands.nativeSkills` default `"auto"` = เปิดบน Discord อยู่แล้ว ไม่ต้องแก้ config
- ชื่อ command ถูก sanitize เป็น `a-z0-9_` (สูงสุด 32 ตัว)
- Slash command reply เป็น **ephemeral by default** (`channels.discord.slashCommand.ephemeral: true`) — คำยืนยัน config เห็นคนเดียว
- Command route เข้า model เป็น request ปกติ (ไม่ใช้ `command-dispatch: tool` — เราต้องการให้ model อ่าน/เขียนไฟล์ config)
- Native slash command รันใน isolated command session แยกจาก conversation session
- `disable-model-invocation: true` เอา skill ออกจาก prompt ปกติ แต่ยังเรียกผ่าน command ได้ — ใช้กับ skill นี้เพื่อไม่กิน context ทุก turn

แหล่งอ้างอิง: docs.openclaw.ai/tools/slash-commands, docs.openclaw.ai/tools/skills (raw จาก github.com/openclaw/openclaw)

## Knobs

| Knob | ค่า | Default | ความหมาย |
|---|---|---|---|
| `prompt_coach` | `on` / `off` | `on` | เปิด/ปิด prompting-coach block (Discord) |
| `english_coach` | `on` / `off` | `on` | เปิด/ปิด english-coach block (Discord) |
| `level` | `full` / `light` | `full` | full = โค้ชตาม spec ปัจจุบันครบ; light = เฉพาะ gap ใหญ่/grammar error จริง |
| `delivery` | `spoiler` / `plain` / `dm` | `spoiler` | รูปแบบการส่ง coaching (Discord เท่านั้น) |
| `enabled` (CLI) | `1` / `0` | `1` | เปิด/ปิดราย plugin (มีอยู่แล้ว) |
| `level` (CLI) | `full` / `light` | `full` | ความหมายเดียวกับฝั่ง Discord |

**นิยาม `level=light`:**

- prompting-coach: โค้ชเฉพาะ gap ที่ load-bearing จริง (เดาผิดแล้วงานเสีย) — gap เล็กน้อยข้าม block ไปเลย; ฝั่ง CLI งด Format B (praise) ด้วย
- english-coach: Format A (แปล) และ Format B (แก้ error จริง) ยังทำงาน แต่**ตัดบรรทัด ✨ ทิ้ง, ตัดคำชม, Format C ข้ามทั้งก้อน**; 🎯 ยังบังคับใน A/B (เป็น core value)

**นิยาม `delivery`:**

- `spoiler` — สอง spoiler แยก section ตาม spec ปัจจุบัน (default)
- `plain` — block เดียวกันแต่ไม่ห่อ `||...||` (มองเห็นทันที)
- `dm` — คำตอบหลักของงาน = reply ปกติของ turn ในช่องเดิม **ต้องมีเนื้อหางานเต็มเสมอ ห้ามแทนที่ด้วยข้อความยืนยันการส่ง coaching** ส่วน coaching ส่งผ่าน message tool เป็นข้อความแยก quote ข้อความต้นทาง — ส่งไม่สำเร็จ → fallback แนบเป็น spoiler ท้ายคำตอบหลัก + บรรทัดแจ้ง (แก้เพิ่มหลัง live-verify รอบแรกพบ bug คำตอบหลักหาย — ดู note 2026-07-live-verify-discord.md)

## สถาปัตยกรรมฝั่ง Discord/OpenClaw

### ไฟล์ config: `~/.openclaw/workspace/coach-config`

รูปแบบ `key=value` บรรทัดละคู่ (ตรงกับฝั่ง CLI):

```
prompt_coach=on
english_coach=on
level=full
delivery=spoiler
```

ไฟล์ไม่มี = ใช้ default ทั้งหมด (ห้าม error)

### Skill ใหม่: `openclaw/skills/coach/SKILL.md` (repo) → deploy ไป `~/.openclaw/workspace/skills/coach/SKILL.md`

Frontmatter:

```yaml
---
name: coach
description: ปรับแต่ง coaching (prompting-coach + english-coach) — /coach status | prompt on|off | english on|off | level full|light | delivery spoiler|plain|dm
user-invocable: true
disable-model-invocation: true
---
```

Body สั่ง model (รันใน isolated command session):

1. Parse argument: `status` (หรือว่าง) / `prompt on|off` / `english on|off` / `level full|light` / `delivery spoiler|plain|dm` — argument ไม่ตรง grammar ให้ตอบ usage สั้นๆ ไม่แก้ไฟล์
2. `status`: อ่านไฟล์ `coach-config` (ไม่มี = รายงาน default) ตอบค่าปัจจุบันทุก key บรรทัดเดียวต่อ key
3. คำสั่งตั้งค่า: อ่านไฟล์เดิม (ถ้ามี) → อัปเดตเฉพาะ key ที่สั่ง → เขียนกลับครบทุก key (เขียน default ให้ key ที่ยังไม่เคยตั้ง) → ตอบยืนยันค่าใหม่ 1 บรรทัด + หมายเหตุ "มีผลข้อความถัดไป"
4. ห้ามทำอย่างอื่นนอกเหนือจากอ่าน/เขียนไฟล์นี้และตอบยืนยัน

### AGENTS.md — เพิ่ม rule 0 ใน Coaching section

ก่อนสร้าง coaching block ทุกครั้ง อ่านไฟล์ `coach-config` ใน workspace (1 tool call ต่อข้อความ — ผู้ใช้เลือกทางนี้แทนการฝัง config ใน AGENTS.md):

- `prompt_coach=off` → ไม่มี 🧭 block
- `english_coach=off` → ไม่มี english block
- ทั้งคู่ off → ไม่ต้องอ่านอะไรเพิ่ม ตอบปกติ
- `level=light` → พฤติกรรมตามนิยามข้างบน
- `delivery` → เลือกรูปแบบส่งตามนิยามข้างบน (dm fallback spoiler เมื่อส่งไม่ได้)
- ไฟล์ไม่มี/อ่านไม่ได้ → default ทั้งหมด (on, full, spoiler)

### แก้ discord SKILL.md ทั้งสองไฟล์

เพิ่ม section สั้น "Config awareness": อ้าง `coach-config` + สรุปผลของ `level=light` และ `delivery` ต่อ format ของ skill ตัวเอง (รายละเอียด format หลักคงเดิมทุกบรรทัด)

## สถาปัตยกรรมฝั่ง Claude CLI

### ขยาย `toggle` → `config` (ทั้งสอง plugin)

- ย้าย `plugins/<p>/skills/toggle/` → `plugins/<p>/skills/config/` (`name: config`) — `/english-coach:config`, `/prompting-coach:config`; ไม่เหลือ skill `toggle` (ไม่มี alias ซ้ำซ้อน)
- Argument: `on` / `off` / `status` (default) / `level full|light`
- เขียนไฟล์เดิม `~/.claude/<plugin>-data/config` แบบ merge key (คง key อื่นที่มีอยู่):

```
enabled=1
level=full
```

- คง pattern เดิมของ toggle skill: resolve `DATA_DIR` ก่อน แล้วรันคำสั่ง shell ผ่าน Bash tool, `status` แสดงไฟล์ทั้งไฟล์

### Hook `coach-enforce.sh` (ทั้งสอง plugin)

- อ่าน key `level` เพิ่ม (loop `key=value` เดิมรองรับอยู่แล้ว — เพิ่ม case)
- `enabled=0` → exit เงียบ (เดิม)
- `level=light` → ต่อท้ายข้อความ enforcement: ฝั่ง english-coach "LIGHT LEVEL: skip praise lines, skip ✨ line, skip Format C entirely; Format A/B still apply with mandatory 🎯" — ฝั่ง prompting-coach "LIGHT LEVEL: emit the verdict block only for load-bearing gaps; skip Format B praise blocks"
- ค่า `level` อื่น/ไม่มี = full (default, ข้อความเดิม)
- คง POSIX sh + fail-open exit 0 + CRLF handling เดิม

### SKILL.md หลักของทั้งสอง plugin

เพิ่ม section สั้น "Level" อธิบายพฤติกรรม `light` (สอดคล้อง enforcement ของ hook) — โครง Format เดิมไม่แตะ

### เอกสาร

`README.md`: แทนที่การอ้าง `/…:toggle` ทุกจุดด้วย `/…:config` + ตาราง argument ใหม่ (on/off/status/level) และเพิ่มหัวข้อ `/coach` ฝั่ง Discord

## Deploy (Discord)

ตาม pipeline เดิมใน `docs/notes/2026-07-openclaw-install.md`:

1. `cp` skill ใหม่ + skill เดิมที่แก้ไป `~/.openclaw/workspace/skills/...`
2. python3 marker-replace section ใน `~/.openclaw/workspace/AGENTS.md` (marker `## Coaching ทุกข้อความ`)
3. `cd ~/Projects/openclaw && docker compose -f docker-compose.yml -f docker-compose.extra.yml restart openclaw-gateway` (**ต้องมี `-f` สองไฟล์เสมอ**)
4. Poll `healthz`/`readyz` ด้วย retry loop
5. Command registration อาจต้องรอ gateway ลงทะเบียนกับ Discord หลัง restart

## Live-verify

**Discord:**

1. `/coach` โผล่ใน Discord command picker (พิมพ์ `/` เห็น command + description)
2. `/coach status` → ตอบ default ครบ (ephemeral)
3. `/coach level light` → ไฟล์ `coach-config` มี `level=light`; ส่งข้อความไทยธรรมดา → english block ไม่มี ✨/คำชม
4. `/coach english off` → ข้อความถัดไปไม่มี english block; `/coach english on` คืนค่า
5. `/coach delivery dm` → coaching มาเป็น DM แยก + quote ต้นทาง (ถ้า message tool DM ไม่ได้ → บันทึกผล + fallback spoiler ทำงาน)
6. `/coach delivery spoiler` + `/coach level full` คืนค่า default แล้วส่งข้อความสั่งงาน → สอง spoiler ตาม spec เดิมครบ (regression)
7. ใช้ `/new` ก่อน verify แต่ละชุดเมื่อ format เปลี่ยน (กัน history mimicry)

**CLI:**

1. Session ทดสอบ: `/prompting-coach:config status` → รายงานค่า
2. `level light` → ไฟล์มี `level=light` และ hook inject ข้อความ LIGHT (ตรวจผ่าน prompt ถัดไป: gap เล็กไม่มี block)
3. `off` → ไม่มี block เลย; `on` คืนค่า
4. english-coach ชุดเดียวกัน

**หมายเหตุ browser verify:** dispatch implementer ตาม Context discipline (serialized, ~50-call budget, dialog line verbatim); Discord spoiler ตรวจระดับ DOM ผ่าน `evaluate_script` อ่าน `span.spoilerContent` (คลิก reveal ไม่ได้)

## Git

หลัง verify ผ่านหมด: commit + push ทั้งหมด (รวมของค้าง 4 ไฟล์ two-spoiler format จากรอบก่อน + merge commit ที่ main นำ origin อยู่ 1 commit) — ผู้ใช้อนุมัติแล้ว 2026-07-14

## นอกขอบเขต

- ไม่มี knob ภาษา commentary (ผู้ใช้ไม่เลือก)
- ไม่แตะ `channels.discord.slashCommand.ephemeral` (default true ดีอยู่แล้ว)
- ไม่มีระดับ `minimal` (สองระดับพอ)
- caveman hook / skill อื่นนอก coaching ไม่เกี่ยว
