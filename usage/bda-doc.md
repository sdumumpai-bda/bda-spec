# /bda-doc

> **เขียน/แก้/review vault doc** — PRD, SRS, Tech, ADR, Feature, Function, Role, Flow, Phase, TestPlan, Reference

[← กลับ usage/README](./README.md) · [Full spec: `commands/bda-doc.md`](../commands/bda-doc.md)

## เมื่อไหร่ใช้

- เติม section ที่ขาดใน PRD/SRS (หลัง `/bda-new` import หรือ `/bda-analyze` flag underspec)
- เขียน Feature spec ใหม่ (FEAT-*) หรือ Function spec (FN-*)
- บันทึก architecture decision (ADR)
- สร้าง Role/Flow/Phase ใหม่
- Review doc ที่มีอยู่ — ดู gaps + link integrity (ไม่แก้)

## Quick start

```
/bda-doc PRD CheckoutFlow
```

หรือ interactive:
```
/bda-doc
→ ถาม type (PRD/SRS/Tech/ADR/Feature/Function/Role/Flow/Phase/TestPlan/Reference)
→ ถามชื่อ + scope
→ copy template + ถาม batch 3-5 คำถาม
```

## รูปแบบเต็ม

```
/bda-doc                              # interactive
/bda-doc <type> <name>                # /bda-doc PRD CheckoutFlow
/bda-doc --edit <path>                # แก้ไฟล์ที่มีอยู่
/bda-doc --review <path>              # review only — ไม่แก้
```

| Flag | Default | ใช้สำหรับ |
|---|---|---|
| `--edit <path>` | n/a | edit specific section (ถาม section ไหน) |
| `--review <path>` | n/a | gap analysis + link check (read-only) |

## Type → folder mapping

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

Template lookup: `.bda-spec/local/templates/<n>.md` > `templates/<n>.md` > `standards/templates/<n>.md`

## ขั้นตอนภายใน (Phase summary)

1. **Phase 0** — เลือก type
2. **Phase 1** — Determine action (create / edit / review)
3. **Phase 2** — Read context (template + related docs + IMPLEMENTATION-STATUS + folder patterns)
4. **Phase 3** — Create/Edit/Review (batch 3-5 คำถาม + show diff ก่อน save)
5. **Phase 4** — Update MOC + link graph (`MOC-*.md`, IMPLEMENTATION-STATUS, wikilinks)
6. **Phase 5** — Design system bind (Function/Feature ที่มี UI → "UI Components Used" section)
7. **Phase 6** — Log checkin

## Output ที่ได้

- New file ใน folder ที่ถูกต้อง (frontmatter ครบ: `status: draft`, `date`, `version`, `authors`)
- MOC updates (`00-Index/MOC-PRD.md`, `MOC-Features.md`, etc.)
- IMPLEMENTATION-STATUS update (ถ้า status เปลี่ยน)
- Checkin: `HH:MM — [type/doc-create] <type> <slug>` หรือ `[type/doc-edit]` / `[type/doc-review]`

## Workflow ที่นิยม

ตัวอย่าง 1: เติม PRD ที่ import มาแบบ partial
```
1. /bda-new --import customer-prd.md       ← gap analysis ระบุขาด Goals, Personas
2. /bda-doc --edit docs/10-PRD/PRD-<slug>.md
   → ถาม section ไหนจะแก้
   → เติม Goals + Personas
```

ตัวอย่าง 2: บันทึก ADR
```
/bda-doc ADR use-graphql-instead-of-rest
  → สร้าง docs/70-Reference/ADR/ADR-0003-use-graphql-instead-of-rest.md
  → ถาม: Context, Decision, Consequences, Alternatives
```

ตัวอย่าง 3: review เก่า
```
/bda-doc --review docs/20-Features/FEAT-Checkout.md
  → list missing sections + dependency check
  → ไม่แก้ — แค่ report
```

## Gotchas / ข้อควรระวัง

- 🚫 ห้ามแต่ง stakeholder name, business rule, requirement ที่ user ไม่ได้ระบุ
- 🚫 ห้าม overwrite section ที่ user เขียนเองโดยไม่ confirm
- 🚫 ห้าม bump version ใน frontmatter โดยไม่ confirm (รักษา version control)
- ⚠️ Wikilink graph: ทุก `[[link]]` ต้องชี้ไปไฟล์จริง — Phase 4 ตรวจ broken links
- 💡 Edit mode แสดง diff ก่อน save — preserve frontmatter ที่ไม่เกี่ยว
- 💡 Review mode = read-only — output report ในแชต, ไม่แก้ไฟล์

## Related

- ก่อน `/bda-doc`: [/bda-new](./bda-new.md) (สร้าง PRD/SRS skeleton), [/bda-analyze](./bda-analyze.md) (flag underspec)
- หลัง `/bda-doc`: [/bda-plan](./bda-plan.md) (ใช้ doc เป็น context)
- DS-related: [/bda-design](./bda-design.md)
- Vault structure: ดู [`README.md`](../README.md) section "โครงสร้าง"
- Templates: [`../templates/`](../templates/)

## FAQ

**Q: ถ้า template ไม่มีใน `templates/` ใช้อันไหน?**
A: Fallback `standards/templates/<n>.md` (read-only) — ถ้าอยาก customize → copy ไป `templates/<n>.md` แล้วแก้

**Q: ADR เป็น immutable หรือเปล่า?**
A: ใช่ — ADR ที่ accepted แล้วไม่แก้ ถ้าเปลี่ยน decision → สร้าง ADR ใหม่ที่ supersedes ของเดิม

**Q: review mode ใช้แทน `/bda-analyze` ได้ไหม?**
A: คนละ scope — review ตรวจ doc เดียว vs template; analyze cross-artifact (coverage table) — ใช้คู่กัน
