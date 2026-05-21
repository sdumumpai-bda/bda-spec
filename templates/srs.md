<!--
═══════════════════════════════════════════════════════════════════════════════
  Template: SRS (Software Requirements Specification)
═══════════════════════════════════════════════════════════════════════════════
  ใช้กับคำสั่ง: /bda-new (post-PRD), /bda-doc srs
  Override ของ: standards/templates/srs.md
  Lookup chain : .bda-spec/local/templates/srs.md  →  templates/srs.md  →  standards/templates/srs.md
  Adopted patterns (spec-kit):
    • Functional Requirements เป็น FR-### numbered + linked back to US# from PRD
    • Each FR มี: priority (P1/P2/P3) + source-user-story + acceptance (Given/When/Then) + dependencies
    • NFR-### numbered + measurable threshold
    • Clarifications section (เติมโดย /bda-clarify)
  /bda-analyze จะอ่าน FR-### + map ไป plan T### + test plan items (Coverage Summary Table)
═══════════════════════════════════════════════════════════════════════════════
-->

---
tags: [type/srs]
status: draft                 # draft | review | approved | superseded
version: 0.1.0
date: <YYYY-MM-DD>
prd: "[[PRD-<slug>]]"
related_features:
  - "[[FEAT-<slug>]]"
related_functions:
  - "[[FN-Web-<slug>]]"
  - "[[FN-API-<slug>]]"
---

# SRS-<slug> — <Product / Feature Name>

<!-- Tip: SRS = "system contract" — รายละเอียดที่ PRD ไม่มี (FR/NFR/data/integration); เก็บ user prose ที่ PRD เท่านั้น -->

## 1. System Overview

<!-- Tip: 1 paragraph อธิบาย system context — ใครใช้, ทำอะไร, ต่อกับอะไร — ไม่เกิน 5 บรรทัด -->

Library Book Tracker เป็น web application (Next.js + REST API) สำหรับห้องสมุดมหาวิทยาลัย รองรับ user 3 role (Member, Librarian, Admin) และทำงาน checkout/checkin/search/overdue management โดยมี Postgres เป็น data store เดียว ระบบติดต่อ external SMTP สำหรับส่ง email reminder และ barcode scanner (HID keyboard input) ที่หน้าเคาน์เตอร์

## 2. Scope

<!-- Tip: ดึงจาก PRD § Goals/Non-goals — แต่ในมุม system, ไม่ใช่ user outcome -->

**In scope:**
- Web UI (responsive, ไทย)
- REST API (JSON, JWT auth)
- Email notification (SMTP)
- Postgres database + migration

**Out of scope:**
- Mobile native app
- E-book reader
- Payment gateway
- Real-time push notification

## 3. Functional Requirements (FR-###)

<!-- Tip: ทุก FR ต้อง: -->
<!-- • id (FR-001..) -->
<!-- • priority (P1/P2/P3 ตรงกับ user story ที่ link) -->
<!-- • source-user-story (US# จาก PRD) -->
<!-- • acceptance เป็น Given/When/Then (≥ 1 scenario) -->
<!-- • dependencies (FR อื่น/external system) -->
<!-- ห้ามเขียน FR ที่ไม่มี acceptance — /bda-analyze จะ flag เป็น underspecification -->

### FR-001 — Member checkout หนังสือ

- **Priority**: P1
- **Source user story**: US1 (PRD-library-book-tracker)
- **Description**: ระบบต้องอนุญาตให้ Librarian บันทึก loan ของ Member ต่อ Book 1 เล่มได้ในการกระทำเดียว โดย default due_date = today + 14 calendar days
- **Inputs**: `member_id` (UUID), `book_id` (UUID), `librarian_id` (จาก session)
- **Outputs**: `loan_id` (UUID) + `due_date` (ISO 8601)
- **Pre-conditions**:
  - Member ต้อง `status = active`
  - Book ต้อง `status = available`
  - Member มี active loan < 5 (business rule)
- **Post-conditions**:
  - Loan record `status = open`
  - Book `status = borrowed`
  - Audit log entry สร้างขึ้น
- **Acceptance** (Given/When/Then):
  1. **Given** Member มี active loan 2 เล่ม + Book A available, **When** Librarian กด checkout Book A ให้ Member, **Then** ระบบสร้าง loan + แสดง due_date + เปลี่ยน Book A เป็น borrowed
  2. **Given** Member มี active loan 5 เล่ม, **When** Librarian กด checkout Book A, **Then** ระบบ reject พร้อม error "loan limit exceeded"
  3. **Given** Book A `status = borrowed`, **When** Librarian กด checkout Book A, **Then** ระบบ reject พร้อม error "book not available"
- **Error handling**: 409 Conflict ถ้า race condition (2 librarian checkout เล่มเดียวกัน) — ใช้ DB unique constraint บน `(book_id, status=open)`
- **Dependencies**: FR-010 (Auth), FR-020 (Catalog read), DB schema (book.status, loan)

---

### FR-002 — Member ค้นหาหนังสือ

- **Priority**: P2
- **Source user story**: US2
- **Description**: ระบบต้องให้ Member ค้นหาหนังสือด้วย keyword (title, author, ISBN) ผ่าน public endpoint โดยไม่ต้อง login
- **Inputs**: `q` (string, 1–100 chars), `page` (int, default 1), `limit` (int, default 20, max 50)
- **Outputs**: list of `{book_id, title, author, status, cover_url}` + total count + pagination
- **Pre-conditions**: ไม่ต้อง auth
- **Post-conditions**: search query บันทึกใน analytics log (anonymous)
- **Acceptance**:
  1. **Given** Member ไม่ได้ login, **When** GET `/api/search?q=harry`, **Then** ระบบ return list books ที่ title/author match "harry" + แสดง status ปัจจุบัน
  2. **Given** ไม่พบหนังสือ, **When** search `q=xyz`, **Then** return `{items: [], total: 0}` (HTTP 200) ไม่ใช่ 404
  3. **Given** `q` length = 0, **When** search, **Then** return HTTP 400 + message "query required"
- **Error handling**: 400 validation, 500 ถ้า DB error
- **Dependencies**: DB index `book(title gin_trgm, author gin_trgm)`

---

### FR-003 — Librarian ดู overdue list

- **Priority**: P3
- **Source user story**: US3
- **Description**: ระบบต้องแสดง list loan ที่ `due_date < today` และ `returned_at IS NULL` พร้อม contact info ของ member ให้ Librarian ดู
- **Inputs**: `branch_id` (optional, default = ของ librarian), `sort` (default `due_date asc`)
- **Outputs**: list of `{loan_id, member_name, member_email, book_title, due_date, days_overdue}`
- **Pre-conditions**: User ต้องมี role `librarian` หรือ `admin`
- **Post-conditions**: view event บันทึก audit
- **Acceptance**:
  1. **Given** มี loan 3 รายการเกินกำหนด, **When** Librarian เปิด `/overdue`, **Then** เห็น 3 รายการเรียงตาม due_date จากเก่าสุด
  2. **Given** ไม่มี loan เกินกำหนด, **When** เปิด `/overdue`, **Then** เห็น empty state "ไม่มีหนังสือเกินกำหนด"
  3. **Given** Member role login, **When** เปิด `/overdue`, **Then** HTTP 403
- **Dependencies**: FR-010 (Auth + RBAC), FR-001 (loan record)

---

### FR-004 — Librarian ส่ง email reminder

- **Priority**: P3
- **Source user story**: US3
- **Description**: ระบบต้องส่ง email reminder ไปยัง member ของ loan ที่เกินกำหนด โดย Librarian กดปุ่มเดียวยิงทีละคน (ไม่ batch ใน MVP)
- **Inputs**: `loan_id`
- **Outputs**: `reminder_id` + status `sent | failed`
- **Acceptance**:
  1. **Given** loan เกินกำหนด + member มี email, **When** Librarian กด Send Reminder, **Then** ระบบส่ง email + บันทึก reminder record + แสดง toast "ส่งสำเร็จ"
  2. **Given** SMTP timeout, **When** Send Reminder, **Then** บันทึก `status=failed` + แสดง error + ให้ retry ได้
- **Dependencies**: FR-003, external SMTP, NFR-003 (email delivery)

---

### FR-010 — Authentication + RBAC

- **Priority**: P1 (foundational — blocks ทุก story)
- **Source user story**: implicit (cross-cutting)
- **Description**: ระบบใช้ JWT-based auth + RBAC ตาม role (`member`, `librarian`, `admin`); ดู `REF-AuthorizationMatrix.md`
- **Acceptance**:
  1. **Given** valid credentials, **When** POST `/api/auth/login`, **Then** ระบบ return JWT (15 min) + refresh token (7 days)
  2. **Given** expired JWT, **When** call protected endpoint, **Then** HTTP 401 + client refresh flow
  3. **Given** member role, **When** call admin-only endpoint, **Then** HTTP 403
- **Dependencies**: NFR-002 (Security), `REF-AuthorizationMatrix.md`

---

<!-- เพิ่ม FR-### ตามจำนวน user story + functional area; ใช้ block 10s (FR-001..009 = user stories; FR-010..019 = cross-cutting auth/security; FR-020..029 = catalog; FR-030..039 = reporting) -->

## 4. Non-functional Requirements (NFR-###)

<!-- Tip: ทุก NFR ต้องมี measurable threshold — ห้าม "fast", "secure" ลอยๆ -->

### NFR-001 — Performance

- **Threshold**: API p95 latency ≤ 800 ms (search), ≤ 500 ms (checkout) under 200 concurrent users
- **Measurement**: k6 load test + Datadog APM trace
- **Linked SC**: SC-002

### NFR-002 — Security

- **Threshold**:
  - Password hashed ด้วย bcrypt cost ≥ 12
  - JWT signed ด้วย RS256 (asymmetric)
  - ทุก write endpoint ต้องมี CSRF token (สำหรับ web)
  - PII (email, phone) encrypt at rest (Postgres pgcrypto)
- **Measurement**: `/bda-secure` pre-flight + OWASP ZAP scan ก่อน launch

### NFR-003 — Reliability / Availability

- **Threshold**: 99.5% uptime (≤ 3.6 hours downtime/month)
- **Measurement**: uptime monitor (UptimeRobot) + monthly SLA report

### NFR-004 — Accessibility

- **Threshold**: WCAG 2.1 AA — contrast ≥ 4.5:1, keyboard navigation 100%, screen reader tested ใน NVDA + VoiceOver
- **Measurement**: axe-core CI check + manual audit checklist `90-TestPlan/a11y-checklist.md`

### NFR-005 — i18n / Localization

- **Threshold**: UI ไทย 100%, admin report อังกฤษ option; date format `dd/MM/yyyy` (ไทย), `yyyy-MM-dd` (ISO ใน export)
- **Measurement**: locale test + manual review

### NFR-006 — Data Retention (PDPA)

- **Threshold**: เก็บ member PII 7 ปีหลัง last activity → anonymize; audit log 5 ปี
- **Measurement**: cron job + quarterly audit

## 5. Data Model (High-level)

<!-- Tip: ไม่ลงรายละเอียด column ทั้งหมด — เก็บ entity + relationship; รายละเอียดอยู่ใน data-model.md -->

- **Member** (id, name, email, phone_encrypted, status, created_at) — 1:N → Loan
- **Book** (id, title, author, isbn, status, cover_url) — 1:N → Loan
- **Loan** (id, member_id, book_id, librarian_id, loaned_at, due_date, returned_at, status) — N:1 → Member, N:1 → Book
- **User** (id, email, password_hash, role, branch_id) — RBAC subject
- **Reminder** (id, loan_id, sent_at, status, error_message)
- **AuditLog** (id, actor_id, action, target_type, target_id, payload_json, created_at)

## 6. External Integrations

<!-- Tip: ทุก integration ระบุ protocol + auth + retry policy + ใครรับผิดชอบ -->

- **SMTP (SendGrid)** — TLS 587, API key auth, retry 3x exponential, owner: ops team
- **Barcode scanner (HID)** — keyboard emulation, no driver needed
- **(future)** SMS gateway — out of MVP

## 7. UX Flows

<!-- Tip: link ไป FLOW-* docs; ไม่วาดที่นี่ -->

- "[[FLOW-checkout]]"
- "[[FLOW-search]]"
- "[[FLOW-overdue-reminder]]"

## 8. Dependencies (system-level)

- Postgres 15+ (DB)
- Node.js 20+ runtime (API + Web)
- SendGrid account + verified domain
- BDA Design System v1.x (ใน `docs/obsidian-vault/70-Reference/DesignSystem/`)

## 9. Out of Scope

- Mobile native (เฟส 2)
- E-book streaming
- Payment / fine collection
- Multi-tenancy (1 ห้องสมุด / 1 instance ใน MVP)

## 10. Acceptance for Release

<!-- Tip: ตอบ "เมื่อไรถึงปล่อย version นี้ได้" — link ไป /bda-verify checklist -->

- [ ] ทุก FR P1+P2 implement + acceptance Given/When/Then pass
- [ ] ทุก NFR ผ่าน threshold (มี evidence)
- [ ] SC-001..005 (PRD) วัดผลได้ + reach target
- [ ] /bda-secure ผ่าน (no secret/PII leak)
- [ ] /bda-verify ออก handoff report + approved

## 11. Clarifications

<!-- Tip: section นี้ถูกเติมโดย `/bda-clarify` — ห้ามแก้ด้วยมือ -->

_ยังไม่มี clarification session_

## 12. Pipeline trace

- **Understand**: PRD review + cross-check `REF-TechStack.md` + `REF-AuthorizationMatrix.md`
- **Plan**: SRS draft → /bda-clarify (อาจมี) → review → approved
- **Execute**: FEAT + FN + plan files (link path)
- **Verify**: FR acceptance + NFR threshold measured (link evidence)
- **Handoff**: linked ใน HOR-* (handoff report)
