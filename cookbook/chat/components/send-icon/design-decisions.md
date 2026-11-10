
**Decision**: Render the arrow using `stroke` with `fill="none"`, round line caps, and round line joins, rather than a filled shape.
**Rationale**: A hollow, stroked arrow stays visible at small sizes, scales cleanly, and works on both light and dark backgrounds via `currentColor` inheritance; the round caps and joins soften the shape and make it feel less geometric.
**Approved**: pending

**Decision**: Fix the icon at 20×20 pixels via explicit `width`/`height` attributes on the `<svg>` (viewBox `0 0 24 24`), rather than exposing a size prop.
**Rationale**: A fixed size matches common icon conventions in web UI and avoids the API surface of a size prop. The tradeoff is that the icon does not automatically grow or shrink with its parent container — a caller needing a different size overrides `width`/`height` directly.
**Approved**: pending

