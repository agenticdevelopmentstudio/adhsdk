
- Constructing the engine with an unrecognized `variant` string fails
  immediately at construction (propagated from the `Scene` initializer's
  validation) — the engine never reaches a `tick` call in that case.
- `setMood(nil)`/`setMood(null)` is not an error path: it is the documented
  way to release an app-level mood override back to idle-ladder/poke/waking
  resolution. Do not confuse it with an unknown mood string, which does
  throw.
- Calling `play(name)` while no timeline currently occupies the engine's
  timeline slot: the cancel step is a no-op, and the named timeline starts
  normally, since the cancel branch only runs when a handle is already held.
- A `now` passed to `tick` that is less than or equal to a previous call's
  `now` (a non-monotonic or repeated clock): the `Scheduler` this engine
  ticks first every frame tolerates this — nothing fires and no repeater's
  catch-up loop runs, deferring pending work rather than crashing or racing
  ahead.
- A large forward jump in `now` between two `tick` calls: any repeating
  scheduler entry catches up in a loop bounded at 1000 iterations rather than
  looping without bound; once that cap is hit, the entry's next-fire time is
  resynced to `now` plus its interval, silently dropping the excess
  repetitions instead of firing all of them.
- `randomSaying(mood)` for a mood string with no saying list of its own
  always falls back to the `"active"` ladder mood's list, which the config
  loader guarantees is non-empty — this path is exercised directly by
  `EngineTests.testFallsBackToTheActiveMoodsListForAMoodThatHasNone` and has
  no unhandled case in the given sources.
- If the saying list a lookup ultimately reaches is itself empty — a
  violation of the config loader's own invariant that every reachable mood
  has at least one saying — `Prng.pick` on that empty list crashes the host
  process on Apple (`preconditionFailure`, uncatchable) but throws an
  ordinary, catchable `Error` on web. Both platforms treat this as the config
  loader's contract having been broken, not as an engine-level condition to
  recover from; see the corresponding Behavioral Requirement and Design
  Decision.
- Reentrant or concurrent calls into the same engine instance (calling `tick`
  from two threads, or issuing a command from inside a scheduler callback
  running on another thread) fall outside this component's contract: every
  collaborator is a plain, non-synchronized, non-`Sendable` reference type,
  so the engine assumes single-context, one-call-at-a-time use.

