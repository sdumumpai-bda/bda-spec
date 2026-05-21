# Evidence Path Strategy — bda-spec

วิธีจัดเก็บ evidence ที่ AI agents สร้างขึ้นระหว่างทำงาน — 3 tiers ตาม lifecycle ของ evidence

> **กฎหลัก:** ทุก agent + ทุก command ต้องเก็บ evidence ตาม tier ที่เหมาะสม
> **ห้าม** เก็บ raw evidence (ยังไม่ mask PII) ใน vault หรือ commit ขึ้น git
> **ห้าม** upload evidence ที่ยังไม่ผ่าน mask ไปยัง cloud

---

## Tier 1 — Raw test artifacts (gitignored, local-only)

**Path:** `test-artifacts/<YYYY-MM-DD>/<plan-or-fix-or-test-slug>/`

**ใคร write:**
- `test-runner` subagent — Playwright/Maestro outputs
- `verifier` subagent — build/lint/test results
- `security` subagent — secret/PII/CVE scan outputs
- `backend`/`frontend`/`mobile` subagents — manual test screenshots before review

**โครงสร้างภายใน folder:**
```
test-artifacts/2026-05-21/2026-05-20-1430-bootstrap-checkout-ui/
├── BUILD-INFO.md              # build/test summary (plan)
├── MANIFEST.md                # test plan list (test-plan)
├── EVIDENCE.md                # fix evidence (fix-log only — before/after/regression)
├── console.log                # browser console capture
├── network.har                # network trace
├── coverage/                  # test coverage report
└── TC-01-checkout-success/    # 1 folder per testcase
    ├── EVIDENCE.md            # per-TC evidence + context
    ├── 01-initial.png         # numbered steps
    ├── 02-form-filled.png
    ├── 03-submit-success.png
    └── console-step-3.log
```

**Status:** **GITIGNORED** — อยู่ใน `.gitignore` `test-artifacts/`

**Lifecycle:**
- เริ่มต้นจาก `/bda-test` หรือ subagent spawned โดย `/bda-implement`
- ค้างไว้ ≤ 7 วัน (cleanup script ลบของเก่ากว่านั้น)
- ก่อนหมดอายุ → `/bda-evidence` move ตัวที่ผ่าน mask → Tier 2

**PII status:**
- อาจมี raw PII (เช่น email, ชื่อจริง, screenshot ที่ยังไม่ blur)
- **ห้าม share, commit, upload โดยไม่ผ่าน Tier 2 ก่อน**

---

## Tier 2 — Curated evidence in vault (gitTracked, masked)

**Path patterns ตาม context:**

| Context | Path |
|---|---|
| Feature-level | `docs/20-Features/<FEAT-slug>/evidence/` |
| Function-level | `docs/40-Functions/<surface>/<role>/<FN-slug>/evidence/` |
| Fix log | `docs/85-FixLog/<fix-slug>/evidence/` หรือ `docs/85-FixLog/<file>.evidence/` |
| Plan-level | `docs/80-ImplementPlan/<plan-slug>.evidence/` |
| Test plan | `docs/90-TestPlan/<TP-slug>/evidence/` |
| Handoff | `docs/95-Handoff/<HOR-slug>.evidence/` |
| Flow | `docs/60-Flows/evidence/` |
| Project-wide / Cross | `docs/00-Index/evidence/` |

**Filename convention:**
```
<SCENARIO-ID>-<STEP>-<state>-<HHMMSS>.<ext>
```
ตัวอย่าง: `TC-Checkout-001-03-submit-success-143022.png`

**ใคร write:**
- **เฉพาะ `/bda-evidence` command** (ผ่าน PII mask + safe-to-share confirm)
- ห้าม agent อื่น write ตรงไปยัง path นี้

**Manifest:** ทุก context folder ต้องมี `evidence-manifest.md` ตาม schema:

```markdown
| ID | File | Type | Captured | Scenario/Step | PII | Masked | Safe-to-share | GDrive Link | Uploaded At | Uploaded By |
|---|---|---|---|---|---|---|---|---|---|---|
| E001 | TC-Checkout-001-03-...png | screenshot | 2026-05-21 14:30 | TC-001 step 3 | none | n/a | ✓ | https://drive.google.com/... | 2026-05-21 17:45 | supasin |
```

**Status:** **gitTracked** — commit ได้ปกติ

**PII status:**
- **ผ่าน mask แล้ว** (`pii: none` หรือ `pii: masked`, `masked: ✓`)
- `safe_to_share: ✓` (user confirm)
- ห้าม include raw PII ที่นี่ — ถ้าเจอ → `/bda-secure audit` flag

---

## Tier 3 — Shared cloud (after upload)

**Path:** `<gdrive_folder>/<YYYY-MM-DD>/<context-slug>/<filename>`

ตั้งค่าใน `.bda-spec.local.yml`:
```yaml
evidence_upload:
  provider: gdrive
  rclone_remote: bda-gdrive
  gdrive_folder: "BDA-Evidence/<project-slug>"
  folder_structure: by-date         # by-date | by-feature | flat
```

**ใคร upload:**
- **เฉพาะ `/bda-upload` command** (ผ่าน 6 gates — pii/masked/safe/exists/size/system-file)
- Result: GDrive shareable link → fill กลับใน manifest column "GDrive Link"

**Lifecycle:**
- Upload หลัง Tier 2 stable แล้ว
- ลบจาก GDrive ผ่าน manual cleanup quarterly
- Local Tier 2 ยังอยู่ใน repo เสมอ (backup ของ truth)

---

## Per-agent responsibilities (where each agent writes)

| Agent | Tier 1 (test-artifacts/) | Tier 2 (docs/.../evidence/) | Tier 3 (GDrive) |
|---|---|---|---|
| **docs** | ❌ | ❌ (updates manifests only) | ❌ |
| **verifier** | ✅ BUILD-INFO.md, coverage, lint | via /bda-evidence | via /bda-upload |
| **security** | ✅ scan reports, CVE lists | via /bda-evidence | via /bda-upload (masked) |
| **design** | ✅ DS audit reports | preview.html + `docs/70-Reference/DesignSystem/audit-<DATE>.md` | via /bda-upload |
| **backend** | ✅ test results, API contracts checked | via /bda-evidence | via /bda-upload |
| **frontend** | ✅ component snapshots, a11y audits | via /bda-evidence | via /bda-upload |
| **mobile** | ✅ device screenshots, Maestro runs | via /bda-evidence | via /bda-upload |
| **figma** | ✅ Figma sync logs (read-only source) | ❌ | ❌ |
| **test-runner** | ✅ **primary** — TC screenshots, console, network, MANIFEST | via /bda-evidence | via /bda-upload |

**Rule:** Subagents write to **Tier 1 only**. Curation to Tier 2 ผ่าน `/bda-evidence`. Upload to Tier 3 ผ่าน `/bda-upload`.

---

## Per-agent testing tools (suitable for project)

| Agent | Default tools | Project-specific (set via /bda-agent regenerate) |
|---|---|---|
| **verifier** | `npm test`, `pytest`, `dotnet test`, `go test`, `cargo test` — detected by `package.json`/`pyproject.toml`/`*.csproj`/`go.mod`/`Cargo.toml` | Custom CI commands |
| **test-runner** | Playwright (web) · Maestro (mobile) · Detox (RN) | Custom selector strategy, baseURL |
| **backend** | curl, httpie, OpenAPI validators | Postman collections, k6 load tests |
| **frontend** | Vitest, Playwright component testing, axe-core (a11y) | Storybook, Chromatic visual diff |
| **mobile** | Maestro, Detox, Appium | iOS Simulator, Android emulator profiles |
| **security** | gitleaks, trufflehog, semgrep, dependency-check | Burp, OWASP ZAP scripts |
| **design** | None (read-only audit) | Token sync tools (Style Dictionary, Tokens Studio) |
| **figma** | Figma REST API (read-only) | Tokens Studio export, Figma plugin sync |
| **docs** | grep, awk, markdownlint | Obsidian dataview queries, custom MOC generators |

ตอน `/bda-agent regenerate <agent>` agent จะอ่าน vault context (`REF-TechStack.md` + `REF-APIIntegration.md`) แล้วเลือก tools ที่เหมาะกับ stack ของ project นี้

---

## Where to look in agent files (§2 + §7)

ทุก agent file ใน `.claude/agents/<name>.md` มี:

- **§2 Project context awareness** — Tech stack + Tools ที่ใช้ + paths ที่ agent owns
- **§5 Gates** — refusal rules (เช่น "production code without test ⇒ STOP")
- **§5.1 Test Creation** — testing tools ที่ต้องใช้
- **§7 Vault Update Checklist** — list ของ vault files ที่ agent ต้อง update รวมถึง evidence manifest

ถ้า §2 ของ agent ยังเป็น generic placeholder `TO BE FILLED by /bda-agent regenerate` → รัน:
```
/bda-agent regenerate <name>
```
หลังจาก vault มี PRD/SRS/Tech-spec แล้ว — agent จะอ่าน context จริงแล้วเขียน §2 ใหม่ให้เหมาะกับ project

---

## Verification

ตรวจสอบทุกครั้งก่อน commit / handoff:

```bash
# 1. ห้ามมี test-artifacts/ ใน git
git ls-files test-artifacts/ | head -1 && echo "ERROR: test-artifacts must be gitignored" || echo "OK"

# 2. ห้ามมี raw PII ใน vault evidence
bash scripts/security-scan-evidence.sh   # (TODO: implement)

# 3. Manifest entries ต้องมีไฟล์จริง
bash scripts/upload-evidence.sh --dry-run --pending   # จะ check file exists เป็น gate
```

หรือใช้ command:
```
/bda-secure                              # scan ทั้งหมด
/bda-evidence audit                      # ตรวจ manifest vs filesystem
/bda-evidence verify                     # ตรวจ PII/masking flags
```
