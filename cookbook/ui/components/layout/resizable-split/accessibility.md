
- **Divider handle**: `role="separator"`, `aria-orientation="horizontal"`, `aria-valuenow`/`aria-valuemin`/`aria-valuemax` reflecting the ratio as percentages, `tabIndex=0`.
- **Collapse button**: a real native `<button>` with `aria-expanded` (reflects `!isCollapsed`) and `aria-label` from `bottomLabel` (default "Details").
- **Keyboard support**: ↑/↓ on the focused divider nudges the ratio; Enter/Space on the button toggles collapse (native button behavior).
- **Touch targets**: The chevron glyph is 14px (header bar) or 12px (seam), but the touch/click target is larger: on the seam, a full-width, 24px-tall transparent grab band (`h-6`, `inset-x-0`) meets the WCAG 2.5.8 minimum of 24×24 CSS px; on the header bar, the whole full-width row — not just the glyph — is the drag/click surface.

