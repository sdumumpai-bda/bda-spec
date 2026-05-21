# /bda-test

> **Smoke test เฉพาะส่วน diff** — detect changed surface → spin servers → spawn test-runner → capture evidence

[← กลับ usage/README](./README.md) · [Full spec: `commands/bda-test.md`](../commands/bda-test.md)

## เมื่อไหร่ใช้

- หลัง `/bda-implement` — verify ว่า code ที่แก้ทำงาน
- ก่อน `/bda-verify` / `/bda-secure` — smoke pass ก่อน
- มี test plan (`90-TestPlan/TP-*.md`) — รัน systematic role-by-role
- หลัง `/bda-fix` → `/bda-implement` — verify ว่า fix ใช้ได้

## Quick start

```
/bda-test
```

Auto-detect:
```
git diff --name-only HEAD
→ ตรวจว่าแก้ใน web/, api/, mobile/
→ spin server → spawn test-runner
→ capture screenshot + console + network
```

## รูปแบบเต็ม

```
/bda-test                       # auto-detect จาก git diff
/bda-test web                   # บังคับ web
/bda-test app                   # บังคับ mobile
/bda-test api                   # backend (unit + integration)
/bda-test <plan-file>           # scope ของ plan
/bda-test <test-plan-file>      # systematic test plan (90-TestPlan/)
/bda-test --since <ref>         # diff ตั้งแต่ ref (default HEAD)
```

| Mode | Trigger |
|---|---|
| Auto | args ว่าง → ดู git diff |
| Forced | `web` / `app` / `api` |
| Plan scope | path ใน `80-ImplementPlan/` |
| Test Plan | path ใน `90-TestPlan/` (systematic) |

## ขั้นตอนภายใน (Phase summary)

1. **Phase 0** — Detect mode
2. **Phase 1** — Detect scope (auto only) จาก `git diff`
3. **Phase 2** — Spin servers (dev server, emulator/simulator, API) เท่าที่จำเป็น
4. **Phase 3** — Spawn `test-runner` subagent: smoke tests, screenshots, console+network logs, PII mask, route source trace
5. **Phase T (Test Plan mode)** — รัน systematic ทุก role × scenario, status taxonomy: PASS/FAIL/INFO/LIMITED/PASS_NO_MUTATION/BLOCKED_*/NOT_RUN
6. **Phase 4** — Evidence collection: `docs/obsidian-vault/90-TestPlan/evidence/<YYYY-MM-DD>-<slug>/`
7. **Phase 5** — Visible-menu rule: route source = VISIBLE_MENU / DIRECT_URL_USER / DIRECT_URL_TECHNICAL
8. **Phase 6** — Output report (PASS/FAIL summary + evidence paths)

## Output ที่ได้

- `docs/obsidian-vault/90-TestPlan/evidence/<YYYY-MM-DD>-<slug>/`
  - `report.md` — summary + status per scenario
  - `screenshots/` — `<SCENARIO-ID>-<STEP-NO>-<state>.png`
  - `console.log`, `network.log`
  - `manifest.json` — PII/masking/safe-to-share flags
- Console: PASS/FAIL/BLOCKED summary

## Status taxonomy

| Status | ความหมาย |
|---|---|
| `PASS` | ผ่านสมบูรณ์ |
| `FAIL` | failed (มี error/wrong output) |
| `INFO` | informational (no pass/fail) |
| `LIMITED` | partial — บาง assertion ทำไม่ได้ |
| `PASS_NO_MUTATION` | pass แต่ไม่ test side-effect |
| `BLOCKED_<reason>` | blocked (env, dep, perm) |
| `NOT_RUN_RISK` | ไม่ได้รัน (ไม่ใช่ pass ปลอม) |

## Workflow ที่นิยม

ตัวอย่าง 1: post-implement smoke
```
1. /bda-implement <plan>           ← code change
2. /bda-test                       ← auto-detect web → smoke
3. (ถ้า fail → /bda-fix)
4. /bda-verify
```

ตัวอย่าง 2: systematic test plan
```
1. /bda-doc TestPlan FEAT-Checkout      ← สร้าง TP-Checkout.md
2. /bda-test docs/obsidian-vault/90-TestPlan/TP-Checkout.md
   → รันทุก role × scenario
   → MANIFEST.md + screenshots ครบ
```

ตัวอย่าง 3: pre-merge check
```
/bda-test --since main
  → diff vs main branch
  → smoke ทุก surface ที่กระทบ
```

## Gotchas / ข้อควรระวัง

- 🚫 **ห้ามแต่ง screenshot, console log, network log** — no-fake-evidence policy
- 🚫 **ห้ามรัน test กับ production env**
- 🚫 ห้าม claim PASS ถ้า test ไม่ได้รันจริง — mark `NOT_RUN_RISK` แทน
- 🚫 ห้าม commit evidence ที่มี PII โดยไม่ mask
- ⚠️ Visible-menu rule: UI test ต้องเริ่มจาก menu navigation default; ใช้ `DIRECT_URL_*` ต้องระบุเหตุผล
- ⚠️ Server credentials/secrets ที่ไม่มี → blocker → STOP + แจ้ง user
- 💡 ถ้า "ไม่มี diff" → exit สั้นๆ ไม่รัน
- 💡 ทุก screenshot ใส่ scenario / step / page / expected / actual / console / network / PII flag ใน manifest

## Related

- ก่อน `/bda-test`: [/bda-implement](./bda-implement.md) (มี code change)
- หลัง `/bda-test` (fail): [/bda-fix](./bda-fix.md)
- หลัง `/bda-test` (pass): [/bda-evidence](./bda-evidence.md) (curate) → [/bda-upload](./bda-upload.md) (share)
- Test plans: `docs/obsidian-vault/90-TestPlan/`
- Subagent: [`.claude/agents/test-runner.md`](../.claude/agents/test-runner.md)
- Evidence paths: [`EVIDENCE-PATHS.md`](../EVIDENCE-PATHS.md)

## FAQ

**Q: ต้อง install Playwright/Maestro ก่อนไหม?**
A: ใช่ — `test-runner` subagent ใช้ Playwright (web) + Maestro (mobile) ถ้าไม่มี → ใช้ unit/integration test ของ project แทน

**Q: ทำไมแยก Tier 1 (test-artifacts/) กับ Tier 2 (docs/.../evidence/)?**
A: Tier 1 = raw (gitignored, อาจมี PII), Tier 2 = curated (masked, gitTracked) — ดู `EVIDENCE-PATHS.md`

**Q: smoke test กับ full test plan ต่างกันไง?**
A: Smoke = diff-scoped (เร็ว, fail-fast); Test Plan = systematic role × scenario (ครบ, ใช้ก่อน release)
