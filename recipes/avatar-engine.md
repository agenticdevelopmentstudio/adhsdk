---
id: bd101720-9fd3-4978-a0aa-7671e301e64b
title: Avatar Engine
domain: adhsdk://recipes/avatar-engine
type: ingredient
version: 1.0.1
status: review
language: en
created: '2026-09-23'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: 'Engine / createEngine: the frame-clocked mood, timeline, gaze and speech
  state machine shared by the Apple and web avatar animation packages.'
platforms:
- ios
- macos
- swift
- typescript
- web
tags:
- avatar
- engine
- animation
- state-machine
depends-on:
- adhsdk://recipes/avatar-engine-config
- adhsdk://recipes/avatar-engine-math
- adhsdk://recipes/avatar-engine-runtime
related: []
references: []
approved-by: ''
approved-date: ''
---

# Avatar Engine

## Overview

Avatar Engine is the top-level orchestrator of the cross-platform avatar
animation stack: `Engine` (`Engine.swift`, the Apple `AvatarAnimationEngine`
package) and `createEngine` (`engine.ts`, the
`@adh-sdk/avatar-engine` web package) are two independent
implementations of the same deterministic, frame-clocked state machine, built
to produce byte-for-byte identical output from the same seed, the same
`CharacterConfig`, and the same sequence of `tick`/command calls. It is a
headless **engine** — no visual surface of its own — that composes a
`CharacterConfig` (documented in
`adhsdk://recipes/avatar-engine-config`), a `Prng`
(`adhsdk://recipes/avatar-engine-math`), and a
`Channels`/`Scheduler`/`Tweens` runtime
(`adhsdk://recipes/avatar-engine-runtime`) with two internal
collaborators not covered by this recipe or any sibling recipe at the time of
writing — a mood/timeline arbiter (`Arbiter.swift`/`arbiter.ts`) and an
ambient-reflex driver (`Reflexes.swift`/`reflexes.ts`) — to turn per-frame
commands into a `DisplayList` a renderer can paint. This package name is
deliberately distinct from the older, web-only
`@adh-sdk/avatar` package (`useAvatarEngine`, documented in
`adhsdk://recipes/avatar-behavior`): the two share the word
"avatar" and little else, and this recipe does not treat them as related.

## Behavioral Requirements

- **construction**: `Engine.init`/`createEngine` MUST accept a `config:
  CharacterConfig` already produced by the config loader, a `seed`
  (`UInt32`/`number`, default `1`), an environment (`AvatarEnvironment`/
  `Environment`, default `reducedMotion: () => false`), and an optional
  `variant` string, and MUST build, in this order, a seeded `Channels` store,
  a `Scene` for `variant` (or the true rig when `variant` is `nil`/
  `undefined`), a `Tweens` instance, a `Scheduler`, one `Prng` seeded from
  `seed`, an `Arbiter`, and a `Reflexes` that reads the arbiter's mood through
  a closure and shares the same `Prng` reference (`Engine.swift`'s `init`;
  `engine.ts`'s `createEngine`).
- **unknown-variant-construction-failure**: Constructing the engine with a
  `variant` the rig has no patch for MUST fail at construction time, before
  any `tick` call — `Engine.init` propagates the `Scene` initializer's throw,
  and `createEngine` calls `buildScene` synchronously in the equivalent
  position (`Engine.swift`'s `init`; `engine.ts`'s `createEngine`).
- **single-clock**: `tick(now)` MUST be the engine's only source of time; the
  engine MUST NOT read a wall clock, timer, or any other time source
  internally — `AvatarEnvironment`/`Environment` deliberately expose no
  `now()` accessor for this reason (`Environment.swift`; `env.ts`;
  demonstrated by `EngineTests.testNeverReadsAClockOfItsOwn`).
- **lazy-start**: The engine MUST NOT arm any scheduler entry or evaluate any
  state before the first `tick` call. On that first call it MUST set
  `origin` to the `now` given, then call `arbiter.start(0)` followed by
  `reflexes.start(0)`, in that exact order — registration order is scheduler
  id order is fire order, so the arbiter's ladder poll must exist before the
  reflexes' first poll reads the mood it sets (`Engine.swift`'s `tick`;
  `engine.ts`'s `tick`).
- **clock-normalization**: Every `tick(now)` call MUST compute the engine's
  internal clock as `now - origin`, so the first tick's clock is always `0`
  regardless of the host's epoch (`Engine.swift`'s `tick`; `engine.ts`'s
  `tick`; demonstrated by `EngineTests.testReachesTheSameFrameAtTheSameTimeAtAnyFrameRate`).
- **fixed-tick-order**: Every `tick` call MUST invoke, in this exact order,
  `scheduler.tick(clock)`, then `arbiter.tick(clock)`, then `tweens.tick(clock)`,
  and only then compose the frame from the channel store and return the
  resulting `DisplayList`. Reordering any pair MUST NOT be done — both
  implementations' own comments state that doing so breaks cross-platform
  frame parity (`Engine.swift`'s `tick`; `engine.ts`'s `tick`).
- **command-deferred-effect**: `setMood`, `notice`, `poke`, `say`, `play`, and
  `look` MUST only record their effect into internal state; none of them may
  alter the composed frame or otherwise take visible effect before the next
  `tick` call processes it (`Engine.swift`; `engine.ts`; demonstrated by
  `EngineTests.testAMoodAppliesOnTheNextTick`).
- **mood-validate-before-commit**: `setMood(mood)` MUST validate a non-nil/
  non-null `mood` against the loaded `config.poses.poses` set before mutating
  any engine state, and MUST throw/raise an error whose message is exactly
  `unknown mood: <mood>` when the name is not found, leaving every field of
  `state` unchanged from its value before the call (`Arbiter.swift`'s
  `setMood`; `arbiter.ts`'s `setMood`; demonstrated by
  `EngineTests.testAnUnknownMoodIsRefusedAtTheDoorAndChangesNothing`).
- **mood-release**: Passing `nil`/`null` to `setMood` MUST release the
  app-level mood override rather than throw, letting the idle ladder (or an
  in-progress poke/waking window) resolve the mood on the next evaluation
  (`Arbiter.swift`'s `resolve`; `arbiter.ts`'s `resolve`).
- **play-cancel-before-attempt**: `play(name)` MUST first cancel whichever
  timeline currently occupies the engine's single timeline slot — whether it
  was started by a previous `play` call or by a choreographed mood change —
  and only then attempt to start the timeline named `name`. If `name` is not
  a key in `config.timelines.timelines`, that attempt MUST throw/raise an
  error whose message is exactly `unknown timeline: <name>`; because the
  cancel already happened, the previously-running timeline stays cancelled
  even though the requested replacement failed to start (`Arbiter.swift`'s
  `play`; `arbiter.ts`'s `play`; demonstrated by
  `EngineTests.testCancelsTheRunningTimelineBeforeStartingAnotherWhicheverDoorStartsIt`
  and `EngineTests.testAnUnknownTimelineThrows`).
- **look-clamping**: `look(x, y)` MUST clamp both `x` and `y` independently to
  the closed interval `[-1, 1]` (`min(max(v, -1), 1)`) before storing the
  result as the gaze target (`Reflexes.swift`'s `look`).
- **say-side-effect**: `say(text)` MUST store the exact `text` given, with no
  transformation, escaping, or localization applied, as the current speech,
  expiring after the character's configured bubble timing
  (`in.duration + out.delay + out.duration`), and MUST pin the idle ladder at
  rung 0 for the character's configured `alertAfterTypingMs`
  (`Arbiter.swift`'s `say`; `arbiter.ts`'s `say`).
- **shared-prng-stream**: The engine MUST construct exactly one `Prng`
  instance, seeded once from `seed` (default `1`), and MUST share that same
  instance by reference between the ambient reflexes and `randomSaying`/the
  internal mutter callback, so that calling `randomSaying()` consumes a draw
  from the same stream and shifts every subsequent scheduled-random value
  (`Engine.swift`'s `init`, `pickSaying`; `engine.ts`'s `createEngine`,
  `pickSaying`; demonstrated by
  `EngineTests.testRandomSayingDrawsFromTheSAMEStreamAsTheReflexes`).
- **saying-fallback**: `randomSaying(mood)` MUST pick from
  `config.sayings.sayings[mood]` when `mood` is given, or from the arbiter's
  current mood when it is omitted, and MUST fall back to the ladder's
  `"active"` mood's saying list when the resolved mood has no list of its own
  (`Engine.swift`'s `pickSaying`; `engine.ts`'s `pickSaying`; demonstrated by
  `EngineTests.testFallsBackToTheActiveMoodsListForAMoodThatHasNone`).
- **variant-reaches-scene**: `variant` MUST be passed through unchanged to the
  `Scene` builder at construction time, and only there — variant selection
  MUST NOT be re-evaluated per tick (`Engine.swift`'s `init`; `engine.ts`'s
  `createEngine`; demonstrated by
  `EngineTests.testEngineOptionsVariantReachesTheSceneItBuilds`).
- **reduced-motion-gating**: The `reducedMotion` predicate is read fresh on
  every poll, never cached — it is a switch, not a one-way door. Whenever it
  returns `true`, the engine's ambient reflex loops (sway and idle fidget
  among them) MUST NOT re-arm and any running mood effect MUST be settled
  and not restarted, holding the affected channels at their rest values
  instead of animating them; as soon as a later poll finds it `false`
  again, the loops MUST re-arm and the mood effect MUST restart from the
  top (`Reflexes.swift`; `reflexes.ts`; demonstrated by
  `EngineTests.testReducedMotionStillsTheAmbientLoops` and
  `ReflexesTests.testSuppressesAMoodEffectUnderReducedMotionAndRestoresItWhenItClears`).
- **state-and-channels-readout**: The engine MUST expose its current
  `ArbiterState` (`mood`, `source`, `speech`, `idleRung`, `lastInteraction`)
  and its `Channels` store for inspection outside of `tick`'s return value —
  as computed properties on Apple (`engine.state`, `engine.channels`) and as
  zero-argument methods on web (`engine.state()`, `engine.channels()`)
  (`Engine.swift`; `engine.ts`).
- **config-exposure-divergence**: On Apple, `Engine.config` MUST
  be a public, readable stored property, so a render layer can read `canvas`
  and `strokeStyle` off the same engine instance it ticks, per `Engine.swift`'s
  own comment on the property. The web `Engine` interface exposes no
  equivalent accessor; a web caller MUST retain its own reference to the
  `CharacterConfig` it passed to `createEngine`, since it already obtained
  one from `loadConfig()` before construction (`engine.ts`'s `EngineOptions`/
  `Engine` interfaces define no `config` member).
- **single-context-usage**: The engine and its internal collaborators
  (`Prng`, `Scheduler`, `Tweens`, `Arbiter`, `Reflexes`, `Channels`) MUST be
  driven from a single thread/execution context at a time. None carries
  internal synchronization, and on Apple none is `Sendable` — a property the
  project's `SWIFT_STRICT_CONCURRENCY: complete` build setting enforces at
  compile time (`Engine.swift`, `Environment.swift`: plain classes and a
  struct with mutable, unsynchronized state).
- **saying-emptiness-divergence**: `randomSaying`/the
  mutter callback rely on `Prng.pick` drawing from a non-empty saying list, an
  invariant the config loader is documented to guarantee. If that invariant
  is broken, Apple's `Prng.pick` MUST fail via `preconditionFailure` — an
  unrecoverable, uncatchable process crash — while the web `Prng.pick` MUST
  throw an ordinary, catchable `Error`. Both are intentional, source-documented
  responses to the same contract violation, not two implementations of one
  behavior (`Prng.swift`'s `pick`; `prng.ts`'s `pick`).

## Appearance

Not applicable — this is a headless animation state machine, not a visual
component: `Engine.swift`/`engine.ts` render nothing themselves; they return a
`DisplayList` for a separate renderer to paint.

## States

Not applicable — this is a headless animation state machine, not a visual
component; its runtime state machines (mood/source resolution, timeline
playback, speech expiry) are covered under Behavioral Requirements above, not
as a visual-state table.

## Accessibility

Not applicable — this is a headless animation state machine, not a visual
component: it has no rendered surface, focus, label, or trait for an
assistive technology to describe.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| avatar-engine-001 | fixed-tick-order | `Engine(EngineOptions(config:, seed: 1)).tick(0)` | Returns a `DisplayList` of exactly 5 items; every item has a non-empty `d`, an ink resolving via `Color.parseHex`, and finite affine-matrix components — `EngineTests.testTickReturnsEveryPaintableNodeWithAResolvedPaint` |
| avatar-engine-002 | single-clock, clock-normalization | Two engines, same seed, each ticked through an identical 60fps/4s sequence | Both engines' full per-frame `DisplayList` traces are equal — `EngineTests.testNeverReadsAClockOfItsOwn` |
| avatar-engine-003 | clock-normalization, fixed-tick-order | One engine run at 60fps for 20s, another at 240fps for 20s, same seed | The two engines' `DisplayList` at `t = 20` and their `state` are exactly equal, not merely close — `EngineTests.testReachesTheSameFrameAtTheSameTimeAtAnyFrameRate` |
| avatar-engine-004 | command-deferred-effect, mood-validate-before-commit | `tick(0)`, then `setMood("out")`, then read `state` immediately, then `tick(1)` | `state.mood == "out"` and `state.source == .app` immediately after `setMood`, but the `eye.scaleY` channel only reaches the `"out"` pose's configured value after the following `tick(1)` — `EngineTests.testAMoodAppliesOnTheNextTick` |
| avatar-engine-005 | mood-validate-before-commit | `tick(0)`, then `setMood("nope")` (not a key in `config.poses.poses`) | Throws with message `unknown mood: nope`; `state` after the throw is unchanged from before the call — `EngineTests.testAnUnknownMoodIsRefusedAtTheDoorAndChangesNothing` |
| avatar-engine-006 | play-cancel-before-attempt | `tick(0)`, then `play("flip")`, ticked across a 0.5s window, then ticked once more at the timeline's duration plus 0.2s | The `line` display item's `d` differs from its rest shape at some point in the 0.5s window, then returns to exactly its rest `d` after the timeline ends — `EngineTests.testPlaysANamedTimelineAndReturnsToRest` |
| avatar-engine-007 | play-cancel-before-attempt | `tick(0)`, then `play("yawn")`, where `"yawn"` is not a key in `config.timelines.timelines` | Throws with message `unknown timeline: yawn` — `EngineTests.testAnUnknownTimelineThrows` |
| avatar-engine-008 | shared-prng-stream | Engine A ticked quietly for 4s at 60fps vs. Engine B ticked once, then `randomSaying()` called, then the same 4s trace | Engine A's and Engine B's per-frame trace (excluding frame 0) are NOT equal — the `randomSaying()` draw shifted every later scheduled-random value — `EngineTests.testRandomSayingDrawsFromTheSAMEStreamAsTheReflexes` |
| avatar-engine-009 | reduced-motion-gating | `body.x` sampled across an 8s/60fps run with `reducedMotion: { true }` vs. the default `{ false }` | With reduced motion off, the observed spread of `body.x` exceeds 1; with it on, the spread is exactly 0 — `EngineTests.testReducedMotionStillsTheAmbientLoops` |
| avatar-engine-010 | variant-reaches-scene | `tick(0)` on a plain engine vs. one constructed with `variant: "bold"`, reading the `limb` item's paint width | Plain build paints `limb` at ink width `4`; the `"bold"` variant paints it at width `7` — `EngineTests.testEngineOptionsVariantReachesTheSceneItBuilds` |

## Edge Cases

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

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `config` | `CharacterConfig` (Apple) / `CharacterConfig` (web) | required | A pre-validated character config produced by the loader (`CharacterConfig.load`/`loadConfig`); the engine trusts every invariant the loader is documented to enforce, including that every reachable mood has at least one saying. |
| `seed` | `UInt32` (Apple) / `number` (web) | `1` | Seeds the single `Prng` stream shared by the ambient reflexes and `randomSaying`. |
| `env` | `AvatarEnvironment` (Apple) / `Partial<Environment>` (web) | `reducedMotion: () => false` | Supplies the reduced-motion predicate. Apple takes a full `AvatarEnvironment`; web merges a partial object over `defaultEnvironment`. |
| `variant` | `String?` (Apple) / `string?` (web) | `nil`/`undefined` (the true rig) | A scene-build-time rig patch name, consumed once at construction by the `Scene` builder. |

## Deep Linking

Not applicable: `Engine.swift`/`engine.ts` define no URL, route, or scheme
handling of any kind — the engine has no navigable screen.

## Localization

Not applicable: the engine stores and echoes caller-supplied or
config-supplied strings verbatim (`say(text)`; the lines `randomSaying`
draws from `config.sayings.sayings`) with no locale-aware formatting,
pluralization, or string-table lookup of its own. Localizing the sayings
data is the config author's concern; `sayings.json` is external content, not
one of the sources given to this recipe.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Read fresh on every poll: while `AvatarEnvironment.reducedMotion`/`Environment.reducedMotion()` reports `true`, the engine's ambient reflex loops (sway, idle fidget, and related scheduled behaviors) settle to rest and do not re-arm, holding the affected channels still; as soon as it reports `false` again, the loops re-arm and the current mood effect restarts from the top — it is a switch, not a one-way door (`Reflexes.swift`; `reflexes.ts`; `EngineTests.testReducedMotionStillsTheAmbientLoops`). |
| Increase Contrast | Not applicable: the engine emits raw ink/paint values sourced from `config`; contrast is a concern of whatever renders the `DisplayList`, not of this engine. |
| Differentiate Without Color | Not applicable: the engine has no rendering surface of its own. |

## Feature Flags

Not applicable: no flag, toggle, or config-gated code path exists in
`Engine.swift`/`Environment.swift`/`engine.ts`/`env.ts` — the engine's only
inputs are its constructor options and each `tick`/command call.

## Analytics

Not applicable: none of the four given sources emits an analytics or
telemetry event; `say`/`play`/`setMood`/etc. only mutate internal state
consumed by the next `tick`.

## Privacy

- **Data collected**: None. The engine holds only the caller-supplied
  `CharacterConfig`, a numeric seed, ephemeral animation state (current
  mood, gaze target, speech text and its expiry), and channel values derived
  from `config` — none of it identifies a person.
- **Storage**: None. Nothing in `Engine.swift`/`Environment.swift`/
  `engine.ts`/`env.ts` writes to disk, `UserDefaults`, `localStorage`, or any
  other persistence layer.
- **Transmission**: None. The engine performs no network I/O; none of the
  four given sources imports a networking type.
- **Retention**: Speech text set via `say(text)` is held only until
  `speech.until` elapses — a few seconds, per the character's configured
  bubble timing — then dropped (`Arbiter.swift`'s `say`/`evaluate`;
  `arbiter.ts`'s `say`/`evaluate`).

## Logging

Not applicable: no `print`, `os_log`, `console.log`, or equivalent call
appears anywhere in `Engine.swift`, `Environment.swift`, `engine.ts`, or
`env.ts`.

## Platform Notes

- **SwiftUI**: The engine is UI-framework agnostic; a SwiftUI host owns the
  frame loop (a `TimelineView` or a `CADisplayLink`-backed driver) that calls
  `engine.tick(_:)` once per frame and feeds the returned `DisplayList` into a
  `Canvas` or a custom `Shape`. SwiftUI's own animation system (`.animation`,
  `withAnimation`) is not used for the avatar's motion — the engine already
  owns interpolation via its runtime's `Tweens`.
- **Compose**: The equivalent host pattern is `withFrameNanos`/a
  `LaunchedEffect` driving a per-frame call into a Kotlin port of `tick`, with
  a `Canvas` composable drawing the returned display list; as with SwiftUI,
  Compose's own animation APIs (`Animatable`, `animate*AsState`) are not used
  for avatar motion, since the engine's `Tweens` already owns it.
- **React/Web** (source platform): `engine.ts`'s `createEngine` and `env.ts`'s
  `defaultEnvironment`/`browserEnvironment` are the actual implementation. A
  host drives `tick` from a `requestAnimationFrame` loop and renders the
  returned `DisplayList` (commonly via the sibling `render/svg` entry point
  in this same package); `browserEnvironment()` supplies `reducedMotion` by
  reading `matchMedia("(prefers-reduced-motion: reduce)")` off `globalThis`
  once at construction.
- **AppKit / UIKit** (source platform): `Engine.swift` and `Environment.swift`
  are the actual implementation. A host drives `tick(_:)` from a
  `CVDisplayLink` (AppKit) or `CADisplayLink` (UIKit) callback and renders the
  returned `DisplayList`; the real, platform-backed `AvatarEnvironment` (its
  `reducedMotion` reading `NSWorkspace`'s or `UIAccessibility`'s reduce-motion
  flag) lives in `Render/PlatformShims.swift`'s `AvatarEnvironment.live()`
  extension, per `Environment.swift`'s own doc comment, not in the two files
  given to this recipe.
- **WinUI 3**: this is the platform this recipe exists to prepare a port for,
  and it needs a from-scratch host and engine, since neither given source
  compiles on .NET. Drive `Tick(double now)` from a
  `CompositionTarget.Rendering` event or a `DispatcherQueueTimer`, called
  synchronously on the UI thread — not through `Task.Run`/`async`, since the
  fixed scheduler-then-arbiter-then-tweens-then-compose order this contract
  requires must run on one thread without interleaving. Deserialize
  `CharacterConfig` with `System.Text.Json` (mirroring the config loader's
  contract, not this recipe's). Port the xoshiro128** `Prng` bit-for-bit in
  C# using `uint` arithmetic; .NET's `System.Random` will not reproduce the
  same stream and MUST NOT be substituted. Read the reduced-motion state
  from `Windows.UI.ViewManagement.UISettings` (or the Windows App SDK's
  accessibility settings API) and wire it the same way
  `AvatarEnvironment.reducedMotion`/`Environment.reducedMotion()` is wired
  here — a predicate read fresh on use, not cached. `DisplayList` is a
  fresh array/list
  returned whole on every tick, not an incrementally-mutated collection, so
  an `ObservableCollection` is unnecessary for it; wrap `ArbiterState` in an
  `INotifyPropertyChanged`-conforming type only if a XAML view will data-bind
  directly to `mood`/`speech` rather than reading them off the return value
  of a poll.

## Design Decisions

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

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | passed | Accessibility |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [fault-tolerance](agenticdevelopercookbook://compliance/reliability#fault-tolerance) | partial | Reliability |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | passed | Security |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |

`reduced-motion` is passed: `Reflexes`/`reflexes.ts` gate ambient loop
re-arming on the environment's predicate, tested on both platforms.
`explicit-error-handling` is passed: `setMood` and `play` validate before
committing and raise a named, message-bearing error rather than failing
silently or corrupting state. `unit-test-coverage` is passed:
`EngineTests.swift` (13 methods) and `engine.test.ts` cover construction,
determinism, frame-rate independence, every command, and the shared-PRNG and
reduced-motion contracts. `fault-tolerance` is partial: the `Scheduler` this
engine ticks first every frame tolerates a non-monotonic `now` and bounds its
catch-up loop, but the saying-list-emptiness path is fatal and uncatchable on
Apple rather than degrading gracefully (see the corresponding Design
Decision). `input-sanitization` is passed: `setMood` and `play` both check
their string argument against the loader-approved mood/timeline sets before
any state mutation. `separation-of-concerns` is passed: `Engine.swift`/
`engine.ts` hold only the tick/state-machine orchestration and
`Environment.swift`/`env.ts` hold only the injected clock/reduced-motion
predicate, with no rendering code in either file — the render path lives
entirely in the sibling avatar-engine-render recipe.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-09-25 | Mike Fullerton | Un-hard-wrapped four adhsdk:// recipe URIs split across code-span line breaks; renamed config-exposure/saying-emptiness-divergence requirement names to kebab-case; reduced-motion-gating corrected to describe re-arm/mood-effect-restart when the predicate later returns false. Added best-practices compliance rows (separation-of-concerns: passed). |
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation |
