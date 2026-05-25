# CHANGELOG — bda-spec

Semantic Versioning · `MAJOR.MINOR.PATCH`
- MAJOR — breaking changes to command names, mandatory output format, or installer flags
- MINOR — new commands, new templates, new AI shims, new helper scripts
- PATCH — clarifications, typo fixes, non-breaking refinements

> bda-spec ห่อ BDA AI Dev Standard ในรูปแบบ Obsidian docs-driven workflow
> เวอร์ชั่นของ bda-spec **ไม่ตรงกับ** BDA Standard version — ดู `standards/VERSION` สำหรับเวอร์ชั่นของ standard ที่ pinned ในตอนนี้

---

## [Unreleased] — split /bda-verify + new /bda-handoff command

### New command: `/bda-handoff`

แยก Handoff Report ออกจาก `/bda-verify` เป็น command ของตัวเอง

- `commands/bda-handoff.md` — สร้าง Handoff Report (HOR-*.md) ส่งงานต่อ reviewer/exec/QA + อัปเดต status → `handed-off`
- `.claude/commands/bda-handoff.md` — Claude Code slash shim
- `codex/AGENTS.md` — เพิ่ม verb mapping `bda-handoff`
- `AI-README.md` — เพิ่ม `/bda-handoff` ใน command list
- `commands/bda-verify.md` — ตัด Phase 7-8 (handoff) ออก; เพิ่ม hint → `/bda-handoff`

**Workflow ใหม่:** `/bda-verify` → ผ่านทุก check → `/bda-handoff` → reviewer approve

---

## [Unreleased] — sync BDA Standard v0.8.0 (coding discipline)

### BDA Standard bump: v0.7.0 → v0.8.0

Sync ตาม [BDA AI Dev Standard v0.8.0](https://github.com/BigDataAgency/bda-ai-dev-standard/releases/tag/v0.8.0)

**Coding discipline** — หลักการใหม่สำหรับ AI agents ให้ทำงานแบบ surgical/goal-driven/minimum correct change:

- `standards/STANDARD.md` — อัปเดต Plan (+success criteria, +minimum correct change), Execute (+trace, +no speculative abstraction, +pattern-first, +assumption rule), Verify (+map to criteria), Definition of Done ขยาย
- `standards/checklists/before-commit.md` — เพิ่ม 4 รายการ: success criteria, minimum correct change, trace, no speculative abstraction/refactor
- `standards/checklists/before-start.md` — เพิ่มข้อ: ระบุ success criteria ก่อนลงมือ
- `AI-README.md` — Universal rule ข้อ 7: coding discipline
- `codex/AGENTS.md` — Universal rule ข้อ 6: coding discipline
- `commands/bda-plan.md` — template มี `## Success Criteria` section แยกชัด; ห้าม speculative steps
- `commands/bda-implement.md` — subagent prompt บังคับ minimum correct change + trace + no refactor; ห้ามเพิ่ม 3 รายการ

---

## [0.1.0] — 2026-05-21 — Initial public release

### Vault path convention

Default `vault_path` = **`docs/obsidian-vault/`** (เก็บ Obsidian vault แยกจาก top-level `docs/`)

เหตุผล: `docs/` ใน repo มักใช้เก็บเอกสารหลายแบบ (README, ARCHITECTURE.md, public API docs, build docs, contribution guides) — แยก Obsidian wiki vault ออกจาก document folder ทั่วไปจะชัดเจนกว่า

Pattern เดียวกับ thai-cleft-main reference implementation

User เลือกได้ตอน install:
- A) `docs/obsidian-vault/` — default (แยกชัด)
- B) `docs/` — vault ที่ root ของ docs (สำหรับ project เล็ก)
- C) ใช้ vault ที่มีอยู่ใน repo (custom path)
- D) external vault (path นอก repo)


First public release ของ bda-spec — AI + Obsidian docs-driven development workflow

### Inheritance

bda-spec รวมแนวทางจาก 3 source:

- **[spec-kit](https://github.com/github/spec-kit)** — plan-driven AI development, multi-AI installer, greenfield/brownfield modes
- **[BDA AI Dev Standard v0.7.0](https://github.com/BigDataAgency/bda-ai-dev-standard)** — 5-step pipeline, 5 mandatory output sections, no-fake-evidence policy
- **[thai-cleft-main](https://github.com/BigDataAgency/thai-cleft-main)** — Obsidian vault patterns, daily-log v5 schema, fix-log split, subagent specialization

### 20 slash commands

**ตั้งค่า + ช่วยเหลือ:**
- `/bda-help` — interactive help (decision tree / cheatsheet / workflow / search)
- `/bda-init` — bootstrap project + Obsidian context manifest (BDA v0.7.0 init alignment)
- `/bda-sync` — sync BDA Standard snapshot จาก org repo (scope-guard)
- `/bda-agent` — manage subagents (list/enable/disable/create/regenerate)

**Spec-driven cycle (จาก spec-kit + BDA standard):**
- `/bda-new` — brainstorm หรือ import PRD → cascade PRD/SRS/Tech-spec
- `/bda-clarify` — 9-category ambiguity scan, 1-at-a-time + recommended answer
- `/bda-plan` — vault-first research + plan file (FR-### / T### / Constitution Check / Complexity Tracking)
- `/bda-analyze` — cross-artifact consistency + Coverage Summary Table (read-only)
- `/bda-checklist` — "unit tests for English" per domain (ux/api/security/perf/data/a11y/observability/rollout)
- `/bda-implement` — execute approved plan ผ่าน specialized subagent
- `/bda-fix` — diagnose bug + fix-log (no code change)

**เอกสาร + ทดสอบ + ออกแบบ + หลักฐาน:**
- `/bda-doc` — create/update doc (PRD/SRS/ADR/Feature/Function/Role) ผ่าน template lookup chain
- `/bda-test` — smoke test changed surface (Playwright/Maestro/native test) + evidence capture
- `/bda-design` — design system (DS-Tokens + DS-Components + ...) + Storybook-lite `preview.html`
- `/bda-evidence` — capture/mask/store evidence + manifest (3-tier strategy)
- `/bda-upload` — upload curated evidence to GDrive (rclone-based) + update manifest links

**ประจำวัน + ส่งมอบ:**
- `/bda-checkin` — daily log (BDA v5 schema, 1 file/วัน — morning/midday/note/end)
- `/bda-secure` — security pre-flight (secrets, PII, public-repo guardrails)
- `/bda-verify` — verify + handoff report
- `/bda-git` — submodule-aware commit/push/merge

### 9 specialized subagents (79 gates รวม)

- **docs** — Obsidian vault keeper (frontmatter, link graph, IMPLEMENTATION-STATUS sync, MOC patterns)
- **verifier** — multi-stack test/lint/build runner with retry + coverage delta
- **security** — secret regex (AWS/GitHub/Stripe/JWT/OpenAI), **Thai national ID mod-11 + Luhn credit card**, STRIDE, OWASP Top 10
- **design** — DS architect (token hierarchy, WCAG 2.2 AA, preview.html sync, code↔DS drift)
- **backend** — REST/GraphQL/idempotency/OTel/expand-contract migration/N+1
- **frontend** — DS-strict (refuses ad-hoc styling), WCAG 2.2, hydration safety
- **mobile** — Flutter/RN/native, platform conventions, offline-first, deep links
- **figma** — read-only DS source mapper (W3C DTCG, frame→FN-* mapping)
- **test-runner** — Playwright + Maestro automation, BDA status taxonomy (12 enums), PII masking

ทุก agent มี §1-§9 structure (Role / Project context / Read context / Scope / Gates / Process / Vault Update / Hand-back / Examples + ห้าม)

### Multi-AI support (5 shims)

| AI | Folder | Entry point |
|---|---|---|
| **Claude Code** | `.claude/{commands,agents}/` + `CLAUDE.md` | slash commands `/bda-*` |
| **Codex CLI** | `codex/AGENTS.md` + `codex/agents/` | `codex run "bda-init"` |
| **Google Gemini** | `gemini/prompts/` | `gemini chat --system "$(cat gemini/prompts/system.md)"` |
| **ChatGPT** | `gpt/{README,prompts/{system,router}}.md` | paste in chatgpt.com |
| **Zhipu GLM** | `glm/{README,prompts/}.md` | paste in chatglm.cn / z.ai |

Installer interactive AI picker — เลือกได้หลายตัว (claude,codex,all,…)

### BDA Standard v0.7.0 (snapshot)

`standards/` mirror BDA AI Dev Standard ที่ pinned ไว้ — read-only, sync ผ่าน `/bda-sync`:

- STANDARD.md — 5-step pipeline
- 4 policies (no-fake-evidence, evidence-verification, source-of-truth, working-result)
- 5 checklists (before-start, before-commit, before-handoff, code-review, real-app-check)
- 18 templates (PRD, SRS, plan, fix-log, feature, function, ..., obsidian-context, obsidian-work-note, init)
- workflows/obsidian.md

Tracks BDA v0.7.0 changes: removed staff reporting/planning commands (daily-log, weekly-focus) at org level; bda-spec preserves `/bda-checkin` as extension for executive reporting

### 16 project-customizable templates

`templates/` overrides `standards/templates/`:
- PRD with P1/P2/P3 user stories + SC-### measurable success criteria
- SRS with FR-### / NFR-### + Given/When/Then acceptance
- Plan with **Constitution Check gate** + **Complexity Tracking** + checkbox tasks `- [ ] T001 [P] [US1]`
- Feature with prioritized stories + Independent Test
- Fix-log with severity P0-P3 + area + reported_by
- Checkin (BDA Daily Log v5 schema)
- Handoff (HOR-*.md)
- ADR (MADR format)
- Function spec (FN-*.md)
- Test plan + evidence manifest + design system
- + more

### 5 helper scripts

- `scripts/install.sh` — one-line bootstrap (curl-pipe ready, --ai picker, interactive mode question)
- `scripts/upgrade.sh` — bump bda-spec with backup + rollback (preserves user content)
- `scripts/bda-paths.sh` — JSON/shell config resolver (single source for all 20 commands)
- `scripts/upload-evidence.sh` — rclone GDrive uploader (6 hard gates)
- `scripts/test.sh` — 233 smoke tests
- `bin/bda-spec` — CLI wrapper (init / upgrade / sync / doctor / test / paths)

### Configuration model

| File | gitTracked | Purpose |
|---|---|---|
| `.bda-spec.yml` | ✅ | shared — project, mode, vault path, subagents, submodules, AI agents |
| `.bda-spec.local.yml` | ❌ | personal — external vault, daily-log mirror, GDrive folder, AI cost tracking |
| `.bda-spec/local/commands/` | ❌ | personal slash commands |
| `.bda-spec/local/templates/` | ❌ | personal template overrides |

Template lookup chain: `.bda-spec/local/templates/` → `templates/` → `standards/templates/`

### 3-tier evidence storage

ดู [`EVIDENCE-PATHS.md`](./EVIDENCE-PATHS.md):

1. **Tier 1** — `test-artifacts/<DATE>/<slug>/` (gitignored, raw with PII)
2. **Tier 2** — `docs/<context>/<slug>/evidence/` (committed, masked via `/bda-evidence`)
3. **Tier 3** — `<gdrive_folder>/<DATE>/<context>/` (uploaded via `/bda-upload`)

ทุก agent §5.5 ระบุชัดว่าเขียน Tier ไหน, ทุกการ upload ผ่าน 6 hard gates

### Greenfield + brownfield detection

Installer ตรวจ indicators (package.json, src/, .git+commits, docs/ with content, .gitmodules):
- **ไม่มี indicator** → greenfield auto (no question)
- **มี indicator** → ถาม user 3 ตัวเลือก: greenfield / brownfield / adopt-vault

`--here` flag ไม่ assume brownfield — ตัดสินจาก code indicators ของจริงเสมอ

### Sample vault

`docs/` มี Library Book Tracker sample (47 ไฟล์):
- PRD + SRS + 3 features + 4 functions
- Design system (Tokens + Components + Patterns + A11y + Layout + preview.html)
- 2 implement plans + 1 fix-log + 3 daily check-ins + 2 test plans + 1 handoff
- Full IMPLEMENTATION-STATUS dashboard

### Documentation

- `README.md` — quick start + 20 commands + 4 workflows + config
- `AI-README.md` — multi-AI usage guide
- `CLAUDE.md` — Claude project entry
- `EVIDENCE-PATHS.md` — 3-tier evidence strategy
- `DISTRIBUTION.md` — release flow + spec-kit comparison
- `usage/` — 20+1 user-facing usage docs (Quick start, FAQ, gotchas per command)
- `commands/` — 20 source-of-truth Phase specifications

### Quality

- **233 smoke tests** (`scripts/test.sh`) covering structure, shims, frontmatter, gates, standards banner, multi-AI maps, paths resolution, sample vault, template lookup chain
- **doctor command** (`bda-spec doctor`) for health check

---

## Acknowledgements

- [spec-kit](https://github.com/github/spec-kit) by GitHub
- [BDA AI Dev Standard](https://github.com/BigDataAgency/bda-ai-dev-standard) by Big Data Agency
- [thai-cleft-main](https://github.com/BigDataAgency/thai-cleft-main) — reference implementation

## License

MIT — see `LICENSE`
