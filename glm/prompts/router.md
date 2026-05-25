# bda-spec verb router (for GLM / ChatGLM)

When user says `bda-<verb>: <task>` or `<verb>: <task>`, read the corresponding spec file and follow its Phase structure.

## Verb → spec mapping

| User input | Spec file to load |
|---|---|
| `bda-help` / `help` / `?` | `commands/bda-help.md` |
| `bda-init` / `init` | `commands/bda-init.md` |
| `bda-new` / `new` | `commands/bda-new.md` |
| `bda-clarify` / `clarify` | `commands/bda-clarify.md` |
| `bda-plan` / `plan` | `commands/bda-plan.md` |
| `bda-checklist` / `checklist` | `commands/bda-checklist.md` |
| `bda-implement` / `implement` | `commands/bda-implement.md` |
| `bda-fix` / `fix` | `commands/bda-fix.md` |
| `bda-reverse-engineer` / `reverse-engineer` / `reverse` | `commands/bda-reverse-engineer.md` |
| `bda-doc` / `doc` | `commands/bda-doc.md` |
| `bda-test` / `test` | `commands/bda-test.md` |
| `bda-design` / `design` | `commands/bda-design.md` |
| `bda-evidence` / `evidence` | `commands/bda-evidence.md` |
| `bda-checkin` / `checkin` | `commands/bda-checkin.md` |
| `bda-secure` / `secure` | `commands/bda-secure.md` |
| `bda-verify` / `verify` | `commands/bda-verify.md` |
| `bda-handoff` / `handoff` | `commands/bda-handoff.md` |
| `bda-git` / `git-sync` | `commands/bda-git.md` |
| `bda-upload` / `upload` | `commands/bda-upload.md` |
| `bda-sync` / `sync` | `commands/bda-sync.md` |
| `bda-agent` / `agent` | `commands/bda-agent.md` |

## Persona switching

When working in a particular domain, mention you're acting as the corresponding subagent persona:
- Backend work → "Acting as `.claude/agents/backend.md`"
- Frontend work → "Acting as `.claude/agents/frontend.md`" (DS-strict)
- Mobile → "Acting as `.claude/agents/mobile.md`"
- Docs/vault → "Acting as `.claude/agents/docs.md`"
- Tests → "Acting as `.claude/agents/test-runner.md`"
- Security → "Acting as `.claude/agents/security.md`"
- Design system → "Acting as `.claude/agents/design.md`"
- Figma read-only → "Acting as `.claude/agents/figma.md`"
- Verification → "Acting as `.claude/agents/verifier.md`"

Each persona file describes role, scope, gates (§5), and forbidden actions.
