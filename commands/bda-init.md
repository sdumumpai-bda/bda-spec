---
description: Bootstrap bda-spec — Obsidian vault + standards + subagents (greenfield หรือ brownfield) + Obsidian context manifest (BDA v0.7.0)
model: claude-sonnet-4-6
---

<!--
BDA Standard v0.7.0 alignment (matches `commands/init.md`):
- bda-init covers the install/bootstrap responsibility + BDA v0.7.0 init context-priming step
- Phase 8 (added) → generate/update Obsidian context manifest using `standards/templates/obsidian-context.md`
  Default location in bda-spec: `docs/00-Index/IMPLEMENTATION-STATUS.md` (with Agent Context section)
- Phase 9 (added) → initialize session/evidence indexes:
  - `docs/75-Checkins/_index.md`
  - `docs/95-Handoff/_index.md` (evidence_index)
- All subsequent commands (plan/fix/doc/implement) read the manifest BEFORE working
-->


# /bda-init — Bootstrap bda-spec

ตั้งค่า project — รองรับทั้ง **greenfield** (folder ว่าง) และ **brownfield** (มี code อยู่แล้ว)

> **หมายเหตุ**: ก่อนรัน /bda-init โดยมาก `scripts/install.sh` ได้ scaffolding ไว้แล้ว
> `/bda-init` ใช้สำหรับ **interactive config** และ **brownfield gap analysis**

## Trigger

```
/bda-init
/bda-init <project-name>
/bda-init --greenfield        # บังคับ mode
/bda-init --brownfield        # บังคับ mode
/bda-init --reconfigure       # แก้ config ของ project ที่ init แล้ว
```

## Phase 0 — ตรวจสถานะ + Detect mode

```bash
# ทำงานจาก project root
test -f .bda-spec.yml && echo "EXISTS" || echo "FRESH"
test -d docs && ls docs | head -5
test -d .claude/commands && ls .claude/commands | grep -c '^bda-' || echo 0

# Detect brownfield indicators (code already in repo)
ls package.json requirements.txt pyproject.toml go.mod Cargo.toml \
   pubspec.yaml pom.xml build.gradle composer.json *.csproj *.sln \
   2>/dev/null | head -3

# Detect submodules
test -f .gitmodules && cat .gitmodules
```

| สภาพ | การตัดสินใจ |
|---|---|
| **ไม่มี indicator เลย** (folder ว่าง) | **Greenfield auto** — ไม่ถาม |
| **มี indicator อย่างน้อย 1 อย่าง** | **ถาม user** 3 ตัวเลือก: greenfield / brownfield / adopt-vault |
| มี `.bda-spec.yml` แล้ว | **Reconfigure** — ถามว่า reset ส่วนไหน |

> **`--here` ≠ brownfield** — folder ที่ user รันใน cwd อาจเป็น project setup ไว้แล้วแต่ยังไม่ได้เริ่มเขียน code จริง (เช่น `git init` แล้วทำ scaffolding ไว้) — เลยต้อง**ถามแทน assume**

### Indicators ที่ตรวจ (ถ้ามีอย่างน้อย 1 อย่าง → ถาม user)

**Manifests:**
- `package.json`, `requirements.txt`, `pyproject.toml`, `Pipfile`
- `pom.xml`, `build.gradle`, `build.gradle.kts`
- `go.mod`, `Cargo.toml`, `composer.json`, `Gemfile`
- `pubspec.yaml`, `mix.exs`, `*.csproj`, `*.sln`

**Source folders:** `src/`, `lib/`, `app/`, `frontend/`, `backend/`, `mobile/`, `server/`, `client/`, `api/`, `packages/`, `apps/`, `services/`

**VCS state:** `.git` directory + ≥ 1 commit (empty init ไม่นับ — ยังเป็น greenfield ได้)

**Multi-repo:** `.gitmodules`

**Existing docs:** `docs/` ที่มี markdown content (อาจเป็น Obsidian vault อยู่แล้ว)

### 3 ตัวเลือกที่ถาม user

```
🔍 ตรวจพบ indicators ใน folder นี้:
   • package.json
   • src/
   • .git (47 commits)
   • docs/ (existing content)

โหมดไหนตรงกับสถานการณ์ของคุณ?

  1) greenfield   — project setup ไว้แล้ว แต่ยังไม่มี content จริง (เริ่ม fresh ได้)
  2) brownfield   — มี code/docs ใช้งานอยู่จริง (adopt + ห้ามแตะของเดิม)
  3) adopt-vault  — มี Obsidian vault อยู่แล้วใน docs/ (ใช้ vault เดิม + รวม commands ของ bda-spec)

เลือก (1/2/3) [default: 2 brownfield]:
```

ความหมายของแต่ละ mode:

- **greenfield** — ลบ scaffolding เดิมที่ไม่จำเป็นได้, copy sample vault, สร้าง vault skeleton
- **brownfield** — **ห้ามแตะ** ของเดิม, เพิ่มเฉพาะ `commands/`, `.claude/`, `standards/`, `templates/`, vault skeleton (ใหม่หรือใน sub-folder)
- **adopt-vault** — brownfield + ใช้ vault path ที่ user ระบุ (`docs/` เดิม), ไม่สร้าง vault ใหม่

## Phase 1 — ถามข้อมูลขั้นต่ำ (1 message รวมทุกคำถาม)

### 1.1 Common (ทั้ง greenfield + brownfield):

1. **ชื่อ project** + slug (ถ้ายังไม่ระบุใน `$ARGUMENTS`)
2. **Mode**: `standalone` (vault อยู่ใน repo นี้) หรือ `submodule` (bda-spec เป็น submodule ใน repo ใหญ่)
3. **Stack/scope** (multi-select):
   - [ ] Backend / API
   - [ ] Web frontend
   - [ ] Mobile app
   - [ ] Figma design source
   - [ ] Multi-repo (มี submodule)
4. **Design system** → bootstrap minimal หรือไม่? (สร้างทีหลังด้วย `/bda-design` ได้)
5. **Language** สำหรับรายงาน: `th` (default) / `en`

### 1.2 Vault location (always ถาม — ไม่ขึ้นกับ green/brownfield):

6. **Obsidian vault อยู่ที่ไหน?** (4 options)

   | ตัวเลือก | เก็บที่ | ใช้เมื่อ |
   |---|---|---|
   | **A) สร้างใหม่ใน `docs/`** | `<project>/docs/` (default, in-repo) | greenfield หรือ project ใหม่ |
   | **B) สร้างใหม่ใน `docs/bda-vault/`** | `<project>/docs/bda-vault/` | brownfield ที่ `docs/` ใช้อยู่แล้ว |
   | **C) ใช้ vault ที่มีอยู่ใน repo นี้** | `<project>/<path>` ที่ user ระบุ | brownfield + มี vault อยู่แล้ว |
   | **D) ใช้ external vault (path นอก repo)** | absolute path เช่น `/Volumes/.../MyVault` | shared org vault, iCloud sync, multi-project vault |

   ถ้าเลือก **D** (external):
   - บันทึก path ลง **`.bda-spec.local.yml`** ที่ `paths.external_vault:` (gitignored — เฉพาะเครื่องนี้)
   - **`.bda-spec.yml`** จะ set `vault_path: external`
   - commands ทุกตัวอ่าน local config ก่อน fallback to `vault_path`

   ถ้าเลือก **A/B/C** (in-repo):
   - บันทึก path ลง `.bda-spec.yml` `vault_path:` (gitTracked — ทุกคนใน team ใช้ path เดียวกัน)
   - `.bda-spec.local.yml` `paths.external_vault:` = empty

### 1.3 Brownfield-specific (เพิ่ม ถ้ามี code indicator):

7. **มี README หรือ docs อยู่แล้ว** อยาก import เข้า PRD ไหม?
   - `yes` → จะ analyze README + เสนอ PRD draft ใน Phase 3
   - `no` → ข้าม, ค่อยใช้ /bda-new ทีหลัง
8. **Submodules** — list ที่มี (auto-detect จาก `.gitmodules` + ให้ user confirm + branch ของแต่ละ submodule)

### 1.4 Personal paths (เก็บใน .bda-spec.local.yml — ถามได้แต่ skip ได้):

9. **Daily-log mirror** — ต้องการ mirror executive daily log ไปยัง path นอก repo ไหม? (เช่น Obsidian sync folder)
   - ถ้ามี → ใส่ใน `.bda-spec.local.yml` `paths.daily_log_mirror:`
   - skip ก็ได้ — `/bda-checkin` จะใช้ default ใน `<vault>/75-Checkins/`
10. **Evidence staging** — path เก็บ screenshot ดิบก่อน mask?
    - ถ้ามี → `.bda-spec.local.yml` `paths.evidence_staging:`
    - skip ได้

## Phase 2 — สร้าง vault skeleton

ตาม `vault_path` ที่ user เลือก:

```
<vault_path>/
├── .obsidian/                  basic config
├── 00-Index/
│   ├── IMPLEMENTATION-STATUS.md   single source of truth
│   ├── MOC-PRD.md
│   ├── MOC-Features.md
│   ├── MOC-Functions.md
│   └── README.md
├── 10-PRD/
├── 20-Features/
├── 30-Roles/
├── 40-Functions/
├── 50-Phases/
├── 60-Flows/
├── 70-Reference/
│   ├── REF-TechStack.md
│   ├── REF-AuthorizationMatrix.md
│   ├── REF-APIIntegration.md
│   └── DesignSystem/ (ถ้าเลือก yes ใน 1.1)
├── 75-Checkins/
├── 80-ImplementPlan/
├── 85-FixLog/
├── 90-TestPlan/
└── 95-Handoff/
```

ในแต่ละ folder ใส่ `_README.md` อธิบายหน้าที่ + naming convention

## Phase 3 — Brownfield adoption (skip ถ้า greenfield)

ทำเฉพาะ brownfield mode:

### 3.1 Stack scan (read-only — ไม่แก้โค้ด)

```bash
# Auto-detect frameworks
[ -f package.json ] && cat package.json | head -30
[ -f requirements.txt ] && cat requirements.txt | head -20
[ -f pyproject.toml ] && grep -A 20 'dependencies' pyproject.toml
[ -f go.mod ] && cat go.mod | head -10
[ -f pubspec.yaml ] && head -30 pubspec.yaml
[ -f *.csproj ] && head -20 *.csproj 2>/dev/null

# Detect API surface
find . -type f \( -name "*.controller.*" -o -name "*Controller.*" -o -name "routes.*" -o -path "*/api/*" \) 2>/dev/null | grep -v node_modules | head -20

# Detect UI components
find . -type d \( -name "components" -o -name "screens" -o -name "pages" \) 2>/dev/null | grep -v node_modules | head -10
```

จาก scan → สร้าง draft ของ:
- `docs/70-Reference/REF-TechStack.md` (auto-fill จาก dependencies)
- `docs/70-Reference/REF-APIIntegration.md` (auto-fill endpoints ที่เจอ)
- `docs/00-Index/IMPLEMENTATION-STATUS.md` (mark project as: `adopted from existing codebase`)

### 3.2 Import README (ถ้า user เลือก yes ใน 1.2)

อ่าน `README.md` ของ project แล้วเสนอ:
- หา section ที่เป็น product description → ใส่ใน `docs/10-PRD/PRD-<slug>.md`
- หา section ที่เป็น install/usage → reference ใน `REF-TechStack.md`
- หา features list → สร้าง `docs/20-Features/FEAT-*.md` draft

แสดง user เห็น mapping → ถาม confirm ก่อนสร้างจริง

### 3.3 Suggest first checkin

> "Brownfield project ที่ adopt — มี code อยู่แล้ว แต่ไม่มี docs ครบ"
>
> เสนอ:
> - สร้าง `docs/75-Checkins/<today>.md` พร้อม note: "Started adopting bda-spec into existing codebase"
> - ตั้งงานแรก: `/bda-plan reverse-engineer existing X` หรือ `/bda-doc PRD` เพื่อเติม PRD

### 3.4 ไม่แตะโค้ดเดิม — กฎเหล็ก

- ห้าม /bda-init แก้ไฟล์โค้ดที่มีอยู่
- ห้ามย้าย/rename ไฟล์โค้ดเดิม
- เพิ่มเฉพาะ: `docs/`, `.claude/`, `standards/`, `templates/`, `scripts/`, `.bda-spec.yml`, `CLAUDE.md`
- ถ้า `CLAUDE.md` มีอยู่แล้ว → ถามว่า append หรือ rename เก่าเป็น `CLAUDE.legacy.md`

## Phase 4 — Pin standards snapshot

```bash
test -d standards || mkdir -p standards
test -f standards/VERSION || echo "0.4.1" > standards/VERSION
```

ถ้า template มี `standards/STANDARD.md` ฯลฯ อยู่แล้ว → ไม่ต้องทำอะไร (installer copy มาแล้ว)

ถ้าจะ update → ใช้ `/bda-sync`

## Phase 5 — เลือก + enable subagents

จาก stack ที่ user เลือก Phase 1, set ใน `.bda-spec.yml`:

| Stack | Subagents ที่ enable (set true) |
|---|---|
| (always-on) | `docs`, `verifier`, `security` |
| Backend/API | + `backend` |
| Web frontend | + `frontend` |
| Mobile app | + `mobile` |
| Figma | + `figma` |
| Design system: yes | + `design` |

Subagents ที่ disable ก็ยังอยู่ใน `.claude/agents/` แค่ `bda-spec.yml` set false → `/bda-implement` จะ skip

## Phase 6 — เขียน config (2 ไฟล์)

### 6.1 `.bda-spec.yml` (gitTracked — shared กับ team)

ใช้ค่าที่ user ตอบ:
- `project.name`, `project.slug`
- `mode` (standalone / submodule)
- `vault_path`: ถ้า user เลือก A/B/C ใน Phase 1.2 → in-repo relative path; ถ้าเลือก D (external) → ใส่ `external` (special value)
- `subagents.*`
- `submodules` (auto-fill จาก `.gitmodules` ถ้ามี)
- `standard.version` + `standard.last_synced`

### 6.2 `.bda-spec.local.yml` (gitignored — เฉพาะเครื่อง user)

สร้าง/update ถ้า user ใส่ personal paths ใน Phase 1.2 D หรือ 1.4:

```yaml
paths:
  external_vault: "<absolute path>"      # ถ้า user เลือก D ใน Phase 1.2
  daily_log_mirror: "<absolute path>"    # ถ้า user ตอบ Phase 1.4 q9
  evidence_staging: "<absolute path>"    # ถ้า user ตอบ Phase 1.4 q10
user:
  name: "<git config user.name fallback>"
  timezone: "Asia/Bangkok"
```

ถ้า user skip ทุก personal path → คัดลอก `.bda-spec.local.yml.example` → `.bda-spec.local.yml` เป็น template ว่างให้ user เติมทีหลัง

### 6.3 ตรวจ `.gitignore`

```bash
test -f .gitignore || cp .gitignore.template .gitignore
grep -q "^.bda-spec.local.yml" .gitignore || echo "" >> .gitignore && cat >> .gitignore <<'EOF'

# bda-spec local config (machine-specific)
.bda-spec.local.yml
.bda-spec/local/
EOF
```

## Phase 7 — Verification

```bash
ls docs/ | wc -l                    # expect ≥ 12 folders
test -f .bda-spec.yml && echo OK
test -f CLAUDE.md && echo OK
ls .claude/commands | grep -c '^bda-'  # expect ≥ 13
ls .claude/agents | wc -l           # expect ≥ 8 (3 always-on + 5 optional)
test -f standards/VERSION && cat standards/VERSION
```

แสดง summary:

```
✅ bda-spec init complete

Mode: <greenfield|brownfield>
Project: <name> (<slug>)
Vault: <vault_path>/
Standards version: <0.4.1>
Subagents enabled: docs, verifier, security, <+optionals>
Submodules: <list or none>

ขั้นต่อไป:
  • Greenfield → /bda-new (brainstorm ไอเดียใหม่)
  • Brownfield (มี README) → ตรวจ PRD draft + /bda-doc PRD-<slug> เพิ่ม section ที่ขาด
  • Brownfield (ไม่มี README) → /bda-new --import <path-to-existing-doc>
  • อยากสร้าง design system ก่อน → /bda-design
```

## Output (5 หัวข้อบังคับ)

1. **BDA Standard files used** — `standards/STANDARD.md`, `standards/policies/*`, template files
2. **Pipeline trace** — Understand (Phase 0 detect) → Plan (Phase 1 ถาม) → Execute (Phase 2-6 สร้าง/แก้ไฟล์) → Verify (Phase 7) → Handoff (summary)
3. **Commands run** — list bash commands (detect, mkdir, cat, etc.)
4. **Verification / Evidence** — output ของ Phase 7
5. **Limitations / Risks / Next steps** — เช่น "Brownfield import: PRD draft จาก README ต้องตรวจกับ stakeholder", "Standards 0.4.1 อาจมี update — รัน /bda-sync"

## ห้าม

- ห้ามแก้โค้ดเดิม
- ห้ามแต่ง dependencies, framework, version ที่ไม่ได้เห็นจริงในไฟล์
- ห้าม assume project type ถ้า detect ไม่ชัด — ถาม user
