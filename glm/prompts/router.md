# bda-spec verb router (for GLM / ChatGLM)

When user says `bda-<verb>: <task>` or `<verb>: <task>`, read the corresponding spec file and follow its Phase structure.

## Verb → spec mapping

| User input | Spec file to load |
|---|---|
| `bda-help` / `help` / `?` | `.bda-spec/commands/bda-help.md` |
| `bda-init` / `init` | `.bda-spec/commands/bda-init.md` |
| `bda-new` / `new` | `.bda-spec/commands/bda-new.md` |
| `bda-clarify` / `clarify` | `.bda-spec/commands/bda-clarify.md` |
| `bda-plan` / `plan` | `.bda-spec/commands/bda-plan.md` |
| `bda-checklist` / `checklist` | `.bda-spec/commands/bda-checklist.md` |
| `bda-implement` / `implement` | `.bda-spec/commands/bda-implement.md` |
| `bda-fix` / `fix` | `.bda-spec/commands/bda-fix.md` |
| `bda-reverse-engineer` / `reverse-engineer` / `reverse` | `.bda-spec/commands/bda-reverse-engineer.md` |
| `bda-doc` / `doc` | `.bda-spec/commands/bda-doc.md` |
| `bda-test` / `test` | `.bda-spec/commands/bda-test.md` |
| `bda-design` / `design` | `.bda-spec/commands/bda-design.md` |
| `bda-evidence` / `evidence` | `.bda-spec/commands/bda-evidence.md` |
| `bda-checkin` / `checkin` | `.bda-spec/commands/bda-checkin.md` |
| `bda-secure` / `secure` | `.bda-spec/commands/bda-secure.md` |
| `bda-verify` / `verify` | `.bda-spec/commands/bda-verify.md` |
| `bda-handoff` / `handoff` | `.bda-spec/commands/bda-handoff.md` |
| `bda-git` / `git-sync` | `.bda-spec/commands/bda-git.md` |
| `bda-upload` / `upload` | `.bda-spec/commands/bda-upload.md` |
| `bda-sync` / `sync` | `.bda-spec/commands/bda-sync.md` |
| `bda-agent` / `agent` | `.bda-spec/commands/bda-agent.md` |

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
