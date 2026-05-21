---
description: Sync latest BDA AI Dev Standard snapshot into standards/ and bump pinned version
model: claude-sonnet-4-6
---

# bda-sync — Sync BDA AI Dev Standard snapshot

Pull latest standard จาก `bda-ai-dev-standard` repo → update `standards/` snapshot + bump version

## Trigger

```
/bda-sync                       # interactive — show diff + ask confirm
/bda-sync --check               # check version difference, ไม่ดาวน์โหลด
/bda-sync --to <version>        # pin ไป version เฉพาะ
/bda-sync --dry-run             # show changes แต่ไม่จริง
/bda-sync --force               # skip confirmation
```

## Phase 1 — Read current pinned

```bash
current=$(cat standards/VERSION 2>/dev/null || echo "0.0.0")
echo "Currently pinned: $current"
```

## Phase 2 — Fetch latest from source

```bash
source_url=$(yq '.standard.source' .bda-spec.yml)
# Default: https://github.com/BigDataAgency/bda-ai-dev-standard

# Public repo — use raw VERSION + tree API
latest=$(curl -fsSL "https://raw.githubusercontent.com/BigDataAgency/bda-ai-dev-standard/main/VERSION" | tr -d '[:space:]')
echo "Latest available: $latest"
```

ถ้า private repo → ต้อง GITHUB_TOKEN env var

## Phase 3 — Diff

```bash
# Fetch tree
tree=$(curl -fsSL "https://api.github.com/repos/BigDataAgency/bda-ai-dev-standard/git/trees/main?recursive=1")

# Compare แต่ละ blob hash กับ local snapshot
# (implementation: ทำ sha1 ของ local file vs blob.sha)
```

แสดง diff:
```
Files to add:    3
Files to update: 5
Files to remove: 0

Detail:
+ standards/policies/new-policy.md
~ standards/STANDARD.md (changed: lines 12-15)
~ standards/templates/handoff.md (template format updated)
- (none)
```

## Phase 4 — Confirm

ถ้าไม่ `--force` หรือ `--dry-run` → ถาม user confirm

```
Update standards from 0.4.1 → 0.4.3?
  Files to update: 5
  Files to add: 3
  Breaking changes? See CHANGELOG.

[y/N]:
```

## Phase 5 — Download + replace (SCOPE: standards/ only)

> ⚠️ **Scope guard** — `/bda-sync` แตะเฉพาะ `standards/` เท่านั้น
> ห้ามทับ `templates/`, `commands/`, `.claude/`, `docs/`, `.bda-spec.yml`,
> `.bda-spec.local.yml`, `.bda-spec/local/` ไม่ว่ากรณีใดๆ
> ถ้า template structure ของ standard เปลี่ยน → แค่ flag ให้ user review ใน Phase 7

```bash
# Pre-flight: verify ห้ามแตะของ project
PROTECTED=(
  templates
  commands
  .claude
  docs
  codex
  gemini
  prompts
  bin
  .bda-spec.yml
  .bda-spec.local.yml
  .bda-spec
  CLAUDE.md
  AI-README.md
  README.md
)
echo "Protected paths (จะไม่ถูกแตะ): ${PROTECTED[*]}"

mkdir -p standards.new
for path in <paths-to-update>; do
  # ทุก path ต้องขึ้นต้นด้วย standards/ — refuse otherwise
  case "$path" in
    standards/*) ;;
    *) echo "REFUSED non-standards path: $path"; exit 1 ;;
  esac
  curl -fsSL "https://raw.githubusercontent.com/.../main/${path#standards/}" \
    -o "standards.new/${path#standards/}"
done

# Atomic swap — ของเดิม backup ก่อน
backup_ts=$(date +%Y%m%d-%H%M%S)
cp -R standards "standards.backup-$backup_ts"
cp -R standards.new/. standards/   # merge เข้า (ไม่ทับ folder อื่น)
rm -rf standards.new

# Verify
test -f standards/STANDARD.md && test -f standards/VERSION && echo OK

# Verify: ห้ามมีไฟล์โผล่ใน folder อื่น
for p in "${PROTECTED[@]}"; do
  before=$(find "standards.backup-$backup_ts/../$p" -type f 2>/dev/null | wc -l)
  after=$(find "$p" -type f 2>/dev/null | wc -l)
  if [ "$before" -ne "$after" ]; then
    echo "⚠️ PROTECTED PATH MODIFIED: $p ($before → $after files)"
    echo "ABORTED — กลับไปใช้ backup"
    rm -rf standards && mv "standards.backup-$backup_ts" standards
    exit 2
  fi
done
```

## Phase 6 — Update .bda-spec.yml

```yaml
standard:
  source: <unchanged>
  version: "0.4.3"               # bumped
  snapshot_path: standards
  last_synced: "2026-05-20"
```

## Phase 7 — Run impact check

หลัง update:
- ตรวจว่า command/template paths ที่ user override ใน `templates/` ยังตรงกับ schema ใหม่ของ standard
- ถ้า template structure เปลี่ยน → flag user ให้ review project-level overrides
- ถ้า policy ใหม่ → แสดง summary ของ policy ใหม่

## Phase 8 — Log checkin + changelog

```markdown
- HH:MM — [type/sync] /bda-sync 0.4.1 → 0.4.3 — files: ~5, +3, -0
```

สร้าง `standards/SYNC-HISTORY.md` (append-only):
```markdown
## 2026-05-20 — 0.4.1 → 0.4.3
- Updated by: <user>
- Reason: routine sync / fixing X
- Changes: ~5 files, +3 files
- Breaking: none / list
- Reviewed by: <reviewer>
```

## Output (5 หัวข้อบังคับ)

1. **BDA Standard files used** — `.bda-spec.yml`, `standards/VERSION`
2. **Pipeline trace** — Understand (Phase 1-3) → Plan (Phase 4 confirm) → Execute (Phase 5-6) → Verify (test -f checks) → Handoff (Phase 8)
3. **Commands run** — curl commands, file moves
4. **Verification / Evidence** — new VERSION content, diff summary
5. **Limitations / Risks / Next steps** — template overrides ใน `templates/` ที่อาจ outdated, breaking changes ที่ต้อง update commands

## ห้าม

- ห้าม sync โดยไม่ backup `standards/`
- ห้ามแก้ `standards/` ด้วยมือ — แก้ผ่าน feedback loop ที่ bda-ai-dev-standard repo ก่อน
- ห้ามใส่ template ของ project เข้า `standards/templates/` — ใส่ `templates/` แทน
- **ห้ามแตะ folder อื่นโดยเด็ดขาด** — ถ้า sync ทับ `templates/`, `commands/`, `.claude/`, `docs/`, หรือ config ของ user → abort + restore backup ทันที
- ห้ามแก้ `.bda-spec.yml` หรือ `.bda-spec.local.yml` (เปลี่ยนแค่ `standard.version` + `standard.last_synced` ได้ผ่าน Phase 6)
- ห้ามลบ `standards.backup-*` โดยไม่บอก user — เก็บไว้อย่างน้อย 3 backup ล่าสุด
