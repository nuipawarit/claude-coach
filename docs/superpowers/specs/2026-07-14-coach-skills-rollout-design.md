# Design Spec: Coach Skills Rollout

- **วันที่:** 2026-07-14
- **สถานะ:** รอ user review
- **ที่มา:** brainstorming session (board: https://claude.ai/code/artifact/fbc5d5b4-6f60-42a0-a5f5-8e6d45385dc6)

## 1. เป้าหมาย

นำ skill สองตัวที่ใช้งานจริงบนเครื่องหลักอยู่แล้ว — `prompting-coach` (โค้ชคุณภาพ prompt ตาม Anthropic best practices) และ `english-coach` (โค้ชภาษาอังกฤษจาก prompt ของผู้ใช้) — ออกไปใช้งานนอกเครื่อง ในสองปลายทาง:

1. **Track 1 — Plugin Marketplace:** แจกให้ผู้ใช้ Claude Code คนอื่นติดตั้งผ่าน plugin marketplace บน GitHub
2. **Track 2 — OpenClaw + Discord:** ใช้เองผ่าน Discord bot ที่ขับด้วย OpenClaw เพื่อให้ได้ coaching ระหว่างแชตจากมือถือได้ทุกที่

Scope ของรอบนี้คือ **แผนอย่างเดียว** — ได้ spec ฉบับนี้ + implementation plan แล้วเก็บไว้ dispatch ภายหลัง ยังไม่ implement

### Non-goals (v1)

- ไม่ generalize `english-coach` เป็น language-coach หลายภาษา (เก็บเป็น roadmap)
- ไม่ทำ Telegram channel (แต่บันทึกไว้ว่าถ้าทำจะได้ true-collapse block ฟรี)
- ไม่มี monetization / ไม่มี analytics ฝั่งผู้ใช้ plugin
- ไม่แตะ workflow บนเครื่องหลักจนกว่า marketplace version จะพิสูจน์ตัวเอง (การย้ายเครื่องหลักไปใช้ plugin ของตัวเองเป็น optional task ท้ายแผน)

## 2. สิ่งที่มีอยู่ (สำรวจแล้ว)

| ของ | ที่อยู่ | สภาพ |
|---|---|---|
| prompting-coach | `~/.claude/skills/prompting-coach/SKILL.md` | standalone ประกาศตัวเองชัดว่าไม่พึ่ง skill อื่น; commentary ภาษาไทย hardcode |
| english-coach | `~/.claude/skills/english-coach/SKILL.md` | standalone; commentary ภาษาไทย hardcode; description ยาวมาก |
| Enforcement | `~/.claude/settings.json` → `UserPromptSubmit` hook | `echo` ข้อความ COACHING ENFORCEMENT ก้อนเดียว inline — ไม่มี script แยก |
| Caveman interop | `~/.claude/CLAUDE.md` | อยู่นอกตัว skill ทั้งสอง — ไม่ต้อง port |

Surface ที่ต้อง port จึงเล็ก: SKILL.md สองไฟล์ + hook text หนึ่งก้อน

## 3. การตัดสินใจหลัก (จบแล้ว)

| ประเด็น | ตัดสินใจ |
|---|---|
| ภาษา commentary (marketplace) | แยกกลยุทธ์ราย skill — prompting-coach: อังกฤษ default + config เปลี่ยนภาษาได้; english-coach: Thai-first (คุณค่าหลักคือ Thai↔EN) |
| Packaging | marketplace repo เดียว บรรจุ 2 plugins แยก ติดตั้งอิสระต่อกัน |
| Enforcement (marketplace) | UserPromptSubmit hook ต่อ plugin + toggle skill ปิด/เปิดได้ |
| โหมด Discord | always-on ทุกข้อความที่คุยกับ bot |
| รูปแบบ block บน Discord | ข้อความท้ายแยกต่างหาก ห่อทั้งก้อนใน spoiler ของ Discord (ซ่อนจนคลิก) — ผลตรวจสอบยืนยันว่า Discord ไม่มี true-collapse ใน plain markdown ถึง ก.ค. 2026 (สิ่งที่จำได้คือ expandable blockquote ของ Telegram); spoiler คือตัวใกล้เคียงสุด ผู้ใช้ยืนยันเลือกเองหลังทราบผลตรวจ |
| Host + auth (Track 2) | Phase A: Mac เครื่องหลัก รัน daemon + runtime `claude-cli` ใช้ Claude Max subscription เดิม (ไม่มีค่า API เพิ่ม); Phase B (optional ภายหลัง): Docker บน VPS + `ANTHROPIC_API_KEY` ถ้าต้องการ uptime 24/7 |
| Scope วันนี้ | Plan อย่างเดียว |
| Repo | `~/Projects/claude-coach` — เป็นทั้งที่เก็บ spec/plan และ marketplace repo ตัวจริงตอน execute |

## 4. Track 1 — Plugin Marketplace

### 4.1 โครง repo

```
claude-coach/                                # GitHub public repo = marketplace
├── .claude-plugin/
│   └── marketplace.json                     # name: "claude-coach", owner, plugins[2]
├── plugins/
│   ├── prompting-coach/
│   │   ├── .claude-plugin/plugin.json       # name, version 0.1.0, description, license
│   │   ├── skills/
│   │   │   ├── prompting-coach/SKILL.md     # ฉบับ EN-default + config ภาษา
│   │   │   └── toggle/SKILL.md              # /prompting-coach:toggle on|off|lang <code>
│   │   └── hooks/
│   │       ├── hooks.json                   # UserPromptSubmit → coach-enforce.sh
│   │       └── coach-enforce.sh             # POSIX sh, zero dependency
│   └── english-coach/
│       ├── .claude-plugin/plugin.json
│       ├── skills/
│       │   ├── english-coach/SKILL.md       # ฉบับ Thai-first (core เดิม ตัด machine-specific)
│       │   └── toggle/SKILL.md              # /english-coach:toggle on|off
│       └── hooks/
│           ├── hooks.json
│           └── coach-enforce.sh
├── docs/superpowers/specs/                  # spec + plan (ไฟล์นี้)
├── README.md                                # อังกฤษ: install, ตัวอย่าง, config, known limitations
└── LICENSE                                  # MIT
```

ข้อเท็จจริงจาก docs ที่โครงนี้อิง: `.claude-plugin/` ใน plugin เก็บได้เฉพาะ `plugin.json`; `skills/` `hooks/` ต้องอยู่ plugin root; `commands/` เป็น backward-compat แล้ว official แนะนำใช้ skill แทน (ที่มา: code.claude.com/docs/en/plugins-reference)

### 4.2 กลไก enforcement + config

- `hooks.json` ผูก event `UserPromptSubmit` (รองรับเต็มรูปแบบ, default timeout 30s) เรียก `${CLAUDE_PLUGIN_ROOT}/hooks/coach-enforce.sh`
- `coach-enforce.sh` เป็น POSIX sh ล้วน ไม่พึ่ง jq/node:
  1. อ่านไฟล์ config รูปแบบ `key=value` จาก `${CLAUDE_PLUGIN_DATA}/config` (dir นี้คงอยู่ข้าม plugin update — ต่างจาก `${CLAUDE_PLUGIN_ROOT}` ที่เปลี่ยนทุก update)
  2. `enabled=0` → exit 0 เงียบๆ (ปิด coaching ทั้ง turn-level)
  3. `enabled=1` (default เมื่อไม่มีไฟล์) → echo ข้อความ enforcement เฉพาะของ skill ตัวเอง — แยกร่างมาจาก echo รวมบนเครื่องหลัก โดย plugin ละตัวพูดถึงเฉพาะ skill ของตัวเอง ติดตั้งคู่กันแล้วได้ผลรวมเท่าเครื่องหลัก ติดตั้งตัวเดียวก็สมบูรณ์ในตัว
  4. เฉพาะ prompting-coach: แนบบรรทัด `commentary language: <lang>` จาก config (default `en`)
- toggle skill (`user-invocable`) รับ args `on|off|lang <code>` แล้วเขียนไฟล์ config ด้วยคำสั่ง shell ธรรมดา — ตัวอย่างการเรียก: `/prompting-coach:toggle off`
- Hook fail-open: script error ใดๆ ต้องไม่ block prompt ของผู้ใช้ (ไม่ใช้ `decision: "block"`)

### 4.3 การแปลง SKILL.md

**prompting-coach (ฉบับ marketplace):**
- Commentary ทุกส่วน (verdict block, gate question, option labels) เปลี่ยน default เป็นอังกฤษ; เพิ่มกติกา "เขียน commentary ตามภาษาใน config ที่ hook inject; improved prompt ยังคงเป็นภาษาของผู้ใช้เสมอ" (หลักการเดิมของ skill: prompting effectiveness เป็น language-independent)
- ตัวอย่างในไฟล์ (Format A/B/G examples) แปลงเป็นอังกฤษ เพื่อให้ผู้ใช้ทั่วโลกอ่าน template ออก
- Gate (Format G) ใช้ AskUserQuestion ซึ่งมีในทุก Claude Code — ไม่ต้องแปลงกลไก

**english-coach (ฉบับ marketplace):**
- Core เดิมคงไว้ (Thai-first คือจุดขาย) — ตัดเฉพาะการอ้างถึงสภาพแวดล้อมเครื่องหลักถ้ามี
- README ระบุชัดว่า plugin นี้ออกแบบสำหรับ Thai speakers learning English; ผู้ใช้ภาษาอื่น รอ language-coach (roadmap)

**ทั้งคู่:**
- `description` ใน frontmatter ตัดให้ ≤ ~300 ตัวอักษร — listing budget ของเครื่องผู้ใช้อื่นมีจำกัด (`description`+`when_to_use` cap 1,536 chars/skill และ budget รวม ~1% ของ context window) และพฤติกรรม "ทำทุก turn" มี hook การันตีอยู่แล้ว ไม่ต้องอัด trigger ยาวๆ ใน description
- Frontmatter ใส่ `name` + `description` ครบถ้วนชัดเจน (มาตรฐาน agentskills.io)

### 4.4 marketplace.json + plugin.json

- `marketplace.json` (ที่ `.claude-plugin/` ของ repo root): `name: "claude-coach"`, `owner {name}`, `plugins: [{name, source: "./plugins/prompting-coach", description, category, keywords}, {...english-coach}]`
- `plugin.json` ต่อ plugin: `name` (required, kebab-case), `version` (semver เริ่ม 0.1.0 — bump ทุก release ไม่งั้นผู้ใช้ไม่ได้ update), `description`, `license: "MIT"`, `keywords`
- คำสั่งฝั่งผู้ใช้ (ลง README):
  - `/plugin marketplace add <github-owner>/claude-coach` (`<github-owner>` = GitHub username ของเจ้าของ ณ ตอน push)
  - `/plugin install prompting-coach@claude-coach` และ/หรือ `/plugin install english-coach@claude-coach`

### 4.5 คุณภาพก่อนปล่อย

1. `claude plugin validate . --strict` ต้องผ่าน
2. ติดตั้งจริงจาก local path ในเซสชัน Claude Code ใหม่ → ยิง prompt ไทย/อังกฤษ/สั่งงานคลุมเครือ → เห็น verdict block + english block + gate ทำงาน → `/prompting-coach:toggle off` → block หาย (live-verify)
3. Push GitHub + tag `v0.1.0` (ตามคำสั่ง end-of-run ที่ user อนุมัติใน plan)

## 5. Track 2 — OpenClaw + Discord

### 5.1 สถาปัตยกรรม

```
Discord (มือถือ/desktop)
   └─ DM ถึง bot (dmPolicy: pairing — คนนอกใช้ไม่ได้)
        └─ OpenClaw gateway (Mac เครื่องหลัก, LaunchAgent daemon)
             └─ agent runtime: claude-cli (reuse Claude Max login บนเครื่องเดียวกัน)
                  ├─ AGENTS.md ← กติกา coaching (stable context ทั้ง session)
                  ├─ <workspace>/skills/prompting-coach-discord/SKILL.md
                  └─ <workspace>/skills/english-coach-discord/SKILL.md
```

- ติดตั้ง: `openclaw onboard --install-daemon` (macOS → LaunchAgent)
- Auth: เลือก "Claude CLI" ใน onboard → `agentRuntime.id: "claude-cli"` — ต้องรันบน host เดียวกับที่ Claude Code login ไว้ (Mac เครื่องนี้ตรงเงื่อนไข) → ไม่มีค่า API เพิ่มจาก Max subscription
- Model ของ agent ตั้งเป็น Sonnet — งาน coaching เป็นงาน format ไม่ต้องใช้ frontier model (วินัยต้นทุนเดิม)
- Discord token: `channels.discord.token = {source:"env", id:"DISCORD_BOT_TOKEN"}` — token อยู่ใน env เท่านั้น ห้ามลงไฟล์ที่ commit
- v1 เน้น DM (session หลักร่วมกัน `agent:main:main` + MEMORY.md auto-load เฉพาะ DM); guild channel เปิดทีหลังได้ผ่าน `groupPolicy: "allowlist"`

### 5.2 ทำไม enforcement อยู่ใน AGENTS.md

OpenClaw ไม่มีกลไก inject ต่อข้อความแบบ UserPromptSubmit hook — AGENTS.md/SOUL.md โหลดครั้งเดียวตอน session start เป็น "stable" context เหนือ prompt-cache boundary (ที่มา: docs.openclaw.ai/concepts/system-prompt) ดังนั้นกติกา coaching จึงเขียนเป็น section ใน AGENTS.md ให้มีผลตลอด session ส่วน SKILL.md สองตัวทำหน้าที่เก็บ template + decision tree ฉบับเต็มให้ agent เปิดอ่านเมื่อต้องใช้

### 5.3 กติกา coaching ฉบับ Discord (สรุปที่จะลง AGENTS.md)

1. **english-coach:** ทุกข้อความ natural language ของผู้ใช้ → ประเมินตาม decision tree เดิม (Format A/B/C)
2. **prompting-coach:** เฉพาะข้อความที่เป็น "คำสั่งงาน" ถึง bot (ขอให้ทำ/วิเคราะห์/สร้างอะไร) — แชตสนทนาทั่วไปไม่มี prompt ให้โค้ช ข้ามไป
3. **รูปแบบ block:** ส่งเป็น**ข้อความแยกต่างหากต่อท้าย**คำตอบหลักเสมอ ห่อทั้ง block ใน spoiler `||...||` คู่เดียว (ซ่อนจนคลิก) รวม ≤ 5 บรรทัด ใช้ emoji นำ (🧭/🌐/✨/🎯/💡) แทนโครง blockquote เดิม
4. **ห้ามใช้:** blockquote (render เพี้ยนบน Discord), ตาราง (channel เป็น plain text), heading
5. เหตุที่แยกข้อความ: Discord auto-chunk ที่ 2000 chars / 17 บรรทัด — ถ้าคู่ `||...||` โดนผ่ากลาง chunk รูปแบบ spoiler จะพังทั้งก้อน; block แยกที่สั้นเสมอไม่มีทางโดนตัด และผู้ใช้กดดูเมื่อพร้อม/อ่านข้ามได้ง่าย

ตัวอย่างหน้าตาจริง:

```
[ข้อความ 1 — คำตอบหลักของ bot ตามปกติ]

[ข้อความ 2]
||🧭 prompt: ระบุช่วงเวลา + format ที่อยากได้ เช่น "สรุป error log วันนี้เป็น 5 bullet"
🌐 EN: "Summarize today's server logs for me."
🎯 "Give me a rundown of today's logs." — สำนวน native กว่า||
```

### 5.4 การแปลง SKILL.md ฉบับ Discord

- แตกจาก core เดียวกับฉบับ marketplace (single source ก่อน แล้ว fork ปรับ format)
- Frontmatter ต้องมี `name` + `description` (OpenClaw เข้มกว่า Claude Code — parse YAML ก่อน มี fallback parser; เขียน YAML ให้สะอาด)
- วางที่ `<workspace>/skills/` (precedence สูงสุดในลำดับโฟลเดอร์ skill ของ OpenClaw)
- Template ทุกตัวในไฟล์เปลี่ยนจาก blockquote → บรรทัดธรรมดาห่อใน spoiler `||...||` ก้อนเดียว และตัวอย่างเปลี่ยนเป็นบริบทแชต (ไม่ใช่บริบท coding terminal)

## 6. ลำดับ execute (โครงของ implementation plan)

| Phase | เนื้องาน | Verify |
|---|---|---|
| 0 | สกัด core: SKILL.md สองตัวฉบับ portable (EN-default prompting-coach, ตัด machine-specific, trim descriptions) | อ่านทวน + `claude plugin validate` หลังประกอบ |
| 1 | Track 1: โครง repo, marketplace.json, plugin.json ×2, hooks + toggle ×2, README, validate, ติดตั้ง local ทดสอบจริง, push + tag | live-verify ในเซสชันใหม่ตาม §4.5 |
| 2 | Track 2: ติดตั้ง OpenClaw daemon, onboard claude-cli, Discord bot + token (user สร้างใน Developer Portal — มีจังหวะรอ), config DM pairing, AGENTS.md + skills ฉบับ Discord, คุยทดสอบจาก DM จริง | live-verify: ส่งข้อความไทย/อังกฤษ/สั่งงาน แล้วเห็น block `-#` ถูก format |
| — | Optional ท้ายสุด: ย้ายเครื่องหลักมาใช้ plugin ของตัวเอง (ลบ user skills + echo hook เดิม) | เซสชันใหม่ทำงานเหมือนเดิม |

ทุก phase ใช้ **live-verify** (ตามที่ user เลือกในตอนถาม scope — งานเป็น config/markdown เกือบทั้งหมด ไม่มี unit ให้ TDD)

## 7. ความเสี่ยงและการรับมือ

| ความเสี่ยง | รับมือ |
|---|---|
| Hook ทุก turn รบกวนผู้ใช้บางคน → uninstall | `/…:toggle off` ปิดได้ทันที + README บอกตรงๆ ว่า plugin นี้ opinionated by design |
| Windows: hook เป็น sh | ผ่าน Git Bash ได้ตามปกติของ Claude Code hooks แต่ยังไม่ทดสอบจริง → ระบุ README เป็น known limitation; hook เขียนแบบ fail-open |
| OpenClaw docs ขัดกันเอง (chunk 4000 vs 2000) | ยึด 2000 (Discord hard cap); block แยก-สั้นทำให้ประเด็นนี้แทบไม่มีผล และกันคู่ spoiler โดนผ่ากลางด้วย |
| Blockquote บน Discord เพี้ยน (พบใน issue tracker, ยังไม่ยืนยันจาก docs หลัก) | design เลิกใช้ blockquote ตั้งแต่ต้น — ไม่ depend กับ bug นี้ทั้งขาไปขากลับ |
| `${CLAUDE_PLUGIN_DATA}` เป็น feature ค่อนข้างใหม่ | ถ้าไม่มีจริงตอน implement → fallback เขียน config ที่ `~/.claude/coach-<plugin>.conf` (plan จะมี task ยืนยัน) |
| OpenClaw YAML frontmatter parser เข้มกว่า | เขียน frontmatter YAML มาตรฐาน ไม่ใช้ syntax แผลงๆ |
| รายละเอียด API เล็กๆ ยังไม่ยืนยัน: รูปแบบชื่อ slash ของ toggle skill ใน plugin (`/prompting-coach:toggle`?) และ config key ตั้ง model ต่อ agent ของ OpenClaw | plan มี task ยืนยันจาก docs/ทดลองจริง ก่อนเขียนส่วนที่ depend |
| Mac หลับ → bot Discord เงียบ | ยอมรับใน Phase A (personal use); แก้จริงคือ Phase B (VPS) เมื่อพร้อมจ่าย API |

## 8. Roadmap (นอก scope v1 — จดกันลืม)

- **language-coach:** generalize english-coach ให้ config คู่ภาษา L1→L2 ได้
- **Telegram channel บน OpenClaw:** ได้ expandable blockquote (`**>`) = true collapse ที่ตามหา โดย code ฝั่ง skill แทบไม่ต้องแก้
- **Daily recap:** cron ของ OpenClaw สรุปคำที่ถูกแก้ประจำวัน
- **Guild สำหรับเพื่อน:** เปิด allowlist channel ให้เพื่อนคนไทยใช้ english-coach ร่วมกัน

## 9. อ้างอิง (ยืนยันเมื่อ 2026-07-14)

- https://code.claude.com/docs/en/plugins-reference — โครง plugin, plugin.json, hooks ใน plugin, `${CLAUDE_PLUGIN_ROOT}`/`${CLAUDE_PLUGIN_DATA}`
- https://code.claude.com/docs/en/plugin-marketplaces — marketplace.json schema, คำสั่ง add/install, `claude plugin validate`
- https://code.claude.com/docs/en/hooks — UserPromptSubmit
- https://code.claude.com/docs/en/skills — frontmatter, listing budget
- https://docs.openclaw.ai/tools/skills — AgentSkills spec, โฟลเดอร์ skill precedence
- https://docs.openclaw.ai/concepts/system-prompt — AGENTS.md โหลดครั้งเดียว/stable context
- https://docs.openclaw.ai/channels/discord — token, dmPolicy, groupPolicy, session ต่อ channel
- https://docs.openclaw.ai/gateway/config-channels — textChunkLimit 2000, maxLinesPerMessage 17
- https://docs.openclaw.ai/providers/anthropic — claude-cli runtime / API key
- https://support.discord.com/hc/en-us/articles/210298617 + File-Preview article — markdown, subtext `-#`, ไฟล์แนบพับได้
- https://core.telegram.org/bots/api — expandable blockquote (เทียบเคียง)
