#!/usr/bin/env bash
# bda-spec — First release script (v0.1.0)
#
# ต้องรันจาก Terminal ของคุณ (Mac/Linux) — workspace VM ไม่มี permission
# Usage:
#   cd /Volumes/testspace/AI-workflow/bda-spec
#   bash scripts/release-v0.1.0.sh
#
# Script นี้จะ:
#   1. Clean lock file (ถ้ามี)
#   2. Verify tests pass
#   3. Set git user (ถ้ายัง)
#   4. git add -A
#   5. git commit (พร้อม commit message ที่เตรียมไว้)
#   6. git push -u origin main
#   7. git tag v0.1.0
#   8. git push origin v0.1.0

set -uo pipefail

c_bold='\033[1m'; c_reset='\033[0m'
c_green='\033[32m'; c_red='\033[31m'; c_yellow='\033[33m'; c_blue='\033[34m'
log()  { printf "${c_blue}[release]${c_reset} %s\n" "$*"; }
ok()   { printf "${c_green}  ✓${c_reset} %s\n" "$*"; }
warn() { printf "${c_yellow}  ⚠${c_reset} %s\n" "$*" >&2; }
err()  { printf "${c_red}  ✗${c_reset} %s\n" "$*" >&2; exit 1; }

# ── Pre-flight ──
[[ -d .git ]] || err "ไม่ใช่ git repo — รันใน bda-spec root"
[[ -f VERSION ]] || err "ไม่พบ VERSION file"
VERSION=$(cat VERSION | tr -d '[:space:]')
[[ "$VERSION" == "0.1.0" ]] || err "VERSION ไม่ใช่ 0.1.0 (current: $VERSION) — อัพเดทก่อน"

log "Releasing bda-spec v$VERSION"

# ── Step 1: Clean lock ──
if [[ -f .git/index.lock ]]; then
  log "Removing stale .git/index.lock"
  rm -f .git/index.lock || err "ลบ lock ไม่ได้ — ปิด git GUI/editor ทั้งหมดแล้วลองใหม่"
fi

# ── Step 2: Tests ──
log "Running smoke tests"
if bash scripts/test.sh > /tmp/bda-test-output.log 2>&1; then
  ok "All tests passed"
else
  warn "Tests failed — ดู /tmp/bda-test-output.log"
  read -r -p "Continue anyway? (y/N) " ans
  [[ "$ans" =~ ^[Yy] ]] || exit 1
fi

# ── Step 3: Git config ──
if ! git config user.name >/dev/null 2>&1; then
  default_name="${USER:-bda-developer}"
  read -r -p "Git user.name [$default_name]: " gname
  git config user.name "${gname:-$default_name}"
  ok "set user.name = $(git config user.name)"
fi
if ! git config user.email >/dev/null 2>&1; then
  default_email="${USER:-noreply}@bda.co.th"
  read -r -p "Git user.email [$default_email]: " gemail
  git config user.email "${gemail:-$default_email}"
  ok "set user.email = $(git config user.email)"
fi

# ── Step 4: Stage ──
log "Staging changes"
git add -A
staged=$(git diff --cached --name-only | wc -l | tr -d ' ')
ok "Staged $staged files"

# Quick sanity check — ห้าม commit personal config
if git diff --cached --name-only | grep -E "^\.bda-spec\.local\.yml$"; then
  err "พบ .bda-spec.local.yml ใน staged — ห้าม commit (gitignored)"
fi

# ── Step 5: Commit ──
log "Creating commit"

COMMIT_MSG="feat: initial bda-spec release v0.1.0

bda-spec is an AI + Obsidian docs-driven development workflow
combining spec-kit, BDA AI Dev Standard v0.7.0, and thai-cleft patterns.

What's in v0.1.0:
- 20 slash commands (spec-driven cycle + daily ops + delivery)
- 9 specialized AI subagents (79 refusal gates total)
- 5 AI shims: Claude Code, Codex CLI, Gemini, ChatGPT, Zhipu GLM
- BDA AI Dev Standard v0.7.0 snapshot in standards/ (read-only)
- 16 project-customizable templates with override chain
- 3-tier evidence storage (test-artifacts/ → vault → GDrive)
- 5 helper scripts: install, upgrade, paths, upload-evidence, test
- 233 smoke tests passing
- Sample 'Library Book Tracker' Obsidian vault (47 files)

Install (one-line):
  bash <(curl -fsSL https://raw.githubusercontent.com/sdumumpai-bda/bda-spec/main/scripts/install.sh)

Docs:
- README.md            — quick start + workflows
- usage/               — 20+1 user-facing command docs
- commands/            — Phase-by-Phase source-of-truth
- DISTRIBUTION.md      — release flow
- EVIDENCE-PATHS.md    — 3-tier evidence strategy
- AI-README.md         — multi-AI usage

Inheritance:
- spec-kit (github/spec-kit) — plan-driven philosophy, multi-AI installer
- BDA AI Dev Standard v0.7.0 — 5-step pipeline, mandatory output, no-fake-evidence
- thai-cleft-main — vault patterns, daily-log v5 schema, fix-log split"

if git commit -m "$COMMIT_MSG"; then
  ok "Committed"
else
  err "Commit failed"
fi

# ── Step 6: Push main ──
log "Pushing to origin/main"
current_branch=$(git branch --show-current)
if [[ "$current_branch" != "main" ]]; then
  log "Renaming branch '$current_branch' → main"
  git branch -M main
fi

if git push -u origin main; then
  ok "Pushed to origin/main"
else
  err "Push failed — ตรวจ SSH key + remote access ที่ git@github.com:sdumumpai-bda/bda-spec.git"
fi

# ── Step 7: Tag ──
log "Creating tag v$VERSION"
TAG_MSG="Release v$VERSION — initial public release

ดู CHANGELOG.md สำหรับรายละเอียดเต็ม

Install:
  bash <(curl -fsSL https://raw.githubusercontent.com/sdumumpai-bda/bda-spec/v$VERSION/scripts/install.sh)"

if git tag -a "v$VERSION" -m "$TAG_MSG"; then
  ok "Tag v$VERSION created"
else
  err "Tag creation failed"
fi

# ── Step 8: Push tag ──
log "Pushing tag v$VERSION"
if git push origin "v$VERSION"; then
  ok "Tag pushed"
else
  err "Tag push failed"
fi

# ── Done ──
echo ""
printf "${c_green}${c_bold}✓ Released bda-spec v$VERSION${c_reset}\n\n"

cat <<EOF
Next steps:
  1. ดู release ที่: https://github.com/sdumumpai-bda/bda-spec/releases/tag/v$VERSION
  2. (Optional) สร้าง GitHub Release notes:
       gh release create v$VERSION --title "v$VERSION" --notes-from-tag
     หรือผ่าน web → GitHub → Releases → Draft new release → tag v$VERSION
  3. แชร์ install command กับ team:
       bash <(curl -fsSL https://raw.githubusercontent.com/sdumumpai-bda/bda-spec/v$VERSION/scripts/install.sh)
  4. ถ้า repo เป็น private — user ต้องใช้ token:
       bash <(curl -fsSL -H "Authorization: token \$GITHUB_TOKEN" \\
         https://raw.githubusercontent.com/sdumumpai-bda/bda-spec/v$VERSION/scripts/install.sh)
EOF
