---
description: Generate domain checklist — "unit tests for English" to validate spec quality before implementation
model: claude-sonnet-4-6
---

# /bda-checklist — Spec Quality Checklist Generator

สร้าง checklist ที่เป็น **"unit tests for English"** — ทดสอบคุณภาพ spec ไม่ใช่ behavior ของ code
แต่ละ CHK item เป็นคำถามที่ author ตอบเอง: ✅ Yes / ❌ No → ✅ ทุกข้อก่อน implement

> **inspired by:** spec-kit `/checklist`

## Trigger

```
/bda-checklist                        # interactive — ถาม domain
/bda-checklist <domain>               # generate ใหม่
/bda-checklist <domain> --append      # เพิ่ม items ลง checklist เดิม
/bda-checklist review <path>          # ตรวจ checklist ที่ user ตอบแล้ว
/bda-checklist list                   # แสดง checklists ทั้งหมดของ project
```

## Phase 0 — Detect domain

Domains ที่ default มี:

| Domain | ตรวจอะไร |
|---|---|
| **ux** | clarity, accessibility, error handling, copy, loading states |
| **api** | versioning, auth, errors, idempotency, rate limit, schema |
| **security** | secrets, PII, threat model, audit log, OWASP top 10 |
| **performance** | latency, throughput, payload size, cache, query N+1 |
| **data** | schema migration, retention, backup, GDPR, integrity |
| **a11y** | WCAG AA, keyboard, screen reader, contrast, focus |
| **observability** | logs, metrics, traces, alerts, dashboards |
| **rollout** | feature flag, rollback, monitoring, canary, comms |
| **<custom>** | user-defined — สร้างเองได้ |

ถ้า `$ARGUMENTS` ว่าง → ถาม "domain ไหน?" (multi-select ได้)

## Phase 1 — Determine scope

ถาม:
1. **Target**: feature ไหน / PRD ไหน / project-wide?
2. **Phase**: pre-design / pre-implementation / pre-release?
3. **Append หรือ new file**?

## Phase 2 — Generate items (CHK### format)

แต่ละ item เป็น **คำถามที่ทดสอบ spec ไม่ใช่ implementation**

Examples สำหรับ `ux`:
```markdown
- [ ] CHK001 ทุก action button ใน spec ระบุ "ทำอะไรเมื่อ user คลิก" ชัดเจน (ไม่ใช่แค่ชื่อ)?
- [ ] CHK002 ทุก form field ระบุ validation rule + error message ที่ user จะเห็น?
- [ ] CHK003 ทุก state (idle/loading/success/error/empty) มี wireframe หรือคำอธิบาย?
- [ ] CHK004 Copy ทั้งหมดเป็นภาษาที่กำหนด (th/en) + ผ่าน tone guideline?
- [ ] CHK005 Loading > 1 วินาที มี loading indicator + estimated time?
- [ ] CHK006 Error message บอก user ว่า "ทำอะไรต่อ" ไม่ใช่แค่ "เกิดข้อผิดพลาด"?
- [ ] CHK007 ทุก destructive action (delete/cancel) มี confirmation dialog?
- [ ] CHK008 ทุก dialog ระบุ keyboard behavior (Escape, Enter, Tab focus trap)?
- [ ] CHK009 Mobile layout ระบุ ตั้งแต่ width < 640px?
- [ ] CHK010 Empty state มี call-to-action ที่ user รู้ว่าทำอะไรต่อ?
```

Examples สำหรับ `api`:
```markdown
- [ ] CHK001 ทุก endpoint ระบุ HTTP method + path pattern + auth requirement?
- [ ] CHK002 Request schema ระบุ field type + required/optional + max length?
- [ ] CHK003 Response schema ระบุ success format + ทุก error code + message structure?
- [ ] CHK004 Idempotency — POST/PUT ระบุ idempotency-key behavior?
- [ ] CHK005 Rate limit ระบุ (per-user / per-IP) + response เมื่อเกิน?
- [ ] CHK006 Pagination ระบุ format (offset/cursor) + max page size?
- [ ] CHK007 Backward compatibility — breaking change ระบุ versioning?
- [ ] CHK008 ทุก timestamp ระบุ timezone (UTC vs local)?
- [ ] CHK009 PII fields ใน response ระบุ masking rule?
- [ ] CHK010 Webhook retry policy + signature verification ระบุ?
```

Examples สำหรับ `security`:
```markdown
- [ ] CHK001 ทุก secret/credential ระบุ source (env var / secret manager) + ไม่อยู่ใน vault?
- [ ] CHK002 PII fields ระบุ + masking rule + retention?
- [ ] CHK003 ทุก endpoint ที่อ่าน data ระบุ authorization rule (role × resource)?
- [ ] CHK004 Input validation ระบุ + sanitization สำหรับ SQL/XSS/SSRF?
- [ ] CHK005 Audit log ระบุ what/who/when/where ทุก mutation?
- [ ] CHK006 Rate limit + brute-force protection สำหรับ auth endpoint?
- [ ] CHK007 CSRF token / SameSite cookie ระบุ?
- [ ] CHK008 Dependency CVE scan ผ่าน?
- [ ] CHK009 Threat model อย่างน้อย 1 หน้า มี?
- [ ] CHK010 Backup + recovery procedure ระบุ?
```

จำนวน items: 10-30 ต่อ domain (custom domain → ถาม user ว่าต้องการกี่ข้อ)

## Phase 3 — Write file

Path: `docs/obsidian-vault/95-Handoff/checklists/<domain>-<scope>-<YYYY-MM-DD>.md`

หรือ append ถ้า `--append`

Frontmatter:
```yaml
---
tags: [type/checklist, domain/<domain>]
date: 2026-05-21
scope: feature:<slug> | project
domain: ux
generated_by: /bda-checklist
items_total: 10
items_passed: 0
items_failed: 0
items_pending: 10
status: in-review                # in-review | passed | blocked
---
```

## Phase 4 — Review mode (`/bda-checklist review`)

อ่าน checklist ที่ user mark `[X]` แล้ว → สรุป:

```markdown
## Review Summary — ux-FEAT-Checkout-2026-05-21

- **Total:** 10
- **Passed [X]:** 7
- **Failed [N]:** 1 — CHK004 "Copy ทั้งหมดเป็นภาษาที่กำหนด" (user marked failed)
- **Pending [ ]:** 2 — CHK008, CHK010

**Blocking issues:**
- CHK004 → /bda-doc copy-guide หรือแก้ใน PRD copy section
- CHK008, CHK010 → ตอบใน PR review

**Next:** กลับมารัน /bda-checklist review หลังแก้
```

## Phase 5 — Integration ตับ /bda-verify

`/bda-verify` ตรวจ checklist:
- ถ้ามี `domain` checklist ใน scope → required ทุกข้อ pass (`[X]`)
- ถ้ามี [ ] หรือ [N] → block handoff ออก WARNING

`/bda-implement` ตรวจ checklist:
- ถ้า status ของ plan == approved แต่ checklist `status: in-review` → ถาม "ดำเนินต่อโดย checklist ยังไม่ผ่านครบ?"

## Output (5 หัวข้อบังคับ)

1. **BDA Standard files used** — `standards/STANDARD.md`, `standards/checklists/` (process), `templates/checklist.md` (new format)
2. **Pipeline trace** — Understand (Phase 0/1) → Plan (Phase 2 generate) → Execute (Phase 3 write) → Verify (Phase 4 review) → Handoff (link to plan/feature)
3. **Commands run** — Read scope, Write checklist file
4. **Verification / Evidence** — checklist path + items count + scope
5. **Limitations / Risks / Next steps** — items pending = unresolved spec quality risk

## ห้าม

- ห้าม generate item ที่ทดสอบ implementation (เช่น "POST /api/checkouts returns 201") — checklist เป็น spec-quality test เท่านั้น
- ห้ามถ้าทำให้ checklist > 30 items ใน domain เดียว — แตกเป็น sub-checklist
- ห้าม mark item เป็น `[X]` แทน user (user ต้องตอบเอง)
- ห้ามแก้ source spec ใน checklist process — ใช้ /bda-doc หรือ /bda-clarify
- ห้าม block /bda-implement automatically — แค่ WARN ถ้า checklist ไม่ผ่าน
