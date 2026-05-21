# /bda-evidence

> **Capture, mask, store evidence** — จัดเก็บ screenshot/log/trace/test-report ใน vault + update manifest

[← กลับ usage/README](./README.md) · [Full spec: `commands/bda-evidence.md`](../commands/bda-evidence.md)

## เมื่อไหร่ใช้

- หลัง manual test/debug/demo — อยากเก็บ screenshot/log
- ย้าย raw evidence จาก `evidence_staging` (Tier 1) → vault (Tier 2, masked)
- ก่อน `/bda-upload` — ต้อง curate + mask ก่อน share
- Audit evidence ที่ commit ไปแล้ว (unmasked PII?)

> **ทำไมแยกจาก `/bda-checkin`:** evidence เกิดหลายครั้ง/วัน + ผูกกับ feature/fix/test ไม่ใช่แค่ daily log

## Quick start

```
/bda-evidence
```

Interactive — ถาม batch:
```
1. Source path(s)
2. Type (screenshot/log/trace/test-report/recording/file)
3. Link to context (feature/fix/plan/test)
4. PII status (clean/masked/raw)
5. Safe to share? (yes/no)
```

## รูปแบบเต็ม

```
/bda-evidence                              # interactive
/bda-evidence <source-path>                # ระบุ path ของ raw evidence
/bda-evidence --from-staging               # ทุกอย่างใน paths.evidence_staging
/bda-evidence --link-to <plan|fix|test>    # ระบุ context ตั้งแต่ trigger
/bda-evidence --upload                     # หลัง store → trigger /bda-upload ทันที
/bda-evidence list                         # evidence ของ feature/fix/plan
/bda-evidence verify                       # ตรวจ manifest vs filesystem
/bda-evidence audit                        # scan unmasked PII ใน commit ไปแล้ว
```

| Flag | Default | ใช้สำหรับ |
|---|---|---|
| `--from-staging` | off | bulk import จาก `.bda-spec.local.yml` `paths.evidence_staging` |
| `--link-to <ctx>` | ask | skip คำถาม link |
| `--upload` | off | chain `/bda-upload` ทันที |

## ขั้นตอนภายใน (Phase summary)

1. **Phase 0** — Resolve config + detect source (staging files ใหม่ 24 ชม.)
2. **Phase 1** — รับ + classify (batch 5 questions)
3. **Phase 2** — Validate (size ≤ 10MB warn, format check, filename pattern)
4. **Phase 3** — Mask PII (regex auto-mask logs; screenshot **manual** — user confirm ด้วยตา)
5. **Phase 4** — Store: `docs/<context-folder>/<slug>/evidence/<filename>` ตาม convention
6. **Phase 5** — Update manifest (`evidence-manifest.md` append, ไม่ overwrite)
7. **Phase 6** — Link จาก source doc (`## Evidence` section in plan/fix/test/feature)
8. **Phase 6.5** — Optional GDrive upload (`--upload`)
9. **Phase 7** — Update IMPLEMENTATION-STATUS + checkin
10. **Phase 8** — Audit mode

## Storage paths (Tier 2)

| Context | Folder |
|---|---|
| Feature | `docs/20-Features/<FEAT-slug>/evidence/` |
| Fix | `docs/85-FixLog/<fix-slug>/evidence/` |
| Plan | `docs/80-ImplementPlan/<plan-slug>.evidence/` |
| Test scenario | `docs/90-TestPlan/<TP-slug>/evidence/` |
| Handoff | `docs/95-Handoff/<HOR-slug>.evidence/` |

Filename: `<SCENARIO-ID>-<STEP>-<state>-<HHMMSS>.<ext>`
ตัวอย่าง: `TC-Checkout-001-03-submit-success-143022.png`

## Manifest structure

```markdown
| ID | File | Type | Captured | Scenario/Step | PII | Masked | Safe-to-share | Notes |
| E001 | TC-001-03-submit-success.png | screenshot | 2026-05-21 14:30 | TC-001 step 3 | none | n/a | ✓ | success state |
| E002 | TC-001-04-receipt.png | screenshot | 2026-05-21 14:31 | TC-001 step 4 | masked-email | ✓ | ✓ | receipt masked |
```

## Workflow ที่นิยม

ตัวอย่าง 1: หลัง manual test
```
1. (test ด้วยตา + screenshot ใส่ /tmp/test-screenshots/)
2. /bda-evidence /tmp/test-screenshots/checkout-success.png
   → type: screenshot
   → link: FEAT-Checkout
   → PII: raw → user mask ด้วยตา → confirm
3. /bda-upload --feature checkout       ← share ขึ้น GDrive
```

ตัวอย่าง 2: bulk import จาก staging
```
1. (Subagent วาง screenshots ใน paths.evidence_staging)
2. /bda-evidence --from-staging --link-to plan:checkout
3. (review + mask)
4. /bda-evidence --upload                ← share ทันที
```

ตัวอย่าง 3: audit เก่า
```
/bda-evidence audit
  → scan all evidence files
  → find unmasked PII (email regex, phone, common names)
  → docs/95-Handoff/EVIDENCE-AUDIT-<date>.md
```

## Gotchas / ข้อควรระวัง

- 🚫 **ห้าม commit evidence ที่ `pii: raw` หรือ `masked: ✗` ลงสาธารณะ** — block
- 🚫 ห้าม mask **อัตโนมัติบน screenshot** — image-based PII (face, signature, ID card) AI mask ไม่ครอบคลุม → user ต้องทำเอง
- 🚫 ห้ามใส่ evidence ลง `standards/` หรือ `templates/` — vault context folder เท่านั้น
- 🚫 ห้ามลบ evidence ใน manifest — flag เป็น `status: superseded` แทน
- 🚫 ห้ามแก้ source doc นอก `## Evidence` section
- 🚫 ห้ามแต่ง E### ที่ไม่มีไฟล์จริง (no-fake-evidence)
- ⚠️ Size > 10MB → warn (พิจารณา link external store แทน)
- 💡 Mask log อัตโนมัติ: email/phone regex ทำได้; screenshot ต้อง manual

## Related

- ก่อน `/bda-evidence`: [/bda-test](./bda-test.md) (สร้าง raw evidence ใน Tier 1), [/bda-implement](./bda-implement.md) (subagent capture)
- หลัง `/bda-evidence`: [/bda-upload](./bda-upload.md) (share GDrive), [/bda-verify](./bda-verify.md) (audit manifest)
- Strategy: [`EVIDENCE-PATHS.md`](../EVIDENCE-PATHS.md) — 3 tiers (raw → curated → uploaded)
- Template: `standards/templates/evidence-manifest.md`

## FAQ

**Q: ผมต้องรัน `/bda-evidence` ทุกครั้งหลัง test ไหม?**
A: ถ้า test ผ่าน `/bda-test` แล้ว → subagent vault evidence ให้แล้วใน Tier 1 → `/bda-evidence` ใช้เมื่อต้องการ curate ไปใส่ context folder + mask PII ก่อน share

**Q: ความต่าง Tier 1/2/3 คือ?**
A: Tier 1 = raw (gitignored), Tier 2 = curated (gitTracked, masked), Tier 3 = uploaded (GDrive link ใน manifest) — ดู `EVIDENCE-PATHS.md`

**Q: ถ้าลืม mask แล้ว commit ไปแล้ว?**
A: `/bda-evidence audit` จะ flag → run `git filter-repo` + rotate URL/credential ถ้าเกี่ยว
