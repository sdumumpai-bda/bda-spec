# /bda-verify

> **Full verify + handoff report** — tests + evidence + vault + security + DS audit → executive handoff doc

[← กลับ usage/README](./README.md) · [Full spec: `commands/bda-verify.md`](../commands/bda-verify.md)

## เมื่อไหร่ใช้

- ก่อนส่งงานให้ reviewer/executive
- หลัง `/bda-implement` + `/bda-test` + `/bda-secure` ผ่าน
- รวบรวมทุกอย่าง (tests, evidence, vault sync, security, DS compliance) → 1 doc
- Approval gate ก่อน deploy production

## Quick start

```
/bda-verify docs/obsidian-vault/80-ImplementPlan/2026-05-21-1430-add-search.md
```

ผลลัพธ์:
```
docs/obsidian-vault/95-Handoff/HOR-2026-05-21-add-search.md

# Add Search Feature — Handoff Report
## Summary · What Changed · Verification · DS Compliance · Security · BDA Standard files · Pipeline trace · Commands run · Evidence Manifest · Limitations · Rollback · Approval
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
4. **Phase 4** — Vault consistency (wikilinks, IMPLEMENTATION-STATUS, missing FN-* etc.)
5. **Phase 5** — Security pre-flight (เรียก `/bda-secure` logic) — STOP ถ้า BLOCKED
6. **Phase 6** — Design system audit (เรียก `/bda-design audit` logic)
7. **Phase 7** — สร้าง handoff report `docs/obsidian-vault/95-Handoff/HOR-<YYYY-MM-DD>-<slug>.md`
8. **Phase 8** — Update status (plan → handed-off, IMPLEMENTATION-STATUS, checkin log)

## Output ที่ได้

- `docs/obsidian-vault/95-Handoff/HOR-<YYYY-MM-DD>-<slug>.md` — handoff report ที่ครบ 12 sections
- Plan/fix file → `status: handed-off`
- `docs/obsidian-vault/00-Index/IMPLEMENTATION-STATUS.md` mark `ready-for-review`
- Checkin log entry

## Handoff report sections

```
Frontmatter:
  status: ready-for-review | approved | deployed
  audience: [executive, reviewer, qa]

Body:
  ## Summary (1 paragraph executive-friendly)
  ## What Changed (files, features, bugs, docs)
  ## Verification (tests, build, lint, manual checks)
  ## Design System Compliance (components, violations)
  ## Security Pre-flight (secrets, PII, masking, prod)
  ## BDA Standard files used
  ## Pipeline trace (Understand → Plan → Execute → Verify → Handoff)
  ## Commands run
  ## Evidence Manifest (plan link, evidence folder, commit hashes)
  ## Limitations / Risks / Next steps
  ## Rollback / Mitigation (ถ้า production-facing)
  ## Approval (reviewer signs ทีหลัง)
```

## Workflow ที่นิยม

ตัวอย่าง 1: feature handoff
```
1. /bda-implement <plan>            ← code + tests + evidence
2. /bda-test                         ← smoke pass
3. /bda-secure                       ← clean
4. /bda-verify <plan>                ← คุณอยู่ที่นี่ — handoff report
5. /bda-git --plan <plan>            ← commit + push
6. [reviewer review HOR-* + sign Approval]
```

ตัวอย่าง 2: bug fix handoff
```
1. /bda-fix → /bda-plan → /bda-implement
2. /bda-test --since HEAD~
3. /bda-verify --fix docs/obsidian-vault/85-FixLog/<slug>.md
4. /bda-git --fix <fix-log>
```

ตัวอย่าง 3: diff-scoped
```
/bda-verify --since main
  → ตรวจทุก commit vs main
  → 1 handoff report
```

## Gotchas / ข้อควรระวัง

- 🚫 **ห้าม verify ที่ test ไม่ผ่าน** — STOP, แจ้ง user แก้ก่อน
- 🚫 **ห้าม fake evidence ใน handoff report** — no-fake-evidence policy
- 🚫 **ห้าม approve ตัวเอง** — section Approval ให้ reviewer ทีหลัง
- 🚫 ห้าม push handoff to public ถ้ามี customer PII
- ⚠️ Security pre-flight (Phase 5) BLOCKED → STOP, ต้อง `/bda-secure` clear ก่อน
- ⚠️ Vault inconsistency (Phase 4) → flag list + เสนอ `/bda-doc` แก้ — ไม่ block แต่ recommend
- 💡 Handoff report = **คือ** 5 mandatory output sections (ครบใน doc เอง)
- 💡 Approval section เป็น checkbox `[ ] Reviewed by: …` — user/reviewer set ทีหลัง

## Related

- ก่อน `/bda-verify`: [/bda-implement](./bda-implement.md), [/bda-test](./bda-test.md), [/bda-secure](./bda-secure.md), [/bda-evidence](./bda-evidence.md), [/bda-upload](./bda-upload.md)
- หลัง `/bda-verify`: [/bda-git](./bda-git.md) (commit + push), reviewer review
- Embedded calls: `/bda-secure` (Phase 5), `/bda-design audit` (Phase 6)
- Vault path: `docs/obsidian-vault/95-Handoff/HOR-*.md`

## FAQ

**Q: ถ้า `/bda-verify` fail — ต้องเริ่มใหม่ไหม?**
A: ไม่ — แก้ blocker (test fail / secret found / unmasked PII) แล้วรัน `/bda-verify` ใหม่ — handoff report จะ regenerate

**Q: Reviewer ตรวจ handoff report ที่ไหน?**
A: `docs/obsidian-vault/95-Handoff/HOR-*.md` หรือคลิก GDrive link ของ evidence (ถ้า uploaded แล้ว) — Approval section รอ sign

**Q: ทำไมต้องมี handoff report แยกจาก plan file?**
A: Plan = ทำอะไร; HOR = ทำแล้วผลเป็นยังไง + evidence + risks + rollback — exec-friendly summary
