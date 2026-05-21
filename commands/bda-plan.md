---
description: Vault-first research + create implementation plan file (no code touch)
model: claude-sonnet-4-6
---

<!--
BDA Standard v0.7.0 alignment (matches `commands/plan-work.md` + `workflows/obsidian.md`):
- Read Obsidian context manifest (00-Agent-Context.md → bda-spec: IMPLEMENTATION-STATUS.md) FIRST
- Include target Obsidian session/evidence note path in the plan when relevant
- Reference `standards/templates/obsidian-context.md` ใน "BDA Standard files used"
-->


# /bda-plan — Plan a task (no code)

อ่าน vault → clarify → สร้าง plan file → **หยุดก่อนแก้โค้ดเสมอ**

## Trigger

```
/bda-plan <task description>
/bda-plan <task> --revise docs/80-ImplementPlan/YYYY-MM-DD-HHmm-<slug>.md
```

ว่าง → ถาม "วางแผนงานอะไร?"

## `--revise` mode

1. Read existing plan file
2. Re-run Phase 1 (vault อาจเปลี่ยน)
3. Skip Phase 2 ถ้า task description ไม่เปลี่ยน
4. **Update in-place** — ไม่สร้างไฟล์ใหม่
5. แสดง diff → STOP รอ user review

## Phase 1 — อ่าน vault context (บังคับ)

1. อ่าน `docs/00-Index/IMPLEMENTATION-STATUS.md`
2. อ่านเอกสารที่เกี่ยวกับ task:
   - Feature/PRD → `docs/10-PRD/PRD-*.md` + `docs/20-Features/FEAT-*.md`
   - Role/menu → `docs/30-Roles/`
   - Function/API → `docs/40-Functions/`
   - Phase task → `docs/50-Phases/PHASE-*.md`
   - Flow → `docs/60-Flows/`
   - Auth → `docs/70-Reference/REF-AuthorizationMatrix.md`
   - API contracts → `docs/70-Reference/REF-APIIntegration.md`
   - Tech stack → `docs/70-Reference/REF-TechStack.md`
   - **Design system** → `docs/70-Reference/DesignSystem/` (ถ้ามี — บังคับ frontend/mobile ใช้)
3. อ่านทุก doc ที่เกี่ยวข้องเต็มๆ (ไม่ใช่แค่ skim)
4. List ทุก doc ใน plan file (เป็นหลักฐาน)

> **Vault ตอบอยู่แล้ว → ห้ามถาม user ใหม่**

## Phase 2 — Clarifying questions (1 batch)

หลังอ่าน vault, ถามคำถามทั้งหมด **ในข้อความเดียว** ห้ามทยอย

ถามเฉพาะที่ vault ไม่ตอบ:
- Roles ที่เกี่ยวข้อง?
- Edge cases นอกเหนือ spec?
- Submodule scope (api / web / mobile / all)?
- Constraints (deadline, ต้อง reuse component ไหน, ฯลฯ)?
- Design system ยังต้องเพิ่ม component ใหม่ไหม?

## Phase 3 — สร้าง plan file

Path: `docs/80-ImplementPlan/YYYY-MM-DD-HHmm-<slug>.md`

(slug = kebab-case, ≤ 5 คำ)

Template:
```markdown
---
tags: [type/plan]
date: YYYY-MM-DD HH:mm
title: <one-line task title>
status: planning            # planning | approved | in-progress | done | abandoned
submodule_target: <api | web | mobile | docs | all>
subagent_target: <backend | frontend | mobile | docs | design | all>
related_docs:
  - docs/10-PRD/PRD-xxx.md
  - docs/20-Features/FEAT-xxx.md
  - docs/40-Functions/FN-xxx.md
estimate_hours: <number>
risk_level: <low | medium | high>
---

# <Task title>

## Vault Context Read
- docs/00-Index/IMPLEMENTATION-STATUS.md
- docs/10-PRD/PRD-xxx.md (section: ...)
- docs/20-Features/FEAT-xxx.md (FR-001, FR-002)
- docs/40-Functions/FN-xxx.md
- docs/70-Reference/REF-TechStack.md
- docs/70-Reference/DesignSystem/DS-Components.md  ← ถ้า frontend/mobile

## Task
<clear one-paragraph task description>

## Goals
- [ ] Goal 1
- [ ] Goal 2

## Non-goals
- ทำอะไรที่ **จะไม่ทำ** ใน plan นี้

## Doc Gaps Found
- (ถ้าเจอ vault inconsistent ระหว่างอ่าน list ที่นี่ — /bda-implement จะ fix ก่อน)

## Affected Files
- `path/to/file1.ts` — <what changes>
- `path/to/file2.tsx` — <what changes>

## Implementation Steps
1. <step 1 — กึ่ง declarative ไม่ใส่โค้ดยาว>
2. <step 2>
3. <step 3>
... (5-15 steps for medium task; 3-5 for small)

## Design System Compliance (ถ้า frontend/mobile)
- [ ] ใช้ tokens จาก `DS-Tokens.md` เท่านั้น (สี/font/spacing)
- [ ] ใช้ components จาก `DS-Components.md` (Button, Input, ฯลฯ)
- [ ] ถ้าต้อง component ใหม่ → log ใน "Design Additions" ก่อน
- [ ] WCAG AA contrast ผ่านทุก state

## Design Additions (ถ้ามี)
- <New component or token ที่ต้องเพิ่ม — จะ trigger /bda-design ก่อน /bda-implement>

## Test Plan
- [ ] Unit tests สำหรับ <X>
- [ ] Integration tests สำหรับ <Y>
- [ ] Manual checks: <list scenarios>

## Verification
- เกณฑ์ pass ของ plan นี้ (acceptance criteria เชิงรูปธรรม)

## Risks
- <risk 1> → mitigation: <plan>
- <risk 2> → mitigation: <plan>

## Approvals
- [ ] Requested by: <user>
- [ ] Reviewed by: <reviewer>
- [ ] Approved (set status: approved before /bda-implement)
```

## Phase 4 — Doc gap detection

ระหว่าง Phase 1, ถ้าเจอ:
- Doc ที่กล่าวถึงใน PRD แต่ไม่มีไฟล์
- ข้อมูล contradict ระหว่าง docs (เช่น role A ใน PRD ไม่ตรงกับ AuthorizationMatrix)
- Function spec ที่ทำงานเกี่ยวข้องแต่ยังไม่มี

→ List ใน `Doc Gaps Found` ของ plan file
→ Plan file ระบุว่า `/bda-implement` จะเรียก `docs` subagent มา fix ก่อน

## Phase 5 — STOP

แสดง plan file ที่สร้าง + ข้อความ:

> Plan สร้างเสร็จ: `docs/80-ImplementPlan/2026-05-20-1430-add-search-feature.md`
>
> ขั้นต่อไป:
> - Review plan + set `status: approved` ใน frontmatter
> - แก้/เพิ่ม → `/bda-plan <task> --revise <path>`
> - Approve แล้ว → `/bda-implement <path>`

**ห้าม** /bda-plan เริ่ม implement เอง

## Phase 6 — Log checkin

เพิ่ม entry ใน `docs/75-Checkins/<today>.md`:

```markdown
- HH:MM — [type/plan] Created plan: 2026-05-20-1430-add-search-feature.md (status: planning)
```

## Output (5 หัวข้อบังคับ)

1. **BDA Standard files used** — `standards/STANDARD.md`, plan template
2. **Pipeline trace** — Understand (Phase 1 read vault) → Plan (Phase 2-3 ถาม + เขียน) → Execute (Phase 3 write plan file only) → Verify (file exists check) → Handoff (Phase 5 STOP message)
3. **Commands run** — Read of vault docs, Write of plan file
4. **Verification / Evidence** — plan file path + list of vault docs read
5. **Limitations / Risks / Next steps** — risks section จาก plan + "ต้อง approve ก่อน /bda-implement"

## ห้าม

- ห้ามแก้โค้ด ห้ามรัน build/test/lint ใน /bda-plan
- ห้าม spawn subagent — plan file เป็น text only
- ห้าม set `status: approved` ให้ user — user ต้องทำเอง
