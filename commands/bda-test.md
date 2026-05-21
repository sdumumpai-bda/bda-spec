---
description: Auto smoke test changed surface — detect diff → spin servers → dispatch test-runner
model: claude-sonnet-4-6
---

# /bda-test — Smoke test changed surface

Detect diff → spin server เท่าที่จำเป็น → spawn `test-runner` agent → report

## Trigger

```
/bda-test                    # auto-detect จาก git diff
/bda-test web                # บังคับ web
/bda-test app                # บังคับ mobile
/bda-test api                # บังคับ backend (unit + integration)
/bda-test <plan-file>        # ใช้ scope ของ plan
/bda-test <test-plan-file>   # systematic role-by-role test plan
/bda-test --since <ref>      # diff ตั้งแต่ ref (default HEAD)
```

## Phase 0 — Detect mode

| `$ARGUMENTS` | Mode |
|---|---|
| ว่าง | **Auto** — Phase 1 → 3 |
| `web` / `app` / `api` | **Forced** — Phase 2 → 3 |
| path ใน `90-TestPlan/` | **Test Plan** — Phase T |
| path ใน `80-ImplementPlan/` | **Plan scope** — Phase 2 → 3 (infer target จาก plan) |

## Phase 1 — Detect scope (Auto only)

```bash
changed=$(git diff --name-only HEAD; git diff --name-only --cached; git ls-files --others --exclude-standard)
```

ตรวจว่าแก้ที่ไหน:
- API/backend folders → `api`, `server`, `backend`, `*.controller.*`
- Web → `web`, `client`, `frontend`, `*.tsx`, `*.vue`, `*.svelte`
- Mobile → `app`, `mobile`, `*.dart`, `*.swift`, `*.kt`

| Changed | Action |
|---|---|
| API only | unit + integration tests (no UI) |
| Web (±API) | dispatch test-runner target=web |
| Mobile (±API) | dispatch test-runner target=app |
| Web + Mobile | dispatch twice |
| Nothing | Exit — "ไม่มี diff" |

## Phase 2 — Spin up servers (เท่าที่จำเป็น)

- Web → check ว่า dev server รันอยู่ที่ expected port; ถ้าไม่ → spin up
- Mobile → check emulator/simulator; ถ้าไม่ → start
- API → check ว่า API responsive; ถ้าไม่ → spin up

ถ้า servers ต้อง credentials/secrets ที่ไม่มี → blocker → STOP + แจ้ง user

## Phase 3 — Spawn test-runner

Prompt:
```
Target: <web | app | api>
Scope: <files changed | plan file>
Vault context: docs/90-TestPlan/ (อ่านที่มี relevant)

Tasks:
1. Run smoke tests สำหรับ surface ที่เปลี่ยน
2. Capture screenshots (เฉพาะ web/mobile)
3. Capture console + network logs
4. Detect PII/secret ในผลลัพธ์ → mask
5. Mark route source trace ของแต่ละ check:
   VISIBLE_MENU / DIRECT_URL_USER / DIRECT_URL_TECHNICAL
6. Report: PASS / FAIL / BLOCKED + evidence paths
```

## Phase T — Test Plan mode

อ่าน test plan ที่ `90-TestPlan/TP-*.md` — ทำ systematic test ตาม:
- แต่ละ role ใน plan
- แต่ละ scenario
- เก็บ evidence ตาม manifest format ของ BDA standard
- Status taxonomy: PASS / FAIL / INFO / LIMITED / PASS_NO_MUTATION / BLOCKED_* / NOT_RUN

## Phase 4 — Evidence collection

ทุก test run สร้าง:
```
docs/90-TestPlan/evidence/<YYYY-MM-DD>-<slug>/
├── report.md              # summary + status per scenario
├── screenshots/           # <SCENARIO-ID>-<STEP-NO>-<short-state>.png
├── console.log
├── network.log
└── manifest.json          # PII flag, masking flag, safe-to-share flag
```

แต่ละ screenshot บันทึก:
- scenario / step
- page / URL
- expected / actual
- console summary
- network summary
- PII / secret flag
- masking applied
- safe-to-share flag

## Phase 5 — Visible-menu rule

UI tests ต้องเริ่มจาก **visible menu navigation** เป็น default

ถ้า skip menu → ระบุ:
- `DIRECT_URL_USER` (URL ที่ user-facing) — ต้องอธิบายเหตุผล
- `DIRECT_URL_TECHNICAL` (สำหรับ tech check เท่านั้น) — label ชัดเจน

ห้าม claim user journey ผ่าน hidden route

## Phase 6 — Output report

แสดง:
```
Test summary
============
Target: web
Scenarios: 5 (PASS: 4, FAIL: 1, BLOCKED: 0)

[FAIL] TC-003 — Search returns empty when DB has results
  Page: /search
  Console: TypeError: cannot read 'items' of undefined
  Screenshot: docs/90-TestPlan/evidence/<slug>/TC-003-04-error-state.png
  
Next: รัน /bda-fix "search returns empty..." → diagnose
```

## Output (5 หัวข้อบังคับ)

1. **BDA Standard files used** — `standards/STANDARD.md`, `standards/policies/no-fake-evidence.md`, `standards/templates/test-scenario-report.md`
2. **Pipeline trace** — Understand (Phase 1 detect) → Plan (Phase 2 setup) → Execute (Phase 3 dispatch) → Verify (Phase 4 evidence) → Handoff (Phase 6 report)
3. **Commands run** — `git diff`, server commands, test commands ทั้งหมด พร้อม exit code
4. **Verification / Evidence** — evidence folder path + screenshot count + status taxonomy
5. **Limitations / Risks / Next steps** — flaky tests, blocked scenarios, suggested fix-log

## ห้าม

- ห้ามแต่ง screenshot, console log, network log
- ห้ามรัน test กับ production env
- ห้าม claim PASS ถ้า test ไม่ได้รันจริง — mark `NOT_RUN_RISK` แทน
- ห้าม commit evidence ที่มี PII โดยไม่ mask
