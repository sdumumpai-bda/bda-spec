<!--
═══════════════════════════════════════════════════════════════════════════════
  Template: PRD (Product Requirements Document)
═══════════════════════════════════════════════════════════════════════════════
  ใช้กับคำสั่ง: /bda-new (brainstorm/import-prd), /bda-doc prd
  Override ของ: standards/templates/prd.md
  Lookup chain : .bda-spec/local/templates/prd.md  →  templates/prd.md  →  standards/templates/prd.md
  Adopted patterns (spec-kit):
    • User Stories แบบ prioritized P1/P2/P3 + Independent Test + Given/When/Then
    • Success Criteria เป็น SC-### numbered, measurable, technology-agnostic
    • Clarifications log section (เติมโดย /bda-clarify)
  เก็บ ID เป็นอังกฤษ (PRD-/US1/SC-001) — เนื้อหา prose เป็นไทยได้
═══════════════════════════════════════════════════════════════════════════════
-->

---
tags: [type/prd]
status: draft                 # draft | review | approved | superseded
version: 0.1.0
date: <YYYY-MM-DD>
authors: [<user>]
related_docs:
  - "[[SRS-<slug>]]"
  - "[[FEAT-<slug>]]"
  - "[[REF-TechStack]]"
---

# PRD-<slug> — <Product / Feature Name>

<!-- Tip: ใช้ slug แบบ kebab-case สั้นๆ (≤ 5 คำ) เช่น `library-book-tracker` — ต้องตรงกับ filename -->

## 1. Vision

<!-- Tip: 2–3 ประโยค ตอบ "อีก 12 เดือนข้างหน้า ระบบนี้จะเปลี่ยนชีวิตใครยังไง" — ห้าม jargon -->

ทำให้สมาชิกห้องสมุดยืม-คืนหนังสือได้เร็วกว่าเดิม 3 เท่า และให้บรรณารักษ์เห็นสถานะหนังสือทุกเล่มแบบ real-time โดยไม่ต้องเช็คในหลายระบบ

## 2. Problem

<!-- Tip: ใคร เจอปัญหาอะไร ตอนนี้เขา workaround ยังไง ทำไมถึงเจ็บปวด -->

บรรณารักษ์ใช้เวลาเฉลี่ย 4 นาที/เล่ม ในการ checkout เพราะต้องเช็คสมาชิก + เช็คหนังสือ + บันทึก in/out ใน Excel + ยืนยันด้วยลายเซ็นกระดาษ สมาชิกร้องเรียนเรื่องคิวยาวเฉลี่ย 12 ครั้ง/สัปดาห์ และ Excel มี conflict ตอนหลายคนแก้พร้อมกัน 1–2 ครั้ง/วัน

## 3. Personas

<!-- Tip: 2–4 personas พอ; แต่ละตัวมี role + context + pain เฉพาะ -->

- **Member (สมาชิก)** — ผู้ใช้ทั่วไปที่ยืมหนังสือเดือนละ 2–5 เล่ม ต้องการรู้ว่าหนังสือเล่มไหนว่าง/จองได้ และยืม-คืนเร็ว
- **Librarian (บรรณารักษ์)** — เจ้าหน้าที่หน้าเคาน์เตอร์ ต้องการ tool เดียวที่ทำ checkout/checkin/search/audit ได้ครบ
- **Admin** — หัวหน้าห้องสมุด ต้องการ dashboard สถิติยืมคืน + จัดการ catalog + จัดการสิทธิ์ผู้ใช้

## 4. Goals

<!-- Tip: เขียนเป็น outcome ที่ user ได้รับ (ไม่ใช่ feature list); 3–6 ข้อ -->

- ลดเวลา checkout เฉลี่ยเหลือ ≤ 90 วินาที/เล่ม
- ให้สมาชิกค้นหา + จอง + ดูสถานะหนังสือออนไลน์ได้ 24/7
- ให้บรรณารักษ์เห็น overdue list + ส่ง reminder ได้ในหน้าเดียว
- ให้ admin export รายงานยืม-คืนรายเดือนได้ในคลิกเดียว

## 5. Non-goals

<!-- Tip: ระบุชัดว่า "ไม่ทำใน scope นี้" เพื่อกัน scope creep — โยงไปอนาคตได้ -->

- ระบบจ่ายค่าปรับออนไลน์ (เฟส 2)
- Mobile app (เฟส 2 — version แรก web responsive พอ)
- การอ่าน e-book ในระบบ (ไม่ใช่ scope)
- Integration กับระบบบัญชีของมหาวิทยาลัย (พิจารณาภายหลัง)

## 6. Success Metrics (SC-###)

<!-- Tip: ทุก SC ต้อง **measurable** + **technology-agnostic** + บอกวิธีวัด — spec-kit pattern -->

- **SC-001** — สมาชิก checkout สำเร็จในเวลา ≤ 90 วินาที (p95) วัดจาก server log + UI tracking
- **SC-002** — รองรับการใช้งานพร้อมกัน 200 user โดย response p95 ≤ 800 ms (load test)
- **SC-003** — 95% ของ checkout สำเร็จในการกดครั้งแรกโดยไม่ retry (UX funnel)
- **SC-004** — ลด complaint คิวยาวลง ≥ 60% ใน 3 เดือนแรกหลัง launch (survey + ticket count)
- **SC-005** — Librarian สร้างรายงาน overdue รายสัปดาห์ได้ในคลิกเดียวภายใน 5 วินาที (manual test)

## 7. User Stories Overview (Prioritized)

<!-- Tip: แต่ละ story ต้อง **Independent Test ได้** (ทำ story เดียวแล้ว user ใช้งานได้จริง) -->
<!-- รายละเอียด acceptance Given/When/Then ไปอยู่ใน SRS / FEAT (FR-###) -->

### US1 — Member checkout หนังสือ (Priority: P1) — MVP

**As a** Member **I want** ยืมหนังสือผ่าน librarian ที่เคาน์เตอร์ **so that** เอาหนังสือกลับบ้านได้โดยไม่ต้องรอนาน

**Why this priority:** core revenue/value loop — ถ้า checkout ไม่ทำงาน ระบบไม่มีค่าอะไรเลย

**Independent Test:** Librarian login → scan barcode สมาชิก → scan barcode หนังสือ → กด confirm → ระบบบันทึก loan record + แสดง due date — ทำเฉพาะ story นี้แล้วใช้งานจริงได้

---

### US2 — Member ค้นหา + ดูสถานะหนังสือ (Priority: P2)

**As a** Member **I want** ค้นหาหนังสือว่ามีในระบบไหม + ว่าง/ถูกยืมอยู่ **so that** ตัดสินใจมาเอาที่ห้องสมุดหรือไม่ก่อนเดินทาง

**Why this priority:** ลด traffic ที่เคาน์เตอร์ + เพิ่ม convenience — เสริม US1 แต่ทำงานแยกได้

**Independent Test:** เปิดหน้า /search → พิมพ์ชื่อหนังสือ → เห็นผล + สถานะ (available/borrowed/reserved) — ทำเฉพาะ story นี้ก็มีประโยชน์ standalone

---

### US3 — Librarian ดู overdue + ส่ง reminder (Priority: P3)

**As a** Librarian **I want** เห็น list หนังสือเกินกำหนดคืน + ส่ง email reminder ได้ **so that** เก็บหนังสือคืนได้ทันก่อนหายถาวร

**Why this priority:** ช่วยลด loss แต่ไม่ใช่ blocker สำหรับ launch — ทำหลัง P1/P2 ได้

**Independent Test:** Librarian login → เปิดหน้า /overdue → เห็น list + กดปุ่ม Send Reminder → ระบบส่ง email ไปสมาชิก → log ใน audit

---

## 8. Constraints

<!-- Tip: deadline, budget, tech, compliance — สิ่งที่ "ต้องทำตาม" -->

- **Deadline**: launch MVP ภายใน Q3 2026
- **Budget**: internal team only, ไม่มี vendor
- **Tech stack**: Next.js + Postgres + Prisma (ดู `REF-TechStack.md`)
- **Compliance**: PDPA — เก็บข้อมูลสมาชิกในไทย, retention 7 ปี
- **Language**: ไทย (UI) + อังกฤษ (admin reports)

## 9. Assumptions

- สมาชิกทุกคนมี email/เบอร์มือถือลงทะเบียนแล้ว
- ห้องสมุดมี barcode scanner ที่เคาน์เตอร์อยู่แล้ว
- WiFi ในห้องสมุดเสถียร (ไม่ต้องออกแบบ offline-first สำหรับ MVP)

## 10. Risks

<!-- Tip: risk → mitigation; ห้าม risk ลอยๆ ไม่มีแผนรับมือ -->

- **R1** — Excel data migration ผิดเพี้ยน → mitigation: เขียน migration script + dry-run บน staging + manual spot check 100 records
- **R2** — Librarian resist การเปลี่ยนระบบ → mitigation: training 2 ครั้ง + parallel run Excel + ระบบใหม่ 2 สัปดาห์
- **R3** — Load จาก search สูงกว่าคาด → mitigation: add Postgres index + cache top-100 query ใน Redis

## 11. Glossary

<!-- Tip: ใช้คำศัพท์ตรงกันทั้ง project — SRS/FEAT/FN อ้างกลับมาที่นี่ -->

- **Member** — สมาชิกห้องสมุด (เลือกใช้แทน "patron"/"user")
- **Loan** — การยืมหนังสือ 1 ครั้ง (record ใน DB)
- **Overdue** — loan ที่ `due_date < today` และยัง `returned_at IS NULL`
- **Catalog** — รายการหนังสือทั้งหมดในระบบ (book master)
- **Reserve** — สมาชิกจองหนังสือที่ถูกยืมอยู่ให้ตัวเองได้คิวถัดไป

## 12. Open Questions

<!-- Tip: ใช้ /bda-clarify เพื่อแก้ทีละข้อ; เมื่อแก้แล้วจะย้ายไป Clarifications section -->

- [ ] Reserve queue limit 3 หรือ 5 เล่ม/สมาชิก?
- [ ] Admin role ต้องแยก super-admin vs branch-admin ไหม?

## 13. Clarifications

<!-- Tip: section นี้จะถูกเติมโดย `/bda-clarify` — ห้ามแก้ด้วยมือ; แต่ละ session = วันละ block -->

<!-- ตัวอย่างหลัง /bda-clarify:
### Session 2026-05-21
- **Q1 (Domain):** "Overdue" นับ calendar day หรือ business day? **A:** Calendar day (grace 1 วัน weekend). Reasoning: PDPA ไม่ระบุ + ลด edge case
- **Q2 (UX):** Reminder ส่งทาง email หรือ SMS? **A:** Email only (MVP); SMS เฟส 2
-->

_ยังไม่มี clarification session_

## 14. Pipeline trace

<!-- Tip: ทุก doc ใน bda-spec ต้องมี trace 5 ขั้น (BDA standard) — เติมเมื่อ doc ผ่านขั้นไหน -->

- **Understand**: vault scan + stakeholder interview (เติม path)
- **Plan**: PRD draft → review → approved
- **Execute**: SRS + FEAT + Plan files generated (link path)
- **Verify**: SC-### measured on launch (link evidence)
- **Handoff**: launch announcement + post-launch review (link path)
