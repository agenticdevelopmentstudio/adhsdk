
**Decision**: Render a semantic `<hr>` element and delegate all visual styling to CSS classes, rather than a styled `<div>`.
**Rationale**: The `<hr>` element is recognized as a separator by assistive technologies, and delegating styling to the `{{app_prefix}}-divider` class plus an optional `className` prop keeps the component minimal while allowing flexible styling.
**Approved**: pending

