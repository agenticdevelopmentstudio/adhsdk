
- **row-input**: The cell MUST draw exactly the `row` it is given (`CommitGraphLayout<String>.Row?`) and nothing when it is `nil`. Setting a different row MUST invalidate its intrinsic size and redraw it.
- **width**: `intrinsicContentSize.width` MUST be `row.width × columnWidth` (`columnWidth` = 14 pt), 0 for no row; the height MUST be `NSView.noIntrinsicMetric`, so the row height comes from the table.
- **geometry**: Column `c`'s centre MUST be at `x = (c + 0.5) × columnWidth`; the commit's centre at `y = bounds.midY`. Each `top` segment MUST run from `(x(from), top edge)` to `(x(to), midY)`; each `bottom` segment from `(x(from), midY)` to `(x(to), bottom edge)`.
- **lane-colour**: Each segment and the node MUST be stroked or filled with `SemanticPalette.laneColor(lane)`, which cycles the theme's ANSI slots `1, 2, 3, 4, 5, 6, 9, 10, 11, 12, 13, 14` by `lane mod 12`, falling back to the `accent` role for a slot the theme lacks.
- **node**: A commit with one parent or none MUST draw a filled circle; a merge (two or more `bottom` segments leaving the commit's column) MUST draw a ring, its centre left unpainted.
- **theme**: The cell MUST repaint on every theme change, through `ThemePaletteObserver` (`observeTheme`).

