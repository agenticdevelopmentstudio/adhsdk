
**Decision**: ViewportComposer delegates keyboard-height tracking to its parent, reading the `--kb-inset` CSS custom property instead of observing the keyboard itself.
**Rationale**: Keeps the composer a simple, stateless container that responds to external state rather than managing its own keyboard observer, avoiding duplicate keyboard-tracking logic across components (see **kb-inset-read-only**) and simplifying testing and composition.
**Approved**: pending

**Decision**: Safe-area insets are read through the standard CSS environment variable (via `--safe-bottom`) rather than passed as a prop or tracked in JavaScript.
**Rationale**: Follows the same "read external state, don't own it" pattern used for the keyboard inset; the browser already exposes `env(safe-area-inset-bottom)`, so no additional plumbing is needed.
**Approved**: pending

**Decision**: Accept two failed Compliance checks as known debt for now: the 180ms `padding-bottom` transition is not gated behind `prefers-reduced-motion`, and no unit test exercises the component.
**Rationale**: The transition is declared unconditionally in `base.css` and no test exists in the package for `ViewportComposer`; both are recorded here as work to fix rather than hidden, and the recipe stays in `review` until they are resolved.
**Approved**: pending
