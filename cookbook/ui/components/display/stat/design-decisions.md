
**Decision**: Ship `StatRow` (baseline row) and `Stat` (right-aligned column) as two
separate exports sharing one `StatProps` and `statValueVariants`.
**Rationale**: A dashboard card and a hero strip render the same figure look without a
mode prop.
**Approved**: pending

**Decision**: Bound `tone` to a cva with the seven family status tokens, and give
`valueClassName` as the escape hatch for anything outside that set.
**Rationale**: The `tone` variant covers the common, themable cases; a caller needing
a categorical hue outside that set uses `valueClassName`, which merges after the tone
class — avoiding a variant explosion.
**Approved**: pending

**Decision**: Give the label a distinct micro-caption class instead of reusing the
form-field caption.
**Rationale**: This is a display label under/beside a figure, not a field name, so it
should read as chrome around the number — intentionally smaller and dimmer than the
form-field caption.
**Approved**: pending

**Decision**: Render the value in a big, mono, bold weight with `leading-none`.
**Rationale**: Monospace, bold, large, tight leading keeps columns of figures aligned
and makes the number the visual anchor.
**Approved**: pending

