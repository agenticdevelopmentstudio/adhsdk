
- **Container**: `<div class="lp-checklist">` with no inline styles; styling is via CSS class.
- **Layout**: `.lp-checklist` is a CSS grid: 1 column below a 34rem viewport width, 2 columns at ≥34rem, 3 columns at ≥58rem (`packages/web/packages/landing/src/css/blocks.css`). The column count is a fixed value chosen for the current six-group content (three per row across two full rows), not derived from the number of groups; the source notes revisiting the number if a seventh group is added.
- **Group container**: `<div>` wrapping each group heading and list, with no class or inline styles.
- **Heading**: `<h3>` with no class or inline styles.
- **List**: `<ul>` with no class or inline styles, rendered only when items array is non-empty.
- **List item**: `<li>` with optional `lp-checklist__item--soon` class (applied when `item.soon` is truthy).
- **Item text**: `<span>` containing the item's `text` ReactNode, with no class or inline styles.

