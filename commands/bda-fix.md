---
description: Diagnose bug + create fix-log with evidence trail (no code change)
model: claude-sonnet-4-6
---

<!--
BDA Standard v0.7.0 alignment (matches `commands/fix-bug.md` + `workflows/obsidian.md`):
- Read Obsidian context manifest FIRST
- Append root cause + fix summary + regression check + evidence to active session note
- Reference `standards/templates/obsidian-work-note.md` ใน "BDA Standard files used"
-->


# /bda-fix — Diagnose bug (ไม่แก้โค้ด)

วินิจฉัย + เตรียม fix-log + เก็บ before evidence เท่านั้น
**code change ทั้งหมดต้องผ่าน `/bda-implement`** — ห้ามแก้ตรงๆ ใน /bda-fix

## Trigger

```
/bda-fix <bug description>
/bda-fix <bug> --update docs/obsidian-vault/85-FixLog/YYYY-MM-DD-HHMM-<slug>.md
```

ว่าง → ถาม "บั๊กอะไร?"

## Phase 1 — Detect mode

| Arg | Mode |
|---|---|
| free text | **New** fix-log |
| `--update <path>` | **Append** section ใน existing fix-log |

## Phase 2 — Diagnose (read-only)

ก่อนเขียนไฟล์:
1. ระบุ submodule/area (api / web / mobile / cross)
2. Reproduce ถ้าทำได้ (start dev server เท่าที่จำเป็น; preferred: read code)
3. หา root cause ผ่าน grep/Read — **ห้ามแก้โค้ด**
4. ร่าง fix approach + test cases ที่จะพิสูจน์ว่า bug หาย

Bug ไม่ชัด → ถาม 1-3 คำถาม **ใน message เดียว**

## Phase 3 — สร้าง fix-log

Path: `docs/obsidian-vault/85-FixLog/YYYY-MM-DD-HHMM-<slug>.md`

```markdown
---
tags: [type/fix-log]
date: YYYY-MM-DD HH:mm
title: <one-line bug title>
status: in-progress         # in-progress | fixed | wont-fix | regressed
severity: P1                # P0 blocker | P1 major | P2 minor | P3 polish
area: <api | web | mobile | cross>
reported_by: <user | qa | self | customer>
related_plan: <path or none>
---

# <Bug title>

## Symptom
<what user sees / what's broken>

## Reproduction
1. <step 1>
2. <step 2>
3. <expected vs actual>

## Root Cause
<technical cause — file path, function, line — from grep/read>

## Vault Context Read
- docs/obsidian-vault/40-Functions/FN-<related>.md
- docs/obsidian-vault/70-Reference/REF-AuthorizationMatrix.md (ถ้าเกี่ยว auth)
- docs/obsidian-vault/85-FixLog/<previous-similar>.md (ถ้าเคยมี regression)

## Before Evidence
- Error log: <path or paste>
- Screenshot: docs/obsidian-vault/90-TestPlan/evidence/<slug>/before.png (ถ้ามี)
- Console output: <paste>

## Fix Approach
<paragraph อธิบาย fix ที่จะทำ — ยังไม่ใช่โค้ด>

## Affected Files
- `path/file1.ts` — <what to change>
- `path/file2.ts` — <what to change>

## Test Cases (เพื่อพิสูจน์ว่า fix ใช้ได้)
- [ ] Test 1: <scenario>
- [ ] Test 2: <scenario>
- [ ] Regression test: <scenario>

## Risk
- ความเสี่ยงของ fix นี้ + mitigation

## Next
- [ ] รัน `/bda-plan` หรือสร้าง mini-plan ที่ link มาที่นี่
- [ ] รัน `/bda-implement <plan-path>` เพื่อแก้จริง
- [ ] หลัง fix: update status: fixed + เก็บ after evidence
```

## Phase 4 — Auto-link plan

หลังสร้าง fix-log → เสนอ:

> Fix-log สร้างแล้ว: `docs/obsidian-vault/85-FixLog/2026-05-20-1530-search-not-returning-results.md`
>
> ตัวเลือก:
> - **A)** สร้าง implement plan จาก fix-log นี้: `/bda-plan fix:<slug>` → จะ pre-fill plan จาก fix-log
> - **B)** บั๊กเล็ก ข้าม plan ไปเลย: `/bda-implement --from-fix <fix-log-path>` (ใช้สำหรับ P3 polish เท่านั้น)
> - **C)** บั๊กยังไม่ urgent — ปิดไว้ก่อน status: in-progress

## Phase 5 — Update mode (`--update`)

อ่าน existing fix-log → append section ใหม่:
- Investigation update
- New evidence
- Status change (เช่น `in-progress` → `regressed` พร้อม reason)

ไม่ overwrite ของเดิม

## Phase 6 — Log checkin

```markdown
- HH:MM — [type/fix-diagnose] Created fix-log: <slug> (severity: P1, area: web)
```

## Output (5 หัวข้อบังคับ)

1. **BDA Standard files used** — `standards/STANDARD.md`, fix-log template
2. **Pipeline trace** — Understand (Phase 2 diagnose) → Plan (Phase 3 fix-log = plan output) → Execute (none — diagnose only) → Verify (root cause confirmation) → Handoff (Phase 4 next-step menu)
3. **Commands run** — grep, Read of source files, `git log -S <symbol>`, etc.
4. **Verification / Evidence** — paths ของ source files ที่ confirm root cause + before evidence
5. **Limitations / Risks / Next steps** — "Fix ยังไม่ทำ — รัน /bda-implement หลัง approve", risk section จาก fix-log

## ห้าม

- ห้ามแก้โค้ดใน /bda-fix
- ห้ามเดา root cause โดยไม่ verify ที่ source
- ห้ามแต่ง error message หรือ stack trace
