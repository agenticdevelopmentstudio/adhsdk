
- **CSS class**: `lp-rule`, defined in `packages/web/packages/landing/src/css/blocks.css`, applied to the root `<dl>` element; all visual styling is delegated to this stylesheet.
- **Source of truth**: `blocks.css` is the full reference for every value; the list below copies the values a port needs and the stylesheet wins if they disagree.
- **Container**: `1px` border in `--lp-hairline` (fallback `rgba(216, 216, 216, 0.18)`), corner radius `--lp-radius` (fallback `14px`), background `--lp-rule-bg` (fallback `rgba(16, 16, 16, 0.65)`), padding `1.2rem 1.35rem`, font size `0.85rem`, line height `1.8`.
- **Layout**: two-column grid — a content-sized term column and a flexible detail column — with a `1.1rem` column gap and a `0.5rem` row gap, baseline-aligned. A wrapped detail stays inside its own column. Below a 34rem viewport width it collapses to a single stacked column with a `0.15rem` row gap, and each `<dd>` gets a `0.6rem` bottom margin.
- **Term (`<dt>`)**: uppercase, `0.14em` letter-spacing, `0.68rem` font size, muted accent color (`--lp-accent`, fallback `#9a9a9a`).
- **Detail (`<dd>`)**: sentence case, `0.85rem` font size (inherited), font-weight 300, primary ink color (`--lp-ink`, fallback `#ededed`); an embedded `<b>` uses a brighter accent color (`--lp-accent-bright`, fallback `#d8d8d8`) and weight 400.
- **Semantic structure**: Markup uses `<dl>`, `<dt>`, and `<dd>` elements; appearance is determined by CSS, not the component.
- **No inline styles**: Component applies no inline styles or className overrides beyond the `lp-rule` class.

