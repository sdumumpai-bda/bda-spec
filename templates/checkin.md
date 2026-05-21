<!--
═══════════════════════════════════════════════════════════════════════════════
  Daily Check-in Template (BDA Daily Log v5 schema, adapted for bda-spec)
═══════════════════════════════════════════════════════════════════════════════
  ใช้กับ /bda-checkin (1 file ต่อวัน — append section ตามช่วงเวลา)
  Override ของ standards/templates/checkin.md (lookup chain: local → project → standards)

  Origin: ดัดแปลงจาก thai-cleft .claude/commands/daily-log.md template (v5)
  ────────────────────────────────────────────────────────────────────────────
  Placeholders:
    <YYYY-MM-DD>, <name>, <role>, <project_slug>, <customer>, <repo_url>,
    <branch>, <submodule>, <ai_model>, <int>, <iso8601>
  ════════════════════════════════════════════════════════════════════════════
-->

---
# Identity
date: <YYYY-MM-DD>
name: "<full name>"
role: "<Dev / PM / QA / Designer / etc.>"
project: "<project_slug>"
customer: "<customer org name or 'internal'>"
source: "manual"                 # manual | ai-assisted

# Repo (เติมจาก git remote)
repo: "<main remote URL>"
repo_bda: "<BDA shared repo if any>"
branch: "<main branch>"
dev: "<dev name>"
commits_count: <int — total commits ทั้งวัน ทุก repo>
hours: 8

# Multi-submodule (ถ้ามี — duplicate per submodule)
submodules:
  # api:    { branch: "<branch>", remote: "<url>" }
  # web:    { branch: "<branch>", remote: "<url>" }
  # mobile: { branch: "<branch>", remote: "<url>" }

# Canonical flag
canonical_daily_log: true
log_version: "v5"

# Workflow state
status: "draft"                  # draft | submitted | verified
written_at: "<ISO-8601 timestamp +07:00 — เติมตอน end-of-day>"
timezone: "Asia/Bangkok"

# AI usage (เติมตอน end-of-day)
ai_usage_level: "none"           # none | low | medium | high
ai_tool: "Claude Code"
ai_model: "<merged from ccusage modelsUsed[] or self-report>"
ai_input_tokens: 0
ai_output_tokens: 0
ai_cache_read_tokens: 0
ai_cache_write_tokens: 0
ai_total_tokens: 0
daily_ai_total_tokens: 0         # all projects (จาก ccusage no-filter)
hit_ai_limit: false
ai_usage_notes: "<used for / human verification / AI limitations>"

# Validation
validation_status: "self-checked"
human_verified_by: "<name>"
human_verified_at: "<ISO-8601 timestamp +07:00>"

# Tags
tags: [type/checkin, daily-log/v5]
---

# Daily Check-in — <YYYY-MM-DD>

<!-- /bda-checkin จะ append/update sections ตามช่วงเวลา:
     - morning  → กรอก Section 2 (Today's Goal) + 0 (Morning notes)
     - midday   → กรอก Section 4 (In Progress) preview + 5 (Blockers) preview
     - note     → append timestamped entries ใน Section 0 Notes
     - end      → กรอก Section 1, 3, 6-13 (executive summary)
-->

## 0 Morning notes / Midday adjustments / Day notes
<!-- timestamped entries ระหว่างวัน (meeting, manual test, review, etc.) -->
<!-- /bda-checkin note → append ที่นี่ -->

- HH:MM — morning standup — goals set: [G1, G2, G3]
- HH:MM — [meeting] ...
- HH:MM — [manual-test] ...
- HH:MM — midday check — progress: [G1 ✅, G2 🟡, G3 not started]

## 1 Summary
<!-- AI draft จาก morning goals + commits + midday — user confirm Overall status -->

- Main focus today: <จาก morning's goals หรือ derived from commits>
- Overall status: <🟢 Green / 🟡 Yellow / 🔴 Red>
- Key outcome: <1-2 บรรทัด สิ่งที่ได้จริงวันนี้>
- Biggest risk/blocker: <จาก midday blockers หรือ "none">

## 2 Today's Goal
<!-- จาก morning checkin หรือ derive จาก commits — append status ต่อท้ายแต่ละข้อ -->

1. <goal 1> — ✅ done · [[<plan-slug>]] + `<commit-hash>`
2. <goal 2> — 🟡 partial · <reason>
3. <goal 3> — 🔴 not-done · <blocker หรือ "deferred to <date>">

## 3 Done with Evidence

### Commit log (cross-repo, ascending time)
<!-- 1 row = 1 commit. Files = "+A −D files" จาก `--stat`. ห้ามแต่ง — paste ตรงจาก git log -->

| Time  | Module | Commit | Summary | Files | Evidence |
|-------|--------|--------|---------|-------|----------|
| HH:MM | <repo> | [`<sha7>`](<commit-url>) | <commit subject> | N files · +A −D | [[<plan-slug>]] / TC-XX |

> Total: **N commits · M modules**

### Per-task breakdown
<!-- 1 bullet = 1 feature/bug/task (group commits by plan/fix slug) -->
<!-- Fallback: commit ที่ไม่ match slug ใด → 1 bullet/commit, ไม่มี Verification -->

- Task: <task / feature / bug title — จาก plan/fix `task:` หรือ commit subject>
  - Requested by: <PM / Customer / Sales / Self / team routine / unknown — จาก plan `requested_by:`>
  - Task type: <Focus / Adhoc / Support — จาก plan `task_type:` (default: Focus)>
  - Priority: <P0 / P1 / P2 / unknown — จาก plan `priority:` (default: P1)>
  - Status: <Done / In Progress / Blocked / Deferred / Cancelled>
  - What changed / output: <1 ประโยค — code/feature/fix>
  - Evidence: commits `<sha7>`, `<sha7>` ([github](url)), [[<plan-slug>]], [GDrive folder](<gdrive-link>)
  - Verification: <not required / pending review by <name> / verified by <name> on YYYY-MM-DD / "Build pass · Test 23/23 · Review pending">
  - Files/Area: <module + paths — เช่น `web/src/pages/*.vue`, `api/Modules/**`>
  - Outcome/Impact: <ผู้ใช้/ระบบ/ทีมได้อะไร — 1 ประโยค>
  - Owner/Reviewer: <name> / <self / QA pending / PM acknowledged>
  - Blocker/Escalation: <none / blocker detail + escalation target>
  - Next action: <none / next action — จาก plan unchecked [ ] ตัวแรก>

## 4 In Progress / Carry Over

- Task: <in-progress task>
  - Current state: <% done หรือ "draft / WIP / awaiting review">
  - Remaining work: <งานที่เหลือ>
  - Expected completion: <YYYY-MM-DD / unknown>
  - Confidence: <high / medium / low>
  - Branch: <branch name>
  - Evidence so far: <commits/PRs/screenshots ที่ทำไปแล้ว>
  - Next step: <next action>
  - Waiting on: <Self / Dev / QA / PM / Customer / Vendor / None>

<!-- "-" ถ้าไม่มี in-progress — ห้ามลบ section -->

## 5 Blockers / Escalations

- Blocker: <blocker / risk>
  - Impact: <ผลกระทบต่อ delivery / deadline>
  - Needed from: <ใคร / ทีมอะไร>
  - Deadline / escalation time: <YYYY-MM-DD HH:mm / "ก่อน PM review">
  - Evidence/context: <link / วิธีอ้างอิง>

<!-- "-" ถ้าไม่มี blocker — ห้ามลบ section -->

## 6 Test/Verification

### Summary (ทั้งวัน)
- Build: <Pass / Fail / Not yet / N/A>
- Unit: <X/Y passed — เช่น "api: 45/45 · web: 23/23">
- Integration: <X/Y passed — หรือ N/A>
- E2E: <X/Y passed — หรือ N/A>
- Review: <PR/MR review status — เช่น "PR #12 approved", "N/A">
- Retest needed: <yes/no — reason ถ้า yes>
- Evidence root: <[GDrive root](url) / local path ถ้า fallback>

### Per plan/fix detail
<!-- 1 sub-section ต่อ plan/fix slug — รวม build/unit/int/e2e ของ slug + evidence table -->
<!-- ลำดับ: plans ก่อน fixes; ภายใน group เรียงตาม timestamp ของ commit แรก -->

#### [[<plan-or-fix-slug>]]

- Build: <Pass / Fail / Not yet / N/A> — <BUILD-INFO summary>
- Unit/Integration/E2E: <X/Y per layer — เช่น "Unit 23/23 · Int 5/5 · E2E n/a">
- UI TC: <X/Y passed — จาก MANIFEST.md>

| # | TC | Type | Context (พิสูจน์อะไร) | Result | Link |
|---|----|------|----------------------|--------|------|
| 1 | TC-01 | Screenshot | <ตัวอย่าง: Patient list — initial empty state> | ✅ Pass | [view](<drive-file-url>) |
| 2 | TC-01 | Screenshot | <Create form — valid data> | ✅ Pass | [view](<drive-file-url>) |
| 3 | TC-02 | Before | <Bug repro screenshot> | 🐛 Bug confirmed | [view](<drive-file-url>) |
| 4 | TC-02 | After | <After-fix screenshot> | ✅ Fixed | [view](<drive-file-url>) |

<!-- repeat block สำหรับ plan/fix ถัดไป -->

## 7 Adhoc / Support Summary
<!-- v5 NEW section — สรุปงานที่ไม่ใช่ Focus (Adhoc + Support) แยกออกมาให้ PM เห็นชัด -->

- Adhoc items: <list ของ Adhoc task วันนี้ + ระยะเวลาคร่าวๆ — หรือ "none">
- Support given: <list ของ Support task + non-dev help — หรือ "none">
- Impact on planned focus: <กระทบ Focus ที่วางไว้ตอนเช้ายังไง — เช่น "Adhoc 1 ชม. → goal 3 เลื่อนไปวันพรุ่งนี้" หรือ "ไม่กระทบ">

## 8 AI Usage

- Tool/Model: <ai_tool> / <ai_model>
- Usage level: <none / low / medium / high>
- Project tokens: input <int> · output <int> · cache read <int> · cache write <int> · total <int> · $<cost>
- Daily total tokens: <int from ccusage no-filter>
- Hit limit: <true / false>
- Used for: <ที่ใช้ AI ทำอะไร — code generation, planning, refactor, doc, test scenario, etc.>
- Human verification: <ตรวจสอบยังไง — review diff, run test, manual check, etc.>

## 9 Evidence / Links Collected
<!-- รวม links ทั้งวัน — commits, GDrive, tickets, PRs, vault wikilinks, screenshots -->
<!-- auto-populated จาก Section 3 Evidence fields + Section 6 + /bda-upload result -->

-

## 10 Forecast / Capacity
<!-- v5 — 9 fields -->

- Current Stage: <Active Dev / QA / UAT / Waiting Customer / Delivered / Closed / Unknown>
- Remaining Work Type: <Feature / Bugfix / QA / Support / Doc / None / Unknown>
- Waiting On: <Self / Dev / QA / PM / Customer / Vendor / None / Unknown>
- Expected Next Action Date: <YYYY-MM-DD / unknown>
- Can Take New Work: <Yes / Part-time / No / unknown>
- Available Capacity: <0% / 25% / 50% / 75% / 100% / unknown>
- Confidence: <high / medium / low — ระดับความมั่นใจว่างานจะเสร็จตาม Expected Next Action Date>
- Risk If Reassigned: <Low / Medium / High — เหตุผล>
- Help needed: <สิ่งที่ต้องการจาก PM/Lead/Team — หรือ "none" — auto จาก Section 5 Blocker>

## 11 Decision & Lesson
<!-- user เขียนเอง · "-" ถ้าไม่มี · AI ห้ามเดา -->

- Decision: <ตัดสินใจอะไร>
- Reason: <ทำไม>
- Lesson learned: <เรียนรู้อะไร>

## 12 Questions / Decisions Needed
<!-- คำถาม/decision ที่ต้องการ PM/Lead/Customer ตอบ — หรือ "-" ถ้าไม่มี -->

-

## 13 Performance Score Inputs
<!-- AI draft "เหตุผล" — ไม่ใส่ level/score (PM/Lead ให้ score เอง) -->

- Real output: <summary จาก Section 3 Done>
- Evidence quality: <BUILD-INFO + TC count + GDrive folders>
- Clarity: <Done/In-Progress/Blocked แยกชัดไหม>
- Impact: <ผลต่อ project/customer/team>
- Growth/Learning: <เรียนรู้อะไร จาก Section 11>
- AI quality: <AI ช่วยอะไร · model mix · limitation>
- No-Fake confirmed: <Yes / Partial — <violations จาก No-Fake Gate cross-check>>

---

<!-- ═════════════════════════════════════════════════════════════════════════
     Leave-mode override
     ═════════════════════════════════════════════════════════════════════════
     ถ้าวันนี้ลา/WFH ไม่มี commit — แทนที่ frontmatter + sections ด้วย:

     ---
     date: YYYY-MM-DD
     leave_type: "ลาพักร้อน / ลาป่วย / ลากิจ / WFH / etc."
     leave_approver: "<ชื่อ/ตำแหน่งผู้อนุมัติ>"
     leave_doc: "<URL ใบลา / Drive link / HR system reference>"
     return_date: "<YYYY-MM-DD>"
     commits_count: 0
     hours: 0
     ai_usage_level: "none"
     ---

     ## 1 Summary
     - Main focus today: Leave / <leave_type>
     - Overall status: N/A (leave day)
     - Key outcome: N/A
     - Biggest risk/blocker: none

     ## 3 Done with Evidence
     - Task: <leave_type>
       - Status: Done (leave approved)
       - Evidence: [ใบลา](<leave_doc>)
       - Verification: verified by <leave_approver>
       - Next action: Return to work on <return_date>

     ## 4-12: "N/A — on leave" หรือ "-"
     ═════════════════════════════════════════════════════════════════════════
-->

<!-- Pipeline trace + 5 mandatory output sections (BDA Standard) -->

## Pipeline trace
- **Understand** — อ่าน morning goals + commits + plans + fix-logs ของวันนี้
- **Plan** — Section 2 (Today's Goal) draft
- **Execute** — Section 3 (Done with Evidence) + 4 (In Progress)
- **Verify** — Section 6 (Test/Verification) + Section 9 (Evidence links)
- **Handoff** — Section 10 (Forecast) + Section 12 (Questions)

## BDA Standard files used
- `standards/STANDARD.md` (5-step pipeline)
- `standards/policies/no-fake-evidence.md`
- `standards/templates/obsidian-work-note.md` (v0.7.0 session note shape)
- `templates/checkin.md` (this file)

## Commands run
- (ระบุ command shell / tool ที่รันจริงตอน generate checkin)

## Verification / Evidence
- (ระบุไฟล์ที่ create/update + commits/links ที่ตรวจจริง)

## Limitations / Risks / Next steps
- (ข้อจำกัด / ความเสี่ยง / งานต่อ — ห้ามเขียนลอย)
