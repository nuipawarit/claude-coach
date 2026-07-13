# API Verification Notes — 2026-07-14

ตรวจสอบข้อเท็จจริงเกี่ยวกับ API/config ที่ spec (§9) ติดธงไว้ ก่อนให้ task หลังอ้างอิง

- **`${CLAUDE_PLUGIN_DATA}` มีจริงและ default path**: มีจริง — เป็น environment variable ที่ resolve เป็น persistent directory สำหรับ plugin state ที่รอดจากการ update plugin (ใช้เก็บ `node_modules`, venv, cache, generated code ฯลฯ) โฟลเดอร์นี้ถูกสร้างอัตโนมัติครั้งแรกที่ variable ถูก reference ค่า default path คือ `~/.claude/plugins/data/{id}/` โดย `{id}` คือ plugin identifier (แทนที่อักขระนอก `a-z A-Z 0-9 _ -` ด้วย `-`) เช่น plugin `formatter@my-marketplace` → `~/.claude/plugins/data/formatter-my-marketplace/`. Source: https://code.claude.com/docs/en/plugins-reference (ดึงมา 2026-07-14)

- **รูปแบบ slash เรียก skill ใน plugin**: ใช่ ตรงตามที่คาด — รูปแบบคือ `/plugin-name:skill-name` (namespace ด้วยชื่อ plugin กันชนกับ skill ระดับอื่น) ตัวอย่างจาก docs: `my-plugin/skills/review/SKILL.md` → เรียกด้วย `/my-plugin:review` ดังนั้น `/prompting-coach:toggle` เป็นรูปแบบที่ถูกต้อง (สมมติ plugin ชื่อ `prompting-coach` มี skill ชื่อ `toggle`) Source: https://code.claude.com/docs/en/skills (ดึงมา 2026-07-14, บรรทัด "Plugin skills use a `plugin-name:skill-name` namespace..." และตาราง "Plugin `skills/` subdirectory ... → `/my-plugin:review`")

- **config key ตั้ง model ต่อ agent ของ OpenClaw**: key คือ `agents.list[].model.primary` (รูปแบบเดียวกับ `agents.defaults.model.primary` แต่ตั้งเฉพาะ agent นั้นด้วยการ match `id`) ตัวอย่าง config เพื่อตั้ง agent ชื่อ `research` ให้ใช้ Sonnet:
  ```json5
  {
    agents: {
      list: [
        { id: "research", model: { primary: "anthropic/claude-sonnet-5" } },
      ],
    },
  }
  ```
  Source: https://docs.openclaw.ai/providers/anthropic (ดึงมา 2026-07-14)

- **คำสั่ง health-check ของ OpenClaw daemon**: `openclaw gateway status` — อยู่ในหัวข้อ "Verify the install" ของหน้า install ใช้เพื่อยืนยันว่า Gateway (daemon) กำลังรันอยู่ Source: https://docs.openclaw.ai/install (ดึงมา 2026-07-14)

- **วิธีส่ง env (`DISCORD_BOT_TOKEN`) ให้ daemon ที่รันเป็น LaunchAgent**: docs ไม่ได้พูดถึง `launchctl setenv` โดยตรง แต่ให้กลไกของ OpenClaw เอง 2 ทาง: (1) รัน `export DISCORD_BOT_TOKEN="YOUR_BOT_TOKEN"` แล้วรัน `openclaw gateway install` จาก shell session เดียวกันที่ตั้ง env ไว้แล้ว (ตอน install ครั้งแรกของ managed service) หรือ (2) เก็บค่าไว้ใน `~/.openclaw/.env` เพื่อให้ service resolve env SecretRef ได้ใหม่ทุกครั้งที่ restart (เหมาะกับ daemon/LaunchAgent ระยะยาวเพราะไม่ผูกกับ shell session ที่ตั้งตอน install) Source: https://docs.openclaw.ai/channels/discord (ดึงมา 2026-07-14)
