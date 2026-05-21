---
description: Security pre-flight — scan secrets, PII, screenshot masking, public-repo and prod guardrails
model: claude-sonnet-4-6
---

# bda-secure — Security Pre-flight

ตรวจ secrets, PII, public-repo guardrails, screenshot masking ก่อน commit/handoff

## Trigger

```
/bda-secure                    # full scan
/bda-secure secrets            # scan secrets only
/bda-secure pii                # scan PII only
/bda-secure evidence           # check evidence masking
/bda-secure --since <ref>      # scan diff since ref
```

## Phase 1 — Secret scan

```bash
# Common secret patterns (extend as needed)
patterns=(
  "AKIA[0-9A-Z]{16}"                           # AWS access key
  "-----BEGIN [A-Z ]+ PRIVATE KEY-----"        # RSA/EC private keys
  "ghp_[A-Za-z0-9]{36,}"                       # GitHub PAT
  "ghs_[A-Za-z0-9]{36,}"                       # GitHub server token
  "sk-[A-Za-z0-9]{32,}"                        # Generic API key (Anthropic/OpenAI)
  "xox[bpoa]-[0-9a-zA-Z-]{10,}"                # Slack token
  "AIza[0-9A-Za-z-_]{35}"                      # Google API key
  "[A-Za-z0-9_]*(password|secret|api_key|token)[A-Za-z0-9_]*\\s*=\\s*['\"][^'\"]{8,}['\"]"
)

# Scan changed files (since ref or staged)
target_files=$(git diff --name-only --diff-filter=ACMR HEAD 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null)

for f in $target_files; do
  for p in "${patterns[@]}"; do
    grep -HnE "$p" "$f" 2>/dev/null
  done
done
```

Report findings → BLOCK commit ถ้าเจอ (ระบุ file:line)

## Phase 2 — PII scan ใน docs/

```bash
# Thai-specific PII patterns
patterns=(
  "[0-9]{1}-[0-9]{4}-[0-9]{5}-[0-9]{2}-[0-9]{1}"   # Thai citizen ID
  "[0-9]{10}"                                       # 10-digit phone (refine)
  "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}" # Email
  "(HN|VN|AN)[0-9]{6,}"                             # Hospital numbers
)

# Scan vault evidence + docs
find docs/90-TestPlan/evidence docs/85-FixLog docs/95-Handoff -type f \
  \( -name "*.md" -o -name "*.json" -o -name "*.log" \) 2>/dev/null
```

Report PII findings → BLOCK ถ้าไม่ได้ mask + ไม่มี `pii_masked: true` ใน manifest

## Phase 3 — Screenshot masking check

ตรวจ `docs/90-TestPlan/evidence/**/*.png`:
- ทุก image ต้องมี manifest entry
- ถ้า `contains_pii: true` ต้องมี `masking_applied: true`
- ถ้า `safe_to_share: false` → flag ห้าม push

```bash
find docs/90-TestPlan/evidence -name "manifest.json" -exec cat {} \;
```

## Phase 4 — Public-repo guardrails

ถ้า repo เป็น public (ตรวจจาก `.git/config` remote URL):
- Block ถ้ามี `confidential` หรือ `internal-only` tag ใน vault docs
- Block ถ้ามี `BDA-internal` หรือ customer name ที่ทำ NDA
- Block ถ้ามี real customer email/contact

```bash
remote=$(git config --get remote.origin.url 2>/dev/null)
echo "Remote: $remote"

# Check if public (heuristic — adjust for org)
if grep -lE "tags:.*\b(confidential|internal-only|nda)\b" docs/ -r; then
  echo "BLOCK: confidential content"
fi
```

## Phase 5 — Dependency vulnerability quick-check

```bash
# Quick scan (does not replace full SCA tool)
test -f package-lock.json && npm audit --audit-level=high 2>/dev/null | head -30
test -f requirements.txt && pip list --outdated 2>/dev/null | head -20
test -f Cargo.lock && cargo audit 2>/dev/null
```

ไม่ block แต่ report high/critical vulnerabilities

## Phase 6 — Production-write guardrails

ตรวจ:
- มี `.env.production` ที่ committed?
- มี config file ที่ point ไป prod database?
- มี script ที่ deploy ขึ้น prod โดยไม่มี confirm step?

```bash
git ls-files | grep -E '\.env\.prod|production\.config|deploy-prod' | head -10
```

Report ถ้าเจอ → require explicit user confirm

## Phase 7 — Report + decision

แสดง report:
```
Security pre-flight
===================
✅ Secret scan: clean (5 files scanned)
✅ PII scan: clean (12 docs scanned)
🟡 Screenshot masking: 2 screenshots missing PII flag
   - docs/90-TestPlan/evidence/2026-05-20-search/TC-001-03-results.png
   - docs/90-TestPlan/evidence/2026-05-20-search/TC-002-01-detail.png
✅ Public-repo guardrails: ok
🟡 npm audit: 3 high-severity (express@4.17 — upgrade to 4.19)
✅ Production guardrails: ok

Verdict: REVIEW NEEDED (2 yellow)
```

| Verdict | Action |
|---|---|
| ✅ ALL GREEN | OK to commit/handoff |
| 🟡 REVIEW NEEDED | แก้/justify ก่อน proceed |
| ❌ BLOCKED | ห้าม commit — ต้องแก้ก่อน |

## Phase 8 — Log checkin

```markdown
- HH:MM — [type/security] /bda-secure — 0 secrets, 0 PII, 2 unmasked screenshots — REVIEW
```

## Output (5 หัวข้อบังคับ)

1. **BDA Standard files used** — `standards/policies/no-fake-evidence.md`, `standards/policies/source-of-truth.md`
2. **Pipeline trace** — Understand (read .git/config + .bda-spec.yml) → Plan (Phase 1-6 scope) → Execute (scans) → Verify (re-check after fix) → Handoff (report)
3. **Commands run** — whole list ของ grep/find/audit commands
4. **Verification / Evidence** — scan output + counts ของ findings
5. **Limitations / Risks / Next steps** — secret patterns ไม่ครอบคลุม custom secrets, PII regex อาจ false-positive

## ห้าม

- ห้ามรัน scan โดย skip files (transparent — list ทุก file ที่ scan)
- ห้าม fix secrets เอง — แจ้ง user ให้ revoke + rotate
- ห้าม commit ถ้า BLOCKED — ต้องผ่าน manual override + log reason
