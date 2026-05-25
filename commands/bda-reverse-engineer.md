---
description: อ่านโค้ดที่มีอยู่แล้วสร้าง vault docs ย้อนกลับ — TechStack, API, Features, Functions (draft)
model: claude-sonnet-4-6
---

# /bda-reverse-engineer — Code → Vault Docs

อ่านโค้ดจริงแล้วสร้าง Obsidian vault docs เป็น draft สำหรับ brownfield project ที่ไม่มี spec

> **Read-only บนโค้ด** — ไม่แตะ source files เลย สร้างเฉพาะ docs ใน vault

## Trigger

```
/bda-reverse-engineer                        # scan ทั้ง project
/bda-reverse-engineer --area api             # เฉพาะ API/routes
/bda-reverse-engineer --area ui              # เฉพาะ UI components/screens
/bda-reverse-engineer --area models          # เฉพาะ domain models/schemas
/bda-reverse-engineer --area all             # ครบทุกมิติ (default)
/bda-reverse-engineer --depth shallow        # โครงสร้างอย่างเดียว (เร็ว)
/bda-reverse-engineer --depth deep           # อ่านเนื้อหาไฟล์จริง (ละเอียด)
```

ว่าง → ถาม area + depth แล้วเริ่ม scan

## Phase 0 — Project structure detection

```bash
# Manifests
ls package.json requirements.txt pyproject.toml go.mod Cargo.toml \
   pubspec.yaml pom.xml build.gradle composer.json Gemfile *.csproj 2>/dev/null

# Source roots
find . -maxdepth 3 -type d \( \
  -name src -o -name lib -o -name app -o -name api \
  -o -name server -o -name client -o -name backend -o -name frontend \
  -o -name mobile -o -name packages -o -name services \
\) 2>/dev/null | grep -v node_modules | grep -v .git

# Entry points
ls main.* index.* app.* server.* 2>/dev/null | grep -v node_modules
```

แสดง structure ที่เจอ + ถามว่าจะ scan ส่วนไหนก่อน (ถ้าไม่ได้ระบุ `--area`)

## Phase 1 — Tech stack scan

อ่าน manifest files แล้ว draft `REF-TechStack.md`:

```bash
# Node/JS
[ -f package.json ] && cat package.json | grep -A 50 '"dependencies"'

# Python
[ -f requirements.txt ] && cat requirements.txt
[ -f pyproject.toml ] && grep -A 30 '\[tool.poetry.dependencies\]' pyproject.toml

# Go
[ -f go.mod ] && cat go.mod

# Dart/Flutter
[ -f pubspec.yaml ] && grep -A 20 'dependencies:' pubspec.yaml

# Java/Kotlin
[ -f build.gradle ] && grep -E 'implementation|api' build.gradle | head -20
```

**Output draft:**
```
docs/obsidian-vault/70-Reference/REF-TechStack.md
```

ระบุเฉพาะสิ่งที่เห็นจริงในไฟล์ — ห้ามเดา version หรือ dependency ที่ไม่เจอ

## Phase 2 — API / Routes scan

```bash
# Express / Fastify / Hapi (JS)
find . -type f \( -name "routes.*" -o -name "*.routes.*" -o -name "router.*" \) \
  2>/dev/null | grep -v node_modules | head -20

# NestJS controllers
find . -type f -name "*.controller.*" 2>/dev/null | grep -v node_modules | head -20

# FastAPI / Flask (Python)
grep -r "@app\.\(get\|post\|put\|delete\|patch\)" --include="*.py" -l 2>/dev/null | head -10
grep -r "@router\." --include="*.py" -l 2>/dev/null | head -10

# Go (gin/echo/chi)
grep -r "\.\(GET\|POST\|PUT\|DELETE\|PATCH\)(" --include="*.go" -l 2>/dev/null | head -10

# Laravel (PHP)
[ -f routes/api.php ] && cat routes/api.php | head -50
[ -f routes/web.php ] && cat routes/web.php | head -50

# Rails
[ -f config/routes.rb ] && cat config/routes.rb | head -50
```

ถ้า `--depth deep` → อ่านไฟล์ route จริง extract:
- method + path (`GET /api/users/:id`)
- parameters ที่เห็น
- response shape (ถ้าเห็น)

**Output draft:**
```
docs/obsidian-vault/70-Reference/REF-APIIntegration.md
```

## Phase 3 — Domain model scan

```bash
# TypeScript interfaces / types
find . -type f \( -name "*.types.*" -o -name "*.interface.*" -o -name "*.model.*" -o -name "*.entity.*" -o -name "*.schema.*" \) \
  2>/dev/null | grep -v node_modules | head -20

# Prisma schema
find . -name "schema.prisma" 2>/dev/null

# SQLAlchemy / Django models (Python)
grep -r "class.*Model\|class.*Base" --include="*.py" -l 2>/dev/null | head -10

# Go structs (domain layer)
find . -path "*/domain/*.go" -o -path "*/model/*.go" -o -path "*/entity/*.go" 2>/dev/null | head -10

# Dart/Flutter models
find . -name "*.dart" -path "*/models/*" 2>/dev/null | head -10
```

ถ้า `--depth deep` → อ่าน fields จาก model/schema จริง

**Output draft (1 ไฟล์ต่อ domain entity ที่เจอ):**
```
docs/obsidian-vault/40-Functions/FN-<EntityName>.md   ← status: draft
```

ใส่เฉพาะ fields ที่เห็นจริง — ห้ามเดา business logic

## Phase 4 — Feature area detection

จัดกลุ่ม files ที่เจอจาก Phase 2-3 เป็น feature clusters โดยดูจาก:
- folder structure (`/checkout/`, `/auth/`, `/users/`, `/products/`)
- naming patterns (`checkout*.`, `auth*.`, `user*.`)
- route prefix (`/api/checkout/`, `/api/auth/`)

แต่ละ cluster → draft `FEAT-*.md` หนึ่งไฟล์

**Output draft:**
```
docs/obsidian-vault/20-Features/FEAT-<Area>.md   ← status: draft
```

ข้อมูลที่ใส่:
- Feature name + slug (จาก folder/prefix ที่เจอ)
- Files ที่อยู่ใน cluster นี้
- API endpoints ที่ map มา (จาก Phase 2)
- Domain models ที่เกี่ยวข้อง (จาก Phase 3)
- ส่วนที่ **ไม่รู้** (เว้นว่างไว้ให้คนกรอก): business rules, acceptance criteria, non-goals

## Phase 5 — Review checkpoint (บังคับ)

แสดง mapping ทั้งหมดก่อนเขียนจริง:

```
📋 Reverse Engineer Summary — <project>

Tech Stack:
  → REF-TechStack.md (Node.js 20, Express 4, PostgreSQL, Prisma)

API Endpoints found: 23
  → REF-APIIntegration.md

Domain Models found: 6 (User, Order, Product, Cart, Payment, Review)
  → FN-User.md, FN-Order.md, FN-Product.md ... (6 files)

Feature clusters detected: 4
  → FEAT-Auth.md       (src/auth/, /api/auth/*, User model)
  → FEAT-Checkout.md   (src/checkout/, /api/orders/*, Order+Cart+Payment)
  → FEAT-Catalog.md    (src/catalog/, /api/products/*, Product model)
  → FEAT-Reviews.md    (src/reviews/, /api/reviews/*, Review model)

⚠️  ไม่แน่ใจ (ต้องการ input จาก user):
  - src/utils/ → ไม่ชัดว่า belong feature ไหน
  - /api/admin/* → พบ endpoints แต่ไม่มี source folder ตรงกัน

สร้าง draft ทั้งหมด? [y/n] หรือ ระบุ cluster ที่ต้องการ (เช่น "Auth, Checkout"):
```

รอ user confirm ก่อนเขียนไฟล์จริง

## Phase 6 — Write vault docs

เขียนเฉพาะที่ user confirm:

- Frontmatter ทุกไฟล์ต้องมี `status: draft` และ `source: reverse-engineered`
- เนื้อหาที่ยังไม่รู้ใส่ `<!-- TODO: fill in -->`
- ไม่ overwrite ไฟล์ที่มีอยู่แล้ว — ถามก่อน

```yaml
---
tags: [type/feature]
status: draft
source: reverse-engineered
date: YYYY-MM-DD
reverse_engineered_from:
  - src/checkout/checkout.controller.ts
  - src/checkout/checkout.service.ts
---
```

## Phase 7 — สรุปและ next steps

```
✅ Reverse Engineer เสร็จ

สร้างแล้ว:
  1 × REF-TechStack.md
  1 × REF-APIIntegration.md
  6 × FN-*.md (domain models)
  4 × FEAT-*.md (feature clusters)

⚠️  Draft ทั้งหมด — ต้องตรวจและเติมก่อนใช้ plan/implement

ขั้นต่อไป (แนะนำตามลำดับ):
  1. ตรวจ FEAT-*.md — ลบ cluster ที่ผิด, เพิ่ม business rules
  2. /bda-clarify <FEAT-*.md> — scan ambiguity ใน draft
  3. /bda-new --import-prd — ถ้ามี PRD/spec เดิมอยู่ → merge เข้า vault
  4. /bda-plan <task> — เริ่มวางแผน feature แรก
```

## Output (5 หัวข้อบังคับ)

1. **BDA Standard files used** — `standards/STANDARD.md`, `standards/policies/source-of-truth.md`
2. **Pipeline trace** — Understand (Phase 0-4 scan) → Plan (Phase 5 review) → Execute (Phase 6 write) → Verify (file count check) → Handoff (Phase 7 next steps)
3. **Commands run** — `find`, `grep`, `cat` commands ที่รันจริง พร้อมผลสรุป
4. **Verification / Evidence** — list ไฟล์ที่สร้าง + source files ที่ใช้ generate แต่ละไฟล์
5. **Limitations / Risks / Next steps** — docs เป็น draft, business logic ต้องเติมเอง, ต้อง /bda-clarify ก่อน implement

## ห้าม

- ห้ามแก้ source code ใดๆ — read-only ทั้งหมด
- ห้าม overwrite vault doc ที่มีอยู่แล้วโดยไม่ถาม
- ห้ามเดา business rules, acceptance criteria, หรือ behavior ที่ไม่เห็นในโค้ด
- ห้ามเขียนไฟล์โดยไม่ผ่าน Phase 5 review checkpoint
- ห้าม mark status อื่นนอกจาก `draft` — user ต้อง promote เอง
