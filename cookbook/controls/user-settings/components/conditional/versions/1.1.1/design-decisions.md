
**Decision**: `fallback` defaults to `null` when the `fallback` prop is not provided.
**Rationale**: Simplifies the common case where no fallback content is needed; callers can omit the prop when rendering conditionally is sufficient to hide content entirely.
**Approved**: pending

**Decision**: The component renders via a fragment (`<>...</>`) rather than a `<div>` or other wrapper element.
**Rationale**: Avoids introducing an extra DOM node that would affect styling and layout, keeping the component transparent to the surrounding component tree.
**Approved**: pending

