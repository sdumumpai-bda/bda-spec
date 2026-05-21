# /bda-analyze

> **Cross-artifact consistency analyzer** — Coverage Summary Table (FR-### → task ID) + findings report (read-only)

[← กลับ usage/README](./README.md) · [Full spec: `commands/bda-analyze.md`](../commands/bda-analyze.md)

## เมื่อไหร่ใช้

- ก่อน `/bda-implement` รอบใหญ่ — มั่นใจว่า FR ทุกข้อ map กับ task
- หลัง `/bda-clarify` — เช็ค consistency หลัง resolve ambiguity
- ก่อน handoff — มี orphan FR ไหม? terminology ตรงกันไหม?
- ผู้บริหารถาม coverage % เท่าไหร่

> **อิงจาก spec-kit `/analyze`** — read-only (ไม่แก้ source)

## Quick start

```
/bda-analyze
```

ตัวอย่าง output (ใน report):
```
Coverage ratio: 83%
Findings: 6 (1 critical, 2 high, 3 medium)
Top risk: FR-002 (Return book) has no plan/task → blocked

| ID | Category | Severity | Location | Summary |
|---|---|---|---|---|
| A001 | Duplication | MEDIUM | FEAT-Checkout vs FEAT-Returns | Both list FN-MemberSearch |
| A003 | Coverage gap | CRITICAL | FR-002 | ไม่มี plan/task รับไป |
```

## รูปแบบเต็ม

```
/bda-analyze                          # project-wide (all open features)
/bda-analyze --feature <slug>         # เฉพาะ feature
/bda-analyze --plan <path>            # เฉพาะ plan
/bda-analyze --severity high          # filter (CRITICAL/HIGH/MED/LOW)
/bda-analyze --max 50                 # max findings (default 50)
/bda-analyze --coverage-only          # แสดง Coverage Summary Table อย่างเดียว
```

| Flag | Default | ใช้สำหรับ |
|---|---|---|
| `--feature <slug>` | all | filter scope |
| `--plan <path>` | n/a | analyze specific plan |
| `--severity <lvl>` | all | filter (CRITICAL/HIGH/MEDIUM/LOW) |
| `--max <N>` | 50 | จำกัด findings count |
| `--coverage-only` | off | skip findings, แสดงแค่ coverage table |

## ขั้นตอนภายใน (Phase summary)

1. **Phase 0** — Resolve scope (project/feature/plan)
2. **Phase 1** — Gather: extract IDs (PRD, FEAT-*, FN-*, FR-###, SC-###, T###, US###), frontmatter, cross-refs, tasks, constitution refs
3. **Phase 2** — Find issues: Coverage Table (FR × plan × task × test) + Findings (6 categories: Duplication, Ambiguity, Coverage gap, Constitution, Underspec, Inconsistency)
4. **Phase 3** — Write report: `docs/95-Handoff/ANALYSIS-<date>-<scope>.md`
5. **Phase 4** — Update `IMPLEMENTATION-STATUS.md` (last analysis, coverage ratio)
6. **Phase 5** — Log checkin

## Output ที่ได้

- `docs/95-Handoff/ANALYSIS-<YYYY-MM-DD>-<scope>.md` — report ใหม่ทุกครั้ง (date-stamped, ไม่ overwrite)
- `docs/00-Index/IMPLEMENTATION-STATUS.md` update (last analysis link, coverage %, outstanding critical)
- Checkin entry

## Findings categories + severity

| Category | ตัวอย่าง |
|---|---|
| Duplication | FR ซ้ำ, function spec ซ้ำ |
| Ambiguity | weasel words ที่ /bda-clarify ยังไม่แก้ |
| Coverage gap | FR ไม่ map กับ task ID (= ORPHAN) |
| Constitution | ขัด STANDARD/policies (เช่น skip test) |
| Underspecification | FR ไม่มี acceptance criteria, function ไม่มี state |
| Inconsistency | terminology mismatch, data model conflict |

| Severity | ความหมาย |
|---|---|
| CRITICAL | blocks implementation, broken assumption |
| HIGH | rework รุนแรง, ขัด policy |
| MEDIUM | quality issue, ควรแก้ก่อน handoff |
| LOW | polish, optional |

## Workflow ที่นิยม

ตัวอย่าง 1: ก่อน implement รอบใหญ่
```
1. /bda-analyze --feature checkout      ← coverage 70%, 2 orphan
2. /bda-plan FR-002 ...                  ← สร้าง plan สำหรับ orphan
3. /bda-analyze --feature checkout      ← coverage 95%, 0 orphan
4. /bda-implement <plans>
```

ตัวอย่าง 2: ก่อน handoff
```
1. /bda-analyze                          ← project-wide
2. (review findings → /bda-doc / /bda-clarify แก้ก่อน)
3. /bda-verify                           ← handoff report
```

ตัวอย่าง 3: ดูแค่ coverage table
```
/bda-analyze --coverage-only
  → quick view: FR coverage % ของแต่ละ feature
```

## Gotchas / ข้อควรระวัง

- 🚫 **ห้ามแก้ source artifact ใดๆ** — analyze read-only
- 🚫 ห้าม invent FR ที่ไม่มีจริง — ถ้า doc prose → flag underspec ไม่สร้าง FR-### เอง
- 🚫 ห้าม mark "covered" ถ้า task ไม่มี ID link ชัด — ใส่ `PARTIAL` แทน
- 🚫 ห้าม include suggestion ที่ไม่ cite source artifact
- 🚫 ห้าม overwrite ANALYSIS report เก่า — ใหม่ทุกครั้งเป็นไฟล์ใหม่ date-stamped
- 💡 Output **คือ report file** — ไม่ใช่ตอบในแชต ดูที่ `docs/95-Handoff/ANALYSIS-*.md`
- 💡 ทุก finding มี Recommendation → action ที่ใช้ command อื่นได้

## Related

- ก่อน `/bda-analyze`: [/bda-new](./bda-new.md), [/bda-plan](./bda-plan.md), [/bda-doc](./bda-doc.md) (มี artifact ให้ analyze)
- หลัง findings: [/bda-clarify](./bda-clarify.md) (ambiguity), [/bda-doc](./bda-doc.md) (underspec), [/bda-plan](./bda-plan.md) (coverage gap)
- Pair กับ: [/bda-checklist](./bda-checklist.md) (spec quality test)
- Vault path: `docs/95-Handoff/ANALYSIS-*.md`

## FAQ

**Q: Coverage ratio คำนวณยังไง?**
A: `(FR ที่มี task ID มัด) / (total FR)` — orphan + partial นับว่าไม่ covered

**Q: ทำไม `/bda-analyze` ไม่ fix ให้ฉันเลย?**
A: Read-only ตามหลักการ source-of-truth — แก้ผ่าน `/bda-doc`, `/bda-clarify`, `/bda-plan` แทน

**Q: เรียก /bda-analyze บ่อยแค่ไหน?**
A: หลัง major change (new feature, refactor PRD) + ก่อน handoff อย่างน้อย 1 ครั้ง
