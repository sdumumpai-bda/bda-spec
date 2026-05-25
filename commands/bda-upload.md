---
description: Upload evidence (screenshots, logs, traces, test reports) to Google Drive / cloud storage and update manifest with shareable links
model: claude-sonnet-4-6
---

# /bda-upload — Upload Evidence to GDrive / Cloud

อัปโหลด evidence ที่ผ่าน masking + safe-to-share check แล้วขึ้น Google Drive (หรือ cloud provider อื่น) → ได้ shareable link → update manifest ให้ link ใช้ใน `/bda-checkin` ได้ทันที

> **เพิ่งสร้างใน v0.3.0 ของ bda-spec** — เกิดจาก user ต้องการให้ AI test → capture screenshot → upload สำหรับส่ง daily log ผู้บริหาร

## Trigger

```
/bda-upload                                   # interactive — แสดง pending + ถาม
/bda-upload --feature <slug>                  # อัปโหลดเฉพาะ feature
/bda-upload --plan <path>                     # อัปโหลดเฉพาะ plan
/bda-upload --fix <path>                      # อัปโหลดเฉพาะ fix-log
/bda-upload --since <date>                    # อัปโหลด evidence ที่บันทึกตั้งแต่ <date>
/bda-upload --pending                         # อัปโหลดทุก evidence ที่ยังไม่มี gdrive_link
/bda-upload --dry-run                         # show what would upload, ไม่จริง
/bda-upload --provider gdrive|s3|dropbox|onedrive    # default: gdrive
/bda-upload status                            # แสดง status ของ evidence ทั้งหมด (uploaded / pending / blocked)
/bda-upload retry-failed                      # retry uploads ที่ fail
```

## Phase 0 — Resolve config

```bash
eval "$(bash scripts/bda-paths.sh --shell)"

# GDrive config จาก .bda-spec.local.yml (personal — gitignored)
GDRIVE_FOLDER=$(yget .bda-spec.local.yml "evidence_upload.gdrive_folder")
GDRIVE_REMOTE=$(yget .bda-spec.local.yml "evidence_upload.rclone_remote")  # default "gdrive"
PROVIDER=$(yget .bda-spec.local.yml "evidence_upload.provider")            # default "gdrive"
LINK_VISIBILITY=$(yget .bda-spec.local.yml "evidence_upload.link_visibility") # private / org / anyone

[ -z "$GDRIVE_FOLDER" ] && {
  echo "❌ ยังไม่ได้ตั้งค่า evidence_upload.gdrive_folder ใน .bda-spec.local.yml"
  echo ""
  echo "ตัวอย่าง config:"
  echo "  evidence_upload:"
  echo "    provider: gdrive"
  echo "    rclone_remote: bda-gdrive"
  echo "    gdrive_folder: BDA-Evidence/MyProject"
  echo "    link_visibility: org           # private | org | anyone"
  echo "    auto_upload_on_evidence: false"
  exit 1
}
```

ถ้าใช้ครั้งแรก → guide setup rclone:
```
rclone config           # สร้าง remote 'bda-gdrive' โดย type=drive
rclone lsd bda-gdrive:  # ทดสอบ
```

## Phase 1 — Scan pending evidence

```bash
# หา evidence manifest ทั้งหมดใน vault
MANIFESTS=$(find "$VAULT_ABS"/{20-Features,80-ImplementPlan,85-FixLog,90-TestPlan,95-Handoff} \
            -name "evidence-manifest.md" 2>/dev/null)

# extract evidence entries ที่ยังไม่มี gdrive_link
pending=()
for m in $MANIFESTS; do
  awk -F'|' '/^\| E[0-9]+/ { print $1 "|" m "|" $2 "|" $7 "|" $8 }' m="$m" "$m"
done | while read row; do
  # filter: ไม่มี gdrive_link AND pii != raw AND safe_to_share != no
  ...
done
```

แสดง summary:
```
📦 Evidence summary

  Total entries:     45
  ✅ Uploaded:       28 (62%)
  ⏳ Pending upload: 15
  🚫 Blocked:        2 (pii: raw หรือ safe_to_share: no)

Pending breakdown by context:
  FEAT-Checkout/evidence:       6 items (4.2 MB)
  85-FixLog/.../evidence:       3 items (0.8 MB)
  90-TestPlan/.../evidence:     6 items (12 MB — includes 1 video)

Total upload size: ~17 MB
```

## Phase 2 — Validate before upload (HARD gates)

ทุก item ที่จะ upload ต้องผ่าน:

```bash
for item in pending; do
  # Gate 1: PII status
  [ "$pii" = "raw" ] && { skip "raw PII"; continue; }

  # Gate 2: safe_to_share
  [ "$safe_to_share" = "no" ] && { skip "marked unsafe"; continue; }

  # Gate 3: masked check
  [ "$pii" = "masked" ] && [ "$masked" != "✓" ] && {
    skip "marked has PII but not masked"; continue
  }

  # Gate 4: file exists locally
  [ -f "$local_path" ] || { skip "file missing"; continue; }

  # Gate 5: size limit (configurable, default 50 MB per file)
  size=$(stat -f%z "$local_path" 2>/dev/null || stat -c%s "$local_path")
  [ "$size" -gt $((50 * 1024 * 1024)) ] && {
    skip "exceeds 50 MB — link via external store instead"; continue
  }

  # Gate 6: not in .bda-spec/ or templates/
  case "$local_path" in
    .bda-spec/*|templates/*|.bda-spec/*) skip "system file"; continue ;;
  esac

  ok+=("$item")
done
```

ถ้า user ระบุ `--force` → ข้าม gate 5 เท่านั้น (size); gates อื่นห้ามข้าม

## Phase 3 — Plan upload structure

GDrive folder layout:
```
<GDRIVE_FOLDER>/                            # เช่น "BDA-Evidence/Library-Tracker"
├── YYYY-MM-DD/                              # 1 folder/วัน
│   ├── FEAT-Checkout/
│   │   ├── E001-checkout-success.png
│   │   ├── E002-receipt-printed.png
│   │   └── E003-api-trace.har
│   ├── fix-2026-05-20-search-empty/
│   │   └── E001-repro.png
│   └── TP-Checkout/
│       └── ...
└── _index.md                                # manifest หลัก (เพิ่มทุกครั้ง)
```

หรือถ้า user override ใน `.bda-spec.local.yml`:
```yaml
evidence_upload:
  folder_structure: "by-feature"   # by-date | by-feature | flat
  filename_prefix_date: true       # YYYY-MM-DD-E001-... vs E001-...
```

## Phase 4 — Upload via rclone (default)

```bash
for item in ok; do
  src="$local_path"
  dst_folder="${GDRIVE_FOLDER}/${TODAY}/${context_slug}"
  dst_name=$(basename "$src")

  # Create remote folder (idempotent)
  rclone mkdir "${GDRIVE_REMOTE}:${dst_folder}" 2>/dev/null

  # Upload
  rclone copy "$src" "${GDRIVE_REMOTE}:${dst_folder}" \
    --transfers 4 --check-first --progress

  # Get shareable link
  link=$(rclone link "${GDRIVE_REMOTE}:${dst_folder}/${dst_name}" 2>&1)

  # Set permissions ตาม link_visibility (rclone supports --drive-shared-with-me etc)
  case "$LINK_VISIBILITY" in
    private)  ;;  # default; only owner
    org)      rclone backend set "${GDRIVE_REMOTE}:${dst_folder}/${dst_name}" \
              --domain-share="${ORG_DOMAIN:-bda.co.th}" ;;
    anyone)   rclone backend set "${GDRIVE_REMOTE}:${dst_folder}/${dst_name}" \
              --shared-with-anyone ;;
  esac

  # Update manifest
  update_manifest_row "$item_id" "$link" "$TODAY $(date +%H:%M)" "$USER"
done
```

ถ้าใช้ provider อื่น (s3/dropbox/onedrive) → ก็ใช้ rclone remote ของ provider นั้น (rclone รองรับ 70+ providers)

## Phase 5 — Update manifests

สำหรับแต่ละ item ที่ upload สำเร็จ:

```markdown
| ID | File | Type | Captured | Scenario/Step | PII | Masked | Safe-to-share | GDrive Link | Uploaded At | Uploaded By |
|---|---|---|---|---|---|---|---|---|---|---|
| E001 | ... | screenshot | 2026-05-21 14:30 | TC-001 step 3 | none | n/a | ✓ | https://drive.google.com/... | 2026-05-21 17:45 | supasin |
```

เพิ่ม columns ในตอนแรกที่ /bda-evidence สร้าง manifest:
- `GDrive Link` (เริ่มว่าง)
- `Uploaded At` (เริ่มว่าง)
- `Uploaded By` (เริ่มว่าง)

`/bda-upload` แค่ fill 3 columns นี้

## Phase 6 — Update checkin (today's daily log)

Append ใน `docs/obsidian-vault/75-Checkins/<today>.md` Notes:

```markdown
- HH:MM — [type/upload] /bda-upload — 15 items uploaded ({contexts}), 2 blocked
  - Evidence URLs (for executive summary):
    - FEAT-Checkout E001: https://drive.google.com/...
    - FEAT-Checkout E002: https://drive.google.com/...
    - ...
```

## Phase 7 — Mirror to executive folder (optional)

ถ้า `paths.daily_log_mirror` set ใน `.bda-spec.local.yml`:
```bash
if [ -n "$DAILY_LOG_MIRROR" ]; then
  # Generate a "executive evidence index" — single markdown with all today's links
  cat > "$DAILY_LOG_MIRROR/${TODAY}-evidence.md" <<EOF
# Evidence Links — ${TODAY} — ${PROJECT_NAME}

[Pipeline trace + 5 mandatory sections]

## Evidence captured today

| Context | Item | Type | Link |
|---|---|---|---|
$(for ev in uploaded_today; do
  echo "| $context | $item_id | $type | [$filename]($gdrive_link) |"
done)

## Pending evidence (not uploaded yet)
- ...
EOF
fi
```

Executive ที่เปิด central vault จะเห็น today's evidence ทันที พร้อมคลิก link ไปดูใน GDrive

## Phase 8 — Status mode (`status`)

แสดง dashboard ของ evidence ทั้ง project:

```
📊 Evidence Status — Library Book Tracker

By context:
  FEAT-Checkout:    18 total  · 15 uploaded  · 2 pending  · 1 blocked
  FEAT-Returns:      8 total  ·  8 uploaded  · 0 pending  · 0 blocked
  85-FixLog:         5 total  ·  3 uploaded  · 2 pending  · 0 blocked
  90-TestPlan:      14 total  · 14 uploaded  · 0 pending  · 0 blocked

By date (last 7 days):
  2026-05-21:  6 items  · 6 uploaded
  2026-05-20:  4 items  · 4 uploaded
  ...

Blocked items (need attention):
  1. FEAT-Checkout/E007  — pii: raw (need masking)
  2. FEAT-Checkout/E012  — safe_to_share: no (private customer data)

Storage:
  Local total:        ~125 MB
  GDrive uploaded:    ~118 MB
  GDrive folder:      BDA-Evidence/Library-Tracker
```

## Phase 9 — Cleanup (optional)

ถ้า config มี `evidence_upload.cleanup_local_after_upload: true`:
- ลบ local copy ของ evidence ที่ upload สำเร็จ (เพื่อประหยัด disk)
- เก็บ manifest ไว้ (มี gdrive_link สำหรับ reference)
- **default: false** — เก็บ local ไว้เสมอเพื่อ safety

## Output (5 หัวข้อบังคับ)

1. **BDA Standard files used** — `.bda-spec/STANDARD.md`, `.bda-spec/policies/no-fake-evidence.md`, `.bda-spec/templates/evidence-manifest.md`
2. **Pipeline trace** — Understand (Phase 0/1 scan) → Plan (Phase 3 structure) → Execute (Phase 4 upload) → Verify (Phase 8 status / file exists in GDrive)
3. **Commands run** — `rclone copy`, `rclone link`, manifest updates
4. **Verification / Evidence** — items uploaded count, total size, gdrive folder, sample link (cite จริงไม่ fake)
5. **Limitations / Risks / Next steps** — blocked items + reasons, pending PII masking, oversize files, network failures

## ห้าม

- **ห้ามอัปโหลด evidence ที่ `pii: raw` หรือ `safe_to_share: no`** — เด็ดขาด ไม่มี --force ข้าม
- ห้าม fake gdrive_link — ถ้า upload fail ให้ใส่ `[FAILED: <reason>]` ใน manifest
- ห้าม upload `.bda-spec/`, `templates/`, `.bda-spec/`, `commands/` — ไม่ใช่ evidence
- ห้ามตั้งค่า `link_visibility: anyone` โดยไม่ confirm กับ user (default: org)
- ห้ามลบ local file หลัง upload ถ้า config ไม่ explicit set `cleanup_local_after_upload: true`
- ห้ามใส่ secret/credential ใน file ที่ upload — `/bda-secure` ควรรันก่อน
- ห้ามแก้ manifest column ที่ไม่ใช่ GDrive Link / Uploaded At / Uploaded By
