
**Decision**: Use Base UI's `ToggleGroup` + `Toggle` primitives rather than a bespoke button row.
**Rationale**: Reusing the Base UI primitive gives correct pressed semantics and roving-focus keyboard support for free and keeps the control consistent with the family's other base-ui primitives (radio/switch).
**Approved**: pending

**Decision**: Build the group container on the shared `fieldShellClass`.
**Rationale**: Borrowing the field shell lets a segmented control read as a peer of the other form fields rather than a loose row of buttons.
**Approved**: pending

**Decision**: Treat single-select as a `value={[selected]}` convention on the same component rather than a separate variant.
**Rationale**: Base UI's value is always `string[]`; documenting the `value={[selected]}` + `next[0]` + ignore-empty pattern lets one component cover both single- and multi-select instead of forking a single-select variant.
**Approved**: pending

**Decision**: Give the pressed item a single gold fill treatment (`bg-apt-gold` + `text-apt-bg`).
**Rationale**: A single, token-only pressed treatment reads clearly against the muted rest state without per-item color rules.
**Approved**: pending

