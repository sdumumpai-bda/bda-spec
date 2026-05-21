## <ComponentName>

### Purpose
<when to use, when not — concrete>

### Anatomy
- Container
- Slot/children
- Icon (optional)
- <other parts>

### Variants
- **size**: sm / md / lg
- **intent**: primary / secondary / danger / ghost
- **state**: default / hover / focus / disabled / loading / error

### Props (framework-agnostic)
| Prop | Type | Default | Note |
|---|---|---|---|
| ... | ... | ... | ... |

### Accessibility
- Role: <button | link | textbox | ...>
- ARIA: <attributes>
- Keyboard: <Enter / Space / arrows>
- Focus visible: <how>
- Screen reader: <expected announcement>

### Tokens Used
- color: `--color-primary-500`, `--color-text-on-primary`
- spacing: `--space-3`, `--space-4`
- radius: `--radius-md`
- typography: `--text-body-md`
- shadow: `--shadow-sm`
- motion: `--motion-fast`

### Example (framework-aware)
```tsx
<Button intent="primary" size="md" onClick={save}>
  บันทึก
</Button>
```

### Don't
- ห้ามใส่ icon เกิน 1 ตัว
- ห้ามใช้ใน table cell หนาแน่น (ใช้ ghost variant)
- ห้ามเปลี่ยนสีโดย override class
