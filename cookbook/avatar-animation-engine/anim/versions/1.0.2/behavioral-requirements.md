
### Arbiter: mood resolution

- **mood-source-priority**: `Arbiter.evaluate` MUST resolve the mood in
  force from exactly four sources, in this fixed priority order: an
  unexpired poke, an unexpired app-forced mood (`setMood`), an unexpired
  waking transition, and otherwise the idle ladder rung computed by
  `rungFor`. The first source that is active wins; none of the lower
  sources are consulted once a higher one applies.
- **evaluate-runs-on-every-mutation**: every public call that can change
  which source is active (`start`, `setMood`, `notice`, `poke`, `tick`
  observing an expiry) MUST re-run resolution before returning, so
  `Arbiter.state` always reflects the currently-resolved mood rather than a
  stale one.
- **idle-ladder-rung-selection**: `rungFor(now)` MUST return rung 0
  whenever `now < alertUntil` (the typing pin, below), and otherwise MUST
  return the highest-indexed rung in the ladder's ascending-by-threshold
  rung list whose idle threshold is at or below `now - lastInteraction`.
- **notice-resets-the-idle-clock**: `notice(now)` MUST set
  `lastInteraction = now`, and MUST open a waking window
  (`wakeUntil = now + waking window duration`) when the mood resolved
  immediately beforehand is the waking transition's configured starting
  mood; it MUST NOT open a waking window from any other mood.
- **typing-pin-holds-rung-zero**: `say(text, now)` MUST set `alertUntil` far
  enough past `now` to hold the idle ladder at rung 0 for the configured
  post-typing window, and MUST NOT modify `lastInteraction` while doing so
  — the typing pin holds the ladder still without resetting the interaction
  clock `notice` advances.
- **poke-rule-matching**: `poke(now)` MUST select the first configured poke
  rule whose `from` names the mood resolved immediately beforehand, and
  otherwise the first rule whose `from` is the wildcard `"*"`; when neither
  matches, `poke(now)` MUST leave the poke source inactive (aside from
  still updating `lastInteraction` and re-resolving).
- **poke-expiry-falls-back**: once a poke's expiry time has passed, the
  poke source MUST stop outranking the sources beneath it on the very next
  resolution (a subsequent `tick(now)` at or after that expiry, or any
  other call that triggers resolution), without requiring a further,
  separate caller action to clear it.
- **unknown-mood-rejected**: `setMood(mood, now)` MUST throw an error whose
  message is `"unknown mood: <mood>"` when `mood` is non-nil and is not a
  key of the loaded pose table, and MUST leave the previously-forced mood
  (if any) unchanged when it throws. `setMood(nil, now)` MUST clear the
  app-forced mood instead of throwing, unconditionally.
- **unknown-timeline-rejected**: `play(name, now)` MUST first cancel and
  clear whatever the arbiter's timeline slot currently holds (restoring any
  channel family that timeline had promoted), unconditionally, and MUST
  then throw an error whose message is `"unknown timeline: <name>"` when
  `name` is not a key of the loaded timeline table.
- **applied-mood-drives-pose-or-choreography**: on a mood change (including
  the first resolution `start` performs), the arbiter MUST cancel whatever
  timeline currently occupies its single choreography/hand-play slot, then
  MUST play the new mood's declarative timeline instead of applying a
  static pose when that mood has a configured choreography entry, and
  otherwise MUST apply the mood's static pose via `applyPose`.
- **hand-play-shares-the-timeline-slot**: `play(name, now)` and an
  arbiter-driven choreographed-mood timeline MUST share the same
  mutual-exclusion slot: starting either one MUST cancel whatever timeline
  currently occupies that slot first, so a hand-played timeline and a
  mood's own choreography can never run concurrently against the same rig.
- **spin-reset-is-the-callers-job**: when `applyPose` returns a spin reset
  (`PoseResult.resetAt`), the arbiter MUST schedule that reset itself (a
  one-shot at the reported time that writes the reported, range-normalized
  value); `applyPose` performs no scheduling on its own.
- **generation-guarded-rearm**: every self-re-arming one-shot chain the
  arbiter or reflexes own (an ambient loop, a mood effect's `stir`, a
  fidget/breathe/blink/wander cycle) MUST be guarded by a monotonically
  increasing generation counter (`gen`/`effectGen`) captured when the chain
  is armed; a fired one-shot whose captured generation no longer matches
  the live counter MUST be a no-op rather than re-arming or animating,
  which is what keeps a canceled or restarted chain from stacking duplicate
  loops.

### Params: the predicate/amplitude language

- **params-scope-is-mood-only**: every predicate, amplitude, and number
  derivation MUST be evaluated purely against `{mood}` (the resolved mood
  string and the loaded config) — it MUST NOT read live channel values,
  tween state, or scheduler time, which is what keeps the expression
  language free of feedback loops between what it decides and what it is
  deciding about.
- **predicate-vocabulary-is-closed**: `predicate` MUST support exactly the
  configured predicate kinds (including `eyesShut`, `curious`,
  `choreographed`, and the relational `gt`) and MUST NOT accept an
  unrecognized kind as anything other than an error; a config that reaches
  this evaluator with an unrecognized predicate kind is a loader-contract
  violation, not a value this function silently tolerates.
- **amplitude-and-number-derivation**: `amplitude`/`numberParam` MUST
  resolve `literal` to its literal value verbatim, `param` to the named
  parameter looked up for the current mood, and `select` to the branch
  chosen by evaluating the select's own predicate — with no other
  derivation kinds accepted.

### Poses: static pose application

- **pose-lookup-failure**: `applyPose(config, context, mood, now)` MUST
  throw the same `"unknown mood: <mood>"` error `setMood` throws when
  `mood` is not a key of the loaded pose table.
- **channel-iteration-is-sorted**: `applyPose` MUST iterate a pose's
  channel keys in sorted (not insertion, not hash) order before expanding
  and tweening each one; this is a determinism requirement, not a style
  choice — an unordered iteration would let a Swift `Dictionary` and a
  TypeScript object/`Map` observably diverge in which of several
  same-instant writes to a shared channel lands last.
- **channel-group-expansion**: every channel key a pose names MUST be
  expanded through the config's `expand` operation (a group name fans out
  to its member channels; a non-group name expands to itself) before a
  tween is added, so a pose can target a named group once and animate every
  member channel identically.
- **per-channel-delay-ladder**: each expanded channel's tween delay MUST be
  `channelDelay(config, channel)` — the channel's own configured delay
  entry when one exists, and otherwise `0` — so a pose can stagger a rig's
  channels into a wave rather than moving them all in lockstep.
- **spin-carries-its-own-timing**: when a pose declares a `spin`, the spin
  channel's tween MUST use the spin's own duration and ease (not the pose's
  general duration/ease) whenever that channel is listed among the spin's
  carried channels, animating from the channel's pose-specified value (or
  its live value, or `0`, in that fallback order) to that value plus the
  spin's configured number of full turns.
- **spin-reset-value-is-range-normalized**: the `PoseResult.resetAt` value
  `applyPose` reports for a spin MUST be the spin's ending angle normalized
  into a half-open range of one full turn (so a caller's scheduled reset
  leaves the channel wound to an equivalent, but not ever-increasing,
  angle) rather than the raw, ever-growing turn-accumulated value the spin
  tweened to.

### Reflexes: ambient and mood-driven motion

- **prng-draws-only-at-scheduled-events**: every random draw Reflexes makes
  (a blink wait, a wander target, a fidget jitter, a mood-effect branch or
  amplitude) MUST happen inside a scheduled callback (a `Scheduler.once`/
  `every` handler), never inside a per-frame tick, so the random stream
  consumed is identical regardless of display refresh rate.
- **per-channel-independent-blink**: `armBlink` MUST arm one independent
  re-arming chain per channel the blink group expands to (so a multi-eye
  rig blinks each eye on its own timer rather than in forced unison), and
  each chain MUST re-arm on every cycle regardless of whether the current
  mood suppresses the blink for that cycle.
- **blink-restores-the-pre-close-value**: a blink chain MUST reopen the
  channel to whatever value it held immediately before the chain closed it
  (captured at close time), not to a fixed rest value, so a posed value
  (such as a squint) already on that channel survives a blink.
- **gaze-shut-suppresses-look-and-wander**: `applyGaze` and `wander` MUST
  both no-op whenever the current mood satisfies the gaze-disabled
  predicate; `wander`'s own re-arm MUST still occur on schedule regardless
  of that outcome.
- **wander-levels-without-turning-the-head**: `wander`'s re-centering step
  MUST level the head rotation and recenter the lean offset directly,
  without invoking `applyGaze`, so a wander event that recenters never
  turns the head — only the eyes move under `wander`.
- **fidget-jitters-from-live-value-and-settles-back**: while
  `fidgetActive()` is true, the fidget chain MUST jitter each configured
  channel by a signed random offset from that channel's own live value
  (not from a fixed rest value) and, after the drawn duration, MUST settle
  every jittered channel back to the value it captured as that cycle's
  base — except a channel flagged pose-owned, which the settle MUST skip
  once fidget is no longer active by the time the settle fires, so a mood's
  own posed brows are not fought by a stale fidget settle.
- **breathe-yoyos-then-settles-on-deactivation**: while its activation
  predicate holds, `breathe` MUST yoyo the breath channel(s) between the
  configured `from` and `to` on the configured duration; once the predicate
  no longer holds, it MUST tween back to `from` over the configured settle
  duration/ease and MUST stop re-arming.
- **mood-effect-replaces-the-previous-one**: `startEffect` MUST first
  settle every channel the previous mood effect left off its rest value
  (using the incoming effect's own settle timing) before installing the new
  effect, and MUST bump the effect generation counter so any pending `stir`
  chain from the previous effect becomes a no-op.
- **stir-branch-selection**: `stir` MUST choose between a `then`/`else`
  step list by drawing a seeded Bernoulli value against the effect's
  configured `branch.probability` when a `branch` is present, and MUST
  default to the `"twitch"` step list when no branch is configured; if the
  chosen key names a step list the effect does not define, `stir` MUST end
  that chain silently (no error, no re-arm) rather than treating the
  missing list as empty steps to play.
- **effect-steps-play-in-sequence**: `playSteps` MUST play an effect's
  steps one after another — the next step's channels MUST NOT be written
  until the previous step's full duration has elapsed — and, within one
  step, MUST resolve every channel key in sorted order, sharing one PRNG
  draw across every concrete channel a `.rnd` value's group name expands
  to.
- **stop-effect-tears-down-immediately**: `stopEffect` MUST clear the
  active effect, bump the effect generation counter, stop the effect's own
  loop (if any) through the same generation-guarded bookkeeping an ambient
  loop uses, and settle every channel the effect touched to the rig's own
  rest value for that channel — without animating the settle through a
  tween when `Reflexes.stop()` itself is the caller (full engine teardown
  writes rest values directly).
- **pinprick-tick-is-idempotent**: `pinprickTick` MUST write a tween only
  when a pinprick node's shown/hidden state actually flips against its
  `shownWhen` predicate; it MUST NOT re-issue a tween on a poll where the
  state is unchanged from the previous poll.
- **mutter-always-rearms**: `mutterTick` MUST re-arm itself on the
  configured mutter interval regardless of the current mood, invoking the
  injected `mutter` callback only when the current mood is one of the
  configured mutter-eligible moods; deciding whether that instant actually
  produces output is the injected callback's responsibility, not
  `mutterTick`'s.
- **restart-is-idempotent**: calling `Reflexes.start(now)` while already
  started MUST cancel the previously-armed poll before re-arming it (not
  double-arm it), matching the same cancel-before-arm rule `Arbiter.start`
  applies to its own poll.
- **stop-cancels-every-outstanding-chain**: `Reflexes.stop()` MUST cancel
  every pending scheduled one-shot and the poll, clear every running/active
  flag (fidget, breathe, the active mood effect), and, for every channel an
  active effect had moved off its rest value, cancel that channel's live
  tween and write its rest value directly.

### Timelines: declarative playback

- **timeline-lookup-failure**: `playTimeline` MUST throw an error whose
  message is `"unknown timeline: <name>"` when `name` is not a key of the
  loaded timeline table.
- **steps-scheduled-from-a-single-anchor**: every step in a timeline MUST
  be scheduled as one `Scheduler.once` at `now + step.at`, where `now` is
  the instant `playTimeline` itself was called — never relative to a
  previous step's actual fire time — so a delayed frame cannot cascade
  timing drift down a timeline's later steps. Timeline steps never apply
  the pose per-channel delay ladder; each step's timing is authored
  explicitly.
- **family-write-precedes-the-tween**: a step that declares a `family`
  MUST write that node's family-tracking channel before adding its tween,
  so anything reading the family and the animated value together within
  the same scheduled callback observes them already paired.
- **promote-is-reversible-or-silently-skipped**: a step that declares a
  `promote` MUST re-express the channel's current value into an equivalent
  all-cubic path of the requested segment count when that value is a path
  string, and MUST record the pre-promote value the first time a promote
  succeeds for a given channel so `cancel()` can restore it exactly; when
  the channel does not currently hold a promotable path value, the promote
  step MUST be skipped silently for that channel (no tween, no write, no
  thrown error).
- **cancel-restores-only-what-still-belongs-to-it**: `TimelineHandle.cancel()`
  MUST cancel every not-yet-fired scheduled step (and the optional
  completion one-shot), and, for every node the timeline promoted a family
  for, MUST restore the rig-declared family and the exact pre-promote path
  text — but only when that node's family channel still names the family
  this timeline set; if a later write has already changed it, `cancel()`
  MUST leave that node alone rather than overwriting a newer state.
- **completion-callback-is-cancellable**: a timeline's optional completion
  one-shot MUST NOT fire once `cancel()` has removed it, even if `cancel()`
  is called after the timeline's steps have all fired but before the
  completion one-shot's own deadline.

### Ordering and concurrency

- **fixed-per-frame-tick-order**: a host driving this component MUST
  advance `Scheduler.tick(now)` before invoking the arbiter's/reflexes'
  own per-frame hooks, and MUST advance `Tweens.tick(now)` after both, on
  every frame — the same order the shared test harness uses
  (`scheduler.tick → arbiter.tick/poll callbacks → tweens.tick`). Reversing
  or interleaving this order is not covered by any source-level guard and
  produces undefined write ordering on channels touched by more than one
  of the three stages in the same frame.
- **single-caller-threading**: `Arbiter` and `Reflexes` declare no actor
  isolation, lock, or `Sendable` conformance in the given sources; a host
  MUST confine all calls into a given instance (including the scheduler
  and tween ticks that drive it) to one logical caller at a time. Calling
  the same instance concurrently from more than one thread/task is
  undefined by the source, not merely unsynchronized.
- **no-persistence-or-caching**: neither Arbiter nor Reflexes persists any
  state across process restarts; all state (`ArbiterState`, `SpeechState`,
  generation counters, armed scheduler ids) lives only in memory for the
  instance's lifetime and is rebuilt from the loaded `CharacterConfig` on
  the next `start(now)`.
- **side-effects-are-channel-and-scheduler-only**: the only side effects
  either type performs are: writing channel values (directly or through a
  `Tweens` tween), scheduling or canceling `Scheduler` entries, and reading
  from the injected `Prng`. Neither type performs file, network, or process
  I/O, and neither reads or writes any persistence layer.

- **gaze-input-validation**: NEEDS REVIEW: Not implemented in source. `Reflexes.look(x, y, now)` clamps its inputs toward `[-1, 1]` but does not validate that `x`/`y` are finite numbers; a non-finite (`NaN`/`Infinity`) coordinate from the host passes the clamp unchanged (both platforms' clamp forms leave `NaN` as `NaN`) and is then written into a gaze channel, where it can permanently corrupt that channel's tween interpolation (`lerpValue`'s numeric branch and the tween progress calculation both propagate `NaN` once introduced, with no recovery path in the given sources); the contract does not say whether the host is required to pre-validate pointer input or whether `look`/the params/tween layer should reject or sanitize a non-finite value itself.

