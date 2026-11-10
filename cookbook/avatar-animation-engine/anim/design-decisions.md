
- **Decision**: PRNG draws happen only inside scheduled callbacks
  (`Scheduler.once`/`every` handlers), never inside a per-frame tick.
  **Rationale**: this is the only way to guarantee the exact same random
  stream is consumed at 60 Hz, 120 Hz, or after a large catch-up step —
  drawing per-tick would make the stream (and therefore every blink/wander/
  fidget/mood-effect timing and amplitude) depend on the host's frame rate,
  breaking the bit-for-bit determinism the shared `Prng` exists to
  guarantee across platforms.
  **Approved**: pending
- **Decision**: an unreachable, loader-guaranteed branch (an unrecognized
  predicate kind reaching `Params.predicate`, a spin's carried channel not
  present in the pose) traps the process via `preconditionFailure`/`try!`
  on Apple, while the TypeScript mirror throws a catchable `Error` for the
  same condition.
  **Rationale**: both platforms agree the condition can only be reached by
  a config `CharacterConfig.load` should already have rejected, so neither
  treats it as a normal, catchable runtime error; Swift's idiom for "this
  is a bug in the data that already passed validation" is a hard trap,
  while TypeScript has no equivalent zero-cost trap and uses `throw`
  instead. This is a genuine, intentional cross-platform divergence in
  failure *mechanism* (crash vs. catchable exception) even though both
  sides agree the condition itself is a contract violation, not a value to
  handle.
  **Approved**: pending
- **Decision**: `Reflexes.stop()` settles a departing effect's touched
  channels by writing their rest values directly, without animating a
  settle tween, even though `stopEffect` called during a normal mood change
  does animate that same settle.
  **Rationale**: `stop()` models a full engine teardown (the host is
  discarding the rig, not transitioning it to a new mood), so there is no
  future frame in which an animated settle would ever be seen; writing the
  rest value directly avoids leaving a tween registered against a `Tweens`
  instance the caller is about to discard.
  **Approved**: pending
- **Decision**: a timeline step's `promote` is skipped silently (no tween,
  no error) when the channel it targets does not currently hold a
  promotable path value, rather than throwing.
  **Rationale**: which pose a choreographed timeline is interrupting is not
  known in advance — that is the entire reason `promote` exists, to let a
  timeline cross out of whatever shape family it happens to land on. Ending
  the timeline (or the whole scheduled step batch) with a thrown error the
  first time an author's assumption about the interrupted pose's shape
  turns out wrong would make every mood interruption a potential runtime
  failure instead of a silently-degraded (but still safe) animation.
  **Approved**: pending
- **Decision**: `Arbiter`/`Reflexes` declare no actor isolation, lock, or
  `Sendable` conformance, and the contract instead requires the host to
  serialize `Scheduler.tick → (arbiter/reflexes) → Tweens.tick` itself.
  **Rationale**: the given sources are pure, single-threaded logic that
  assumes exactly one caller drives the fixed tick order every frame (the
  same order the shared test `Harness` uses); adding internal
  synchronization would cost every frame a lock/actor hop for a
  single-writer access pattern the host already guarantees by construction
  in both the Apple and web hosts observed. A host that violates this
  (calling into the same instance from more than one thread/task) is
  outside the contract this component defines.
  **Approved**: pending

