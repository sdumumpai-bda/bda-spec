# CLAUDE.md — bda-spec

โปรเจกต์นี้ใช้ **bda-spec** — AI + Obsidian docs-driven development ที่รวม BDA AI Dev Standard, spec-kit philosophy, และ daily executive reporting

## หัวใจ 3 ข้อ

1. **Vault-first** — Claude อ่าน `docs/` (Obsidian vault) ก่อนถามคำถาม หรือเขียนโค้ด เสมอ
2. **Plan/Implement แยกกัน** — `/bda-plan` สร้าง plan file (ไม่แก้โค้ด), `/bda-implement` เท่านั้นที่แก้โค้ด, `/bda-fix` แค่ diagnose
3. **Log everything** — ทุกการ plan/fix/checkin มี log ใน vault, มี evidence ตรวจสอบได้

## เริ่มต้น

| สถานการณ์ | คำสั่ง |
|---|---|
| Project ยังไม่มี vault | `/bda-init` |
| ไอเดียใหม่ ยังไม่มี PRD | `/bda-new` แล้วเลือก `brainstorm` |
| มี PRD อยู่แล้ว อยากต่อ SRS/Tech | `/bda-new` แล้วเลือก `import-prd` |
| วางแผน feature/task | `/bda-plan <task>` |
| ลงมือทำตาม plan | `/bda-implement <plan-file>` |
| แก้บั๊ก | `/bda-fix <bug>` |
| Daily check-in (เช้า/เที่ยง/เย็น) | `/bda-checkin` |

## คำสั่งทั้งหมด (19 ตัว)

<!-- BDA-SPEC START: command-list -->
ดู `.claude/commands/` หรือพิมพ์ `/bda-` ใน Claude Code แล้วกด Tab

```
ช่วยเหลือ:        /bda-help        ← ถ้าไม่รู้จะใช้ตัวไหน
ตั้งค่า:          /bda-init        /bda-sync       /bda-agent
spec-driven:     /bda-new         /bda-clarify    /bda-plan        /bda-analyze
                 /bda-checklist   /bda-implement  /bda-fix
เอกสาร+ทดสอบ:    /bda-doc         /bda-test       /bda-design      /bda-evidence
ประจำวัน:         /bda-checkin
ส่งมอบ:           /bda-secure      /bda-verify     /bda-git
```

**ไม่รู้จะเริ่มที่ไหน?** → `/bda-help` แล้วตอบคำถาม → จะแนะนำ command ที่ตรงสถานการณ์
<!-- BDA-SPEC END: command-list -->

## Spec-driven workflow (spec-kit pattern)

```
/bda-new        — สร้าง PRD/SRS/Tech-spec
/bda-clarify    — taxonomy ambiguity scan (1-at-a-time + recommended answer)
/bda-plan       — research vault + create plan with FR-### / T### + Constitution Check gate
/bda-analyze    — cross-artifact consistency + Coverage Summary Table (FR-### → T###)
/bda-checklist  — "unit tests for English" — spec-quality gate per domain (ux/api/security/perf)
/bda-implement  — execute approved plan via specialized subagent
```

## Helper scripts

```
scripts/bda-paths.sh   — JSON/shell-eval'able config + path resolution (single source)
scripts/upgrade.sh     — bump bda-spec itself (preserves templates/, docs/, configs)
scripts/test.sh        — smoke tests (run: `bash scripts/test.sh`)
scripts/install.sh     — initial bootstrap (one-line installer)
bin/bda-spec doctor    — health check
```

## หลักการที่บังคับใช้ (จาก BDA AI Dev Standard)

ทุก output ของ Claude ต้องมี **5 หัวข้อบังคับ**:

1. **BDA Standard files used** — path ของไฟล์มาตรฐานที่อ้างอิงจริง
2. **Pipeline trace** — Understand → Plan → Execute → Verify
3. **Commands run** — คำสั่งที่รันจริง พร้อมผลลัพธ์
4. **Verification / Evidence** — หลักฐานตรวจจริง (test/lint/build/screenshot)
5. **Limitations / Risks / Next steps** — ข้อจำกัด ความเสี่ยง งานต่อ

**ห้ามเด็ดขาด:**
- ห้ามอ้าง test ผ่านโดยไม่ได้รัน
- ห้ามแต่ง commit hash, URL, token count
- ถ้าไม่มี evidence ให้เขียน `pending evidence`
- ห้ามแก้ shared repo หรือ production โดยไม่ confirm scope

## โครงสร้าง vault (`docs/`)

```
00-Index/         MOCs, IMPLEMENTATION-STATUS
10-PRD/           Product Requirements (PRD-*.md)
20-Features/      FEAT-*.md
30-Roles/         Role-based views
40-Functions/     Granular function specs (FN-*.md)
50-Phases/        Phase planning (PHASE-*.md)
60-Flows/         User flows
70-Reference/     AuthorizationMatrix, APIIntegration, TechStack, ADRs
75-Checkins/      Daily check-in (YYYY-MM-DD.md — 1 file/วัน)
80-ImplementPlan/ Implementation plans (YYYY-MM-DD-HHmm-<slug>.md)
85-FixLog/        Bug fix logs (YYYY-MM-DD-HHMM-<slug>.md)
90-TestPlan/      Test plans + evidence manifest
95-Handoff/       Executive handoff reports (HOR-*.md)
```

## Configuration

`.bda-spec.yml` ที่ root กำหนด:
- `mode`: `standalone` หรือ `submodule`
- `vault_path`: ตำแหน่ง vault (default: `docs/`)
- `standard_version`: version ของ BDA standard ที่ใช้ (pinned)
- `subagents`: agents ที่ใช้ (docs, verifier, security, backend, frontend, mobile, figma)
- `submodules`: list submodules ถ้ามี (เช่น `[api, web, app]`)

## Standards snapshot

`standards/` เก็บ snapshot ของ BDA AI Dev Standard ที่ pin ไว้

- `STANDARD.md` — 5-step pipeline
- `policies/` — no-fake-evidence, evidence-verification, source-of-truth, working-result
- `checklists/` — before-start, before-commit, before-handoff, code-review
- `templates/` — org-level templates ที่ทุก project ใช้ร่วมกัน
- `VERSION` — version ที่ pinned

อัปเดต: `/bda-sync`

## Templates ของ project (`templates/`)

Override ของ `standards/templates/` ตามความเหมาะสมของ project นี้ — ถ้าไฟล์เดียวกันมีทั้งใน `templates/` และ `standards/templates/` `/bda-doc` จะใช้ตัวใน `templates/` ก่อน

## ภาษา

รายงาน + log ทั้งหมดเป็น **ภาษาไทย** (ตาม BDA standard); code comments + frontmatter เป็นอังกฤษได้
