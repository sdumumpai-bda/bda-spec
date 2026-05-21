<!--
═══════════════════════════════════════════════════════════════════════════════
  Template: PLAN (Implementation Plan)
═══════════════════════════════════════════════════════════════════════════════
  ใช้กับคำสั่ง: /bda-plan (สร้าง), /bda-plan --revise (แก้), /bda-implement (อ่าน + execute)
  Override ของ: standards/templates/plan.md
  Lookup chain : .bda-spec/local/templates/plan.md  →  templates/plan.md  →  standards/templates/plan.md
  Adopted patterns (spec-kit):
    • Constitution Check เป็น GATE ก่อนเริ่ม implement — PASS / FAIL / JUSTIFIED
    • Complexity Tracking — เติมเมื่อ Constitution Check มี JUSTIFIED items
    • Implementation Steps เป็น **checkbox task** `T### [P] [USx] description — file:path`
       - [P] = parallelizable (different files, no dep)
       - [USx] = user story ที่ task นี้ realize (US1/US2/US3)
       - แต่ละ task ระบุ file path ตรงๆ
    • Test Plan แยกเป็น **per-story Independent Test** + integration
  /bda-analyze จะอ่าน T### + map กับ FR-### ใน Coverage Summary Table
═══════════════════════════════════════════════════════════════════════════════
-->

---
tags: [type/plan]
date: <YYYY-MM-DD HH:mm>
title: <one-line task title>
status: planning              # planning | approved | in-progress | done | abandoned
submodule_target: <api | web | mobile | docs | all>
subagent_target: <backend | frontend | mobile | docs | design | all>
related_feature: "[[FEAT-<slug>]]"
related_docs:
  - "[[PRD-<slug>]]"
  - "[[SRS-<slug>]]"
  - "[[FN-Web-<slug>]]"
  - "[[FN-API-<slug>]]"
  - "[[REF-TechStack]]"
  - "[[REF-AuthorizationMatrix]]"
covers_user_stories: [US1, US2]       # which US# จาก feature นี้ plan ครอบคลุม
covers_frs: [FR-001, FR-005, FR-010]  # FR-### ที่ task ครอบคลุม
estimate_hours: <number>
risk_level: <low | medium | high>     # ใช้ตัดสิน reviewer + smoke test depth
---

# <Task title>

<!-- Tip: slug ของ filename = kebab-case ≤ 5 คำ; เช่น `add-checkout-mvp.md` -->

## A. Vault Context Read

<!-- Tip: list ทุก doc ที่อ่านระหว่าง /bda-plan Phase 1 — เป็นหลักฐานว่า "vault-first" จริง -->
<!-- ทุก doc ในรายการนี้ต้องอ่านเต็ม ไม่ใช่ skim -->

- [x] `docs/00-Index/IMPLEMENTATION-STATUS.md`
- [x] `docs/10-PRD/PRD-library-book-tracker.md` (section: User Stories US1, US2)
- [x] `docs/20-Features/FEAT-checkout.md` (covers FR-001, FR-005, FR-010)
- [x] `docs/40-Functions/FN-Web-Lib-Checkout.md`
- [x] `docs/40-Functions/FN-API-Loan-Create.md`
- [x] `docs/70-Reference/REF-TechStack.md`
- [x] `docs/70-Reference/REF-AuthorizationMatrix.md`
- [x] `docs/70-Reference/DesignSystem/DS-Tokens.md`
- [x] `docs/70-Reference/DesignSystem/DS-Components.md`
- [ ] `docs/60-Flows/FLOW-checkout-counter.md` _ยังไม่มี — flag ใน Doc Gaps_

## B. Task

<!-- Tip: 1 paragraph; ตอบ what + why ในประโยคแรก -->

Implement Member checkout flow (US1 + US2 จาก FEAT-checkout): librarian ที่เคาน์เตอร์ scan member barcode + book barcode → กด confirm → ระบบสร้าง loan record + อัปเดต book status atomically + แสดง due_date; รวม member loan history page เพื่อให้ member ดู loan ปัจจุบันของตัวเอง

## C. Goals / Non-goals

**Goals:**
- [ ] US1 ทำงานได้ end-to-end (FR-001 acceptance Given/When/Then pass)
- [ ] US2 ทำงานได้ end-to-end (FR-005 pass)
- [ ] Test coverage ≥ 80% สำหรับ loan service
- [ ] Performance: checkout p95 ≤ 500 ms ใน load test 200 concurrent

**Non-goals:**
- US3 (override loan limit) — ทำใน plan ถัดไป
- Overdue reminder (FR-003/004) — แยก feature
- Mobile UI — phase 2

## D. Affected Files

<!-- Tip: list **ทุกไฟล์ที่ต้องสร้าง/แก้** พร้อม path เต็ม + 1-line summary -->

- `apps/api/prisma/migrations/202605201430_add_loan_table.sql` — สร้างตาราง loan + unique partial index
- `apps/api/src/models/loan.ts` — Loan entity + Zod schema
- `apps/api/src/services/loan-service.ts` — business logic + transaction
- `apps/api/src/routes/loans.ts` — POST `/api/loans`, GET `/api/members/:id/loans`
- `apps/api/tests/unit/loan-service.test.ts` — unit tests
- `apps/api/tests/integration/loans.test.ts` — integration tests
- `apps/web/src/pages/librarian/checkout.tsx` — checkout UI
- `apps/web/src/pages/member/my-loans.tsx` — loan history UI
- `apps/web/src/components/CheckoutForm.tsx` — form component
- `apps/web/src/lib/api-client.ts` — เพิ่ม loan methods
- `apps/web/tests/e2e/checkout.spec.ts` — Playwright e2e

## E. Constitution Check

<!-- Tip: GATE ก่อนเริ่ม implement — ต้อง PASS หรือ JUSTIFIED ทุก rule -->
<!-- ดู: standards/STANDARD.md (5-step pipeline), standards/policies/*, docs/00-Index/CONSTITUTION.md (ถ้ามี local) -->

**Source rules:**
- `standards/STANDARD.md` — 5-step pipeline + 5 mandatory output sections
- `standards/policies/no-fake-evidence.md`
- `standards/policies/source-of-truth.md`
- `standards/policies/evidence-verification.md`
- `standards/policies/working-result.md`
- `docs/00-Index/CONSTITUTION.md` _(if exists; project-specific principles)_

| # | Rule / Principle                                          | Status     | Note                                                                          |
|---|-----------------------------------------------------------|------------|-------------------------------------------------------------------------------|
| 1 | Plan/Implement แยกกัน (ห้าม /bda-plan แก้โค้ด)             | PASS       | plan file นี้ไม่แตะโค้ด                                                       |
| 2 | Vault-first (อ่าน docs/ ก่อน plan)                         | PASS       | ดู section A — 9 docs อ่านครบ                                                  |
| 3 | No fake evidence (ห้ามแต่ง result)                         | PASS       | ใช้ /bda-test + /bda-verify จริง                                              |
| 4 | Single source of truth (FR-### ลิงก์ใน SRS เท่านั้น)        | PASS       | section H ใช้ FR-### จาก SRS-library-book-tracker                              |
| 5 | Test before claim done                                    | PASS       | section J ระบุ test ครบทุก story                                              |
| 6 | Design System compliance (frontend ใช้ tokens/components)  | PASS       | section I ลิสต์ tokens + components จาก DS                                    |
| 7 | RBAC enforcement (ทุก endpoint check role)                 | PASS       | T010 [US1] add middleware check                                                |
| 8 | PDPA — encrypt PII at rest                                 | JUSTIFIED  | dependency NFR-002; ต้อง enable pgcrypto + migrate phone column — ทำใน plan แยก |
| 9 | A11y WCAG AA (frontend)                                    | PASS       | section I มี axe-core CI gate                                                  |

**Outcome:** PASS (with 1 JUSTIFIED — ดู Complexity Tracking section F)

## F. Complexity Tracking

<!-- Tip: เติมเฉพาะเมื่อ Constitution Check มี JUSTIFIED items; ห้ามมี JUSTIFIED โดยไม่มีเหตุผลใน table นี้ -->

| Violation / Deviation                              | Why Needed                                                                            | Simpler Alternative Rejected Because                                       |
|----------------------------------------------------|---------------------------------------------------------------------------------------|----------------------------------------------------------------------------|
| PDPA encrypt PII at rest (เลื่อนเป็น plan ถัดไป)    | scope plan นี้คือ checkout flow; PII migration ใหญ่ + ต้อง downtime → ทำแยก plan dedicated | ทำพร้อม checkout = scope creep + risk migration fail ทำ checkout เสีย       |

## G. Doc Gaps Found

<!-- Tip: ระหว่าง Vault read ถ้าเจอ inconsistent/missing → list ที่นี่; /bda-implement จะเรียก docs subagent fix ก่อน -->

- **FLOW-checkout-counter.md** ยังไม่มี (FEAT-checkout § UX Flows อ้างถึง) → /bda-doc flow ก่อน /bda-implement
- **FR-005 (loan history)** ใน SRS ไม่มี Given/When/Then ครบ — ต้องเติม scenario "empty state" และ "pagination > 50 items"

## H. Implementation Steps

<!-- Tip: -->
<!-- รูปแบบ task: `- [ ] T### [P?] [USx] description — file:path` -->
<!-- [P] = parallelizable (file ต่าง + ไม่ขึ้นกับ task อื่น); ไม่มี [P] = sequential -->
<!-- [USx] = user story (US1/US2/US3) ที่ task นี้ realize; ถ้า cross-cutting/foundation ใส่ [FND] -->
<!-- numbering: T001 = ลำดับใน plan นี้ (ไม่ใช่ทั้ง project) — /bda-analyze เทียบ FR ↔ T### -->

### Phase 1 — Setup (Shared infrastructure)

- [ ] T001 [P] [FND] เพิ่ม Prisma model `Loan` ใน schema — file: `apps/api/prisma/schema.prisma`
- [ ] T002 [FND] สร้าง migration + unique partial index (`WHERE status = 'open'`) — file: `apps/api/prisma/migrations/202605201430_add_loan_table.sql` (depends on T001)
- [ ] T003 [P] [FND] เพิ่ม Zod schema `LoanSchema` + `CreateLoanInput` — file: `apps/api/src/models/loan.ts`

**Checkpoint:** DB schema ready + types available — ทุก user story เริ่ม implement ได้

### Phase 2 — User Story 1 (Checkout) — P1 / MVP

- [ ] T010 [P] [US1] เขียน unit test สำหรับ `LoanService.create()` (3 scenario จาก FR-001 acceptance) — file: `apps/api/tests/unit/loan-service.test.ts`
- [ ] T011 [US1] Implement `LoanService.create()` ใน transaction (loan insert + book status update) — file: `apps/api/src/services/loan-service.ts` (depends on T002, T003)
- [ ] T012 [US1] เพิ่ม route POST `/api/loans` + RBAC middleware (librarian only) — file: `apps/api/src/routes/loans.ts` (depends on T011)
- [ ] T013 [P] [US1] เขียน integration test ครอบคลุม 4 acceptance scenario — file: `apps/api/tests/integration/loans.test.ts`
- [ ] T014 [US1] สร้าง `CheckoutForm` component (member input → book input → confirm) ตาม DS — file: `apps/web/src/components/CheckoutForm.tsx`
- [ ] T015 [US1] สร้างหน้า `/librarian/checkout` ใช้ `CheckoutForm` + Toast on success/error — file: `apps/web/src/pages/librarian/checkout.tsx` (depends on T014)
- [ ] T016 [US1] เพิ่ม `loans.create()` ใน api-client — file: `apps/web/src/lib/api-client.ts`
- [ ] T017 [P] [US1] เขียน Playwright e2e ครอบคลุม "happy path + loan limit reject + book unavailable reject" — file: `apps/web/tests/e2e/checkout.spec.ts`

**Checkpoint US1:** Librarian login → checkout 1 เล่ม → loan record + book status update + due_date แสดง — Independent Test pass; standalone MVP ใช้งานได้

### Phase 3 — User Story 2 (Member loan history) — P2

- [ ] T020 [P] [US2] เขียน unit test `LoanService.listByMember()` (pagination + empty state) — file: `apps/api/tests/unit/loan-service.test.ts`
- [ ] T021 [US2] Implement `LoanService.listByMember(member_id, page, limit)` — file: `apps/api/src/services/loan-service.ts` (depends on T011)
- [ ] T022 [US2] เพิ่ม route GET `/api/members/:id/loans` + RBAC (member ดูได้แค่ของตัวเอง / librarian ดูได้ทุกคน) — file: `apps/api/src/routes/loans.ts`
- [ ] T023 [US2] สร้างหน้า `/member/my-loans` ใช้ `Card` + `Badge` + `Pagination` — file: `apps/web/src/pages/member/my-loans.tsx`
- [ ] T024 [P] [US2] เพิ่ม `loans.listByMember()` ใน api-client — file: `apps/web/src/lib/api-client.ts`
- [ ] T025 [P] [US2] เพิ่ม Playwright e2e: empty state + with 5 loans + pagination — file: `apps/web/tests/e2e/my-loans.spec.ts`

**Checkpoint US2:** Member login → เปิด `/my-loans` → เห็น loan ตัวเอง + pagination ทำงาน — Independent Test pass

### Phase 4 — Polish / Cross-cutting

- [ ] T030 [P] [FND] เพิ่ม structured logging ใน loan-service (event: `loan.created`, `loan.create_failed`) — file: `apps/api/src/services/loan-service.ts`
- [ ] T031 [P] [FND] เพิ่ม Datadog APM trace + custom metric `loan.checkout.duration_ms` — file: `apps/api/src/services/loan-service.ts`
- [ ] T032 [FND] รัน load test (k6) — 200 concurrent → confirm p95 ≤ 500 ms — evidence: `docs/90-TestPlan/evidence/loan-load-test-<date>.json`
- [ ] T033 [FND] axe-core CI gate ผ่านทั้ง 2 หน้าใหม่ — evidence: CI run URL

## I. Design System Compliance

<!-- Tip: ทำเฉพาะเมื่อ subagent_target = frontend หรือ mobile -->
<!-- ห้าม ad-hoc styling — ถ้าต้อง component ใหม่ → run /bda-design ก่อน /bda-implement -->

- [ ] ใช้ `color.primary`, `color.danger`, `color.text.muted` (no hardcoded hex)
- [ ] ใช้ `space.4`, `space.6` (no hardcoded px)
- [ ] ใช้ component: `Button`, `Input`, `Toast`, `Modal`, `Card`, `Badge`, `EmptyState`, `Pagination`
- [ ] **New components needed:** _none_ (ถ้ามี → list ใน "Design Additions" + /bda-design ก่อน)
- [ ] WCAG AA contrast pass ทุก state (default/hover/focus/disabled)
- [ ] Keyboard nav: Tab → CheckoutForm fields → Confirm button (focus visible)
- [ ] Screen reader: `aria-label` บน barcode input + result toast `aria-live="polite"`

### Design Additions (ถ้ามี)

_ไม่มี — ใช้ component ปัจจุบันครบ_

## J. Test Plan

<!-- Tip: แยกเป็น **per-story Independent Test** + integration + cross-cutting; link ไป TP-* ใน 90-TestPlan -->

### Per-story Independent Test

**US1 — Checkout** ([[TP-FEAT-checkout#US1]])
- [ ] Unit: `LoanService.create()` — 3 scenarios (happy / loan limit / book unavailable)
- [ ] Integration: POST `/api/loans` — 4 scenarios (รวม race condition test)
- [ ] E2E (Playwright): librarian login → scan → confirm → see due_date
- [ ] Manual: barcode scanner real device (HID input ≤ 50ms buffer)

**US2 — Loan history** ([[TP-FEAT-checkout#US2]])
- [ ] Unit: `LoanService.listByMember()` — pagination + empty
- [ ] Integration: GET `/api/members/:id/loans` — RBAC (member ↔ librarian)
- [ ] E2E: member login → `/my-loans` → see list + pagination
- [ ] A11y: NVDA + VoiceOver navigation

### Cross-cutting / Non-functional

- [ ] Load test: k6 → 200 concurrent checkout, p95 ≤ 500 ms (NFR-001)
- [ ] Security: /bda-secure — no secret/PII leak ใน log
- [ ] A11y: axe-core ผ่าน 0 violation บน 2 หน้าใหม่

## K. Verification Checklist

<!-- Tip: /bda-verify จะอ่าน checklist นี้แล้วเช็คทีละข้อ + รวบ evidence path -->

- [ ] ทุก task ใน section H เป็น `[x]`
- [ ] ทุก acceptance Given/When/Then ของ US1 + US2 pass (link test result)
- [ ] Test coverage ≥ 80% สำหรับ `loan-service.ts` (link coverage report)
- [ ] Load test ผ่าน NFR-001 threshold (link k6 report)
- [ ] /bda-secure ผ่าน (link report)
- [ ] axe-core 0 violation (link CI run)
- [ ] /bda-test --since <ref> ผ่านทั้งหมด
- [ ] Doc updated: FEAT-checkout § Implementation Status, IMPLEMENTATION-STATUS.md
- [ ] Coverage Summary (จาก /bda-analyze): FR-001, FR-005, FR-010 → mapped กับ T### ของ plan นี้

## L. Risks / Open Questions

- **R1** — Race condition (2 librarian → book เดียวกัน) → mitigation: DB unique partial index + integration test concurrent
- **R2** — Barcode scanner buffer timing → mitigation: 50ms debounce window + manual real-device test
- **R3** — Performance ของ `listByMember` ถ้า loan > 1000 รายการ/member → mitigation: index + cursor pagination (ไม่ใช่ offset)
- **OQ1** — Member ดู loan ของ "ตัวเอง" — ต้อง check ทั้ง JWT user_id + URL `:id` match? → ปัจจุบัน plan ใช้ JWT-only (ดู T022) — ยืนยัน?

## M. Approvals

| Role             | Name        | Status              | Date       |
|------------------|-------------|---------------------|------------|
| Requested by     | <user>      | requested           | YYYY-MM-DD |
| Tech reviewer    | <reviewer>  | pending             | —          |
| Product owner    | <owner>     | pending             | —          |
| Approved         |             | _set status above_  | —          |

> เมื่อทุก row = approved → แก้ frontmatter `status: approved` → /bda-implement พร้อมรัน

---

## N. Implementation Result (เติมหลัง /bda-implement)

<!-- Tip: /bda-implement จะมาเติม section นี้หลัง execute เสร็จ — ห้ามเติมตอน /bda-plan -->

- Files changed: <list with commit hash>
- Tests added: <count + path>
- Test result: <pass/fail + coverage %>
- Subagent used: <backend / frontend / docs / ...>
- Time taken: <duration>
- Evidence path: `docs/90-TestPlan/evidence/<plan-slug>/`
- Handoff: [[HOR-<slug>]]

## O. Pipeline trace

- **Understand**: Phase 1 vault read (section A — 9 docs)
- **Plan**: /bda-plan สร้าง file นี้ + (optional) /bda-clarify
- **Execute**: /bda-implement spawn subagent ตาม `subagent_target`
- **Verify**: /bda-test + /bda-verify ใช้ section K
- **Handoff**: /bda-verify ออก HOR + update IMPLEMENTATION-STATUS

## P. BDA Standard Output Sections

<!-- Tip: 5 mandatory sections — เติมโดย /bda-implement หลังรัน; ห้ามเติมตอน /bda-plan -->

1. **BDA Standard files used** — _เติมหลัง execute_
2. **Pipeline trace** — ดู section O (อัปเดตหลัง execute)
3. **Commands run** — _เติมหลัง execute_
4. **Verification / Evidence** — link ไป section K + evidence paths
5. **Limitations / Risks / Next steps** — ดู section L + next plan suggestion
