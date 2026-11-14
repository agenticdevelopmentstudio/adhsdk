
- **grouping-container**: Component MUST render a semantic grouping container as its root.
- **title-when-provided**: When a `title` is provided, component MUST render it as a heading scoped to the group.
- **title-when-omitted**: When `title` is not provided or is falsy (including the number `0`), component MUST NOT render a title element or any stray text in its place.
- **hint-when-provided**: When a `hint` is provided, component MUST render it as descriptive text within the group, adjacent to the title and body. Programmatic association with the group is platform-specific (see Accessibility and Platform Notes).
- **hint-when-omitted**: When `hint` is not provided or is falsy (including the number `0`), component MUST NOT render a hint element or any stray text in its place (see **Edge Cases**).
- **children-in-body**: Children content MUST be rendered inside a body container, distinct from the title and hint.
- **base-style-applied**: Component MUST apply its base styling identity to the root element.
- **custom-style-accepted**: Component MUST accept a caller-supplied style/class extension and combine it with the base styling identity.
- **empty-style-filtered**: When combining style identifiers, empty or falsy values MUST be filtered out before combining.

Platform-specific DOM shape and class names (the `aws-group*` BEM classes, the
`<section>`/`<h3>`/`<p>`/`<div>` elements, and the class-string join/filter
logic) are the React/Web implementation of these requirements — see
**Platform Notes**.

