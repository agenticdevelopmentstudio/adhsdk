
**Decision**: Position updates are batched via `requestAnimationFrame` rather than continuous polling or timers.
**Rationale**: Ensures computations occur at most once per display refresh cycle, minimizing layout thrashing and aligning with browser rendering constraints (see **raf-batching**).
**Approved**: pending

**Decision**: Connector stroke and fill colors are derived from the source element's computed `color` style rather than an explicit color prop, and the SVG is marked `aria-hidden="true"`.
**Rationale**: Deriving color from the source element keeps the interface minimal while allowing per-connector color customization without new props (see **source-color**). The lines are purely decorative and add no semantic value to the document structure; they support visual understanding but do not convey information necessary for keyboard or screen reader users, so hiding them from the accessibility tree is correct (see **aria-hidden**).
**Approved**: pending

