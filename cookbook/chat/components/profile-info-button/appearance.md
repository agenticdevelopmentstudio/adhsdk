
- **Corner radius**: 50% (a circle).
- **Padding**: none; the glyph is centered with `display: flex`, `align-items: center` and `justify-content: center`.
- **Font**: monospace from `--pc-font-mono`; size 0.6 times the circle diameter (13.2px at the default 22px); line height 1; the glyph is the lowercase letter "i".
- **Background**: `--pc-surface`, fallback `#050805`; opaque.
- **Foreground/Text**: `--pc-persona-text`, fallback `#d0d0d0`.
- **Border**: 1px solid `--pc-input-border`, fallback `rgba(255, 255, 255, 0.35)`; on hover and focus-visible, `currentColor`.
- **Shadow**: none at rest; on hover and focus-visible, `0 0 6px` of `currentColor` mixed to 45% with transparent.
- **Min/Max size**: no min or max; the diameter is `--pc-pi-size`, default 22px.
- **Position**: absolute, `top: 0`, `left: --pc-pi-inset` (default 21px, chosen to clear the rounded corner), centered on that point by `translate(-50%, -50%)`, so half the circle overhangs the top edge. `z-index: 2`.
- **Cursor**: pointer.
- **target-size**: NEEDS REVIEW: Not implemented in source. The default 22px square sets no larger hit area, and the source does not say whether that is acceptable; a decision against the platform touch-target minimums (WCAG 2.2 AA 24px, Apple 44pt, Material 48dp) would settle it.
- **contrast**: NEEDS REVIEW: Not implemented in source. The colors come from theme tokens and fixed fallbacks, and the source cannot say whether glyph-on-face and border-on-frame meet WCAG 2.1 contrast ratios (4.5:1 for text, 3:1 for the border) in every theme; a contrast audit of each chat theme's token values would settle it.

