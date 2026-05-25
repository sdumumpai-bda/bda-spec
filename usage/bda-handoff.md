# /bda-handoff

> **สร้าง Handoff Report ส่งงานต่อ reviewer/exec/QA** — เอกสารทางการสรุปผลงานพร้อม evidence และ approval section

[← กลับ usage/README](./README.md) · [Full spec: `.bda-spec/commands/bda-handoff.md`](../.bda-spec/commands/bda-handoff.md)

## เมื่อไหร่ใช้

- หลัง `/bda-verify` ผ่านครบแล้ว — พร้อมส่งงาน
- เมื่อต้องการเอกสารทางการให้ reviewer/executive อ่านและ approve
- ก่อน deploy production — Approval gate

> ควรรัน `/bda-verify` ให้ผ่านก่อน แล้วค่อย `/bda-handoff`

## Quick start

```
/bda-handoff docs/obsidian-vault/80-ImplementPlan/2026-05-21-1430-add-search.md
```

ผลลัพธ์:
```
docs/obsidian-vault/95-Handoff/HOR-2026-05-21-add-search.md

# Add Search Feature — Handoff Report
## Summary · What Changed · Verification Results · DS Compliance
## Security · BDA Standard files · Pipeline trace · Commands run
## Evidence Manifest · Limitations · Rollback · Approval [ ]
```

## รูปแบบเต็ม

```
/bda-handoff <plan-or-fix-path>     # handoff งานจาก plan/fix
/bda-handoff --feature <name>       # handoff ทั้ง feature
/bda-handoff --since <ref>          # handoff ทุกอย่างใน diff range
```

## ขั้นตอนภายใน (Phase summary)

1. **Phase 1** — Pre-flight check: ตรวจ plan status + warn ถ้ายังไม่ `/bda-verify`
2. **Phase 2** — สร้าง Handoff Report `HOR-<YYYY-MM-DD>-<slug>.md` (12 sections)
3. **Phase 3** — อัปเดต status: plan → `handed-off`, IMPLEMENTATION-STATUS → `ready-for-review`, checkin log

## Handoff Report sections

```
Frontmatter:
  status: ready-for-review | approved | deployed
  audience: [executive, reviewer, qa]

Body:
  ## Summary                    ← 1 ย่อหน้า exec-friendly
  ## What Changed               ← files, features, bugs, docs
  ## Verification Results       ← tests, build, lint + evidence paths
  ## Design System Compliance   ← components, violations
  ## Security Pre-flight        ← secrets, PII, masking, prod
  ## BDA Standard files used
  ## Pipeline trace             ← Understand → Plan → Execute → Verify → Handoff
  ## Commands run
  ## Evidence Manifest          ← plan link, evidence folder, commit hashes
  ## Limitations / Risks / Next steps
  ## Rollback / Mitigation      ← ถ้า production-facing
  ## Approval                   ← reviewer signs ทีหลัง
```

## Workflow

```
1. /bda-implement <plan>        ← code + tests + evidence
2. /bda-test                    ← smoke pass
3. /bda-secure                  ← clean
4. /bda-verify <plan>           ← ตรวจครบ (tests, evidence, vault, security, DS)
5. /bda-handoff <plan>          ← คุณอยู่ที่นี่ — สร้าง HOR-*.md
6. /bda-git --plan <plan>       ← commit + push
7. [reviewer เปิด HOR-*.md + sign Approval section]
```

## Gotchas / ข้อควรระวัง

- 🚫 **ห้าม fake evidence** ในรายงาน
- 🚫 **ห้าม approve ตัวเอง** — Approval section ให้ reviewer กรอก
- 🚫 ห้าม push handoff to public ถ้ามี customer PII
- ⚠️ ถ้า plan ยัง `status != done` → warn ให้ implement ก่อน (ไม่ block แต่ recommend)
- ⚠️ ถ้าไม่ได้รัน `/bda-verify` → warn ให้รันก่อน (ไม่ block แต่ recommend)
- 💡 Handoff Report = 5 mandatory output sections ครบในเอกสารเดียว

## Related

- ก่อน `/bda-handoff`: [/bda-verify](./bda-verify.md), [/bda-secure](./bda-secure.md), [/bda-evidence](./bda-evidence.md)
- หลัง `/bda-handoff`: [/bda-git](./bda-git.md), reviewer review + approve
- Vault path: `docs/obsidian-vault/95-Handoff/HOR-*.md`

## FAQ

**Q: ต่างจาก `/bda-verify` ยังไง?**
A: `/bda-verify` = ตรวจงานตัวเอง (tests/evidence/security/DS); `/bda-handoff` = สร้างเอกสารส่งต่อคนอื่น พร้อม Approval section

**Q: Reviewer ดูที่ไหน?**
A: `docs/obsidian-vault/95-Handoff/HOR-*.md` หรือ GDrive link (ถ้า upload แล้ว) — Approval section รอ sign

**Q: ต้อง verify ก่อนทุกครั้งไหม?**
A: แนะนำ — ถ้าไม่ verify มาก่อน `/bda-handoff` จะ warn แต่ไม่ block; handoff report จะมีหมายเหตุว่า verification pending
