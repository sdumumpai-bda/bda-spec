# /bda-help

> **Interactive help + cheatsheet + decision tree** — ใช้เมื่อไม่รู้ว่าจะใช้ command ไหน

[← กลับ usage/README](./README.md) · [Full spec: `.bda-spec/commands/bda-help.md`](../.bda-spec/commands/bda-help.md)

## เมื่อไหร่ใช้

- เพิ่งเริ่มใช้ bda-spec — อยากดูรายการ command ทั้งหมด
- รู้ว่าอยากทำอะไรแต่ไม่รู้ command ตรงเป๊ะ
- อยาก cheatsheet 1 หน้า, decision tree, หรือ workflow card

## Quick start

```
/bda-help
```

จะถาม 1 คำถาม:
```
จะให้ผมช่วยอะไร?
  1) แนะนำ command ตามสถานการณ์
  2) อธิบาย command เฉพาะ
  3) แสดง workflow ที่พบบ่อย
  4) Cheatsheet 1 หน้า
  5) ค้นด้วย keyword
```

## รูปแบบเต็ม

```
/bda-help                          # interactive — ถาม 1 คำถาม
/bda-help <command>                # อธิบาย command ตัวนั้น (เช่น /bda-help plan)
/bda-help workflow                 # workflows ที่พบบ่อย
/bda-help workflow <name>          # workflow card เฉพาะ (new-project, bug-fix, daily, design, brownfield-adopt, submodule)
/bda-help search <keyword>         # ค้น keyword ใน commands/*.md + .claude/agents/*.md
/bda-help cheatsheet               # ตาราง 1 หน้า — command × ใช้เมื่อ × ผลลัพธ์
/bda-help tree                     # decision tree "ถ้า X → ใช้ Y"
```

## ขั้นตอนภายใน (Phase summary)

1. **Phase 0** — Detect intent (ถ้า args ว่าง → ถาม mode)
2. **Phase 1** — "แนะนำตามสถานการณ์" (batch 3-5 คำถาม)
3. **Phase 2** — "อธิบาย command เฉพาะ" (อ่าน `.bda-spec/commands/<cmd>.md` แล้วสรุป)
4. **Phase 3** — "workflows" (แสดง workflow cards)
5. **Phase 4** — "cheatsheet" (ตาราง 1 หน้า)
6. **Phase 5** — "search" (grep ใน .bda-spec/commands/ + .claude/agents/)

## Output ที่ได้

- ไม่สร้าง/แก้ไฟล์ใดๆ — `/bda-help` เป็น **read-only**
- แสดงข้อมูลในแชตเท่านั้น

## Workflow ที่นิยม

ตัวอย่าง: user ใหม่ ไม่รู้จะเริ่มอะไร
```
1. /bda-help tree           ← ดู decision tree
2. /bda-help workflow new-project  ← step-by-step
3. /bda-init                ← เริ่มจริง
```

ตัวอย่าง: user อยาก deep-dive command
```
1. /bda-help plan           ← สรุป + path ของ full spec
2. cat .bda-spec/commands/bda-plan.md  ← อ่านเต็ม
```

## Gotchas / ข้อควรระวัง

- 🚫 ห้ามแก้ไฟล์ — help เป็น read-only (ได้รับ exception จาก 5 mandatory output sections)
- 💡 ถ้า command ที่ถามไม่มีจริง → help จะ refuse (ไม่ guess)
- 💡 `/bda-help cheatsheet` คือเร็วสุดถ้ามีประสบการณ์แล้ว — รายชื่อทุก command + ใช้เมื่อ + ผลลัพธ์ ในตาราง 1 หน้า

## Related

- ทุก command ที่ help อ้างถึง → ดู `.bda-spec/commands/<name>.md` หรือ `usage/bda-<name>.md`
- README หลัก: [`../README.md`](../README.md)

## FAQ

**Q: ถามคำถามนอก scope ของ bda-spec ได้ไหม?**
A: ไม่ — help ตอบเฉพาะ command + workflow ของ bda-spec ถ้าถามทั่วไป (เช่น "Vue คืออะไร") ให้ใช้ general AI

**Q: ถ้า help แนะนำ command ไม่มีจริงล่ะ?**
A: ไม่ควรเกิด — help ผูกกับ 21 commands ที่ list ใน `.bda-spec/commands/` เท่านั้น ถ้าเจอ bug แจ้งเลย
