#!/usr/bin/env bash
# bda-paths — Single source of truth for config + vault paths
# Resolves .bda-spec.yml + .bda-spec.local.yml override + sensible defaults
# Used by all commands (instead of grep-yaml-inline)
#
# Output modes:
#   --shell            eval-able shell vars (default)
#   --json             JSON object (for jq pipelines)
#   --paths-only       only path-related keys
#   --check <key>      print single value (e.g., --check VAULT_PATH)
#   --help             show this

set -euo pipefail

ROOT="${BDA_SPEC_ROOT:-$(pwd)}"
SHARED="${ROOT}/.bda-spec.yml"
LOCAL="${ROOT}/.bda-spec.local.yml"

MODE="shell"
CHECK_KEY=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --shell)      MODE=shell; shift ;;
    --json)       MODE=json; shift ;;
    --paths-only) MODE=paths; shift ;;
    --check)      MODE=check; CHECK_KEY="$2"; shift 2 ;;
    -h|--help)
      grep '^#' "$0" | head -20; exit 0 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

# ── helpers ──────────────────────────────────────────────────────────────────

yget() {
  # yget <file> <yaml-path>  (e.g., yget .bda-spec.yml project.name)
  local file="$1" path="$2"
  [ -f "$file" ] || { echo ""; return; }
  if command -v yq >/dev/null 2>&1; then
    local v
    v=$(yq ".$path // \"\"" "$file" 2>/dev/null | tr -d '"')
    [ "$v" = "null" ] && v=""
    echo "$v"
    return
  fi
  # Fallback: awk-based YAML parser handling depth 1/2/3 + comment stripping
  local depth_keys; IFS=. read -ra depth_keys <<< "$path"
  local result=""
  case "${#depth_keys[@]}" in
    1)
      result=$(awk -v k="${depth_keys[0]}:" '
        index($0, k) == 1 {
          sub(k, "");
          # strip inline comment
          gsub(/#.*$/, "");
          gsub(/^[ \t]+|[ \t]+$/, "");
          gsub(/^"|"$/, "");
          print; exit
        }' "$file") ;;
    2)
      result=$(awk -v a="${depth_keys[0]}:" -v b="  ${depth_keys[1]}:" '
        $0 ~ ("^" a)                  { in_block=1; next }
        /^[a-zA-Z_]/                   { in_block=0 }
        in_block && index($0, b) == 1 {
          sub(b, "");
          gsub(/#.*$/, "");
          gsub(/^[ \t]+|[ \t]+$/, "");
          gsub(/^"|"$/, "");
          print; exit }
      ' "$file") ;;
    3)
      result=$(awk -v a="${depth_keys[0]}:" -v b="  ${depth_keys[1]}:" -v c="    ${depth_keys[2]}:" '
        $0 ~ ("^" a)                  { in_a=1; next }
        /^[a-zA-Z_]/                   { in_a=0; in_b=0 }
        in_a && index($0, b) == 1     { in_b=1; next }
        in_b && index($0, c) == 1 {
          sub(c, "");
          gsub(/#.*$/, "");
          gsub(/^[ \t]+|[ \t]+$/, "");
          gsub(/^"|"$/, "");
          print; exit }
      ' "$file") ;;
  esac
  echo "$result"
}

# Override chain: local > shared > default
get() {
  local key="$1" default="$2"
  local local_val shared_val
  local_val="$(yget "$LOCAL" "$key" 2>/dev/null || echo "")"
  shared_val="$(yget "$SHARED" "$key" 2>/dev/null || echo "")"
  if [ -n "$local_val" ]; then echo "$local_val"
  elif [ -n "$shared_val" ]; then echo "$shared_val"
  else echo "$default"
  fi
}

# ── resolve all paths ────────────────────────────────────────────────────────

PROJECT_NAME=$(get "project.name" "unknown-project")
PROJECT_SLUG=$(get "project.slug" "unknown-project")
PROJECT_LANG=$(get "project.language" "th")
PROJECT_TZ=$(get "project.timezone" "Asia/Bangkok")

MODE_VAL=$(get "mode" "standalone")

VAULT_PATH=$(get "vault_path" "docs/obsidian-vault")
EXTERNAL_VAULT=$(yget "$LOCAL" "paths.external_vault")
[ -n "$EXTERNAL_VAULT" ] && VAULT_PATH="$EXTERNAL_VAULT"

# Absolute vault path
if [[ "$VAULT_PATH" = /* ]]; then VAULT_ABS="$VAULT_PATH"; else VAULT_ABS="$ROOT/$VAULT_PATH"; fi

# Personal paths
DAILY_LOG_MIRROR=$(yget "$LOCAL" "paths.daily_log_mirror")
EVIDENCE_STAGING=$(yget "$LOCAL" "paths.evidence_staging")
SECRETS_FILE=$(yget "$LOCAL" "paths.secrets_file")

# bda-spec metadata (v0.4.1+: was under `standard.*`; legacy keys still readable via fallback)
# BDA standard version ที่ pinned อยู่ใน file `.bda-spec/VERSION` เท่านั้น (single source of truth)
BDA_SPEC_VERSION=$(yget "$SHARED" "bda_spec.version")
[ -z "$BDA_SPEC_VERSION" ] && BDA_SPEC_VERSION=$(yget "$SHARED" "standard.bda_spec_version")     # legacy
BDA_SPEC_SOURCE=$(yget "$SHARED" "bda_spec.source")
[ -z "$BDA_SPEC_SOURCE" ] && BDA_SPEC_SOURCE=$(yget "$SHARED" "standard.source")                 # legacy
BDA_SPEC_LAST_SYNC=$(yget "$SHARED" "bda_spec.last_synced")
[ -z "$BDA_SPEC_LAST_SYNC" ] && BDA_SPEC_LAST_SYNC=$(yget "$SHARED" "standard.last_synced")      # legacy

# STANDARD_VERSION: อ่านจาก .bda-spec/VERSION (single source of truth — ไม่ duplicate ใน YAML)
if [ -f "$ROOT/.bda-spec/VERSION" ]; then
  STANDARD_VERSION=$(tr -d '[:space:]' < "$ROOT/.bda-spec/VERSION")
elif [ -f "$ROOT/.bda-spec/standards/VERSION" ]; then
  STANDARD_VERSION=$(tr -d '[:space:]' < "$ROOT/.bda-spec/standards/VERSION")  # v0.4-intermediate
elif [ -f "$ROOT/standards/VERSION" ]; then
  STANDARD_VERSION=$(tr -d '[:space:]' < "$ROOT/standards/VERSION")            # pre-v0.4
else
  STANDARD_VERSION=""
fi
# Back-compat aliases (so older callers still work)
STANDARD_LAST_SYNC="$BDA_SPEC_LAST_SYNC"
STANDARD_SOURCE="$BDA_SPEC_SOURCE"

# Common derived paths
IMPL_STATUS="$VAULT_ABS/00-Index/IMPLEMENTATION-STATUS.md"
PRD_DIR="$VAULT_ABS/10-PRD"
FEAT_DIR="$VAULT_ABS/20-Features"
ROLE_DIR="$VAULT_ABS/30-Roles"
FN_DIR="$VAULT_ABS/40-Functions"
PHASE_DIR="$VAULT_ABS/50-Phases"
FLOW_DIR="$VAULT_ABS/60-Flows"
REF_DIR="$VAULT_ABS/70-Reference"
DS_DIR="$REF_DIR/DesignSystem"
CHECKIN_DIR="$VAULT_ABS/75-Checkins"
PLAN_DIR="$VAULT_ABS/80-ImplementPlan"
FIX_DIR="$VAULT_ABS/85-FixLog"
TEST_DIR="$VAULT_ABS/90-TestPlan"
HANDOFF_DIR="$VAULT_ABS/95-Handoff"

# Today's checkin
TODAY=$(date +%Y-%m-%d)
TODAY_CHECKIN="$CHECKIN_DIR/${TODAY}.md"

# Templates lookup chain (v0.4+: standards snapshot moved into .bda-spec/)
# Backward-compat: if legacy layout (root `standards/`) still exists, fall back to it
# so projects installed before v0.4 keep working until they run migration
TEMPLATES_LOCAL="$ROOT/.bda-spec/local/templates"
TEMPLATES_PROJECT="$ROOT/templates"
# Resolve TEMPLATES_STANDARD via fallback chain (newest layout first)
if [ -d "$ROOT/.bda-spec/templates" ]; then
  TEMPLATES_STANDARD="$ROOT/.bda-spec/templates"            # v0.4 current (flat)
elif [ -d "$ROOT/.bda-spec/standards/templates" ]; then
  TEMPLATES_STANDARD="$ROOT/.bda-spec/standards/templates"  # v0.4-intermediate
elif [ -d "$ROOT/standards/templates" ]; then
  TEMPLATES_STANDARD="$ROOT/standards/templates"            # pre-v0.4
else
  TEMPLATES_STANDARD="$ROOT/.bda-spec/templates"            # default for fresh install
fi

# BDA standard snapshot root (for STANDARD.md, policies/, checklists/, workflows/)
if [ -f "$ROOT/.bda-spec/STANDARD.md" ]; then
  STANDARD_ROOT="$ROOT/.bda-spec"                       # v0.4 current
elif [ -f "$ROOT/.bda-spec/standards/STANDARD.md" ]; then
  STANDARD_ROOT="$ROOT/.bda-spec/standards"             # v0.4-intermediate
elif [ -f "$ROOT/standards/STANDARD.md" ]; then
  STANDARD_ROOT="$ROOT/standards"                       # pre-v0.4
else
  STANDARD_ROOT="$ROOT/.bda-spec"
fi

# Commands lookup chain (v0.4.1+: commands moved into .bda-spec/)
# Order: project override (root) → .bda-spec/commands → legacy fallback
# COMMANDS_DIR_PRIMARY: where AI shims should @-reference (the canonical source)
# COMMANDS_DIR_OVERRIDE: optional user override layer (root commands/)
if [ -d "$ROOT/.bda-spec/commands" ]; then
  COMMANDS_DIR_PRIMARY="$ROOT/.bda-spec/commands"   # v0.4.1 current
elif [ -d "$ROOT/commands" ]; then
  COMMANDS_DIR_PRIMARY="$ROOT/commands"             # pre-v0.4.1 legacy
else
  COMMANDS_DIR_PRIMARY="$ROOT/.bda-spec/commands"   # default for fresh install
fi
COMMANDS_DIR_OVERRIDE="$ROOT/commands"

# Subagents (enabled list)
ENABLED_AGENTS=""
for a in docs verifier security design backend frontend mobile figma test-runner; do
  val=$(yget "$SHARED" "subagents.$a")
  if [ "$val" = "true" ]; then ENABLED_AGENTS="${ENABLED_AGENTS}${a} "; fi
done
ENABLED_AGENTS="${ENABLED_AGENTS% }"

# ── output ───────────────────────────────────────────────────────────────────

print_var() {
  printf "%s=%s\n" "$1" "$(printf %q "$2")"
}

case "$MODE" in
  shell)
    print_var ROOT             "$ROOT"
    print_var PROJECT_NAME     "$PROJECT_NAME"
    print_var PROJECT_SLUG     "$PROJECT_SLUG"
    print_var PROJECT_LANG     "$PROJECT_LANG"
    print_var PROJECT_TZ       "$PROJECT_TZ"
    print_var MODE_VAL         "$MODE_VAL"
    print_var VAULT_PATH       "$VAULT_PATH"
    print_var VAULT_ABS        "$VAULT_ABS"
    print_var EXTERNAL_VAULT   "$EXTERNAL_VAULT"
    print_var DAILY_LOG_MIRROR "$DAILY_LOG_MIRROR"
    print_var EVIDENCE_STAGING "$EVIDENCE_STAGING"
    print_var SECRETS_FILE     "$SECRETS_FILE"
    print_var STANDARD_VERSION    "$STANDARD_VERSION"
    print_var STANDARD_SOURCE     "$STANDARD_SOURCE"
    print_var STANDARD_LAST_SYNC  "$STANDARD_LAST_SYNC"
    print_var BDA_SPEC_VERSION    "$BDA_SPEC_VERSION"
    print_var BDA_SPEC_SOURCE     "$BDA_SPEC_SOURCE"
    print_var BDA_SPEC_LAST_SYNC  "$BDA_SPEC_LAST_SYNC"
    print_var IMPL_STATUS      "$IMPL_STATUS"
    print_var PRD_DIR          "$PRD_DIR"
    print_var FEAT_DIR         "$FEAT_DIR"
    print_var FN_DIR           "$FN_DIR"
    print_var PHASE_DIR        "$PHASE_DIR"
    print_var FLOW_DIR         "$FLOW_DIR"
    print_var REF_DIR          "$REF_DIR"
    print_var DS_DIR           "$DS_DIR"
    print_var CHECKIN_DIR      "$CHECKIN_DIR"
    print_var PLAN_DIR         "$PLAN_DIR"
    print_var FIX_DIR          "$FIX_DIR"
    print_var TEST_DIR         "$TEST_DIR"
    print_var HANDOFF_DIR      "$HANDOFF_DIR"
    print_var TODAY            "$TODAY"
    print_var TODAY_CHECKIN    "$TODAY_CHECKIN"
    print_var TEMPLATES_LOCAL  "$TEMPLATES_LOCAL"
    print_var TEMPLATES_PROJECT "$TEMPLATES_PROJECT"
    print_var TEMPLATES_STANDARD "$TEMPLATES_STANDARD"
    print_var COMMANDS_DIR_PRIMARY  "$COMMANDS_DIR_PRIMARY"
    print_var COMMANDS_DIR_OVERRIDE "$COMMANDS_DIR_OVERRIDE"
    print_var STANDARD_ROOT    "$STANDARD_ROOT"
    print_var ENABLED_AGENTS   "$ENABLED_AGENTS"
    ;;
  json)
    cat <<EOF
{
  "root": "$ROOT",
  "project": {"name":"$PROJECT_NAME","slug":"$PROJECT_SLUG","language":"$PROJECT_LANG","timezone":"$PROJECT_TZ"},
  "mode": "$MODE_VAL",
  "vault": {"path":"$VAULT_PATH","abs":"$VAULT_ABS","external":"$EXTERNAL_VAULT"},
  "paths": {
    "daily_log_mirror":"$DAILY_LOG_MIRROR",
    "evidence_staging":"$EVIDENCE_STAGING",
    "secrets_file":"$SECRETS_FILE",
    "impl_status":"$IMPL_STATUS",
    "prd":"$PRD_DIR","features":"$FEAT_DIR","functions":"$FN_DIR",
    "phases":"$PHASE_DIR","flows":"$FLOW_DIR","reference":"$REF_DIR",
    "design_system":"$DS_DIR","checkins":"$CHECKIN_DIR",
    "plans":"$PLAN_DIR","fixes":"$FIX_DIR","tests":"$TEST_DIR","handoffs":"$HANDOFF_DIR",
    "today_checkin":"$TODAY_CHECKIN"
  },
  "templates": {"local":"$TEMPLATES_LOCAL","project":"$TEMPLATES_PROJECT","standard":"$TEMPLATES_STANDARD"},
  "commands": {"primary":"$COMMANDS_DIR_PRIMARY","override":"$COMMANDS_DIR_OVERRIDE"},
  "bda_spec": {"version":"$BDA_SPEC_VERSION","source":"$BDA_SPEC_SOURCE","last_synced":"$BDA_SPEC_LAST_SYNC"},
  "standard": {"version":"$STANDARD_VERSION","root":"$STANDARD_ROOT"},
  "subagents_enabled": "$ENABLED_AGENTS",
  "today": "$TODAY"
}
EOF
    ;;
  paths)
    for k in IMPL_STATUS PRD_DIR FEAT_DIR FN_DIR PLAN_DIR FIX_DIR TEST_DIR HANDOFF_DIR CHECKIN_DIR DS_DIR TODAY_CHECKIN; do
      print_var "$k" "$(eval echo \$$k)"
    done
    ;;
  check)
    eval echo "\${$CHECK_KEY}"
    ;;
esac
