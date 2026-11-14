
- **Empty/no-op poke**: `poke(now)` when the resolved mood has neither a
  matching `from` rule nor a `"*"` wildcard rule is a fully defined no-op
  for the mood (only `lastInteraction` and the re-resolution still happen)
  — not an error.
- **Repeated `start`/`stop`**: calling `Arbiter.start`/`Reflexes.start`
  again without an intervening `stop`/teardown MUST NOT double-arm the
  shared poll (each cancels its previous poll id before re-arming); calling
  `Reflexes.stop()` when nothing is running MUST be a no-op, not an error.
- **Cancel racing a timeline's own closing snap**: calling a
  `TimelineHandle.cancel()` after that timeline's own last step has already
  restored a node's family is a no-op for that node (see
  **cancel-restores-only-what-still-belongs-to-it**) — the source treats
  this as a legitimate, reachable race, not a bug.
- **Malformed promote input**: a `promote` step whose target channel does
  not currently hold a path-shaped string value is skipped silently for
  that channel (see **promote-is-reversible-or-silently-skipped**); it does
  not throw and does not abort the rest of the timeline.
- **Mismatched-family tween**: a pose or timeline step that ends up tweening
  a path-valued channel between two values whose shape families differ
  cannot be interpolated (`avatar-engine-runtime`'s `lerpValue` has no
  anchor-for-anchor mapping between them) and SNAPS to the target instead
  of animating — this is a property of the underlying tween runtime, not of
  this component, but every pose/timeline author relies on it to make an
  unplanned mood interruption land safely.
- **Concurrent hand-play and mood-driven choreography**: calling `play(name)`
  while a mood's own choreography timeline is active cancels that mood's
  timeline first (see **hand-play-shares-the-timeline-slot**); there is no
  configuration that lets the two run side by side.
- **Non-finite gaze input**: see the open question on gaze-input-validation
  — `look(x, y, now)` does not validate that its coordinates are finite
  before clamping and writing them.

