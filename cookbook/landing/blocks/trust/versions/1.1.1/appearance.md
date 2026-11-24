
- **Container**: Semantic `<ul>` element with className `lp-trust`; no inline styles. Visual treatment comes entirely from `packages/web/packages/landing/src/css/blocks.css`: a wrapping flex row (not a vertical stack), centered, small uppercase text (`0.72rem`, `0.14em` letter-spacing) in a dim ink color, with no border or box—lighter weight than `.lp-cards`.
- **Items**: `<li>` elements, each a flex row with a small 5px round accent-colored marker (`::before`) preceding the provided React node content; no other item-level styling.
- **Layout**: Items wrap left-to-right and center as a group (`flex-wrap: wrap; justify-content: center`), not stacked vertically; gap of `0.4rem` (row) by `1.5rem` (column) between items.

