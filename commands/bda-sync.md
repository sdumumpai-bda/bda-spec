---
description: Sync curated BDA AI Dev Standard snapshot from bda-spec repo into .bda-spec/ and bump pinned version
model: claude-sonnet-4-6
---

# bda-sync — Sync BDA AI Dev Standard snapshot (via bda-spec curated layer)

Pull latest **curated** standard snapshot จาก **bda-spec repo** (`sdumumpai-bda/bda-spec`) → update `.bda-spec/` snapshot + bump version

## ทำไม sync ผ่าน bda-spec ไม่ใช่จาก BDA standard ตรงๆ?

bda-spec เป็น **curated middle layer** ระหว่าง upstream BDA standard กับ user project:

```
upstream BDA standard (BigDataAgency/bda-ai-dev-standard)
        ↓ (bda-spec dev curates: review, test against commands, snapshot)
bda-spec repo (sdumumpai-bda/bda-spec) ─── .bda-spec/ (pinned)
        ↓ (/bda-sync pulls from here)
user project ─── .bda-spec/ (snapshot copy)
```

เหตุผล:
- **Compatibility guarantee** — bda-spec dev test ทุก standard version กับ commands ของ bda-spec ก่อน release. User project จึงไม่เจอ situation ที่ standard ใหม่กว่า commands รองรับ
- **Curated content** — bda-spec อาจมี notes/adaptations ที่ไม่อยู่ใน upstream
- **Single source of truth** — version ของ bda-spec ↔ version ของ standard snapshot ที่ bundle มา = compatible เสมอ

## Trigger

```
/bda-sync                       # interactive — show diff + ask confirm
/bda-sync --check               # check version difference, ไม่ดาวน์โหลด
/bda-sync --to <version>        # pin ไป bda-spec version เฉพาะ (เช่น v0.4.0)
/bda-sync --dry-run             # show changes แต่ไม่จริง
/bda-sync --force               # skip confirmation
```

## Phase 1 — Read current pinned

```bash
current_std=$(cat .bda-spec/VERSION 2>/dev/null || echo "0.0.0")
current_bda_spec=$(cat .bda-spec/VERSION 2>/dev/null || echo "0.0.0")
echo "Currently pinned:"
echo "  bda-spec:     $current_bda_spec"
echo "  BDA standard: $current_std"
```

## Phase 2 — Fetch latest from bda-spec repo

```bash
# bda-spec repo is the source — NOT upstream BDA standard repo
source_url=$(yq '.standard.source' .bda-spec.yml)
# Default (v0.4+): https://github.com/sdumumpai-bda/bda-spec

# Public repo — use raw VERSION
latest_bda_spec=$(curl -fsSL "https://raw.githubusercontent.com/sdumumpai-bda/bda-spec/main/.bda-spec/VERSION" | tr -d '[:space:]')
latest_std=$(curl -fsSL "https://raw.githubusercontent.com/sdumumpai-bda/bda-spec/main/.bda-spec/VERSION" | tr -d '[:space:]')

echo "Latest available (from bda-spec main):"
echo "  bda-spec:     $latest_bda_spec"
echo "  BDA standard: $latest_std"
```

ถ้า private repo → ต้อง `GITHUB_TOKEN` env var

## Phase 3 — Diff

```bash
# Fetch tree of .bda-spec/ from bda-spec repo
tree=$(curl -fsSL "https://api.github.com/repos/sdumumpai-bda/bda-spec/git/trees/main?recursive=1" \
  | jq '[.tree[] | select(.path | startswith(".bda-spec/"))]')

# Compare แต่ละ blob hash กับ local snapshot
# (implementation: ทำ sha1 ของ local file vs blob.sha)
```

แสดง diff:
```
Files to add:    3
Files to update: 5
Files to remove: 0

Detail:
+ .bda-spec/policies/new-policy.md
~ .bda-spec/STANDARD.md (changed: lines 12-15)
~ .bda-spec/templates/handoff.md (template format updated)
- (none)
```

## Phase 4 — Confirm

ถ้าไม่ `--force` หรือ `--dry-run` → ถาม user confirm

```
Update standards snapshot from bda-spec 0.4.0 → 0.4.3?
  BDA standard:  0.8.0 → 0.8.1
  Files to update: 5
  Files to add: 3
  Breaking changes? See CHANGELOG.

[y/N]:
```

## Phase 5 — Download + replace (SCOPE: .bda-spec/ only)

> ⚠️ **Scope guard** — `/bda-sync` แตะเฉพาะ `.bda-spec/` เท่านั้น
> ห้ามทับ `templates/`, `commands/`, `.claude/`, `docs/`, `.bda-spec.yml`,
> `.bda-spec.local.yml`, `.bda-spec/local/`, `.bda-spec/VERSION` ไม่ว่ากรณีใดๆ
> ถ้า template structure ของ standard เปลี่ยน → แค่ flag ให้ user review ใน Phase 7

```bash
# Pre-flight: verify ห้ามแตะของ project
PROTECTED=(
  templates                       # project-level template overrides
  commands
  .claude
  docs
  codex
  gemini
  prompts
  bin
  scripts                         # bda-paths.sh + upgrade.sh + upload-evidence.sh
  .bda-spec.yml
  .bda-spec.local.yml
  .bda-spec/local
  .bda-spec/VERSION               # bda-spec version (separate from standard.version)
  CLAUDE.md
  AI-README.md
  README.md
)
echo "Protected paths (จะไม่ถูกแตะ): ${PROTECTED[*]}"

# Stage download from bda-spec repo
STAGE=$(mktemp -d -t bda-sync-XXXXXX)
trap "rm -rf $STAGE" EXIT

# Option A (preferred): shallow clone + extract .bda-spec/
git clone --depth 1 --branch "${TARGET_VER:-main}" \
  "https://github.com/sdumumpai-bda/bda-spec.git" "$STAGE/repo" >/dev/null 2>&1

# Verify source has expected structure
test -d "$STAGE/repo/.bda-spec/standards" || { echo "ERROR: bda-spec repo missing .bda-spec/"; exit 1; }

# Atomic swap — backup ของเดิม
backup_ts=$(date +%Y%m%d-%H%M%S)
cp -R .bda-spec/standards ".bda-spec/standards.backup-$backup_ts"
rm -rf .bda-spec/standards
cp -R "$STAGE/repo/.bda-spec/standards" .bda-spec/standards

# Verify
test -f .bda-spec/STANDARD.md && test -f .bda-spec/VERSION && echo OK

# Verify: ห้ามมีไฟล์โผล่ใน folder อื่น (compare file counts pre/post)
for p in "${PROTECTED[@]}"; do
  [ -e "$p" ] || continue
  before=$(find ".bda-spec/standards.backup-$backup_ts/../../$p" -type f 2>/dev/null | wc -l)
  after=$(find "$p" -type f 2>/dev/null | wc -l)
  if [ "$before" -ne "$after" ]; then
    echo "⚠️ PROTECTED PATH MODIFIED: $p ($before → $after files)"
    echo "ABORTED — restoring backup"
    rm -rf .bda-spec/standards && mv ".bda-spec/standards.backup-$backup_ts" .bda-spec/standards
    exit 2
  fi
done
```

## Phase 6 — Update .bda-spec.yml

```yaml
standard:
  source: "https://github.com/sdumumpai-bda/bda-spec"   # NOT upstream BDA standard — curated layer
  version: "0.8.1"                                       # BDA standard version (from snapshot)
  snapshot_path: .bda-spec/standards
  last_synced: "2026-05-25"
  bda_spec_version: "0.4.3"                              # which bda-spec release this snapshot came from
```

## Phase 7 — Run impact check

หลัง update:
- ตรวจว่า command/template paths ที่ user override ใน `templates/` ยังตรงกับ schema ใหม่ของ standard
- ถ้า template structure เปลี่ยน → flag user ให้ review project-level overrides
- ถ้า policy ใหม่ → แสดง summary ของ policy ใหม่
- ถ้า bda-spec version ใหม่กว่า commands ของ user → แนะนำให้รัน `bash scripts/upgrade.sh` ด้วย

## Phase 8 — Log checkin + changelog

```markdown
- HH:MM — [type/sync] /bda-sync 0.4.1 → 0.4.3 (via bda-spec) — files: ~5, +3, -0
```

สร้าง `.bda-spec/SYNC-HISTORY.md` (append-only):
```markdown
## 2026-05-25 — 0.8.0 → 0.8.1 (via bda-spec 0.4.0 → 0.4.3)
- Updated by: <user>
- Source: sdumumpai-bda/bda-spec (curated)
- Reason: routine sync / fixing X
- Changes: ~5 files, +3 files
- Breaking: none / list
- Reviewed by: <reviewer>
```

## Output (5 หัวข้อบังคับ)

1. **BDA Standard files used** — `.bda-spec.yml`, `.bda-spec/VERSION`, `.bda-spec/VERSION`
2. **Pipeline trace** — Understand (Phase 1-3) → Plan (Phase 4 confirm) → Execute (Phase 5-6) → Verify (test -f + protected-path comparison)
3. **Commands run** — git clone bda-spec, file moves, find counts
4. **Verification / Evidence** — new VERSION content, diff summary, protected-paths unchanged
5. **Limitations / Risks / Next steps** — template overrides ใน `templates/` ที่อาจ outdated, breaking changes ที่ต้อง update commands, suggestion ให้รัน `scripts/upgrade.sh` ถ้า bda-spec version ก็เปลี่ยนด้วย

## ห้าม

- ห้าม sync โดยไม่ backup `.bda-spec/`
- **ห้ามดึงจาก upstream BDA standard (BigDataAgency/bda-ai-dev-standard) ตรงๆ** — ต้องผ่าน bda-spec ที่ curated แล้วเสมอ
- ห้ามแก้ `.bda-spec/` ด้วยมือ — แก้ผ่าน feedback loop ที่ bda-spec repo (ซึ่งจะ propagate ขึ้น upstream BDA standard ผ่าน UPDATE-POLICY)
- ห้ามใส่ template ของ project เข้า `.bda-spec/templates/` — ใส่ `templates/` แทน
- **ห้ามแตะ folder อื่นโดยเด็ดขาด** — ถ้า sync ทับ `templates/`, `commands/`, `.claude/`, `docs/`, `scripts/`, หรือ config ของ user → abort + restore backup ทันที
- ห้ามแตะ `.bda-spec/VERSION` (bda-spec version) — sync เฉพาะ `.bda-spec/VERSION` (BDA standard version)
- ห้ามแก้ `.bda-spec.yml` หรือ `.bda-spec.local.yml` (เปลี่ยนแค่ `standard.version` + `standard.last_synced` + `standard.bda_spec_version` ได้ผ่าน Phase 6)
- ห้ามลบ `.bda-spec/standards.backup-*` โดยไม่บอก user — เก็บไว้อย่างน้อย 3 backup ล่าสุด
