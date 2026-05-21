# Codex Agent Instructions — bda-spec

ตัว Codex ใช้ AGENTS.md เป็น top-level instruction. ไฟล์นี้ shadow `commands/<verb>.md` ของ bda-spec

## หลักการ

bda-spec มี 13 commands ที่ source-of-truth อยู่ที่ `commands/`. เมื่อ user ระบุ verb (`bda-plan`, `bda-fix`, ฯลฯ), อ่านไฟล์ใน `commands/<verb>.md` แล้วทำตาม Phase ที่กำหนด

## Verb mapping

| User input | Read file |
|---|---|
| `bda-help` หรือ `help`, `?` | `commands/bda-help.md` |
| `bda-init` หรือ `init` | `commands/bda-init.md` |
| `bda-clarify` หรือ `clarify` | `commands/bda-clarify.md` |
| `bda-analyze` หรือ `analyze` | `commands/bda-analyze.md` |
| `bda-checklist` หรือ `checklist` | `commands/bda-checklist.md` |
| `bda-evidence` หรือ `evidence` | `commands/bda-evidence.md` |
| `bda-agent` หรือ `agent` | `commands/bda-agent.md` |
| `bda-new` หรือ `new` | `commands/bda-new.md` |
| `bda-plan` หรือ `plan` | `commands/bda-plan.md` |
| `bda-implement` หรือ `implement` | `commands/bda-implement.md` |
| `bda-fix` หรือ `fix` | `commands/bda-fix.md` |
| `bda-doc` หรือ `doc` | `commands/bda-doc.md` |
| `bda-test` หรือ `test` | `commands/bda-test.md` |
| `bda-design` หรือ `design` | `commands/bda-design.md` |
| `bda-checkin` หรือ `checkin` | `commands/bda-checkin.md` |
| `bda-secure` หรือ `secure` | `commands/bda-secure.md` |
| `bda-verify` หรือ `verify` | `commands/bda-verify.md` |
| `bda-git` หรือ `git-sync` | `commands/bda-git.md` |
| `bda-sync` หรือ `sync` | `commands/bda-sync.md` |

## Universal rules (จาก BDA AI Dev Standard)

1. **Vault-first** — อ่าน `docs/obsidian-vault/00-Index/IMPLEMENTATION-STATUS.md` + relevant docs ก่อนถามคำถาม
2. **5 mandatory output sections** ทุก response:
   - BDA Standard files used
   - Pipeline trace: Understand → Plan → Execute → Verify → Handoff
   - Commands run
   - Verification / Evidence
   - Limitations / Risks / Next steps
3. **No fake evidence** — ห้ามแต่ง commit hash, URL, test result, file content ที่ไม่เห็นจริง
4. **Plan/Implement separation** — Plan + Fix ห้ามแก้โค้ด; Implement เท่านั้น
5. **Thai-first** — รายงาน + log ภาษาไทย เว้นแต่ `.bda-spec.yml` `language: en`

## Sub-agent equivalence (Codex)

Codex ไม่มี sub-agent แบบ Claude Code; ใช้ persona switching ผ่าน prompt section:

| ตอนทำงานใน | Persona |
|---|---|
| Backend code | "Acting as `codex/agents/backend.toml`" → อ่าน gates §5 |
| Frontend code | "Acting as `codex/agents/frontend.toml`" → enforce design system |
| Mobile code | "Acting as `codex/agents/mobile.toml`" → enforce design system |
| Docs/vault | "Acting as `codex/agents/docs.toml`" |
| Tests | "Acting as `codex/agents/test-runner.toml`" |
| Security audit | "Acting as `codex/agents/security.toml`" |
| Design system | "Acting as `codex/agents/design.toml`" |

## Config

อ่าน `.bda-spec.yml` เสมอที่จุดเริ่มต้น:
- `mode`
- `vault_path` (โดยมาก `docs`)
- `subagents.*` (ตัวที่ true = persona ที่ใช้)
- `submodules`
- `standard.version`

## ภาษา

ใช้ภาษาไทยใน:
- Phase descriptions
- Output 5 mandatory sections
- Doc content ใน vault
- Checkin entries

ใช้ภาษาอังกฤษใน:
- Code (variable names, comments)
- Frontmatter keys
- File paths
- Git commit messages (subject line)

## ห้าม (BDA Standard policies)

- ห้ามส่งงานโดยไม่มี evidence
- ห้ามบอกว่า test ผ่านถ้าไม่ได้รัน
- ห้ามแก้ shared repo หรือ production โดยไม่ confirm scope
- ห้ามส่งงานโดยไม่ระบุไฟล์มาตรฐาน, pipeline trace, commands run
- ห้ามใส่ secret/credential ลง vault docs
