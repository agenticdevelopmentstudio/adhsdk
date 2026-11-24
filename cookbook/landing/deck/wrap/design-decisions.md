
**Decision**: Compose the div's class list with `['lp-wrap', className].filter(Boolean).join(' ')` rather than a conditional ternary.
**Rationale**: `.filter(Boolean)` handles `className` being `undefined` or an empty string uniformly, without an explicit type guard, even though the `className?: string` signature already restricts the prop to those two falsy shapes at compile time.
**Approved**: pending

