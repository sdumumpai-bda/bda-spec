# Distribution Guide — bda-spec

วิธี distribute bda-spec ให้ team หรือ external users ผ่าน git (รูปแบบเดียวกับ [spec-kit](https://github.com/github/spec-kit))

---

## 1. โมเดล distribution

**bda-spec ใช้แนวทาง 3 ขั้น:**

1. **Source repo on GitHub** — `git@github.com:sdumumpai-bda/bda-spec.git` (ตอนนี้ตั้งไว้แล้ว)
2. **One-line install via curl** — `bash <(curl -fsSL .../scripts/install.sh)` (เหมือน spec-kit)
3. **Tagged releases** — version-pinned snapshots (`v0.1.0`, `v0.2.0`, ...)

**ต่างจาก spec-kit ตรงไหน:**
- spec-kit ใช้ Python (`uvx`) — ต้องมี Python + uv ติดตั้ง
- bda-spec ใช้ **pure bash** — ใช้ได้ทุก Mac/Linux โดยไม่ต้องลงอะไรเพิ่ม นอกจาก `git` + `bash`

---

## 2. First commit + push (ครั้งแรก)

```bash
cd /Volumes/testspace/AI-workflow/bda-spec

# ตรวจ remote (ตั้งไว้แล้ว)
git remote -v
# origin    git@github.com:sdumumpai-bda/bda-spec.git (fetch/push)

# Stage ทั้งหมด
git add -A

# ดู status (กันลืม)
git status

# Commit แรก
git commit -m "feat: initial bda-spec release v0.2.0

- 20 commands (spec-driven + BDA + thai-cleft patterns)
- 9 specialized subagents
- 5 AI shims (Claude/Codex/Gemini/GPT/GLM)
- BDA Standard v0.7.0 pinned
- 3-tier evidence storage with GDrive upload
- Sample Library Book Tracker vault
- 233 smoke tests passing"

# Push
git branch -M main
git push -u origin main

# Tag release
git tag -a v0.2.0 -m "Release v0.2.0 — initial public release"
git push origin v0.2.0
```

---

## 3. Subsequent releases (สำหรับ maintainer)

```bash
# 1. Bump VERSION
echo "0.3.0" > VERSION

# 2. Update CHANGELOG.md เพิ่ม section ใหม่ที่ด้านบน:
#    ## [0.3.0] — YYYY-MM-DD
#    ### Added / Changed / Removed
#    ...

# 3. Verify ก่อน push
bash scripts/test.sh                     # ทุก test ต้อง pass
bash bin/bda-spec doctor                 # check ครบไหม

# 4. Commit + tag
git add -A
git commit -m "release: v0.3.0 — <summary 1 บรรทัด>"
git push origin main

git tag -a v0.3.0 -m "Release v0.3.0 — <summary>"
git push origin v0.3.0

# 5. (Optional) สร้าง GitHub Release จาก tag
gh release create v0.3.0 --title "v0.3.0" --notes-from-tag
# หรือผ่าน web: GitHub → Releases → Draft new release → เลือก tag v0.3.0
```

---

## 4. User install/upgrade flow

### Greenfield (project ใหม่)

```bash
mkdir my-app && cd my-app
bash <(curl -fsSL https://raw.githubusercontent.com/sdumumpai-bda/bda-spec/main/scripts/install.sh)
```

### Brownfield (มี code อยู่แล้ว)

```bash
cd existing-project
bash <(curl -fsSL https://raw.githubusercontent.com/sdumumpai-bda/bda-spec/main/scripts/install.sh)
# installer จะตรวจ indicators แล้วถาม mode
```

### Pin version (production projects)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sdumumpai-bda/bda-spec/v0.2.0/scripts/install.sh)
# ใช้ tag v0.2.0 แทน main — version-locked
```

### Local install (offline / dev mode)

```bash
git clone git@github.com:sdumumpai-bda/bda-spec.git ~/bda-spec
cd target-project
bash ~/bda-spec/scripts/install.sh --source ~/bda-spec
```

### Upgrade ของ project ที่ติดตั้งไว้แล้ว

```bash
cd my-project

# Latest
bda-spec upgrade

# Pin to specific version
bda-spec upgrade --version v0.3.0

# Preview (ไม่จริง)
bda-spec upgrade --dry-run

# Rollback ถ้าพัง
bda-spec upgrade --rollback
```

`upgrade` **ห้ามแตะ**: `templates/`, `docs/`, `.bda-spec.yml`, `.bda-spec.local.yml`, `.bda-spec/local/`, `CLAUDE.md`, `AI-README.md`, `README.md`
**แทนที่** (v0.4.1+): `.bda-spec/commands/`, `.claude/commands/`, `.claude/agents/`, `.bda-spec/`, `.bda-spec/VERSION`, `scripts/`, `bin/`, `codex/`, `gemini/`, `gpt/`, `glm/`, `prompts/`

---

## 5. Repository visibility decisions

| ทางเลือก | ข้อดี | ข้อเสีย |
|---|---|---|
| **Public** (เหมือน spec-kit) | curl install ทำงานได้ทันที, ไม่ต้อง auth | content เห็นได้สาธารณะ |
| **Private** | controlled access | curl ต้อง GITHUB_TOKEN, ใช้ยากขึ้น |

**แนะนำ**: เริ่ม **Private** (org-internal) → เมื่อ stable แล้วค่อย flip เป็น **Public**

**ถ้า private** — installer ต้องใช้ token:

```bash
export GITHUB_TOKEN=ghp_xxx
bash <(curl -fsSL -H "Authorization: token $GITHUB_TOKEN" \
  https://raw.githubusercontent.com/sdumumpai-bda/bda-spec/main/scripts/install.sh)
```

หรือใช้ SSH clone แทน:

```bash
git clone git@github.com:sdumumpai-bda/bda-spec.git /tmp/bda-spec
bash /tmp/bda-spec/scripts/install.sh
```

---

## 6. CI/CD checklist (suggested)

เพิ่ม GitHub Actions workflow ที่ `.github/workflows/test.yml`:

```yaml
name: bda-spec smoke tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run smoke tests
        run: |
          bash scripts/test.sh
      - name: Run doctor
        run: |
          bash bin/bda-spec doctor
      - name: Test install on empty folder (greenfield)
        run: |
          mkdir /tmp/test-greenfield
          bash scripts/install.sh /tmp/test-greenfield \
            --source . --ai claude --yes
          test -f /tmp/test-greenfield/.bda-spec.yml
          test -d /tmp/test-greenfield/commands
```

หรือเพิ่ม release workflow ที่ `.github/workflows/release.yml`:

```yaml
name: Release

on:
  push:
    tags: ['v*']

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          generate_release_notes: true
```

---

## 7. Versioning policy

bda-spec ใช้ **Semantic Versioning** (`MAJOR.MINOR.PATCH`):

- **MAJOR** — breaking changes: command rename/remove, output format change, installer flag change
- **MINOR** — new command, new template, new AI shim, new helper script
- **PATCH** — clarifications, bug fix, doc update (ไม่ breaking)

`.bda-spec/VERSION` (BDA standard ที่ pinned) **ต่างจาก** `VERSION` (bda-spec เอง) — ดูใน CHANGELOG.md ทั้งสองตัว

---

## 8. รายชื่อ users / consumers

(ใส่ project ที่ใช้ bda-spec — เพื่อ track adoption)

- `BigDataAgency/thai-cleft-main` — Thai Cleft Primary Care App (reference implementation)
- (เพิ่ม project ใหม่ที่นี่)

---

## 9. Comparison — spec-kit vs bda-spec distribution

| Aspect | spec-kit | bda-spec |
|---|---|---|
| Language | Python | Bash |
| Install command | `uvx specify init <name>` | `bda-spec init <name>` หรือ curl-pipe |
| Dependencies | Python 3 + uv | Bash + git (most systems) |
| Version pinning | `--from git+...@tag` | `--version v0.2.0` |
| Greenfield/Brownfield | `init` vs `init --here` | auto-detect via indicators + ถาม user |
| AI selection | `--ai claude\|copilot\|gemini\|...` | `--ai claude,codex,google,gpt,glm` |
| Template override | 4-tier override stack | 3-tier (local → project → standards) |
| Update | re-run installer | `bda-spec upgrade` (preserves user content) |

---

## 10. ขั้นต่อไป (recommended)

1. ✅ commit + push ครั้งแรก (ดู section 2)
2. ✅ tag `v0.2.0` (ดู section 2)
3. ☐ ตั้ง repo visibility (private → public เมื่อ stable)
4. ☐ เพิ่ม `.github/workflows/test.yml` (section 6)
5. ☐ เขียน GitHub Release notes สำหรับ `v0.2.0`
6. ☐ แชร์ install command กับ team:
   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/sdumumpai-bda/bda-spec/main/scripts/install.sh)
   ```
7. ☐ collect feedback ผ่าน issues + standard-feedback process
