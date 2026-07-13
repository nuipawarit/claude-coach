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
