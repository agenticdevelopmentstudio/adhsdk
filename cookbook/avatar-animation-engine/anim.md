---
id: a7c91832-4059-4e06-b8c6-e8c727567c66
title: "Avatar Engine Anim"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-09-23
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Mood arbitration, procedural reflexes, mood effects, and declarative timeline playback: the deterministic animation-logic contract shared by the Swift and TypeScript avatar engines."
platforms:
  - swift
  - macos
  - ios
  - typescript
  - web
tags:
  - avatar
  - engine
  - animation
  - mood
  - reflexes
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Avatar Engine Anim

## Overview

`avatar-engine-anim` is the mood-and-motion layer of the avatar animation
engine, shared verbatim in contract between the Swift implementation
(`Arbiter.swift`, `Params.swift`, `Poses.swift`, `Reflexes.swift`,
`Timelines.swift`) and its TypeScript mirror (`arbiter.ts`, `params.ts`,
`pose.ts`, `reflexes.ts`, `timeline.ts`). It has no visual surface of its
own: it reads a loaded `CharacterConfig` and writes channel values and
tweens through the `avatar-engine-runtime` primitives (`Channels`,
`Scheduler`, `Tweens`), which a host `Engine` then renders. Five
cooperating pieces make up the contract:

- **Arbiter** decides which mood is in force at any instant, out of four
  competing sources — a poke, an app-forced mood, a waking transition, and
  an idle ladder — and applies the winner as either a static pose or a
  choreographed timeline.
- **Params** evaluates the closed predicate/amplitude/number expression
  language (`PoseNumber`/`predicate`/`numberParam`/`amplitude`/`gateOpen`)
  that poses, reflexes, and mood effects use to vary by mood, purely against
  `{mood}` — never against live channel state.
- **Poses** applies a mood's static pose: a set of channel targets tweened
  in on the pose's own duration, ease, per-channel delay ladder, and
  optional spin (a full-turn rotation that the caller must schedule a reset
  for).
- **Reflexes** drives every ambient, self-re-arming behavior that runs
  independently of an explicit mood change: blink, gaze/wander, idle
  fidget, breathe, per-mood effect loops ("stir"), pinpricks, and mutter —
  all reseeded from one shared, deterministic PRNG consumed only at
  scheduled events.
- **Timelines** plays a declarative, absolute-offset sequence of steps —
  used both for a hand-invoked `play()` call and for a mood's own
  choreography — including the reversible "family" promotion that lets a
  timeline cross an SVG-like polyline path into an all-cubic Bezier path and
  restore it exactly on cancellation.

A port of this component to a third platform is translation work: every
operation, data shape, and ordering rule below applies identically on
Apple and web, and every place the two given implementations actually
diverge is called out explicitly rather than silently favored toward one
side.

## Behavioral Requirements

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

## Appearance

Not applicable — this is a mood-arbitration, reflex, and timeline-playback
engine, not a visual component.

## States

Not applicable — this is a mood-arbitration, reflex, and timeline-playback
engine, not a visual component; its runtime state machines (the idle
ladder's rung, which mood source is currently winning, which timeline
handle occupies the choreography slot, which ambient loops/effects are
armed) are covered under Behavioral Requirements above, not as a
visual-state table.

## Accessibility

Not applicable — this is a mood-arbitration, reflex, and timeline-playback
engine, not a visual component; it has no rendered surface, focus, label, or
trait for an assistive technology to describe.

## Conformance Test Vectors

Traced to `ArbiterTests.swift`'s shared `Harness` fixture, which loads the
checked-in `dot` config, seeds `Channels`, ticks `scheduler → arbiter →
tweens` at 60 fps, and asserts against the resulting channel/state values.

| ID | Requirements | Input | Expected |
|----|---|---|---|
| avatar-engine-anim-001 | idle-ladder-rung-selection, applied-mood-drives-pose-or-choreography | Construct the harness and call `arbiter.start(0)` with no prior interaction. | `arbiter.state.idleRung == 0` and the active mood's pose is already applied to the rig (`testStartsOnRungZeroAndActuallyAppliesTheActivePose`). |
| avatar-engine-anim-002 | idle-ladder-rung-selection | Run the harness forward with no `notice`/`poke`/`say` calls past the ladder's bored threshold, then past its asleep threshold. | `arbiter.state.idleRung` climbs from 0 to the bored rung and then to the asleep rung, each transition landing on that rung's configured mood with no explicit caller action beyond the elapsed clock (`testClimbsToBoredAndThenAsleepWithNoInteraction`). |
| avatar-engine-anim-003 | notice-resets-the-idle-clock | While at the bored or asleep rung, call `notice(now)`. | `arbiter.state.idleRung` resets to 0 and `lastInteraction` updates to `now` (`testResetsTheLadderOnNotice`). |
| avatar-engine-anim-004 | mood-source-priority | Call `setMood("<validAppMood>", now)`, then later `setMood(nil, now)`. | The app-forced mood outranks the idle ladder while set, and the ladder resumes governing the resolved mood immediately after it is cleared (`testLetsAnAppMoodOutrankTheLadderAndReleasesItOnNil`). |
| avatar-engine-anim-005 | unknown-mood-rejected | Call `setMood("<nameNotInTheLoadedPoseTable>", now)`. | The call throws (`"unknown mood: <name>"`) and the previously-forced mood, if any, is left unchanged (`testRefusesAnAppMoodNoPoseDefines`). |
| avatar-engine-anim-006 | poke-rule-matching | Call `poke(now)` while the resolved mood is one with a configured poke rule whose `from` matches it. | The poke-forced mood is exactly that rule's reaction mood, not a generic default (`testPicksThePokeReactionFromTheMoodItInterrupts`). |
| avatar-engine-anim-007 | poke-expiry-falls-back | Call `poke(now)`, then advance the clock past that poke rule's configured hold window without any further call. | The poke-forced mood is in force for the whole window and the arbiter falls back to the next-highest source (app mood, waking, or the ladder) exactly once the window elapses (`testHoldsThePokeForItsRulesWindowThenFallsBack`). |
| avatar-engine-anim-008 | mood-source-priority, notice-resets-the-idle-clock | From the waking transition's configured starting mood, call `notice(now)`, then advance the clock past the waking transition's configured `ms` window. | While the window is open the arbiter plays the waking transition as a mood (a timeline/choreography); once the window elapses, mood-source-priority hands control to the idle ladder, which resolves its own rung from time-since-interaction — the arbiter does not land on the waking transition's configured `to` destination pose merely because the window ended; it lands there only when the ladder's resolved rung happens to be that same mood (`testWakesIntoWakingPlayAsAMoodAndOnlyThenLandsOnWakingTo`). |
| avatar-engine-anim-009 | applied-mood-drives-pose-or-choreography | Resolve into a mood that has a configured choreography entry. | The arbiter plays that mood's timeline instead of applying its static pose (`testPlaysAChoreographedMoodsTimelineInsteadOfItsPose`). |
| avatar-engine-anim-010 | hand-play-shares-the-timeline-slot | While a choreographed mood's timeline is mid-playback, force a mood change out from under it (via `setMood`, `poke`, or the ladder advancing). | The outstanding timeline is canceled, and any family/shape it had promoted is restored before the new mood's pose or timeline is applied (`testCancelsAChoreographedTimelineWhenTheMoodChangesOutFromUnderIt`). |

## Edge Cases

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

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `AnimContext` (`config`, `channels`, `tweens`, `prng`, deps) | struct/object, constructor argument | — (required) | The loaded `CharacterConfig`, the runtime `Channels`/`Tweens` instances, and the shared seeded `Prng` every Arbiter/Reflexes instance is built against. |
| `ReflexDeps` (`mood`, `reducedMotion`, `mutter`, and related closures) | injected callbacks | — (required) | Host-supplied functions Reflexes reads every poll: the currently resolved mood, whether reduced motion is active, and the mutter callback invoked on eligible moods. |
| `config.behavior.ladder` (`LadderDef`) | config, loaded JSON | — (authored per character) | The idle rung thresholds/moods, `pollMs` poll cadence, and `alertAfterTypingMs` typing-pin window `Arbiter`/`Reflexes` share one poll cadence from. |
| `config.behavior.poke` (`[PokeRule]`) | config, loaded JSON | — (authored per character) | Ordered `from`/`"*"`-matched poke reactions and their hold windows. |
| `config.behavior.waking` (`WakingDef`) | config, loaded JSON | — (authored per character) | The waking transition's starting mood, destination mood, and window duration. |
| `config.behavior.choreography` | config, loaded JSON, `[String: String]` | `{}` (no mood choreographed) | Maps a mood name to the timeline name the arbiter plays instead of that mood's static pose. |
| `config.poses.poses` | config, loaded JSON | — (required, non-empty) | The pose table every `setMood`/`applyPose`/ladder/poke/waking mood name is validated against. |
| `config.timelines.timelines` | config, loaded JSON | — (authored per character) | The timeline table `play`/choreography names are validated against. |
| `Prng(seed:)` seed | `UInt32` / `number` | host-supplied | Determines the entire random stream (blink waits, wander targets, fidget jitter, mood-effect branch/amplitude draws) for both platforms identically given the same seed and the same sequence of scheduled events. |
| Reduce Motion (host-read, via `ReflexDeps.reducedMotion`) | `Bool`/`boolean` | host-supplied, read every poll | Gates ambient loops, the active mood effect, and fidget/breathe activation off when true (see Accessibility Options). |

## Deep Linking

Not applicable: the given sources contain no URL, route, or deep-link
handling of any kind.

## Localization

Not applicable: the two thrown error messages (`"unknown mood: <mood>"`,
`"unknown timeline: <name>"`) are fixed, non-localized diagnostic strings
identical on both platforms, consumed by tests and caller error handling —
the source does not present them as user-facing, localizable text.

## Accessibility Options

`ReflexDeps.reducedMotion` (read every poll in `pollTick`) is the one real
accessibility-driven behavior in this component: when it reports true, the
current mood's effect is stopped rather than started (or re-started) on the
next mood/reduced-motion change, ambient loops that would otherwise be
"live" are stopped instead of armed, and fidget/breathe treat their own
activation predicates as false regardless of what those predicates would
otherwise evaluate to. This is the same code path a mood change drives
`pollTick` through — reduced motion is handled as an input to the same
gating logic, not a separate motion-disable mode. No other accessibility
setting (contrast, larger text, differentiate-without-color) is read
anywhere in the given sources.

## Feature Flags

Not applicable: the given sources read no feature-flag or remote-config
value; every branch in Arbiter/Params/Poses/Reflexes/Timelines is driven
only by the loaded `CharacterConfig`, the resolved mood, and
`ReflexDeps`.

## Analytics

Not applicable: the given sources contain no analytics, telemetry, or usage
event calls.

## Privacy

Not applicable: this component collects no user data. The only
caller-supplied content it holds is the `text` argument to `say(text, now)`,
which it keeps in `SpeechState` in memory for the bubble's own lifetime and
never persists or transmits.

## Logging

Not applicable: the given sources contain no logging calls; a failure is
communicated only through a thrown `AnimError`/`Error`, never a log line.

## Platform Notes

- **Swift/Apple**: uses `Foundation`'s `Double` for all timestamps/durations
  (no `Date`/`DispatchTime`), Swift's native `struct`/`enum`/`final class`
  for data shapes, and `throws`/`Error` for the two validated failure paths.
  An unreachable/loader-guaranteed branch (an unrecognized predicate kind,
  a spin channel not present where expected) uses `preconditionFailure`/
  `try!`, which traps the process rather than returning an error — see
  Design Decisions.
- **TypeScript/web**: mirrors every type one-for-one (`MoodSource`,
  `SpeechState`, `ArbiterState` are the same names on both sides) using
  plain interfaces/discriminated unions and `Map`/plain objects in place of
  Swift's `Dictionary`; the same unreachable/loader-guaranteed branches
  `throw` a catchable `Error` on this side instead of trapping, which is
  the one systematic behavioral divergence between the platforms (see
  Design Decisions).
- **WinUI 3 / .NET port**: this component's data shapes translate directly
  to C# `record`/`readonly struct` types; `Scheduler`/`Tweens`/`Channels`
  (from `avatar-engine-runtime`) are the natural home for
  `System.Threading.Tasks`/`DispatcherQueue.TryEnqueue`-based scheduling in
  place of the given sources' plain closures, and `ObservableCollection`/
  `INotifyPropertyChanged` are not needed here since this component exposes
  no bindable UI state of its own — a WinUI host reads `Arbiter.state` and
  drives its own bound view-models from it. The two validated failure paths
  (`setMood`, `play`) map to a thrown `InvalidOperationException` or a
  dedicated exception type, matching the web side's catchable-`Error`
  choice rather than the Swift side's `preconditionFailure`s, since .NET
  has no equivalent "fail the whole process" trap idiom for library code.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AvatarAnimationEngine/Sources/Anim/` | unverified |
| web | `packages/web/packages/avatar-engine/src/anim/` | unverified |

## Design Decisions

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

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | partial | Reliability |
| [adc.check.artifact-formatting.ingredient-formatting.if-behavioral-requirements](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/192770a1-b6b6-5782-bc29-251a8a941272) | passed | Artifact Formatting |

`explicit-error-handling` is partial: `setMood`/`play`/`applyPose` raise a
catchable, byte-identical-message error on both platforms for the two
validated failure paths, but an unreachable/loader-guaranteed branch traps
the process on Apple (`preconditionFailure`/`try!`) instead of raising a
catchable error the way the TypeScript mirror does — see Design Decisions.
`graceful-degradation` is partial for the same asymmetry, mirrored: a
malformed `promote` input degrades safely to a skipped step on both
platforms, but the loader-guaranteed-unreachable branches degrade
identically only on the web side; on Apple they end the process instead.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial ingredient recipe covering `Arbiter.swift`/`arbiter.ts`, `Params.swift`/`params.ts`, `Poses.swift`/`pose.ts`, `Reflexes.swift`/`reflexes.ts`, and `Timelines.swift`/`timeline.ts`, with the open question about unvalidated non-finite gaze input carried as the one open item for a future revision to resolve. |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.0.2 | 2026-09-25 | Mike Fullerton | unknown-timeline-rejected now cancels the running timeline before throwing; stir-branch-selection uses a seeded Bernoulli draw on branch.probability, not a predicate; vector 8 corrected to reflect the idle ladder taking over after the waking window, not waking.to. Converted the Conformance Test Vectors section from a numbered list into a pipe table, mapping each of the 10 existing vectors to its Behavioral Requirement name(s), and added `macos`/`ios` to the frontmatter `platforms` list. |
