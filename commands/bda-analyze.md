---
description: Cross-artifact consistency analyzer — Coverage Summary Table (FR-### → Task IDs) + findings report; read-only
model: claude-sonnet-4-6
---

# /bda-analyze — Cross-artifact Consistency Report

อ่าน PRD + Features + Functions + active plan + tasks → ตรวจ:
- **Duplication** (FR ซ้ำ, function spec ซ้ำ)
- **Ambiguity** (weasel words ที่ /bda-clarify ยังไม่ได้แก้)
- **Underspecification** (FR ไม่มี acceptance criteria, function ไม่มี state)
- **Constitution alignment** (ขัด STANDARD/policies/constitution)
- **Coverage gaps** (FR ไม่ map กับ plan step, function ไม่มี FR)
- **Inconsistency** (terminology, data model)

Output: report ที่ `docs/obsidian-vault/95-Handoff/ANALYSIS-<date>-<scope>.md`

> **inspired by:** spec-kit `/analyze`
> **Read-only** — ไม่แก้ source ใดๆ

## Trigger

```
/bda-analyze                          # project-wide (default: all open features)
/bda-analyze --feature <slug>         # specific feature
/bda-analyze --plan <path>            # specific plan
/bda-analyze --severity high          # filter (CRITICAL/HIGH/MED/LOW; default: all)
/bda-analyze --max 50                 # max findings (default: 50)
/bda-analyze --coverage-only          # only Coverage Summary Table
```

## Phase 0 — Resolve scope

```bash
eval "$(bash scripts/bda-paths.sh --shell)"

case "$SCOPE" in
  feature) ARTIFACTS=$(grep -l "feature: $SLUG" "$VAULT_PATH"/{10-PRD,20-Features,40-Functions,80-ImplementPlan,90-TestPlan}/*.md) ;;
  plan)    ARTIFACTS="$PLAN_PATH" ;;
  *)       ARTIFACTS=$(find "$VAULT_PATH"/{10-PRD,20-Features,40-Functions,50-Phases,80-ImplementPlan} -name "*.md" -not -name "_*") ;;
esac

echo "Analyzing $(echo "$ARTIFACTS" | wc -l) artifacts"
```

## Phase 1 — Gather

อ่านทุก artifact, extract:

- **IDs**: PRD ID, FEAT-*, FN-*, FR-###, SC-###, T###, US### (user story)
- **Frontmatter**: status, priority, related, blocked_by
- **Cross-refs**: wikilinks + explicit related lists
- **Tasks**: checkbox items `- [ ] T### [P?] [USx] desc` from plan files
- **Constitution refs**: standards/STANDARD.md + standards/policies/* + docs/obsidian-vault/00-Index/CONSTITUTION.md (if exists)

## Phase 2 — Find issues

### 2.1 Coverage Summary Table

```markdown
| FR ID | Source Doc | Plan Step(s) covering | Task ID(s) | Test Plan Item | Status |
|---|---|---|---|---|---|
| FR-001 | SRS § Functional | plan-2026-05-19 step 3-5 | T003, T004 | TP-FEAT-Checkout § Scenario 2 | covered |
| FR-002 | SRS § Functional | (none) | (none) | (none) | ❌ ORPHAN |
| FR-003 | SRS § Functional | plan-2026-05-20 step 1-2 | T001 | TP-FEAT-Return § S1 | covered |
| FR-004 | PRD § Goals | plan-2026-05-19 step 7 | (no task ID — prose only) | (none) | 🟡 PARTIAL |
```

ทุก FR ที่ไม่มี task ID = orphan → flag CRITICAL

### 2.2 Findings (max N items)

```markdown
| ID | Category | Severity | Location | Summary | Recommendation |
|---|---|---|---|---|---|
| A001 | Duplication | MEDIUM | FEAT-Checkout § Functions + FEAT-Returns § Functions | Both list FN-Web-Lib-MemberSearch | extract เป็น shared component หรือ link |
| A002 | Ambiguity | HIGH | PRD § Goals "improve search" | "improve" ไม่มี SC measurable | /bda-clarify หรือเพิ่ม SC-### |
| A003 | Coverage gap | CRITICAL | FR-002 (Return book) | ไม่มี plan/task ใดมัด | สร้าง plan หรือ remove FR |
| A004 | Constitution | HIGH | plan-2026-05-20 step 3 "skip test ตอน MVP" | ขัด policies/no-fake-evidence | ต้องมี test ทุก code change |
| A005 | Underspecification | MEDIUM | FN-Web-Lib-Checkout § States | missing 'error' state | เพิ่ม state + recovery |
| A006 | Inconsistency | MEDIUM | PRD vs SRS | PRD ใช้ "member", SRS ใช้ "patron" | unify ใน glossary |
```

Severity scale:
- **CRITICAL** — blocks implementation, broken assumption, missing safety
- **HIGH** — เกิด rework รุนแรง, ขัด policy
- **MEDIUM** — quality issue, ควรแก้ก่อน handoff
- **LOW** — polish, optional

### 2.3 Metrics

```markdown
**Artifacts analyzed:** 12
**Total FRs:** 18 (covered: 15 / orphan: 2 / partial: 1)
**Total tasks:** 24 (mapped to FR: 21 / unmapped: 3)
**Constitution checks:** 5 (passed: 4 / violation: 1)
**Terminology consistency:** 92% (3 mismatches)
**Coverage ratio:** 15/18 = 83%
```

## Phase 3 — Write report

Path: `docs/obsidian-vault/95-Handoff/ANALYSIS-<YYYY-MM-DD>-<scope>.md`

```markdown
---
tags: [type/analysis]
date: 2026-05-21
scope: project-wide | feature:<slug> | plan:<file>
artifacts_count: 12
findings_total: 6
critical: 1
high: 2
medium: 3
low: 0
status: draft
---

# Cross-artifact Analysis — <scope> · <date>

## Executive Summary
- **Coverage ratio:** 83%
- **Critical findings:** 1 (orphan FR-002)
- **Top risk:** FR-002 (Return book) has no plan/task — implementation blocked.

## Coverage Summary Table
<table from 2.1>

## Findings
<table from 2.2>

## Metrics
<2.3>

## Recommendations
1. Add plan for FR-002 (or remove if descoped)
2. Run /bda-clarify on PRD § Goals to refine "improve search"
3. Add 'error' state to FN-Web-Lib-Checkout

## Pipeline trace
- Understand: Phase 0/1 — read 12 artifacts
- Plan: Phase 2 — apply 6 analyzers
- Execute: Phase 3 — write this report
- Verify: re-grep IDs to confirm count
- Handoff: link this in IMPLEMENTATION-STATUS

(5 mandatory sections at end)
```

## Phase 4 — Update dashboard

Update `docs/obsidian-vault/00-Index/IMPLEMENTATION-STATUS.md`:
- Last analysis: `<this report path>` (<date>)
- Coverage ratio: 83%
- Outstanding critical: 1

## Phase 5 — Log

Append ใน `docs/obsidian-vault/75-Checkins/<today>.md`:
```
- HH:MM — [type/analyze] /bda-analyze <scope> — 6 findings (1 crit, 2 high, 3 med); coverage 83%; report: <link>
```

## Output (5 หัวข้อบังคับ)

1. **BDA Standard files used** — `standards/STANDARD.md`, `standards/policies/no-fake-evidence.md`, `standards/policies/source-of-truth.md`
2. **Pipeline trace** — Understand (Phase 0/1) → Plan (Phase 2 analyzers) → Execute (Phase 3 report) → Verify (re-count IDs) → Handoff (Phase 4 dashboard)
3. **Commands run** — `find`, `grep -E "FR-[0-9]+"`, `grep weasel`, Read all artifacts
4. **Verification / Evidence** — report path, finding count by severity, coverage %
5. **Limitations / Risks / Next steps** — orphan FRs ต้องแก้, ambiguities ต้อง /bda-clarify, constitution violations ต้อง revise plan

## ห้าม

- **ห้ามแก้ source artifact ใดๆ** — analyze read-only
- ห้าม invent FR ที่ไม่มีจริง — ถ้า doc มีแค่ prose → flag เป็น underspecification, ไม่สร้าง FR-### เอง
- ห้าม mark "covered" ถ้า task ไม่มี ID ที่ link ชัด — ใส่ PARTIAL แทน
- ห้าม include suggestion ที่ไม่มี cite source artifact
- ห้าม overwrite ANALYSIS report เก่า — รายงานใหม่เป็นไฟล์ใหม่ (date-stamped)
- ห้ามแก้ Coverage ratio ใน IMPLEMENTATION-STATUS โดยไม่ verify count ใหม่
