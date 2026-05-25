# /bda-fix

> **Diagnose bug + สร้าง fix-log** — ไม่แก้โค้ด, เก็บ before-evidence, เตรียม root cause + fix approach

[← กลับ usage/README](./README.md) · [Full spec: `.bda-spec/commands/bda-fix.md`](../.bda-spec/commands/bda-fix.md)

## เมื่อไหร่ใช้

- เจอ bug → อยาก document + diagnose ก่อนแก้
- ลูกค้า report — ต้องเก็บ trail สำหรับ exec/QA
- บั๊ก regression — track ครั้งที่ 2, 3 ของ bug เดียวกัน (`--update`)
- หลัง `/bda-fix` → `/bda-plan fix:<slug>` → `/bda-implement` (= แก้จริง)

## Quick start

```
/bda-fix "search ค้างเมื่อใส่ขีดล่าง"
```

ตัวอย่างไฟล์ที่ได้:
```
docs/obsidian-vault/85-FixLog/2026-05-21-1430-search-stuck-underscore.md

---
status: in-progress
severity: P1
area: web
---

# search ค้างเมื่อใส่ขีดล่าง
## Symptom · Reproduction · Root Cause · Vault Context · Before Evidence · Fix Approach · Affected Files · Test Cases · Risk · Next
```

## รูปแบบเต็ม

```
/bda-fix "<bug description>"
/bda-fix <bug> --update docs/obsidian-vault/85-FixLog/<file>.md
```

| Flag | Default | ใช้สำหรับ |
|---|---|---|
| `--update <path>` | new file | append investigation/evidence/status change ใน fix-log เดิม (append-only) |

## ขั้นตอนภายใน (Phase summary)

1. **Phase 1** — Detect mode (new vs --update)
2. **Phase 2** — Diagnose (read-only): identify area, reproduce (read code preferred), grep/Read root cause, draft fix approach + test cases
3. **Phase 3** — สร้าง fix-log `docs/obsidian-vault/85-FixLog/YYYY-MM-DD-HHMM-<slug>.md`
4. **Phase 4** — Auto-link plan: เสนอ `/bda-plan fix:<slug>` หรือ `/bda-implement --from-fix` (P3 polish เท่านั้น)
5. **Phase 5** — Update mode (append section: investigation update, new evidence, status change)
6. **Phase 6** — Log checkin

## Fix-log structure

```
Frontmatter:
  status: in-progress | fixed | wont-fix | regressed
  severity: P0 blocker | P1 major | P2 minor | P3 polish
  area: api | web | mobile | cross
  reported_by: user | qa | self | customer
  related_plan: <path or none>

Body:
  ## Symptom               ← what user sees
  ## Reproduction          ← steps + expected vs actual
  ## Root Cause            ← file:function:line จาก grep/read
  ## Vault Context Read    ← FN-*, REF-Auth, similar fix-logs
  ## Before Evidence       ← error log, screenshot path, console
  ## Fix Approach          ← paragraph (ยังไม่ใช่โค้ด)
  ## Affected Files
  ## Test Cases            ← พิสูจน์ว่า fix ใช้ได้
  ## Risk                  ← ของ fix นี้ + mitigation
  ## Next                  ← /bda-plan fix:<slug> → /bda-implement
```

## Output ที่ได้

- `docs/obsidian-vault/85-FixLog/YYYY-MM-DD-HHMM-<slug>.md`
- Before evidence files (ใน `docs/<context>/evidence/` หรือ shown path)
- Checkin entry: `HH:MM — [type/fix-diagnose] Created fix-log: <slug> (severity: P1, area: web)`
- **ไม่แตะโค้ด**

## Severity guide

| Level | ใช้เมื่อ |
|---|---|
| P0 — blocker | service ลม, data loss, security breach |
| P1 — major | feature broken, ผู้ใช้ได้รับผลกระทบกว้าง |
| P2 — minor | edge case, workaround มี |
| P3 — polish | cosmetic, copy, small UX |

## Workflow ที่นิยม

ตัวอย่าง 1: standard bug fix
```
1. /bda-fix "search ค้าง"              ← คุณอยู่ที่นี่ — diagnose + fix-log
2. /bda-plan fix:search-stuck           ← mini-plan link ไปยัง fix-log
3. [approve]
4. /bda-implement <plan>
5. /bda-test --since HEAD~              ← verify fix
6. /bda-evidence                        ← curate before/after
7. /bda-git --fix <fix-log>             ← commit prefix `fix:`
```

ตัวอย่าง 2: P3 polish (skip plan)
```
1. /bda-fix "typo ใน button" --severity P3
2. /bda-implement --from-fix <fix-log>  ← ข้าม /bda-plan
```

ตัวอย่าง 3: regression
```
1. /bda-fix "search ค้างอีกแล้ว" --update docs/obsidian-vault/85-FixLog/2026-05-10-search-stuck.md
   → append section: "Investigation update — regressed after refactor"
   → change status: in-progress → regressed
```

## Gotchas / ข้อควรระวัง

- 🚫 **ห้ามแก้โค้ดใน `/bda-fix`** — diagnose-only, code change ต้องผ่าน `/bda-implement`
- 🚫 ห้ามเดา root cause โดยไม่ verify ที่ source (grep/read)
- 🚫 ห้ามแต่ง error message หรือ stack trace
- 🚫 `--update` = append-only — ห้าม overwrite section เดิม
- ⚠️ Bug ไม่ชัด → ถาม **1-3 คำถามใน message เดียว**
- 💡 fix-log เป็น "lighter plan" ของ bda-spec — โครงเล็กกว่า `/bda-plan` แต่หลักการเดียวกัน
- 💡 ก่อน implement ต้องผ่าน `/bda-plan fix:<slug>` (ยกเว้น P3) — เพื่อให้มี approved gate

## Related

- ก่อน `/bda-fix`: ผู้ใช้ report bug / `/bda-test` เจอ FAIL
- หลัง `/bda-fix`: [/bda-plan](./bda-plan.md) `fix:<slug>` → [/bda-implement](./bda-implement.md)
- Evidence: [/bda-evidence](./bda-evidence.md) (before/after)
- Vault path: `docs/obsidian-vault/85-FixLog/`
- Template: `templates/fix-log.md`

## FAQ

**Q: ต่าง `/bda-fix` กับ `/bda-plan` ยังไง?**
A: `/bda-plan` = feature work (vault-driven, FR-### mapping, 5-15 steps); `/bda-fix` = bug (diagnose-first, lighter structure, root cause focus)

**Q: ผมแก้บั๊กเอง ไม่ผ่าน `/bda-fix` ได้ไหม?**
A: ได้ทางเทคนิค แต่จะไม่มี trail สำหรับ exec/audit — แนะนำผ่าน workflow แม้บั๊กเล็ก

**Q: P3 polish ต้องมี fix-log ไหม?**
A: แนะนำมี (เพื่อ track) แต่ skip `/bda-plan` ได้ — `/bda-implement --from-fix` ใช้ได้กับ P3 เท่านั้น
