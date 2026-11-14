
- **Layout**: Explicit three-column grid (`grid-template-columns: repeat(3, minmax(0, 1fr))`) at viewport widths ≥34rem; a fourth entry wraps onto a new row rather than forcing a fourth column. Below 34rem the grid collapses to `grid-template-columns: minmax(0, 1fr)` and entries stack one per row. The column count is declared explicitly rather than derived from an `auto-fit`/`auto-fill` floor — see Design Decisions. Defined in `packages/web/packages/landing/src/css/blocks.css`.
- **Container**: `dl` with class `lp-stats`.
- **Grid item**: Each entry is wrapped in its own `div`. That wrapper carries no class of its own — the `lp-stats` class lives on the `dl`, and the wrapper is styled only through the `.lp-stats div` descendant selector in `packages/web/packages/landing/src/css/blocks.css`.
- **Grid**: `1rem` gap and `2rem` top margin.
- **Entry wrapper**: a hairline start-side divider (`1px solid var(--lp-hairline, rgba(216, 216, 216, 0.18))`) with `1rem` padding on that side. The web CSS writes it as physical `border-left` and `padding-left`, so it does not flip under `dir="rtl"`.
- **Term (`dt`)**: font size `clamp(1.3rem, 3vw, 1.8rem)`, weight 200, line height 1.3, color `var(--lp-accent-bright, #d8d8d8)`.
- **Detail (`dd`)**: font size `0.8rem`, letter-spacing `0.06em`, color `var(--lp-ink-dim, #a0a0a0)`.

