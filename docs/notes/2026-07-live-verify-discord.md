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

---

# Redesign: blockquote แบบ CLI — 2026-07-14 (หลัง merge Phase 2)

ผู้ใช้ขอให้ Discord render คล้าย CLI (แถบแนวตั้ง + bold labels + 🧭 block 3 บรรทัด) — เลือก blockquote แทน spoiler (สองอย่างใช้ร่วมกันไม่ได้: spoiler เป็น inline, blockquote เป็น block-level) แก้ 3 asset: AGENTS section (rule 3 = blockquote, budget ≤7), prompting-coach-discord (🧭 บรรทัดเดียว → 3 บรรทัด 🧭/✍️/📐), english-coach-discord (bold labels `🌐 EN:` / `✨ กระชับ:` / `🎯 ยกระดับ:`)

## รอบที่ 5 — ผ่านบางส่วน เจอ 2 root cause

- แชตธรรมดายังออก format เก่า (spoiler, label หาย) ทั้งที่ skill ใหม่ load แล้ว (พิสูจน์จากข้อความสั่งงานที่ 🧭 มา 3 บรรทัดแบบใหม่) — root cause: **history mimicry** — DM เดิมเต็มไปด้วยตัวอย่าง format เก่า model เลียนตัวอย่างแรงกว่า rule (บทเรียนเดียวกับ bug 🎯 รอบ 3) → แก้: เพิ่ม rule 6 ใน AGENTS section ห้ามเลียน format เก่าจาก history + reset session (`/new`) ตอน verify
- **literal `>` หลุดกลางก้อน** — spec สั่งคั่น 🧭 block กับ english block ด้วยบรรทัด `>` เปล่า แต่ Discord render `>` เดี่ยวเป็นตัวอักษร ไม่ใช่ quote ว่าง → แก้ spec: ไม่มีบรรทัดคั่น ต่อเป็น blockquote ก้อนเดียว

## รอบที่ 6 (final) — PASS ครบทุกเกณฑ์ทั้ง 2 ข้อความ

หลัง `/new` (ตัด history เก่า):

- แชตเล่า (`วันนี้อากาศดีมากเลย...`): blockquote ไม่มี spoiler, labels bold ครบ `🌐 EN:` / `✨ กระชับ:` / `🎯 ยกระดับ:` + เหตุผลไทยหลัง dash, ไม่มี 🧭, main reply สะอาด
- สั่งงาน vague (`ช่วยวางแผนทริปให้หน่อย`): 🧭 3 บรรทัด (`🧭 Prompt Coach:` / `✍️ ลองแบบนี้:` / `📐 be-explicit — ...`) ต่อด้วย `🌐 EN:` / `🎯 ยกระดับ:` ในก้อน quote เดียวต่อเนื่อง 5 บรรทัด ไม่มี literal `>` ไม่มี spoiler

หมายเหตุ: DM ที่มี history format เก่ายาวๆ อาจยังเลียนแบบเก่าได้บ้างแม้มี rule 6 — ถ้าเจอ ให้ผู้ใช้สั่ง `/new` หนึ่งครั้ง format ใหม่จะ lock จากตัวอย่างใหม่เอง

## รอบที่ 7 — ครบทุก format ที่เหลือ (Format B / C / skip) — PASS ทั้งหมด

- `yesterday I go to office but forgot bring my laptop` → Format B ครบ: blockquote (ยืนยัน DOM มี `<blockquote>` ไม่มี spoiler element), `🌐 คุณเขียน:` verbatim, `แก้ไข:` bold เฉพาะ **went**/**the**/**forgot to**, `🎯 ยกระดับ:` + เหตุผลไทย, `💡` tip past-tense/forget-to, 4 บรรทัด, ไม่มี 🧭
- `I finished the report and sent it to the team this morning.` → Format C: `✅` ชมเจาะจง (tense + ลำดับข้อมูล) ไม่ยัด 🎯
- `ok` → skip ถูกต้อง: bot ตอบ 👍 เดียว ไม่มี coaching เลย

**สรุป redesign: 5 เคสครอบทุก format (A / B / C / 🧭 / skip) ผ่านทุกเกณฑ์บน Discord จริง**

---

# Revert เป็น spoiler + bold labels (final) — 2026-07-14

ผู้ใช้อยากได้ coaching แบบ **collapse ได้** — Discord ไม่มี collapse ในข้อความ text ธรรมดา จึงใช้ fallback ที่ผู้ใช้กำหนด: กลับเป็น spoiler `||...||` แต่**คงของใหม่จากรุ่น blockquote ไว้ทั้งหมด** (bold labels `🌐 EN:` / `✨ กระชับ:` / `🎯 ยกระดับ:` + 🧭 block 3 บรรทัด ไม่มีบรรทัดคั่น)

## รอบที่ 8 — แชตธรรมดา PASS / สั่งงาน FAIL (skill ไม่ถูกอ่าน)

- แชตธรรมดา: spoiler เดียว + labels ครบ — ผ่าน
- สั่งงาน: 🧭 block หลุดนอก spoiler + labels เพี้ยนเป็นคำที่ไม่มีใน spec ไหนเลย (`🧭 ประเด็น:`, `✍️ ตัวอย่าง prompt ที่ดีขึ้น:`) — model **แต่งเอง** = เทิร์นนั้นไม่ได้อ่าน SKILL.md ของ prompting-coach (การโหลด skill ไม่ deterministic) เห็นแค่โครง "3 บรรทัด 🧭/✍️/📐" จาก AGENTS section
- แก้แบบ root cause: ฝัง**ตัวอย่างก้อนเต็ม labels ตรงตัว** ลง AGENTS.md rule 7 (อยู่ใน context เสมอ ไม่พึ่งการอ่าน skill) — ตัวอย่างเดียวสอนทั้ง labels และ spoiler-ห่อ-ทั้งก้อน

## รอบที่ 9 (final) — PASS ครบทุกเกณฑ์

`ช่วยแนะนำหนังสือให้หน่อย` → ก่อนคลิกเห็นแค่ main reply + ปุ่ม spoiler เดียว (🧭 ไม่หลุด) ข้างใน 5 บรรทัด labels ตรงเป๊ะ: `🧭 Prompt Coach:` / `✍️ ลองแบบนี้:` / `📐 be-explicit — ...` / `🌐 EN:` / `🎯 ยกระดับ:` + เหตุผลไทย

## Ephemeral message — investigate แล้ว ทำไม่ได้

ผู้ใช้อยากได้ coaching เป็น ephemeral message ("มีเพียงคุณเท่านั้นที่เห็นข้อความนี้" แบบผลของ `/new`) — อ่าน docs ละเอียดทั้ง Discord developer docs และ OpenClaw:

- Discord API: `EPHEMERAL` flag (1<<6) ใช้ได้เฉพาะ interaction response/followup (token อายุ 15 นาที) — reply ปกติใส่ไม่ได้
- OpenClaw: ไม่รองรับ custom slash command; ปุ่ม Components V2 มีจริง (`channels.discord.agentComponents.ttlMs`, callback default 30 นาที) แต่ผลการกดปุ่ม "route back to the agent as normal inbound messages" — ตอบกลับเป็นข้อความปกติ ไม่ใช่ ephemeral และไม่มี disclosure mode
- ephemeral มีที่เดียว: native slash command replies (`channels.discord.slashCommand.ephemeral`, default true)

→ spoiler คือตัวเลือกใกล้ collapse/ephemeral ที่สุดที่ทำได้จริงบน reply ปกติ

## รอบที่ 10 (final จริง) — แยกสอง spoiler ตาม section — PASS ครบ

ผู้ใช้ขอแยก section (🧭 กับ english ไม่ปนก้อนเดียว) → spec สุดท้าย: **spoiler ก้อน 🧭 (3 บรรทัด) + บรรทัดว่าง + spoiler ก้อน english** เปิดอ่านแยกกันได้ แชตทั่วไปมีเฉพาะก้อน english

`ช่วยคิดเมนูมื้อเย็นให้หน่อย` → ยืนยันระดับ DOM: 2 `span.spoilerContent` แยกกัน คั่น blank line, ก้อนแรก `🧭 Prompt Coach:` / `✍️ ลองแบบนี้:` (`<strong>` จริง) / `📐 be-explicit — ...`, ก้อนสอง `🌐 EN:` / `🎯 ยกระดับ:` + เหตุผลไทย, รวม 5 บรรทัด ไม่มี blockquote/ตาราง, main reply สะอาด — **PASS ทุกเกณฑ์**

(ข้อสังเกตฝั่งเครื่องมือ: chrome-devtools คลิก reveal spoiler ไม่ได้ — Discord กัน synthetic click — แต่อ่านเนื้อหาใต้ blur ผ่าน innerHTML ได้ครบ ใช้วิธีนี้ verify แทน)

## coach config commands — live-verify 2026-07-14

Verify ผ่าน implementer dispatches 5 รอบ (budget ~50 calls/รอบ) บน Discord DM "nhui coach" จริง:

- Step 3 (command registration): **PASS** — พิมพ์ `/` แล้ว picker แสดง command `coach` พร้อม description; `/coach status` ตอบ ephemeral ครบ 4 keys ค่า default; gateway log ยืนยัน `command:coach` ถูก register ตอน restart
- Step 4.1 (`/coach level light`): **PASS** — `~/.openclaw/workspace/coach-config` มี `level=light`
- Step 4.2 (level=light + ข้อความไทยธรรมดา): **PASS** — spoiler เดียวเป็น A-format (🌐 EN + 🎯) ไม่มี ✨/คำชม ตามนิยาม light
- Step 4.3 (`/coach english off`): **PASS** — ไฟล์มี `english_coach=off`; ข้อความถัดไปไม่มี spoiler เลย (DOM count=0)
- Step 4.4 (คืนค่า `english on` + `level full`): **PASS** — ไฟล์กลับเป็น default ครบ ephemeral ยืนยันถูกต้อง
- Step 5 (`delivery=dm`) **รอบแรก: FAIL** — bot ส่ง reply-quote ที่มีแต่ coaching spoilers + ข้อความแยก "Coaching DM ส่งแล้วครับ" — **คำตอบหลัก (คำแนะนำหนังสือ) หายไปทั้ง turn**
  - Root cause: rule 0 bullet `delivery=dm` เดิมไม่ได้ห้าม agent แทนที่คำตอบหลักด้วยข้อความยืนยันการส่ง coaching — model ตีความว่า turn นี้มีหน้าที่แค่ส่ง coaching
  - Fix: แก้ bullet ที่ `openclaw/AGENTS-coaching-section.md:13` — บังคับ "คำตอบหลักของงาน = reply ปกติของ turn ต้องมีเนื้อหางานเต็มเสมอ ห้ามแทนที่ด้วยข้อความยืนยันการส่ง" + ห้ามพูดถึงการส่ง coaching ในคำตอบหลัก แล้ว redeploy + restart gateway
- Step 5 **รอบสอง (หลัง fix): PASS** — คำตอบหลักมีคำแนะนำหนังสือจริง ("Sapiens" — Yuval Noah Harari) และ coaching มาเป็นข้อความแยก quote ข้อความต้นทางถูกต้อง; restore `delivery=spoiler` แล้ว ไฟล์ยืนยัน
- Step 6 (regression สอง spoiler): **PASS** — ข้อความสั่งงาน `ช่วยคิดเมนูมื้อเย็นให้หน่อย` ได้ 2 `span[class*="spoilerContent"]` เป๊ะ: ก้อนแรก Prompt Coach/ลองแบบนี้/📐, ก้อนสอง 🌐 EN:, bold labels เป็น `<strong>` ครบ

บทเรียน browser-automation เพิ่มเติม: Discord Slate editor desync ง่ายกับ `execCommand` (ห้ามใช้ — press_key Backspace เท่านั้น); `wait_for` keyword กว้างคืน full-page snapshot กิน context — ใช้ `evaluate_script` polling เฉพาะ message group ล่าสุดแทน; Tab หลัง picker บางครั้งไม่แทรก trailing space ต้องเช็คก่อนพิมพ์ args
