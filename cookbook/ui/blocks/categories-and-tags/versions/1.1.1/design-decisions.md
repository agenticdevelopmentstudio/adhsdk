
**Decision**: No default label or noun values — the component requires the host to supply `category.label`, `category.noun`, `tags.label`, and `tags.noun`.
**Rationale**: This avoids embedding assumptions about the semantic meaning of the fields (e.g., whether a field is for "categories" in a research system vs. "types" in a work-tracking system); the host controls all user-facing language.
**Approved**: pending

**Decision**: Share label alignment through the `--apt-field-label-w` CSS custom property rather than a fixed `labelWidth` prop.
**Rationale**: This lets sibling components (e.g., `document-identity-field.tsx`) that use the same `FIELD_LABEL_GROUP_CLASS` constant stay in alignment without duplicating the value, keeping one source of truth for the shared alignment strategy.
**Approved**: pending

**Decision**: A single `disabled` prop governs both rows.
**Rationale**: Both fields edit one logical draft or record, so they are disabled or enabled together; this prevents inconsistent states (e.g., category editable but tags read-only) and simplifies the host's state management.
**Approved**: pending

**Decision**: Neither `options` nor `value` is filtered or defaulted before being passed to the children.
**Rationale**: Empty arrays, undefined values, and missing optional properties all flow through as-is, keeping the component transparent and delegating validation and defaulting to the host.
**Approved**: pending

