
- **Layout**: Explicit three-column grid (`grid-template-columns: repeat(3, minmax(0, 1fr))`) at viewport widths ≥34rem; a fourth entry wraps onto a new row rather than forcing a fourth column. Below 34rem the grid collapses to `grid-template-columns: minmax(0, 1fr)` and entries stack one per row. The column count is declared explicitly rather than derived from an `auto-fit`/`auto-fill` floor — see Design Decisions. Defined in `packages/web/packages/landing/src/css/blocks.css`.
- **Container**: `dl` with class `lp-stats`.
- **Grid item**: Each entry is wrapped in its own `div`. That wrapper carries no class of its own — the `lp-stats` class lives on the `dl`, and the wrapper is styled only through the `.lp-stats div` descendant selector in `packages/web/packages/landing/src/css/blocks.css`.
- **Term (`dt`)**: No specific padding, font, or color defined in component; defer to CSS rules via `lp-stats` class.
- **Detail (`dd`)**: No specific padding, font, or color defined in component; defer to CSS rules via `lp-stats` class.

