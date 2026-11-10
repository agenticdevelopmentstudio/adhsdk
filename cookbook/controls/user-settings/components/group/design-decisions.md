
**Decision**: Appearance (color, spacing, typography, borders) is left entirely to the caller's CSS; Group applies no inline styles or built-in visual treatment of its own.
**Rationale**: Keeps the component minimal, semantically-correct, and reusable across different design contexts without imposing an opinionated look.
**Approved**: pending

**Decision**: The base class (`aws-group`) and its sub-elements (`aws-group__title`, `aws-group__hint`, `aws-group__body`) follow BEM naming.
**Rationale**: Makes the styling contract predictable and maintainable for consumers writing CSS against the component.
**Approved**: pending

**Decision**: Group accepts a caller-supplied `className` and merges it with the base class rather than replacing it, filtering out empty or falsy values before joining.
**Rationale**: Lets consumers layer additional styling onto Group without having to reimplement or fork the component.
**Approved**: pending

**Decision**: The title always renders as a fixed `<h3>` heading; there is no `headingLevel` prop to vary the depth.
**Rationale**: Matches the component's current usage context; a caller needing a different heading depth restyles or wraps Group rather than reconfiguring it, keeping the contract simple.
**Approved**: pending

