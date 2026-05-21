#!/usr/bin/env bash
# bda-spec upgrade — bump bda-spec itself (commands/scripts/standards skeleton)
#                    keeps templates/, docs/, .bda-spec.yml safe
#
# Usage:
#   bash scripts/upgrade.sh                  # pull latest from configured source
#   bash scripts/upgrade.sh --source <path>  # use local checkout
#   bash scripts/upgrade.sh --version <tag>  # pin to specific version
#   bash scripts/upgrade.sh --dry-run        # show diff, don't apply
#   bash scripts/upgrade.sh --rollback       # restore from last backup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

# Load config
eval "$(bash "$SCRIPT_DIR/bda-paths.sh" --shell)" 2>/dev/null || true

SOURCE="${BDA_SPEC_SOURCE:-https://github.com/BigDataAgency/bda-spec.git}"
VERSION="main"
DRY_RUN=0
ROLLBACK=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --source) SOURCE="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --rollback) ROLLBACK=1; shift ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

# ── colors ──
c_bold='\033[1m'; c_reset='\033[0m'
c_blue='\033[34m'; c_green='\033[32m'; c_yellow='\033[33m'; c_red='\033[31m'
log()  { printf "${c_blue}[upgrade]${c_reset} %s\n" "$*"; }
ok()   { printf "${c_green}  ✓${c_reset} %s\n" "$*"; }
warn() { printf "${c_yellow}  ⚠${c_reset} %s\n" "$*" >&2; }
err()  { printf "${c_red}  ✗${c_reset} %s\n" "$*" >&2; }

# ── rollback ──
if [ "$ROLLBACK" -eq 1 ]; then
  latest_backup=$(ls -td .bda-spec.backup-* 2>/dev/null | head -1 || true)
  [ -z "$latest_backup" ] && { err "No backup found"; exit 1; }
  log "Rolling back from: $latest_backup"
  for item in commands .claude/commands .claude/agents standards scripts bin codex gemini prompts; do
    if [ -d "$latest_backup/$item" ]; then
      rm -rf "./$item"
      cp -R "$latest_backup/$item" "./$item"
      ok "Restored: $item"
    fi
  done
  ok "Rollback complete from $latest_backup"
  exit 0
fi

# ── pre-flight ──
current_version=$(cat VERSION 2>/dev/null || echo "0.0.0")
log "Current bda-spec version: $current_version"
log "Source:  $SOURCE"
log "Target:  $VERSION"

# ── stage ──
STAGE=$(mktemp -d -t bda-spec-upgrade-XXXXXX)
trap "rm -rf $STAGE" EXIT

if [ -d "$SOURCE" ]; then
  log "Using local source"
  cp -R "$SOURCE/." "$STAGE/"
elif [[ "$SOURCE" =~ ^https?:// ]]; then
  log "Cloning $SOURCE @ $VERSION"
  command -v git >/dev/null || { err "git not found"; exit 1; }
  git clone --depth 1 --branch "$VERSION" "$SOURCE" "$STAGE" >/dev/null 2>&1
else
  err "Invalid source: $SOURCE"; exit 1
fi

new_version=$(cat "$STAGE/VERSION" 2>/dev/null || echo "0.0.0")
log "New version: $new_version"

# ── diff ──
log "Computing diff..."
DIFF_REPORT=$(mktemp)
{
  for item in commands .claude/commands .claude/agents standards scripts bin codex gemini prompts; do
    if [ -d "$STAGE/$item" ]; then
      if [ -d "./$item" ]; then
        diff -rq "./$item" "$STAGE/$item" 2>/dev/null || true
      else
        echo "Only in $STAGE/$item: (new directory)"
      fi
    fi
  done
} > "$DIFF_REPORT"

diff_lines=$(wc -l < "$DIFF_REPORT")
log "Diff: $diff_lines changes"
head -20 "$DIFF_REPORT" | sed 's/^/  /'

# ── safe paths ──
# These NEVER touched:
SAFE_PATHS=(
  templates                       # project overrides
  docs                            # Obsidian vault (user content)
  .bda-spec.yml                   # shared config
  .bda-spec.local.yml             # personal config
  .bda-spec/local                 # personal commands/templates
  CLAUDE.md                       # may be customized
  AI-README.md                    # may be customized
  README.md                       # may be customized
)
log "Safe paths (never touched): ${SAFE_PATHS[*]}"

# Paths that GET replaced wholesale:
REPLACE_PATHS=(
  commands
  .claude/commands
  .claude/agents
  standards
  scripts
  bin
  codex
  gemini
  prompts
  VERSION
)

# ── dry-run ──
if [ "$DRY_RUN" -eq 1 ]; then
  log "Dry-run — no changes will be applied"
  for p in "${REPLACE_PATHS[@]}"; do
    if [ -e "$STAGE/$p" ]; then
      printf "  would replace: %s\n" "$p"
    fi
  done
  exit 0
fi

# ── backup ──
BACKUP_DIR=".bda-spec.backup-$(date +%Y%m%d-%H%M%S)"
log "Creating backup: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
for p in "${REPLACE_PATHS[@]}"; do
  [ -e "$p" ] && cp -R "$p" "$BACKUP_DIR/$(dirname "$p" | sed 's|^\./||')/$(basename "$p")" 2>/dev/null || true
done
ok "Backup: $BACKUP_DIR"

# ── apply ──
log "Applying upgrade..."
for p in "${REPLACE_PATHS[@]}"; do
  if [ -e "$STAGE/$p" ]; then
    if [ -d "$STAGE/$p" ]; then
      rm -rf "./$p"
      cp -R "$STAGE/$p" "./$p"
    else
      cp "$STAGE/$p" "./$p"
    fi
    ok "Updated: $p"
  fi
done

# Update standard.last_synced ใน .bda-spec.yml ถ้ามี
if command -v yq >/dev/null 2>&1 && [ -f .bda-spec.yml ]; then
  yq -i ".standard.last_synced = \"$(date +%Y-%m-%d)\"" .bda-spec.yml
  ok "Updated .bda-spec.yml standard.last_synced"
fi

# Refresh marked sections (CLAUDE.md START/END markers)
if grep -q '<!-- BDA-SPEC START -->' CLAUDE.md 2>/dev/null && [ -f "$STAGE/CLAUDE.md" ]; then
  marker_start='<!-- BDA-SPEC START -->'
  marker_end='<!-- BDA-SPEC END -->'
  new_block=$(awk "/$marker_start/,/$marker_end/" "$STAGE/CLAUDE.md")
  if [ -n "$new_block" ]; then
    awk -v start="$marker_start" -v end="$marker_end" -v new="$new_block" '
      $0 ~ start { print new; in_block=1; next }
      $0 ~ end   { in_block=0; next }
      !in_block   { print }
    ' CLAUDE.md > CLAUDE.md.new && mv CLAUDE.md.new CLAUDE.md 2>/dev/null || true
    ok "Refreshed CLAUDE.md marked section"
  fi
fi

# ── verify ──
log "Running doctor..."
if [ -f bin/bda-spec ]; then
  bash bin/bda-spec doctor || warn "Doctor reported issues — review above"
fi

# ── summary ──
echo ""
printf "${c_green}${c_bold}✓ Upgrade complete${c_reset}\n"
log "$current_version → $new_version"
log "Backup at: $BACKUP_DIR (delete after verifying everything works)"
log "Rollback: bash scripts/upgrade.sh --rollback"
log ""
log "Next:"
log "  • Run tests: bash scripts/test.sh"
log "  • Check breaking changes ใน CHANGELOG.md"
log "  • รัน /bda-agent audit เพื่อตรวจ agent files"
