---
description: Taxonomy-driven ambiguity scan + 1-at-a-time question with recommended answer → write Clarifications log back into spec
model: claude-sonnet-4-6
---

# /bda-clarify — Ambiguity Scan (1-at-a-time)

Scan spec/plan/PRD แล้วถามคำถามทีละข้อ (max 5) พร้อม **Recommended answer** เพื่อลด decision fatigue
เขียน answers กลับเข้า doc เป็น `## Clarifications > ### Session YYYY-MM-DD` block

> **inspired by:** spec-kit `/clarify`

## Trigger

```
/bda-clarify                          # scan latest active plan
/bda-clarify <path-to-doc>            # scan specific doc (PRD/SRS/FEAT/plan/etc.)
/bda-clarify --feature <slug>         # scan all docs of a feature
/bda-clarify --max 3                  # override max questions (default: 5)
/bda-clarify --resume                 # continue session ที่ค้าง
```

## Phase 0 — Resolve target

```bash
# Use scripts/bda-paths.sh if available
eval "$(bash scripts/bda-paths.sh --shell)"

if [ -z "$ARGUMENTS" ]; then
  # default: latest plan in 80-ImplementPlan with status: planning|approved
  TARGET=$(ls -t "$VAULT_PATH/80-ImplementPlan"/*.md 2>/dev/null | head -1)
fi
test -f "$TARGET" || echo "target not found"
```

แสดง user:
> จะ scan: `<TARGET>`
> ประเภท: PRD / SRS / Feature / Plan / Function / Fix-log
> Existing clarifications: <N> session(s)
> ดำเนินการต่อ?

## Phase 1 — Taxonomy scan (read-only)

ตรวจ ambiguity ตาม 9 หมวด (จาก spec-kit):

| Category | ตัวอย่าง ambiguity ที่หา |
|---|---|
| **1. Functional Scope** | "support multiple X" — กี่ตัว? ทุกประเภท? |
| **2. Domain & Data** | "user" — role ไหน? "order" — schema มีอะไร? |
| **3. UX / Behavior** | "show notification" — modal/toast/banner? auto-dismiss? |
| **4. Non-functional Requirements** | "fast" — กี่ ms? "secure" — threat model ไหน? |
| **5. Integration** | "send to API" — endpoint? auth? retry? |
| **6. Edge Cases** | empty state, network fail, concurrent edit, permission denied |
| **7. Constraints** | budget, deadline, team size, must-reuse |
| **8. Terminology** | "member" vs "user" vs "account" ใช้ตัวไหน |
| **9. Completion / DoD** | "done" หมายถึง? — code merged? deployed? approved? |

สำหรับแต่ละหมวด:
1. Grep target doc + linked docs (frontmatter `related:` + wikilinks)
2. หา weasel words: "should", "could", "may", "fast", "many", "appropriate", "TBD", "?"
3. หา `[NEEDS CLARIFICATION]` markers
4. รวม candidate questions

ลด list → **max 5 คำถาม** เลือกตาม:
- Severity (Critical > High > Medium)
- Block downstream (เช่น affect data model หรือ API contract)
- Cheap to answer (1 sentence)

## Phase 2 — Ask 1 question at a time

**ห้าม batch** — ถามทีละข้อ (ต่างจาก /bda-new และ /bda-plan ที่ batch)

Format ของแต่ละคำถาม:

```markdown
🔍 Clarification 2/5 — Category: UX / Behavior

**Question:**
เมื่อ checkout สำเร็จ ระบบควรแสดงผลแบบไหน?

**Options:**
  A) Toast (auto-dismiss 3 วินาที) — discrete, ไม่ block flow
  B) Modal dialog (user ต้องคลิก close) — explicit confirmation
  C) Inline message ใน page เดิม — เหมาะ embedded flow
  D) Redirect ไป /checkout/success page — ครบสุด มี receipt

**Recommended:** B) Modal dialog
**Reasoning:** Librarian ต้องการ explicit confirmation ก่อน proceed; matches DS-Components Modal pattern; aligned with FN-Web-Lib-Checkout state diagram.

**Your answer:** [A/B/C/D หรือ ข้อความอื่น]
```

User ตอบ → record + ไป question ถัดไป

ถ้า user ตอบ "skip" หรือ "TBD" → record เป็น `[DEFERRED]` ใน Clarifications log

## Phase 3 — Write back to source doc

หลังจบ session (5 คำถาม หรือ user หยุดก่อน):

```markdown
<!-- ที่ source doc — เพิ่ม section ก่อน "Acceptance Criteria" -->

## Clarifications

### Session 2026-05-21

- **Q1 (UX):** Toast vs modal สำหรับ checkout success? **A:** Modal (recommended). Reasoning: explicit confirmation needed.
- **Q2 (Edge):** Behavior เมื่อ network fail ระหว่าง checkout? **A:** Show inline error + retry button; keep form state.
- **Q3 (NFR):** Acceptable checkout latency? **A:** p95 ≤ 800ms.
- **Q4 (Domain):** "Overdue" definition — ตาม due_date ปกติ หรือ business day? **A:** Calendar day (grace period 1 day weekend).
- **Q5 (Terminology):** "Member" vs "Patron" — ใช้ตัวไหน? **A:** Member (consistent กับ PRD glossary).
```

ถ้ามี `## Clarifications` อยู่แล้ว → append `### Session <today>` ใหม่ (ไม่ทับเก่า)

## Phase 4 — Update affected docs

ถ้า answer มีผลต่อ:
- **Data model** → flag ใน plan: "data-model.md needs update (Q4)"
- **API contract** → flag in REF-APIIntegration.md
- **DS component** → flag if new variant needed
- **FR list** → suggest FR-### addition/refinement

ไม่แก้ docs อื่นเอง — แค่ **flag** ให้ user รัน `/bda-doc` หรือ `/bda-plan --revise`

## Phase 5 — Log + handoff

Append ใน `docs/obsidian-vault/75-Checkins/<today>.md` Notes:
```
- HH:MM — [type/clarify] /bda-clarify on <target> — 5 questions resolved (1 deferred); affected: <link list>
```

Update IMPLEMENTATION-STATUS.md ถ้า target ของ doc เปลี่ยน status (เช่น planning → approved-pending-update)

## Phase 6 — Next-step suggestion

> ✅ Clarifications saved → `<target>`
>
> Next:
>   • Revise plan: `/bda-plan --revise <target>`
>   • Re-analyze: `/bda-analyze --feature <slug>` (check consistency)
>   • If data-model changed: `/bda-doc data-model <feature>`
>   • If unblocked: `/bda-implement <plan>` (only if status: approved)

## Output (5 หัวข้อบังคับ)

1. **BDA Standard files used** — `standards/STANDARD.md`, `standards/policies/source-of-truth.md`
2. **Pipeline trace** — Understand (Phase 0/1) → Plan (taxonomy filter) → Execute (Phase 2/3) → Verify (Phase 4 affected-docs check) → Handoff (Phase 5 log)
3. **Commands run** — grep weasel words, Read target + linked, Write append
4. **Verification / Evidence** — answer log path + count of clarifications added + affected-docs list
5. **Limitations / Risks / Next steps** — deferred questions, downstream docs ต้อง revise

## ห้าม

- ห้าม batch คำถาม — **ทีละข้อเท่านั้น**
- ห้ามให้คำตอบ recommended ที่ไม่อิง vault content (ต้อง cite ทุก reasoning ด้วย link ไป doc/section)
- ห้ามแก้ source doc นอก `## Clarifications` section — ไม่แตะ FR, Goals, etc.
- ห้ามถามคำถามที่ vault ตอบอยู่แล้ว — Phase 1 ต้อง filter ออกก่อน
- ห้ามแก้ doc อื่นๆ — แค่ flag เท่านั้น
- ห้าม invent option ที่ unrealistic — ถ้าไม่รู้ → ใส่แค่ 2 options + "[OTHER]" ให้ user พิมพ์เอง
