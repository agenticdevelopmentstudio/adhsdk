
- **Decision**: Combine class names using an array filter-and-join pattern (`[defaultClass, className].filter(Boolean).join(' ')`).
  **Rationale**: Prevents invalid or malformed `class` attributes (e.g., a trailing double space from a falsy `className`) while keeping the implementation simple and readable.
  **Approved**: pending

- **Decision**: Use a `<p>` element as the component's root, rather than a `<div>` or `<span>`.
  **Rationale**: Preserves semantic meaning in the document outline and ensures screen reader compatibility; `<div>` or `<span>` would lose that semantic information.
  **Approved**: pending

- **Decision**: The `aws-explanation` class is fixed and not configurable per instance.
  **Rationale**: The `.aws-explanation` rule is defined once in the user-settings stylesheet (`styles.css`) and shared with sibling components (Panel, Group, Field, Header, Divider, Stack, Hint) through the `:where(...)` rule, keeping visual consistency across the settings panel; per-instance overrides would fragment that consistency.
  **Approved**: pending

