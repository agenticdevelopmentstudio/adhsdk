
- **Decision**: the character split (`splitIntoChars`) is destructive and
  one-way: it replaces an element's `textContent` with per-character spans
  once, and neither `stop()` nor `destroy()` ever restores the original
  text node.
  **Rationale**: re-splitting on every `start()` would re-measure every
  glyph and visibly jitter the line for what the source's own doc comment
  calls "short static labels" — text that is not expected to change once
  split. The `textlensSplit` dataset flag makes the split idempotent so
  overlapping `createLens` calls over the same element are harmless, but
  the caller is responsible for not asking React to re-render text inside
  an already-split element (see the **Behaviour worth knowing** section of
  the package's own `README.md`).
  **Approved**: pending
- **Decision**: overlapping `Lens` instances are not coordinated — there is
  no module-level "active lens" registry, and two lenses over the same
  elements will both run and fight over the same inline styles.
  **Rationale**: the source's own doc comment on `createLens` states the
  alternative directly: a module-level "current lens" would silently stop
  whichever instance it decided was stale, from a place the caller cannot
  see or control. Requiring the caller to start at most one lens at a time
  makes that a visible decision at the call site (`useTextLens`'s `enabled`
  flag) instead of a hidden one inside the library.
  **Approved**: pending
- **Decision**: `resolveColor` throws rather than falling back to a default
  colour when a value cannot be read.
  **Rationale**: the source's own doc comment states this is deliberate — a
  lens that silently tints toward the wrong colour because of a typo'd
  custom-property name is exactly the class of bug likely to survive code
  review unnoticed, so an unresolvable colour is made to fail loudly, on
  the first frame, instead.
  **Approved**: pending
- **Decision**: pausing the sweep (via `pointerenter`) rests every glyph
  immediately but does not adjust the sweep's `startedAt` reference, so
  `elapsed` keeps advancing in real time for the whole duration of the
  pause.
  **Rationale**: not stated in the source — the pause's own comment
  addresses only that a glyph being read or about to be clicked should not
  keep swelling and blurring, and says nothing about whether resuming
  should catch up or continue smoothly. Compensating for paused time would
  require tracking accumulated pause duration, which the source does not
  do; the observable consequence is that a long hover can make the sweep
  resume mid-leg, or on a different leg entirely, rather than where it
  visually left off. This is carried here as a documented, deliberate-or-not
  fact about the current implementation (see the Edge Cases entry "pause
  outlives the clock"), not as a claim that it is the intended behavior.
  **Approved**: pending

