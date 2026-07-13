# OpenClaw Install Notes — 2026-07-14

ผลติดตั้ง OpenClaw ตาม plan Task 11 — **เบี่ยงจาก plan: ใช้ Docker แทน native daemon/LaunchAgent** (ผู้ใช้สั่งกลางคัน "ใช้ docker สำหรับ openclaw")

## สิ่งที่เกิดขึ้นก่อนเปลี่ยนเส้นทาง

- รัน `curl -fsSL https://openclaw.ai/install.sh | bash` ไปแล้วหนึ่งรอบ (native path) — installer ติดตั้ง Node.js v24 ผ่าน Homebrew (`node@24`, keg-only) และ openclaw npm global v2026.7.1 แต่ยังไม่ได้ onboard/ติด daemon (no TTY)
- ถอน npm global ออกแล้ว (`/opt/homebrew/opt/node@24/bin/npm uninstall -g openclaw`) — **`node@24` จาก brew ยังอยู่** (ไม่เกี่ยวกับ openclaw แล้ว ถอนได้ถ้าไม่ใช้)

## Docker setup ที่ใช้จริง

- Source checkout: `~/Projects/openclaw` (clone `--depth 1` เอา compose files + `scripts/docker/setup.sh`)
- คำสั่ง setup:
  ```bash
  cd ~/Projects/openclaw
  export OPENCLAW_IMAGE="ghcr.io/openclaw/openclaw:latest" \
         OPENCLAW_HOME_VOLUME="openclaw_home" \
         OPENCLAW_CONFIG_DIR="$HOME/.openclaw" \
         OPENCLAW_WORKSPACE_DIR="$HOME/.openclaw/workspace" \
         OPENCLAW_SKIP_ONBOARDING=1
  ./scripts/docker/setup.sh
  ```
- ผล: gateway container `openclaw-openclaw-gateway-1` รัน, bind `lan`, control UI `http://127.0.0.1:18789/`
- Paths (host): config `~/.openclaw`, workspace `~/.openclaw/workspace` — mount เข้า container ที่ `/home/node/.openclaw`, `/home/node/.openclaw/workspace`
- Home volume `openclaw_home` persist `/home/node` (เก็บ Claude CLI + OAuth token ข้าม restart)

## Health check (ผ่าน)

```bash
curl -fsS http://127.0.0.1:18789/healthz   # {"ok":true,"status":"live"}
curl -fsS http://127.0.0.1:18789/readyz    # {"ready":true}
```

หมายเหตุ: `openclaw-cli gateway probe` จากใน container ฟ้อง `ECONNREFUSED 127.0.0.1:18789` — ปกติ (loopback ใน cli container คนละ network namespace กับ gateway) ใช้ healthz/readyz จาก host แทน

## Provider: Claude CLI (ตาม plan — ไม่ใช้ API key)

- ติดตั้ง Claude Code CLI ในบ้าน container: `docker compose ... run --rm --entrypoint sh openclaw-cli -lc 'curl -fsSL https://claude.ai/install.sh | bash'`
- Login: ผู้ใช้รัน `docker compose ... run --rm --entrypoint /home/node/.local/bin/claude openclaw-cli auth login` (OAuth ใน browser) — ยืนยันแล้ว `subscriptionType: "max"`, `apiProvider: "firstParty"`
- Model config apply แล้วผ่าน `config patch --file /home/node/.openclaw/claude-cli.patch.json5` (ไฟล์อยู่ `~/.openclaw/claude-cli.patch.json5` บน host):
  ```json5
  {
    agents: {
      defaults: {
        cliBackends: { "claude-cli": { command: "/home/node/.local/bin/claude" } },
        model: { primary: "anthropic/claude-sonnet-5" },
        models: { "anthropic/claude-sonnet-5": { agentRuntime: { id: "claude-cli" } } },
      },
    },
  }
  ```
  (รูปแบบ key ยืนยันจาก https://docs.openclaw.ai/providers/anthropic ดึงมา 2026-07-14 — model id ใช้ `anthropic/*` + เลือก runtime ที่ `agentRuntime.id: "claude-cli"` ระดับ model config)

## ผลกระทบต่อ task ถัดไป

- **Task 12 (Discord token):** ใส่ `DISCORD_BOT_TOKEN=<token>` ใน `~/.openclaw/.env` (config dir mount — OpenClaw resolve env SecretRef ตอน restart) แล้ว restart gateway; ใช้ `openclaw/discord.patch.json5` จาก repo ตามเดิมผ่าน `config patch`
- **Task 13 (workspace):** copy assets ไป `~/.openclaw/workspace` บน host ได้ตรงๆ (mount แล้ว)
- **ทุกคำสั่ง compose ต้องใส่ `-f docker-compose.yml -f docker-compose.extra.yml` เสมอ** — extra file เป็นตัว mount volume `openclaw_home` (`/home/node` = claude CLI + OAuth) เข้า gateway; restart โดยไม่ใส่จะได้ container ที่ไม่มี claude binary → agent turn ตาย `write EPIPE` (พลาดจริงมาแล้ว — ดู `2026-07-live-verify-discord.md` รอบที่ 1)
- Restart daemon = `cd ~/Projects/openclaw && docker compose -f docker-compose.yml -f docker-compose.extra.yml down && docker compose -f docker-compose.yml -f docker-compose.extra.yml up -d openclaw-gateway`
- คำสั่ง CLI ทุกตัว = `cd ~/Projects/openclaw && docker compose -f docker-compose.yml -f docker-compose.extra.yml run -T --rm openclaw-cli <command>`
