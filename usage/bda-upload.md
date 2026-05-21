# /bda-upload

> **Upload evidence ไป GDrive** (rclone) — ผ่าน HARD gates (PII/safe-to-share) → ใส่ link ใน manifest

[← กลับ usage/README](./README.md) · [Full spec: `commands/bda-upload.md`](../commands/bda-upload.md)

## เมื่อไหร่ใช้

- หลัง `/bda-evidence` mask + curate แล้ว — ต้อง share link กับผู้บริหาร/ลูกค้า
- Pending evidence ที่ยังไม่มี `gdrive_link` ใน manifest
- Daily report — ต้องการ link คลิกได้ใน `/bda-checkin end`
- Retry uploads ที่ fail

## Quick start

```
/bda-upload --pending
```

ตัวอย่าง output:
```
📦 Evidence summary
  Total entries: 45
  ✅ Uploaded: 28 (62%)
  ⏳ Pending upload: 15
  🚫 Blocked: 2 (pii: raw หรือ safe_to_share: no)

Pending breakdown:
  FEAT-Checkout/evidence: 6 items (4.2 MB)
  85-FixLog/.../evidence: 3 items (0.8 MB)
  90-TestPlan/.../evidence: 6 items (12 MB)

Total upload size: ~17 MB
[y/N]:
```

## รูปแบบเต็ม

```
/bda-upload                                   # interactive
/bda-upload --feature <slug>                  # อัปโหลดเฉพาะ feature
/bda-upload --plan <path>                     # เฉพาะ plan
/bda-upload --fix <path>                      # เฉพาะ fix-log
/bda-upload --since <date>                    # evidence ตั้งแต่ <date>
/bda-upload --pending                         # ทุกตัวที่ไม่มี gdrive_link
/bda-upload --dry-run                         # show what would upload
/bda-upload --provider gdrive|s3|dropbox|onedrive
/bda-upload status                            # dashboard
/bda-upload retry-failed                      # retry uploads ที่ fail
```

| Flag | Default | ใช้สำหรับ |
|---|---|---|
| `--pending` | n/a | bulk upload all w/o gdrive_link |
| `--dry-run` | off | preview เท่านั้น |
| `--provider <p>` | gdrive | rclone remote provider |
| `--force` | off | bypass size limit (50MB) — gates อื่นห้ามข้าม |

## Pre-flight setup

ใน `.bda-spec.local.yml`:
```yaml
evidence_upload:
  provider: gdrive
  rclone_remote: bda-gdrive
  gdrive_folder: BDA-Evidence/MyProject
  link_visibility: org           # private | org | anyone
  auto_upload_on_evidence: false
```

ก่อนใช้ครั้งแรก:
```
rclone config           # สร้าง remote 'bda-gdrive' (type: drive)
rclone lsd bda-gdrive:  # ทดสอบ
```

## ขั้นตอนภายใน (Phase summary)

1. **Phase 0** — Resolve config (`.bda-spec.local.yml`)
2. **Phase 1** — Scan pending evidence (filter: ไม่มี gdrive_link, pii != raw, safe_to_share != no)
3. **Phase 2** — Validate HARD gates (6 gates)
4. **Phase 3** — Plan upload structure (by-date / by-feature / flat)
5. **Phase 4** — Upload via rclone + get shareable link + set permissions
6. **Phase 5** — Update manifests (3 columns: GDrive Link, Uploaded At, Uploaded By)
7. **Phase 6** — Update today's checkin (append link list)
8. **Phase 7** — Mirror to executive folder (`daily_log_mirror`)
9. **Phase 8** — Status mode (dashboard)
10. **Phase 9** — Cleanup (optional — default off)

## HARD gates (Phase 2)

| Gate | ทำอะไร |
|---|---|
| 1. PII status | skip ถ้า `pii: raw` |
| 2. Safe to share | skip ถ้า `safe_to_share: no` |
| 3. Masked check | skip ถ้า `pii: masked` แต่ `masked: ✗` |
| 4. File exists | skip ถ้า local file หาย |
| 5. Size limit | skip ถ้า > 50MB (override ด้วย `--force`) |
| 6. System file | skip ถ้าอยู่ใน `standards/`, `templates/`, `.bda-spec/` |

## Output ที่ได้

- Upload files ขึ้น GDrive folder `<GDRIVE_FOLDER>/<YYYY-MM-DD>/<context-slug>/`
- Manifest update (3 columns ใหม่):
  ```
  | E001 | ... | screenshot | ... | ✓ | https://drive.google.com/... | 2026-05-21 17:45 | supasin |
  ```
- Checkin entry: `HH:MM — [type/upload] /bda-upload — 15 items uploaded, 2 blocked`
- Executive mirror file (ถ้าตั้ง `daily_log_mirror`)

## Workflow ที่นิยม

ตัวอย่าง 1: end-of-day chain
```
1. /bda-evidence (curate วันนี้)
2. /bda-upload --pending                ← bulk upload
3. /bda-checkin end                      ← link จาก manifest ใส่ executive summary
```

ตัวอย่าง 2: per-feature share
```
/bda-upload --feature checkout --link-visibility org
  → ส่ง link เฉพาะคนใน domain (bda.co.th)
```

ตัวอย่าง 3: dashboard
```
/bda-upload status

📊 Evidence Status — Library Book Tracker
By context:
  FEAT-Checkout:    18 total · 15 uploaded · 2 pending · 1 blocked
  FEAT-Returns:      8 total ·  8 uploaded · 0 pending · 0 blocked
Blocked items (need attention):
  1. FEAT-Checkout/E007 — pii: raw (need masking)
```

## Gotchas / ข้อควรระวัง

- 🚫 **ห้ามอัปโหลด evidence ที่ `pii: raw` หรือ `safe_to_share: no`** — **เด็ดขาด ไม่มี `--force` ข้าม**
- 🚫 ห้าม fake `gdrive_link` — ถ้า upload fail ใส่ `[FAILED: <reason>]`
- 🚫 ห้าม upload `standards/`, `templates/`, `.bda-spec/`, `commands/` — ไม่ใช่ evidence
- 🚫 ห้ามตั้ง `link_visibility: anyone` โดยไม่ confirm — default: org
- 🚫 ห้ามลบ local file หลัง upload เว้นแต่ explicit `cleanup_local_after_upload: true`
- 🚫 ห้ามใส่ secret/credential ใน file ที่ upload — รัน `/bda-secure` ก่อน
- 🚫 ห้ามแก้ manifest column ที่ไม่ใช่ 3 columns (GDrive Link, Uploaded At, Uploaded By)
- ⚠️ ถ้า GDrive config ไม่มี — command exit + แสดง config example
- 💡 ใช้ `rclone` รองรับ 70+ providers (gdrive/s3/dropbox/onedrive/etc.)

## Related

- ก่อน `/bda-upload`: [/bda-evidence](./bda-evidence.md) (mask + curate), [/bda-secure](./bda-secure.md) (scan secrets)
- หลัง `/bda-upload`: [/bda-checkin](./bda-checkin.md) end (link ใส่ executive summary)
- Strategy: [`EVIDENCE-PATHS.md`](../EVIDENCE-PATHS.md) Tier 3
- Helper: `scripts/upload-evidence.sh`

## FAQ

**Q: ผมไม่มี rclone — ใช้ command อื่นได้ไหม?**
A: ปัจจุบัน hardcode rclone (รองรับ provider เยอะ + signed URLs); ติดตั้ง `brew install rclone` หรือ `apt install rclone`

**Q: ถ้า upload fail กลางทาง?**
A: `/bda-upload retry-failed` — re-attempt items ที่ manifest มี `[FAILED]` marker

**Q: ต่าง `auto_upload_on_evidence` กับ `/bda-upload` ทันที?**
A: ถ้า `true` → `/bda-evidence` จะ chain `/bda-upload` อัตโนมัติ; ถ้า `false` → user ต้องเรียกเอง
