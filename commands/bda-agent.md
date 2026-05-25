---
description: Agent management — list, enable, disable, create, regenerate intelligent specialized agents based on project context
model: claude-sonnet-4-6
---

# /bda-agent — Subagent Management

จัดการ subagent: list/enable/disable + **สร้าง agent ใหม่ที่ specialize ตาม project context จริง**

> **ปัญหาที่แก้:** ตอน `/bda-init` ใน greenfield ยังไม่รู้ scope → agent generic
> วิธีแก้: เริ่มจาก agent generic 3 ตัว (docs/verifier/security) → หลังมี PRD/SRS แล้ว → รัน `/bda-agent regenerate` หรือ `/bda-agent create` เพื่อทำ agent ที่เก่งเฉพาะด้านมากๆ ตาม context จริง

## Trigger

```
/bda-agent                                # interactive — แสดง menu
/bda-agent list                           # แสดง agents ทั้งหมด + enabled status
/bda-agent enable <name>                  # enable agent
/bda-agent disable <name>                 # disable agent
/bda-agent create <name>                  # สร้าง agent ใหม่ (interactive)
/bda-agent regenerate <name>              # rewrite agent ตาม vault context ปัจจุบัน
/bda-agent audit                          # ตรวจ agent definition ครบไหม
/bda-agent suggest                        # AI suggest agents ใหม่ที่ project ควรมี
```

## Phase 0 — Resolve state

```bash
eval "$(bash scripts/bda-paths.sh --shell)"
ls .claude/agents/*.md
yq '.subagents' .bda-spec.yml
```

แสดง table:

```
Agent          Enabled   Last regenerated   Spec lines   Notes
-----          -------   ----------------   ----------   -----
docs           ✓         init (generic)     220          always-on, vault keeper
verifier       ✓         init (generic)     180          always-on
security       ✓         init (generic)     200          always-on
design         ✗         —                  —            enable via /bda-design init
backend        ✓         2026-05-19         320          specialized: .NET 8 API, dotnet test
frontend       ✓         2026-05-20         380          specialized: Next.js 14 + DS-Components
mobile         ✗         —                  —            no mobile in this project
figma          ✗         —                  —            no figma source
test-runner    ✓         init (generic)     410          Playwright + Maestro auto-detect
```

## Phase 1 — `list` / `enable` / `disable`

Simple — update `.bda-spec.yml` `subagents.<name>: true/false`

```bash
yq -i ".subagents.<name> = true" .bda-spec.yml
```

`/bda-agent enable design` → ถามต่อ "รัน /bda-design init ด้วยเลยไหม?"

## Phase 2 — `create <name>` (interactive)

สร้าง agent ใหม่ที่ specialize เฉพาะด้าน

### 2.1 ถาม batch:

1. **Agent name** (kebab-case, e.g., `data-pipeline`, `infra-aws`, `seo-content`)
2. **One-line role** ("Maintain ETL pipelines for Snowflake warehouse")
3. **Domain expertise** (multi-select + free text):
   - [ ] Backend / API
   - [ ] Frontend / UI
   - [ ] Mobile
   - [ ] Data engineering / ETL
   - [ ] DevOps / Infra
   - [ ] Security / Compliance
   - [ ] QA / Testing
   - [ ] Content / Copy
   - [ ] Analytics / Tracking
   - [ ] AI / ML / Prompts
   - Custom: ___
4. **Tech stack ที่ agent ต้องเชี่ยวชาญ** (e.g., "Python 3.12, dbt, Airflow, Snowflake, Great Expectations")
5. **Files/paths ที่ agent มี ownership** (e.g., `etl/`, `dags/`, `dbt_project/`)
6. **Tools ที่ agent ใช้** (Read, Write, Edit, Bash, Glob, Grep, WebFetch, etc.)
7. **Gates ที่ห้ามข้าม** (e.g., "ห้าม merge ETL change ก่อน rerun data-quality tests")
8. **Linked vault docs** (ถ้ามี — เช่น `docs/obsidian-vault/70-Reference/REF-DataPlatform.md`)

### 2.2 Auto-scan vault for context

```bash
# Find related docs
grep -l -i "$DOMAIN_KEYWORDS" "$VAULT_PATH"/{10-PRD,20-Features,40-Functions,70-Reference}/*.md

# Find existing patterns to follow
grep -l "subagent_target: $RELATED" "$VAULT_PATH"/80-ImplementPlan/*.md

# Constitution rules ที่อาจ apply
ls standards/policies/
```

ใช้เป็น **input** ให้ agent prompt ที่ generate

### 2.3 Generate agent file

Path: `.claude/agents/<name>.md`

Structure:
```markdown
---
name: <name>
description: Use this agent when <role>. Examples: <2-3 invocation patterns>
model: claude-sonnet-4-6
tools: Read, Write, Edit, Glob, Grep, Bash[selective allowlist]
---

# <Name> Agent

## §1. Role
<one paragraph — be very specific about expertise>

## §2. Project context awareness (THIS PROJECT'S SPECIFICS)
- **Tech stack:** <from Phase 2.1 Q4 — be specific: versions, framework choices>
- **Owned paths:** <Q5>
- **Key vault refs:** <Q8 — list of docs to read on first invocation>
- **Related agents:** <which other agents this agent hands off to/from>
- **Conventions:** <linting, formatting, naming — from existing codebase if any>

## §3. Read context first (vault-first rule)
Before any action:
1. Read `docs/obsidian-vault/00-Index/IMPLEMENTATION-STATUS.md`
2. Read all relevant docs from §2 vault refs
3. Read active plan if invoked from /bda-implement
4. Read DS-Tokens.md + DS-Components.md if frontend/mobile

## §4. Scope rules
- MAY touch: <list of paths>
- MUST NOT touch: <list — usually production data, shared/published>
- MUST coordinate with: <agents/humans for shared resources>

## §5. Gates (must-not-skip)
- <gate 1 — e.g., "Production code change without test ⇒ STOP">
- <gate 2 — domain-specific, e.g., "ETL DAG change without lineage test ⇒ STOP">
- <gate 3 — e.g., "Migration ที่ irreversible ต้อง approval ใน plan">

### §5.1 Test creation
<for code agents: when production code changes, what tests must exist before commit>

## §6. Process
1. <Phase 1>
2. <Phase 2>
3. ...

## §7. Vault Update Checklist (after work)
- [ ] Update FN-* docs ที่เกี่ยวข้อง
- [ ] Update IMPLEMENTATION-STATUS.md
- [ ] Append evidence to manifest if any
- [ ] Update related REF-* docs

## §8. Hand-back format to main Claude
- Files changed (production vs test): ...
- Vault docs updated: ...
- Evidence captured: ...
- Risks / Limitations / Next steps: ...
- 5 mandatory output sections inherited via main Claude

## §9. Examples (good vs bad)
**✓ Good invocation:**
<example use case>

**✗ Bad — refuse:**
<example out-of-scope>

## ห้าม
- ห้าม <forbidden 1>
- ห้าม <forbidden 2>
```

### 2.4 Update .bda-spec.yml
```yaml
subagents:
  <name>: true
```

### 2.5 Suggest commands ที่อาจ benefit
- `/bda-plan` ใช้ agent นี้เป็น `subagent_target` ได้ในงานประเภทไหน
- เพิ่ม agent ใน `/bda-implement` mapping

## Phase 3 — `regenerate <name>`

Re-create agent ที่มีอยู่แล้วโดยใช้ **vault context ที่ updated**

ทำเมื่อ:
- Project grew — agent generic เริ่ม irrelevant
- หลัง /bda-doc PRD/SRS/Tech — agent ควรรู้รายละเอียดมากขึ้น
- หลัง /bda-design init — frontend/mobile ควร force DS

Process:
1. Read existing `.claude/agents/<name>.md` → extract §2 project context
2. Scan vault for updates (new FN-*, new FR-###, new DS components)
3. Show diff: "Will update §2 project context: <list>"
4. Confirm → write new agent file
5. Backup old as `.claude/agents/<name>.md.bak-<date>` (gitignored)

## Phase 4 — `suggest`

AI analyze vault → suggest agents ที่ project น่าจะมี

```bash
# Heuristics
grep -l "ETL\|pipeline\|warehouse" docs/**/*.md && suggest "data-engineer"
grep -l "deploy\|infra\|kubernetes\|terraform" docs/**/*.md && suggest "devops"
grep -l "SEO\|content\|copy" docs/**/*.md && suggest "content-writer"
ls docs/obsidian-vault/40-Functions/*Analytics* && suggest "analytics"
```

แสดง suggestions + ให้ user เลือกที่จะ create

## Phase 5 — `audit`

ตรวจ agent definition:
- มี §1-§8 ครบไหม
- §2 มี specifics หรือยังเป็น placeholder
- §5 gates มีอย่างน้อย 2 ข้อ
- ห้าม section มีอย่างน้อย 3 ข้อ
- `tools:` ใน frontmatter sensible

Report findings ในรูปแบบ:
```
docs.md          ✓ ok
verifier.md      ⚠ §2 ยัง generic — รัน /bda-agent regenerate verifier
backend.md       ✗ ขาด §5.1 Test creation gate
```

## Output (5 หัวข้อบังคับ)

1. **BDA Standard files used** — `standards/STANDARD.md`, `.bda-spec.yml`
2. **Pipeline trace** — Understand (Phase 0) → Plan (Phase 1 batch ถาม) → Execute (Phase 2-5) → Verify (Phase 5 audit)
3. **Commands run** — Read agents, Write agent file, yq update
4. **Verification / Evidence** — agent file path, line count, sections present, enabled flag
5. **Limitations / Risks / Next steps** — agent ที่ยัง generic, missing gates, suggestions ที่ไม่ได้ create

## ห้าม

- ห้าม create agent ที่ tools มี `Bash` แบบ unrestricted — ต้อง allowlist commands
- ห้าม overwrite agent ที่มีอยู่โดยไม่ backup (.bak-<date>)
- ห้าม create agent โดยไม่ scan vault context — ต้องมี §2 specifics ที่อิง doc จริง
- ห้าม suggest agent ที่ project ไม่มี evidence ต้องการ (Phase 4 ต้องอิง grep result)
- ห้ามแก้ §2 project context ของ agent อื่นที่ไม่ได้ regenerate
- ห้ามใส่ secret/credential ใน agent prompt
