---
description: Submodule-aware git ops — commit, push, branch, merge across main repo + submodules from plan/fix scope
model: claude-sonnet-4-6
---

# bda-git — Submodule-aware git ops

Commit + push ทั้ง submodules + main repo ตาม plan/fix scope หรือ free text

## Trigger

```
/bda-git --plan docs/obsidian-vault/80-ImplementPlan/<slug>.md
/bda-git --fix docs/obsidian-vault/85-FixLog/<slug>.md
/bda-git --message "feat: add search"
/bda-git --branch <name>
/bda-git --status
/bda-git --pull
/bda-git --merge-to default
/bda-git --no-push
```

## Rules

- **ห้ามรันอัตโนมัติ** — รันเฉพาะตอน user เรียก
- ตาม `.bda-spec.yml` `submodules:` list
- Submodule branches ใช้ค่าจาก `.gitmodules` หรือ config
- **Read-only submodules** (เช่น figma) → skip silently
- Main repo commit หลัง submodules push หมด
- Submodule ไม่มี staged → skip silently

## Phase 1 — Parse args

| Flag | Purpose |
|---|---|
| `--plan <path>` | Plan file → scope staged files + auto-generate commit message |
| `--fix <path>` | Fix log → scope + commit prefix `fix:` |
| `--branch <name>` | Switch main + submodules ก่อน commit (ยกเว้น read-only) |
| `--branch default` | Switch กลับ branch ตาม `.gitmodules` |
| `--create-branch` | สร้าง branch ใหม่ถ้าไม่มี |
| `--message "<msg>"` | Explicit message |
| `--no-push` | Commit only |
| `--switch-only` | แค่ switch ไม่ commit |
| `--status` | แสดง branch + dirty state ของแต่ละ repo |
| `--pull` | Fetch + ff pull ก่อน stage |
| `--rebase` | Pull --rebase |
| `--bump patch\|minor\|major` | bump version + append `[vX.Y.Z]` |
| `--no-bump` | ข้าม bump |
| `--merge-to <branch>` | หลัง push → merge เข้า branch |
| `--merge-to default` | merge เข้า tracked branch ของแต่ละ repo |
| `--no-ff` | force `--no-ff` merge commit |
| `--delete-source` | หลัง merge สำเร็จ → delete source branch local + remote |

Precedence ของ message: `--message` > free text > auto-from-plan/fix > prompt user

## Phase 2 — Status / Switch-only modes

ถ้า `--status` หรือ `--switch-only`: ทำเฉพาะ branch ops ไม่ stage/commit/push

```bash
# Status example
for repo in . $(jq -r '.submodules[].path' .bda-spec.yml 2>/dev/null); do
  echo "=== $repo ==="
  git -C "$repo" branch --show-current
  git -C "$repo" status --short
done
```

## Phase 3 — Pull / Sync (ถ้า `--pull` หรือ `--update-submodules`)

```bash
git fetch --all
git pull --ff-only        # หรือ --rebase ถ้า --rebase
# submodules
for sub in $(jq -r '.submodules[].path' .bda-spec.yml); do
  git -C "$sub" pull --ff-only
done
```

Abort ถ้า non-ff โดยไม่ใช่ --rebase

## Phase 4 — Scope staged files (ถ้า --plan / --fix)

อ่าน plan/fix file → list `Affected Files` → stage เฉพาะที่อยู่ใน list

```bash
files=$(grep -oP '`[^`]+`' "$plan" | head -50 | tr -d '`')
for f in $files; do git add "$f"; done
```

ถ้า file ไม่อยู่ใน plan → ไม่ stage; แจ้ง user ว่า file ใดถูก skip

## Phase 5 — Generate commit message

ลำดับ precedence:
1. `--message`
2. Free text จาก `$ARGUMENTS`
3. Auto จาก plan/fix:
   - Plan: `feat(<area>): <plan title>` หรือ `feat: <title>`
   - Fix: `fix(<area>): <fix title>`
4. Prompt user

Append `[vX.Y.Z]` ถ้า `--bump`

## Phase 6 — Commit + push per submodule

```bash
for sub in $(jq -r '.submodules[].path' .bda-spec.yml); do
  test "$(jq -r ".submodules[] | select(.path==\"$sub\") | .read_only" .bda-spec.yml)" = "true" && continue
  
  cd "$sub"
  staged=$(git diff --cached --name-only)
  test -z "$staged" && { cd -; continue; }
  
  git commit -m "$msg"
  test "$no_push" = "1" || git push origin "$current_branch"
  cd -
done
```

## Phase 7 — Main repo commit

หลัง submodules push:
1. Stage submodule pointer updates ถ้ามี
2. Stage main repo files ตาม scope
3. Commit + push (เว้นแต่ `--no-push`)

## Phase 8 — Merge-to (optional)

ถ้า `--merge-to <branch>`:
- per repo: checkout target → merge --no-ff source → push
- ถ้า `--delete-source`: delete source local + remote

## Phase 9 — Report

แสดง:
```
git-sync summary
================
api    [develop]    1 commit pushed   ✅
web    [develop]    2 commits pushed  ✅
app    [master]     0 commits         skip (no changes)
main   [main]       1 commit pushed   ✅
figma  [read-only]  skipped
```

## Phase 10 — Log checkin

```markdown
- HH:MM — [type/git] /bda-git --plan <slug> — committed: api(1), web(2), main(1)
```

## Output (5 หัวข้อบังคับ)

1. **BDA Standard files used** — `standards/STANDARD.md`, `standards/policies/source-of-truth.md`
2. **Pipeline trace** — Understand (Phase 2 status) → Plan (Phase 4 scope) → Execute (Phase 6/7) → Verify (Phase 9 summary) → Handoff (checkin log)
3. **Commands run** — ทุก git command + exit codes
4. **Verification / Evidence** — commit hashes, push results, branches per repo
5. **Limitations / Risks / Next steps** — files ที่ skip, conflicts ที่ต้อง resolve

## ห้าม

- ห้าม `git push --force` โดยไม่ explicit user confirm
- ห้าม commit ก่อนรัน /bda-secure
- ห้าม delete branch โดยไม่ verify ว่า merged
- ห้าม commit ที่ figma (หรือ read-only) submodule
- ห้าม `git reset --hard` โดยไม่ confirm
