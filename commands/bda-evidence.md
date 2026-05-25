---
description: Capture, mask, validate, store evidence (screenshot, log, trace, test-report) + update manifest
model: claude-sonnet-4-6
---

# /bda-evidence — Evidence Capture (แยกจาก /bda-checkin)

จัดการ evidence ที่เกิดจาก manual test, debug, demo, audit
ทำ masking (PII), validate (size/format), store ใน vault, update manifest

> **ทำไมแยกจาก /bda-checkin:** evidence อาจเกิดหลายครั้งต่อวัน + เกี่ยวข้องกับ feature/fix/test เฉพาะ ไม่ใช่แค่บันทึกใน daily log

## Trigger

```
/bda-evidence                              # interactive — ถามรายละเอียด
/bda-evidence <source-path>                # ระบุ path ของ raw evidence
/bda-evidence --from-staging               # ใช้ทุกอย่างใน paths.evidence_staging
/bda-evidence --link-to <plan|fix|test>    # ระบุ context ตั้งแต่ trigger
/bda-evidence --upload                     # หลัง store → trigger /bda-upload ทันที (GDrive)
/bda-evidence list                         # แสดง evidence ของ feature/fix/plan
/bda-evidence verify                       # ตรวจ manifest vs file system
/bda-evidence audit                        # ตรวจ PII/secret ใน evidence ที่ commit ไปแล้ว
```

## Phase 0 — Resolve config + detect source

```bash
eval "$(bash scripts/bda-paths.sh --shell)"

# evidence_staging จาก .bda-spec.local.yml (เฉพาะของ user)
echo "Staging: $EVIDENCE_STAGING"

# ถ้า user ไม่ระบุ source → list ไฟล์ใหม่ใน staging
if [ -z "$SOURCE" ] && [ -d "$EVIDENCE_STAGING" ]; then
  find "$EVIDENCE_STAGING" -mmin -1440 -type f | head -20
fi
```

## Phase 1 — รับ + classify

ถาม user (batch):

1. **Source path(s)**: ที่อยู่ของไฟล์ดิบ (1 หรือหลายไฟล์)
2. **Type**:
   - `screenshot` — image/png, jpg
   - `log` — text log file
   - `trace` — network/perf trace (HAR, chrome trace, OpenTelemetry)
   - `test-report` — JUnit XML, Playwright report, Cypress, etc.
   - `recording` — video/gif
   - `file` — other artifact (json/yaml/csv export)
3. **Link to context**:
   - Feature: `<slug>` หรือ FEAT-*
   - Fix: fix-log path
   - Plan: plan path
   - Test: test plan / test scenario
   - General: ไม่ link เฉพาะ
4. **PII status**:
   - `clean` — ไม่มี PII (e.g., dummy data)
   - `masked` — มี PII แต่ mask แล้ว
   - `raw` — มี PII ยังไม่ mask (จะถูก mask ใน Phase 3)
5. **Safe to share** (commit ใน repo public): yes/no

## Phase 2 — Validate

```bash
# Size limit
[ "$(stat -f%z "$FILE" 2>/dev/null || stat -c%s "$FILE")" -gt $((10 * 1024 * 1024)) ] \
  && echo "WARN: file > 10 MB — consider linking external store"

# Format check
case "$TYPE" in
  screenshot)  file "$FILE" | grep -E "image|PNG|JPEG" ;;
  log)         file "$FILE" | grep -E "text|ASCII" ;;
  test-report) head -3 "$FILE" ;;
esac

# Filename sanitization — must match: <SCENARIO>-<STEP>-<state>.png pattern
# (จาก BDA test-scenario standard)
```

ถ้าไม่ผ่าน validate → reject + suggest แก้

## Phase 3 — Mask PII (ถ้า raw)

```bash
# Screenshot: ใช้ external tool (user pre-installed) เช่น Skitch, macOS Preview
# Command นี้ไม่ทำเอง — แต่:
#   1. แจ้ง user ว่าต้อง mask อะไร (email, ชื่อ-นามสกุล, เบอร์, ID card, address)
#   2. รอ user save masked version
#   3. Re-check (manual review)

# Log: regex mask
sed -E 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+/[email-redacted]/g' "$IN" > "$OUT"
sed -E 's/0[0-9]{9}/[phone-redacted]/g' "$OUT"
```

ห้ามทำ mask อัตโนมัติบน screenshot — image-based PII (face, signature, paper ID) AI mask ไม่ครอบคลุม
**user ต้อง confirm masking ด้วยตา**

## Phase 4 — Store ใน vault

Path convention:

```
docs/<vault>/<context-folder>/<context-slug>/evidence/<filename>
```

โดย `<context-folder>`:
| Type | Folder |
|---|---|
| Feature evidence | `20-Features/<FEAT-slug>/evidence/` |
| Fix evidence | `85-FixLog/<fix-slug>/evidence/` หรือ `85-FixLog/<file>.evidence/` |
| Plan evidence | `80-ImplementPlan/<plan-slug>.evidence/` |
| Test scenario | `90-TestPlan/<TP-slug>/evidence/` |
| Handoff | `95-Handoff/<HOR-slug>.evidence/` |
| Project-wide | `60-Flows/evidence/` หรือ `00-Index/evidence/` |

Filename: `<SCENARIO-ID>-<STEP>-<state>-<HHMMSS>.<ext>` (อิง BDA test standard)
ตัวอย่าง: `TC-Checkout-001-03-submit-success-143022.png`

```bash
cp "$SRC" "$DEST"
chmod 644 "$DEST"
```

## Phase 5 — Update manifest

Manifest อยู่ที่ `<context-folder>/<slug>/evidence-manifest.md`:

```markdown
---
tags: [type/evidence-manifest]
context: feature:checkout    # หรือ fix/plan/test
updated: 2026-05-21 14:30
items: 5
---

# Evidence Manifest — FEAT-Checkout

| ID | File | Type | Captured | Scenario/Step | PII | Masked | Safe-to-share | Notes |
|---|---|---|---|---|---|---|---|---|
| E001 | TC-Checkout-001-03-submit-success-143022.png | screenshot | 2026-05-21 14:30 | TC-001 step 3 | none | n/a | ✓ | checkout success state |
| E002 | TC-Checkout-001-04-receipt-printed-143105.png | screenshot | 2026-05-21 14:31 | TC-001 step 4 | masked-email | ✓ | ✓ | receipt header masked |
| E003 | api-trace-checkout-143200.har | trace | 2026-05-21 14:32 | TC-001 e2e | none | n/a | ✓ | full network trace |
```

Append entry — ห้าม overwrite manifest เดิม

## Phase 6 — Link จาก source doc

อัพเดท source doc (plan/fix/test/feature) เพิ่ม link ไป evidence:

```markdown
<!-- in plan or fix file -->

## Evidence
- [[E001]] checkout success state (screenshot)
- [[E002]] receipt printed (screenshot, masked)
- [[E003]] full API trace (HAR)
```

ห้ามแก้ section อื่น

## Phase 6.5 — Optional GDrive upload (`--upload` flag)

ถ้า user ระบุ `--upload` หรือ `.bda-spec.local.yml` มี `evidence_upload.auto_upload_on_evidence: true`:

```bash
# Trigger /bda-upload สำหรับ items ที่เพิ่งสร้าง
bash scripts/upload-evidence.sh --feature "$CONTEXT_SLUG" --pending
```

หลัง upload สำเร็จ:
- manifest row ของ items ที่เพิ่งสร้างจะมี GDrive Link, Uploaded At, Uploaded By ใส่อัตโนมัติ
- daily checkin เพิ่ม line: `- HH:MM — /bda-upload — N items uploaded`

ถ้า `evidence_upload.gdrive_folder` ยังไม่ตั้งค่า → command จะเตือนให้ตั้งค่าใน `.bda-spec.local.yml` แทน — ไม่ block phase 7

## Phase 7 — Update IMPLEMENTATION-STATUS + checkin

อัพเดท `docs/obsidian-vault/00-Index/IMPLEMENTATION-STATUS.md`:
- Evidence count for feature/fix
- Last evidence captured timestamp

Append to today's checkin Notes:
```
- HH:MM — [type/evidence] /bda-evidence FEAT-Checkout — 3 items added (E001-E003)
```

## Phase 8 — Audit mode (`audit`)

Scan all evidence files ใน repo:
- Find unmasked PII (email regex, phone regex, common name patterns)
- Find unflagged-but-questionable filenames (e.g., `customer-data.csv`)
- Check manifest count vs filesystem count

Report ที่ `docs/obsidian-vault/95-Handoff/EVIDENCE-AUDIT-<date>.md`

## Output (5 หัวข้อบังคับ)

1. **BDA Standard files used** — `.bda-spec/STANDARD.md`, `.bda-spec/policies/no-fake-evidence.md`, `.bda-spec/templates/evidence-manifest.md`
2. **Pipeline trace** — Understand (Phase 0) → Plan (Phase 1 classify) → Execute (Phase 2-6 validate/mask/store/link) → Verify (manifest count == FS count)
3. **Commands run** — `cp`, `sed` (mask), validation greps
4. **Verification / Evidence** — manifest entries added, file paths, PII flag status
5. **Limitations / Risks / Next steps** — unmasked items waiting, unsafe-to-share count, large files > 10MB

## ห้าม

- **ห้าม commit evidence ที่ `pii: raw` หรือ `masked: ✗` ลงสาธารณะ** — block
- ห้าม mask อัตโนมัติบน screenshot โดยไม่ user review — image-based PII ต้อง manual confirm
- ห้ามใส่ evidence ลง `.bda-spec/` หรือ `templates/` — ใส่เฉพาะ vault context folder
- ห้ามลบ evidence ใน manifest — แค่ flag เป็น `status: superseded` + เพิ่มใหม่
- ห้ามแก้ source doc นอก `## Evidence` section
- ห้ามแต่ง E### ที่ไม่มีไฟล์จริง — ห้าม fake evidence (`policies/no-fake-evidence.md`)
