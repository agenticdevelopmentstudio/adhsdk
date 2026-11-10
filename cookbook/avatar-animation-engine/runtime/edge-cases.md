
- **Never-set channel as a tween source (null/empty input).** A tween with no
  explicit `from` targeting a channel that has never been `set` MUST resolve
  its starting value to the (respond-mapped) `to` value, per
  **tween-from-resolves-from-channel** — the tween is live and completes
  normally, but produces no visible change because it starts equal to its
  target. MUST.
- **Zero or negative duration below the snap-channel path.** A duration of
  exactly `0` with `delay: 0` takes the documented immediate-apply path
  (**tween-zero-duration-immediate-apply**). Source does not special-case a
  negative `duration`: it flows into `end = start + duration` with `end <
  start`, so `write`'s `span <= 0` branch treats it as fully complete
  (`p = 1`) on the very first `tick` at or after `start` — behavior is
  defined (no crash, no divide-by-zero), just not called out anywhere in
  source as an intentional input. SHOULD (callers SHOULD NOT rely on a
  negative duration; it is unvalidated, tolerated input, not a documented
  feature).
- **Boundary: interval `<= 0` passed to `every`.** As stated in
  **scheduler-one-shot-classification**, `every(0, ...)` and `every(-1, ...)`
  both behave exactly like `once` — one fire, then removal — because `tick`
  branches on `interval <= 0`, not on which factory method was called. MUST.
- **Boundary: a channel name with no `"."`.** `snaps("pivotX")` (no dot) MUST
  return `false` — the snap rule requires a `"<nodeId>.<prop>"` shape; a bare
  property name never snaps regardless of its text. MUST.
- **Concurrent access.** None of `Channels`, `Scheduler`, or `Tweens`
  synchronizes its mutable state internally — no lock, no actor isolation,
  and (on Apple) none of the three classes conforms to `Sendable`. The
  contract REQUIRES every call into a given instance to be serialized through
  one execution context; the reference host (`Engine.tick`) satisfies this by
  calling `scheduler.tick`, `arbiter.tick` (which itself may call into
  `tweens`/`channels`), and `tweens.tick` synchronously, in that order, from
  whatever single caller drives `Engine.tick`. Calling any of these types'
  methods from more than one thread/queue/task concurrently is undefined
  behavior the source does not guard against. MUST NOT (concurrent,
  unsynchronized access).
- **Error states: unresolvable ease name.** Covered normatively under
  **tween-ease-resolution-fails-closed** — this is documented, deliberate,
  fail-fast behavior (the config loader is stated to validate every ease name
  before it reaches a `TweenSpec`), not a swallowed error.
- **Error states: a same-kind path pair that fails to parse.** `lerpValue`
  reaches its path branch only after `isPath` confirms both strings start
  with `M`/`m`; it does not otherwise validate path grammar before parsing.
  A malformed value that passes that shape check but fails `parsePath`'s
  grammar (e.g., a truncated command) reaches `try!` (Apple, traps the
  process) or an un-try/catch-wrapped `parsePath` call (web, throws
  uncaught) — the same "not reachable in practice" reasoning as the ease
  case (comments cite upstream loader invariants — `poseKind`, per-timeline
  family checks — that are not part of these three files). Given the sources
  provided for THIS component, `Tweens`/`createTweens` performs no grammar
  validation of its own and trusts every `TweenSpec` handed to it. This is
  documented, intentional trust in an upstream-enforced invariant, not an
  unresolved contract gap — but implementors on a platform without that same
  upstream loader validation MUST supply an equivalent guard before reusing
  this contract, or accept the same crash-on-malformed-input behavior.
- **Offline / disconnected state.** Not applicable: `Channels`, `Scheduler`,
  and `Tweens` perform no network access and no file I/O anywhere in
  `Channels.swift`/`channels.ts`, `Scheduler.swift`/`scheduler.ts`, or
  `Tweens.swift`/`tween.ts`; there is no connection to lose.

