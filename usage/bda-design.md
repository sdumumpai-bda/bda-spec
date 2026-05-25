# /bda-design

> **Design system** — tokens + components + patterns + preview.html (Storybook-lite single-file)

[← กลับ usage/README](./README.md) · [Full spec: `.bda-spec/commands/bda-design.md`](../.bda-spec/commands/bda-design.md)

## เมื่อไหร่ใช้

- เริ่ม project ที่มี UI — bootstrap design system ก่อน frontend dev
- ปรับ brand colors / typography / spacing (tokens)
- เพิ่ม component ใหม่ (ก่อน frontend/mobile implement)
- ตรวจ implementation vs DS (audit)

> **สำคัญ:** หลังมี DS แล้ว → frontend/mobile subagent **ถูกบังคับใช้** — ad-hoc styling ถูก refuse

## Quick start

```
/bda-design init
```

ตัวอย่าง output:
```
ถามทีเดียว 5 คำถาม:
  1. Brand colors (primary/secondary/accent hex)
  2. Typography (font family หลัก + code font)
  3. Style (minimalist/playful/corporate/dark-first)
  4. Framework (React/Vue/Svelte/Flutter/SwiftUI/Compose)
  5. Target users (consumer/professional/a11y-critical)

→ สร้าง 7 ไฟล์ใน docs/obsidian-vault/70-Reference/DesignSystem/
→ เปิด preview.html ด้วย browser ได้เลย
```

## รูปแบบเต็ม

```
/bda-design                     # interactive
/bda-design init                # bootstrap minimal DS
/bda-design tokens              # แก้/เพิ่ม tokens
/bda-design component <name>    # เพิ่ม/แก้ component
/bda-design pattern <name>      # เพิ่ม recurring pattern
/bda-design audit               # ตรวจ implementation vs DS
```

| Mode | ใช้สำหรับ |
|---|---|
| `init` | bootstrap 7 ไฟล์ + preview.html |
| `tokens` | colors, typography, spacing, radius, shadow, motion |
| `component <name>` | Button, Input, Card, Modal, Toast, … |
| `pattern <name>` | form layouts, list-detail, empty state |
| `audit` | scan source code → contrast/token/component violations |

## ขั้นตอนภายใน (Phase summary)

1. **Phase 0** — Detect state (มี folder?)
2. **Phase 1 (init)** — สร้าง 7 ไฟล์ + ถาม batch 5 questions + generate tokens defaults
3. **Phase 2** — Extend mode (tokens / component / pattern / audit)
4. **Phase 3** — Force-use rule: update `.bda-spec.yml` `subagents.{frontend,mobile,design}: true` → subagent ถูกบังคับใช้ DS
5. **Phase 4** — Link จาก docs + update preview.html ให้ตรง DS-Tokens.md (lint rule)
6. **Phase 5** — Log checkin

## Output ที่ได้

```
docs/obsidian-vault/70-Reference/DesignSystem/
├── README.md
├── DS-Tokens.md            ← colors, typography, spacing, radius, shadow, motion
├── DS-Components.md        ← Button, Input, Card, Modal, Toast, …
├── DS-Patterns.md          ← form, list, detail, empty-state patterns
├── DS-Accessibility.md     ← WCAG AA, contrast, focus, ARIA
├── DS-Layout.md            ← grid, breakpoints, container, spacing scale
├── DS-Voice.md             ← tone, copy guidelines, microcopy
└── preview.html            ← Storybook-lite single-file (เปิด browser ได้เลย)
```

## preview.html — Storybook-lite

- Self-contained (vanilla HTML + inline CSS + JS) — เปิดด้วย browser ตรงๆ ไม่ต้อง build
- รวม tokens จาก DS-Tokens.md เป็น CSS variables ที่ `:root { }`
- แสดงทุก component (variant × size × state matrix)
- มี light/dark theme toggle + sidebar nav
- ใช้ source-of-truth จาก DS-*.md — ห้าม diverge

## Workflow ที่นิยม

ตัวอย่าง 1: bootstrap หลัง PRD
```
1. /bda-new                          ← PRD/SRS
2. /bda-design init                   ← คุณอยู่ที่นี่
3. เปิด preview.html ดู
4. /bda-plan FEAT-X                   ← frontend agent ตอนนี้ใช้ DS แล้ว
5. /bda-implement <plan>
```

ตัวอย่าง 2: เพิ่ม component ใหม่
```
1. /bda-plan FEAT-Y                          ← plan ระบุ Design Additions: Datepicker
2. (STOP — DS ยังไม่มี Datepicker)
3. /bda-design component Datepicker          ← สร้าง spec ก่อน
4. /bda-implement <plan>                     ← agent ใช้ Datepicker ได้
```

ตัวอย่าง 3: audit เก่า
```
/bda-design audit
  → scan frontend/src/, mobile/lib/
  → report: 5 violations (3 inline color, 2 ad-hoc component)
  → docs/obsidian-vault/70-Reference/DesignSystem/audit-2026-05-21.md
```

## Gotchas / ข้อควรระวัง

- 🚫 **ห้ามแก้ source code ของ frontend/mobile** — `/bda-design` = spec, code = `/bda-implement`
- 🚫 ห้าม commit DS โดยไม่มี accessibility section
- 🚫 ห้ามใช้ color/font ที่ไม่มี explicit reference (ห้าม "AI-suggested" unverified)
- ⚠️ DS-Tokens.md เปลี่ยน → ต้อง update preview.html ใน commit เดียว (lint rule จะตรวจ)
- ⚠️ Component ใหม่ใน plan → STOP, ต้อง `/bda-design component <name>` ก่อน `/bda-implement`
- 💡 หลัง DS active → frontend/mobile agent ถูกบังคับอ่าน DS-Tokens + DS-Components ก่อน implement (gate §5.2-§5.4)

## Related

- ก่อน `/bda-design`: [/bda-new](./bda-new.md) (มี PRD ระบุ style/target users)
- หลัง `/bda-design init`: [/bda-plan](./bda-plan.md) (plan ต้องระบุ Design System Compliance section)
- Audit: [/bda-verify](./bda-verify.md) (ทำ design audit ใน Phase 6)
- Subagent: [`.claude/agents/design.md`](../.claude/agents/design.md), `frontend.md`, `mobile.md`
- Vault path: `docs/obsidian-vault/70-Reference/DesignSystem/`

## FAQ

**Q: ถ้าทีมยังไม่มี brand guideline?**
A: ใช้ "defaults" — tokens generic จาก template ปรับทีหลังด้วย `/bda-design tokens`

**Q: ทำไมไม่ใช้ Storybook จริง?**
A: bda-spec philosophy = single-file + source-driven จาก markdown — preview.html อ่านจาก DS-*.md เปิด browser ได้เลย ไม่ต้อง npm install

**Q: ถ้า frontend แก้ inline style จะเป็นยังไง?**
A: `frontend` subagent §5.3 refuse ถ้าไม่ใช้ token — `/bda-design audit` จะ flag

**Q: ใช้ DS กับ Flutter ได้ไหม?**
A: ได้ — Phase 1 ถาม framework → component examples generate ตาม (Flutter, SwiftUI, Compose, React, Vue)
