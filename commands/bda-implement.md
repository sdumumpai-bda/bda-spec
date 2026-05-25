---
description: Execute approved plan file via subagent — captures evidence, syncs vault
model: claude-sonnet-4-6
---

<!--
BDA Standard v0.8.0 alignment (matches `commands/build-feature.md` + `commands/fix-bug.md`):
- Read Obsidian context manifest FIRST
- Append feature/fix summary + changed files + verification + evidence to ACTIVE session note
- After implementation: dispatch update-obsidian behavior — reconcile session/evidence/index notes
- Use `standards/templates/obsidian-work-note.md` shape สำหรับ session note ที่สร้าง
-->


# /bda-implement — ลงมือทำตาม plan

Execute plan file ที่ approve แล้ว spawn subagent ที่ถูกต้อง เก็บ evidence

## Trigger

```
/bda-implement docs/obsidian-vault/80-ImplementPlan/YYYY-MM-DD-HHmm-<slug>.md
/bda-implement <slug>      # auto-locate by slug
```

ว่าง → ถามว่า plan ไหน + list 5 plans ล่าสุดที่ `status: approved`

## Phase 1 — Validate

1. อ่าน plan file
2. **Refuse** ถ้า `status != approved` → แจ้ง user ให้ set status ก่อน
3. **Refuse** ถ้า `status: done` แล้ว → แจ้ง user
4. ตรวจว่า `Implementation Steps` ครบ + `subagent_target` set
5. แสดง task + submodule + step count → ถาม "ลงมือเลย?"
6. ถ้า `Doc Gaps Found` ไม่ว่าง → ไป Phase 2 ก่อน

## Phase 2 — Fix doc gaps (ถ้ามี)

Spawn `docs` subagent:
```
Plan: <path>
Gaps to fix: <list>
Rule: แก้ factual discrepancy เท่านั้น ห้ามเปลี่ยน implementation intent
```

รอจบ → ค่อยไป Phase 3

## Phase 3 — Spawn subagent ตาม target

| `subagent_target` ใน plan | Spawn |
|---|---|
| `backend` | `.claude/agents/backend.md` |
| `frontend` | `.claude/agents/frontend.md` |
| `mobile` | `.claude/agents/mobile.md` |
| `docs` | `.claude/agents/docs.md` |
| `design` | `.claude/agents/design.md` |
| `all` | sequence: backend → frontend → mobile → docs |

Prompt ที่ส่งให้ subagent:
```
Plan file: <path>
Task: <task field จาก frontmatter>

Instructions:
1. อ่าน full plan ก่อนแตะ code — โดยเฉพาะ Success Criteria และ Implementation Steps
2. ทำตาม Implementation Steps ตามลำดับ — minimum correct change เท่านั้น
3. ทุก changed line ต้อง trace กลับไปยัง step ใน plan, success criteria, หรือ verification ได้
4. ห้ามเพิ่ม abstraction/config/dependency/feature นอก scope ของ plan
5. ห้าม refactor หรือ reformat ไฟล์ที่ไม่เกี่ยวกับ task
6. ทำตาม existing patterns ของ repo ก่อนสร้าง pattern ใหม่
7. Enforce gates ของ agent (test creation, design system compliance, security)
8. หลังเสร็จ: map verification กลับไปยัง Success Criteria ทีละข้อ
9. Update vault per Vault Update Checklist ของ plan
10. Report: files changed (production vs test), vault docs updated
11. ห้าม fake evidence — ถ้า test รันไม่ผ่าน บอก blocker
```

## Phase 4 — Design system gate (ถ้ามี)

ถ้า `docs/obsidian-vault/70-Reference/DesignSystem/` มีอยู่ และ subagent คือ `frontend` หรือ `mobile`:

ก่อน subagent เขียน UI code → บังคับให้:
1. อ่าน `DS-Tokens.md`, `DS-Components.md`, `DS-Patterns.md`
2. ใช้ token/component ที่มี
3. ถ้าต้อง component ใหม่ → STOP, แจ้ง user ให้รัน `/bda-design` เพิ่ม component นั้นก่อน

## Phase 5 — Capture evidence

หลัง implement เสร็จ — เก็บอย่างน้อย:
- diff summary (`git diff --stat`)
- test output (path/file ของ test run)
- screenshot (ถ้า UI — ผ่าน `/bda-test` หรือ manual upload)

เก็บใน `docs/obsidian-vault/90-TestPlan/evidence/<plan-slug>/`

## Phase 6 — Update plan + checkin

1. Plan frontmatter: `status: done`, `completed_at: YYYY-MM-DD HH:mm`
2. Append section ใน plan:
   ```markdown
   ## Implementation Result
   - Files changed: <list>
   - Tests added: <list>
   - Evidence: docs/obsidian-vault/90-TestPlan/evidence/<slug>/
   - Subagent used: <name>
   - Time: <duration>
   ```
3. Update `docs/obsidian-vault/00-Index/IMPLEMENTATION-STATUS.md` mark feature/phase done
4. Append checkin entry:
   ```markdown
   - HH:MM — [type/implement] Completed <plan-slug> — files: N, tests: N
   ```

## Phase 7 — Output (5 หัวข้อบังคับ)

1. **BDA Standard files used** — `standards/STANDARD.md`, `standards/policies/no-fake-evidence.md`, `standards/policies/evidence-verification.md`, plan file
2. **Pipeline trace** — Understand (Phase 1 read plan) → Plan (plan file itself) → Execute (Phase 3 spawn subagent) → Verify (Phase 5 evidence) → Handoff (Phase 6 update)
3. **Commands run** — ทุก bash, test, build command ที่รันจริง พร้อมผล
4. **Verification / Evidence** — paths ของ evidence files + test results (pass/fail counts)
5. **Limitations / Risks / Next steps** — เช่น "Manual UAT ยังไม่ทำ", "Production deploy ต้อง /bda-verify ก่อน"

## ห้าม

- ห้าม implement ถ้า plan ไม่ `approved`
- ห้ามแก้ scope จาก plan โดยไม่ revise plan ก่อน (`/bda-plan --revise`)
- ห้าม fake test/build evidence
- ห้ามแก้ shared/production env โดยไม่ confirm
- ห้ามเพิ่ม speculative abstraction/config/dependency/feature ที่ plan ไม่ได้ระบุ
- ห้าม refactor หรือ format churn ไฟล์นอก scope
- ห้าม deliver งานโดยไม่มี verification map กลับไปยัง success criteria
