---
description: Start new project from idea (brainstorm) or existing PRD — builds PRD → SRS → Tech spec chain
model: claude-sonnet-4-6
---

# /bda-new — เริ่มโปรเจกต์ใหม่ จาก idea หรือ PRD

ใช้เมื่อ:
- มี idea แต่ยังไม่มีเอกสารใดๆ → **Brainstorm mode**
- มี PRD เขียนไว้แล้ว อยากต่อ SRS/Tech spec → **Import mode**

## Trigger

```
/bda-new
/bda-new <one-line description>
/bda-new --import <path-to-existing-prd>
```

## Phase 0 — Detect mode

| Argument | Mode |
|---|---|
| ว่าง | ถาม "มี PRD แล้วหรือยัง? (brainstorm / import / show-existing)" |
| free text | **Brainstorm** with seed |
| `--import <path>` | **Import** existing PRD file |

ถ้าใน `docs/obsidian-vault/10-PRD/` มีไฟล์อยู่แล้ว → แจ้ง user + ถามว่าจะเริ่มอันใหม่ หรือต่อจากของเดิม

## Phase 1 (Brainstorm mode) — เปิด idea

ถาม **5 คำถาม ครั้งเดียว** (ห้ามทยอย):

1. **Problem**: ปัญหาที่อยากแก้คืออะไร? ใครเจอ?
2. **Target users**: ใครคือผู้ใช้หลัก? (1-3 personas)
3. **Goals**: เมื่อใช้แล้วผู้ใช้ได้อะไร? (3-5 outcomes)
4. **Non-goals**: ที่จะ **ไม่ทำ** ใน MVP นี้? (กันขอบเขต)
5. **Constraints**: deadline, budget, tech stack, compliance, language ที่บังคับ?

จาก answers → สร้าง:

### 1.1 PRD draft

`docs/obsidian-vault/10-PRD/PRD-<project-slug>.md` ตาม `templates/prd.md` (ถ้าไม่มีใน `templates/` ใช้ `standards/templates/prd.md`)

Frontmatter:
```yaml
---
tags: [type/prd]
status: draft           # draft | review | approved | superseded
version: 0.1.0
date: YYYY-MM-DD
authors: [<user>]
---
```

### 1.2 ถาม clarification (รอบ 2, ถ้ามีคำถามเหลือ)

ถ้ายังขาด detail เรื่อง business rule, scale, integration → ถามอีกแค่ **1 รอบ** แล้วเขียนต่อ

### 1.3 สร้าง SRS

`docs/obsidian-vault/10-PRD/SRS-<project-slug>.md` ตาม `templates/srs.md`

Section: System overview, User stories, Functional requirements (FR-001, FR-002, ...), Non-functional requirements, Acceptance criteria

### 1.4 สร้าง Tech spec

`docs/obsidian-vault/70-Reference/REF-TechStack.md` + `docs/obsidian-vault/70-Reference/REF-Architecture.md` ตาม `templates/tech-spec.md`

Section: Tech stack, Architecture diagram (Mermaid), Data model, API contracts (REST/GraphQL), Auth, Deployment

### 1.5 สร้าง Phase plan

`docs/obsidian-vault/50-Phases/PHASE-1-MVP.md` — แตก SRS เป็น features ใน Phase 1

### 1.6 Update 00-Index/IMPLEMENTATION-STATUS.md

เพิ่ม project entry, link ไปไฟล์ที่สร้าง, status: `planning`

## Phase 1 (Import mode) — รับ PRD เข้ามา

```bash
# ถ้า user ระบุ path ไม่ถูกหรือไม่มี → ขอ path ใหม่
test -f "$PRD_PATH" || echo "ไฟล์ไม่พบ"
```

1. อ่าน PRD ที่ user ให้
2. Copy/move → `docs/obsidian-vault/10-PRD/PRD-<slug>.md`
3. ถ้า frontmatter ไม่ครบ → เติมให้ตาม template (ถาม user ถ้าจำเป็น)
4. **Gap analysis** — เทียบกับ `templates/prd.md`:
   - หา section ที่ขาด (Goals, Non-goals, Personas, KPIs, Risks, ฯลฯ)
   - แสดงให้ user เห็นแต่ละ gap
   - ถามแบบ batch: "ต้องการเติม section ไหนบ้าง?"
5. เติม section ที่ user เลือก โดยถาม content ทีละ section (or generate suggestion)
6. ต่อ **เหมือน Phase 1.3 onward** — สร้าง SRS → Tech spec → Phase plan
7. Update `IMPLEMENTATION-STATUS.md`

## Phase 2 — Plan trail

ทุกการสร้าง doc ต้อง log ลง `docs/obsidian-vault/75-Checkins/<today>.md` ใน section "Created":

```markdown
## Notes
- HH:MM — [type/doc-create] Created PRD-library-book-tracker.md via /bda-new brainstorm
- HH:MM — [type/doc-create] Created SRS-library-book-tracker.md
- HH:MM — [type/doc-create] Created REF-TechStack.md
```

ถ้า checkin file ยังไม่มีของวันนี้ → สร้างใหม่ตาม template

## Phase 3 — แนะนำขั้นต่อไป

แสดง next-step menu:

> เอกสาร foundation พร้อมแล้ว ขั้นต่อไป:
>
> - วางแผน feature แรก → `/bda-plan <feature>`
> - สร้าง design system → `/bda-design`
> - เริ่ม build เลย (ข้าม plan) → `/bda-implement` (ไม่แนะนำสำหรับ MVP)
> - เพิ่ม PRD detail → `/bda-doc PRD-<slug>`

## Output ที่ต้องมี (5 หัวข้อบังคับ)

1. **BDA Standard files used** — `standards/STANDARD.md`, `standards/policies/no-fake-evidence.md`, `templates/prd.md`, `templates/srs.md`, `templates/tech-spec.md`
2. **Pipeline trace** — Understand (Phase 0 detect) → Plan (Phase 1 ถามคำถาม) → Execute (Phase 1.1-1.6 สร้างเอกสาร) → Verify (file existence check + frontmatter validation) → Handoff (Phase 3 next-step)
3. **Commands run** — `mkdir -p docs/{10-PRD,...}`, `Write docs/...`, ฯลฯ
4. **Verification / Evidence** — list ของไฟล์ที่สร้างจริง + จำนวน sections ใน PRD
5. **Limitations / Risks / Next steps** — เช่น "PRD ยังเป็น draft — ต้อง review กับ stakeholder ก่อนสร้าง plan", "Tech stack ยังไม่ confirm กับทีม backend"

## ห้าม

- ห้ามแก้โค้ดใดๆ ใน command นี้ — `/bda-new` สร้างเอกสารเท่านั้น
- ห้ามแต่ง user data, stakeholder, requirement ที่ user ไม่ได้ระบุ — ถามดีกว่า
- ห้าม overwrite PRD เดิมโดยไม่ confirm
