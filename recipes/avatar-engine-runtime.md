---
id: 74ba9dde-4963-42cb-aa03-bf1ee4dcc794
title: Avatar Engine Runtime
domain: adhsdk://recipes/avatar-engine-runtime
type: ingredient
version: 1.0.1
status: review
language: en
created: '2026-09-23'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: 'Channels, Scheduler, and Tweens: the frame-timing and interpolation contract
  shared by the Swift and TypeScript avatar engines.'
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
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Avatar Engine Runtime

## Overview

The avatar engine runtime is the frame-timing and interpolation core shared by
the Swift and TypeScript avatar engines. It has no visual surface of its own —
a host `Engine` composes it with a scene graph and a config loader to produce
frames, but the runtime itself only stores values, schedules callbacks against
an absolute clock, and interpolates values toward targets. It is three
independent primitives:

- **Channels** (`Channels.swift` / `channels.ts`) — a flat, string-keyed store
  of `ChannelValue`s (a `number` or a `string`). Everything the engine animates
  — a node property, an ink color, a mouth path, a shape family — is a channel,
  so neither the scene tree nor the animation code needs to know about the
  other.
- **Scheduler** (`Scheduler.swift` / `scheduler.ts`) — absolute-time event
  scheduling. It never asks "how much time passed"; it asks "what should have
  happened by now," which is what makes the same sequence of fires happen at
  60Hz, 120Hz, or after one large catch-up tick, regardless of refresh rate.
- **Tweens** (`Tweens.swift` / `tween.ts`) — per-channel interpolation driven
  by the Channels store: `TweenSpec`s describe a target value, a duration, an
  optional delay and ease, and `Tweens.tick` writes the eased value for `now`
  into the channel it targets.

The reference host (`Engine.swift`, `Sources/Engine.swift`) drives all three on
one clock, in one order, per frame: `scheduler.tick(clock)`, then
`arbiter.tick(clock)` (which adds/cancels tweens in response to scheduled
events), then `tweens.tick(clock)`, then reads the channels to render. That
ordering is load-bearing — each swap is documented in source as "its own
frame-late bug" — but it lives in `Engine`, not in these three files; this
recipe specifies the contract each of the three offers to whatever drives it,
not the driving order itself.

## Behavioral Requirements

### Channels

- **channel-value-shape**: A channel value MUST be either a number
  (`ChannelValue.number` / a JS `number`) or a string (`ChannelValue.text` / a
  JS `string`); no other shape is a valid channel value.
- **channel-value-json-round-trip**: On the Apple platform, encoding a
  `ChannelValue` to JSON MUST produce a bare JSON number for `.number` and a
  bare JSON string for `.text`, and decoding MUST accept a JSON number or a
  JSON string and MUST fail with an error ("a channel value must be a number
  or a string") for any other JSON type. The TypeScript `ChannelValue` type
  has no equivalent runtime decode step in these runtime files — a `number |
  string` union is enforced only at compile time, so this requirement is
  Apple-only as written in source.
- **channels-get-missing-returns-nothing**: `Channels.get(name)` MUST return
  `nil` (`undefined` in TypeScript) when no value has ever been set for
  `name`, and MUST otherwise return the value most recently set for it.
- **channels-set-overwrites**: `Channels.set(name, value)` MUST create the
  entry if `name` is unset and MUST overwrite the existing value if it is set;
  there is no append or merge behavior.
- **channels-names-sorted**: `Channels.names()` MUST return every channel name
  sorted ascending (lexicographic string order), never in the underlying
  dictionary's/Map's own iteration order — a `Dictionary`'s order is seeded
  per process, so an unsorted read would produce a different display list on
  every launch.
- **snap-channel-classification**: `snaps(channel)` MUST return `true` if and
  only if `channel` contains at least one `"."` and the substring after the
  LAST `"."` is exactly `"pivotX"` or `"pivotY"`; it MUST return `false` for
  every other channel name, including a bare `"pivotX"`/`"pivotY"` with no
  `"."` at all. A pivot is where a transform's motion originates, not a
  quantity that itself moves — tweening it (rather than snapping it) would
  compose a rotation about an origin nobody authored for the length of the
  tween.

### Scheduler

- **scheduler-registers-repeating**: `Scheduler.every(interval, first:,
  run:)` MUST register a callback whose first due time is `first` if given,
  else `interval` (never `0`/"now") — a repeater's initial delay defaults to
  one full interval, not an immediate fire.
- **scheduler-one-shot-classification**: A registration's due time recurs
  (fires and reschedules) only while its stored interval is greater than `0`.
  `Scheduler.once(at:run:)` MUST register with interval `0`; a caller that
  instead calls `every(0, first: at, run:)` MUST observe identical behavior —
  a single fire, then removal — because `tick` itself branches on `interval
  <= 0`, not on which factory method created the entry.
- **scheduler-fires-when-due**: `Scheduler.tick(now)` MUST run every
  registration whose next due time is `<= now`.
- **scheduler-catch-up-fires-every-missed-interval**: For a repeating
  registration, if more than one interval has elapsed since the last `tick`,
  `Scheduler.tick(now)` MUST fire the callback once for every interval that
  became due, each time advancing the due time by exactly `interval` (never
  by `now - due time`), so the same absolute number of fires occurs whether
  they are delivered as one call every interval or as a single catch-up after
  a long gap.
- **scheduler-catch-up-guard**: Within one `tick(now)` call, a repeating
  registration's catch-up loop MUST NOT fire more than 1000 times; on
  exceeding that bound the Scheduler MUST stop firing for that registration
  in this tick and MUST set its next due time to `now + interval`, so an
  absurd interval or a clock that jumped hours cannot hang the calling frame.
- **scheduler-one-shot-fires-once**: `Scheduler.once(at:run:)`'s callback MUST
  run exactly once and the registration MUST be removed immediately upon
  firing; a subsequent `tick` at any later `now` MUST NOT run it again.
- **scheduler-one-shot-stale-clamp** (Apple only): When a one-shot's due time
  is more than `1.0` second (`staleAfter`) in the past at the moment `tick`
  observes it, the Swift `Scheduler` MUST invoke the callback with `max(due
  time, now - 1.0)` rather than the true (arbitrarily old) due time. This
  bounds how far a chain of self-re-arming one-shots (a reflex that re-arms
  itself each time it fires) can replay its backlog after the frame loop was
  stopped for real reasons (display sleep, backgrounding): each link re-arms
  relative to the time it was handed, so an unclamped chain would replay one
  link per frame for as many links as were missed, each walking its target
  channel by one step.
- **scheduler-cancel-removes-and-tolerates-unknown-ids**:
  `Scheduler.cancel(id)` MUST remove the registration for `id` if present,
  and MUST silently do nothing (never throw or trap) if `id` is unknown,
  already fired (a spent one-shot), or already cancelled.
- **scheduler-tick-order-and-snapshot**: `Scheduler.tick(now)` MUST visit
  registrations in the order their ids were assigned (ids are issued
  monotonically starting at `1`), and MUST decide which registrations are due
  from a snapshot taken before any callback in this `tick` call runs — a
  callback that itself registers, cancels, or is itself cancelled during the
  same `tick` MUST NOT change which already-decided registrations this call
  visits, and a registration removed by another callback's side effect during
  the tick MUST be silently skipped rather than erroring when this call
  reaches it.
- **scheduler-mid-run-cancellation**: If a repeating registration's own
  callback cancels its id while that same registration's catch-up loop is
  still running (i.e., the callback removes itself), `Scheduler.tick` MUST
  stop that registration's catch-up loop immediately rather than continuing
  to invoke a callback for a registration that no longer exists.

### Tweens

- **tween-recognized-value-kinds**: A `TweenSpec.to` (and, if present,
  `.from`) value MUST be one of: a number; a hex color string matching
  `#rrggbb` or the 3-digit short form `#rgb`, using only ASCII hex digits (`0`
  through `9`, `a`-`f`, `A`-`F` — Unicode "fullwidth" digit and letter
  look-alikes MUST NOT be accepted as hex digits); an SVG-subset path string
  whose first character is `M` or `m`; or any other string, which is treated
  as an opaque, non-interpolatable value.
- **tween-numeric-interpolation**: When both `from` and `to` resolve to
  numbers, `Tweens` MUST linearly interpolate `from + (to - from) * easedT`
  at each sampled progress.
- **tween-color-interpolation**: When both `from` and `to` are recognized hex
  colors, `Tweens` MUST interpolate perceptually — converting sRGB to OKLab,
  lerping there, and converting back — rather than a componentwise sRGB
  lerp, because a componentwise lerp between two saturated colors visibly
  dips through grey at the midpoint while the OKLab path does not.
- **tween-color-fallback-on-unmixable-pair**: If the perceptual color mix
  operation fails for a pair that passed the hex-shape check (e.g., a
  malformed value that slips past the ASCII-hex guard), `Tweens` MUST hold
  `from` until progress reaches `1` and then snap directly to `to`, the same
  answer given for any unrecognized/uninterpolatable pair — it MUST NOT
  propagate the failure out of the tween loop.
- **tween-path-morph-same-kind**: When both `from` and `to` are recognized
  path strings and their parsed "kind" (the joined command-letter sequence,
  e.g. `"MLL"` or `"MCCCCZ"`) is identical, `Tweens` MUST morph anchor-by-anchor
  between them at each sampled progress.
- **tween-path-snap-cross-kind**: When both `from` and `to` are recognized
  path strings but their parsed kinds differ (no anchor-for-anchor mapping is
  possible between different command sequences), `Tweens` MUST NOT attempt a
  morph and MUST instead treat the pair as uninterpolatable: hold `from` until
  progress reaches `1`, then snap to `to`.
- **tween-unrecognized-pair-snap**: For any `from`/`to` pair that is not
  both-numbers, both-recognized-colors, or both-same-kind-paths (including a
  color paired with a path, two differently-shaped strings, or any other
  mixed pairing), `Tweens` MUST hold `from` for the full duration and MUST
  write `to` verbatim only once progress reaches `1`.
- **tween-snap-channel-forces-zero-duration**: If `TweenSpec.channel` is a
  channel `snaps()` classifies as snapping (see **snap-channel-classification**),
  `Tweens.add` MUST use an effective duration of `0` regardless of
  `TweenSpec.duration`; a caller cannot make a pivot channel animate by
  requesting a longer duration.
- **tween-zero-duration-immediate-apply**: When the effective duration is `0`
  AND `TweenSpec.delay` is `0`, `Tweens.add` MUST write the (respond-mapped)
  `to` value to the channel synchronously, at call time — before any `tick`
  call — and MUST NOT create a live tween entry for it (`Tweens.active` does
  not increase). A same-kind path family snap MUST write `to` verbatim,
  never routed through the morph/lerp path, because two same-instant
  crossings (an authored snap immediately superseded by an authored morph)
  must both resolve without one masking the other.
- **tween-delay-defers-visible-start**: When `TweenSpec.delay` is greater than
  `0`, neither a zero-duration snap's target nor an interpolated tween's first
  sample MUST become visible before `tick(now)` is called with `now >=` (the
  `now` passed to `add`, plus `delay`); until then the channel MUST retain
  whatever value it held when `add` was called.
- **tween-from-resolves-from-channel**: If `TweenSpec.from` is omitted, the
  tween's starting value MUST be resolved from the channel's stored value at
  the moment of the tween's first `write` (its first `tick` at or after its
  start time, or an earlier `settle` — see **tween-add-settles-outgoing-tween**),
  NOT at the moment `add` was called, so a delayed tween picks up whatever the
  channel holds when it actually starts. This resolution MUST happen only
  once per tween and MUST be cached — a later change to the channel's value by
  something else MUST NOT re-resolve it. An unspecified `from` resolved this
  way MUST NOT be passed through `respond`; if the channel has no stored
  value at all at that moment, the starting value MUST be the (already
  respond-mapped) `to` value.
- **tween-from-explicit-through-respond**: If `TweenSpec.from` is provided,
  `Tweens` MUST use it as the starting value in place of the channel's stored
  value, and MUST pass it through `respond` the same way `to` is mapped.
- **tween-respond-maps-endpoints-once**: `Tweens.add`/`createTweens` MUST pass
  `to` (and an explicit `from`) through the constructor's `respond` function
  (identity by default) exactly once, at `add` time, before any
  interpolation — `respond` maps the target value a tween is driving toward,
  not the interpolated value produced on each frame.
- **tween-add-cancels-existing-channel-tween**: Calling `Tweens.add` for a
  channel that already has a live tween MUST cancel that prior tween before
  registering the new one; a channel MUST NOT have two live tweens
  simultaneously.
- **tween-add-settles-outgoing-tween**: Before cancelling a channel's prior
  live tween to replace it, `Tweens.add` MUST first write to the channel the
  value that prior tween would show at the current `now` (the handoff
  instant), so the incoming tween's unspecified `from` resolves against that
  exact instant's value rather than whatever the last discrete `tick` left
  behind — this is what makes the same animation, interrupted at the same
  wall-clock instant, land on the same value regardless of frame rate.
- **tween-cancel-by-channel**: `Tweens.cancel(channel)` MUST remove any live
  tween on `channel` and MUST be a no-op if none is live there.
- **tween-tick-progress-and-completion**: `Tweens.tick(now)` MUST, for every
  live tween whose start time is `<= now`, write the eased value at progress
  `min(1, (now - start) / (end - start))` (or `1` if `end <= start`) to its
  channel, and MUST remove the tween from the live set once progress reaches
  `1`.
- **tween-tick-ignores-future-start**: `Tweens.tick(now)` MUST NOT write to,
  or resolve the `from` of, a tween whose start time is still after `now`.
- **tween-active-count**: `Tweens.active` (a property in Swift,
  `active()` in TypeScript) MUST report exactly the number of tweens
  currently live; it MUST be unaffected by an `add` call that resolved
  immediately (zero duration, zero delay).
- **tween-ease-resolution-fails-closed**: An ease name that is not one of the
  24 names in the fixed ease vocabulary (`none`, `sine.{in,out,inOut}`,
  `power{1-4}.{in,out,inOut}`, bare `power3`, and `back.out`/six explicit
  `back.out(s)` overshoot values) MUST cause resolving that tween's easing
  function to fail rather than silently substitute a default curve. On the
  Apple platform this happens at `Tweens.add` time and crashes the process
  (a forced unwrap on `Ease.resolve`, deliberate: the config loader is
  documented as validating every reachable ease name before a `TweenSpec`
  ever reaches `Tweens`, so an unknown name here is a bug, not bad data). On
  the web platform, `resolveEase` is invoked from inside `write`, which is
  called from every `tick`/`settle` that touches the tween — so an unknown
  name throws an uncaught `Error` the first time the tween is sampled, not at
  `add` time, and (per source comment) nothing in the render loop (`useAvatarEngine`'s
  `requestAnimationFrame` callback) catches it.
- **tween-default-ease-and-delay**: When `TweenSpec.ease` is omitted, `Tweens`
  MUST use `"power3.out"`; when `TweenSpec.delay` is omitted, `Tweens` MUST
  use `0`.

## Appearance

Not applicable — this is a headless frame-timing and interpolation engine,
not a visual component: `Channels.swift`/`channels.ts`, `Scheduler.swift`/
`scheduler.ts`, and `Tweens.swift`/`tween.ts` render nothing themselves.

## States

Not applicable — this is a headless frame-timing and interpolation engine,
not a visual component; the runtime's own state machines (which channels are
mid-tween, which scheduler entries are pending) are covered under Behavioral
Requirements above, not as a visual-state table.

## Accessibility

Not applicable — this is a headless frame-timing and interpolation engine,
not a visual component: it has no rendered surface, focus, label, or trait
for an assistive technology to describe.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| aer-001 | channels-names-sorted | `Channels` seeded via dictionary/object insertion in non-alphabetical order | `names()` returns keys in ascending lexicographic order, not insertion order |
| aer-002 | scheduler-catch-up-fires-every-missed-interval | `every(0.1, first: 0.1)`; ticked once per frame from `0` to `0.55` at 60fps | Callback fires 5 times, not 1 — `SchedulerTests.testFiresARepeatingEventOncePerInterval` / `scheduler.test.ts "fires a repeating event once per interval"` |
| aer-003 | scheduler-catch-up-fires-every-missed-interval | `every(0.1, first: 0.1)`; `tick(0)` then a single `tick(0.55)` | Callback fires 5 times in that one call, not 1 — `SchedulerTests.testCatchesUpAcrossALongFrameInsteadOfDroppingEvents` / `scheduler.test.ts "catches up across a long frame instead of dropping events"` |
| aer-004 | scheduler-catch-up-fires-every-missed-interval | Same `every(0.1, first: 0.1)` registration ticked to `t=2` at a `1/60` step vs. a `1/240` step | Both step sizes produce the identical fire count — `SchedulerTests.testIsFrameRateIndependent` / `scheduler.test.ts "is frame-rate independent"` |
| aer-005 | scheduler-one-shot-fires-once | `once(at: 0.5)`; `tick(1)` then `tick(2)`; then `cancel(id)` | Callback runs exactly once; the later `cancel` on the already-spent id does not throw — `SchedulerTests.testRunsAOneShotExactlyOnceAndForgetsIt` / `scheduler.test.ts "runs a one-shot exactly once and forgets it"` |
| aer-006 | scheduler-one-shot-stale-clamp (Apple only) | `once(at: 0.5)`; `tick(1)` (half a second late) | Callback receives `0.5` (its own deadline), not `1` (`now`) — `SchedulerTests.testHandsASlightlyLateOneShotItsOwnDeadline`. No equivalent assertion exists in `scheduler.test.ts`. |
| aer-007 | scheduler-catch-up-guard, scheduler-one-shot-stale-clamp | A one-shot chain that re-arms itself every `+5`s, armed at `t=5`; `tick(5)` then a single `tick(3600)` (an hour with no frames) | Only 2 fires total (not 719); the second fire lands within `[3599, 3600]`; a subsequent `tick(3600 + 1/60)` produces no further fire — `SchedulerTests.testResumesAOneShotChainAfterAStoppedLoopInsteadOfReplayingItsBacklog`. TypeScript's `createScheduler` has no `staleAfter` clamp in these runtime files, so the same scenario in `scheduler.ts` would hand each re-arm its true (unclamped) deadline and is untested by `scheduler.test.ts`. |
| aer-008 | scheduler-cancel-removes-and-tolerates-unknown-ids | `every(0.1, first: 0.1)`; `tick(0.25)`; `cancel(id)`; `tick(5)` | 2 fires total, none after cancel — `SchedulerTests.testCancelsARepeater` / `scheduler.test.ts "cancels a repeater"` |
| aer-009 | tween-numeric-interpolation, tween-tick-progress-and-completion | `Channels(["eye.scaleY": 1])`; `add({channel: "eye.scaleY", to: 0.1, duration: 0.4, ease: "none"}, now: 10)`; ticks at `10`, `10.2`, `10.4` | Values `1`, `0.55`, `0.1`; `active == 0` after the last tick — `TweenTests.testInterpolatesANumberOverAbsoluteTime` / `tween.test.ts "interpolates a number over absolute time"` |
| aer-010 | tween-snap-channel-forces-zero-duration | `Channels(["body.pivotY": 50])`; `add({channel: "body.pivotY", to: 74, duration: 0.9}, now: 0)` | `body.pivotY` reads `74` immediately after `add`, before any `tick`; `active == 0` — `TweenTests.testSnapsAPivotToItsTargetAtAddTimeHoweverLongADurationItIsGiven` (Apple only; no equivalent test in `tween.test.ts`) |
| aer-011 | tween-snap-channel-forces-zero-duration, tween-delay-defers-visible-start | `Channels(["body.pivotX": 50])`; `add({channel: "body.pivotX", to: 80, duration: 0.9, delay: 0.2}, now: 0)`; ticks at `0.1` then `0.2` | `body.pivotX` still reads `50` at `0.1`, then `80` at `0.2` — never an intermediate value — `TweenTests.testStillWaitsOutAPivotsDelayAndThenJumps` (Apple only; no equivalent test in `tween.test.ts`) |
| aer-012 | tween-from-explicit-through-respond | `Channels(["x": 5])`; `add({channel: "x", to: 10, duration: 1, ease: "none", from: 0}, now: 0)`; ticks at `0.5` and `1` | `x` reads `5` at `t=0.5` (halfway from the explicit `from: 0` to `10`), `10` at `t=1` — not `7.5`, which is what an unspecified `from` (reading the channel's `5`) would have produced — `TweenTests.testStartsFromAnExplicitFromInsteadOfTheChannelsCurrentValue` / `tween.test.ts "starts from an explicit \`from\` instead of the channel's current value"` |
| aer-013 | tween-add-cancels-existing-channel-tween, tween-add-settles-outgoing-tween | `add({channel:"x", to:100, duration:1, ease:"none"}, now:0)`; `tick(0.5)`; `add({channel:"x", to:0, duration:1, ease:"none"}, now:0.5)`; `tick(1)` | `active == 1` right after the second `add`; `x` reads `25` at `t=1` (halfway back from the settled `50`, not from `100`) — `TweenTests.testLetsANewerTweenCancelTheOlderOneOnTheSameChannel` / `tween.test.ts "lets a newer tween cancel the older one on the same channel"` |
| aer-014 | tween-color-interpolation, tween-path-morph-same-kind | Colors `#00ff41` → `#ff2d2d` and paths `M187,233L200,246L213,233` → `M189,235L200,235L211,235`, both `duration: 1, ease: "none"`; `tick(1)` | Both channels read their `to` value exactly at `t=1` — `TweenTests.testInterpolatesColoursAndPaths` / `tween.test.ts "interpolates colours and paths"` |
| aer-015 | tween-respond-maps-endpoints-once, tween-from-explicit-through-respond | A `respond` that multiplies positive numbers by `0.72`; `add({channel: "antennaLeft.bend", to: -10.64, duration: 0}, now: 0)`, then `add({..., to: 10.64, duration: 1, ease: "none"}, now: 0)`; `tick(0.5)` and `tick(1)` | Immediate write reads `-10.64` (negative, so `respond` is a no-op here); at `t=0.5` reads `(-10.64 + 10.64*0.72)/2`; at `t=1` reads `10.64*0.72` — the endpoint is mapped once, not the live interpolated value each frame — `TweenTests.testMapsAnEndpointThroughRespondAndThenLerpsInTheMappedSpace` / `tween.test.ts "maps an endpoint through \`respond\` and then lerps in the mapped space"` |
| aer-016 | tween-color-fallback-on-unmixable-pair | `body.ink` set to an unmixable value (`"#\u{FF10}0ff41"` fullwidth-digit, or `"#abcd"` 4-digit body); `add({channel:"body.ink", to:"#ff2d2d", duration:1, ease:"none"}, now:0)`; ticks at `0.5` and `1` | Value holds the original (unmixable) string at `t=0.5`, then snaps to `#ff2d2d` at `t=1` — `TweenTests.testSnapsAColourPairParseHexCannotReadInsteadOfTrapping` / `tween.test.ts "snaps a colour pair \`parseHex\` cannot read instead of throwing out of the frame loop"` |
| aer-017 | tween-zero-duration-immediate-apply | `Channels(["mouth.family": "mouth"])`; `add({channel:"mouth.family", to:"mouthO", duration:0}, now:3)` | `mouth.family` reads `"mouthO"` before any `tick` runs; `active == 0`; a subsequent `tick(3)` leaves it unchanged — `TweenTests.testAppliesAZeroDurationTweenAtAddTimeBeforeAnyTick` / `tween.test.ts "applies a zero-duration tween at add time, before any tick"` |
| aer-018 | tween-zero-duration-immediate-apply, tween-path-morph-same-kind | Same-instant pair on `mouth.shape`: a duration-0 snap to family `mouthO`, immediately followed (same `add` call sequence, same `now`) by a `duration: 0.85` morph to a different `mouthO`-family path | The snap's target is written verbatim, then the morph interpolates from it (the snap is not lost, and the morph is a real anchor-to-anchor lerp, not a snap) — `TweenTests.testLetsASameInstantFamilySnapSurviveTheMorphThatSupersedesIt` / `tween.test.ts "lets a same-instant family snap survive the morph that supersedes it"` |
| aer-019 | tween-path-snap-cross-kind | `mouth.shape` set to an `"MCCCCZ"`-kind path; `add` a `duration:0.3` tween to an `"MLL"`-kind path; ticks at `0.1` and `0.3`; then `add` back to the original kind | The target path is written verbatim on the FIRST tick after `add` (not held to the end of the duration), and the reverse crossing behaves the same way — `TweenTests.testSnapsAPathAcrossShapeFamiliesInsteadOfTrapping` / `tween.test.ts "snaps a path across shape families instead of throwing"` |
| aer-020 | tween-add-settles-outgoing-tween, tween-tick-progress-and-completion | `add({channel:"x", to:10, duration:1, ease:"none"}, now:0)`; `tick(0.5)`; `add({channel:"x", to:0, duration:1, ease:"none"}, now:0.75)` (an off-tick handoff instant) | `x` reads `7.5` immediately after the second `add` (settled to `0.75`, not left at the `0.5`-tick value of `5`); `tick(1.25)` reads `3.75` (halfway back from `7.5`) — `TweenTests.testSettlesTheTweenItReplacesAtTheInstantOfTheHandoff` / `tween.test.ts "settles the tween it replaces at the instant of the handoff"` |
| aer-021 | tween-add-settles-outgoing-tween | The same interrupted-handoff animation (ease `power2.in` then `none`, interrupted at `t=0.41`) run to completion at 60fps, 240fps, and 1000fps ticking granularities | All three frame rates land on the identical final value (`≈0.5582601`) — `TweenTests.testHandsOffToTheSameValueAt60And240And1000fps`. No equivalent multi-rate handoff test exists in `tween.test.ts`. |
| aer-022 | tween-ease-resolution-fails-closed | `TweenSpec.ease` set to a name outside the fixed 24-name vocabulary | Apple: `Tweens.add` crashes (forced unwrap traps). Web: no error at `add`; `resolveEase` throws the first time `write` samples the tween (inside `tick`/`settle`), uncaught by the render loop. Traced to `Ease.swift`'s `resolve(_:) throws` used via `try!` in `Tweens.add`, and `ease.ts`'s `resolveEase` used inside `tween.ts`'s `write`; neither `EaseTests`/`Math`-level test nor `tween.test.ts` exercises an unknown name reaching `Tweens`/`createTweens` directly (only `MathTests`/`ease.test.ts` test `resolveEase`/`Ease.resolve` in isolation). |

## Edge Cases

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

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `Channels(initial:)` constructor argument | `[String: ChannelValue]` / `Record<string, ChannelValue>` | `[:]` / `{}` | Seed values a caller supplies at construction; every subsequent value comes from `set`. |
| `Tweens(channels:respond:)` / `createTweens(channels, respond)` `respond` | `(String, ChannelValue) -> ChannelValue` | identity (`{ _, v in v }` / `(_c, v) => v`) | Maps a tween's endpoint (`to`, and an explicit `from`) into whatever space the caller renders in, once, at `add` time. |
| `TweenSpec.duration` | number (seconds) | — (required, no default) | Requested animation length; overridden to `0` for a snapping channel. |
| `TweenSpec.delay` | number (seconds) | `0` | Time after the `add`-time `now` before the tween's start. |
| `TweenSpec.ease` | string (one of 24 fixed names) | `"power3.out"` | Selects the easing curve; an unrecognized name fails closed (see **tween-ease-resolution-fails-closed**). |
| `TweenSpec.from` | `ChannelValue?` | unset (resolved from the channel) | Overrides the tween's starting value. |
| `Scheduler.every` `first` | number (seconds), optional | `interval` | The registration's first due time. |
| Snap channel set (`SNAP_PROPS`) | fixed `Set<String>` / `ReadonlySet<string>` | `{"pivotX", "pivotY"}` | Hardcoded in `Channels.swift`/`channels.ts`; not configurable by a caller. |
| Scheduler catch-up guard | fixed integer constant | `1000` | Hardcoded in `Scheduler.swift`/`scheduler.ts`; not configurable. |
| One-shot stale clamp (`staleAfter`, Apple only) | fixed `Double` constant | `1.0` seconds | Hardcoded in `Scheduler.swift`; has no equivalent constant in `scheduler.ts`. |
| Ease vocabulary | fixed table of 24 names | — | Hardcoded in `Ease.swift`/`ease.ts`; closed by design — "no synthesis at runtime" — so a caller cannot register a custom ease name. |

## Deep Linking

Not applicable: `Channels.swift`/`channels.ts`, `Scheduler.swift`/`scheduler.ts`,
and `Tweens.swift`/`tween.ts` define no URL, route, or scheme handling of any
kind.

## Localization

Not applicable: the only strings this runtime handles are channel
identifiers (`"eye.scaleY"`, `"body.ink"`), opaque channel payload values
(hex colors, SVG path data), and ease names — none is user-facing display
text. The developer-facing error descriptions (`Ease.Failure.unknown`,
`Color.Failure.badHex`, `PathError`'s cases, the Swift `Codable` decode
error) are fixed English diagnostic strings, not localized or exposed to end
users by these files.

## Accessibility Options

Not applicable: reduced motion, increased contrast, and differentiate-without-color
are handled elsewhere in the engine (`Reflexes`/`Engine`'s `reducedMotion`
option, per `EngineOptions`/`AvatarEnvironment` in `Engine.swift`) — none of
`Channels.swift`/`channels.ts`, `Scheduler.swift`/`scheduler.ts`, or
`Tweens.swift`/`tween.ts` reads or responds to any accessibility display
option.

## Feature Flags

Not applicable: no flag, toggle, or config-gated code path exists in
`Channels.swift`/`channels.ts`, `Scheduler.swift`/`scheduler.ts`, or
`Tweens.swift`/`tween.ts`.

## Analytics

Not applicable: none of these three files emits an analytics event; the
reference host's own `SyncEvent`-style observability (used by other engine
components) has no counterpart here.

## Privacy

- **Data collected**: None. A channel value can hold arbitrary caller-supplied
  numbers or strings, but nothing in `Channels`, `Scheduler`, or `Tweens`
  treats any value as a credential, token, or personal identifier, collects
  it, or transmits it.
- **Storage**: In-memory only, for the lifetime of the owning `Channels`/
  `Scheduler`/`Tweens` instance; nothing here writes to disk. (`ChannelValue`'s
  `Codable` conformance lets a caller elsewhere serialize a snapshot, but
  serialization and persistence are outside these three files.)
- **Transmission**: None. No network call exists in `Channels.swift`/
  `channels.ts`, `Scheduler.swift`/`scheduler.ts`, or `Tweens.swift`/`tween.ts`.
- **Retention**: For the lifetime of the instance; there is no persistence to
  retain beyond that.

## Logging

Not applicable: no `print`, `os_log`, `console.log`, or equivalent call
appears anywhere in `Channels.swift`/`channels.ts`, `Scheduler.swift`/
`scheduler.ts`, or `Tweens.swift`/`tween.ts`.

## Platform Notes

- **SwiftUI**: The runtime is UIKit/AppKit/SwiftUI-agnostic — `Channels`,
  `Scheduler`, and `Tweens` are plain `Foundation`-only classes with no
  rendering dependency. A SwiftUI host drives `tick` from a `TimelineView` or
  a `CADisplayLink`-backed publisher, reading `Channels` afterward to update
  `@State`/`@Observable` properties that feed the view; nothing about these
  three types changes for SwiftUI versus any other Apple UI framework.
- **Compose**: Port `ChannelValue` as a `sealed interface`/`sealed class`
  with `Number`/`Text` variants (Kotlin has no built-in tagged union), back
  `Channels` with a `MutableMap<String, ChannelValue>` (or `SnapshotStateMap`
  if channel reads should trigger recomposition directly), and drive
  `Scheduler`/`Tweens.tick` from a `withFrameNanos`/`LaunchedEffect` loop
  converting nanoseconds to the same absolute-seconds clock the source uses.
- **React/Web**: This IS the reference implementation
  (`packages/web/packages/avatar-engine/src/runtime/{channels,scheduler,tween}.ts`);
  a host drives `tick` from `requestAnimationFrame`, converting the RAF
  timestamp to seconds since the engine's own origin (see `useAvatarEngine`,
  which is outside this component's scope).
- **AppKit / UIKit**: Also UI-framework-agnostic like the SwiftUI note above;
  an AppKit/UIKit host drives `tick` from a `CVDisplayLink`/`CADisplayLink`
  callback and reads `Channels` in its own drawing/layout pass — no part of
  `Channels`, `Scheduler`, or `Tweens` depends on either framework.
- **WinUI 3**: Model `ChannelValue` as a small `readonly record struct` or a
  two-case discriminated union (`double` XOR `string`, since C# has no native
  tagged union) rather than reusing `object`, so a channel can never silently
  hold an unsupported type. Back `Channels` with a plain
  `Dictionary<string, ChannelValue>` (`ObservableCollection`/
  `INotifyPropertyChanged` are unnecessary here — nothing in source makes
  `Channels` itself observable; only the rendered composition downstream
  needs to notify a view). Drive `Scheduler`/`Tweens.Tick` from
  `CompositionTarget.Rendering` or a `DispatcherQueueTimer`, using
  `Stopwatch.Elapsed.TotalSeconds` (or an injected clock) as the same
  absolute-seconds `now` the source threads through every call — never
  `DateTime.Now`, whose resolution and monotonicity guarantees are weaker
  than `Stopwatch`'s. Port the 24-entry ease table as a
  `static readonly Dictionary<string, Func<double, double>>` built once
  (mirroring the Swift `static let table` comment's reasoning: build
  immutably, once, so it is safe to read from multiple call sites without a
  lock), and port `Ease.resolve`/`resolveEase` as a method that throws
  `KeyNotFoundException` (or a dedicated exception type) for an unknown name
  rather than returning a default curve, matching **tween-ease-resolution-fails-closed**.
  There is no `Task`/`async` surface to port: every method here (`Channels.Get`/
  `Set`, `Scheduler.Tick`, `Tweens.Add`/`Tick`) is synchronous, called from
  whatever single thread drives the host's render loop — an `async` wrapper
  would misrepresent the contract.

## Design Decisions

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

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | partial | Reliability |
| [fault-tolerance](agenticdevelopercookbook://compliance/reliability#fault-tolerance) | partial | Reliability |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

`explicit-error-handling` is partial: an unmixable color pair degrades
explicitly to a snap (handled), but an unknown ease name and a malformed
same-kind path both crash/throw uncaught rather than surfacing a catchable,
documented error (see **tween-ease-resolution-fails-closed** and the
malformed-path edge case). `graceful-degradation` is partial for the same
reason, mirrored: recognized-but-unmixable color/path pairs degrade to a snap,
but an unrecognized ease name or malformed path grammar does not degrade —
it fails hard. `fault-tolerance` is partial because the Scheduler's
1000-iteration catch-up guard protects both platforms equally, but the
one-shot stale-time clamp that bounds a long-stopped reflex chain's replay
exists only on Apple (see the corresponding Design Decision). `unit-test-coverage`
is partial because `Channels`/`createChannels` has no dedicated test file on
either platform (`ChannelsTests.swift` and `channels.test.ts` do not exist);
it is exercised only indirectly through `TweenTests.swift`/`tween.test.ts`
and the higher-level `EngineTests.swift`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-09-25 | Mike Fullerton | Added `macos`/`ios` to the frontmatter `platforms` list. |
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation |
