---
description: Daily executive check-in — morning/midday/note/end in one file per day
model: claude-sonnet-4-6
---

# bda-checkin — Daily Check-in (1 file/วัน)

รวม morning + midday + notes + end-of-day ใน **1 ไฟล์ต่อวัน** ที่ `docs/75-Checkins/<YYYY-MM-DD>.md`

Auto-detect ช่วงเวลา + section ที่ยังว่าง → ถามว่าจะ update section ไหน

## Trigger (Claude Code)

```
/bda-checkin                 # auto-detect ช่วง
/bda-checkin morning         # บังคับ section
/bda-checkin midday
/bda-checkin note            # quick capture (meeting, test, review)
/bda-checkin end             # end-of-day executive log
/bda-checkin show            # แสดง checkin ของวันนี้
```

## Phase 0 — Resolve config + detect ช่วงเวลา

```bash
TODAY=$(date +%Y-%m-%d)
NOW_HOUR=$(date +%H)

# 1. Resolve vault location — local.yml override > .bda-spec.yml
VAULT_PATH=$(grep -E '^vault_path:' .bda-spec.yml | awk '{print $2}' | tr -d '"')
if [ -f .bda-spec.local.yml ]; then
  EXT_VAULT=$(grep -A 5 'paths:' .bda-spec.local.yml | grep -E 'external_vault:' | awk -F'"' '{print $2}')
  [ -n "$EXT_VAULT" ] && VAULT_PATH="$EXT_VAULT"
fi
[ -z "$VAULT_PATH" ] && VAULT_PATH="docs"

CHECKIN="${VAULT_PATH}/75-Checkins/${TODAY}.md"

# 2. Resolve daily_log_mirror (personal path สำหรับ executive log)
DAILY_MIRROR=""
if [ -f .bda-spec.local.yml ]; then
  DAILY_MIRROR=$(grep -A 5 'paths:' .bda-spec.local.yml | grep -E 'daily_log_mirror:' | awk -F'"' '{print $2}')
fi

# 3. Time-of-day suggestion
if   [ "$NOW_HOUR" -lt 11 ]; then SUGGEST=morning
elif [ "$NOW_HOUR" -lt 15 ]; then SUGGEST=midday
elif [ "$NOW_HOUR" -lt 18 ]; then SUGGEST=midday-or-note
else SUGGEST=end
fi

test -f "$CHECKIN" && echo "EXISTS" || echo "FRESH"
```

ถ้า `$ARGUMENTS` ว่าง → ใช้ `$SUGGEST` แต่ถามยืนยัน

> **หมายเหตุ**: ทุก path อ้างจาก `$VAULT_PATH` ที่ resolve จาก config — ห้าม hardcode `docs/`
>
> **Daily-log mirror**: ถ้า user set `paths.daily_log_mirror` ใน `.bda-spec.local.yml`
> หลัง update section "End-of-day" → คัดลอกไฟล์ไป mirror path ด้วย (executive ที่ใช้ central vault จะเห็น)

## Phase 1 — สร้างไฟล์ (ถ้ายังไม่มี)

ใช้ template — `templates/checkin.md` หรือ `standards/templates/checkin.md`

Frontmatter:
```yaml
---
tags: [type/checkin]
date: YYYY-MM-DD
project: <slug from .bda-spec.yml>
status: open                # open | closed
ai_used: false              # set true ถ้าใช้ AI วันนี้
ai_tokens_input: 0
ai_tokens_output: 0
ai_cost_usd: 0
---
```

โครงไฟล์:
```markdown
# Check-in <YYYY-MM-DD>

## 1. Morning — Goals & Plan
<empty until /bda-checkin morning>

## 2. Midday — Progress
<empty until /bda-checkin midday>

## 3. Notes (timestamped)
<empty — appended by /bda-checkin note ตลอดวัน>

## 4. End-of-day — Executive Summary
<empty until /bda-checkin end>

## 5. Carry-over to Tomorrow
<filled from /bda-checkin end>
```

## Phase 2 — Morning section

ก่อน fill — auto-gather context:

### 2.1 อ่าน checkin เมื่อวาน (ถ้ามี)
```bash
YESTERDAY=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d "yesterday" +%Y-%m-%d)
test -f "docs/75-Checkins/${YESTERDAY}.md" && \
  grep -A 10 "## 5. Carry-over" "docs/75-Checkins/${YESTERDAY}.md"
```

### 2.2 สแกน plan/fix ที่ in-progress
```bash
grep -l "^status: in-progress\|^status: planning\|^status: approved" \
  docs/80-ImplementPlan/*.md docs/85-FixLog/*.md 2>/dev/null
```

แสดง list → user เลือกว่าจะปิดวันนี้ตัวไหน

### 2.3 ถามวันนี้ (batch 3 คำถาม)
1. **Top 3 outcomes** ที่อยากได้สิ้นวัน
2. **Blockers / dependencies** ที่อาจขัด
3. **Hard meetings / deadlines** วันนี้

### 2.4 Fill section 1
```markdown
## 1. Morning — Goals & Plan
**Time:** HH:MM
**Top 3 outcomes:**
1. <outcome 1>
2. <outcome 2>
3. <outcome 3>

**Blockers anticipated:**
- <blocker> → mitigation: <plan>

**Meetings/deadlines:**
- HH:MM — <event>

**Plans/fixes carried over (จาก in-progress):**
- [[80-ImplementPlan/<slug>]]
- [[85-FixLog/<slug>]]
```

## Phase 3 — Midday section

### 3.1 อ่าน morning ของวันนี้ + git activity ตั้งแต่เช้า
```bash
MORNING_TIME=$(grep "**Time:**" "$CHECKIN" | head -1 | awk '{print $NF}')
git log --since="$(date +%Y-%m-%d) $MORNING_TIME" --pretty=format:'%h %ai %s' | head -20
```

### 3.2 ถาม batch 3 คำถาม
1. Outcomes ที่ done แล้ว / partial / not started
2. New blockers หรือ direction change?
3. Adjustment สำหรับครึ่งหลัง?

### 3.3 Fill section 2
```markdown
## 2. Midday — Progress
**Time:** HH:MM
**Done (since morning):**
- ✅ <outcome 1> — evidence: <plan-slug or commit>
- 🟡 <outcome 2> — 60% — blocker: <reason>
- ⬜ <outcome 3> — not started — deferred to tomorrow

**Git activity:** N commits (api: M, web: K, app: L)

**Direction change:** <none | description>

**Afternoon focus:**
- <revised priority>
```

## Phase 4 — Note (quick capture, multiple ต่อวัน)

Type keywords:
| Input | Type | ตัวอย่าง |
|---|---|---|
| `meeting` | meeting | "ประชุม UAT กับ stakeholder" |
| `test` | manual-test | "ทดสอบ login flow บน mobile" |
| `review` | review | "ตรวจ PR #45" |
| `doc` | doc | "เขียน test plan ฟีเจอร์ใหม่" |
| `call` | call | "คุยกับ vendor" |
| `other` | other | "รออนุมัติ" |

ถ้า user พิมพ์ `/bda-checkin note` ว่าง → ถาม type + brief + duration + outcome

Append:
```markdown
## 3. Notes (timestamped)
- **HH:MM** [meeting] ประชุม UAT กับ stakeholder — 45 min — outcome: agreed on Phase 2 scope
- **HH:MM** [manual-test] login flow บน mobile — pass, screenshot: docs/90-TestPlan/evidence/...
- **HH:MM** [review] PR #45 — approved with 2 comments
```

หลายรายการในวันเดียวได้ ไม่ overwrite

## Phase 5 — End-of-day (Executive Summary)

### 5.1 รวบรวมข้อมูล 6 แหล่ง (data-gathering — parallel)

> **อิงจาก thai-cleft daily-log Step 1a-1f** — ทุกแหล่งเป็น "ของจริง" ที่เกิดวันนั้น ไม่ใช่การคิดเอง

#### 5.1a — Git commits + repo URL/branch (ทุก submodule)

```bash
# Main repo
git log --since="$TODAY 00:00" --author="$USER_NAME" \
  --stat --pretty=format:'%h|%ai|%s'
git remote get-url origin
git rev-parse --abbrev-ref HEAD

# Submodules (จาก .bda-spec.yml `submodules:` หรือ .gitmodules)
for sub in $(yq '.submodules[].path' .bda-spec.yml); do
  git -C "$sub" log --since="$TODAY 00:00" --author="$USER_NAME" \
    --stat --pretty=format:'%h|%ai|%s'
  git -C "$sub" remote get-url origin
  git -C "$sub" rev-parse --abbrev-ref HEAD
done
```

→ ใช้กรอก frontmatter `repo`, `branch`, `submodules`, `commits_count`

#### 5.1b — Vault files ของวันนี้ (Standup / Plan / Fix-log / Notes)

```bash
TODAY=$(date +%Y-%m-%d)

# Today's checkin file (มี morning/midday/notes รวมอยู่แล้ว — 1 file/วัน)
ls "$VAULT_ABS/75-Checkins/${TODAY}.md" 2>/dev/null

# Plans + fix-logs ที่เริ่ม/แก้วันนี้
find "$VAULT_ABS/80-ImplementPlan" -maxdepth 1 -name "${TODAY}-*.md"
find "$VAULT_ABS/85-FixLog" -maxdepth 1 -name "${TODAY}-*.md"

# Plans ที่ status เปลี่ยน (completed/in-progress/blocked) วันนี้
grep -l "^completed_at: ${TODAY}\|^updated_at: ${TODAY}" \
  "$VAULT_ABS/80-ImplementPlan"/*.md "$VAULT_ABS/85-FixLog"/*.md
```

**Extract จากแต่ละไฟล์:**
- `75-Checkins/${TODAY}.md` → **Morning Section 2 "Today's Goal"** + Section 0 timestamped notes (meeting/test/review)
- `Plan/Fix file frontmatter:**
  - `task:` / `title:` / H1 → ชื่อ Done item
  - `status:` → done / in-progress / blocked / regressed / wont-fix / cancelled / deferred
  - `task_type:` → Focus / Adhoc / Support (default Focus)
  - `priority:` → P0/P1/P2 (default P1; fix `severity: P0` → `P0`)
  - `requested_by:` → stakeholder (default "Self / team routine")
  - `blocker:` → text (default "none")
  - `next_action:` → จาก plan unchecked `[ ]` ตัวแรก, หรือ "none" ถ้า done
- `- [ ]` unchecked items → suggest "In Progress" section
- `## AI Usage` section ใน plan/fix → merge เข้า frontmatter (rule: usage_level เลือกสูงสุด, used_for merge เข้า ai_usage_notes)

#### 5.1c — Evidence manifests (test/screenshot/log)

```bash
# Find evidence manifests touched today
find "$VAULT_ABS"/{20-Features,80-ImplementPlan,85-FixLog,90-TestPlan} \
  -name "evidence-manifest.md" -newer "/tmp/midnight-marker" 2>/dev/null

# Or with explicit date check in manifest body
grep -l "${TODAY}" $(find "$VAULT_ABS"/{20-Features,80-ImplementPlan,85-FixLog,90-TestPlan} \
  -name "evidence-manifest.md" 2>/dev/null)
```

**Build `evidence_map` keyed by plan/fix slug:**
- `commits[]` (matched by slug ใน commit message หรือ branch name)
- `screenshots[]` — `{ tc_id, type, context, result, file_path, gdrive_link }`
- `build_result` / `test_result` / `ui_test_result` (จาก BUILD-INFO ถ้ามี)

ใช้ map นี้สร้าง **Section 3 Done items**: 1 item = 1 plan/fix slug (รวม commits + evidence ภายใต้ slug เดียว)
ถ้า commit ไม่ match slug ใด → 1 item/commit (Evidence: hash, ไม่มี Verification)

#### 5.1d — No-Fake Gate (5 cross-checks — บังคับ)

รันเงียบ ผลใส่ใน Section 13 "No-Fake confirmed":

1. **Goal coverage** — ทุก goal จาก morning match commit/plan/fix?
2. **Status vs evidence** — plan `status: done` + fix `status: fixed` มี evidence-manifest entries?
3. **Required artifacts** — plan ที่ done ต้องมี BUILD-INFO; fix ที่มี UI change ต้องมี before+after screenshots; test plan ต้องมี MANIFEST
4. **Commit hashes verifiable** — `git -C <repo> cat-file -e <hash>` ผ่านทุก hash ที่ใส่
5. **Screenshots referenced exist** — `test -f` ทุก path ที่ evidence อ้าง

```
🔍 No-Fake Gate
✅ Check 1 (Goal coverage): 3/3 mapped
⚠️ Check 4 (Commit hashes): 1 violation — abc1234 not in git
Total: 14/15 pass · 1 warning
```

→ ใส่ใน frontmatter `validation_status:` + Section 13 reason

#### 5.1e — Remaining Work scan (50-Phases/) — สำหรับ Forecast เท่านั้น

```python
import re, os
PHASE_DIR = f"{VAULT_ABS}/50-Phases"
phases = []
grand_d = grand_t = 0
for fname in sorted(os.listdir(PHASE_DIR)):
    if not fname.endswith('.md') or fname.startswith('_'): continue
    txt = open(f'{PHASE_DIR}/{fname}', encoding='utf-8').read()
    done = len(re.findall(r'^\s*-\s*\[x\]', txt, re.M|re.I))
    todos = re.findall(r'^\s*-\s*\[ \]', txt, re.M)
    grand_d += done; grand_t += done + len(todos)
print(f"Grand: {grand_d}/{grand_t} ({100*grand_d/grand_t:.0f}%)")
```

> ⚠️ **ห้าม dump remaining work list ลง checkin** — ใช้ผลแค่กรอก **Section 10 Forecast** (Current Stage, Remaining Work Type, Expected Next Action Date, Available Capacity)

#### 5.1f — AI token usage (จาก `ccusage daily` — 2 calls)

```bash
TODAY_COMPACT=$(date +%Y%m%d)
PROJECT_KEY=$(pwd | tr '/' '-')   # หรือ slug from .bda-spec.yml

# Call A — project-filtered (frontmatter ai_*_tokens)
ccusage daily --project="$PROJECT_KEY" \
  --since "$TODAY_COMPACT" --until "$TODAY_COMPACT" --json --breakdown

# Call B — all projects (daily_ai_total_tokens)
ccusage daily --since "$TODAY_COMPACT" --until "$TODAY_COMPACT" --json
```

**Field mapping (ลง frontmatter):**
- `ai_input_tokens` = Call A `.inputTokens`
- `ai_output_tokens` = Call A `.outputTokens`
- `ai_cache_read_tokens` = Call A `.cacheReadTokens`
- `ai_cache_write_tokens` = Call A `.cacheCreationTokens`
- `ai_total_tokens` = Call A `.totalTokens`
- `ai_model` = Call A `.modelsUsed[]` joined ", " (override plan/fix file values)
- `cost_usd` = Call A `.totalCost`
- `daily_ai_total_tokens` = Call B `.totalTokens` (all projects total)

**Error handling:**
- Call fail → field = `"unknown"`, Section 8 line = `_ccusage failed_`
- No entry → all = `0`, Section 8 line = `_no usage data_`
- ccusage ไม่ติดตั้ง → ใช้ self-report (ถาม user ใน 5.2)

#### 5.1g — Evidence GDrive links (จาก /bda-upload)

```bash
# Scan manifests สำหรับ entries ที่มี gdrive_link และ uploaded_at = today
grep -E "\|.*${TODAY}.*\|.*https://drive\.google\.com" \
  $(find "$VAULT_ABS" -name "evidence-manifest.md" 2>/dev/null)
```

→ ใส่ Section 9 "Evidence / Links Collected" + Section 6 per-plan TC tables (link column)

### 5.2 ถาม batch
1. AI usage วันนี้: ใช้ AI ตัวไหน? token in/out / cost (ถ้ารู้)
2. Confidence ของ outcomes (High/Med/Low + reason)
3. Carry-over tasks ไปพรุ่งนี้

### 5.3 Fill section 4 + 5

```markdown
## 4. End-of-day — Executive Summary
**Time:** HH:MM

**Top outcomes today:**
1. ✅ <outcome> — evidence: <link>
2. ✅ <outcome> — evidence: <link>
3. 🟡 <outcome> — partial, status: <reason>

**Work done with evidence:**
| Task | Result | Evidence | Status |
|---|---|---|---|
| <task> | <result> | <commit/plan/doc> | done |
| <task> | <result> | <link> | partial |

**Blockers / help needed:**
- <blocker> — for: <name/team>

**Learnings / notes:**
- <insight>

**AI usage today:**
- Tool: Claude Sonnet 4.6 (Claude Code)
- Input tokens: 145,000
- Output tokens: 28,500
- Cost: $X.XX
- Evidence: <session links or "self-tracked">

(ถ้าไม่ได้ใช้ AI ระบุ: "ไม่ได้ใช้ AI วันนี้")

**Tomorrow focus:**
1. <focus 1>
2. <focus 2>
3. <focus 3>

**Confidence:** High / Med / Low — <reason>

## 5. Carry-over to Tomorrow
- [[80-ImplementPlan/<slug>]] — status: in-progress
- [[85-FixLog/<slug>]] — status: in-progress
- <other carry-over>
```

### 5.3.5 Collect evidence GDrive links (NEW)

ถ้า project มี evidence ที่ upload ขึ้น GDrive แล้ว (จาก `/bda-upload`):

```bash
# Scan manifest entries with gdrive_link from today
for m in $(find "$VAULT_ABS"/{20-Features,80-ImplementPlan,85-FixLog,90-TestPlan} -name "evidence-manifest.md"); do
  grep -E "\|.*$TODAY.*\|.*https://" "$m"
done
```

เพิ่มใน end-of-day section:

```markdown
**Evidence captured today (for executive):**
| Context | Item | Description | Link |
|---|---|---|---|
| FEAT-Checkout | E001 | submit success | [view](https://drive.google.com/...) |
| FEAT-Checkout | E002 | receipt printed | [view](https://drive.google.com/...) |
| fix-search | E001 | repro screen | [view](https://drive.google.com/...) |

**Local-only (not yet uploaded):** 2 items — รัน `/bda-upload --pending` เพื่อ share
```

ถ้า `paths.daily_log_mirror` set → ก่อนสรุปจบให้ trigger:
```bash
bash scripts/upload-evidence.sh --pending --dry-run   # show what would upload
# ให้ user confirm → ค่อยรันจริงไม่มี --dry-run
```

### 5.4 Update IMPLEMENTATION-STATUS
ถ้ามี plan/feature completed วันนี้ → update `docs/00-Index/IMPLEMENTATION-STATUS.md`

### 5.5 Set status: closed
Update frontmatter `status: closed` หลัง end-of-day filled

### 5.6 Mirror ไป daily_log_mirror (optional, personal)

ถ้า `$DAILY_MIRROR` ไม่ว่าง:
```bash
if [ -n "$DAILY_MIRROR" ] && [ -d "$DAILY_MIRROR" ]; then
  # คัดลอกไฟล์ checkin ของวันนี้ไป mirror
  cp "$CHECKIN" "$DAILY_MIRROR/${TODAY}-${PROJECT_SLUG:-project}.md"
  echo "  → Mirrored to: $DAILY_MIRROR/${TODAY}-${PROJECT_SLUG:-project}.md"
fi
```

> Mirror path เป็น personal ของ user (อยู่ใน `.bda-spec.local.yml`) — ไม่ใช่ของ team
> Executive ที่ใช้ central vault จะเห็นไฟล์นี้, ส่วนใน repo ของ project ยังเป็น source-of-truth

## Phase 6 — Show mode

แสดง section ทั้งหมดที่ filled + section ที่ยังว่าง — ไม่แก้

## Output (5 หัวข้อบังคับ)

1. **BDA Standard files used** — `standards/STANDARD.md`, `standards/templates/daily-log-v5.md`
2. **Pipeline trace** — Understand (Phase 0 detect) → Plan (Phase 1 file scaffold) → Execute (Phase 2/3/4/5 ตาม section) → Verify (Phase 6 show) → Handoff (status: closed + carry-over)
3. **Commands run** — `git log`, grep ของ in-progress, file Write
4. **Verification / Evidence** — `docs/75-Checkins/<date>.md` path + sections filled count
5. **Limitations / Risks / Next steps** — incomplete outcomes ที่ carry over

## ห้าม

- ห้ามแต่ง commits/plans/fixes ที่ user ไม่ได้ทำจริง
- ห้ามแต่ง token count, cost — ถ้าไม่รู้ ระบุ "self-reported" หรือ "not tracked"
- ห้าม overwrite section ที่ filled แล้วโดยไม่ confirm
