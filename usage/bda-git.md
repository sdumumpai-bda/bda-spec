# /bda-git

> **Submodule-aware git ops** — commit/push/branch/merge ทั้ง main repo + submodules ตาม plan/fix scope

[← กลับ usage/README](./README.md) · [Full spec: `commands/bda-git.md`](../commands/bda-git.md)

## เมื่อไหร่ใช้

- Commit + push หลัง `/bda-implement` (plan-scoped — auto-stage จาก plan file)
- Commit fix (prefix `fix:` อัตโนมัติ จาก fix-log)
- Switch branch ทั้ง main + submodules พร้อมกัน
- Merge feature branch → default ของแต่ละ repo

## Quick start

```
/bda-git --plan docs/80-ImplementPlan/2026-05-21-add-search.md
```

ตัวอย่าง output:
```
git-sync summary
================
api    [develop]    1 commit pushed   ✅
web    [develop]    2 commits pushed  ✅
app    [master]     0 commits         skip (no changes)
main   [main]       1 commit pushed   ✅
figma  [read-only]  skipped
```

## รูปแบบเต็ม

```
/bda-git --plan <path>             # auto-stage + auto-message จาก plan
/bda-git --fix <path>              # commit prefix `fix:`
/bda-git --message "<msg>"         # explicit message
/bda-git --branch <name>           # switch branch + submodules
/bda-git --branch default          # switch กลับ tracked branch
/bda-git --create-branch           # สร้าง branch ใหม่ถ้าไม่มี
/bda-git --no-push                 # commit only
/bda-git --switch-only             # switch ไม่ commit
/bda-git --status                  # แสดง branch + dirty state
/bda-git --pull                    # fetch + ff pull
/bda-git --rebase                  # pull --rebase
/bda-git --bump patch|minor|major  # bump version + append [vX.Y.Z]
/bda-git --merge-to default        # merge เข้า tracked branch
/bda-git --no-ff                   # force --no-ff merge commit
/bda-git --delete-source           # หลัง merge → delete source local + remote
```

| Flag group | Default | ใช้สำหรับ |
|---|---|---|
| `--plan` / `--fix` | n/a | scope จาก plan/fix + auto message |
| `--branch <name>` | current | switch all repos to branch |
| `--merge-to <br>` | n/a | merge หลัง push |
| `--no-push` | off | commit only (review ก่อน push) |
| `--bump` | off | bump version + append tag in message |

## ขั้นตอนภายใน (Phase summary)

1. **Phase 1** — Parse args (message precedence: `--message` > free text > auto > prompt)
2. **Phase 2** — Status / Switch-only modes (ไม่ commit)
3. **Phase 3** — Pull / Sync (fetch + ff หรือ rebase)
4. **Phase 4** — Scope staged files (จาก plan `Affected Files` — file นอก list ไม่ stage + แจ้ง)
5. **Phase 5** — Generate commit message (plan → `feat(<area>): <title>`, fix → `fix(<area>): <title>`)
6. **Phase 6** — Commit + push per submodule (skip read-only + no-stage)
7. **Phase 7** — Main repo commit (stage submodule pointer updates + main files)
8. **Phase 8** — Merge-to (optional)
9. **Phase 9** — Report summary table
10. **Phase 10** — Log checkin

## Rules ที่บังคับ

- **ห้ามรันอัตโนมัติ** — รันเฉพาะ user เรียก
- ใช้ submodules list จาก `.bda-spec.yml`
- **Read-only submodules** (เช่น `figma`) → skip silently
- Main repo commit **หลัง** submodules push หมด
- Submodule ไม่มี staged → skip silently

## Output ที่ได้

- Git history (commits + tags ถ้า `--bump`)
- Push to remote (เว้นแต่ `--no-push`)
- Console: summary table (branch × commits × status per repo)
- Checkin log: `HH:MM — [type/git] /bda-git --plan <slug> — committed: api(1), web(2), main(1)`

## Workflow ที่นิยม

ตัวอย่าง 1: feature commit
```
1. /bda-implement <plan>
2. /bda-secure
3. /bda-verify <plan>
4. /bda-git --plan <plan>
   → stage เฉพาะไฟล์ใน Affected Files
   → message: feat(web): add search feature
   → push api/, web/, main/
```

ตัวอย่าง 2: bug fix
```
1. /bda-fix → /bda-plan fix:<slug> → /bda-implement
2. /bda-git --fix docs/85-FixLog/<slug>.md
   → message: fix(web): search returns empty
```

ตัวอย่าง 3: switch branch
```
/bda-git --switch-only --branch feature/checkout
  → main + submodules ทั้งหมด switch ไป feature/checkout
  → ไม่ commit
```

ตัวอย่าง 4: bump version + merge
```
/bda-git --plan <plan> --bump minor --merge-to default
  → commit message: feat: ... [v1.3.0]
  → push → merge เข้า main/develop ของแต่ละ repo
```

## Gotchas / ข้อควรระวัง

- 🚫 **ห้าม `git push --force` โดยไม่ explicit user confirm**
- 🚫 **ห้าม commit ก่อนรัน `/bda-secure`** — workflow บังคับ pre-flight
- 🚫 ห้าม delete branch โดยไม่ verify ว่า merged
- 🚫 **ห้าม commit ที่ figma (หรือ read-only) submodule** — skip silently
- 🚫 ห้าม `git reset --hard` โดยไม่ confirm
- ⚠️ File ที่ไม่อยู่ใน plan `Affected Files` → ไม่ถูก stage + แจ้ง user
- ⚠️ Non-ff push abort เว้นแต่ `--rebase` หรือ explicit pull ก่อน
- 💡 Commit message precedence: `--message` > free text > plan auto > prompt user

## Related

- ก่อน `/bda-git`: [/bda-secure](./bda-secure.md) (บังคับ), [/bda-verify](./bda-verify.md) (recommended)
- หลัง `/bda-git`: [/bda-checkin](./bda-checkin.md) (log activity), reviewer review
- Config: `.bda-spec.yml` `submodules:` (path + branch + read_only)
- Standard: `standards/policies/source-of-truth.md`

## FAQ

**Q: ผมมี submodule แต่ `.bda-spec.yml` ไม่มี — `/bda-git` จะรู้ไหม?**
A: ใช้ `.gitmodules` fallback แต่แนะนำ list ใน `.bda-spec.yml` เพื่อ explicit branch + read_only flag

**Q: ถ้า submodule บางตัวมี conflict?**
A: `/bda-git` abort + แจ้ง — user ต้อง resolve manually ใน submodule ก่อนรันใหม่

**Q: ใช้ `/bda-git` กับ monorepo (ไม่มี submodule) ได้ไหม?**
A: ได้ — `.bda-spec.yml` `submodules: []` ว่าง → ทำงาน main repo อย่างเดียว

**Q: ทำไม `--plan` auto-message — ผมเปลี่ยน message ได้ไหม?**
A: ได้ — ใช้ `--message "<msg>"` (precedence สูงสุด) หรือ ตอบ prompt ตอน commit
