
- **Layout**: 3×3 grid with center column and row empty, four arrow buttons at cardinal positions.
- **Button style**: Accessory bar action (AppKit system style).
- **Button content**: System symbol image only (SF Symbols), no text or border.
- **Grid spacing**: 2pt between rows and columns.
- **Padding**: 8pt on all sides (top, leading, trailing, bottom) around the grid.
- **Icon color (enabled)**: Primary text color from current theme (`palette.nsColor(.primaryText)`).
- **Icon color (disabled)**: Tertiary text color from current theme (`palette.nsColor(.tertiaryText)`).
- **Border**: None.
- **Popover anchor**: The popover is anchored to the invoking control, preferring the edge nearest available screen space. The reference AppKit implementation anchors from the `.minY` edge of the anchor view's bounds, in that view's own (typically flipped) coordinate space.

