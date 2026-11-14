
**Decision**: The bar owns its own `role="progressbar"` + `aria-value*` attributes
rather than wrapping a headless progress primitive.
**Rationale**: Progress is simple enough that the ARIA is trivial, and avoiding
an extra runtime dependency keeps the shared bundle lean.
**Approved**: pending

**Decision**: The indicator is a full-width element translated with
`translateX(-{100 - pct}%)` rather than animated via a width change.
**Rationale**: The fill animates on the compositor (`transition-transform`) and
stays crisp on its rounded ends.
**Approved**: pending

**Decision**: `value` is clamped to 0–100 inside the component.
**Rationale**: An out-of-range value from a consumer can never overflow the
track or produce a nonsensical `aria-valuenow`.
**Approved**: pending

**Decision**: The fill defaults to the `apt-gold` token but exposes
`indicatorClassName` as a dedicated recoloring hook.
**Rationale**: Context can recolor the fill (amber building → green done)
without a variant explosion.
**Approved**: pending

**Decision**: The Controls bar reports `value` verbatim as `aria-valuenow` and clamps only the fill's width.
**Rationale**: The reported value stays identical to what the caller supplied while the visual fill stays inside the track. The cost is that an out-of-range or fractional value reaches assistive technology unchanged (see Edge Cases).
**Approved**: pending

**Decision**: The Controls indeterminate mode is a fixed 35%-wide fill moved by the `aws-progress-indeterminate` keyframe, not a resizing width.
**Rationale**: The fill's geometry stays constant and only a transform animates, so no value is needed in indeterminate mode.
**Approved**: pending

**Decision**: The Controls bar does not forward arbitrary props.
**Rationale**: Its props are the fixed set `label`, `hint`, `value`, `max`, `indeterminate` and `className`, matching the other `aws-field` controls. The cost is that a consumer cannot name the progressbar (see Accessibility).
**Approved**: pending
