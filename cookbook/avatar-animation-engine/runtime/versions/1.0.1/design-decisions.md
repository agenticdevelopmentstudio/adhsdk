
- **Decision**: `Scheduler`'s Apple implementation clamps a grossly overdue
  one-shot's handler argument to `now - 1.0` (`staleAfter`); the TypeScript
  implementation (`scheduler.ts`) hands the callback the true, unclamped due
  time in every case, and `scheduler.test.ts` has no test exercising this
  path.
  **Rationale**: Documented in `Scheduler.swift`'s own comments as
  deliberately closing a real failure mode — a chain of self-re-arming
  one-shots (any reflex that re-arms itself each time it fires) recovering
  from a long-stopped frame loop would otherwise replay its entire backlog at
  one link per frame, each walking a live channel by one step, which reads as
  the avatar "catching up" visibly rather than having simply lost time. This
  is a genuine, unresolved divergence between the two platform
  implementations, not a stylistic difference — a web host that stops
  receiving animation frames for an extended period (a backgrounded or
  throttled tab) and then resumes will not get the same bounded-backlog
  behavior the Swift engine gives, and no test currently protects against a
  regression on either side of this asymmetry.
  **Approved**: pending
- **Decision**: An ease name outside the fixed 24-entry vocabulary is a fatal
  error (a process trap on Apple; an uncaught exception on the web) rather
  than a fallback to a default curve or a silently-ignored tween.
  **Rationale**: The vocabulary is closed "by design — no synthesis at
  runtime" (`Ease.swift`) specifically so the same finite set of curves is
  guaranteed available on every platform; the responsibility for rejecting an
  invalid name is placed on the config loader that builds a `TweenSpec`, not
  on `Tweens` itself, which trusts its input and fails loudly rather than
  masking an authoring bug with a plausible-looking but wrong animation.
  **Approved**: pending
- **Decision**: `Tweens` resolves an unspecified `from` from the channel's
  raw stored value and does NOT pass it through `respond`, while an explicit
  `from` (like `to`) IS passed through `respond`.
  **Rationale**: A channel's stored value, when read as an implicit `from`,
  is assumed to already be in whatever space the caller renders in (it was
  either seeded directly or written there by a previous, already-mapped
  tween); mapping it a second time would double-apply `respond`. An explicit
  `from` is caller-authored data in the same "logical" space as `to`, so it
  needs the same one-time mapping `to` gets. This asymmetry is not called out
  in source comments as a rule the way rules 1-5 are numbered elsewhere in
  `Tweens.swift`, but it is directly observable from where each call site
  does or omits the `respond`/`.map { respond(...) }` wrapper.
  **Approved**: pending
- **Decision**: Neither `Tweens`/`createTweens` nor `Channels`/`createChannels`
  performs any internal synchronization, and on Apple neither class conforms
  to `Sendable`.
  **Rationale**: The reference host (`Engine`) always calls `scheduler.tick`,
  the arbiter (which may call into `tweens`), and `tweens.tick` synchronously
  from a single call to `Engine.tick`, itself driven by one render-loop
  caller; there is no concurrent-access scenario in the shipped usage this
  recipe's sources cover. A port that drives this runtime from more than one
  execution context (e.g., a background thread updating channels while a
  render thread ticks tweens) MUST add its own synchronization — nothing in
  these three files provides it.
  **Approved**: pending

