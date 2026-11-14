
**Decision**: Each entry is wrapped in its own `div` rather than placing `dt` and `dd` directly as children of the `dl`.
**Rationale**: This lets the CSS grid layout in `packages/web/packages/landing/src/css/blocks.css` treat each entry pair as a single grid item; the `dl` itself is not the grid container — the wrapper `div`s are the grid items.
**Approved**: pending

**Decision**: `term` and `detail` accept `ReactNode` rather than being restricted to strings.
**Rationale**: Gives the caller full flexibility to compose rich content (formatted numbers, icons, inline components) without the component prescribing a structure.
**Approved**: pending

**Decision**: The component defines no styling of its own; all visual properties (padding, font, color, layout) are delegated to CSS rules applied via the `lp-stats` class.
**Rationale**: Keeps the component focused on semantic structure; presentation is the responsibility of `packages/web/packages/landing/src/css/blocks.css` and the calling context.
**Approved**: pending

**Decision**: The three-column layout is declared explicitly (`grid-template-columns: repeat(3, minmax(0, 1fr))`) rather than derived with an `auto-fit`/`auto-fill` minmax floor.
**Rationale**: Stats lives in the narrow column of a `.lp-split` layout, where a floor wide enough to keep a long caption off four lines only fits two columns, stranding a third entry alone under an empty cell. An explicit three-column count avoids that. A `minmax` floor tuned to produce a specific column count is also arithmetic against a 14px rem that stops holding the moment the base font size changes. See `packages/web/packages/landing/src/css/blocks.css`.
**Approved**: pending

