# /bda-verify

> **Full verify** — tests + evidence + vault + spec audit + security + DS audit → สรุปผลพร้อม next steps

> ต้องการสร้าง Handoff Report ส่งต่อ reviewer/exec? → `/bda-handoff <path>` (command แยก)

[← กลับ usage/README](./README.md) · [Full spec: `.bda-spec/commands/bda-verify.md`](../.bda-spec/commands/bda-verify.md)

## เมื่อไหร่ใช้

- หลัง `/bda-implement` + `/bda-test` + `/bda-secure` ผ่าน
- ตรวจให้ครบก่อนสร้าง Handoff Report
- ต้องการ verify แต่ยังไม่พร้อม handoff (ยังแก้อยู่)

## Quick start

```
/bda-verify docs/obsidian-vault/80-ImplementPlan/2026-05-21-1430-add-search.md
```

ผลลัพธ์:
```
✅ Phase 1 Scope      — plan + git diff + linked vault docs
✅ Phase 2 Tests      — 42/42 passed, lint clean, build OK
✅ Phase 3 Evidence   — manifest OK, PII masked, screenshots 5/5
✅ Phase 4 Vault      — links OK, IMPLEMENTATION-STATUS updated
   ⚠️  Spec audit     — FR-003 no task ID (orphan) — warn only
✅ Phase 5 Security   — no secrets, no PII
✅ Phase 6 DS Audit   — 0 violations

→ /bda-handoff <path>  เพื่อสร้าง Handoff Report ส่งต่อ reviewer
```

## รูปแบบเต็ม

```
/bda-verify <plan-or-fix-path>      # ตรวจ specific work
/bda-verify --since <ref>           # ตรวจทุกอย่างใน diff range
/bda-verify --feature <name>        # ตรวจ feature scope
```

## ขั้นตอนภายใน (Phase summary)

1. **Phase 1** — Scope identification (plan/fix + `git diff` + linked vault docs)
2. **Phase 2** — Test verification (unit, integration, lint, build, type check) — **ห้าม fake**
3. **Phase 3** — Evidence audit (manifest, screenshots, PII masked, route source trace, status taxonomy)
4. **Phase 4** — Vault consistency + Spec audit (wikilinks, IMPLEMENTATION-STATUS, orphan FR, terminology)
5. **Phase 5** — Security pre-flight (เรียก `/bda-secure` logic) — STOP ถ้า BLOCKED
6. **Phase 6** — Design system audit (เรียก `/bda-design audit` logic)
7. **Phase 7** — สรุปผล ✅/❌ แต่ละ Phase + hint `→ /bda-handoff`

## Output ที่ได้

- ผลรวม ✅/❌ แต่ละ Phase พร้อมรายการที่ยังไม่ผ่าน
- Spec audit: orphan FR warn (ไม่ block), terminology issues
- Checkin log entry
- Hint: `→ /bda-handoff <path>` ถัดไป

## Workflow

ตัวอย่าง 1: feature
```
1. /bda-implement <plan>            ← code + tests + evidence
2. /bda-test                        ← smoke pass
3. /bda-secure                      ← clean
4. /bda-verify <plan>               ← คุณอยู่ที่นี่
5. /bda-handoff <plan>              ← สร้าง HOR-*.md ส่ง reviewer
6. /bda-git --plan <plan>           ← commit + push
```

ตัวอย่าง 2: bug fix
```
1. /bda-fix → /bda-plan → /bda-implement
2. /bda-test --since HEAD~
3. /bda-verify --fix docs/obsidian-vault/85-FixLog/<slug>.md
4. /bda-handoff --fix <fix-log>
5. /bda-git --fix <fix-log>
```

ตัวอย่าง 3: diff-scoped
```
/bda-verify --since main
  → ตรวจทุก commit vs main
  → สรุปผล + hint /bda-handoff
```

## Gotchas / ข้อควรระวัง

- 🚫 **ห้าม verify ที่ test ไม่ผ่าน** — STOP, แจ้ง user แก้ก่อน
- 🚫 **ห้าม fake evidence** — no-fake-evidence policy
- ⚠️ Security pre-flight (Phase 5) BLOCKED → STOP, ต้อง `/bda-secure` clear ก่อน
- ⚠️ Vault inconsistency (Phase 4) → flag + เสนอ `/bda-doc` แก้ — ไม่ block
- ⚠️ Orphan FR (Phase 4 spec audit) → warn เท่านั้น ไม่ block
- 💡 `/bda-verify` ไม่สร้าง Handoff Report — ใช้ `/bda-handoff` แยกต่างหาก

## Related

- ก่อน `/bda-verify`: [/bda-implement](./bda-implement.md), [/bda-test](./bda-test.md), [/bda-secure](./bda-secure.md), [/bda-evidence](./bda-evidence.md)
- หลัง `/bda-verify`: [/bda-handoff](./bda-handoff.md) (สร้าง HOR-*.md), [/bda-git](./bda-git.md)
- Embedded: `/bda-secure` (Phase 5), `/bda-design audit` (Phase 6)

## FAQ

**Q: ต่างจาก `/bda-handoff` ยังไง?**
A: `/bda-verify` = ตรวจงานตัวเอง; `/bda-handoff` = สร้างเอกสารส่งต่อคนอื่น ควรรัน verify ให้ผ่านก่อน

**Q: ถ้า verify fail ต้องเริ่มใหม่ไหม?**
A: ไม่ — แก้ blocker แล้วรัน `/bda-verify` ใหม่

**Q: Orphan FR ใน spec audit เป็น error ไหม?**
A: เป็นแค่ warning — ไม่ block verify แต่ควรแก้ก่อน handoff (สร้าง plan สำหรับ FR นั้น หรือลบถ้า descoped)
