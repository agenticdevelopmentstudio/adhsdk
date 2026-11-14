
- **Size**: SVG viewBox is 5, 1, 14, 22 (width 14 units, height 22 units). Rendered size is controlled by the companion CSS custom property `--pc-rm-size` (default `34px` wide; height follows automatically via `aspect-ratio: 14 / 22`, i.e. `34×53.4px`). A caller override such as `--pc-rm-size: 56px` yields `56×88px`, keeping the artwork's 14:22 ratio at any density.
- **Glyph**: JetBrains Mono @ (weight 400), embedded as precise SVG path, no live font dependency.
- **Star**: Four-pointed concave star (N/E/S/W points, independent x/y radii rx=4.0, ry=6.6, centered at 14.1, 12.2).
- **Glyph fill**: `currentColor` (inherits tint from ancestor).
- **Star fill**: `#c4a35a` — ADH gold, the toolkit's fixed brand-accent color reserved for AI/registry credential marks (hex literal, not a theme token; see Design Decisions).
- **Positioning anchor**: Center point of @ glyph is (12, 12) in viewBox; CSS custom props `--pc-rm-anchor-x: 50%` and `--pc-rm-anchor-y: -50%` place this anchor at host's top-right corner.
- **Popover offset**: Popover (when rendered) displays above the mark, positioned via CSS (not inline).

