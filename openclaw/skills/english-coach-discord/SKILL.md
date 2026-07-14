---
name: english-coach-discord
description: โค้ชภาษาอังกฤษจากทุกข้อความแชตของผู้ใช้ — แปล/แก้/ชม พร้อมรูปแบบ spoiler + bold labels สำหรับ Discord (กดเปิดอ่าน, ≤5 บรรทัด)
---

# english-coach-discord

A behavior-shaping skill that runs on every user chat message on Discord. Its only job is to evaluate the user's most recent message and decide whether to append a spoiler-wrapped English-learning block at the end of the bot's main reply — as part of the same message (see `AGENTS-coaching-section.md` rule 3). When a 🧭 spoiler block from `prompting-coach-discord` leads, this skill's spoiler block must still follow in full — as **its own separate `||...||` spoiler**, one blank line after the 🧭 block.

## Config awareness

การเปิด/ปิดและรูปแบบ ควบคุมด้วยไฟล์ `coach-config` ตาม AGENTS section rule 0:
`english_coach=off` → ไม่มี block นี้ทั้งก้อน · `level=light` → ตัดบรรทัด ✨ และคำชม
ทั้งหมด, Format C ข้ามทั้งก้อน — Format A/B ยังทำงานและ 🎯 ยังบังคับ · `delivery`
เปลี่ยนเฉพาะการห่อ/ช่องทางส่ง (spoiler/plain/dm) — เนื้อหา block คงเดิม

## When to trigger

Run this skill after producing the main reply. Evaluate the user's most recent chat message through the decision tree below. Based on the outcome, you either append a Format A block, a Format B block, a Format C block, or nothing at all — wrapped once in `||...||` at the end of the same message.

## Language of the Coaching Block

**All coaching commentary must be in Thai.** Only the actual English content stays in English.

| Part | Language |
|---|---|
| Labels (e.g. `คุณเขียน:`, `แก้ไข:`, `กระชับ:`, `ยกระดับ:`) | Thai |
| Praise lines (Format C) | Thai (jargon loanwords OK) |
| Why-tips (💡 in Format B) | Thai (jargon loanwords OK) |
| The English translation (🌐 EN line) | English |
| The user's verbatim message (Format B `คุณเขียน:`) | English (as written) |
| The corrected sentence (Format B `แก้ไข:`) | English |
| The concise alternative (✨ กระชับ) | English |
| The idiomatic upgrade (🎯 ยกระดับ) | English |

Mixing Thai with English jargon (`refactor`, `deploy`, `commit`, `PR`, `bug`, `AI` ฯลฯ) is fine and natural in commentary. The rule is: *explanation* in Thai, *the English example sentences* in English.

## Decision Tree

```
new chat message arrives
    │
    ▼
[1] ข้อความ ≤ 2 คำ, สติกเกอร์/ไฟล์/ลิงก์ล้วนไม่มีข้อความ,
    หรือเป็นการตอบคำถามที่ bot เพิ่งถาม?
    │ yes → SKIP (AGENTS section rule 5)
    ▼
[2] มี code / error / log paste ปนอยู่?
    │ yes → ดึงเฉพาะส่วน natural-language narration มาประเมิน
    │       ถ้า paste ล้วนไม่มี narration → SKIP
    ▼
[3] มีตัวอักษรไทย (U+0E00–U+0E7F) อยู่ในข้อความ?
    │ yes → emit Format A (แปล + กระชับ + 🎯 บังคับ)
    │ no
    ▼
[4] ข้อความอังกฤษมี grammar error ชัดเจน?
    (subject-verb, article, tense, plural, auxiliary, preposition,
     phrasing ที่ทำให้ความหมายไม่ชัด)
    │ yes → emit Format B (diff + กระชับ + 🎯 บังคับ + tip ไทย)
    │ no  → emit Format C (✅ ชม + optional 🎯 native upgrade)
```

**"jargon ปนอังกฤษ ≠ Thai ปน"**: คำอย่าง `refactor`, `deploy`, `commit`, `merge`, `push`, `pull`, `PR`, `bug`, `error`, `staging`, `production`, `API`, `endpoint` ถือเป็นคำยืมฝั่งไทยตามปกติในงาน dev — กติกาข้อ [3] คือ: ถ้ามีตัวอักษรไทยอย่างน้อย 1 ตัว → Format A เสมอ

## Format A — Translation

ใช้เมื่อ decision tree ตัดสินว่าข้อความมีตัวอักษรไทย (รวมถึงข้อความไทยล้วน)

**Output template** (spoiler เดียวห่อทั้งก้อน, ≤ 3 บรรทัด, ห้าม blockquote `>`, ห้ามตาราง, ห้าม heading):

```
||🌐 **EN:** "<corrected English translation>"
✨ **กระชับ:** "<shorter version>"
🎯 **ยกระดับ:** "<more idiomatic version>" — <เหตุผลไทยสั้น>||
```

**Rules:**
- สูงสุด 3 บรรทัด: แปลเต็ม / กระชับ (optional) / ยกระดับ (บังคับ)
- แปลแบบ idiomatic รักษา intent ไว้ ไม่แปลทีละคำ
- คำเติมไทย (เช่น "หน่อย", "ครับ", "ค่ะ") ตัดออกได้
- คงชื่อไฟล์ / identifier ตามต้นฉบับ
- บรรทัด ✨ ใส่เฉพาะเมื่อสั้นลงอย่างมีนัยสำคัญ — ถ้า intent สั้นอยู่แล้ว **ข้าม**
- บรรทัด 🎯 **บังคับเสมอใน Format A** — phrasing ที่ native กว่ามีอยู่เสมอ (สำนวน, phrasal verb, register) ตามด้วย `— <เหตุผลไทยสั้น>` ห้ามข้ามด้วยเหตุผลว่าคำแปลดีอยู่แล้ว

**Example 1 — ถามตารางนัด (ไทยล้วน):**

User: `พรุ่งนี้เรามีประชุมกี่โมงอะ`

```
||🌐 **EN:** "What time is our meeting tomorrow?"
✨ **กระชับ:** "What time's the meeting tomorrow?"
🎯 **ยกระดับ:** "When are we meeting tomorrow?" — native ถามแบบนี้สั้นและเป็นธรรมชาติกว่า||
```

**Example 2 — เล่าเรื่องวันนี้ (ไทย + jargon):**

User: `วันนี้ deploy ขึ้น production แล้วเจอ bug นิดหน่อยเลยต้อง rollback`

```
||🌐 **EN:** "We deployed to production today but hit a small bug, so we had to roll back."
✨ **กระชับ:** "Deployed today, hit a bug, rolled back."
🎯 **ยกระดับ:** "Today's prod deploy hit a snag — we had to roll it back." — "hit a snag" สำนวน dev เวลาเจอปัญหาไม่คาดคิด||
```

**Example 3 — สั่ง bot เช็คของ (ไทยล้วน มี upgrade):**

User: `ช่วยเช็คให้หน่อยว่า service ยัง alive อยู่มั้ย`

```
||🌐 **EN:** "Can you check if the service is still alive?"
🎯 **ยกระดับ:** "Can you check if the service is still up?" — dev นิยมใช้ "up" แทน "alive" กับ service||
```

## Format B — Correction

ใช้เมื่อข้อความเป็นอังกฤษล้วน (ไม่มีตัวอักษรไทย) **และมี error ชัดเจน**

**Output template:**

```
||🌐 **คุณเขียน:** "<verbatim user message>"
**แก้ไข:** "<corrected version, **bold** เฉพาะส่วนที่แก้>"
✨ **กระชับ:** "<shorter version>"
🎯 **ยกระดับ:** "<more idiomatic version>" — <เหตุผลไทยสั้น>
💡 <tip ไทย ≤80 ตัวอักษร>||
```

**Rules:**
- สูงสุด 5 บรรทัด: คุณเขียน / แก้ไข / กระชับ (optional) / ยกระดับ (บังคับ) / tip
- ในบรรทัด "แก้ไข" bold เฉพาะคำที่เปลี่ยน ห้าม bold ทั้งประโยค
- บรรทัด ✨ ใส่เฉพาะเมื่อสั้นลงอย่างมีนัยสำคัญ ไม่งั้นข้าม
- 🎯 **บังคับเสมอ** เช่นเดียวกับ Format A — แทรกก่อนบรรทัด 💡 และคุมรวม ≤ 5 บรรทัด (ตัดบรรทัด ✨ ถ้าจำเป็น)
- 💡 tip 1 บรรทัดภาษาไทย อธิบาย "ทำไม" (เหตุผลด้าน grammar/phrasing) jargon ภาษาอังกฤษ (`auxiliary`, `preposition`) ใช้ได้แต่ตัวอธิบายต้องเป็นไทย

**Example 1 — ถามตารางนัดผิด grammar:**

User: `what time we have meeting tomorrow`

```
||🌐 **คุณเขียน:** "what time we have meeting tomorrow"
**แก้ไข:** "What time **do** we have **the** meeting tomorrow?"
🎯 **ยกระดับ:** "When are we meeting tomorrow?" — native ถามสั้นกว่าด้วย present continuous
💡 คำถามต้องมี auxiliary "do" นำหน้า subject และ meeting ที่เจาะจงต้องมี "the"||
```

**Example 2 — เล่าเรื่องวันนี้ผิด tense:**

User: `I fix the bug yesterday but it come back today`

```
||🌐 **คุณเขียน:** "I fix the bug yesterday but it come back today"
**แก้ไข:** "I **fixed** the bug yesterday but it **came** back today."
🎯 **ยกระดับ:** "I fixed the bug yesterday, but it resurfaced today." — "resurface" คำที่ dev ใช้กับ bug ที่กลับมา
💡 เหตุการณ์ในอดีตต้องใช้ past tense: fix→fixed, come→came||
```

## Format C — Praise

ใช้เมื่อข้อความเป็นอังกฤษล้วนและไม่มี error ชัดเจน

**Output template:**

```
||✅ <คำชมไทย อ้างประโยคของผู้ใช้และบอกจุดที่ดีสั้นๆ>
✨ **กระชับ:** "<shorter version>"
🎯 **ยกระดับ:** "<more idiomatic version>" — <เหตุผลไทยสั้น>||
```

**Rules:**
- 1–3 บรรทัด: ชม / กระชับ (optional) / ยกระดับ (optional)
- คำชมต้องเจาะจง (ชัดเจน / phrasing เป็นธรรมชาติ / preposition ถูก) ไม่ใช่ "ดีมาก" ลอยๆ
- ✨ และ 🎯 ใส่เฉพาะเมื่อมีจริง ห้ามยัดเยียด

**Example 1 — สั่ง bot เช็คของ ประโยคดีอยู่แล้ว:**

User: `Can you check if the deploy succeeded?`

```
||✅ ประโยคนี้ชัดเจน ใช้โครงคำถามถูกต้องและตรงประเด็น||
```

**Example 2 — เล่าเรื่องวันนี้ ประโยคดี มี upgrade:**

User: `Today was pretty busy, I finished three tasks.`

```
||✅ ประโยคนี้เป็นธรรมชาติและกระชับดี
🎯 **ยกระดับ:** "Today was packed — knocked out three tasks." — dev ฝรั่งชอบใช้ "knock out" กับงานที่ทำเสร็จเร็ว||
```

## Skip Rules

ไม่ต้องส่งข้อความ coaching เมื่อ:

| # | Condition | Examples |
|---|-----------|----------|
| 1 | ข้อความ ≤ 2 คำ | `ok`, `ครับ`, `👍`, `yes` |
| 2 | สติกเกอร์ / ไฟล์ / ลิงก์ล้วน ไม่มีข้อความ | ส่งรูปเปล่า, แปะลิงก์เปล่า |
| 3 | ข้อความที่เป็นการตอบคำถามที่ bot เพิ่งถาม | bot ถาม "เอา A หรือ B" แล้วผู้ใช้ตอบ "A" |
| 4 | Pure paste ไม่มี narration | แปะ stack trace ล้วนไม่มีคำพูด |

## What this skill does NOT do

- ❌ ไม่แก้หรือแปล**คำตอบของ bot** — โค้ชเฉพาะข้อความของผู้ใช้
- ❌ ไม่แตะ system message หรือ tool output
- ❌ ไม่โค้ชเนื้อหาภายใน code/log paste — โค้ชเฉพาะส่วน narration
- ❌ ไม่แต่ง 🎯 ยกระดับขึ้นมาเองใน Format C เมื่อประโยคเป็นธรรมชาติอยู่แล้ว (Format A/B บังคับเสมอ)
- ❌ ไม่ block คำตอบหลัก — ต่อท้ายเป็นส่วนของข้อความเดียวตาม AGENTS section rule 3
