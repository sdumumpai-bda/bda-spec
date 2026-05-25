# /bda-secure

> **Security pre-flight** — scan secrets, PII, screenshot masking, public-repo, dependency CVE, prod guardrails

[← กลับ usage/README](./README.md) · [Full spec: `.bda-spec/commands/bda-secure.md`](../.bda-spec/commands/bda-secure.md)

## เมื่อไหร่ใช้

- ก่อน `/bda-git` commit/push — เด็ดขาดก่อนส่ง code
- ก่อน `/bda-upload` — มี secret ใน screenshot ไหม
- ก่อน `/bda-verify` handoff — pre-flight check
- ตอน adopt repo เดิม (brownfield) — สแกน hidden secrets

## Quick start

```
/bda-secure
```

ตัวอย่าง output:
```
Security pre-flight
===================
✅ Secret scan: clean (5 files scanned)
✅ PII scan: clean (12 docs scanned)
🟡 Screenshot masking: 2 screenshots missing PII flag
   - docs/obsidian-vault/90-TestPlan/evidence/2026-05-20-search/TC-001-03-results.png
✅ Public-repo guardrails: ok
🟡 npm audit: 3 high-severity (express@4.17 → 4.19)
✅ Production guardrails: ok

Verdict: REVIEW NEEDED (2 yellow)
```

## รูปแบบเต็ม

```
/bda-secure                    # full scan (all 6 phases)
/bda-secure secrets            # secrets only
/bda-secure pii                # PII only
/bda-secure evidence           # screenshot masking check
/bda-secure --since <ref>      # scan diff since ref
```

## ขั้นตอนภายใน (Phase summary)

1. **Phase 1** — Secret scan (AWS, GitHub PAT, Anthropic/OpenAI keys, Slack, Google, generic) → BLOCK ถ้าเจอ
2. **Phase 2** — PII scan in `docs/` (Thai citizen ID, phone, email, HN/VN/AN) → BLOCK ถ้าไม่ mask
3. **Phase 3** — Screenshot masking check (manifest entries vs files)
4. **Phase 4** — Public-repo guardrails (confidential tags, NDA, customer name)
5. **Phase 5** — Dependency CVE quick-check (`npm audit`, `pip list --outdated`, `cargo audit`)
6. **Phase 6** — Production-write guardrails (`.env.production`, prod config, deploy script)
7. **Phase 7** — Report + verdict (ALL GREEN / REVIEW NEEDED / BLOCKED)
8. **Phase 8** — Log checkin

## Verdict matrix

| Verdict | Action |
|---|---|
| ✅ ALL GREEN | OK to commit/handoff |
| 🟡 REVIEW NEEDED | แก้/justify ก่อน proceed |
| ❌ BLOCKED | ห้าม commit — ต้องแก้ก่อน |

## Output ที่ได้

- Console report (verdict + findings table)
- Checkin entry: `HH:MM — [type/security] /bda-secure — 0 secrets, 0 PII, 2 unmasked — REVIEW`
- **ไม่แก้ไฟล์** — read-only scan

## Secret patterns ที่ scan

- `AKIA[0-9A-Z]{16}` — AWS access key
- `-----BEGIN [A-Z ]+ PRIVATE KEY-----` — RSA/EC private keys
- `ghp_[A-Za-z0-9]{36,}` — GitHub PAT
- `sk-[A-Za-z0-9]{32,}` — Anthropic/OpenAI keys
- `xox[bpoa]-[0-9a-zA-Z-]{10,}` — Slack token
- `AIza[0-9A-Za-z-_]{35}` — Google API key
- Generic: `password|secret|api_key|token = "..."` (≥ 8 chars)

## PII patterns (Thai-specific)

- `[0-9]-[0-9]{4}-[0-9]{5}-[0-9]{2}-[0-9]` — Thai citizen ID
- 10-digit phone number
- Email regex
- `(HN|VN|AN)[0-9]{6,}` — hospital numbers

## Workflow ที่นิยม

ตัวอย่าง 1: pre-commit
```
1. /bda-implement <plan>
2. /bda-secure                  ← คุณอยู่ที่นี่
   → ✅ ALL GREEN
3. /bda-git --plan <path>
```

ตัวอย่าง 2: pre-handoff
```
1. /bda-secure
   → 🟡 REVIEW: 2 unmasked screenshots
2. /bda-evidence (mask + update manifest)
3. /bda-secure
   → ✅ ALL GREEN
4. /bda-verify
```

ตัวอย่าง 3: diff-scoped
```
/bda-secure --since main
  → scan เฉพาะ diff vs main branch
```

## Gotchas / ข้อควรระวัง

- 🚫 **ห้ามรัน scan โดย skip files** — transparent, list ทุก file ที่ scan
- 🚫 **ห้าม fix secrets เอง** — แจ้ง user ให้ revoke + rotate (AI ไม่ควรรู้ secret value)
- 🚫 ห้าม commit ถ้า BLOCKED — ต้องผ่าน manual override + log reason
- ⚠️ Secret patterns ไม่ครอบคลุม custom secrets (เช่น internal token format) — manual review ด้วย
- ⚠️ PII regex อาจ false-positive (เช่น 10-digit timestamp) — verify ก่อน block
- ⚠️ `npm audit` อาจ noisy — focus high/critical
- 💡 ทุก verdict yellow ก็ block `/bda-verify` handoff — ต้องแก้ก่อน

## Related

- ก่อน `/bda-secure`: [/bda-implement](./bda-implement.md), [/bda-evidence](./bda-evidence.md)
- หลัง `/bda-secure`: [/bda-git](./bda-git.md), [/bda-verify](./bda-verify.md)
- Embedded ใน: [/bda-verify](./bda-verify.md) Phase 5
- Policies: `.bda-spec/policies/no-fake-evidence.md`, `.bda-spec/policies/source-of-truth.md`

## FAQ

**Q: ถ้าเจอ secret ใน .git history เก่า?**
A: `/bda-secure` แค่ flag — ต้อง rotate credential + `git filter-repo` แยกต่างหาก

**Q: PII Thai pattern คลุม ID อื่นๆ ไหม?**
A: คลุม citizen ID, phone, email, hospital number ถ้ามี custom pattern → extend ใน `.bda-spec/commands/bda-secure.md` patterns array

**Q: ใช้ตัวเดียวกับ pre-commit hook ได้ไหม?**
A: ได้ — `bash <path>/.bda-spec/scripts/secure.sh` (ถ้า project มี) หรือ `/bda-secure --since HEAD` ใน hook
