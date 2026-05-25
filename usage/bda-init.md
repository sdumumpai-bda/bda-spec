# /bda-init

> **Bootstrap bda-spec** — ตั้งค่า project ครั้งแรก + สร้าง Obsidian vault + เลือก subagent

[← กลับ usage/README](./README.md) · [Full spec: `commands/bda-init.md`](../commands/bda-init.md)

## เมื่อไหร่ใช้

- หลังรัน `bash <(curl ... install.sh)` แล้ว — `/bda-init` ทำ interactive config
- เริ่ม project ใหม่จากศูนย์ (greenfield — folder ว่าง)
- รับ codebase เดิมเข้า bda-spec (brownfield — มี code/docs อยู่แล้ว)
- อยาก reconfigure project ที่ init แล้ว (`--reconfigure`)

## Quick start

```
/bda-init
```

ตัวอย่าง output:
```
🔍 ตรวจพบ indicators ใน folder นี้:
   • package.json
   • src/
   • .git (47 commits)

โหมดไหนตรงกับสถานการณ์?
  1) greenfield   — project setup ไว้ แต่ยังไม่มี content จริง
  2) brownfield   — มี code/docs ใช้งานอยู่
  3) adopt-vault  — มี Obsidian vault เดิม

เลือก (1/2/3) [default: 2]:
```

## รูปแบบเต็ม

```
/bda-init                     # auto-detect mode (ถามถ้า ambiguous)
/bda-init <project-name>      # ระบุชื่อ project
/bda-init --greenfield        # บังคับ greenfield mode
/bda-init --brownfield        # บังคับ brownfield (ห้ามแตะของเดิม)
/bda-init --reconfigure       # แก้ config ของ project ที่ init แล้ว
```

| Flag | Default | ใช้สำหรับ |
|---|---|---|
| `--greenfield` | auto | บังคับ — สร้าง vault skeleton ใหม่ |
| `--brownfield` | auto | บังคับ — ห้ามแตะ code เดิม |
| `--reconfigure` | n/a | reset ส่วนใดส่วนหนึ่งของ `.bda-spec.yml` |

## ขั้นตอนภายใน (Phase summary)

1. **Phase 0** — Detect mode (greenfield/brownfield/adopt-vault) จาก indicators (`package.json`, `.git`, `docs/`, etc.)
2. **Phase 1** — ถามคำถามขั้นต่ำ batch เดียว (project name, mode, stack, vault location, language, brownfield import)
3. **Phase 2** — สร้าง vault skeleton (12 folders ใน `<vault_path>/`)
4. **Phase 3** — Brownfield adoption (stack scan + import README + suggest first checkin)
5. **Phase 4** — Pin standards snapshot (`.bda-spec/VERSION`)
6. **Phase 5** — Enable subagents ตาม stack
7. **Phase 6** — เขียน `.bda-spec.yml` (shared) + `.bda-spec.local.yml` (personal)
8. **Phase 7** — Verification + แสดง summary

## Output ที่ได้

- `<vault_path>/` (12 folders ครบ — `00-Index/`, `10-PRD/`, …, `95-Handoff/`)
- `.bda-spec.yml` (gitTracked — shared กับ team)
- `.bda-spec.local.yml` (gitignored — personal paths)
- `.bda-spec/VERSION` (pinned)
- `.claude/commands/`, `.claude/agents/` (จาก installer)
- (brownfield) PRD draft จาก README ใน `docs/obsidian-vault/10-PRD/PRD-<slug>.md`

## Vault location options (Phase 1.2)

| ตัวเลือก | เก็บที่ | ใช้เมื่อ |
|---|---|---|
| A) `docs/` | `<project>/docs/` | greenfield, default |
| B) `docs/bda-vault/` | `<project>/docs/bda-vault/` | brownfield ที่ `docs/` ใช้อยู่ |
| C) custom in-repo | path ที่ user ระบุ | brownfield + มี vault อยู่ |
| D) external | absolute path นอก repo | shared org vault, iCloud sync |

ถ้าเลือก D → path ไป `.bda-spec.local.yml` `paths.external_vault:` (personal)

## Workflow ที่นิยม

ตัวอย่าง 1: เริ่ม project ใหม่
```
1. mkdir my-app && cd my-app
2. bash <(curl ... install.sh)     ← copy scaffolding
3. /bda-init                        ← คุณอยู่ที่นี่
4. /bda-new                         ← brainstorm PRD
5. /bda-plan FEAT-X                 ← เริ่ม implement cycle
```

ตัวอย่าง 2: รับ codebase เดิม (brownfield)
```
1. cd existing-project
2. bash <(curl ... install.sh)
3. /bda-init                        ← ตอบ "brownfield" + ระบุ vault B
4. (ตรวจ PRD draft + REF-TechStack ที่ generate มา)
5. /bda-doc PRD-<slug>              ← เติม section ที่ขาด
```

## Gotchas / ข้อควรระวัง

- ⚠️ `--here` ≠ brownfield — installer/init จะ**ถาม** แม้รันใน cwd เดิม (อาจเป็น scaffolding ที่ยังไม่เริ่ม)
- 🚫 ห้ามแตะ code เดิมใน brownfield — `/bda-init` เพิ่มเฉพาะ `docs/`, `.claude/`, `.bda-spec/`, `templates/`, `.bda-spec.yml`
- 🚫 ห้ามแต่ง dependencies/framework version ที่ไม่ได้เห็นจริงในไฟล์
- 💡 ถ้ามี `CLAUDE.md` อยู่แล้ว → ถามว่า append หรือ rename เก่าเป็น `CLAUDE.legacy.md`
- 💡 `.bda-spec.local.yml` gitignored แล้ว — เก็บ external vault path / daily-log mirror / evidence staging ที่นี่

## Related

- ก่อน `/bda-init`: `bash scripts/install.sh` (bootstrap CLI)
- หลัง `/bda-init` (greenfield): [/bda-new](./bda-new.md) — brainstorm PRD
- หลัง `/bda-init` (brownfield): [/bda-doc](./bda-doc.md) — เติม PRD/SRS
- Reconfigure ทีหลัง: `/bda-init --reconfigure` หรือ [/bda-agent](./bda-agent.md) สำหรับ subagent
- Vault path: `docs/` (ดู [`README`](../README.md) section "โครงสร้าง")

## FAQ

**Q: ผมรันใน folder ที่มี `git init` แล้วแต่ยังไม่มี code — เป็น greenfield หรือ brownfield?**
A: Greenfield — `.git` ว่างไม่นับเป็น indicator init จะถามให้ confirm

**Q: External vault (option D) ใส่ตรงไหน?**
A: `.bda-spec.local.yml` ที่ `paths.external_vault: "<absolute path>"` — gitignored

**Q: ถ้า subagent บางตัวยังไม่ enable แต่อยากใช้ทีหลัง?**
A: ใช้ [/bda-agent enable &lt;name&gt;](./bda-agent.md) หรือ `/bda-init --reconfigure`
