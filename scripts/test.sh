#!/usr/bin/env bash
# bda-spec test — smoke tests to verify the system works correctly
#
# Usage:
#   bash scripts/test.sh              # run all tests
#   bash scripts/test.sh --verbose    # show details for each test
#   bash scripts/test.sh --filter <kw> # only tests matching keyword
#
# Exit code: 0 if all pass, 1 if any fail

set -uo pipefail   # not -e because we want to count failures
# allow grep -q to exit fast without SIGPIPE breaking upstream cmd
trap '' SIGPIPE 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

VERBOSE=0
FILTER=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    -v|--verbose) VERBOSE=1; shift ;;
    --filter)     FILTER="$2"; shift 2 ;;
    -h|--help)
      grep '^#' "$0" | head -10; exit 0 ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
done

# ── tally ──
declare -i PASS=0 FAIL=0 SKIP=0
FAILED_NAMES=()

# ── colors ──
c_bold='\033[1m'; c_reset='\033[0m'
c_green='\033[32m'; c_red='\033[31m'; c_yellow='\033[33m'; c_dim='\033[2m'

# ── runner ──
# Note: runs each test in a subshell with pipefail DISABLED so that grep -q
# (which closes the pipe fast and causes SIGPIPE 141 in the producer) doesn't
# trip the test as failed. We only care about grep's own exit code.
run() {
  local name="$1" cmd="$2"
  if [ -n "$FILTER" ] && [[ "$name" != *"$FILTER"* ]]; then
    SKIP+=1; return
  fi
  if ( set +o pipefail 2>/dev/null; eval "$cmd" ) >/tmp/bda-test-output.$$ 2>&1; then
    PASS+=1
    printf "  ${c_green}✓${c_reset} %s\n" "$name"
    [ "$VERBOSE" -eq 1 ] && sed 's/^/      /' /tmp/bda-test-output.$$
  else
    FAIL+=1
    FAILED_NAMES+=("$name")
    printf "  ${c_red}✗${c_reset} %s\n" "$name"
    sed 's/^/      /' /tmp/bda-test-output.$$ | head -5
  fi
  rm -f /tmp/bda-test-output.$$
}

# ════════════════════════════════════════════════════════════════════════════
# Test 1: Core files exist
# ════════════════════════════════════════════════════════════════════════════
printf "${c_bold}Section 1 — Core files${c_reset}\n"
run "VERSION exists"               '[ -f .bda-spec/VERSION ]'
run ".bda-spec.yml exists"         '[ -f .bda-spec.yml ]'
run ".bda-spec.local.yml.example"  '[ -f .bda-spec.local.yml.example ]'
run ".gitignore exists"            '[ -f .gitignore ]'
run "CLAUDE.md exists"             '[ -f CLAUDE.md ]'
run "AI-README.md exists"          '[ -f AI-README.md ]'
run "README.md exists"             '[ -f README.md ]'

# ════════════════════════════════════════════════════════════════════════════
# Test 2: Folder structure
# ════════════════════════════════════════════════════════════════════════════
printf "\n${c_bold}Section 2 — Folder structure${c_reset}\n"
for d in commands .claude/commands .claude/agents .bda-spec/policies .bda-spec/checklists .bda-spec/templates scripts bin codex/agents docs/obsidian-vault/00-Index docs/obsidian-vault/10-PRD docs/obsidian-vault/20-Features docs/obsidian-vault/30-Roles docs/obsidian-vault/40-Functions docs/obsidian-vault/50-Phases docs/obsidian-vault/60-Flows docs/obsidian-vault/70-Reference docs/obsidian-vault/75-Checkins docs/obsidian-vault/80-ImplementPlan docs/obsidian-vault/85-FixLog docs/obsidian-vault/90-TestPlan docs/obsidian-vault/95-Handoff; do
  run "dir $d"                     "[ -d $d ]"
done
# v0.4: root `templates/` is OPTIONAL — only created when project customizes templates
# Sanity check just verifies it's a directory IF it exists (don't fail if absent)
[ -e templates ] && [ ! -d templates ] && echo "FAIL: templates exists but is not a directory"

# ════════════════════════════════════════════════════════════════════════════
# Test 3: Commands — source + shim integrity
# ════════════════════════════════════════════════════════════════════════════
printf "\n${c_bold}Section 3 — Commands${c_reset}\n"
for cmd_file in commands/bda-*.md; do
  cmd_name=$(basename "$cmd_file" .md)
  shim=".claude/commands/${cmd_name}.md"
  run "shim exists: $cmd_name"     "[ -f $shim ]"
  run "shim → source: $cmd_name"   "grep -q '@commands/${cmd_name}.md' $shim"
  run "frontmatter: $cmd_name"     "head -1 $cmd_file | grep -q '^---$'"
done

# ════════════════════════════════════════════════════════════════════════════
# Test 4: Commands contain required sections
# ════════════════════════════════════════════════════════════════════════════
printf "\n${c_bold}Section 4 — Command structure${c_reset}\n"
for cmd_file in commands/bda-*.md; do
  cmd_name=$(basename "$cmd_file" .md)
  # 5 mandatory output sections + ห้าม section
  run "5-section output: $cmd_name"  "grep -q '5 หัวข้อบังคับ\|Output (' $cmd_file"
  run "ห้าม section: $cmd_name"        "grep -q '^## ห้าม' $cmd_file"
done

# ════════════════════════════════════════════════════════════════════════════
# Test 5: Subagents
# ════════════════════════════════════════════════════════════════════════════
printf "\n${c_bold}Section 5 — Subagents${c_reset}\n"
for agent_file in .claude/agents/*.md; do
  agent_name=$(basename "$agent_file" .md)
  run "frontmatter: $agent_name"   "head -1 $agent_file | grep -q '^---$'"
  run "name field: $agent_name"    "grep -q '^name:' $agent_file"
  run "§5 Gates: $agent_name"      "grep -qE '^## ?§?5\.' $agent_file"
done

# ════════════════════════════════════════════════════════════════════════════
# Test 6: Standards
# ════════════════════════════════════════════════════════════════════════════
printf "\n${c_bold}Section 6 — Standards${c_reset}\n"
run "STANDARD.md banner"           "head -5 .bda-spec/STANDARD.md | grep -q 'READ-ONLY'"
run "VERSION file"                 "[ -s .bda-spec/VERSION ]"
for poli in .bda-spec/policies/*.md; do
  pn=$(basename "$poli" .md)
  run "banner: policies/$pn"       "head -5 $poli | grep -q 'READ-ONLY'"
done
for tpl in .bda-spec/templates/*.md; do
  tn=$(basename "$tpl" .md)
  run "banner: templates/$tn"      "head -5 $tpl | grep -q 'READ-ONLY'"
done

# ════════════════════════════════════════════════════════════════════════════
# Test 7: Scripts syntax
# ════════════════════════════════════════════════════════════════════════════
printf "\n${c_bold}Section 7 — Script syntax${c_reset}\n"
for s in scripts/*.sh bin/bda-spec; do
  [ -f "$s" ] || continue
  run "bash syntax: $s"            "bash -n $s"
  run "executable: $s"             "[ -x $s ]"
done

# ════════════════════════════════════════════════════════════════════════════
# Test 8: Multi-AI shims
# ════════════════════════════════════════════════════════════════════════════
printf "\n${c_bold}Section 8 — Multi-AI integration${c_reset}\n"
# Claude (always)
run "Claude: .claude/ exists"      "[ -d .claude ]"
run "Claude: CLAUDE.md"            "[ -f CLAUDE.md ]"
# Codex
run "Codex: AGENTS.md"             "[ -f codex/AGENTS.md ]"
run "Codex: maps bda-help"         "grep -q 'bda-help' codex/AGENTS.md"
run "Codex: maps bda-clarify"      "grep -q 'bda-clarify' codex/AGENTS.md"
run "Codex: maps bda-reverse-engineer" "grep -q 'bda-reverse-engineer' codex/AGENTS.md"
# Google Gemini
run "Google: gemini/prompts/"      "[ -d gemini/prompts ]"
# GPT
run "GPT: gpt/prompts/system.md"   "[ -f gpt/prompts/system.md ]"
run "GPT: gpt/prompts/router.md"   "[ -f gpt/prompts/router.md ]"
# GLM
run "GLM: glm/prompts/system.md"   "[ -f glm/prompts/system.md ]"
run "GLM: glm/prompts/router.md"   "[ -f glm/prompts/router.md ]"
# Generic
run "Generic: prompts/general-ai/" "[ -d prompts/general-ai ]"
# Installer AI picker
run "install.sh --ai flag"         "grep -q 'AI_AGENTS' scripts/install.sh"
run "install.sh ai_validate"       "grep -q 'ai_validate' scripts/install.sh"

# ════════════════════════════════════════════════════════════════════════════
# Test 9: bda-paths.sh works
# ════════════════════════════════════════════════════════════════════════════
printf "\n${c_bold}Section 9 — bda-paths.sh${c_reset}\n"
if [ -x scripts/bda-paths.sh ]; then
  run "bda-paths --shell"          'bash scripts/bda-paths.sh --shell | grep -q VAULT_ABS='
  run "bda-paths --json"           'bash scripts/bda-paths.sh --json | grep -q "\"vault\""'
  run "bda-paths --check"          'bash scripts/bda-paths.sh --check PROJECT_NAME >/dev/null'
fi

# ════════════════════════════════════════════════════════════════════════════
# Test 10: Doctor runs
# ════════════════════════════════════════════════════════════════════════════
printf "\n${c_bold}Section 10 — Doctor${c_reset}\n"
run "bin/bda-spec doctor runs"     'bash bin/bda-spec doctor 2>&1 | grep -q "commands"'

# ════════════════════════════════════════════════════════════════════════════
# Test 11: Sample vault references valid
# ════════════════════════════════════════════════════════════════════════════
printf "\n${c_bold}Section 11 — Sample vault (Library Book Tracker)${c_reset}\n"
run "IMPLEMENTATION-STATUS"        '[ -s docs/obsidian-vault/00-Index/IMPLEMENTATION-STATUS.md ]'
run "PRD file"                     'ls docs/obsidian-vault/10-PRD/PRD-*.md >/dev/null 2>&1'
run "Feature files"                'ls docs/obsidian-vault/20-Features/FEAT-*.md >/dev/null 2>&1'
run "Function files"               'find docs/obsidian-vault/40-Functions -name "FN-*.md" | head -1 | xargs test -f'
run "DesignSystem"                 '[ -d docs/obsidian-vault/70-Reference/DesignSystem ]'
run "DS preview.html"              '[ -f docs/obsidian-vault/70-Reference/DesignSystem/preview.html ]'

# ════════════════════════════════════════════════════════════════════════════
# Test 12: Template lookup chain integrity
# ════════════════════════════════════════════════════════════════════════════
printf "\n${c_bold}Section 12 — Template lookup chain${c_reset}\n"
for tpl in prd srs tech-spec adr feature function role flow phase plan fix-log checkin handoff evidence-manifest; do
  # at least one of: project / standard (local is optional)
  run "template available: $tpl"    "[ -f templates/${tpl}.md ] || [ -f .bda-spec/templates/${tpl}.md ]"
done

# ════════════════════════════════════════════════════════════════════════════
# Summary
# ════════════════════════════════════════════════════════════════════════════
TOTAL=$((PASS + FAIL))
echo ""
printf "${c_bold}─────────── Summary ───────────${c_reset}\n"
printf "  ${c_green}Passed:${c_reset}  %d\n" "$PASS"
[ "$FAIL" -gt 0 ] && printf "  ${c_red}Failed:${c_reset}  %d\n" "$FAIL"
[ "$SKIP" -gt 0 ] && printf "  ${c_yellow}Skipped:${c_reset} %d (filter)\n" "$SKIP"
printf "  Total run: %d\n\n" "$TOTAL"

if [ "$FAIL" -gt 0 ]; then
  printf "${c_red}${c_bold}FAILED tests:${c_reset}\n"
  for n in "${FAILED_NAMES[@]}"; do echo "  • $n"; done
  echo ""
  exit 1
fi

printf "${c_green}${c_bold}All tests passed${c_reset}\n"
exit 0
