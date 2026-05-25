# /bda-implement

> **Execute plan ที่ approve แล้ว** ผ่าน subagent — เก็บ evidence + sync vault + update IMPLEMENTATION-STATUS

[← กลับ usage/README](./README.md) · [Full spec: `.bda-spec/commands/bda-implement.md`](../.bda-spec/commands/bda-implement.md)

## เมื่อไหร่ใช้

- Plan file `status: approved` แล้ว (user set เองใน frontmatter)
- เมื่อต้องการแก้โค้ดจริง — **command เดียวที่ได้รับอนุญาตให้แตะโค้ด**
- หลัง `/bda-fix` → `/bda-plan fix:<slug>` → `/bda-implement` chain

## Quick start

```
/bda-implement docs/obsidian-vault/80-ImplementPlan/2026-05-21-1430-add-search.md
```

หรือ auto-locate by slug:
```
/bda-implement add-search
```

ถ้าไม่ระบุ args:
```
/bda-implement
→ list 5 plans ล่าสุดที่ status: approved
```

## รูปแบบเต็ม

```
/bda-implement <plan-path>            # หรือ auto-locate
/bda-implement <slug>                 # search by slug
/bda-implement --from-fix <fix-log>   # P3 polish เท่านั้น (skip plan)
```

## ขั้นตอนภายใน (Phase summary)

1. **Phase 1** — Validate plan: **Refuse ถ้า status != approved**, ตรวจ Implementation Steps + subagent_target
2. **Phase 2** — Fix doc gaps (spawn `docs` subagent ถ้า `Doc Gaps Found` ไม่ว่าง)
3. **Phase 3** — Spawn subagent ตาม `subagent_target` (backend/frontend/mobile/docs/design/all sequence)
4. **Phase 4** — Design system gate: บังคับ frontend/mobile อ่าน DS-Tokens + DS-Components ก่อน → STOP ถ้าต้อง component ใหม่
5. **Phase 5** — Capture evidence (`git diff --stat`, test output, screenshots) ใน `test-artifacts/` → curated → vault
6. **Phase 6** — Update plan (`status: done`, `Implementation Result` section) + IMPLEMENTATION-STATUS + checkin

## Subagent routing

| `subagent_target` | Spawns |
|---|---|
| `backend` | `.claude/agents/backend.md` |
| `frontend` | `.claude/agents/frontend.md` |
| `mobile` | `.claude/agents/mobile.md` |
| `docs` | `.claude/agents/docs.md` |
| `design` | `.claude/agents/design.md` |
| `all` | sequence: backend → frontend → mobile → docs |

## Output ที่ได้

- Code changes (production + test files)
- `test-artifacts/<YYYY-MM-DD>/<plan-slug>/` (raw evidence, gitignored — Tier 1)
- `docs/obsidian-vault/90-TestPlan/evidence/<slug>/` หรือ `docs/<context>/evidence/` (curated, masked — Tier 2)
- Plan file update: `status: done` + `## Implementation Result` section
- `docs/obsidian-vault/00-Index/IMPLEMENTATION-STATUS.md` mark feature/phase done
- Checkin entry: `HH:MM — [type/implement] Completed <slug> — files: N, tests: N`

## Workflow ที่นิยม

ตัวอย่าง 1: feature implement
```
1. /bda-plan FEAT-Checkout            ← plan file (status: planning)
2. [user review + set status: approved]
3. /bda-implement <path>              ← คุณอยู่ที่นี่
   → docs agent fix gaps (ถ้ามี)
   → frontend agent: read DS + implement + capture screenshots
   → update plan status: done
4. /bda-test --since HEAD             ← smoke test
5. /bda-verify                         ← handoff
```

ตัวอย่าง 2: bug fix
```
1. /bda-fix "search ค้าง"
2. /bda-plan fix:search-stuck
3. [approve]
4. /bda-implement <plan>
   → backend agent fix + add regression test
```

ตัวอย่าง 3: multi-stack feature
```
plan: subagent_target: all
/bda-implement <plan>
  → backend agent (API)
  → frontend agent (UI)
  → mobile agent (mobile screen)
  → docs agent (FN-* files update)
```

## Gotchas / ข้อควรระวัง

- 🚫 **Refuse ถ้า plan ไม่ approved** — ต้อง set `status: approved` ใน frontmatter manually ก่อน
- 🚫 **ห้ามแก้ scope** จาก plan โดยไม่ revise plan ก่อน — ใช้ `/bda-plan --revise`
- 🚫 **ห้าม fake test/build evidence** — ถ้า fail บอก blocker แทน
- 🚫 ห้ามแก้ shared/production env โดยไม่ confirm
- 🚫 **ห้ามเพิ่ม abstraction/config/feature** ที่ plan ไม่ได้ระบุ (minimum correct change)
- 🚫 **ห้าม refactor ไฟล์นอก scope** ของ plan
- ⚠️ Design system gate: ถ้าต้อง component ใหม่ → STOP → ต้องรัน `/bda-design component <name>` ก่อน
- ⚠️ Test creation **mandatory** ถ้า production code change — ดู `.claude/agents/{backend,frontend,mobile}.md` §5.1
- 💡 ทุก changed line ต้อง trace กลับไปยัง step ใน plan หรือ success criteria ได้
- 💡 ถ้า test fail: schema/mock outdated → แก้ test; regression/wrong logic → แก้ code (ห้ามลด assertion)

## Related

- ก่อน `/bda-implement`: [/bda-plan](./bda-plan.md) (บังคับ) — plan ต้อง approved
- หลัง `/bda-implement`: [/bda-test](./bda-test.md), [/bda-evidence](./bda-evidence.md), [/bda-secure](./bda-secure.md), [/bda-verify](./bda-verify.md)
- Subagent specs: [`.claude/agents/{backend,frontend,mobile,docs,design}.md`](../.claude/agents/)
- Evidence paths: [`EVIDENCE-PATHS.md`](../EVIDENCE-PATHS.md)

## FAQ

**Q: ทำไมต้อง approve plan ก่อน?**
A: Gate ให้ user review สิ่งที่จะเกิดขึ้น + เพิ่ม intentionality ป้องกัน AI ทำเกิน scope

**Q: ถ้า plan ใหญ่ใช้เวลานาน — แบ่งย่อยได้ไหม?**
A: ได้ — แบ่ง plan เป็นหลายไฟล์ (เช่น P1/P2/P3) แล้ว `/bda-implement` ทีละ plan

**Q: ถ้า subagent ไม่ได้ enable?**
A: `/bda-implement` จะ warn + แนะนำ `/bda-agent enable <name>` ก่อนรันใหม่
