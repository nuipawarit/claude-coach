# Live-verify Discord Coaching — 2026-07-14

ผลทดสอบจริงบน Discord DM กับ bot "nhui coach" (OpenClaw + Docker, workspace skills `prompting-coach-discord` / `english-coach-discord`) ตาม plan Task 13

## Setup ที่ใช้ทดสอบ

- Bot: application "nhui coach" (App ID 1526354466729889872), MESSAGE CONTENT INTENT เปิด, token ใน `~/.openclaw/.env` (`chmod 600`)
- Pairing: `openclaw pairing approve discord GLR595TL` — ผู้ใช้ 919818343274381334 เป็น command owner
- ทดสอบผ่าน browser agent (chrome-devtools) ส่ง DM จริง อ่าน reply + spoiler จริง

## รอบที่ 1 — FAIL ทั้งหมด (ไม่ใช่ความผิด skill)

ทุกข้อความได้ `⚠️ Something went wrong...` — root cause: restart gateway ด้วย `docker compose down/up` โดยไม่ใส่ `-f docker-compose.extra.yml` ทำให้ volume `openclaw_home` (เก็บ claude CLI + OAuth) หลุดจาก container → spawn ตาย (`write EPIPE`, `durationMs=2`)

**บทเรียนสำคัญ: ทุกคำสั่ง compose ของ OpenClaw ต้องใส่ `-f docker-compose.yml -f docker-compose.extra.yml` เสมอ** (จดใน install note แล้ว)

## รอบที่ 2 — เนื้อหาทำงาน มี deviation 2 จุด

| ส่ง | ผล |
|---|---|
| `วันนี้เหนื่อยมากเลย` | ✅ reply ปกติ + spoiler `🌐 EN` + `✨` — แต่ `🎯` หาย |
| `ช่วยสรุปว่าพรุ่งนี้ผมต้องทำอะไรบ้าง` | ✅ มี `🧭` — แต่ `🌐 EN` หาย |
| `Can you check my calendar tomorrow?` | ✅ Format C (`✅` ชมไทย) |

Deviation + การแก้ (แก้ที่ source ใน repo แล้ว copy ทับ workspace ตามหลัก source of truth):

1. **Coaching ไม่ได้มาเป็น "ข้อความที่สอง"** — แพลตฟอร์มส่งหนึ่งข้อความต่อเทิร์น (main reply + บรรทัดว่าง + spoiler ใน message เดียว) → ตัดสินใจแก้ spec ให้ตรงความจริง: `AGENTS-coaching-section.md` ข้อ 3 เปลี่ยนเป็น same-message + blank line + spoiler เดียว
2. **`🌐 EN` หายเมื่อมี `🧭` นำ** → เพิ่ม rule ใน AGENTS section ข้อ 2 + SKILL.md: บรรทัด english-coach ต้องตามมาครบเสมอ ห้ามแทนที่

## รอบที่ 3 — `🧭` + `🌐` + `✨` ผ่าน แต่ `🎯` ยังหาย

`ช่วยจองร้านอาหารให้หน่อยพรุ่งนี้เย็น` → spoiler: `🧭` (ชี้ gap ระบุร้าน/คน/เวลา + ตัวอย่าง prompt ที่ดีกว่า) → `🌐 EN` → `✨` ลำดับถูก 3 บรรทัด สะอาด — ผ่าน

Root cause ของ `🎯` หาย: SKILL.md เขียน "optional 🎯" ใน decision tree + **ตัวอย่างในไฟล์เองไม่มีบรรทัด 🎯** (Example 1-2 ของ Format A) — model เรียนจากตัวอย่างมากกว่า rule → แก้: เปลี่ยน `🎯` เป็น **บังคับเสมอ** ใน Format A/B (rule + decision tree) และเติมบรรทัด `🎯` ให้ตัวอย่างครบทุกตัว (Format C คง optional ตาม spec)

## รอบที่ 4 (final) — PASS ครบทุกเกณฑ์

`เดี๋ยวบ่ายนี้ขอลาไปหาหมอหน่อยนะ` →

- Main reply สะอาด ไม่มี coaching ปน
- Spoiler เดียวครอบทั้งก้อน 3 บรรทัด: `🌐 EN` / `✨` / `🎯 "Stepping out this afternoon for a doctor's appointment." — "step out" ให้ความรู้สึกเป็นกันเองกว่า...` (มีเหตุผลไทยหลัง dash ครบ)
- ไม่มี `🧭` (ถูกต้อง — เป็นแชตทั่วไปไม่ใช่สั่งงาน), ไม่มี `>` / ตาราง, ≤5 บรรทัด

## สรุป

Coaching ทั้งสอง skill ทำงานบน Discord จริงครบตาม spec (ฉบับแก้แล้ว) — เกณฑ์ตาราง 3 ข้อความใน plan Task 13 Step 2 ผ่านทั้งหมดในรอบ 2-4 รวมกัน; จุดที่ plan คาดไว้ผิดจากแพลตฟอร์มจริงมีจุดเดียวคือ "ข้อความที่สอง" ซึ่งแก้ spec ลง asset แล้ว
