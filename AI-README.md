# AI-README.md — bda-spec usage guide for any AI

bda-spec ทำงานกับ AI ตัวใดก็ได้ที่อ่าน markdown ได้

## Source of truth

ทุก command มี source-of-truth ที่ `commands/<verb>.md`

แต่ละไฟล์เป็น self-contained markdown — อธิบาย Phase, validations, output requirements, restrictions

## วิธีใช้กับแต่ละ AI

### Claude Code (interactive)

ใช้ slash commands ได้เลย (shim อยู่ที่ `.claude/commands/bda-*.md` ซึ่ง `@`-reference commands/):

```
/bda-help                        ← ถามว่าใช้ command ไหน / อธิบาย / workflow
/bda-init
/bda-new
/bda-clarify <doc>               ← spec-kit taxonomy ambiguity scan
/bda-plan <task>
/bda-analyze [--feature <slug>]  ← cross-artifact coverage + findings
/bda-checklist <domain>          ← unit tests for English (ux/api/security/perf)
/bda-implement <plan-path>
/bda-fix <bug>
/bda-doc <type> <name>
/bda-test
/bda-design
/bda-evidence                    ← capture/mask/store evidence (แยกจาก checkin)
/bda-checkin
/bda-secure
/bda-verify <scope>
/bda-handoff <plan-path>             ← สร้าง Handoff Report ส่งต่อ reviewer/exec
/bda-git <args>
/bda-sync
/bda-agent <action>              ← list/enable/create/regenerate intelligent agents
```

### Claude Code (print mode `claude -p`)

Slash commands ไม่ทำงาน — reference path แทน:

```bash
claude -p "$(cat commands/bda-plan.md)\n\nTask: เพิ่ม search feature"
```

หรือใช้:
```bash
claude -p "Follow @commands/bda-plan.md\n\nTask: เพิ่ม search feature"
```

### Codex CLI

อ่าน `codex/AGENTS.md` — มี mapping ของ command verb → instruction file

```bash
codex run "bda-plan: เพิ่ม search feature"
```

Codex จะอ่าน `codex/AGENTS.md` → route ไปที่ `commands/bda-plan.md`

### Gemini CLI / API

ใช้ prompts ที่ `gemini/prompts/` หรือชี้ไปที่ `commands/<verb>.md` ตรงๆ:

```bash
gemini chat --system "$(cat commands/bda-plan.md)" "Task: ..."
```

### Cursor / Windsurf / ChatGPT / อื่นๆ

Paste content ของ command markdown เป็น system prompt:

```
[Paste content of commands/bda-plan.md]

Task: เพิ่ม search feature
Project root: /path/to/project
```

หรือ reference file path ถ้า AI ตัวนั้นมี file access:

```
Follow the instructions in commands/bda-plan.md

Task: ...
```

### Generic prompts สำหรับ AI ใดๆ

`prompts/general-ai/start-here.md` — เริ่มต้นทั่วไป
`prompts/general-ai/review-output.md` — pattern review output

## Universal rules ที่ทุก AI ต้องปฏิบัติ

1. **Vault-first** — อ่าน `docs/` (00-Index, PRD, Features, Reference) ก่อนถามคำถาม
2. **5 mandatory output sections** ทุก response ของ command:
   - BDA Standard files used
   - Pipeline trace (Understand → Plan → Execute → Verify → Handoff)
   - Commands run
   - Verification / Evidence
   - Limitations / Risks / Next steps
3. **No fake evidence** — ห้ามแต่ง commit hash, URL, test result, token count
4. **Thai-first reporting** — รายงาน + log ภาษาไทย (เว้นแต่ project ตั้ง `language: en`)
5. **Plan/Implement separation** — `/bda-plan` ไม่แตะโค้ด, `/bda-implement` เท่านั้นที่แก้โค้ด, `/bda-fix` แค่ diagnose
6. **Design system compliance** — ถ้ามี `docs/obsidian-vault/70-Reference/DesignSystem/` → frontend/mobile ต้องใช้ token/component จากนั้น
7. **Coding discipline** — ก่อนแก้ระบุ success criteria ที่ตรวจได้; เลือก minimum correct change; ทุก changed line ต้อง trace กลับไปยัง request/bug/criteria ได้; ห้ามเพิ่ม speculative abstraction/config/feature; ห้าม unrelated refactor/format churn; verification ต้อง map กลับไปยัง success criteria

## Config

`.bda-spec.yml` ที่ root — ทุก AI อ่านได้:
- `mode`: standalone หรือ submodule
- `vault_path`: ตำแหน่ง Obsidian vault
- `subagents`: agents ที่ enable (เฉพาะ AI ที่ support sub-agents)
- `submodules`: list submodule + branch
- `standard.version`: pinned version

## Sub-agents

Claude Code มี `.claude/agents/*.md` (8 agents)
Codex มี `codex/agents/*.toml` (mapping เดียวกัน)

AI ตัวที่ไม่ support sub-agents → main AI ทำเองทั้งหมดโดยอ่าน guidance ของ agent ผ่าน `commands/<verb>.md`

## Project structure (ทุก AI เห็นเหมือนกัน)

```
.
├── AI-README.md           ← คุณอยู่ที่นี่
├── CLAUDE.md              ← Claude-specific entry
├── .bda-spec.yml          ← config (all AIs read)
├── commands/              ← source-of-truth commands (neutral)
│   ├── bda-init.md
│   ├── bda-new.md
│   └── ... (13 commands)
├── .claude/
│   ├── commands/          ← Claude Code slash shims
│   ├── agents/            ← Claude sub-agents
│   └── settings.json
├── codex/
│   ├── AGENTS.md          ← Codex top-level instruction
│   └── agents/            ← Codex agent configs
├── gemini/
│   └── prompts/           ← Gemini prompts
├── prompts/
│   └── general-ai/        ← generic prompts
├── standards/             ← BDA standard snapshot (pinned)
│   ├── VERSION
│   ├── STANDARD.md
│   ├── policies/
│   ├── checklists/
│   └── templates/
├── templates/             ← project-customizable overrides
├── scripts/               ← bootstrap + helpers
│   └── install.sh
└── docs/                  ← Obsidian vault
    ├── .obsidian/
    ├── 00-Index/
    ├── 10-PRD/
    ├── ... (12 folders)
    └── 95-Handoff/
```

## Update standards across AIs

Run `/bda-sync` (Claude Code) หรือ:
```bash
# Manual: ดึง standards/* จาก https://github.com/BigDataAgency/bda-ai-dev-standard
bash scripts/sync-standards.sh
```

ทุก AI shim จะใช้ standard ใหม่อัตโนมัติ — เพราะ commands/<verb>.md อ้าง `standards/` ที่ relative path
