
- **Decision**: Band is sized to its content, not to a fixed height or viewport unit.
  **Rationale**: This distinguishes it from a full-screen container and allows bands to flex based on content, unlike the deck's `Screen`, which reasons in viewport units.
  **Approved**: pending

- **Decision**: The seam uses `clip-path` and a negative margin together, both derived from the same `--lp-seam` CSS variable (default `4.5vw`); the seam is a static visual property toggled only by the boolean `seam` prop and is never animated.
  **Rationale**: Deriving both the cut and the offset from one variable prevents them from drifting apart; keeping the seam static avoids Reduce Motion concerns entirely.
  **Approved**: pending

- **Decision**: Tones are named by their visual role (`dark`, `soft`, `paper`), not by semantic meaning (e.g., not "primary", "secondary").
  **Rationale**: Naming by role keeps the palette flexible as design systems evolve, rather than binding a tone name to a meaning that may not fit a future theme.
  **Approved**: pending

- **Decision**: `tone="paper"` always cuts its own bottom edge, regardless of the `seam` prop; `seam` controls only the top edge.
  **Rationale**: Paper is an inserted card rather than a step down in the tone rhythm, so it always wants a matching angle at its base. This is enforced unconditionally by the `lp-band--paper` CSS rule (see #requirements/paper-cuts-foot) rather than by a separate prop, since no consumer needs to opt out of it.
  **Approved**: pending

- **Decision**: Band always wraps children with `Wrap`, non-configurably.
  **Rationale**: Guarantees consistent horizontal padding and alignment across every band; a developer cannot override `Wrap`'s behavior per instance.
  **Approved**: pending

- **Decision**: `seam` defaults to `true`.
  **Rationale**: A band normally sits under a band of a different tone, where the diagonal is the page's recurring rhythm, so the common case needs no prop. The exceptions (the first band under a hero that already ends on an angle, and a band whose neighbour above has the same tone) pass `seam={false}`; see **First band on a page** in Edge Cases.
  **Approved**: pending
