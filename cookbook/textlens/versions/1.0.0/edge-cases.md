
- **Null/empty input — unparseable colour string**: `parseColor` MUST return
  `null` (never throw) for `''`, a named colour, `hsl()`/`color()`, or a
  malformed hex/`rgb()` string (see **unreadable-input-returns-null**).
- **Null/empty input — no target elements or empty text**: `createLens([])`
  or `createLens` over elements whose text is empty produces zero character
  spans; a subsequent `start()` MUST return with no scheduled frame and no
  thrown error (see **empty-target-no-op**).
- **Null/empty input — selector matches nothing**: `useTextLens` MUST build
  no `Lens` at all when `selector` matches zero elements inside the
  container (see **no-elements-no-op**) — not a `Lens` that then no-ops on
  `start()`.
- **Boundary value — single-character text**: with exactly one character
  span, `firstGlyphCentre === lastGlyphCentre`, so `leftEdge`/`rightEdge`
  still diverge by `radius` on each side (`span = 2 × radius`) and the sweep
  still travels a nonzero distance across that one glyph rather than
  collapsing to a fixed point.
- **Boundary value — `blur: 0`**: with `blur` configured to `0`, the
  computed `blur` at every distance is `0`, which never exceeds the `0.03`
  floor, so `filter` is cleared unconditionally — matching the documented
  meaning of `blur: 0` ("disables it"), even though the code path is the
  same floor check every other `blur` value goes through.
- **Boundary value — `scale: 0`**: with `scale` configured to `0`,
  `transform` is written as `scale(1.000)` (a numerically neutral, but
  still-written, inline style) at every distance within `radius` — scale is
  not skipped, only rendered inert.
- **Concurrent access — overlapping lenses**: two `Lens` instances created
  over the same or overlapping elements run independently and both write
  inline styles to shared spans every frame with no coordination or
  precedence rule (see **independent-lens-instances**); the source
  documents this as the caller's responsibility (start at most one at a
  time), not a bug to be fixed internally.
- **Error state — mismatched colour ramp**: `createLens`'s `start()` throws
  synchronously when exactly one of `fromColor`/`toColor` is given (see
  **colour-ramp-pairing**). Called directly, this is a normal, catchable
  synchronous throw. Called through `useTextLens`, the same throw happens
  inside the deferred `window.setTimeout` callback that invokes
  `lens.start()`, which makes it an uncaught exception in that timer's own
  callback rather than one a `try`/`catch` around the hook call, or a React
  error boundary around the component, can intercept.
- **Error state — unreadable colour**: `resolveColor` throws for an empty or
  unparseable literal or custom-property value (see
  **resolve-throws-on-unreadable-color**); this reaches the caller through
  the same deferred-`setTimeout` path as the mismatched-ramp case when
  driven through `useTextLens`.
- **Cancellation — pause outlives the clock**: pausing (pointer-enter) rests
  every glyph immediately, but the sweep's `elapsed` clock is not paused
  (see **pause-rests-without-resetting-the-clock**); a long pause SHOULD be
  expected to make the sweep resume mid-leg (or on a different leg
  entirely) rather than resuming smoothly from the visual position it held
  when paused, because no accumulated-pause-duration bookkeeping exists in
  the source to compensate for it.
- **Cancellation — destroy while a `startDelay` timer is pending**: when
  `useTextLens`'s cleanup runs before the deferred `start()` timer has
  fired, `clearTimeout` prevents that `start()` from ever running, and
  `lens.destroy()` still runs (calling `stop()` on a lens whose `chars` is
  still `[]`, which is a no-op — see **stop-before-start-is-safe**).
- **Offline/disconnected state**: not applicable — the given sources make
  no network request of any kind (see **side-effects-are-dom-only**).

