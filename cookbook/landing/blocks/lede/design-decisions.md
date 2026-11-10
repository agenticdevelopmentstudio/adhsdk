
**Decision**: Lede is implemented as a standalone component rather than scoped to appear only under a specific heading component (e.g. `Head`).
**Rationale**: The same voice and measure (`max-width: 72ch`, see **constrain-paragraph-measure**) are wanted for the odd paragraph that follows a card grid, a chip list, or another content block, not only the one under a heading.
**Approved**: pending

