
- **Divider handle**: `role="separator"`, `aria-orientation="horizontal"`, `aria-valuenow`/`aria-valuemin`/`aria-valuemax` reflecting the ratio as percentages, `tabIndex=0`. While the pane is collapsed, `aria-valuenow` keeps reporting the remembered ratio (the ratio the pane returns to), and the arrow keys do nothing.
- **Collapse button**: a real native `<button>` with `aria-expanded` (reflects `!isCollapsed`) and `aria-label` from `bottomLabel` (default "Details").
- **Keyboard support**: ↑/↓ on the focused divider nudges the ratio; Enter/Space on the button toggles collapse (native button behavior).
- **Touch targets**: The chevron glyph is 14px (header bar) or 12px (seam). On the seam, the full-width, 24px-tall transparent grab band (`h-6`, `inset-x-0`) meets the WCAG 2.5.8 minimum of 24×24 CSS px for the drag, but it does not enlarge the chevron button: that button's own hit area is the glyph plus `px-1` padding, below 24×24 (the `partial` touch-target status in Compliance). On the header bar, the whole full-width row is the drag surface; the chevron button's hit area is the same glyph plus padding.

