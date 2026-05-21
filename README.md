# bda-spec

**AI + Obsidian docs-driven development workflow** สำหรับทีมที่ใช้ AI ทำงาน — รวม spec-kit philosophy, BDA AI Dev Standard, และ Obsidian vault patterns

> 20 slash commands · 9 specialized AI subagents · 5 AI shims (Claude · Codex · Gemini · GPT · GLM) · pinned BDA Standard v0.7.0 · 3-tier evidence storage with GDrive upload

---

## ⚡ Quick start

### 1. ติดตั้ง (one-line)

```bash
# Greenfield (folder ใหม่)
mkdir my-project && cd my-project
bash <(curl -fsSL https://raw.githubusercontent.com/sdumumpai-bda/bda-spec/main/scripts/install.sh)

# Brownfield หรือ folder ที่ setup ไว้แล้ว
cd existing-project
bash <(curl -fsSL https://raw.githubusercontent.com/sdumumpai-bda/bda-spec/main/scripts/install.sh)
```

ตอน install จะถาม **2 คำถาม:**

1. **โหมดไหน?** ถ้าตรวจเจอ indicators (package.json, src/, .git+commits, docs/) → ถาม greenfield / brownfield / adopt-vault
2. **AI agent?** เลือกได้หลายตัว: claude / codex / google / gpt / glm / all (default: claude)

### 2. รัน command แรก

เปิด Claude Code (หรือ AI ตัวที่ติดตั้ง) ใน folder แล้ว:

```
/bda-init        ← interactive config + Obsidian context manifest
```

ถ้าไม่รู้จะใช้ command ไหน:

```
/bda-help        ← ถาม "จะทำอะไร" แล้วแนะนำ command
```

### 3. ทดสอบ install สำเร็จ

```bash
bda-spec doctor     # health check
bda-spec test       # 233 smoke tests
```

---

## 🎯 20 Commands

| กลุ่ม | Commands |
|---|---|
| **ช่วยเหลือ + ตั้งค่า** | `/bda-help` `/bda-init` `/bda-sync` `/bda-agent` |
| **Spec-driven cycle** | `/bda-new` `/bda-clarify` `/bda-plan` `/bda-analyze` `/bda-checklist` `/bda-implement` `/bda-fix` |
| **เอกสาร + ทดสอบ + ออกแบบ + หลักฐาน** | `/bda-doc` `/bda-test` `/bda-design` `/bda-evidence` `/bda-upload` |
| **ประจำวัน + ส่งมอบ** | `/bda-checkin` `/bda-secure` `/bda-verify` `/bda-git` |

**Usage guide ละเอียด:** [`usage/README.md`](./usage/README.md) — 1 ไฟล์ต่อ command

---

## 📋 Workflows พบบ่อย

### A. เริ่ม project ใหม่

```bash
bda-spec init my-app                    # install
cd my-app
# เปิด Claude Code
```

```
/bda-init                                ← config
/bda-new                                 ← brainstorm → PRD + SRS + Tech-spec
/bda-design init                         ← (optional) design system + preview.html
/bda-plan FEAT-X                         ← วางแผน feature
# [user review plan ใน docs/80-ImplementPlan/, mark status: approved]
/bda-implement docs/80-ImplementPlan/... ← ลงมือผ่าน subagent
/bda-test                                ← smoke test
/bda-evidence --upload                   ← เก็บ + upload หลักฐาน
/bda-verify                              ← handoff report
/bda-git --plan <path>                   ← commit + push
```

### B. แก้บั๊ก

```
/bda-fix "search ค้างเมื่อใส่ขีดล่าง"     ← diagnose + fix-log (no code)
/bda-plan fix:<slug>                     ← small plan
/bda-implement <plan>                    ← แก้จริง
/bda-test --since <ref>                  ← verify
/bda-evidence --upload                   ← capture before/after
/bda-verify                              ← handoff
```

### C. Daily executive log (1 ไฟล์/วัน)

```
ตอนเช้า:   /bda-checkin morning         ← ตั้ง goals
ตอนเที่ยง: /bda-checkin midday          ← progress check
ระหว่างวัน: /bda-checkin note meeting "..."
           /bda-checkin note test "..."
ก่อนเลิก:  /bda-checkin end             ← AI รวบรวม 7 แหล่ง:
                                          commits + vault files + evidence
                                          + no-fake gate + phase progress
                                          + ccusage tokens + GDrive links
```

ผลออกที่ `docs/75-Checkins/YYYY-MM-DD.md` (BDA Daily Log v5 schema)

### D. Brownfield adopt (มี code อยู่แล้ว)

```bash
cd existing-project
bash <(curl -fsSL .../install.sh)
# เลือก mode: brownfield หรือ adopt-vault
# เลือก AI: claude (หรือ multi)
```

```
/bda-init                                ← scan stack + ตั้ง subagents
/bda-doc PRD-<slug>                      ← reverse-engineer PRD จาก README
/bda-agent regenerate <name>             ← specialize agents ตาม project context
```

---

## ⚙️ Configuration

| ไฟล์ | gitTracked? | ใช้สำหรับ |
|---|---|---|
| `.bda-spec.yml` | ✅ | shared — project name, vault path, subagents, submodules, AI agents |
| `.bda-spec.local.yml` | ❌ | personal — external vault, daily-log mirror, GDrive folder, secrets path |
| `.bda-spec/local/commands/` | ❌ | personal slash commands |
| `.bda-spec/local/templates/` | ❌ | personal template overrides |

**Template lookup chain (สูง → ต่ำ):**
1. `.bda-spec/local/templates/<name>.md` (personal)
2. `templates/<name>.md` (project — แก้ + commit ได้)
3. `standards/templates/<name>.md` (org canonical — read-only, sync override)

ดูตัวอย่างใน [`.bda-spec.local.yml.example`](./.bda-spec.local.yml.example)

---

## 🤖 Multi-AI

bda-spec ทำงานกับ AI ทุกตัวที่อ่าน markdown ได้:

| AI | Folder | Entry point |
|---|---|---|
| Claude Code | `.claude/` | slash commands `/bda-*` |
| Codex CLI | `codex/AGENTS.md` | `codex run "bda-init"` |
| Google Gemini | `gemini/prompts/` | `gemini chat --system "$(cat gemini/prompts/system.md)"` |
| ChatGPT | `gpt/prompts/` | paste `gpt/prompts/system.md` ใน chatgpt.com |
| Zhipu GLM | `glm/prompts/` | paste `glm/prompts/system.md` ใน chatglm.cn |

รายละเอียด: [`AI-README.md`](./AI-README.md)

---

## 🛡️ Standards alignment

bda-spec ห่อ **BDA AI Dev Standard v0.7.0** (snapshot ที่ pinned ใน `standards/`)

ทุก command output ต้องมี **5 หัวข้อบังคับ**:

1. BDA Standard files used
2. Pipeline trace (Understand → Plan → Execute → Verify → Handoff)
3. Commands run
4. Verification / Evidence
5. Limitations / Risks / Next steps

**Policies (ห้ามฝ่าฝืน):**
- ห้าม fake evidence
- ห้ามแต่ง commit hash, URL, token count
- Plan/Implement แยกกัน — `/bda-plan` ไม่แตะโค้ด
- Vault-first — อ่าน docs/ ก่อนถามคำถาม

อัพเดท standards: `/bda-sync` หรือ `bda-spec sync`

ดู:
- [`standards/STANDARD.md`](./standards/STANDARD.md) — 5-step pipeline
- [`standards/policies/`](./standards/policies/) — 4 policies
- [`EVIDENCE-PATHS.md`](./EVIDENCE-PATHS.md) — 3-tier evidence storage
- [`CHANGELOG.md`](./CHANGELOG.md) — version history + bda-spec extensions vs BDA standard

---

## 📦 Distribution (สำหรับ maintainer ของ bda-spec)

bda-spec ใช้ pattern คล้าย **spec-kit** — distribute ผ่าน git + bash installer

### Release flow

```bash
# 1. Update VERSION + CHANGELOG.md
echo "0.3.0" > VERSION
# Edit CHANGELOG.md เพิ่ม section ใหม่

# 2. Commit
git add -A
git commit -m "release: v0.3.0"

# 3. Tag
git tag v0.3.0
git push origin main --tags

# 4. Done — users ได้ updated version ผ่าน /bda-sync หรือ bda-spec upgrade
```

### User install URL patterns

```bash
# Latest from main
bash <(curl -fsSL https://raw.githubusercontent.com/sdumumpai-bda/bda-spec/main/scripts/install.sh)

# Pinned version
bash <(curl -fsSL https://raw.githubusercontent.com/sdumumpai-bda/bda-spec/v0.2.0/scripts/install.sh)

# Local development (after git clone)
bash bda-spec/scripts/install.sh --source bda-spec --target ./my-app
```

### Upgrade existing project

```bash
# In any bda-spec project:
bda-spec upgrade              # pull latest, preserves templates/ docs/ configs
bda-spec upgrade --version v0.3.0
bda-spec upgrade --rollback   # restore from backup
```

---

## 🧪 Development

```bash
# Test suite
bash scripts/test.sh           # 233 smoke tests
bash scripts/test.sh -v        # verbose
bash scripts/test.sh --filter <kw>  # filter by keyword

# Doctor
bash bin/bda-spec doctor

# Paths config
bash scripts/bda-paths.sh --json
bash scripts/bda-paths.sh --check VAULT_ABS

# Try install locally (dry-run)
bash scripts/install.sh --source $(pwd) --target /tmp/test-bda --dry-run
```

---

## 📂 โครงสร้าง

```
.
├── README.md                  ← คุณอยู่ที่นี่
├── AI-README.md               ← Multi-AI usage
├── CLAUDE.md                  ← Claude project entry
├── EVIDENCE-PATHS.md          ← 3-tier evidence strategy
├── CHANGELOG.md               ← version history
├── VERSION                    ← bda-spec version
├── .bda-spec.yml              ← shared config (gitTracked)
├── .bda-spec.local.yml.example← personal config template
├── .gitignore
│
├── commands/                  ← 20 source-of-truth commands (Phase descriptions)
├── usage/                     ← 20+1 user-facing usage docs (Quick start, FAQ, gotchas)
├── .claude/
│   ├── commands/              ← Claude slash command shims
│   ├── agents/                ← 9 specialized subagents
│   └── settings.json
├── codex/                     ← Codex AGENTS.md routing
├── gemini/                    ← Gemini prompts
├── gpt/                       ← ChatGPT prompts
├── glm/                       ← Zhipu GLM prompts
├── prompts/general-ai/        ← Generic AI prompts
│
├── standards/                 ← BDA Standard v0.7.0 snapshot (read-only)
│   ├── VERSION
│   ├── STANDARD.md
│   ├── policies/              ← 4 policies
│   ├── checklists/            ← 5 checklists
│   └── templates/             ← canonical templates
├── templates/                 ← project-customizable overrides (16 templates)
│
├── scripts/                   ← bash helpers
│   ├── install.sh             ← one-line bootstrap
│   ├── upgrade.sh             ← bump bda-spec
│   ├── bda-paths.sh           ← config resolver
│   ├── upload-evidence.sh     ← GDrive uploader (rclone)
│   └── test.sh                ← 233 smoke tests
├── bin/
│   └── bda-spec               ← CLI wrapper
│
└── docs/                      ← sample Library Book Tracker Obsidian vault
    ├── 00-Index/              ← MOCs + IMPLEMENTATION-STATUS
    ├── 10-PRD/ 20-Features/ 30-Roles/ 40-Functions/
    ├── 50-Phases/ 60-Flows/
    ├── 70-Reference/          ← TechStack, Auth, API, DesignSystem
    ├── 75-Checkins/           ← daily logs (1/day)
    ├── 80-ImplementPlan/ 85-FixLog/
    ├── 90-TestPlan/ 95-Handoff/
```

---

## 🔗 Acknowledgements

- [spec-kit](https://github.com/github/spec-kit) — Plan-driven AI development philosophy
- [BDA AI Dev Standard](https://github.com/BigDataAgency/bda-ai-dev-standard) — 5-step pipeline + mandatory output
- [thai-cleft-main](https://github.com/BigDataAgency/thai-cleft-main) — Vault-first patterns + daily-log v5 schema

## License

MIT — see `LICENSE`
