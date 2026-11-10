
**Decision**: The strip renders at a fixed width of `PaneMinimizedStripView.thickness` (28 points).
**Rationale**: The width accommodates a 16×16 glyph with 6 points of padding on each side (28 − 16 = 12, split evenly) and keeps a row of minimized panes aligned. This size reads as "a pane is present" without taking excessive screen space.
**Approved**: pending

**Decision**: The vertical hairline is placed on the inward side (interior) of the strip, determined by the `edge` parameter at initialization.
**Rationale**: This avoids doubling a line at the window edge. The `edge` parameter drives this decision at initialization time and cannot be changed post-construction (see **hairline-inward**).
**Approved**: pending

**Decision**: When no valid `symbolName` is available, the glyph falls back to `square.dashed`.
**Rationale**: Provides a safe default when a pane does not implement `PaneMinimizedRepresenting` or supplies an invalid symbol. A completely empty strip would be unidentifiable to users.
**Approved**: pending

**Decision**: Changes to `symbolName` and `tooltip` apply immediately, with no debouncing.
**Rationale**: The source applies changes immediately in `didSet` observers. Rapid changes are rare in practice; if debouncing is needed, the client should throttle updates before setting properties.
**Approved**: pending

**Decision**: The restore button uses `NSButton`'s `.accessoryBarAction` bezel style, borderless, image-only.
**Rationale**: A platform convention for small chrome buttons in narrow spaces; provides appropriate sizing and appearance for the restore action.
**Approved**: pending

**Decision**: Colors update through `observeTheme` closures rather than an external notification the client has to wire up.
**Rationale**: `observeTheme` applies the palette synchronously at registration and again on every theme-change notification, so the component stays visually consistent without requiring external updates (see **theme-colors**).
**Approved**: pending

**Decision**: `init(coder:)` is unavailable; the view is only constructed programmatically via `init(edge:symbolName:tooltip:)`.
**Rationale**: The component is designed for programmatic use in layout code, not for instantiation from `.xib` or `.storyboard` files; this keeps the interface focused and enforces the layout-by-code pattern.
**Approved**: pending

