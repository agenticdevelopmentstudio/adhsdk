
**Decision**: Lede is implemented as a standalone component rather than scoped to appear only under a specific heading component (e.g. `Head`).
**Rationale**: The same voice and measure (`max-width: 72ch`, see **constrain-paragraph-measure**) are wanted for the odd paragraph that follows a card grid, a chip list, or another content block, not only the one under a heading.
**Approved**: pending

**Decision**: The paragraph measure is `max-width: 72ch`.
**Rationale**: The CSS comment in `blocks.css` says 72ch is wider than the 60ch a proportional face would want, because a monospace character is narrower than the average proportional one. That reasoning does not hold: in a monospace face every glyph is exactly 1ch wide, so 72ch is exactly 72 characters per line. The value is kept as the shipped measure. Because `ch` follows the host's font, a host that changes the font-family changes the physical width of the measure.
**Approved**: pending

