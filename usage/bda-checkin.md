# /bda-checkin

> **Daily executive check-in** — morning/midday/note/end ใน 1 ไฟล์/วัน · v5 schema · รวบรวม 7 แหล่งข้อมูล

[← กลับ usage/README](./README.md) · [Full spec: `.bda-spec/commands/bda-checkin.md`](../.bda-spec/commands/bda-checkin.md)

## เมื่อไหร่ใช้

- เช้า — ตั้ง goals 3-5
- เที่ยง — progress check
- ระหว่างวัน — quick capture (meeting, test, review)
- ก่อนเลิก — executive summary (commits + evidence + AI usage + carry-over)
- ผู้บริหารต้องการ daily report

> **bda-spec extension** — BDA v0.7.0 ลบ daily-log ออก, bda-spec เก็บไว้สำหรับ executive reporting

## Quick start

```
/bda-checkin morning
```

ตอนเช้า → batch 3 คำถาม:
```
1. Top 3 outcomes ที่อยากได้สิ้นวัน
2. Blockers / dependencies ที่อาจขัด
3. Hard meetings / deadlines วันนี้
```

## รูปแบบเต็ม

```
/bda-checkin                 # auto-detect ช่วงเวลา
/bda-checkin morning         # บังคับ section
/bda-checkin midday
/bda-checkin note            # quick capture (multiple/วัน)
/bda-checkin note meeting "ประชุม UX"
/bda-checkin end             # end-of-day executive log
/bda-checkin show            # แสดง checkin วันนี้
```

| Section | Time hint | What |
|---|---|---|
| `morning` | ก่อน 11:00 | Goals + blockers + meetings + carry-over จากเมื่อวาน |
| `midday` | 11:00-15:00 | Progress (done/partial/not-started) + direction change + afternoon focus |
| `note` | ตลอดวัน | Timestamped quick capture (meeting/test/review/doc/call/other) |
| `end` | หลัง 18:00 | Executive summary + AI usage + carry-over to tomorrow |
| `show` | n/a | display only |

## ขั้นตอนภายใน (Phase summary)

1. **Phase 0** — Resolve config + detect ช่วงเวลา + suggest section
2. **Phase 1** — สร้างไฟล์ `docs/obsidian-vault/75-Checkins/<YYYY-MM-DD>.md` (ถ้ายังไม่มี)
3. **Phase 2** — Morning: gather context (เมื่อวาน carry-over, in-progress plan/fix) → batch 3 questions → fill section 1
4. **Phase 3** — Midday: read morning + git activity → batch 3 questions → fill section 2
5. **Phase 4** — Note: append timestamped entry (ไม่ overwrite)
6. **Phase 5** — **End-of-day**: รวบรวม **7 data sources** (5.1a-5.1g) → fill section 4+5 → set `status: closed` → mirror (optional)
7. **Phase 6** — Show mode

## End-of-day: 7 data sources

| Source | What |
|---|---|
| 5.1a — Git commits | main + submodules, repo URL/branch, author filter |
| 5.1b — Vault files today | checkin, plans/fix-logs ที่เริ่ม/แก้วันนี้ |
| 5.1c — Evidence manifests | screenshots/logs/traces ที่ touched วันนี้ |
| 5.1d — No-Fake Gate | 5 cross-checks (goal coverage, status vs evidence, artifacts, commits verifiable, screenshots exist) |
| 5.1e — Remaining Work scan | `50-Phases/` checkbox progress (Forecast เท่านั้น — ห้าม dump) |
| 5.1f — AI token usage | `ccusage daily` × 2 (project + all-projects) |
| 5.1g — Evidence GDrive links | จาก `/bda-upload` → ใส่ใน Section 9 |

## Output ที่ได้

```
docs/obsidian-vault/75-Checkins/<YYYY-MM-DD>.md   ← 1 ไฟล์/วัน, 5 sections

Section 1. Morning — Goals & Plan
Section 2. Midday — Progress
Section 3. Notes (timestamped)
Section 4. End-of-day — Executive Summary
Section 5. Carry-over to Tomorrow

Frontmatter: status (open/closed), ai_used, ai_tokens_input/output, ai_cost_usd
```

Mirror (ถ้า set `daily_log_mirror`):
- `<DAILY_MIRROR>/<YYYY-MM-DD>-<project-slug>.md`

## Workflow ที่นิยม

ตัวอย่าง 1: daily rhythm
```
09:00  /bda-checkin morning              ← top 3 outcomes
11:30  /bda-checkin note meeting "stand-up"
13:00  /bda-checkin midday               ← progress check
15:00  /bda-checkin note test "manual login test"
17:30  /bda-checkin end                  ← executive summary
                                         → mirror ไป daily_log_mirror
```

ตัวอย่าง 2: end-of-day chain
```
1. /bda-evidence (curate วันนี้)
2. /bda-upload --pending                 ← share GDrive
3. /bda-checkin end                      ← link จาก manifest อัตโนมัติ
```

ตัวอย่าง 3: quick note
```
/bda-checkin note review "PR #45 approved with 2 comments"
  → append: HH:MM [review] PR #45 — approved with 2 comments
```

## Note types

| Keyword | ตัวอย่าง |
|---|---|
| `meeting` | "ประชุม UAT กับ stakeholder" |
| `test` | "ทดสอบ login flow บน mobile" |
| `review` | "ตรวจ PR #45" |
| `doc` | "เขียน test plan ฟีเจอร์ใหม่" |
| `call` | "คุยกับ vendor" |
| `other` | "รออนุมัติ" |

## Gotchas / ข้อควรระวัง

- 🚫 **ห้ามแต่ง commits/plans/fixes** ที่ user ไม่ได้ทำจริง (5.1d No-Fake Gate จะ flag)
- 🚫 **ห้ามแต่ง token count, cost** — ถ้าไม่รู้ ระบุ "self-reported" หรือ "not tracked"
- 🚫 ห้าม overwrite section ที่ filled แล้วโดยไม่ confirm
- 🚫 **ห้าม dump Remaining Work list ลง checkin** — ใช้ผลแค่ Section 10 Forecast
- ⚠️ Mirror = personal path (`.bda-spec.local.yml`) — ไม่ใช่ team config
- ⚠️ ทุก path อ้างจาก `$VAULT_PATH` config — ห้าม hardcode `docs/`
- 💡 `note` append หลายครั้งต่อวันได้
- 💡 `end` รัน No-Fake Gate 5 cross-checks — fail → `validation_status: warning`

## Related

- ก่อน `/bda-checkin end`: [/bda-upload](./bda-upload.md) (มี gdrive_link), [/bda-implement](./bda-implement.md) (plan status updates)
- หลัง `/bda-checkin end`: mirror file ส่งให้ผู้บริหาร / `git push` ไป repo
- Template: `.bda-spec/templates/daily-log-v5.md` (จาก thai-cleft)
- Vault path: `docs/obsidian-vault/75-Checkins/`

## FAQ

**Q: ถ้าลืม `/bda-checkin morning` ไปแล้ว — ทำตอน midday ได้ไหม?**
A: ได้ — `/bda-checkin morning` ใช้ได้ทุกเวลา (time-of-day suggestion เป็นแค่ hint)

**Q: ทำไม `end` ต้องรวบรวม 7 sources?**
A: ผู้บริหาร/audit ต้องการ traceability — ทุก outcome ต้อง map กับ commit/plan/evidence จริง (No-Fake Gate)

**Q: ถ้า `ccusage` ไม่ติดตั้ง?**
A: ใช้ self-report (`/bda-checkin end` จะถามทีหลังใน Phase 5.2) — token = "unknown" ใน frontmatter
