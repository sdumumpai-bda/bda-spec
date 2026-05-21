# /bda-sync

> **Sync BDA Standard snapshot** — pull update ล่าสุดจาก org repo แล้วทับ `standards/`

[← กลับ usage/README](./README.md) · [Full spec: `commands/bda-sync.md`](../commands/bda-sync.md)

## เมื่อไหร่ใช้

- มี policy ใหม่/template ใหม่ใน [`bda-ai-dev-standard`](https://github.com/BigDataAgency/bda-ai-dev-standard) อยาก pull ลง project
- `standards/VERSION` เก่า อยาก bump
- เริ่ม project ใหม่ + อยากมั่นใจว่าใช้ standard ล่าสุด

## Quick start

```
/bda-sync
```

ตัวอย่าง output:
```
Currently pinned: 0.4.1
Latest available: 0.4.3

Files to add:    3
Files to update: 5
Files to remove: 0

Update standards from 0.4.1 → 0.4.3?
[y/N]:
```

## รูปแบบเต็ม

```
/bda-sync                       # interactive — show diff + ask confirm
/bda-sync --check               # ดู version diff อย่างเดียว ไม่ดาวน์โหลด
/bda-sync --to <version>        # pin ไป version เฉพาะ (เช่น 0.6.0)
/bda-sync --dry-run             # show changes แต่ไม่ทำจริง
/bda-sync --force               # skip confirmation
```

| Flag | Default | ใช้สำหรับ |
|---|---|---|
| `--check` | off | preview version diff |
| `--to <ver>` | latest | pin ไปเวอร์ชันเก่า/เฉพาะ |
| `--dry-run` | off | ทำทุก phase ยกเว้น write |
| `--force` | off | ไม่ถาม confirm (ใช้ใน CI) |

## ขั้นตอนภายใน (Phase summary)

1. **Phase 1** — Read current pinned (`standards/VERSION`)
2. **Phase 2** — Fetch latest version จาก source repo (raw VERSION + tree API)
3. **Phase 3** — Diff (เทียบ blob sha)
4. **Phase 4** — Confirm กับ user (ถ้าไม่ `--force`)
5. **Phase 5** — Download + atomic swap **scope: `standards/` only** (สร้าง `standards.backup-<ts>` ก่อน)
6. **Phase 6** — Update `.bda-spec.yml` `standard.version` + `standard.last_synced`
7. **Phase 7** — Impact check (template overrides ที่ user แก้ใน `templates/` ยัง compatible ไหม)
8. **Phase 8** — Log ลง checkin + `standards/SYNC-HISTORY.md`

## Output ที่ได้

- `standards/` ที่อัพเดต (ทับเฉพาะ folder นี้)
- `standards.backup-<YYYYMMDD-HHMMSS>/` (rollback ได้)
- `.bda-spec.yml` update 2 field: `standard.version`, `standard.last_synced`
- `standards/SYNC-HISTORY.md` (append-only changelog)
- Checkin entry: `HH:MM — [type/sync] /bda-sync 0.4.1 → 0.4.3 — files: ~5, +3, -0`

## Workflow ที่นิยม

ตัวอย่าง: routine monthly sync
```
1. /bda-sync --check              ← เช็คก่อน
2. /bda-sync                       ← confirm + ทำจริง
3. (ตรวจ templates/ overrides ของ project ว่ายัง compat)
4. /bda-git --message "chore: sync BDA standard 0.4.3"
```

ตัวอย่าง: pin ไป version เก่า (rollback)
```
/bda-sync --to 0.4.1
```

## Gotchas / ข้อควรระวัง

- 🚫 **ห้ามแตะ folder อื่นเด็ดขาด** — sync แค่ `standards/` เท่านั้น ถ้าเจอ path นอก scope → abort + restore backup
- 🚫 ห้ามแก้ `standards/` ด้วยมือ — แก้ผ่าน feedback loop ที่ `bda-ai-dev-standard` repo ก่อน (ทุกไฟล์มี banner "READ-ONLY · DO NOT EDIT")
- 🚫 ห้ามใส่ template ของ project เข้า `standards/templates/` — ใส่ `templates/` แทน
- ⚠️ `.bda-spec.yml` `.bda-spec.local.yml` ไม่ถูกแตะ — sync แค่ bump `standard.version` ของไฟล์เดียว
- 💡 เก็บ backup อย่างน้อย 3 อันล่าสุด — `rm -rf standards.backup-*` ทีหลังถ้าเก่าเกิน
- 💡 ถ้า public repo + standard เป็น private → ต้อง `GITHUB_TOKEN` env var

## Related

- ก่อน `/bda-sync`: ดู [`CHANGELOG.md`](https://github.com/BigDataAgency/bda-ai-dev-standard/blob/main/CHANGELOG.md) ของ standard repo
- หลัง `/bda-sync`: ตรวจ `templates/` overrides แล้ว run `/bda-test` smoke test
- Override personal: ใส่ใน `.bda-spec/local/templates/<name>.md` (priority สูงสุด — sync ไม่ทับ)
- Override team: ใส่ใน `templates/<name>.md` (gitTracked — sync ไม่ทับ)

## FAQ

**Q: ถ้า sync ทับ template ของผมล่ะ?**
A: ไม่ทับ — sync แตะแค่ `standards/templates/` ของ project lookup chain: `.bda-spec/local/templates/` > `templates/` > `standards/templates/` — สองตัวแรกไม่ถูก sync

**Q: rollback ยังไง?**
A: `rm -rf standards && mv standards.backup-<ts> standards && yq -i '.standard.version = "<old>"' .bda-spec.yml`

**Q: ใน CI ใช้ยังไง?**
A: `/bda-sync --force --to <pinned-version>` — pin ไป version เฉพาะ ไม่ถาม confirm
