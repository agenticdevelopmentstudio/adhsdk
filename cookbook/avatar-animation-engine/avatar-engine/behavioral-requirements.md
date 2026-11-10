
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

