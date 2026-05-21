#!/usr/bin/env bash
# bda-spec upload-evidence — batch upload evidence to GDrive / cloud via rclone
#
# Usage:
#   bash scripts/upload-evidence.sh                       # interactive
#   bash scripts/upload-evidence.sh --pending             # all not-yet-uploaded
#   bash scripts/upload-evidence.sh --feature <slug>      # filter by feature
#   bash scripts/upload-evidence.sh --dry-run             # show plan only
#   bash scripts/upload-evidence.sh --provider gdrive|s3  # default gdrive
#
# Prerequisites:
#   • rclone installed (brew install rclone)
#   • rclone remote configured: rclone config (create 'bda-gdrive' or set in .bda-spec.local.yml)
#   • .bda-spec.local.yml has evidence_upload.gdrive_folder set
#
# Outputs:
#   • Files uploaded under <gdrive_folder>/<YYYY-MM-DD>/<context>/<filename>
#   • Manifest updated with GDrive Link, Uploaded At, Uploaded By
#   • Daily checkin appended with summary

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

# Load paths config
eval "$(bash "$SCRIPT_DIR/bda-paths.sh" --shell 2>/dev/null)"

# ── flags ──
PROVIDER="gdrive"
FILTER_FEATURE=""
FILTER_PLAN=""
FILTER_FIX=""
FILTER_SINCE=""
PENDING_ONLY=0
DRY_RUN=0
FORCE_SIZE=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --provider) PROVIDER="$2"; shift 2 ;;
    --feature) FILTER_FEATURE="$2"; shift 2 ;;
    --plan) FILTER_PLAN="$2"; shift 2 ;;
    --fix) FILTER_FIX="$2"; shift 2 ;;
    --since) FILTER_SINCE="$2"; shift 2 ;;
    --pending) PENDING_ONLY=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --force-size) FORCE_SIZE=1; shift ;;
    -h|--help) grep '^#' "$0" | head -25; exit 0 ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
done

# ── colors ──
c_bold='\033[1m'; c_reset='\033[0m'
c_green='\033[32m'; c_red='\033[31m'; c_yellow='\033[33m'; c_blue='\033[34m'; c_dim='\033[2m'
log()  { printf "${c_blue}[upload]${c_reset} %s\n" "$*"; }
ok()   { printf "${c_green}  ✓${c_reset} %s\n" "$*"; }
warn() { printf "${c_yellow}  ⚠${c_reset} %s\n" "$*" >&2; }
err()  { printf "${c_red}  ✗${c_reset} %s\n" "$*" >&2; }
skip() { printf "${c_dim}  ⊘${c_reset} %s\n" "$*"; }

# ── config from .bda-spec.local.yml ──
LOCAL_YML=".bda-spec.local.yml"
yget_local() {
  bash "$SCRIPT_DIR/bda-paths.sh" --check "$1" 2>/dev/null || echo ""
}

# Read evidence_upload section using a small awk parser
read_upload_config() {
  [ -f "$LOCAL_YML" ] || return 0
  awk '
    /^evidence_upload:/        { in_block=1; next }
    /^[a-zA-Z_]/                { in_block=0 }
    in_block && /^  [a-zA-Z_]+:/ {
      key=$1; sub(":", "", key); val=$0
      sub(/^  [a-zA-Z_]+:[ \t]*/, "", val)
      gsub(/^"|"$/, "", val)
      gsub(/#.*$/, "", val)
      gsub(/^[ \t]+|[ \t]+$/, "", val)
      printf "EVUP_%s=\"%s\"\n", toupper(key), val
    }
  ' "$LOCAL_YML"
}

eval "$(read_upload_config)"

GDRIVE_FOLDER="${EVUP_GDRIVE_FOLDER:-}"
GDRIVE_REMOTE="${EVUP_RCLONE_REMOTE:-bda-gdrive}"
LINK_VISIBILITY="${EVUP_LINK_VISIBILITY:-private}"
ORG_DOMAIN="${EVUP_ORG_DOMAIN:-bda.co.th}"
CLEANUP_LOCAL="${EVUP_CLEANUP_LOCAL_AFTER_UPLOAD:-false}"
FOLDER_STRUCTURE="${EVUP_FOLDER_STRUCTURE:-by-date}"   # by-date | by-feature | flat
MAX_SIZE_MB="${EVUP_MAX_SIZE_MB:-50}"

if [ -z "$GDRIVE_FOLDER" ]; then
  cat <<EOF
${c_yellow}⚠ ยังไม่ได้ตั้งค่า evidence_upload ใน .bda-spec.local.yml${c_reset}

ตัวอย่าง config (เพิ่มในไฟล์):

evidence_upload:
  provider: gdrive
  rclone_remote: bda-gdrive
  gdrive_folder: BDA-Evidence/${PROJECT_SLUG:-myproject}
  link_visibility: org              # private | org | anyone
  folder_structure: by-date         # by-date | by-feature | flat
  max_size_mb: 50
  cleanup_local_after_upload: false

ตั้งค่า rclone:
  rclone config                    # สร้าง remote 'bda-gdrive' (type=drive)
  rclone lsd bda-gdrive:           # ทดสอบ
EOF
  exit 1
fi

# ── check rclone ──
if ! command -v rclone >/dev/null 2>&1; then
  err "rclone ไม่พบ — ติดตั้ง: brew install rclone (macOS) / curl https://rclone.org/install.sh | sudo bash"
  exit 1
fi

if ! rclone listremotes 2>/dev/null | grep -q "^${GDRIVE_REMOTE}:"; then
  err "rclone remote '$GDRIVE_REMOTE' ไม่ได้ตั้งค่า — รัน: rclone config"
  exit 1
fi

# ── scan manifests ──
log "Scanning evidence manifests in vault: $VAULT_ABS"

MANIFESTS=()
for d in 20-Features 80-ImplementPlan 85-FixLog 90-TestPlan 95-Handoff; do
  [ -d "$VAULT_ABS/$d" ] || continue
  while IFS= read -r m; do
    MANIFESTS+=("$m")
  done < <(find "$VAULT_ABS/$d" -name "evidence-manifest.md" 2>/dev/null)
done

log "Found ${#MANIFESTS[@]} manifest(s)"

# ── extract entries needing upload ──
declare -a TO_UPLOAD=()
declare -a BLOCKED=()

# Manifest table format (markdown):
# | ID | File | Type | Captured | Scenario/Step | PII | Masked | Safe-to-share | GDrive Link | Uploaded At | Uploaded By |

for m in "${MANIFESTS[@]}"; do
  context_dir=$(dirname "$m")
  while IFS='|' read -r _ id file type captured scenario pii masked safe gdrive uploaded_at uploaded_by _; do
    id=$(echo "$id" | xargs); [ -z "$id" ] && continue
    [[ "$id" =~ ^E[0-9]+ ]] || continue
    file=$(echo "$file" | xargs)
    pii=$(echo "$pii" | xargs)
    masked=$(echo "$masked" | xargs)
    safe=$(echo "$safe" | xargs)
    gdrive=$(echo "$gdrive" | xargs)

    # Already uploaded?
    if [ -n "$gdrive" ] && [[ "$gdrive" =~ ^https?:// ]]; then
      continue
    fi

    # Gate 1: PII raw
    if [ "$pii" = "raw" ]; then
      BLOCKED+=("$id|$file|raw PII")
      continue
    fi

    # Gate 2: safe_to_share = no / ✗
    if [ "$safe" = "no" ] || [ "$safe" = "✗" ] || [ "$safe" = "x" ]; then
      BLOCKED+=("$id|$file|marked unsafe")
      continue
    fi

    # Gate 3: masked but not actually masked
    if [ "$pii" = "masked" ] && [ "$masked" != "✓" ] && [ "$masked" != "yes" ]; then
      BLOCKED+=("$id|$file|PII present, not masked")
      continue
    fi

    # Resolve local file path
    local_path="$context_dir/$file"
    [ ! -f "$local_path" ] && {
      BLOCKED+=("$id|$file|file missing locally")
      continue
    }

    # Apply filters
    if [ -n "$FILTER_FEATURE" ] && [[ "$context_dir" != *"$FILTER_FEATURE"* ]]; then continue; fi
    if [ -n "$FILTER_PLAN" ] && [[ "$m" != *"$FILTER_PLAN"* ]]; then continue; fi
    if [ -n "$FILTER_FIX" ] && [[ "$m" != *"$FILTER_FIX"* ]]; then continue; fi

    TO_UPLOAD+=("$id|$file|$local_path|$context_dir|$m")
  done < "$m"
done

# ── show plan ──
log ""
log "${c_bold}Plan: upload ${#TO_UPLOAD[@]} items, block ${#BLOCKED[@]} items${c_reset}"

if [ ${#BLOCKED[@]} -gt 0 ]; then
  warn "Blocked (cannot upload):"
  for b in "${BLOCKED[@]}"; do
    IFS='|' read -r id file reason <<< "$b"
    skip "$id $file — $reason"
  done
fi

if [ ${#TO_UPLOAD[@]} -eq 0 ]; then
  log "ไม่มี evidence ที่จะ upload"
  exit 0
fi

# Show preview
log ""
log "${c_bold}Will upload:${c_reset}"
for u in "${TO_UPLOAD[@]:0:10}"; do
  IFS='|' read -r id file local_path _ _ <<< "$u"
  size=$(stat -f%z "$local_path" 2>/dev/null || stat -c%s "$local_path" 2>/dev/null || echo 0)
  size_kb=$((size / 1024))
  log "  $id $file (${size_kb} KB)"
done
[ ${#TO_UPLOAD[@]} -gt 10 ] && log "  ... และอีก $((${#TO_UPLOAD[@]} - 10)) ไฟล์"

if [ "$DRY_RUN" -eq 1 ]; then
  log ""
  log "${c_yellow}DRY RUN${c_reset} — ไม่ได้ upload จริง"
  exit 0
fi

# ── confirm ──
printf "\n${c_bold}อัปโหลด %d ไฟล์ไปยัง %s:%s ?${c_reset} [y/N] " \
  "${#TO_UPLOAD[@]}" "$GDRIVE_REMOTE" "$GDRIVE_FOLDER"
read -r confirm
[[ "$confirm" =~ ^[Yy] ]] || { log "Aborted."; exit 0; }

# ── upload loop ──
TODAY="${TODAY:-$(date +%Y-%m-%d)}"
NOW=$(date +%H:%M)
USER_NAME="${USER:-unknown}"
UPLOADED_COUNT=0
FAILED_COUNT=0
declare -a UPLOADED_LINKS=()

for u in "${TO_UPLOAD[@]}"; do
  IFS='|' read -r id file local_path context_dir manifest_file <<< "$u"

  # Determine remote folder
  context_slug=$(basename "$context_dir")
  case "$FOLDER_STRUCTURE" in
    by-date)    remote_folder="${GDRIVE_FOLDER}/${TODAY}/${context_slug}" ;;
    by-feature) remote_folder="${GDRIVE_FOLDER}/${context_slug}" ;;
    flat)       remote_folder="${GDRIVE_FOLDER}" ;;
    *)          remote_folder="${GDRIVE_FOLDER}/${TODAY}/${context_slug}" ;;
  esac

  log "Uploading $id $file → $remote_folder/"

  # Size check
  size=$(stat -f%z "$local_path" 2>/dev/null || stat -c%s "$local_path" 2>/dev/null || echo 0)
  size_mb=$((size / 1024 / 1024))
  if [ "$size_mb" -gt "$MAX_SIZE_MB" ] && [ "$FORCE_SIZE" -eq 0 ]; then
    warn "  skip — ${size_mb} MB > ${MAX_SIZE_MB} MB limit (use --force-size to override)"
    FAILED_COUNT=$((FAILED_COUNT + 1))
    continue
  fi

  # Make remote folder (idempotent)
  rclone mkdir "${GDRIVE_REMOTE}:${remote_folder}" 2>/dev/null

  # Upload
  if rclone copy "$local_path" "${GDRIVE_REMOTE}:${remote_folder}/" --transfers 4 2>/tmp/rclone-up.$$; then
    # Get shareable link
    link=$(rclone link "${GDRIVE_REMOTE}:${remote_folder}/${file}" 2>/tmp/rclone-link.$$)
    if [[ "$link" =~ ^https?:// ]]; then
      ok "$id → $link"
      UPLOADED_LINKS+=("$id|$context_slug|$file|$link")
      UPLOADED_COUNT=$((UPLOADED_COUNT + 1))

      # Update manifest row
      if [ -f "$manifest_file" ]; then
        # Use awk to update the row matching this id
        tmpf=$(mktemp)
        awk -F'|' -v id="$id" -v link="$link" -v at="$TODAY $NOW" -v by="$USER_NAME" '
          BEGIN { OFS="|" }
          $0 !~ /^\| / { print; next }
          {
            id_field=$2; gsub(/^[ \t]+|[ \t]+$/, "", id_field)
            if (id_field == id) {
              # Find GDrive Link / Uploaded At / Uploaded By columns (last 3 before trailing |)
              n=NF
              $(n-3)=" " link " "
              $(n-2)=" " at " "
              $(n-1)=" " by " "
            }
            print
          }
        ' "$manifest_file" > "$tmpf"
        cp "$tmpf" "$manifest_file" 2>/dev/null
        rm -f "$tmpf"
      fi
    else
      err "$id link failed: $(cat /tmp/rclone-link.$$)"
      FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
  else
    err "$id upload failed: $(cat /tmp/rclone-up.$$ | tail -3)"
    FAILED_COUNT=$((FAILED_COUNT + 1))
  fi
done

rm -f /tmp/rclone-up.$$ /tmp/rclone-link.$$ 2>/dev/null

# ── append to today's checkin ──
CHECKIN="${CHECKIN_DIR}/${TODAY}.md"
if [ -f "$CHECKIN" ] && [ "$UPLOADED_COUNT" -gt 0 ]; then
  {
    echo ""
    echo "- $NOW — [type/upload] /bda-upload — $UPLOADED_COUNT items uploaded${FAILED_COUNT:+, $FAILED_COUNT failed}"
    echo "  Evidence URLs:"
    for ul in "${UPLOADED_LINKS[@]}"; do
      IFS='|' read -r id ctx file link <<< "$ul"
      echo "    - $ctx $id: $link"
    done
  } >> "$CHECKIN"
fi

# ── mirror to daily_log_mirror (executive folder) ──
if [ -n "${DAILY_LOG_MIRROR:-}" ] && [ -d "$DAILY_LOG_MIRROR" ] && [ "$UPLOADED_COUNT" -gt 0 ]; then
  mirror_file="$DAILY_LOG_MIRROR/${TODAY}-evidence-${PROJECT_SLUG:-project}.md"
  {
    echo "# Evidence — ${TODAY} — ${PROJECT_NAME:-project}"
    echo ""
    echo "Uploaded by: $USER_NAME · Generated: $(date +%Y-%m-%d\ %H:%M)"
    echo ""
    echo "| Context | Item | File | GDrive Link |"
    echo "|---|---|---|---|"
    for ul in "${UPLOADED_LINKS[@]}"; do
      IFS='|' read -r id ctx file link <<< "$ul"
      echo "| $ctx | $id | $file | [$file]($link) |"
    done
  } > "$mirror_file"
  ok "Mirror: $mirror_file"
fi

# ── summary ──
echo ""
printf "${c_bold}Summary${c_reset}\n"
printf "  ${c_green}Uploaded:${c_reset} %d\n" "$UPLOADED_COUNT"
[ "$FAILED_COUNT" -gt 0 ] && printf "  ${c_red}Failed:${c_reset}   %d\n" "$FAILED_COUNT"
[ "${#BLOCKED[@]}" -gt 0 ] && printf "  ${c_yellow}Blocked:${c_reset}  %d (PII/unsafe — แก้แล้วลอง upload ใหม่)\n" "${#BLOCKED[@]}"

[ "$FAILED_COUNT" -gt 0 ] && exit 2
exit 0
