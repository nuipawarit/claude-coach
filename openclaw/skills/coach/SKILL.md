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
