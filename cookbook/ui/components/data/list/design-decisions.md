
**Decision**: List and ListItem manage no internal state and enforce no content structure.
**Rationale**: Simplicity and reusability; state management is left to parent components.
**Approved**: pending

**Decision**: Both components forward all remaining props to their underlying HTML element.
**Rationale**: Allows flexible composition and styling without a bespoke prop API.
**Approved**: pending

**Decision**: Use `data-slot` attributes (`data-slot="list"`, `data-slot="list-item"`) instead of a class-based API.
**Rationale**: Enables targeted CSS and testing selectors without requiring a class-based API.
**Approved**: pending

