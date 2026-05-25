#!/usr/bin/env bash
# bda-spec installer — bootstrap docs-driven AI dev workflow in any project
#
# Usage:
#   Greenfield (new empty folder):
#     mkdir my-project && cd my-project && bash <(curl -fsSL .../install.sh)
#
#   Brownfield (existing project):
#     cd existing-project && bash <(curl -fsSL .../install.sh)
#
#   Local (from cloned bda-spec):
#     ./scripts/install.sh /path/to/target-project
#
# Flags:
#   --source <path|url>   เลือกแหล่ง bda-spec template (default: github)
#   --version <tag>       เลือก version (default: latest)
#   --mode greenfield|brownfield|auto   (default: auto-detect)
#   --ai <list>           Comma-separated AI agents: claude,codex,google,gpt,glm
#                         (default: interactive picker; --yes uses "claude")
#   --yes                 ข้ามคำถามทั้งหมด ใช้ default
#   --dry-run             แสดงสิ่งที่จะทำ แต่ไม่จริง
#
# AI agents supported (เหมือน spec-kit แต่ลดเหลือ 5 ตัว):
#   claude   — Claude Code (Anthropic) — slash commands + subagents
#   codex    — OpenAI Codex CLI — AGENTS.md routing
#   google   — Google Gemini CLI/API — gemini/prompts/
#   gpt      — ChatGPT (web/API) — gpt/prompts/
#   glm      — Zhipu GLM / ChatGLM — glm/prompts/

set -euo pipefail

# ---------- defaults ----------
SOURCE_URL="${BDA_SPEC_SOURCE:-https://github.com/sdumumpai-bda/bda-spec.git}"
VERSION="${BDA_SPEC_VERSION:-main}"
MODE="auto"
AI_AGENTS=""                       # "" = ask interactively; "all" = all 5
YES=0
DRY_RUN=0
TARGET=""

# ---------- parse args ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) SOURCE_URL="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --ai) AI_AGENTS="$2"; shift 2 ;;
    --yes) YES=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help)
      grep '^#' "$0" | head -35; exit 0 ;;
    --*)
      err "Unknown flag: $1"; exit 1 ;;
    *) TARGET="$1"; shift ;;
  esac
done

# Default target: cwd (if no positional arg provided)
TARGET="${TARGET:-$(pwd)}"

# ---------- helpers ----------
log() { printf '\033[1;36m[bda-spec]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[bda-spec]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[bda-spec]\033[0m %s\n' "$*" >&2; }
ask() {
  local prompt="$1"; local default="$2"; local reply
  if [[ $YES -eq 1 ]]; then echo "$default"; return; fi
  read -r -p "$prompt [$default]: " reply
  echo "${reply:-$default}"
}
run() {
  if [[ $DRY_RUN -eq 1 ]]; then echo "DRY-RUN: $*"; else eval "$@"; fi
}

# ---------- detect indicators (returns list of what was found) ----------
detect_indicators() {
  local found=()
  local manifests=(package.json requirements.txt pyproject.toml Pipfile pom.xml build.gradle build.gradle.kts go.mod Cargo.toml composer.json Gemfile pubspec.yaml mix.exs)
  for m in "${manifests[@]}"; do
    [[ -f "$TARGET/$m" ]] && found+=("$m")
  done
  if compgen -G "$TARGET/*.csproj" > /dev/null 2>&1; then found+=("*.csproj"); fi
  if compgen -G "$TARGET/*.sln" > /dev/null 2>&1; then found+=("*.sln"); fi

  # Source folders (any of these = likely brownfield)
  for d in src lib app frontend backend mobile server client api packages apps services; do
    [[ -d "$TARGET/$d" ]] && found+=("$d/")
  done

  # Git history (real commits, not just empty init)
  if [[ -d "$TARGET/.git" ]]; then
    local commits
    commits=$(git -C "$TARGET" rev-list --count HEAD 2>/dev/null || echo 0)
    if [[ "$commits" -gt 0 ]]; then
      found+=(".git ($commits commits)")
    fi
  fi

  # Submodules
  [[ -f "$TARGET/.gitmodules" ]] && found+=(".gitmodules")

  # Existing docs/ vault
  if [[ -d "$TARGET/docs" ]] && [[ -n "$(find "$TARGET/docs" -maxdepth 2 -name '*.md' 2>/dev/null | head -1)" ]]; then
    found+=("docs/ (existing content)")
  fi

  # Print one per line (guard against empty array under set -u)
  [[ ${#found[@]} -eq 0 ]] && return 0
  printf "%s\n" "${found[@]}"
}

# ---------- ask user when ambiguous ----------
ask_mode() {
  # If --mode was set explicitly, honor it
  if [[ "$MODE" != "auto" ]]; then
    echo "$MODE"; return
  fi

  local indicators
  indicators=$(detect_indicators)

  # Case 1: ไม่มี indicator เลย → greenfield แน่นอน (no question)
  if [[ -z "$indicators" ]]; then
    echo "greenfield"
    return
  fi

  # Case 2: มี indicators → ถาม user (เพราะอาจเป็น setup ไว้แล้วแต่ยังเป็น greenfield)
  if [[ $YES -eq 1 ]]; then
    # --yes mode → ถือว่า brownfield ถ้ามี indicator
    echo "brownfield"
    return
  fi

  cat >&2 <<EOF

🔍 ${c_bold:-}ตรวจพบ indicators ใน folder นี้:${c_reset:-}

$(echo "$indicators" | sed 's/^/   • /')

${c_bold:-}โหมดไหนตรงกับสถานการณ์ของคุณ?${c_reset:-}

  1) ${c_bold:-}greenfield${c_reset:-}  — ${c_dim:-}project setup ไว้แล้ว แต่ยังไม่มี content จริง (เริ่ม fresh ได้)${c_reset:-}
  2) ${c_bold:-}brownfield${c_reset:-}  — ${c_dim:-}มี code/docs ใช้งานอยู่จริง (adopt + ห้ามแตะของเดิม)${c_reset:-}
  3) ${c_bold:-}adopt-vault${c_reset:-} — ${c_dim:-}มี Obsidian vault อยู่แล้วใน docs/ (ใช้ vault เดิม + รวม commands ของ bda-spec)${c_reset:-}

EOF
  local choice
  read -r -p "เลือก (1/2/3) [default: 2 brownfield]: " choice
  case "${choice:-2}" in
    1|green|greenfield)      echo "greenfield" ;;
    2|brown|brownfield)      echo "brownfield" ;;
    3|adopt|adopt-vault)     echo "adopt-vault" ;;
    *) err "ตัวเลือกไม่ถูกต้อง: $choice"; exit 1 ;;
  esac
}

# Backward-compat alias
detect_mode() {
  local indicators
  indicators=$(detect_indicators)
  [[ -z "$indicators" ]] && echo "greenfield" || echo "brownfield"
}

# ---------- detect stack (brownfield) ----------
detect_stack() {
  local stacks=()
  [[ -f "$TARGET/package.json" ]] && stacks+=("frontend-or-node")
  [[ -f "$TARGET/requirements.txt" || -f "$TARGET/pyproject.toml" ]] && stacks+=("python")
  [[ -f "$TARGET/go.mod" ]] && stacks+=("go")
  [[ -f "$TARGET/Cargo.toml" ]] && stacks+=("rust")
  [[ -f "$TARGET/pubspec.yaml" ]] && stacks+=("flutter")
  [[ -f "$TARGET/pom.xml" || -f "$TARGET/build.gradle" ]] && stacks+=("jvm")
  [[ -f "$TARGET/composer.json" ]] && stacks+=("php")
  if compgen -G "$TARGET/*.csproj" > /dev/null 2>&1; then stacks+=("dotnet"); fi
  if [[ -f "$TARGET/.gitmodules" ]]; then stacks+=("multi-repo"); fi
  if [[ ${#stacks[@]} -eq 0 ]]; then echo "unknown"; else echo "${stacks[*]}"; fi
}

# ---------- main ----------
log "bda-spec installer — version: $VERSION"
log "Target: $TARGET"

[[ -d "$TARGET" ]] || { err "Target folder ไม่พบ: $TARGET"; exit 1; }
cd "$TARGET"

# Detect mode (interactive if indicators present + not --yes)
MODE=$(ask_mode)
log "Mode: $MODE"

# Handle adopt-vault mode (new third option)
ADOPT_VAULT=0
if [[ "$MODE" == "adopt-vault" ]]; then
  ADOPT_VAULT=1
  MODE="brownfield"   # internally treat as brownfield
  log "(adopt-vault: vault path จะใช้ docs/ ที่มีอยู่แล้ว)"
fi

# Detect existing bda-spec
if [[ -f .bda-spec.yml ]]; then
  warn ".bda-spec.yml already exists — re-init?"
  reply=$(ask "Continue and overwrite config? (y/N)" "n")
  [[ "$reply" =~ ^[Yy] ]] || { log "Aborted."; exit 0; }
fi

# Detect stack (brownfield only)
STACK=""
if [[ "$MODE" == "brownfield" ]]; then
  STACK=$(detect_stack)
  log "Detected stack: $STACK"
fi

# ---------- AI agent picker ----------
# Supported AI agents (5 ตัว — เหมือน spec-kit แต่ลดเหลือที่ใช้จริง)
AI_AVAILABLE=(claude codex google gpt glm)

ai_label() {
  case "$1" in
    claude) echo "Claude Code (Anthropic) — slash commands + agents folder" ;;
    codex)  echo "OpenAI Codex CLI — AGENTS.md routing" ;;
    google) echo "Google Gemini CLI/API — gemini/prompts/" ;;
    gpt)    echo "ChatGPT (web/API) — gpt/prompts/" ;;
    glm)    echo "Zhipu GLM / ChatGLM — glm/prompts/" ;;
  esac
}

ai_validate() {
  # Validate comma list against AI_AVAILABLE; print canonical comma list
  local input="$1" out=() found
  IFS=',' read -ra reqs <<< "$input"
  for r in "${reqs[@]}"; do
    r="$(echo "$r" | tr '[:upper:]' '[:lower:]' | xargs)"
    [ -z "$r" ] && continue
    if [ "$r" = "all" ]; then echo "${AI_AVAILABLE[*]}" | tr ' ' ','; return 0; fi
    found=0
    for a in "${AI_AVAILABLE[@]}"; do
      [ "$a" = "$r" ] && { out+=("$a"); found=1; break; }
    done
    [ "$found" -eq 0 ] && { err "Unknown AI agent: $r (available: ${AI_AVAILABLE[*]}, all)"; return 1; }
  done
  (IFS=,; echo "${out[*]}")
}

if [[ -z "$AI_AGENTS" ]]; then
  if [[ $YES -eq 1 ]]; then
    AI_AGENTS="claude"
    log "AI agent (auto-default): $AI_AGENTS"
  else
    cat <<EOF

🤖 ${c_bold:-}เลือก AI frontend ที่จะใช้${c_reset:-} (พิมพ์เลขคั่นด้วย comma เลือกได้หลายตัว):

   1) claude    — $(ai_label claude)
   2) codex     — $(ai_label codex)
   3) google    — $(ai_label google)
   4) gpt       — $(ai_label gpt)
   5) glm       — $(ai_label glm)
   a) all       — เลือกทั้ง 5

Default: 1 (claude)

หมายเหตุ: นี่คือ AI frontend (CLI/web ที่จะคุยด้วย) — ไม่ใช่ subagent
         Subagent (backend/frontend/mobile/...) เริ่มต้นจะมีแค่ docs/verifier/security
         enable เพิ่มภายหลังด้วย /bda-agent enable <name> หรือ /bda-agent suggest
EOF
    read -r -p "เลือก: " ai_input
    ai_input="${ai_input:-1}"
    # Map numbers → names
    selected=()
    if [[ "$ai_input" =~ ^[Aa]$ ]] || [[ "$ai_input" == "all" ]]; then
      selected=("${AI_AVAILABLE[@]}")
    else
      IFS=',' read -ra picks <<< "$ai_input"
      for p in "${picks[@]}"; do
        p="$(echo "$p" | xargs)"
        case "$p" in
          1) selected+=("claude") ;;
          2) selected+=("codex") ;;
          3) selected+=("google") ;;
          4) selected+=("gpt") ;;
          5) selected+=("glm") ;;
          claude|codex|google|gpt|glm) selected+=("$p") ;;
          *) warn "ข้าม invalid: $p" ;;
        esac
      done
    fi
    [[ ${#selected[@]} -eq 0 ]] && { err "ต้องเลือก AI agent อย่างน้อย 1 ตัว"; exit 1; }
    AI_AGENTS=$(IFS=,; echo "${selected[*]}")
  fi
else
  AI_AGENTS=$(ai_validate "$AI_AGENTS") || exit 1
fi

log "AI agents to install: ${c_bold:-}$AI_AGENTS${c_reset:-}"

# Map AI name → folder in template (canonical)
ai_folder() {
  case "$1" in
    claude) echo ".claude" ;;
    codex)  echo "codex" ;;
    google) echo "gemini" ;;
    gpt)    echo "gpt" ;;
    glm)    echo "glm" ;;
  esac
}

# ---------- fetch template ----------
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

log "Fetching bda-spec template..."

if [[ -d "$SOURCE_URL" ]]; then
  # Local source — use `/.` to include hidden files (.bda-spec.yml, .gitignore, .claude, ...)
  # WITHOUT this, glob `/*` skips dotfiles and installer silently produces an incomplete project
  run "cp -r '$SOURCE_URL/.' '$TMP_DIR/' 2>/dev/null || true"
elif [[ "$SOURCE_URL" =~ ^https?:// ]]; then
  if command -v git > /dev/null; then
    # Don't suppress stderr — user needs to see clone failures (auth, missing repo, network)
    if ! run "git clone --depth 1 --branch '$VERSION' '$SOURCE_URL' '$TMP_DIR' 2>&1"; then
      err ""
      err "❌ git clone ล้มเหลว"
      err "   source: $SOURCE_URL"
      err "   branch: $VERSION"
      err "   ตรวจ: repo ถูกต้อง? branch/tag มีอยู่จริง? network/credential ok?"
      exit 1
    fi
  else
    err "git ไม่พบ ติดตั้ง git ก่อน หรือใช้ --source ชี้ไป local folder"
    exit 1
  fi
else
  err "Source ไม่ valid: $SOURCE_URL"
  exit 1
fi

# Sanity check — verify template actually landed (catches silent partial clones)
if [[ $DRY_RUN -eq 0 ]] && [[ ! -f "$TMP_DIR/.bda-spec.yml" ]] && [[ ! -d "$TMP_DIR/commands" ]]; then
  err "❌ Template ที่ clone มาว่างเปล่า หรือไม่ใช่ bda-spec repo"
  err "   TMP_DIR: $TMP_DIR"
  err "   source: $SOURCE_URL ($VERSION)"
  exit 1
fi

# ---------- copy template into target ----------
log "Installing bda-spec scaffolding..."

# Always-installed items (core — regardless of AI selection)
# v0.4+ layout (FLAT under .bda-spec/, no more standards/ subfolder):
#   - .bda-spec/{STANDARD.md, UPDATE-POLICY.md, VERSION, policies/, checklists/, templates/, workflows/}
#   - .bda-spec/VERSION = BDA standard version (NOT bda-spec own version)
#   - bda-spec own version lives in .bda-spec.yml `bda_spec.version` key (no separate file)
#   - root templates/ — OPTIONAL project overrides (lookup chain: root → .bda-spec/templates/)
SAFE_ITEMS=(
  "commands"
  ".bda-spec/STANDARD.md"
  ".bda-spec/UPDATE-POLICY.md"
  ".bda-spec/VERSION"
  ".bda-spec/policies"
  ".bda-spec/checklists"
  ".bda-spec/templates"
  ".bda-spec/workflows"
  ".bda-spec.yml"
  ".bda-spec.local.yml.example"
  ".gitignore"
  "AI-README.md"
  "README.md"
)

# Scripts: install only runtime helpers — exclude bda-spec source-only scripts.
# install.sh / test.sh ใช้กับ bda-spec source repo เอง — user project ไม่ใช้
SCRIPTS_TO_INSTALL=(
  "bda-paths.sh"          # config resolver (used by every command at runtime)
  "upgrade.sh"            # bump bda-spec version
  "upload-evidence.sh"    # GDrive uploader (used by /bda-evidence + /bda-upload)
)

for item in "${SAFE_ITEMS[@]}"; do
  if [[ -e "$TMP_DIR/$item" ]]; then
    # Compute target path — preserve nested paths like ".bda-spec/standards"
    target_path="$TARGET/$item"
    parent_dir="$(dirname "$target_path")"
    if [[ -e "$target_path" && "$MODE" == "brownfield" ]]; then
      warn "  skip existing: $item (ใช้ --yes เพื่อ overwrite)"
      [[ $YES -eq 1 ]] && run "rm -rf '$target_path' && mkdir -p '$parent_dir' && cp -r '$TMP_DIR/$item' '$target_path'"
    else
      run "mkdir -p '$parent_dir' && cp -r '$TMP_DIR/$item' '$target_path'"
      log "  installed: $item"
    fi
  fi
done

# Install scripts whitelist (not whole scripts/ folder)
mkdir -p "$TARGET/scripts"
for s in "${SCRIPTS_TO_INSTALL[@]}"; do
  if [[ -f "$TMP_DIR/scripts/$s" ]]; then
    if [[ -f "$TARGET/scripts/$s" && "$MODE" == "brownfield" && $YES -ne 1 ]]; then
      warn "  skip existing: scripts/$s (use --yes to overwrite)"
    else
      run "cp '$TMP_DIR/scripts/$s' '$TARGET/scripts/$s'"
      log "  installed: scripts/$s"
    fi
  fi
done

# v0.4 migration: remove install.sh + test.sh if they exist from older install (pre-v0.4)
for old in install.sh test.sh; do
  if [[ -f "$TARGET/scripts/$old" ]]; then
    log "  migration (v0.4): removing scripts/$old (no longer installed — bda-spec source-only)"
    [[ $DRY_RUN -eq 0 ]] && rm -f "$TARGET/scripts/$old"
  fi
done

# ---------- v0.4 migrations (run AFTER copy, so new files exist for conflict detection) ----------
# Goal: bring any prior layout to current FLAT v0.4: .bda-spec/{STANDARD.md,policies,…}
# Sources of legacy state:
#   pre-v0.4:           root standards/  +  root VERSION
#   v0.4-intermediate:  .bda-spec/standards/  +  .bda-spec/VERSION (bda-spec own)
#
# Order matters: drop bda-spec-own VERSION BEFORE flattening (so .bda-spec/VERSION slot is free
# for the BDA standard VERSION that gets copied in from template)
#
# Note: by this point, SAFE_ITEMS loop has already copied the new flat files in.

# (1) Migrate pre-v0.4 root standards/ → .bda-spec/ (flat)
LEGACY_ROOT_STD="$TARGET/standards"
if [[ -d "$LEGACY_ROOT_STD" ]]; then
  bak="$TARGET/standards.bak-$(date +%Y%m%d-%H%M%S)"
  log "  migration (v0.4): moving legacy root standards/ → $bak (template already provided fresh copies in .bda-spec/)"
  [[ $DRY_RUN -eq 0 ]] && mv "$LEGACY_ROOT_STD" "$bak"
fi

# (2) Migrate v0.4-intermediate .bda-spec/standards/ → flatten into .bda-spec/
if [[ -d "$TARGET/.bda-spec/standards" ]]; then
  bak="$TARGET/.bda-spec/standards.bak-$(date +%Y%m%d-%H%M%S)"
  log "  migration (v0.4): moving .bda-spec/standards/ → $bak (now flat under .bda-spec/)"
  [[ $DRY_RUN -eq 0 ]] && mv "$TARGET/.bda-spec/standards" "$bak"
fi

# (3) Migrate pre-v0.4 root VERSION → drop (bda-spec own version now in .bda-spec.yml)
if [[ -f "$TARGET/VERSION" ]]; then
  legacy_bda_spec_ver=$(cat "$TARGET/VERSION" 2>/dev/null | tr -d '[:space:]')
  log "  migration (v0.4): removing root VERSION (bda-spec version $legacy_bda_spec_ver moved to .bda-spec.yml bda_spec.version)"
  [[ $DRY_RUN -eq 0 ]] && rm -f "$TARGET/VERSION"
  # Persist into .bda-spec.yml if legacy version was readable
  if [[ -n "$legacy_bda_spec_ver" && -f "$TARGET/.bda-spec.yml" && $DRY_RUN -eq 0 ]]; then
    if ! grep -q "^bda_spec:" "$TARGET/.bda-spec.yml"; then
      printf '\nbda_spec:\n  version: "%s"\n' "$legacy_bda_spec_ver" >> "$TARGET/.bda-spec.yml"
    fi
  fi
fi

# Legacy root templates/: leave alone if user has customizations; only note its presence
if [[ -d "$TARGET/templates" ]]; then
  log "  note: root templates/ พบ — เก็บไว้เป็น override layer (v0.4 ไม่ติดตั้งให้แล้ว แต่ใช้ได้ถ้ามี)"
fi

# ---------- AI agent folders (only selected ones) ----------
# Always-on subagents (vault/quality/security keepers — every project needs these).
# Specialized subagents (backend/frontend/mobile/design/figma/test-runner) ติดตั้งภายหลัง
# ผ่าน /bda-agent enable <name> หรือ /bda-agent suggest หลัง /bda-init detect stack
ALWAYS_ON_AGENTS=(docs verifier security)

# Helper: install only always-on agents from .claude/agents/ (not the whole folder)
install_claude_selective() {
  local src="$TMP_DIR/.claude"
  local dst="$TARGET/.claude"

  run "mkdir -p '$dst/agents' '$dst/commands'"

  # commands — copy all (these are slash commands, not subagent specs)
  if [[ -d "$src/commands" ]]; then
    run "cp -r '$src/commands/.' '$dst/commands/'"
  fi

  # settings.json — copy if exists (do NOT copy settings.local.json — per-machine)
  [[ -f "$src/settings.json" ]] && run "cp '$src/settings.json' '$dst/'"

  # agents — copy ONLY always-on (docs/verifier/security)
  local copied=()
  for a in "${ALWAYS_ON_AGENTS[@]}"; do
    if [[ -f "$src/agents/$a.md" ]]; then
      run "cp '$src/agents/$a.md' '$dst/agents/'"
      copied+=("$a")
    fi
  done
  log "  installed: .claude/ (commands + always-on agents: ${copied[*]:-none})"
  log "  note: specialized agents (backend/frontend/mobile/...) — รัน /bda-agent suggest หลัง /bda-init"
}

log "Installing AI agent shims: $AI_AGENTS"
IFS=',' read -ra AI_LIST <<< "$AI_AGENTS"
INSTALLED_AI=()
for ai in "${AI_LIST[@]}"; do
  folder=$(ai_folder "$ai")

  # Claude: selective copy (commands + always-on agents only)
  if [[ "$ai" == "claude" ]]; then
    if [[ -d "$TMP_DIR/.claude" ]]; then
      if [[ -d "$TARGET/.claude" && "$MODE" == "brownfield" && $YES -ne 1 ]]; then
        warn "  skip existing: .claude/ (use --yes to overwrite)"
      else
        [[ -d "$TARGET/.claude" && $YES -eq 1 ]] && run "rm -rf '$TARGET/.claude'"
        install_claude_selective
        INSTALLED_AI+=("$ai")
      fi
    else
      warn "  template missing: .claude/ (claude) — skipped"
    fi

    # Claude needs CLAUDE.md at root (AI-specific entry point)
    if [[ -e "$TMP_DIR/CLAUDE.md" ]]; then
      if [[ ! -e "$TARGET/CLAUDE.md" || $YES -eq 1 ]]; then
        run "cp '$TMP_DIR/CLAUDE.md' '$TARGET/CLAUDE.md'"
      fi
    fi
    continue
  fi

  # Other AI frontends: copy whole folder (no subagent concept)
  if [[ -e "$TMP_DIR/$folder" ]]; then
    if [[ -e "$TARGET/$folder" && "$MODE" == "brownfield" ]]; then
      warn "  skip existing: $folder (use --yes to overwrite)"
      [[ $YES -eq 1 ]] && {
        run "rm -rf '$TARGET/$folder' && cp -r '$TMP_DIR/$folder' '$TARGET/'"
        INSTALLED_AI+=("$ai")
      }
    else
      run "cp -r '$TMP_DIR/$folder' '$TARGET/'"
      log "  installed: $folder ($ai)"
      INSTALLED_AI+=("$ai")
    fi
  else
    warn "  template missing: $folder ($ai) — skipped"
  fi
done

# Generic prompts/ — install only if at least one of gpt/glm/google selected
if [[ ",$AI_AGENTS," == *",gpt,"* ]] || [[ ",$AI_AGENTS," == *",glm,"* ]] || [[ ",$AI_AGENTS," == *",google,"* ]]; then
  if [[ -d "$TMP_DIR/prompts" && ! -d "$TARGET/prompts" ]]; then
    run "cp -r '$TMP_DIR/prompts' '$TARGET/'"
    log "  installed: prompts/ (general-AI shared)"
  fi
fi

# Persist ai_agents into .bda-spec.yml
if [[ -f "$TARGET/.bda-spec.yml" && $DRY_RUN -eq 0 ]]; then
  if grep -q "^ai_agents:" "$TARGET/.bda-spec.yml" 2>/dev/null; then
    sed -i.bak "s|^ai_agents:.*|ai_agents: [${AI_AGENTS//,/, }]|" "$TARGET/.bda-spec.yml" \
      && rm -f "$TARGET/.bda-spec.yml.bak"
  else
    printf '\n# AI agents enabled in this project (set by installer)\nai_agents: [%s]\n' \
      "$(echo "$AI_AGENTS" | sed 's/,/, /g')" >> "$TARGET/.bda-spec.yml"
  fi
fi

# ---------- Vault location prompt (separate from green/brownfield detection) ----------
# `--here` ≠ brownfield: ผู้ใช้อาจรันใน folder ว่างที่เพิ่งสร้าง หรือใน repo ที่มี code อยู่แล้ว
# ดังนั้นถามตำแหน่ง vault เป็นคำถามแยก ไม่ผูกกับ mode

vault_default="docs/obsidian-vault"
# ถ้า brownfield + docs/ มีเนื้อหาอื่นๆอยู่ → ใช้ docs/obsidian-vault/ (default) — แยกชัด
[[ "$MODE" == "brownfield" && -d "$TARGET/docs" && ! -d "$TARGET/docs/obsidian-vault" ]] && vault_default="docs/obsidian-vault"

if [[ $YES -eq 0 ]]; then
  cat <<EOF

📁 Obsidian vault location
   A) สร้างใหม่ใน docs/obsidian-vault/     (default — แยกจาก docs/ ที่อาจมีเอกสารอื่น)
   B) สร้างใหม่ใน docs/                    (ใช้ docs/ เป็น vault โดยตรง — สำหรับ project เล็ก)
   C) ใช้ vault ที่มีอยู่แล้วใน repo นี้    (ใส่ relative path)
   D) ใช้ external vault (path นอก repo)   (เช่น Obsidian sync folder)

EOF
  vault_choice=$(ask "เลือก (A/B/C/D)" "A")
else
  vault_choice="A"
fi

VAULT_PATH=""
EXTERNAL_VAULT=""

case "$vault_choice" in
  [Aa])
    VAULT_PATH="docs/obsidian-vault"
    ;;
  [Bb])
    VAULT_PATH="docs"
    ;;
  [Cc])
    existing_path=$(ask "Path ของ vault ที่มีอยู่ (relative to repo root)" "docs")
    VAULT_PATH="$existing_path"
    ;;
  [Dd])
    ext_path=$(ask "Absolute path ของ external vault" "")
    [[ -z "$ext_path" ]] && { err "External vault path ห้ามว่าง"; exit 1; }
    EXTERNAL_VAULT="$ext_path"
    VAULT_PATH="external"
    log "External vault: $EXTERNAL_VAULT"
    log "(จะบันทึกใน .bda-spec.local.yml — gitignored)"
    ;;
  *)
    err "ตัวเลือกไม่ถูกต้อง: $vault_choice"
    exit 1
    ;;
esac

# Create vault skeleton (skip if external — assumes user has it set up)
if [[ "$VAULT_PATH" != "external" ]]; then
  full_vault="$TARGET/$VAULT_PATH"
  if [[ ! -d "$full_vault" ]]; then
    log "สร้าง vault ที่ $VAULT_PATH/"
    run "mkdir -p '$full_vault'"
  fi

  # Copy sample only if greenfield + brand-new vault location + sample available
  if [[ "$MODE" == "greenfield" && -d "$TMP_DIR/docs" && -z "$(ls -A "$full_vault" 2>/dev/null)" ]]; then
    log "Greenfield: copy sample Library Book Tracker → $VAULT_PATH/"
    run "cp -r '$TMP_DIR/docs/.' '$full_vault/'"
  else
    # Brownfield or non-empty vault — สร้างแค่ skeleton folders
    for sub in 00-Index 10-PRD 20-Features 30-Roles 40-Functions 50-Phases 60-Flows 70-Reference 75-Checkins 80-ImplementPlan 85-FixLog 90-TestPlan 95-Handoff; do
      run "mkdir -p '$full_vault/$sub'"
    done
  fi
fi

# Save external_vault to .bda-spec.local.yml if chosen
if [[ -n "$EXTERNAL_VAULT" ]]; then
  if [[ ! -f "$TARGET/.bda-spec.local.yml" ]]; then
    if [[ -f "$TMP_DIR/.bda-spec.local.yml.example" ]]; then
      run "cp '$TMP_DIR/.bda-spec.local.yml.example' '$TARGET/.bda-spec.local.yml'"
    else
      run "touch '$TARGET/.bda-spec.local.yml'"
    fi
  fi
  # Set external_vault — use sed for cross-platform compatibility
  if grep -q "external_vault:" "$TARGET/.bda-spec.local.yml" 2>/dev/null; then
    if [[ $DRY_RUN -eq 0 ]]; then
      sed -i.bak "s|external_vault:.*|external_vault: \"$EXTERNAL_VAULT\"|" "$TARGET/.bda-spec.local.yml" && rm "$TARGET/.bda-spec.local.yml.bak" 2>/dev/null || true
    fi
  else
    if [[ $DRY_RUN -eq 0 ]]; then
      printf '\npaths:\n  external_vault: "%s"\n' "$EXTERNAL_VAULT" >> "$TARGET/.bda-spec.local.yml"
    fi
  fi
  log "  → .bda-spec.local.yml saved (gitignored)"
fi

# Persist VAULT_PATH to .bda-spec.yml (replace default vault_path: docs)
if [[ -f "$TARGET/.bda-spec.yml" && "$VAULT_PATH" != "docs" && $DRY_RUN -eq 0 ]]; then
  sed -i.bak "s|^vault_path:.*|vault_path: $VAULT_PATH|" "$TARGET/.bda-spec.yml" && rm "$TARGET/.bda-spec.yml.bak" 2>/dev/null || true
fi

# ---------- .gitignore ----------
if [[ ! -f "$TARGET/.gitignore" ]]; then
  # Copy from template if exists, otherwise create minimal
  if [[ -f "$TMP_DIR/.gitignore" ]]; then
    run "cp '$TMP_DIR/.gitignore' '$TARGET/.gitignore'"
  else
    run "touch '$TARGET/.gitignore'"
  fi
fi
# Ensure bda-spec local-only paths are gitignored
if ! grep -q '\.bda-spec\.local\.yml' "$TARGET/.gitignore" 2>/dev/null; then
  cat >> "$TARGET/.gitignore" <<'EOF'

# bda-spec local config (machine-specific, never commit)
.bda-spec.local.yml
.bda-spec/local/
.bda-spec/cache/
.bda-spec/.last-sync
# Backup files from sync/migration
*.md.new
*.md.bak
EOF
fi

# ---------- copy .bda-spec.local.yml.example (always) + .bda-spec.local.yml (if missing) ----------
# `.example` = checked-in reference template (always present after install)
# `.local.yml` = personal/per-machine config (gitignored) — bda-paths.sh อ่านเป็น override layer
# Both files coexist by design — separation:
#   .bda-spec.yml       → project-wide config (vault_path, subagents baseline, standard version)
#   .bda-spec.local.yml → machine-specific (external_vault, mirror paths, user.*, ai_usage, debug)
if [[ ! -f "$TARGET/.bda-spec.local.yml.example" && -f "$TMP_DIR/.bda-spec.local.yml.example" ]]; then
  run "cp '$TMP_DIR/.bda-spec.local.yml.example' '$TARGET/'"
  log "  installed: .bda-spec.local.yml.example (reference template)"
fi

# Materialize .bda-spec.local.yml from the example so user has a ready-to-edit file
# (skip if user already created one — never overwrite personal config)
if [[ ! -f "$TARGET/.bda-spec.local.yml" && -f "$TMP_DIR/.bda-spec.local.yml.example" && $DRY_RUN -eq 0 ]]; then
  run "cp '$TMP_DIR/.bda-spec.local.yml.example' '$TARGET/.bda-spec.local.yml'"
  log "  installed: .bda-spec.local.yml (personal/per-machine — gitignored, edit เพื่อ override paths)"
fi

# ---------- finalize ----------
log ""
log "✅ bda-spec installed in $MODE mode"
log "   AI agents: ${INSTALLED_AI[*]:-(none)}"
log ""
log "ขั้นต่อไป:"
case "${INSTALLED_AI[0]:-}" in
  claude)
    log "  1. เปิด Claude Code ใน folder นี้"
    log "  2. รัน: /bda-init               (ตั้งค่า vault + detect stack)"
    log "  3. รัน: /bda-agent suggest      (แนะนำ subagent เฉพาะทางตาม stack)"
    log "  4. ไม่รู้จะใช้ command ไหน? → /bda-help"
    ;;
  codex)
    log "  1. รัน Codex CLI ใน folder นี้ (อ่าน codex/AGENTS.md)"
    log "  2. ลองว่า: codex run 'bda-init'"
    log "  3. ไม่รู้จะใช้ command ไหน? → codex run 'bda-help'"
    ;;
  google)
    log "  1. ใช้ gemini CLI: gemini chat --system \"\$(cat gemini/prompts/system.md)\""
    log "  2. ลอง: bda-init"
    ;;
  gpt)
    log "  1. ไปที่ chatgpt.com — paste gpt/prompts/system.md เป็น Custom Instructions"
    log "  2. พิมพ์: bda-init"
    ;;
  glm)
    log "  1. ไปที่ chatglm.cn / z.ai — paste glm/prompts/system.md เป็น system"
    log "  2. พิมพ์: bda-init"
    ;;
  *)
    log "  1. เลือก AI ที่ install แล้วเปิดใน editor ของคุณ"
    log "  2. รัน command bda-init เป็นอันดับแรก"
    ;;
esac
[[ ${#INSTALLED_AI[@]} -gt 1 ]] && log "  (มี ${#INSTALLED_AI[@]} AI frontends ติดตั้ง — ใช้ตัวไหนก็ได้, command ตัวเดียวกัน)"

# Subagent visibility — ผู้ใช้ควรรู้ว่ามี baseline 3 ตัว และจะเพิ่มได้ภายหลัง
if [[ " ${INSTALLED_AI[*]:-} " == *" claude "* ]]; then
  log ""
  log "Subagents (Claude):"
  log "  • Always-on (installed): docs, verifier, security"
  log "  • Specialized (on-demand): backend, frontend, mobile, design, figma, test-runner"
  log "    → /bda-agent suggest  หรือ  /bda-agent enable <name>"
fi

if [[ "$MODE" == "brownfield" ]]; then
  log ""
  log "Brownfield notes:"
  log "  • Stack ที่ตรวจเจอ: $STACK"
  log "  • /bda-init จะถามว่า import README → PRD หรือสร้างใหม่"
  log "  • /bda-init จะเสนอ subagents ตาม stack ($STACK)"
  log "  • ไม่มีการแก้โค้ดเดิมโดย installer — ทุก vault doc สร้างใน docs/ เท่านั้น"
fi

log ""
log "Config files (อ่านโดย scripts/bda-paths.sh — precedence: local > shared > default):"
log "  Shared:   $TARGET/.bda-spec.yml            (git-tracked, ทีมเดียวกัน)"
log "            └─ project, vault_path, standard, subagents baseline, guardrails"
log "  Personal: $TARGET/.bda-spec.local.yml      (gitignored, ของเครื่องคุณเอง)"
log "            └─ paths.external_vault, daily_log_mirror, user.*, ai_usage, debug"
log "  Template: $TARGET/.bda-spec.local.yml.example  (reference สำหรับ key ทั้งหมดที่ override ได้)"
log ""
log "Other:"
log "  Docs:           $TARGET/CLAUDE.md"
log "  Vault:          $TARGET/$VAULT_PATH/"
[[ -n "$EXTERNAL_VAULT" ]] && log "  External vault: $EXTERNAL_VAULT (recorded in .bda-spec.local.yml)"
log "  Design preview: $TARGET/$VAULT_PATH/70-Reference/DesignSystem/preview.html (เปิดด้วย browser)"
