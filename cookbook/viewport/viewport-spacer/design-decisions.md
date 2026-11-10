
**Decision**: ViewportSpacer is a pure layout primitive: it accepts only `children` and `className`, delegates all visual styling to CSS, and relies entirely on flex layout (`flex: 1 1 0`, `min-height: 0`) for its behavior.
**Rationale**: Keeping the component's surface minimal maximizes flexibility for consuming code while making the flex-grow behavior predictable and impossible to override accidentally.
**Approved**: pending

**Decision**: Class composition always applies `vp-spacer` first and appends a caller-supplied `className` after a single space, following the common React "base class plus optional override class" pattern.
**Rationale**: This lets consuming code extend or theme the spacer without recreating the base class, and keeps the concatenation logic in one place (**class-composition**).
**Approved**: pending

