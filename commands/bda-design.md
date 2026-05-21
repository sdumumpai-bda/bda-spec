---
description: Create or update design system (tokens, components, patterns, accessibility, layout)
model: claude-sonnet-4-6
---

# /bda-design — Design System สำหรับ project

สร้าง/อัพเดท design system ใน `docs/70-Reference/DesignSystem/` — เมื่อ design system มีอยู่ frontend/mobile subagents **ถูกบังคับ** ให้ใช้

## Trigger

```
/bda-design                     # interactive — ถามว่าจะทำอะไร
/bda-design init                # bootstrap minimal design system
/bda-design tokens              # แก้/เพิ่ม tokens (colors, typography, spacing)
/bda-design component <name>    # เพิ่ม component spec
/bda-design pattern <name>      # เพิ่ม pattern
/bda-design audit               # ตรวจ implementation vs design system
```

## Phase 0 — Detect state

```bash
test -d docs/70-Reference/DesignSystem && ls docs/70-Reference/DesignSystem/
```

| สภาพ | Action |
|---|---|
| ไม่มี folder | **Init** → Phase 1 |
| มี folder, มีไฟล์ | **Extend** → Phase 2 |

## Phase 1 — Bootstrap (init)

สร้าง:
```
docs/70-Reference/DesignSystem/
├── README.md
├── DS-Tokens.md            colors, typography, spacing, radius, shadow, motion
├── DS-Components.md        Button, Input, Card, Modal, Toast, ...
├── DS-Patterns.md          Form patterns, list patterns, detail-page patterns
├── DS-Accessibility.md     WCAG AA rules, contrast, focus, ARIA
├── DS-Layout.md            grid, breakpoints, container, spacing scale
├── DS-Voice.md             tone, copy guidelines, microcopy, error messages
└── preview.html            self-contained Storybook-lite — ดู component ทุก variant
```

**preview.html** เป็น single-file HTML ที่:
- Self-contained (vanilla HTML + inline CSS + JS) — เปิดด้วย browser ตรงๆ ไม่ต้อง build
- รวม tokens จาก DS-Tokens.md เป็น CSS variables ที่ `:root { }`
- แสดงทุก component (Button × variants × sizes × states, Input, Card, Modal, Toast, Badge)
- มี light/dark theme toggle
- มี sidebar nav ไป section ต่างๆ (Colors, Typography, Spacing, Components, Patterns, A11y)
- ใช้ source-of-truth จาก DS-*.md — ห้าม diverge

ใช้ template จาก `templates/preview.html` (หรือ `standards/templates/preview.html`)

### Bootstrap minimal — ถาม batch 5 questions:

1. **Brand colors**: primary, secondary, accent (hex) — หรือ "use defaults"
2. **Typography**: font family หลัก + font for code (Google Fonts ok)
3. **Style**: minimalist / playful / corporate / dark-first
4. **Framework**: React/Tailwind / Vue / Svelte / Flutter / SwiftUI / Jetpack Compose — กระทบ component code examples
5. **Target users**: general consumer / professional / accessibility-critical (e.g. healthcare, government)

Generate token defaults (semantic):
- Primary 50-900 (10 shades)
- Neutral 0-1000 (gray scale)
- Semantic: success / warning / error / info
- Typography scale: display, h1-h6, body, caption
- Spacing scale: 4px base (4, 8, 12, 16, 24, 32, 48, 64)
- Radius: none, sm, md, lg, full
- Shadow: sm, md, lg, xl
- Motion: timing (fast 150ms, normal 250ms, slow 400ms) + easing

## Phase 2 — Extend mode

### `tokens`
อ่าน `DS-Tokens.md` → แสดง current scale → ถามว่าจะ add/edit อะไร → update file พร้อม version bump (`tokens_version: 1.2.0`)

### `component <name>`
อ่าน `DS-Components.md` → ถ้ามี component อยู่แล้ว → edit; ถ้าไม่ → add ใหม่

Component spec template:
```markdown
## <Name>

### Purpose
<when to use, when not>

### Anatomy
- Container
- Slot/children
- Icon (optional)

### Variants
- size: sm / md / lg
- intent: primary / secondary / danger / ghost
- state: default / hover / focus / disabled / loading

### Props (framework-agnostic)
| Prop | Type | Default | Note |
|---|---|---|---|
| ... | ... | ... | ... |

### Accessibility
- Role: <button | link | ...>
- ARIA: <list>
- Keyboard: Enter / Space activates
- Focus visible: ring-2 ring-primary-500

### Tokens Used
- color: `--color-primary-500`
- spacing: `--space-3`, `--space-4`
- radius: `--radius-md`

### Example (framework-aware)
\`\`\`tsx
<Button intent="primary" size="md">Save</Button>
\`\`\`

### Don't
- ห้ามใส่ icon เกิน 1 ตัว
- ห้ามใช้ใน table cell หนาแน่น (ใช้ ghost variant)
```

### `pattern <name>`
Pattern = combination ของ components ที่ recurring (form layout, list-detail, empty state)

### `audit`
สแกน source code ที่มี (`frontend/src/`, `mobile/lib/`) — ตรวจ:
- มี style ที่ไม่ตรง token ไหม?
- มี component ad-hoc ที่ควรใช้ DS component แทนไหม?
- contrast ตามมาตรฐาน WCAG AA ผ่านไหม?
- focus state ครบไหม?
Output: report ที่ `docs/70-Reference/DesignSystem/audit-<date>.md`

## Phase 3 — Force-use rule (สำคัญ)

หลังสร้าง design system → update `.bda-spec.yml`:
```yaml
subagents:
  design: true
  frontend: true       # ถ้ามี → จะถูกบังคับใช้ DS
  mobile: true         # ถ้ามี → จะถูกบังคับใช้ DS
```

Subagent `frontend.md` และ `mobile.md` มี gate:
- §5.2 — ต้องอ่าน DS ก่อน
- §5.3 — ห้ามใส่ inline color, font, spacing ที่ไม่ map กับ token
- §5.4 — ถ้าต้อง component ใหม่ → STOP, ขอ user รัน `/bda-design component <new>` ก่อน

## Phase 4 — Link จาก docs

อัพเดท:
- `docs/00-Index/IMPLEMENTATION-STATUS.md` — เพิ่ม "Design System: v1.0.0 active + [preview](docs/70-Reference/DesignSystem/preview.html)"
- `docs/70-Reference/README.md` — link ไป DS-*.md + preview.html
- Feature/Function docs ที่มี UI → require section "Design System Compliance"

### 4.1 Generate/Update preview.html

หลัง update DS-Tokens.md หรือ DS-Components.md → **ต้อง update preview.html ให้ตรง**:

```bash
# หลัง edit DS-Tokens.md → re-emit CSS variables ใน preview.html `:root { }`
# หลัง add DS-Component → add section ใน preview.html ด้วย variant × size × state matrix
```

Workflow:
1. แก้ `DS-Tokens.md` (source of truth)
2. Reflect ใน `preview.html` `<style>:root { ... }`
3. เปิด `preview.html` ด้วย browser → ตรวจตาด้วย human review
4. Commit ทั้งคู่ใน commit เดียว (DS-*.md + preview.html ต้องไม่ diverge)

> **Lint rule (จะเพิ่มภายหลัง):** script ตรวจว่า CSS variable ใน preview.html ตรงกับ DS-Tokens.md
> ถ้า diverge → `/bda-secure` flag เป็น drift (ไม่เป็น production-blocker แต่ต้องแก้ก่อน handoff)

## Phase 5 — Log checkin

```markdown
- HH:MM — [type/design] DS init / Added component Button / Audit found 3 violations
```

## Output (5 หัวข้อบังคับ)

1. **BDA Standard files used** — `standards/STANDARD.md`, `templates/design-system.md`
2. **Pipeline trace** — Understand (Phase 0) → Plan (Phase 1 ถาม) → Execute (Phase 1/2 สร้าง) → Verify (Phase 3 force-use rule + Phase 4 link) → Handoff (Phase 5 checkin)
3. **Commands run** — Read existing DS, Write new files, git diff scan ถ้า audit
4. **Verification / Evidence** — file paths created/edited, components added count
5. **Limitations / Risks / Next steps** — "DS เพิ่งสร้าง — frontend/mobile ที่ implement ไปแล้วต้อง audit", "ปรับตาม brand guideline ตัวจริง"

## ห้าม

- ห้ามแก้ source code ของ frontend/mobile โดยตรง — design system คือ spec, implementation คือ /bda-implement
- ห้าม commit DS โดยไม่มี accessibility section
- ห้ามใช้ color/font ที่ไม่มี explicit reference (ห้าม "AI-suggested" ที่ unverified)
