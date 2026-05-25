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

SOURCE="${BDA_SPEC_SOURCE:-https://github.com/sdumumpai-bda/bda-spec.git}"
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
  for item in .bda-spec/commands .claude/commands .claude/agents standards scripts bin codex gemini prompts; do
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
# bda-spec own version lives in .bda-spec.yml (v0.4+); fallback chain for legacy installs
get_bda_spec_ver() {
  local f="$1"
  if [ -f "$f/.bda-spec.yml" ]; then
    # Simple grep: bda_spec.version key (v0.4+)
    local v
    v=$(awk '/^bda_spec:/{in_b=1;next} /^[a-zA-Z_]/{in_b=0} in_b && /^  version:/{gsub(/^[^"]*"|"[^"]*$/,""); print; exit}' "$f/.bda-spec.yml" 2>/dev/null)
    [ -n "$v" ] && echo "$v" && return
  fi
  # Legacy fallbacks
  [ -f "$f/.bda-spec/VERSION" ] && cat "$f/.bda-spec/VERSION" 2>/dev/null && return  # v0.4-intermediate
  [ -f "$f/VERSION" ] && cat "$f/VERSION" 2>/dev/null && return                       # pre-v0.4
  echo "0.0.0"
}
current_version=$(get_bda_spec_ver ".")
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

new_version=$(get_bda_spec_ver "$STAGE")
log "New version: $new_version"

# ── diff ──
log "Computing diff..."
DIFF_REPORT=$(mktemp)
{
  for item in .bda-spec/commands .claude/commands .claude/agents .bda-spec/STANDARD.md .bda-spec/UPDATE-POLICY.md .bda-spec/VERSION .bda-spec/policies .bda-spec/checklists .bda-spec/templates .bda-spec/workflows scripts bin codex gemini prompts; do
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
  templates                       # project overrides (templates)
  commands                        # project overrides (commands) — optional, layered over .bda-spec/commands/
  docs                            # Obsidian vault (user content)
  .bda-spec.yml                   # shared config
  .bda-spec.local.yml             # personal config
  .bda-spec/local                 # personal commands/templates
  CLAUDE.md                       # may be customized
  AI-README.md                    # may be customized
  README.md                       # may be customized
)
log "Safe paths (never touched): ${SAFE_PATHS[*]}"

# Paths that GET replaced wholesale (v0.4.1 layout — all bda-spec machinery under .bda-spec/):
REPLACE_PATHS=(
  .bda-spec/commands            # was: root commands/ (pre-v0.4.1)
  .claude/commands              # shims (5-line each, @.bda-spec/commands/<verb>.md)
  .claude/agents
  .bda-spec/STANDARD.md         # was: standards/STANDARD.md (pre-v0.4) → .bda-spec/standards/STANDARD.md (v0.4-intermediate)
  .bda-spec/UPDATE-POLICY.md
  .bda-spec/VERSION             # BDA standard version (was: standards/VERSION pre-v0.4)
  .bda-spec/policies
  .bda-spec/checklists
  .bda-spec/templates
  .bda-spec/workflows
  scripts
  bin
  codex
  gemini
  prompts
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
    # Ensure parent dir exists (needed for nested paths like .bda-spec/standards)
    parent="$(dirname "./$p")"
    [ -d "$parent" ] || mkdir -p "$parent"
    if [ -d "$STAGE/$p" ]; then
      rm -rf "./$p"
      cp -R "$STAGE/$p" "./$p"
    else
      cp "$STAGE/$p" "./$p"
    fi
    ok "Updated: $p"
  fi
done

# ── v0.4 / v0.4.1 migration cleanup ──
# Layout history:
#   pre-v0.4:           root standards/ + root VERSION + root commands/
#   v0.4-intermediate:  .bda-spec/standards/ + .bda-spec/VERSION (bda-spec own) + root commands/
#   v0.4:               flat .bda-spec/{STANDARD.md,policies,...} + .bda-spec/VERSION (= BDA standard ver) + .bda-spec.yml bda_spec.version (bda-spec own) + root commands/
#   v0.4.1 (current):   commands/ moved into .bda-spec/commands/ — all machinery in one place

# v0.4.1: legacy root commands/ — archive only if it has no customization vs new .bda-spec/commands/
if [ -d "commands" ] && [ -d ".bda-spec/commands" ]; then
  has_custom=0
  while IFS= read -r f; do
    rel="${f#commands/}"
    if [ ! -f ".bda-spec/commands/$rel" ] || ! diff -q "$f" ".bda-spec/commands/$rel" >/dev/null 2>&1; then
      has_custom=1
      break
    fi
  done < <(find commands -type f -name '*.md' 2>/dev/null)
  if [ "$has_custom" -eq 1 ]; then
    warn "Legacy root commands/ has customization — kept as override layer (lookup: root → .bda-spec/commands/)"
  else
    bak="commands.bak-$(date +%Y%m%d-%H%M%S)"
    warn "Legacy root commands/ found (no customization) — moving to $bak (now under .bda-spec/commands/)"
    mv commands "$bak"
  fi
fi

# Move legacy root standards/ aside (template provided fresh in .bda-spec/)
if [ -d "standards" ]; then
  bak="standards.bak-$(date +%Y%m%d-%H%M%S)"
  warn "Legacy root standards/ found — moving to $bak"
  mv standards "$bak"
fi

# Move legacy .bda-spec/standards/ aside (template provided flat in .bda-spec/)
if [ -d ".bda-spec/standards" ]; then
  bak=".bda-spec/standards.bak-$(date +%Y%m%d-%H%M%S)"
  warn "Legacy .bda-spec/standards/ found — moving to $bak (now flat under .bda-spec/)"
  mv .bda-spec/standards "$bak"
fi

# Drop legacy root VERSION (bda-spec own — now in .bda-spec.yml bda_spec.version)
if [ -f "VERSION" ]; then
  legacy_ver=$(cat VERSION 2>/dev/null | tr -d '[:space:]')
  warn "Legacy root VERSION ($legacy_ver) found — removing (bda-spec own version now in .bda-spec.yml)"
  rm -f VERSION
  # Persist into .bda-spec.yml if not already there
  if [ -n "$legacy_ver" ] && [ -f .bda-spec.yml ] && ! grep -q "^bda_spec:" .bda-spec.yml; then
    printf '\nbda_spec:\n  version: "%s"\n' "$legacy_ver" >> .bda-spec.yml
  fi
fi

# Update bda_spec.last_synced ใน .bda-spec.yml ถ้ามี (v0.4.1+ schema)
# Legacy installs ใช้ standard.* — migrate ตรงนี้ด้วย Python (works without yq)
if [ -f .bda-spec.yml ] && command -v python3 >/dev/null 2>&1; then
  TODAY="$(date +%Y-%m-%d)" python3 - <<'PYEOF'
import os, re
p = '.bda-spec.yml'
today = os.environ.get('TODAY', '')
with open(p) as f: txt = f.read()

# 1) Extract source + last_synced from legacy standard: block (if exists)
m = re.search(r'(?ms)^standard:\s*\n((?:[ \t]+.+\n?)+)', txt)
src = sync = ''
if m:
    block = m.group(1)
    sm = re.search(r'^\s+source:\s*"?([^"\n]+)"?', block, re.M)
    if sm: src = sm.group(1).strip()
    sm = re.search(r'^\s+last_synced:\s*"?([^"\n]+)"?', block, re.M)
    if sm: sync = sm.group(1).strip()
    # Drop the standard: block entirely
    txt = re.sub(r'(?ms)^standard:\s*\n(?:[ \t]+.+\n?)+', '', txt)

# 2) Ensure bda_spec: block exists + has required fields + bump last_synced
bs_m = re.search(r'(?ms)^bda_spec:\s*\n((?:[ \t]+.+\n?)+)', txt)
if bs_m:
    bs_block = bs_m.group(1)
    additions = ''
    if src and 'source:' not in bs_block:
        additions += f'  source: "{src}"\n'
    # Always (re)write last_synced to today
    if 'last_synced:' in bs_block:
        bs_block = re.sub(r'^(\s+last_synced:)\s*"?[^"\n]*"?', rf'\1 "{today}"', bs_block, count=1, flags=re.M)
        txt = txt[:bs_m.start(1)] + bs_block + txt[bs_m.end(1):]
    else:
        additions += f'  last_synced: "{today}"\n'
    if additions:
        # Re-search since txt may have changed
        bs_m2 = re.search(r'(?ms)^bda_spec:\s*\n((?:[ \t]+.+\n?)+)', txt)
        txt = txt[:bs_m2.end()] + additions + txt[bs_m2.end():]
else:
    blk = 'bda_spec:\n'
    if src:  blk += f'  source: "{src}"\n'
    blk += f'  last_synced: "{today}"\n'
    txt = txt.rstrip() + '\n\n' + blk

with open(p, 'w') as f: f.write(txt)
PYEOF
  ok "Updated .bda-spec.yml bda_spec.last_synced (+ migrated legacy standard.* block if present)"
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
