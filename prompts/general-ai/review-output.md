# Review output — Generic AI prompt for verifying bda-spec response

ใช้ prompt นี้ตรวจ output ของ AI ตัวอื่น (หรือ self-review)

---

# Task

ตรวจ response ด้านล่างว่าทำตาม bda-spec rules ครบ:

## Check 1 — 5 mandatory output sections

ตรวจว่ามีครบ:
- [ ] BDA Standard files used — มี path จริง? มี content จริง?
- [ ] Pipeline trace — มี 5 stage: Understand → Plan → Execute → Verify → Handoff?
- [ ] Commands run — มี actual commands + exit code/result?
- [ ] Verification / Evidence — มี file paths + concrete proof?
- [ ] Limitations / Risks / Next steps — มี realistic items?

## Check 2 — No fake evidence

ตรวจว่า:
- [ ] Commit hashes มี format ถูก (40-char SHA-1)? ดู realistic?
- [ ] URLs ที่อ้างมีจริงหรือไม่?
- [ ] Test counts (3/5 passed) match กับ commands run?
- [ ] Token counts มี source ที่ track ได้หรือ self-reported?
- [ ] File paths ที่อ้างมีอยู่จริงใน project?

## Check 3 — Plan/Implement separation

- [ ] ถ้า verb คือ `bda-plan` หรือ `bda-fix` → **ห้าม** มี code change
- [ ] ถ้า verb คือ `bda-implement` → ต้องมี plan file reference + plan status: approved
- [ ] Code change ใน wrong verb → BLOCK + flag

## Check 4 — Vault-first

- [ ] AI ได้อ่าน `docs/obsidian-vault/00-Index/IMPLEMENTATION-STATUS.md`?
- [ ] AI ได้อ่าน relevant docs (PRD/Feature/Function) ก่อนถามคำถาม?
- [ ] คำถามที่ vault ตอบอยู่แล้วถูกถามใหม่ไหม? (ถ้ามี = ผิด)

## Check 5 — Language

- [ ] รายงานเป็นภาษาที่ตรงกับ `.bda-spec.yml` language config?
- [ ] Code/frontmatter/path เป็นอังกฤษ?

## Check 6 — BDA policies

- [ ] ไม่มี secret/credential leak ใน output?
- [ ] Production write ถ้ามี — มี explicit confirm?
- [ ] Shared repo modification ถ้ามี — มี explicit confirm?

---

# Verdict

| Status | Action |
|---|---|
| ✅ ALL PASS | output OK |
| 🟡 MINOR | output OK แต่แก้ที่ list ต่อไป |
| ❌ BLOCKED | output ใช้ไม่ได้ — list reasons + ขอ AI ทำใหม่ |

# Response format

```markdown
## Review verdict
<ALL PASS | MINOR | BLOCKED>

## Issues found
- [Section]: issue description

## Recommended fix
- <specific instruction to AI to re-do or adjust>
```

---

# Original response (paste below)

<AI response to review>
