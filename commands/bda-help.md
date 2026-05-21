---
description: Interactive help — แนะนำ command ตามสถานการณ์ + อธิบายวิธีใช้แต่ละ command + แสดง workflow ที่พบบ่อย
model: claude-sonnet-4-6
---

# /bda-help — Interactive Help

ตัวช่วยถาม-ตอบ: "อยากทำอะไร → ใช้ command ไหน → ทำงานยังไง"

## Trigger

```
/bda-help                          # interactive — ถามว่าอยากทำอะไร
/bda-help <command>                # อธิบาย command ตัวนั้นเชิงลึก
/bda-help workflow                 # แสดง workflows ที่พบบ่อย
/bda-help workflow <name>          # อธิบาย workflow เฉพาะ (new-project, bug-fix, daily, design, etc.)
/bda-help search <keyword>         # ค้น command/concept ที่เกี่ยวข้อง
/bda-help cheatsheet               # 1-page cheatsheet สั้นๆ
/bda-help tree                     # decision tree "ถ้า X → ใช้ Y"
```

## Phase 0 — Detect intent

ถ้า `$ARGUMENTS` ว่าง → ถาม user 1 คำถามเดียว:

```
จะให้ผมช่วยอะไร?

  1) แนะนำ command ตามสถานการณ์    (ถ้าไม่รู้ว่าจะใช้ตัวไหน)
  2) อธิบาย command เฉพาะ           (ถ้ารู้แล้วแต่อยากรู้ option/phase)
  3) แสดง workflow ที่พบบ่อย         (เช่น "เริ่ม project ใหม่ทั้งหมดยังไง")
  4) Cheatsheet 1 หน้า               (รายชื่อ command + ใช้เมื่อไหร่)
  5) ค้นด้วย keyword                  (เช่น "evidence", "obsidian", "submodule")
```

แล้วทำตามที่ user เลือก ใน Phase ที่เกี่ยวข้อง

## Phase 1 — Mode "แนะนำตามสถานการณ์"

ถาม batch 3-5 คำถาม:

1. **คุณอยู่ที่จุดไหนของ project?**
   - ยังไม่มีอะไรเลย (folder ว่าง) → `/bda-init` หรือ installer
   - มี code แล้ว แต่ไม่มี docs → `/bda-init` แบบ brownfield
   - มี vault แล้ว → ต่อไปข้อ 2
   - ทำมาแล้วช่วงหนึ่ง → ต่อไปข้อ 2

2. **กำลังจะทำอะไร?** (multi-select)
   - [ ] เริ่ม feature/task ใหม่
   - [ ] แก้บั๊ก
   - [ ] เขียน/อัพเดท docs (PRD, SRS, ADR, ฯลฯ)
   - [ ] รัน test / ตรวจ implementation
   - [ ] รายงาน executive
   - [ ] commit/push code
   - [ ] ตรวจ security / pre-flight
   - [ ] ส่งมอบงาน
   - [ ] ออกแบบ UI / design system
   - [ ] อัพเดท standards ขององค์กร

3. (ถ้าเลือก "feature/task ใหม่") **มี PRD/spec แล้วหรือยัง?**
   - ยัง → `/bda-new` (brainstorm)
   - มี → `/bda-new --import <path>` (import + ต่อ SRS/Tech)
   - มี vault feature แล้ว → `/bda-plan <task>` ตรงๆ

→ แนะนำ command + cite link path ของ `commands/<name>.md` ให้อ่านต่อ

### Decision tree (ใช้ใน `tree` mode)

```
ถาม: project มี .bda-spec.yml อยู่แล้วไหม?
├─ ไม่มี → /bda-init  (หรือ installer ก่อน)
└─ มี → ถามต่อ: จะทำอะไร?
    ├─ "มีไอเดียใหม่"            → /bda-new
    ├─ "มี PRD แล้ว"              → /bda-new --import
    ├─ "วางแผน feature"          → /bda-plan <task>
    ├─ "ลงมือทำตาม plan"          → /bda-implement <plan-file>
    ├─ "แก้บั๊ก"                  → /bda-fix <bug>
    ├─ "เขียน/แก้ doc"            → /bda-doc <type>
    ├─ "test smoke"               → /bda-test
    ├─ "ออกแบบ UI"               → /bda-design [init|tokens|component]
    ├─ "รายงาน executive"         → /bda-checkin [morning|midday|note|end]
    ├─ "ตรวจ security"            → /bda-secure
    ├─ "verify + handoff"         → /bda-verify
    ├─ "commit/push"             → /bda-git [--plan|--fix|--branch]
    └─ "อัพเดท standards"          → /bda-sync
```

## Phase 2 — Mode "อธิบาย command เฉพาะ"

อ่าน `commands/<cmd>.md` แล้วสรุปให้ user ในรูปแบบ:

```
## /bda-<name>

ใช้เมื่อ: <one-line>

Trigger:
  <list trigger forms>

ทำอะไร: (Phase summary — ไม่ลงรายละเอียดยาว)
  1. <Phase 1 ในประโยคเดียว>
  2. <Phase 2 ...>

ผลลัพธ์ใน vault:
  - <ไฟล์ที่จะสร้าง/แก้>

ห้าม: (top 2-3)
  - <สำคัญสุด>

ต่อด้วย: → /bda-<next>

อ่าน full spec: commands/bda-<name>.md
```

## Phase 3 — Mode "workflows"

แสดง workflow card ตามที่ user เลือก:

### `workflow new-project` — เริ่มโปรเจกต์ใหม่ตั้งแต่ศูนย์

```
1. bash <(curl ... install.sh)         ← bootstrap
2. /bda-init                            ← config (vault location, subagents)
3. /bda-new                             ← brainstorm → PRD + SRS + Tech-spec
4. /bda-design init                     ← (optional) bootstrap design system
5. /bda-plan FEAT-X                     ← วางแผน feature แรก
6. [user review plan, set status: approved]
7. /bda-implement docs/80-.../plan.md   ← ลงมือ ผ่าน subagent
8. /bda-test                            ← smoke test
9. /bda-secure                          ← pre-flight
10. /bda-verify                         ← handoff report
11. /bda-git --plan <path>              ← commit + push
12. /bda-checkin end                    ← daily executive log
```

### `workflow bug-fix` — แก้บั๊กพร้อม evidence

```
1. /bda-fix "search ค้างเมื่อใส่ขีดล่าง"  ← diagnose + fix-log (no code)
2. /bda-plan fix:<slug>                   ← small plan referencing fix-log
3. /bda-implement <plan>                  ← ลงมือ
4. /bda-test --since <sha>                ← verify fix
5. /bda-secure                            ← scan
6. /bda-verify                            ← handoff
7. /bda-git --fix <fix-log-path>          ← commit (prefix: fix:)
```

### `workflow daily` — รายงานรายวันแบบ executive

```
ตอนเช้า:    /bda-checkin morning         ← ตั้ง goals 3-5
ตอนเที่ยง:  /bda-checkin midday          ← progress check
ระหว่างวัน: /bda-checkin note meeting "ประชุม UX"
            /bda-checkin note test "manual test feature X"
ก่อนเลิก:   /bda-checkin end             ← executive summary + AI usage

→ ทั้งหมดใน docs/obsidian-vault/75-Checkins/<today>.md ไฟล์เดียว
→ ถ้า set daily_log_mirror ใน .bda-spec.local.yml → mirror อัตโนมัติ
```

### `workflow design` — สร้าง/ใช้ design system

```
1. /bda-design init                       ← bootstrap minimal DS
   → สร้าง DS-Tokens.md, DS-Components.md, ..., preview.html
2. เปิด docs/obsidian-vault/70-Reference/DesignSystem/preview.html ด้วย browser
3. /bda-design tokens                     ← ปรับ token (brand colors, type)
4. /bda-design component <name>           ← เพิ่ม component ใหม่
5. /bda-design audit                      ← ตรวจ implementation vs DS

หลัง init → frontend/mobile subagent ถูกบังคับใช้ DS
ห้าม ad-hoc styling — ถ้าต้อง component ใหม่ → STOP, /bda-design ก่อน
```

### `workflow brownfield-adopt` — รับ codebase เดิมเข้า bda-spec

```
1. cd existing-project
2. bash <(curl ... install.sh)             ← brownfield mode auto-detect
   → installer ถาม vault location (A/B/C/D)
   → เลือก B (docs/bda-vault/) ถ้า docs/ ใช้อยู่
3. /bda-init                                ← interactive — ตรวจ stack, ถาม import README
4. (ถ้ามี README) → ตรวจ PRD draft ที่ generate มา
5. /bda-doc PRD-<slug>                      ← เติม section ที่ขาด
6. /bda-plan <first task>                   ← เริ่ม workflow ปกติ
```

### `workflow submodule` — bda-spec เป็น submodule ใน repo ใหญ่

```
1. cd parent-repo
2. git submodule add https://github.com/.../bda-spec .bda
3. cd .bda
4. /bda-init                                ← เลือก mode: submodule
   → vault อาจใช้ external (D) ชี้ไปนอก submodule
5. ตั้งค่า .bda-spec.yml มี submodules: list
6. /bda-git --update-submodules             ← sync submodules ภายใน parent
```

## Phase 4 — Mode "cheatsheet"

แสดงตาราง 1-page (สั้นที่สุด):

```
| Command         | ใช้เมื่อ                              | ผลลัพธ์หลัก              |
|-----------------|---------------------------------------|--------------------------|
| /bda-init       | ตั้งค่า project ครั้งแรก                  | .bda-spec.yml + vault   |
| /bda-new        | เริ่ม project/feature ใหม่               | PRD + SRS + Tech        |
| /bda-plan       | วางแผนงาน (ก่อนแตะโค้ด)               | plan file in 80-...     |
| /bda-implement  | ลงมือทำตาม plan (เท่านั้นที่แก้โค้ด)    | code + evidence + log   |
| /bda-fix        | diagnose บั๊ก (ไม่แก้โค้ด)             | fix-log in 85-FixLog    |
| /bda-doc        | เขียน/แก้ doc                          | doc file in vault       |
| /bda-test       | smoke test diff                       | test report + evidence  |
| /bda-design     | สร้าง/อัพเดท design system            | DS-*.md + preview.html  |
| /bda-checkin    | daily executive log (1 file/วัน)       | 75-Checkins/<date>.md   |
| /bda-secure     | security pre-flight                   | secure report           |
| /bda-verify     | verify + handoff report               | HOR-*.md in 95-Handoff  |
| /bda-git        | submodule-aware commit/push           | git history             |
| /bda-sync       | pull standards ใหม่จาก org repo        | standards/ updated      |
| /bda-help       | this help                             |                          |
```

## Phase 5 — Mode "search"

อ่าน description + frontmatter ของทุก `commands/*.md` + key sections — ค้น keyword:

```bash
grep -l "$KEYWORD" commands/*.md
grep -l "$KEYWORD" .claude/agents/*.md
```

แสดงผล:
```
🔎 Keyword: "evidence"

Commands ที่กล่าวถึง:
  • /bda-verify     — verify + collect evidence manifest
  • /bda-test       — capture screenshot/console/network as evidence
  • /bda-fix        — record before/after evidence in fix-log
  • /bda-implement  — produce implementation evidence

Subagents ที่กล่าวถึง:
  • test-runner     — primary evidence capturer
  • security        — masking + safe-to-share check

Standards refs:
  • standards/policies/evidence-verification.md
  • standards/policies/no-fake-evidence.md
```

## Output (5 หัวข้อบังคับ — exception: read-only command)

**สำคัญ**: `/bda-help` เป็น command **อ่านอย่างเดียว** — ไม่สร้าง/แก้ไฟล์ใดๆ ใน vault

แม้ BDA Standard กำหนด 5 หัวข้อบังคับ แต่ command นี้ได้รับ **exception** เพราะไม่มี evidence ใหม่ที่ต้อง track
ใช้ minimal output แทน:
- **Pipeline trace** — Understand (Phase 0) → ตามที่ user ขอ
- **Commands run** — grep/Read ที่รันจริง (ถ้ามี)
- (ข้าม BDA Standard files used / Verification / Limitations เพราะ no-op)

ปิดท้ายด้วยคำเตือนเล็กๆ:

> 💡 ถ้ายังไม่แน่ใจ → ลอง `/bda-help tree` หรือ `/bda-help cheatsheet`
> 📖 อ่านเต็ม: `cat commands/<name>.md`

## ห้าม

- ห้ามแก้ไฟล์ใดๆ — help เป็น read-only
- ห้าม guess command ที่ไม่มีจริง — list 14 commands เท่านั้น
- ห้าม invent workflow ที่ไม่อยู่ใน Phase 3 cards — ถ้าผู้ใช้ถามนอกขอบเขต → ใช้ Phase 1 ถามต่อ
- ห้ามอธิบาย internal phase ของ command เกินที่จำเป็น — ส่ง user ไปอ่าน `commands/<name>.md` เอง
