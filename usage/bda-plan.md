# /bda-plan

> **Vault-first research + สร้าง plan file** — อ่าน vault → clarify → เขียน plan → **หยุดก่อนแตะโค้ดเสมอ**

[← กลับ usage/README](./README.md) · [Full spec: `commands/bda-plan.md`](../commands/bda-plan.md)

## เมื่อไหร่ใช้

- ก่อน implement feature/task — บังคับมี plan file ที่ approve แล้ว
- มี PRD/SRS ครบแล้ว → ขั้นถัดไปคือวางแผน implement
- ต้องการ revise plan เดิม (`--revise`)
- หลัง `/bda-fix` → สร้าง mini-plan ที่ link ไปยัง fix-log

## Quick start

```
/bda-plan "เพิ่ม search สำหรับ book inventory"
```

ตัวอย่างไฟล์ที่ได้:
```
docs/80-ImplementPlan/2026-05-21-1430-add-search-feature.md

---
tags: [type/plan]
status: planning            ← user ต้อง set เป็น approved ก่อน /bda-implement
submodule_target: web
subagent_target: frontend
related_docs: [...]
---

# เพิ่ม search สำหรับ book inventory
## Vault Context Read · Task · Goals · Affected Files · Steps · DS Compliance · Test Plan · Risks · Approvals
```

## รูปแบบเต็ม

```
/bda-plan "<task description>"
/bda-plan <task> --revise docs/80-ImplementPlan/<file>.md
/bda-plan fix:<slug>                # plan ที่ link จาก fix-log
```

| Flag | Default | ใช้สำหรับ |
|---|---|---|
| `--revise <path>` | n/a | update plan in-place (ไม่สร้างไฟล์ใหม่) |

## ขั้นตอนภายใน (Phase summary)

1. **Phase 1** — อ่าน vault context (บังคับ): `IMPLEMENTATION-STATUS`, PRD/SRS, FEAT, FN, ROLE, REF-Auth, REF-API, REF-TechStack, DS-Tokens/Components
2. **Phase 2** — Clarifying questions **1 batch** (ถามที่ vault ไม่ตอบเท่านั้น)
3. **Phase 3** — เขียน plan file ตาม template (Vault Context Read, Task, Goals, Non-goals, Affected Files, Steps, DS Compliance, Test Plan, Risks, Approvals)
4. **Phase 4** — Doc gap detection (จด ใน `Doc Gaps Found` — implement จะ fix ก่อน)
5. **Phase 5** — **STOP** — แสดง path + ขอ user review + set `status: approved`
6. **Phase 6** — Log checkin

## Output ที่ได้

- `docs/80-ImplementPlan/YYYY-MM-DD-HHmm-<slug>.md` (status: planning, ≤ 5 คำ slug)
- Checkin entry: `HH:MM — [type/plan] Created plan: <slug> (status: planning)`
- **ห้ามแตะโค้ด** — plan file เท่านั้น

## Plan file structure

```
Frontmatter:
  tags: [type/plan]
  status: planning | approved | in-progress | done | abandoned
  submodule_target: api | web | mobile | docs | all
  subagent_target: backend | frontend | mobile | docs | design | all
  related_docs: [list]
  estimate_hours: <number>
  risk_level: low | medium | high

Body:
  ## Vault Context Read       ← ทุก doc ที่อ่าน
  ## Task                     ← clear one-paragraph
  ## Goals / Non-goals
  ## Doc Gaps Found           ← จะ fix ก่อน implement
  ## Affected Files
  ## Implementation Steps     ← 5-15 steps medium / 3-5 small
  ## Design System Compliance ← ถ้า frontend/mobile
  ## Design Additions          ← component ใหม่ที่ต้อง /bda-design ก่อน
  ## Test Plan
  ## Verification             ← acceptance criteria
  ## Risks
  ## Approvals
```

## Workflow ที่นิยม

ตัวอย่าง 1: feature ใหม่
```
1. /bda-new                    ← PRD/SRS/Tech
2. /bda-clarify                 ← resolve ambiguity
3. /bda-plan FEAT-Checkout      ← คุณอยู่ที่นี่
4. [user review + set status: approved ใน frontmatter]
5. /bda-implement <path>
```

ตัวอย่าง 2: revise plan ที่ค้าง
```
1. /bda-plan "เพิ่ม search" --revise docs/80-ImplementPlan/2026-05-20-1430-add-search.md
   → re-read vault (อาจมีการ update)
   → update in-place + แสดง diff
   → STOP รอ review
```

ตัวอย่าง 3: bug fix
```
1. /bda-fix "search ค้าง"             ← สร้าง fix-log
2. /bda-plan fix:<slug>                ← mini-plan link ไปยัง fix-log
3. [approve]
4. /bda-implement <plan>
```

## Gotchas / ข้อควรระวัง

- 🚫 **ห้ามแตะโค้ด ห้ามรัน build/test/lint** — `/bda-plan` text-only
- 🚫 **ห้าม spawn subagent** — plan file เท่านั้น
- 🚫 **ห้าม set `status: approved` ให้ user** — user ต้องทำเอง (gate manual)
- ⚠️ Vault-first: ถ้า vault ตอบอยู่แล้ว → ห้ามถาม user
- ⚠️ คำถามใน Phase 2 ต้อง **batch** (ต่างจาก `/bda-clarify` ที่ 1-at-a-time)
- 💡 ถ้า plan มี Design Additions → ต้องรัน `/bda-design component <name>` ก่อน `/bda-implement`
- 💡 Doc Gaps ที่ list ใน plan → `/bda-implement` Phase 2 จะ spawn `docs` subagent fix ก่อน

## Related

- ก่อน `/bda-plan`: [/bda-new](./bda-new.md), [/bda-clarify](./bda-clarify.md), [/bda-fix](./bda-fix.md)
- หลัง `/bda-plan` (approve แล้ว): [/bda-implement](./bda-implement.md)
- Analyze: [/bda-analyze](./bda-analyze.md) — coverage check (FR → task ID mapping)
- Template: `templates/plan.md` (fallback `standards/templates/plan.md`)
- Vault path: `docs/80-ImplementPlan/`

## FAQ

**Q: ทำไม `/bda-plan` ไม่เขียนโค้ดให้?**
A: bda-spec แยก plan/implement เคร่งครัด — plan = thinking, implement = doing เปลี่ยน plan ก่อน implement = `--revise` mode

**Q: ผมอยาก skip plan ทำเลยได้ไหม?**
A: ไม่แนะนำ — `/bda-implement` ต้องการ plan file ที่ `status: approved` ถ้าจริงๆ ต้องการ → ใช้ `/bda-implement --from-fix` (เฉพาะ P3 polish)

**Q: ต้อง read full doc หรือ skim ก็ได้?**
A: **อ่านเต็ม** — Phase 1 บังคับ list ทุก doc ที่อ่านใน plan file (เป็นหลักฐาน)
