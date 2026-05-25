---
description: สร้าง Handoff Report ส่งงานต่อให้ reviewer / exec / QA + อัปเดต status
model: claude-sonnet-4-6
---

# /bda-handoff — ส่งงานต่อ (Handoff Report)

สร้างเอกสารส่งงานอย่างเป็นทางการให้ reviewer / exec / QA อ่านและ approve

> ควรรัน `/bda-verify` ให้ผ่านก่อน แล้วค่อย `/bda-handoff`

## Trigger

```
/bda-handoff <plan-or-fix-path>     # handoff งานจาก plan/fix ที่ระบุ
/bda-handoff --feature <name>       # handoff ทั้ง feature
/bda-handoff --since <ref>          # handoff ทุกอย่างใน diff range
```

ว่าง → ถามว่า handoff งานอะไร + list 5 plans ล่าสุดที่ `status: done`

## Phase 1 — Pre-flight check

1. อ่าน plan/fix file
2. **Warn** ถ้า `status != done` — แนะนำให้ implement ก่อน
3. **Warn** ถ้ายังไม่ได้รัน `/bda-verify` — แสดงข้อความ แต่ไม่ block (user เลือกได้)
4. อ่าน evidence ที่มีใน `docs/obsidian-vault/90-TestPlan/evidence/<slug>/`

## Phase 2 — สร้าง Handoff Report

Path: `docs/obsidian-vault/95-Handoff/HOR-<YYYY-MM-DD>-<slug>.md`

```markdown
---
tags: [type/handoff]
date: YYYY-MM-DD HH:mm
title: <handoff title>
scope: <plan-slug | feature-name | diff-range>
status: ready-for-review     # ready-for-review | approved | deployed
audience: [executive, reviewer, qa]
recipient: <ระบุถ้ามีคนรับงานชัดเจน>
---

# <Title>

## Summary
สรุปงานที่เสร็จ + business value + ผลกระทบ ภาษาเข้าใจง่าย (สำหรับ exec/reviewer)

## What Changed
- Files changed: N (production: M, tests: K)
- New features: <list>
- Bugs fixed: <list>
- Docs updated: <list>

## Verification Results
- Tests: <N passed / M total> — evidence: <path>
- Build: <pass/fail>
- Lint: <pass/fail>
- Manual checks: <list — link to evidence>

## Design System Compliance
- Components used: <list from DS>
- New components added: <list>
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
- (list path ที่ใช้จริง)

## Pipeline trace
- Understand: /bda-new / /bda-plan
- Plan: docs/obsidian-vault/80-ImplementPlan/<slug>.md
- Execute: /bda-implement → subagent <name>
- Verify: /bda-verify
- Handoff: this document (/bda-handoff)

## Commands run
- (list ทุก slash command + bash command ที่รันจริงตลอด pipeline)

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

## Phase 3 — อัปเดต status

1. Plan frontmatter: `status: handed-off`
2. `docs/obsidian-vault/00-Index/IMPLEMENTATION-STATUS.md` → mark scope `ready-for-review`
3. Checkin entry:
   ```markdown
   - HH:MM — [type/handoff] Handoff created: HOR-<slug>.md → reviewer: <name>
   ```

## Output (5 หัวข้อบังคับ)

Handoff Report **คือ** output — ทุก section ในเอกสารครอบ 5 หัวข้อบังคับครบ

## ห้าม

- ห้าม fake evidence ใน handoff report
- ห้าม approve ตัวเอง — section Approval ให้ reviewer กรอก
- ห้าม push handoff to public ถ้ามี customer PII
- ห้ามสร้าง handoff ถ้า plan ยังไม่ done — warn user ให้ทำให้เสร็จก่อน
