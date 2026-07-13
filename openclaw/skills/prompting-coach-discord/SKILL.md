---
name: prompting-coach-discord
description: โค้ชคุณภาพคำสั่งงานที่ผู้ใช้พิมพ์ถึง bot — ชี้ gap เดียวที่คุ้มสุด + ตัวอย่าง prompt ที่ดีกว่า เฉพาะข้อความสั่งงาน
---

# prompting-coach-discord

A behavior-shaping skill that runs on every chat message that is a **task instruction** (ขอให้ทำ/สร้าง/วิเคราะห์/ค้น/แก้อะไรให้ — see `AGENTS-coaching-section.md` rule 2). Its job is to evaluate the effectiveness of the user's task message and emit one 🧭 coaching line — as the **first line** inside the shared spoiler block with `english-coach-discord`. Plain conversational chat gets no line at all.

Source of truth: Anthropic's Prompting Best Practices (Claude 4.6+ / Claude 5 family guidance), condensed into the Principle Catalog below.

The golden rule behind every principle (quoted verbatim from the guide): *"Show your prompt to a colleague with minimal context on the task and ask them to follow it. If they'd be confused, Claude will be too."*

## Chat rule — never gate, always answer

Discord chat has no `AskUserQuestion`. This skill **never stops or blocks** a reply to ask for clarification — it always answers/executes the task message inline, then appends the 🧭 coaching line. There is no pre-flight gate on this surface — coach and proceed, every time.

## When to trigger

Only on messages that are task instructions per AGENTS section rule 2. Plain conversation, small talk, or replies to the bot's own question get no 🧭 line (english-coach-discord's block, if any, may still apply independently).

## Effectiveness Checklist

ประเมินข้อความสั่งงานด้วยคำถามเหล่านี้ — "ไม่ผ่าน" ข้อไหนที่**สำคัญต่องานนี้จริงๆ**ถือเป็น gap อย่าจับผิดเรื่องเล็กในงานเล็ก:

1. **Deliverable ชัดเจนไหม?** บอกได้ไหมว่า "เสร็จ" หน้าตาเป็นยังไง
2. **ให้ทำเลยหรือแค่แนะนำ?** ชัดไหมว่าต้องการให้ bot ลงมือทำหรือแค่ตอบคำแนะนำ
3. **ระบุเป้าหมายไหม?** ไฟล์ / ช่อง / บริการ / project ระบุชื่อหรือปล่อยให้เดา
4. **ให้เหตุผล (motive) มาด้วยไหม?** constraint ที่มาพร้อมเหตุผลช่วยให้ generalize ถูก
5. **บอกรูปแบบผลลัพธ์ไหม (เมื่อสำคัญ)?** พูดเชิงบวกว่าต้องการอะไร ไม่ใช่แค่ห้ามอะไร
6. **ระบุ scope ชัดไหม?** "ทำทุกอัน" ต้องเขียนว่า "ทุกอัน" ตรงๆ ไม่ปล่อยให้เดา
7. **spec ครบในข้อความเดียวไหม?** สำหรับงานที่มีหลาย constraint ควรมาในข้อความเดียว ไม่ทยอยส่ง
8. **ขอ above-and-beyond ไหม (งานสร้างสรรค์ปลายเปิด)?** ระบุว่าอยากได้ครบทุกฟีเจอร์/เกินพื้นฐาน
9. **ไม่ over-specify เกินไปไหม?** สั่งเป็นขั้นตอนละเอียดยิบ/CRITICAL ซ้ำๆ กลับทำให้ผลแย่ลงสำหรับโมเดลรุ่นใหม่
10. **มี success criteria ไหม (งาน research/investigation)?** นิยาม "เสร็จ" และแหล่งอ้างอิงที่ต้อง cross-check

เลือก **gap เดียวที่คุ้มค่าที่สุด** สำหรับบรรทัด 🧭 — gap เดียวที่โค้ชดีกว่า laundry list ที่ไม่มีใครอ่าน

## Principle Catalog

ชื่อ principle อ้างอิงในบรรทัด 🧭 (ใส่ในวงเล็บท้ายถ้าต้องการ) — อิงตาม best-practices guide:

| Principle | Flag when | Coaching angle |
|---|---|---|
| `be-explicit` | Deliverable กว้างเกินไป ("ทำให้หน่อย") | ระบุ feature/data/interaction ที่ต้องการ |
| `ask-for-more` | งานสร้างสรรค์ปลายเปิด คาดหวัง default | เพิ่ม "ทำให้ครบ เกินพื้นฐานไปเลย" |
| `give-motive` | Constraint/request เปล่าๆ ไม่มีเหตุผล | ใส่ "เพราะ..." Claude generalize ถูกจากเหตุผล |
| `action-vs-advice` | "ลองดูหน่อย" กำกวม | บอกตรงๆ ว่า "แก้เลย" หรือ "วิเคราะห์อย่างเดียวยังไม่ต้องแก้" |
| `name-targets` | ไม่ระบุไฟล์/branch/service | ระบุเป้าหมายชัดเจน ป้องกันการเดาผิด |
| `output-shape` | ต้องการ format เฉพาะแต่ไม่บอก | ระบุ structure เชิงบวก ไม่ใช่แค่ "ห้าม..." |
| `front-load` | spec ทยอยส่งหลายข้อความ | รวม task + intent + constraint ไว้ข้อความเดียว |
| `scope-quantifier` | ตั้งใจจะให้ "ทุกอัน" แต่ไม่ได้เขียน | เขียน "ทุกรายการ" ตรงๆ อย่าปล่อยให้ตีความ |
| `dont-overspec` | สั่งขั้นตอนละเอียดยิบ/CRITICAL ซ้ำ | ใช้คำสั่งสั้น กระชับ โมเดลรุ่นใหม่ทำได้ดีกว่า |
| `assign-role` | งานต้องการ judgment เฉพาะทาง ไม่ตั้ง persona | ใส่ role สั้นๆ เช่น "ในฐานะ security engineer ช่วยตรวจ..." |
| `success-criteria` | งาน research/investigation ไม่มีนิยาม "เสร็จ" | บอกเกณฑ์ความสำเร็จ + ขอ cross-check |
| `scope-discipline` | งานแก้บั๊ก/ฟีเจอร์เล็ก เสี่ยงขยายขอบเขต | บอก "แก้เฉพาะที่ขอ อย่าปรับโครงสร้างรอบข้าง" |

## Output — single line

**ทุกงานที่เข้าเกณฑ์นี้ ให้ 🧭 บรรทัดเดียว** (ไม่มี Format A/B แยก ไม่มี gate) — เป็นบรรทัดแรกในก้อน spoiler ร่วมกับ english-coach-discord:

```
🧭 <gap สั้นๆ ภาษาไทย>: "<ตัวอย่าง prompt ที่ดีกว่า ภาษาเดียวกับผู้ใช้>"
```

**Rules:**
- โค้ช gap เดียวที่คุ้มสุด ตัวอย่าง prompt ต้องพิมพ์ได้จริง ไม่ใช่ essay ยาว
- ภาษาของตัวอย่าง prompt = ภาษาที่ผู้ใช้พิมพ์มา (ไทยพิมพ์ไทย อังกฤษพิมพ์อังกฤษ) technical term คงภาษาอังกฤษเสมอ
- คงชื่อไฟล์ / identifier / project name จากต้นฉบับ ใส่ placeholder (`<file>`, `<criteria>`) เฉพาะจุดที่ผู้ใช้ต้องกรอกเอง
- ถ้าข้อความสั่งงานดีอยู่แล้ว (ไม่มี gap ที่คุ้มค่า) → **ข้ามบรรทัดนี้ไปเลย ไม่ต้องชม** (ต่างจากฉบับ marketplace ที่มี Format B ชม — บนแชตเน้นสั้น ไม่ชมทุกครั้ง)
- รวมกับ english-coach-discord แล้วต้อง ≤ 5 บรรทัดทั้งก้อน ห้าม `>`, ห้ามตาราง, ห้าม heading

**Example 1 — deliverable กว้างเกินไป:**

User (สั่งงานใน Discord): `ช่วยทำหน้า about ให้หน่อย`

```
🧭 deliverable กว้างไป ต้องเดา content เอง: "ทำหน้า about ให้มี section ทีมงานกับ timeline บริษัท ทำให้ครบ เกินพื้นฐานไปเลย"
```

**Example 2 — ไม่ระบุเป้าหมาย:**

User: `fix the bug, it's slow`

```
🧭 ไม่ได้ระบุไฟล์/ฟังก์ชันที่ต้องแก้: "Fix the slow query in src/api/orders.ts — profile first, then fix it directly."
```

**Example 3 — งานดีอยู่แล้ว:**

User: `เช็ค service order-api ให้หน่อยว่ายัง alive อยู่มั้ย ผ่าน health endpoint`

→ ไม่มี gap ที่คุ้มค่า → ไม่ต้องมีบรรทัด 🧭

## What this skill does NOT do

- ❌ ไม่หยุดรอ user ตอบก่อนทำงาน (ไม่มี AskUserQuestion / gate บนแชต) — ตอบและโค้ชไปพร้อมกันเสมอ
- ❌ ไม่แก้ grammar/สะกด — เป็นหน้าที่ของ english-coach-discord
- ❌ ไม่โค้ชข้อความสนทนาทั่วไปที่ไม่ใช่การสั่งงาน
- ❌ ไม่ผลิต laundry list — เลือก gap เดียวเท่านั้น
- ❌ ไม่แต่ง gap ขึ้นมาเองเมื่อ prompt ดีอยู่แล้ว — ข้ามบรรทัดไปเลย
