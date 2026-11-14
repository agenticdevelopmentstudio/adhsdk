
- **Empty/omitted `moods.bored`/`moods.asleep`**: The idle ladder still
  reaches `"bored"`/`"asleep"`, but `resting` falls back to `moods.idle` for
  those rungs (**mood-map-fallback**). This MUST hold — it is the source's
  only defined behavior for a partial `MoodMap`.
- **`effective` has no entry in `poses` and no `choreography`**: `applyPose`
  is never called for that render; the rig keeps whatever pose it last
  applied rather than resetting to a neutral pose. This MUST hold
  (**pose-application-on-mood-change**) — it is a real, if surprising,
  consequence of the `if (pose)` guard in `engine.ts`.
- **`poke` omitted, or configured but returns `null`**: `poke()` is a
  permanent no-op in both cases; the two are indistinguishable to a caller
  and both MUST behave identically (**poke-invocation**).
- **`waking` omitted**: No waking one-shot logic ever runs; `effective` is
  simply `reaction ?? resting` (**waking-trigger-condition**'s guard clause
  short-circuits on `waking` being falsy).
- **Rapid repeated `poke()` calls**: Each call cancels the previous call's
  pending clear-timer and starts its own; only the most recently accepted
  reaction is ever shown, cut short of its own `ms` if superseded again
  before it elapses (**poke-supersedes-pending-reaction**).
- **A poke arrives during a waking one-shot**: The click reaction wins
  (**effective-mood-priority**); the waking one-shot keeps its own pending
  timer running underneath and can resurface once the reaction clears, if
  its `ms` has not yet elapsed and `effective` hasn't moved on.
- **`effective` changes on every ladder poll near a threshold**: Each change
  kills every previously tracked loop tween immediately, even one that has
  not completed a cycle (**pose-application-on-mood-change**); there is no
  debouncing of rapid mood churn.
- **`rig` wires only `svg` + `pivot`**: every dependent effect (blink
  collapse, all of gaze, the idle fidget, every `applyPose` channel) is a
  guarded no-op; the engine still returns `{ effective, resting, speech,
  poke }` without throwing (**pose-channel-guard**, **gaze-optional-channel-noop**).
- **`waking.ms`, `poke(...).ms`, or a `tuning.*Ms` value is `0` or
  negative**: `setTimeout`/`setInterval` with a non-positive delay fires on
  the next tick; the source performs no clamping or validation of these
  caller-supplied durations.
- **Two `useAvatarEngine` instances mounted at once (two avatars on one
  page)**: Each instance registers its own `pointermove`/`pointerdown`/
  `keydown`/`mouseleave` listeners and its own timers; there is no shared or
  deduplicated listener, so both avatars react to the same cursor/keyboard
  activity independently and simultaneously.
- **Typing-grace window elapses in a backgrounded tab**: `alertAfterTypingMs`
  is measured against `Date.now()`, so a throttled/delayed poll tick still
  computes the correct elapsed time once it does fire; the grace window is
  not extended or shortened by tab visibility.
- **Malformed `Pose`/`Tuning` values crossing a non-TypeScript boundary**: passed through unchecked; see **pose-shape-validation** above.
- **Mismatched MorphSVG point counts across a mood's poses**: handed to MorphSVGPlugin unchecked; see **morph-point-count-validation** above.
- **Concurrent access**: Not applicable in the multi-thread sense — the
  engine runs entirely on the single browser main thread; "concurrency" here
  means overlapping timers/effects (covered above), not shared-memory
  contention, and the source contains no locks or atomics because none are
  needed (**concurrency-model**).
- **Offline/disconnected state**: Not applicable — the engine makes no
  network requests and has no notion of connectivity; every side effect is
  local DOM/timer scheduling.

