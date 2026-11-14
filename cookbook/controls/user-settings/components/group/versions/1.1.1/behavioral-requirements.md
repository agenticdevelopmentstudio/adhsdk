
- **grouping-container**: Component MUST render a semantic grouping container as its root.
- **title-when-provided**: When a `title` is provided, component MUST render it as a heading scoped to the group.
- **title-when-omitted**: When `title` is not provided or is falsy, component MUST NOT render a title element.
- **hint-when-provided**: When a `hint` is provided, component MUST render it as descriptive text associated with the group.
- **hint-when-omitted**: When `hint` is not provided or is falsy, component MUST NOT render a hint element (see **Edge Cases** for the literal-zero case, which is falsy but still visible).
- **children-in-body**: Children content MUST be rendered inside a body container, distinct from the title and hint.
- **base-style-applied**: Component MUST apply its base styling identity to the root element.
- **custom-style-accepted**: Component MUST accept a caller-supplied style/class extension and combine it with the base styling identity.
- **empty-style-filtered**: When combining style identifiers, empty or falsy values MUST be filtered out before combining.

Platform-specific DOM shape and class names (the `aws-group*` BEM classes, the
`<section>`/`<h3>`/`<p>`/`<div>` elements, and the class-string join/filter
logic) are the React/Web implementation of these requirements — see
**Platform Notes**.

