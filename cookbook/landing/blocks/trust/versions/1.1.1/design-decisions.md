
**Decision**: The component is deliberately unstyled beyond `.lp-trust`/`.lp-trust li` (a wrapping flex row with small dot markers), and is not built from `Cards`.
**Rationale**: These are trust claims a visitor wants settled, not product features; boxing them like `Cards` would give them the same visual weight as the product's actual capabilities, which the source comment explicitly rejects.
**Approved**: pending

**Decision**: Items are keyed by array index (`key={i}`) rather than a caller-supplied stable key.
**Rationale**: The component has no identity to key on for arbitrary `ReactNode` entries; index keys are adequate for the typical static list, but they mean an item's identity (and any item-local state) is not preserved if the `items` array is reordered between renders.
**Approved**: pending

