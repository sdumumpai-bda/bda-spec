# /bda-agent

> **Subagent management** — list/enable/disable + สร้าง agent specialized ตาม project context จริง

[← กลับ usage/README](./README.md) · [Full spec: `commands/bda-agent.md`](../commands/bda-agent.md)

## เมื่อไหร่ใช้

- หลัง `/bda-init` ใน greenfield → agents ยัง generic อยาก specialize ตาม PRD/SRS
- Project โตขึ้น → agent `backend` ควรรู้ stack จริง (เช่น .NET 8 + dotnet test, ไม่ใช่ generic)
- อยากเพิ่ม agent ใหม่ (เช่น `data-pipeline`, `infra-aws`, `seo-content`) ที่ไม่ใช่ในชุด default
- ตรวจ agent definition ครบไหม (audit)

## Quick start

```
/bda-agent list
```

ตัวอย่าง output:
```
Agent          Enabled   Last regenerated   Spec lines   Notes
docs           ✓         init (generic)     220          always-on, vault keeper
verifier       ✓         init (generic)     180          always-on
security       ✓         init (generic)     200          always-on
backend        ✓         2026-05-19         320          specialized: .NET 8 API
frontend       ✓         2026-05-20         380          specialized: Next.js 14 + DS
mobile         ✗         —                  —            no mobile in this project
```

## รูปแบบเต็ม

```
/bda-agent                      # interactive — แสดง menu
/bda-agent list                 # ตาราง agents + enabled status
/bda-agent enable <name>        # enable + update .bda-spec.yml
/bda-agent disable <name>       # disable (ไฟล์ยังอยู่)
/bda-agent create <name>        # สร้าง agent ใหม่ (interactive 8 questions)
/bda-agent regenerate <name>    # rewrite §2 project context ตาม vault ปัจจุบัน
/bda-agent audit                # ตรวจ agent definition (sections, gates, ห้าม)
/bda-agent suggest              # AI scan vault → suggest agent ใหม่ที่ควรมี
```

## ขั้นตอนภายใน (Phase summary)

1. **Phase 0** — Resolve state (ls `.claude/agents/`, `yq` `.subagents`)
2. **Phase 1** — `list`/`enable`/`disable` (update `.bda-spec.yml`)
3. **Phase 2** — `create` (batch 8 questions + auto-scan vault context + generate file)
4. **Phase 3** — `regenerate` (re-read vault + diff §2 + write w/ backup `.bak-<date>`)
5. **Phase 4** — `suggest` (heuristic grep ใน docs/ → match agent type)
6. **Phase 5** — `audit` (check §1-§8, §5 gates ≥ 2, ห้าม section ≥ 3)

## Output ที่ได้

- `.claude/agents/<name>.md` (สร้างใหม่หรือ regenerate)
- `.claude/agents/<name>.md.bak-<date>` (backup ก่อน regenerate, gitignored)
- `.bda-spec.yml` update `subagents.<name>: true/false`

## Agent structure (ที่ generate)

```
§1. Role (one paragraph specific)
§2. Project context awareness (THIS PROJECT'S SPECIFICS — tech stack, owned paths, vault refs)
§3. Read context first (vault-first rule)
§4. Scope rules (MAY/MUST NOT touch)
§5. Gates (must-not-skip)
§5.1 Test creation
§6. Process (phases)
§7. Vault Update Checklist
§8. Hand-back format
§9. Examples (good vs bad)
ห้าม section
```

## Workflow ที่นิยม

ตัวอย่าง 1: specialize agent หลังมี PRD แล้ว
```
1. /bda-new                          ← สร้าง PRD + SRS + Tech-spec
2. /bda-agent regenerate backend     ← agent backend จะรู้ stack จริง (เช่น Node + Fastify)
3. /bda-agent regenerate frontend    ← agent frontend รู้ DS + framework choice
4. /bda-agent audit                  ← ตรวจว่า §2 ไม่ generic แล้ว
```

ตัวอย่าง 2: สร้าง agent ใหม่
```
/bda-agent create data-pipeline
  → ถาม 8 คำถาม (name, role, expertise, stack, paths, tools, gates, vault refs)
  → scan vault หา related docs
  → generate .claude/agents/data-pipeline.md
  → update .bda-spec.yml subagents.data-pipeline: true
```

ตัวอย่าง 3: suggest agents จาก vault
```
/bda-agent suggest
  → grep "ETL\|pipeline\|warehouse" docs/ → suggest data-engineer
  → grep "deploy\|kubernetes" docs/      → suggest devops
  → user เลือกที่จะ create
```

## Default agents

| Agent | Always-on? | Default trigger |
|---|---|---|
| `docs` | ✓ | vault keeper |
| `verifier` | ✓ | test/lint/build runner |
| `security` | ✓ | secret/PII scanner |
| `design` | ✗ | enable เมื่อรัน `/bda-design init` |
| `backend` | ✗ | enable ตาม Phase 1.1 stack |
| `frontend` | ✗ | same |
| `mobile` | ✗ | same |
| `figma` | ✗ | enable ถ้ามี Figma source |
| `test-runner` | ✗ | Playwright/Maestro automation |

## Gotchas / ข้อควรระวัง

- 🚫 ห้าม create agent ที่ `tools:` มี `Bash` แบบ unrestricted — ต้อง allowlist commands
- 🚫 ห้าม overwrite agent เดิมโดยไม่ backup (`.bak-<date>`)
- 🚫 ห้าม suggest agent ที่ vault ไม่มี evidence ต้องการ — Phase 4 ต้องอิง grep result จริง
- 🚫 ห้ามใส่ secret/credential ใน agent prompt
- ⚠️ `regenerate` จะแก้แค่ §2 project context — section อื่นเก็บไว้
- 💡 generic agent (init) มี `Last regenerated: init (generic)` → รัน `regenerate` หลังมี PRD/SRS

## Related

- ก่อน `/bda-agent`: [`/bda-init`](./bda-init.md), [`/bda-new`](./bda-new.md), [`/bda-doc`](./bda-doc.md) (ให้มี vault context ก่อน)
- หลัง `/bda-agent create`: ทดลองด้วย [`/bda-implement`](./bda-implement.md) (set `subagent_target: <name>` ใน plan)
- Subagent specs: [`.claude/agents/*.md`](../.claude/agents/)

## FAQ

**Q: agent ที่ create มา ใช้กับ Codex/Gemini ได้ไหม?**
A: Subagent เป็น Claude Code-specific (`.claude/agents/`) — Codex/Gemini ใช้ verb-routing ผ่าน `codex/AGENTS.md` / `gemini/prompts/` แทน

**Q: disable agent แล้วลบไฟล์ดีไหม?**
A: ไม่จำเป็น — `disable` แค่ set `.bda-spec.yml` `subagents.<name>: false` → `/bda-implement` จะ skip ไฟล์ยังอยู่กู้ได้

**Q: ทำไม `audit` แจ้งว่า `verifier.md` ยัง generic?**
A: หลัง `/bda-init` ของ greenfield ทุก agent generic — รัน `/bda-agent regenerate verifier` หลังมี PRD แล้ว
