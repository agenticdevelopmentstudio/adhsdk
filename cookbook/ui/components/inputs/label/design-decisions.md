
**Decision**: Use a horizontal flex layout (vertically centered, 8px gap) rather than block or inline layout.
**Rationale**: Supports flexible alignment of children and spacing, accommodating common patterns like icon + text within a label.
**Approved**: pending

**Decision**: Omit explicit padding at the component level.
**Rationale**: Allows consumers full control over spacing, supporting a wide range of container contexts.
**Approved**: pending

**Decision**: Respond to a peer element's disabled state via the CSS `:peer-disabled` selector rather than accepting a `disabled` prop.
**Rationale**: Avoids double-managing disabled state between the label and its control, and keeps the label primitive simple. See **peer-disabled-style** for the sibling-order precondition this implies.
**Approved**: pending

**Decision**: Do not style the label as disabled when a nested control is disabled; only a preceding peer control triggers the disabled style.
**Rationale**: The CSS `:peer` mechanism matches only later siblings, and adopting a `:has(:disabled)` style would widen the primitive's contract. Native ports that mirror the disabled state for nested controls will therefore differ from the web; this is an accepted limitation (see **peer-disabled-style**).
**Approved**: pending

**Decision**: Accept `htmlFor` without enforcing the association.
**Rationale**: Keeps the component a true primitive; the consumer supplies the association, and the `jsx-a11y/label-has-associated-control` lint suppression signals that this is an intentional contract rather than an oversight.
**Approved**: pending

