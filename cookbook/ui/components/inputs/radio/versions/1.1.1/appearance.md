
- **Size**: 16×16px (size-4 in Tailwind)
- **Corner radius**: Fully rounded (50% / `rounded-full`)
- **Padding**: None (control is sizing-based)
- **Font**: N/A (no text in the control itself; label text is external)
- **Background**: `apt-bg` (theme token for default state background)
- **Border**: 1px solid `apt-border` (default state); 1px solid `apt-gold` when checked or focused
- **Ring**: 2px, `apt-gold` at 25% opacity, shown on focus-visible only
- **Indicator**: 8×8px inner circle, `apt-gold` when checked; hidden when unchecked
- **Shadow**: None
- **Min/Max size**: Fixed at 16×16px; shrink-0 prevents size changes due to flex containers
- **Transition**: All color changes transition smoothly via CSS transitions

