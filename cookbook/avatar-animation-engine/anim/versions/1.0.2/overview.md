
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

