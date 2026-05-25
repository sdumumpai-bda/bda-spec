# bda-spec Commands — Usage Guide

คู่มือใช้งาน 21 คำสั่งของ bda-spec แบบจริงจัง — 1 ไฟล์ต่อ command พร้อมตัวอย่าง, workflow, gotchas

> ใช้คู่กับ [`commands/bda-*.md`](../commands/) (source-of-truth พร้อม Phase รายละเอียดเต็ม)
> ถ้าไม่รู้จะเริ่มจากไหน → อ่าน [/bda-help](./bda-help.md) ก่อน

---

## หาคำสั่งที่ต้องการ

### ตั้งค่า + ช่วยเหลือ

| Command | ใช้เมื่อ |
|---|---|
| [/bda-help](./bda-help.md) | ถามว่าจะใช้ command ไหน / cheatsheet / decision tree |
| [/bda-init](./bda-init.md) | bootstrap project ครั้งแรก (greenfield หรือ brownfield) |
| [/bda-sync](./bda-sync.md) | อัพเดต BDA Standard snapshot จาก org repo |
| [/bda-agent](./bda-agent.md) | จัดการ subagent (list/enable/create/regenerate) |

### Spec-driven cycle (อิง spec-kit + BDA Standard)

| Command | ใช้เมื่อ |
|---|---|
| [/bda-new](./bda-new.md) | brainstorm จาก idea หรือ import PRD ที่มีอยู่ |
| [/bda-clarify](./bda-clarify.md) | scan ambiguity 9 หมวด ถามทีละข้อพร้อม recommended answer |
| [/bda-plan](./bda-plan.md) | research vault แล้วสร้าง plan file (ไม่แตะโค้ด) |
| [/bda-checklist](./bda-checklist.md) | "unit tests for English" per domain (ux/api/security/...) |
| [/bda-implement](./bda-implement.md) | execute plan ที่ approve แล้วผ่าน subagent |
| [/bda-fix](./bda-fix.md) | diagnose bug + สร้าง fix-log (ไม่แก้โค้ด) |

### เอกสาร + ทดสอบ + ออกแบบ + หลักฐาน

| Command | ใช้เมื่อ |
|---|---|
| [/bda-doc](./bda-doc.md) | สร้าง/แก้ doc (PRD/SRS/ADR/Feature/Function/Role/Flow/Phase) |
| [/bda-test](./bda-test.md) | smoke test เฉพาะส่วน diff + capture evidence |
| [/bda-design](./bda-design.md) | design system (tokens, components) + preview.html |
| [/bda-evidence](./bda-evidence.md) | capture/mask/store evidence + update manifest |
| [/bda-upload](./bda-upload.md) | upload evidence ไปยัง GDrive (rclone) + ใส่ link ใน manifest |

### ประจำวัน + ส่งมอบ

| Command | ใช้เมื่อ |
|---|---|
| [/bda-checkin](./bda-checkin.md) | daily check-in (morning/midday/note/end) — 1 ไฟล์/วัน |
| [/bda-secure](./bda-secure.md) | security pre-flight (secret/PII/screenshot/dep scan) |
| [/bda-verify](./bda-verify.md) | verify ครบ (tests/evidence/vault/security/DS) |
| [/bda-handoff](./bda-handoff.md) | สร้าง Handoff Report ส่งต่อ reviewer/exec/QA |
| [/bda-git](./bda-git.md) | submodule-aware commit/push/branch/merge |

---

## Workflows ที่พบบ่อย

### เริ่ม project ใหม่ (greenfield)

```
1. bash <(curl ... install.sh)              ← bootstrap จาก installer
2. /bda-init                                ← interactive config (vault location, subagents)
3. /bda-new                                 ← brainstorm → PRD + SRS + Tech-spec
4. /bda-design init                         ← (optional) bootstrap design system
5. /bda-plan FEAT-X                         ← research vault + plan file
6. [user review plan, set status: approved ใน frontmatter]
7. /bda-implement docs/...                  ← execute ผ่าน subagent + capture evidence
8. /bda-test                                ← smoke test ส่วนที่แก้
9. /bda-secure                              ← pre-flight scan
10. /bda-verify                             ← ตรวจครบ (tests/evidence/vault/security/DS)
11. /bda-handoff                            ← สร้าง HOR-*.md ส่ง reviewer
12. /bda-git --plan <path>                  ← commit + push
13. /bda-checkin end                        ← executive log
```

### แก้บั๊ก (พร้อม evidence)

```
1. /bda-fix "search ค้างเมื่อใส่ขีดล่าง"      ← diagnose + fix-log (ไม่แก้โค้ด)
2. /bda-plan fix:<slug>                       ← mini plan ที่ link ไปยัง fix-log
3. /bda-implement <plan>                      ← แก้จริง
4. /bda-test --since <ref>                    ← verify ว่า fix ได้
5. /bda-evidence                              ← curate + mask before/after screenshot
6. /bda-upload --pending                      ← share link ขึ้น GDrive
7. /bda-verify                                ← handoff
8. /bda-git --fix <fix-log-path>              ← commit prefix `fix:`
```

### Daily report สำหรับผู้บริหาร

```
เช้า:        /bda-checkin morning           ← ตั้ง goals 3-5
เที่ยง:      /bda-checkin midday            ← progress check
ระหว่างวัน:  /bda-checkin note meeting "ประชุม UX"  (เก็บได้หลายรายการ)
ก่อนเลิก:    /bda-checkin end               ← รวบรวม 7 แหล่งข้อมูล (commits/vault/evidence/no-fake/phase/ccusage/gdrive)
```

ทั้งหมดใน `docs/obsidian-vault/75-Checkins/<YYYY-MM-DD>.md` ไฟล์เดียว

### Brownfield adoption (รับ codebase เดิม)

```
1. cd existing-project
2. bash <(curl ... install.sh)               ← installer auto-detect indicators
3. /bda-init --brownfield                    ← config + vault skeleton
4. /bda-reverse-engineer                     ← scan โค้ด → draft FEAT/FN/REF docs
5. [ตรวจ draft docs + เติม business rules]
6. /bda-clarify FEAT-<slug>                  ← scan ambiguity ใน draft
7. /bda-plan <first task>                    ← เริ่ม workflow ปกติ
```

---

## หลักการที่ทุก command บังคับ

1. **Vault-first** — อ่าน `docs/` ก่อนถามคำถาม
2. **5 mandatory output sections** ทุก response (BDA files used / Pipeline trace / Commands run / Verification / Limitations)
3. **No fake evidence** — ห้ามแต่ง commit hash, URL, test result, token count
4. **Plan/Implement separation** — `/bda-plan` และ `/bda-fix` ไม่แตะโค้ด, `/bda-implement` เท่านั้นแก้โค้ด
5. **Thai-first** reports (เว้นแต่ `.bda-spec.yml` `language: en`)
6. **Coding discipline** — ระบุ success criteria ก่อนลงมือ; minimum correct change; ทุก changed line trace กลับ request/criteria ได้; ห้าม speculative abstraction/refactor นอก scope

---

## Reference docs

- [Full README](../README.md) — overview + install
- [Multi-AI guide](../AI-README.md) — Claude/Codex/Gemini/GPT/GLM
- [Evidence path strategy](../EVIDENCE-PATHS.md) — 3 tiers (raw/curated/uploaded)
- [Changelog](../CHANGELOG.md)
- Command source-of-truth: [`../commands/bda-*.md`](../commands/)
- Subagent specs: [`../.claude/agents/*.md`](../.claude/agents/)
- Templates: [`../templates/*.md`](../templates/)
