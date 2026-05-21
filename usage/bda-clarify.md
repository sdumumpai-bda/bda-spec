# /bda-clarify

> **Taxonomy ambiguity scan** — ถามทีละข้อ (max 5) พร้อม recommended answer → เขียนกลับเข้า doc เป็น Clarifications section

[← กลับ usage/README](./README.md) · [Full spec: `commands/bda-clarify.md`](../commands/bda-clarify.md)

## เมื่อไหร่ใช้

- หลัง `/bda-new` สร้าง PRD/SRS แล้ว → ก่อน `/bda-plan` เพื่อ resolve ambiguity
- ตรวจ plan ที่มี weasel words ("fast", "many", "appropriate", "TBD")
- มี `[NEEDS CLARIFICATION]` marker ใน doc — รวบ resolve ครั้งเดียว

> **อิงจาก spec-kit `/clarify`** — 9-category taxonomy

## Quick start

```
/bda-clarify
```

ตัวอย่างคำถามที่จะเห็น:
```
🔍 Clarification 2/5 — Category: UX / Behavior

Question:
เมื่อ checkout สำเร็จ ระบบควรแสดงผลแบบไหน?

Options:
  A) Toast (auto-dismiss 3 วินาที) — discrete
  B) Modal dialog (user คลิก close) — explicit confirmation
  C) Inline message ใน page เดิม
  D) Redirect ไป /checkout/success — มี receipt

Recommended: B) Modal dialog
Reasoning: Librarian ต้องการ explicit confirmation; matches DS-Components Modal pattern.

Your answer: [A/B/C/D หรือ ข้อความอื่น]
```

## รูปแบบเต็ม

```
/bda-clarify                          # scan latest active plan
/bda-clarify <path>                   # scan specific doc (PRD/SRS/FEAT/plan/...)
/bda-clarify --feature <slug>         # scan all docs ของ feature นั้น
/bda-clarify --max 3                  # override max questions (default 5)
/bda-clarify --resume                 # continue session ที่ค้าง
```

| Flag | Default | ใช้สำหรับ |
|---|---|---|
| `--feature <slug>` | n/a | scan ทุก doc ที่ `feature:` matches |
| `--max <N>` | 5 | จำกัด questions/session |
| `--resume` | off | กลับมาทำต่อจาก deferred questions |

## ขั้นตอนภายใน (Phase summary)

1. **Phase 0** — Resolve target (latest plan หรือ explicit path)
2. **Phase 1** — Taxonomy scan ตาม 9 หมวด (Functional Scope, Domain & Data, UX, NFR, Integration, Edge Cases, Constraints, Terminology, Completion/DoD) → filter เหลือ max 5
3. **Phase 2** — Ask 1-at-a-time พร้อม **Recommended answer** + cite reasoning จาก vault
4. **Phase 3** — Write back: append `## Clarifications > ### Session YYYY-MM-DD` ใน source doc
5. **Phase 4** — Flag affected docs (data-model, API contract, DS component, FR list) — ไม่แก้เอง
6. **Phase 5** — Log + handoff next-step

## Output ที่ได้

- Source doc มี section ใหม่:
  ```markdown
  ## Clarifications
  ### Session 2026-05-21
  - Q1 (UX): Toast vs modal? A: Modal (recommended). Reasoning: …
  - Q2 (Edge): Network fail ระหว่าง checkout? A: Inline error + retry.
  ```
- Checkin entry: `HH:MM — [type/clarify] /bda-clarify on <target> — 5 questions resolved`
- Flag list (affected docs) — แสดงในแชตเท่านั้น

## 9 Taxonomy categories

| Category | ตัวอย่าง ambiguity |
|---|---|
| 1. Functional Scope | "support multiple X" — กี่ตัว? |
| 2. Domain & Data | "user" — role ไหน? schema อะไร? |
| 3. UX / Behavior | "show notification" — modal/toast/banner? |
| 4. Non-functional | "fast" — กี่ ms? "secure" — threat model? |
| 5. Integration | endpoint? auth? retry? |
| 6. Edge Cases | empty state, network fail, concurrent edit |
| 7. Constraints | budget, deadline, must-reuse |
| 8. Terminology | "member" vs "user" vs "account" |
| 9. Completion / DoD | "done" = merged? deployed? approved? |

## Workflow ที่นิยม

ตัวอย่าง 1: หลัง brainstorm PRD
```
1. /bda-new                       ← PRD/SRS draft
2. /bda-clarify                   ← resolve 5 ambiguity
3. /bda-analyze                   ← check ว่ายังมี orphan FR ไหม
4. /bda-plan FEAT-X
```

ตัวอย่าง 2: scan plan ที่ค้าง
```
1. /bda-clarify docs/obsidian-vault/80-ImplementPlan/2026-05-20-bootstrap-checkout-ui.md
2. (user ตอบ 5 ข้อ)
3. /bda-plan --revise <same path>    ← incorporate answers
```

## Gotchas / ข้อควรระวัง

- 🚫 **ห้าม batch คำถาม** — ทีละข้อเท่านั้น (ต่างจาก `/bda-new` และ `/bda-plan` ที่ batch)
- 🚫 ห้ามให้ recommended answer ที่ไม่อิง vault content — ต้อง cite ทุก reasoning ด้วย link
- 🚫 ห้ามแก้ source doc นอก `## Clarifications` section
- 🚫 ห้ามถามคำถามที่ vault ตอบอยู่แล้ว — Phase 1 filter ออกก่อน
- 💡 ตอบ `skip` หรือ `TBD` → mark `[DEFERRED]` กลับมาทำต่อด้วย `--resume`
- 💡 ถ้าไม่รู้จะใส่ option ไหน → ใส่แค่ 2 + `[OTHER]` ให้ user พิมพ์เอง

## Related

- ก่อน `/bda-clarify`: [/bda-new](./bda-new.md), [/bda-doc](./bda-doc.md)
- หลัง `/bda-clarify`: [/bda-analyze](./bda-analyze.md) (check consistency), [/bda-plan](./bda-plan.md) `--revise`
- ถ้า answer กระทบ data model: [/bda-doc](./bda-doc.md) data-model
- ถ้า affect DS: [/bda-design](./bda-design.md) component

## FAQ

**Q: ถ้า session ค้างกลางทาง — กลับมาทำต่อยังไง?**
A: `/bda-clarify --resume` จะอ่าน deferred questions จาก source doc และถามต่อ

**Q: ทำไมต้อง 1-at-a-time? batch ไม่เร็วกว่าหรอ?**
A: spec-kit แนวคิด: ลด decision fatigue + ตอบ Q1 อาจกระทบ Q2-Q5 (เช่น terminology choice) → ดีกว่าตอบครั้งละข้อ

**Q: 5 ข้อพอไหม?**
A: ถ้าเจอเยอะ → ใช้ priority (Critical > High > Medium) + cheap-to-answer แก้รอบเดียว 5 ก่อน รอบหลัง `--max 5` ใหม่
