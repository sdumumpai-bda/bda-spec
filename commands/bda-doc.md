---
description: Write or update vault doc (PRD/SRS/Tech/ADR/Feature/Function/Role) using template
model: claude-sonnet-4-6
---

<!--
BDA Standard v0.7.0 alignment (matches `commands/write-document.md` + `commands/update-obsidian.md`):
- Read Obsidian context manifest BEFORE writing — preserve frontmatter/links/tags conventions
- Update note ตาม manifest's "Structure Map"
- Preserve link graph — never break wikilinks; if rename → leave alias
-->


# /bda-doc — เขียน/แก้เอกสาร vault

ทำงานกับเอกสารทุกประเภทใน vault โดยใช้ template ที่กำหนด

## Trigger

```
/bda-doc                              # interactive — ถาม type
/bda-doc <type> <name>                # เช่น /bda-doc PRD CheckoutFlow
/bda-doc --edit <path>                # แก้ไฟล์ที่มีอยู่
/bda-doc --review <path>              # review only ไม่แก้
```

## Phase 0 — เลือก type

| Type | Folder | Template |
|---|---|---|
| `PRD` | `10-PRD/PRD-<slug>.md` | `prd.md` |
| `SRS` | `10-PRD/SRS-<slug>.md` | `srs.md` |
| `Tech` | `70-Reference/REF-Architecture.md` | `tech-spec.md` |
| `ADR` | `70-Reference/ADR/ADR-NNNN-<slug>.md` | `adr.md` |
| `Feature` | `20-Features/FEAT-<slug>.md` | `feature.md` |
| `Function` | `40-Functions/<area>/FN-<slug>.md` | `function.md` |
| `Role` | `30-Roles/<platform>/<role>.md` | `role.md` |
| `Flow` | `60-Flows/FLOW-<slug>.md` | `flow.md` |
| `Phase` | `50-Phases/PHASE-<n>-<slug>.md` | `phase.md` |
| `TestPlan` | `90-TestPlan/TP-<slug>.md` | `test-plan.md` |
| `Reference` | `70-Reference/REF-<slug>.md` | `reference.md` |

Template lookup: `templates/<name>.md` first, fallback `.bda-spec/templates/<name>.md`

## Phase 1 — Determine action

| สภาพ | Action |
|---|---|
| ไฟล์ยังไม่มี | **Create** mode |
| ไฟล์มีอยู่, `--edit` | **Edit** mode — เพิ่ม/แก้ section |
| ไฟล์มีอยู่, `--review` | **Review** mode — ตรวจ gaps แต่ไม่แก้ |
| ไฟล์มีอยู่, ไม่มี flag | ถาม edit หรือ review |

## Phase 2 — Read context

อ่าน:
1. Template ที่จะใช้ (`templates/<name>.md` หรือ `.bda-spec/templates/<name>.md`)
2. Related docs ที่ link ไป — เช่น สร้าง Feature → อ่าน PRD ก่อน
3. `00-Index/IMPLEMENTATION-STATUS.md`
4. Docs ใน folder เดียวกันที่มี pattern คล้าย (เพื่อ keep consistency)

## Phase 3 — Create / Edit

### Create mode:
1. Copy template → target path
2. Fill frontmatter (`status: draft`, `date`, `version`, `authors`)
3. Fill body ตาม context + ถามคำถามที่ template ระบุ (เป็น `<TODO: ...>` placeholders)
4. ถาม batch — 3-5 คำถาม ใน message เดียว

### Edit mode:
1. แสดง outline current → ถามว่าจะแก้ section ไหน
2. แสดง diff ก่อน save
3. Preserve frontmatter ที่ไม่เกี่ยว (เช่น `version` bump only ถ้า substantive change)
4. Update `last_modified`, `modified_by`

### Review mode:
1. เทียบ section actual กับ template
2. List missing sections + sections ที่ตื้นไป
3. ตรวจ link integrity (link ไป doc อื่นที่ไม่มี)
4. ตรวจ frontmatter completeness
5. **ไม่แก้ไฟล์** — แค่ output report

## Phase 4 — Update MOC + link graph

หลัง create/edit:
1. Update relevant MOC (`00-Index/MOC-PRD.md`, `MOC-Features.md` ฯลฯ) เพิ่ม link
2. Update `00-Index/IMPLEMENTATION-STATUS.md` ถ้า status เปลี่ยน
3. Update outgoing/incoming wiki links — ตรวจว่าทุก `[[link]]` ชี้ไปไฟล์จริง
4. ถ้าเป็น Function → update related Feature, Role
5. ถ้าเป็น PRD/SRS update → flag dependent Features ที่อาจต้อง review

## Phase 5 — Design system bind (ถ้า doc เป็น Function/Feature ที่มี UI)

ถ้า `docs/obsidian-vault/70-Reference/DesignSystem/` มีอยู่:
- Section "UI Components Used" ใน doc → ระบุ components จาก `DS-Components.md`
- Section "Design Tokens Used" → ระบุ tokens จาก `DS-Tokens.md`
- Validate ว่า component ที่อ้างมีอยู่จริงใน design system

## Phase 6 — Log checkin

```markdown
- HH:MM — [type/doc-create] หรือ [type/doc-edit] หรือ [type/doc-review] — <type> <slug>
```

## Output (5 หัวข้อบังคับ)

1. **BDA Standard files used** — `.bda-spec/STANDARD.md`, template ที่ใช้
2. **Pipeline trace** — Understand (Phase 2) → Plan (Phase 1 mode + outline) → Execute (Phase 3) → Verify (Phase 4 link + frontmatter check)
3. **Commands run** — Read template, Read related docs, Write/Edit target
4. **Verification / Evidence** — file path, sections filled count, link integrity result
5. **Limitations / Risks / Next steps** — `draft` status ต้อง review, dependent docs ที่ flag ไว้

## ห้าม

- ห้ามแต่ง stakeholder name, business rule, requirement ที่ user ไม่ได้ระบุ
- ห้าม overwrite section ที่ user เขียนเองโดยไม่ confirm
- ห้าม bump version ใน frontmatter โดยไม่ confirm (รักษา version control)
