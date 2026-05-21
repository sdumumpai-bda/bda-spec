---
tags: [type/handoff]
date: <YYYY-MM-DD HH:mm>
title: <handoff title>
scope: <plan-slug | feature-name | diff-range>
status: ready-for-review       # ready-for-review | approved | deployed
audience: [executive, reviewer, qa]
recipient: <if specific>
---

# Handoff — <Title>

## Summary (1 paragraph, exec-friendly)
สรุปงานที่เสร็จ + business value + ผลกระทบ — ภาษาง่าย ไม่ใช่ technical jargon

## What Changed
- Files changed: N (production: M, tests: K)
- New features: <list>
- Bugs fixed: <list>
- Docs updated: <list>

## Verification
- Tests: <N passed / M total> — evidence: <path>
- Build: <pass/fail>
- Lint: <pass/fail>
- Manual checks: <list — link evidence>

## Design System Compliance
- Components used: <list from DS>
- New components added: <list — refs to /bda-design>
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
- <list ที่ใช้จริง>

## Pipeline trace
- Understand: <command + result>
- Plan: <plan file path>
- Execute: <subagent + outputs>
- Verify: <verify run + results>
- Handoff: this document

## Commands run
- (list ทุก slash command + bash command ที่รันจริง + exit code)

## Evidence Manifest
- Plan: <[[80-ImplementPlan/<slug>]]> (status: done)
- Test evidence: docs/90-TestPlan/evidence/<slug>/ (N screenshots, N logs)
- Git commits: <list of hashes>

## Limitations / Risks / Next steps
- <known limitation>
- <risk + mitigation>
- <next step recommended>

## Rollback / Mitigation
- <production-facing rollback plan — required if affects prod>

## Approval
- [ ] Reviewed by: <reviewer name>
- [ ] Approved at: <YYYY-MM-DD HH:mm>
- [ ] Deployed to: <env>
