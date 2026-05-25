---
description: Full verify (tests + evidence + vault + security + DS) — ไม่สร้าง handoff report (ใช้ /bda-handoff แยก)
model: claude-sonnet-4-6
---

# /bda-verify — Full Verify

ตรวจครบทุกมิติก่อนส่งงาน — tests, evidence, vault, security, design system

> ต้องการสร้าง Handoff Report ส่งต่อให้ reviewer/exec? → `/bda-handoff <plan-or-fix-path>`

## Trigger

```
/bda-verify <plan-or-fix-path>      # ตรวจ specific work
/bda-verify --since <ref>           # ตรวจทุกอย่างใน diff range
/bda-verify --feature <name>        # ตรวจ feature scope
```

## Phase 1 — Scope identification

อ่าน:
- Plan/fix file ที่ user ระบุ
- Files changed (`git diff`)
- Vault docs ที่ link (Feature, Function, PRD)

## Phase 2 — Test verification

รัน (หรือดูว่ารันแล้ว):
- Unit tests (relevant scope)
- Integration tests
- Lint
- Build
- Type check

**ห้าม fake** — ถ้ารันไม่ได้ ระบุ blocker + reason

## Phase 3 — Evidence audit

ตรวจ `docs/obsidian-vault/90-TestPlan/evidence/<scope>/`:
- [ ] Manifest มี
- [ ] Screenshot ครบตาม test plan
- [ ] PII masked
- [ ] Console logs + network logs เก็บแล้ว
- [ ] Route source trace ระบุ
- [ ] Status taxonomy ถูก (PASS/FAIL/BLOCKED_*/NOT_RUN_RISK)

## Phase 4 — Vault consistency

```bash
# ตรวจ link ทุก [[...]] ใน docs ของ scope
# ตรวจ IMPLEMENTATION-STATUS update
# ตรวจ docs ใหม่ที่ควรเพิ่ม (function spec ของ feature ใหม่)
```

ถ้าเจอ inconsistency → list ให้ user → เสนอ /bda-doc แก้

## Phase 5 — Security pre-flight

เรียก /bda-secure logic — ตรวจ secrets, PII, masking, public-repo, prod guardrails

ถ้าผลเป็น BLOCKED → STOP verify, user ต้องแก้ก่อน

## Phase 6 — Design system audit (ถ้ามี frontend/mobile)

ถ้า `docs/obsidian-vault/70-Reference/DesignSystem/` มีอยู่ + scope กระทบ UI:
- เรียก /bda-design audit logic
- ตรวจ component compliance, contrast, focus state
- Report violations

## Phase 7 — สรุปผลและขั้นตอนต่อไป

แสดงผลรวม:
- ✅ / ❌ แต่ละ Phase (test, evidence, vault, security, DS)
- รายการที่ยังไม่ผ่าน (ถ้ามี) + วิธีแก้
- ขั้นตอนต่อไป: `→ /bda-handoff <path>` เพื่อสร้าง Handoff Report ส่งต่อ reviewer

## Output (5 หัวข้อบังคับ)

1. **BDA Standard files used** — `standards/STANDARD.md`, `standards/policies/no-fake-evidence.md`, `standards/policies/evidence-verification.md`
2. **Pipeline trace** — Understand (Phase 1) → Plan (plan file) → Execute (implement) → Verify (Phase 2-6) → Handoff (pending `/bda-handoff`)
3. **Commands run** — ทุก test/lint/build command ที่รันจริง พร้อมผล
4. **Verification / Evidence** — ผลแต่ละ Phase + paths ของ evidence
5. **Limitations / Risks / Next steps** — รายการที่ยังไม่ผ่าน + `→ /bda-handoff` ถัดไป

## ห้าม

- ห้าม verify ที่ test ไม่ผ่าน — STOP, แจ้ง user
- ห้าม fake evidence
- ห้ามสร้าง Handoff Report ใน command นี้ — ใช้ `/bda-handoff` แยก
