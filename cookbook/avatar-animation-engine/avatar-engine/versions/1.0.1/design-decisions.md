
- **Decision**: `Prng.pick` on an empty list crashes the host process on
  Apple (`preconditionFailure`, uncatchable) but throws an ordinary,
  catchable `Error` on web, and this recipe records both as intentional
  rather than reconciling them into one behavior.
  **Rationale**: Both source files document this as the same underlying
  contract violation — the config loader is supposed to guarantee every
  reachable mood has at least one saying, so reaching `Prng.pick` with an
  empty list means that guarantee was broken elsewhere — but each platform's
  own idiom for an "this should be impossible" failure differs: a Swift
  precondition failure versus a thrown JavaScript `Error`. Neither file
  proposes reconciling the two, and this recipe does not either.
  **Approved**: pending
- **Decision**: `Engine` exposes no explicit teardown or dispose method, even
  though its internal `Reflexes` collaborator has a `stop()` that `Engine`
  never calls.
  **Rationale**: Every scheduler closure `Arbiter` and `Reflexes` register
  captures `self` weakly (`[weak self]` on Apple; a closure over local
  bindings rather than a live object reference on web), so nothing keeps the
  engine's collaborators alive once the host drops its reference to `Engine`
  itself — ARC/GC reclaims the whole graph without an explicit stop.
  **Approved**: pending
- **Decision**: `play(name)` cancels the engine's currently-running timeline
  before validating that `name` refers to a known timeline, so an unknown-name
  call still leaves the previous timeline cancelled even though it throws.
  **Rationale**: `Arbiter.swift`'s and `arbiter.ts`'s own comments explain
  that the engine has exactly one timeline slot, shared between hand-played
  timelines and mood-choreographed ones; validating before cancelling would
  require a second code path that peeks at the timeline table without
  starting it, and would still leave the awkward question of what state a
  half-cancelled call leaves behind. Cancelling unconditionally first keeps
  the slot's invariant ("at most one timeline running") true at every
  instant, at the cost of a documented quirk in the failure case.
  **Approved**: pending
- **Decision**: `Engine.config` is a public, readable stored property on
  Apple; the web `Engine` interface has no equivalent member.
  **Rationale**: `Engine.swift`'s own comment ties this directly to a
  specific Apple-side consumer — a render layer that needs `canvas` and
  `strokeStyle` off the same engine instance it ticks, to avoid a mismatch
  where a view renders one character's canvas against another's geometry.
  The web caller has no equivalent need because it already holds the
  `CharacterConfig` reference it obtained from `loadConfig()` before calling
  `createEngine`.
  **Approved**: pending

