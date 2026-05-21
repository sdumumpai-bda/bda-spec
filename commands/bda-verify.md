---
description: Full verify (tests + evidence + vault + security + DS) then create executive handoff report
model: claude-sonnet-4-6
---

# bda-verify — Full Verify + Handoff (รวม verify-work + handoff-report)

ตรวจครบทุกมิติ + สร้าง handoff report สำหรับ executive/reviewer

## Trigger

```
/bda-verify <plan-or-fix-path>      # ตรวจ specific work
/bda-verify --since <ref>           # ตรวจทุกอย่างใน diff range
/bda-verify --feature <name>        # ตรวจ feature scope
```

## Phase 1 — Scope identification

อ่าน:
- Plan/fix file ที่ user ระบุ
- Files changed (`git diff`)
- Vault docs ที่ link (Feature, Function, PRD)

## Phase 2 — Test verification

รัน (หรือดูว่ารันแล้ว):
- Unit tests (relevant scope)
- Integration tests
- Lint
- Build
- Type check

**ห้าม fake** — ถ้ารันไม่ได้ ระบุ blocker + reason

## Phase 3 — Evidence audit

ตรวจ `docs/obsidian-vault/90-TestPlan/evidence/<scope>/`:
- [ ] Manifest มี
- [ ] Screenshot ครบตาม test plan
- [ ] PII masked
- [ ] Console logs + network logs เก็บแล้ว
- [ ] Route source trace ระบุ
- [ ] Status taxonomy ถูก (PASS/FAIL/BLOCKED_*/NOT_RUN_RISK)

## Phase 4 — Vault consistency

```bash
# ตรวจ link ทุก [[...]] ใน docs ของ scope
# ตรวจ IMPLEMENTATION-STATUS update
# ตรวจ docs ใหม่ที่ควรเพิ่ม (function spec ของ feature ใหม่)
```

ถ้าเจอ inconsistency → list ให้ user → เสนอ /bda-doc แก้

## Phase 5 — Security pre-flight

เรียก /bda-secure logic — ตรวจ secrets, PII, masking, public-repo, prod guardrails

ถ้าผลเป็น BLOCKED → STOP verify, user ต้องแก้ก่อน

## Phase 6 — Design system audit (ถ้ามี frontend/mobile)

ถ้า `docs/obsidian-vault/70-Reference/DesignSystem/` มีอยู่ + scope กระทบ UI:
- เรียก /bda-design audit logic
- ตรวจ component compliance, contrast, focus state
- Report violations

## Phase 7 — Handoff report

สร้าง `docs/obsidian-vault/95-Handoff/HOR-<YYYY-MM-DD>-<slug>.md`:

```markdown
---
tags: [type/handoff]
date: YYYY-MM-DD HH:mm
title: <handoff title>
scope: <plan-slug | feature-name | diff-range>
status: ready-for-review     # ready-for-review | approved | deployed
audience: [executive, reviewer, qa]
recipient: <if specific>
---

# <Title>

## Summary (1 paragraph)
สรุปงานที่เสร็จ + business value + ผลกระทบ ภาษาง่าย (สำหรับ exec)

## What Changed
- Files changed: N (production: M, tests: K)
- New features: <list>
- Bugs fixed: <list>
- Docs updated: <list>

## Verification
- Tests: <N passed / M total> — evidence: <path>
- Build: <pass/fail>
- Lint: <pass/fail>
- Manual checks: <list — link to evidence>

## Design System Compliance
- Components used: <list from DS>
- New components added: <list — references in /bda-design>
- Violations: 0 / N

## Security Pre-flight
- Secret scan: <result>
- PII scan: <result>
- Screenshot masking: <result>
- Production guardrails: <result>

## BDA Standard files used
- standards/STANDARD.md
- standards/policies/no-fake-evidence.md
- standards/policies/evidence-verification.md
- (list ที่ใช้จริง)

## Pipeline trace
- Understand: /bda-new / /bda-plan
- Plan: docs/obsidian-vault/80-ImplementPlan/<slug>.md
- Execute: /bda-implement → subagent <name>
- Verify: /bda-test + /bda-verify (this report)
- Handoff: this document

## Commands run
- (list ทุก slash command + bash command ที่รันจริง)

## Evidence Manifest
- docs/obsidian-vault/80-ImplementPlan/<slug>.md (plan, status: done)
- docs/obsidian-vault/90-TestPlan/evidence/<slug>/ (N screenshots, N logs)
- Git commits: <commit hashes>

## Limitations / Risks / Next steps
- <known limitation>
- <risk + mitigation>
- <next step recommended>

## Rollback / Mitigation
- <ถ้า production-facing — rollback plan>

## Approval
- [ ] Reviewed by: <reviewer>
- [ ] Approved at: <YYYY-MM-DD HH:mm>
- [ ] Deployed to: <env>
```

## Phase 8 — Update status

- Plan → `status: handed-off`
- IMPLEMENTATION-STATUS → mark scope `ready-for-review`
- Checkin → log entry

## Output (5 หัวข้อบังคับ — เป็นใน handoff doc เอง)

handoff report **คือ** output 5 หัวข้อบังคับ — ครบทุก section

## ห้าม

- ห้าม verify ที่ test ไม่ผ่าน — STOP, แจ้ง user
- ห้าม fake evidence ใน handoff report
- ห้าม approve ตัวเอง — section Approval ให้ reviewer ทีหลัง
- ห้าม push handoff to public ถ้ามี customer PII
