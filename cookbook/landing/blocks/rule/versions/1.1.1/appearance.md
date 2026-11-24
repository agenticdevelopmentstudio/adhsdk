
- **CSS class**: `lp-rule`, defined in `packages/web/packages/landing/src/css/blocks.css`, applied to the root `<dl>` element; all visual styling is delegated to this stylesheet.
- **Layout**: two-column grid — a content-sized term column and a flexible detail column — collapsing to a single stacked column below a 34rem viewport width.
- **Term (`<dt>`)**: uppercase, `0.14em` letter-spacing, `0.68rem` font size, muted accent color (`--lp-accent`).
- **Detail (`<dd>`)**: sentence case, `0.85rem` font size (inherited), font-weight 300, primary ink color (`--lp-ink`); an embedded `<b>` uses a brighter accent color and weight 400.
- **Semantic structure**: Markup uses `<dl>`, `<dt>`, and `<dd>` elements; appearance is determined by CSS, not the component.
- **No inline styles**: Component applies no inline styles or className overrides beyond the `lp-rule` class.

