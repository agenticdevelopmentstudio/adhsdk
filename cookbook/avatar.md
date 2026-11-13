---
id: ccfd0128-374c-4cca-a83f-71efd3c02176
title: "Avatar Behavior"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-09-23
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Headless React engine (useAvatarEngine) that gives any SVG persona reflexes (blink, idle ladder, gaze, speech) and an expression-driven pose loop over optional, avatar-agnostic channels."
platforms:
  - typescript
  - web
tags:
  - engine
  - animation
  - avatar
depends-on: []
related: []
references:
  - https://gsap.com/docs/v3/Plugins/MorphSVGPlugin/
approved-by: ""
approved-date: ""
---

# Avatar Behavior

## Overview

Avatar Behavior is the headless behavior-and-animation engine behind any SVG
persona in `@adh-sdk/avatar`. Its headline export,
`useAvatarEngine` (`engine.ts`), composes seven pieces — mood arbitration
(`arbitration.ts`), involuntary reflexes (`reflexes.ts`: blink, an inactivity
ladder, speech), cursor/gaze steering (`gaze.ts`), a baseline idle fidget
(`idleLife.ts`), a spoken-utterance popup (`speechBubble.ts`), and the
per-mood tween driver (`pose.ts`) — into a single hook that a React component
mounts and reads. It is a **logic** package: it renders no DOM of its own and
draws no pixels. It only reads and writes refs to SVG elements an avatar hands
it (the `AvatarRig`, `types.ts`) and schedules GSAP tweens/timers against them.

The engine deliberately knows nothing about any one avatar's anatomy or mood
vocabulary. An avatar supplies: its own expression type `E` (a string union),
a `Pose` per expression, an `AvatarRig` of SVG refs (every channel — eyes,
iris, antennae, brows, mouth, descender, face — is optional and skipped when
absent), and a `MoodMap<E>` telling the engine which of its own moods count as
the idle/bored/asleep resting states. A driver (e.g. a chat surface) supplies
`AvatarDriverProps<E>`: a deliberate `expression`, a forced `gaze`, an
`onSpeak` echo, and a `mute` flag. This split — identity + vocabulary on one
side, behavior mechanism on the other — is what lets the same engine drive
different personas without a fork.

## Behavioral Requirements

**Public surface and configuration**

- **public-api-surface**: The package MUST export `useAvatarEngine` together
  with every reflex/pose piece it composes — `useBlink`, `useIdleLadder`,
  `useSpeech`, `useArbitration`, `useGaze`, `useIdleFidget`, `useSpeechBubble`,
  `applyPose` — and `DEFAULT_TUNING`, so a consumer MAY compose a custom
  engine from the pieces instead of using `useAvatarEngine` (`index.ts`).
- **engine-return-shape**: `useAvatarEngine` MUST return an object with
  exactly four fields: `effective` (the mood to render), `resting` (the
  mood absent any transient), `speech` (the current utterance or `null`),
  and `poke` (the click handler) (`engine.ts` `AvatarEngine<E>`).
- **tuning-merge**: `useAvatarEngine` MUST compute its effective `Tuning` by
  shallow-merging the caller's optional `tuning` object over `DEFAULT_TUNING`
  field by field (`{ ...DEFAULT_TUNING, ...config.tuning }`), recomputed via
  `useMemo` keyed on `config.tuning`'s identity.
- **mood-map-fallback**: When computing the resting mood from the idle
  ladder, the engine MUST fall back to `moods.idle` whenever the ladder rung's
  corresponding mood (`moods.bored` for `"bored"`, `moods.asleep` for
  `"asleep"`) is not configured on the `MoodMap`.

**Mood arbitration (`useArbitration`)**

- **resting-mood-priority**: `resting` MUST equal `config.expression` when it
  is set; otherwise it MUST be derived from the current ladder rung:
  `"asleep"` → `moods.asleep ?? moods.idle`, `"bored"` → `moods.bored ??
  moods.idle`, `"active"` → `moods.idle`.
- **effective-mood-priority**: `effective` MUST resolve in this order: an
  active click reaction, else an active waking one-shot, else `resting`
  (`reaction ?? wakingMood ?? resting`). A click reaction MUST outrank a
  waking one-shot, and both MUST outrank the resting mood.
- **poke-invocation**: Calling the returned `poke()` MUST invoke
  `config.poke?.(resting)` and MUST take no further action when that call
  returns `null` or `undefined` (including when `poke` was not configured).
- **poke-reaction-timing**: When `poke(resting)` returns `{ expression, ms }`,
  the engine MUST show `expression` as the click reaction for `ms`
  milliseconds and then clear it, superseding any resting mood or waking
  one-shot for that duration.
- **poke-supersedes-pending-reaction**: A new accepted poke reaction MUST
  cancel any still-pending reaction timer from an earlier poke (`clearTimeout`
  of the previous timer) before scheduling its own — the most recent poke
  always wins and the earlier one never fires its own clear.
- **poke-cleanup-on-unmount**: Any pending reaction timer MUST be cleared
  when the component unmounts, so no state update is scheduled after unmount.
- **waking-trigger-condition**: A waking one-shot MUST play `waking.play` for
  `waking.ms` milliseconds if and only if all of: `waking` is configured, the
  resting mood on the immediately prior render equaled `waking.from`, the
  resting mood on the current render equals `waking.to`, and no click
  reaction is active at that moment.
- **waking-not-triggered-by-click**: The engine MUST NOT start a waking
  one-shot for a resting transition that coincides with an active click
  reaction, even if `waking.from`/`waking.to` otherwise match.
- **waking-supersedes-pending-waking**: A newly triggered waking one-shot
  MUST cancel any still-pending waking timer from an earlier one-shot before
  scheduling its own.
- **waking-cleanup-on-unmount**: Any pending waking timer MUST be cleared
  when the component unmounts.
- **curious-flag**: The internal `curious` flag (drives the idle fidget and
  the wide wander reach) MUST be true exactly when `effective === moods.idle`.
- **eyes-shut-flag**: The internal `eyesShut` flag MUST be true exactly when
  `moods.asleep` is defined and `effective === moods.asleep`.

**Blink (`useBlink`)**

- **blink-scheduling**: While `enabled` is true, `useBlink` MUST alternate
  between not-blinking and blinking on a randomized schedule: the gap before
  each blink MUST be a random value in `[minBlinkMs, maxBlinkMs)`, and each
  blink MUST hold for exactly `blinkDurationMs` before the next gap begins.
- **blink-disabled-no-schedule**: While `enabled` is false, `useBlink` MUST
  report `false` and MUST NOT schedule any pending blink.
- **blink-enable-condition**: `useAvatarEngine` MUST enable blinking only when
  the avatar is not eyes-shut and `effective` is not present in the
  `blinkSuppressed` list (defaulting to `[]` when omitted).
- **blink-independent-left-right**: The engine MUST run separate `useBlink`
  instances for the left and right eye so each schedules its own random
  blink independently of the other.

**Inactivity ladder (`useIdleLadder`)**

- **idle-ladder-domain**: `useIdleLadder` MUST report exactly one of
  `"active"`, `"bored"`, or `"asleep"`, starting at `"active"`.
- **idle-ladder-thresholds**: On a 400ms poll, the ladder MUST report
  `"asleep"` when elapsed idle time exceeds `tuning.asleepAfterMs`,
  `"bored"` when it exceeds `tuning.boredAfterMs` (and is not past
  `asleepAfterMs`), and `"active"` otherwise.
- **idle-ladder-pointer-reset**: A `pointermove` while the window has focus
  (`document.hasFocus()`) MUST reset the idle clock and, if the ladder is not
  already `"active"`, MUST flip it to `"active"` immediately, without waiting
  for the next poll tick.
- **idle-ladder-background-pointer-ignored**: A `pointermove` MUST be ignored
  (no idle-clock reset, no ladder change) while `document.hasFocus()` is
  false.
- **idle-ladder-typing-grace**: A `keydown` MUST reset the idle clock and set
  a grace deadline `tuning.alertAfterTypingMs` in the future; on every poll
  tick before that deadline, the idle clock MUST be held at zero, so the
  avatar stays `"active"` through the grace window rather than jumping
  straight from typing to `"bored"`/`"asleep"` when the deadline passes.
- **idle-ladder-pointerdown-reset**: A `pointerdown` MUST reset the idle
  clock, but — unlike `pointermove` — MUST NOT by itself force an immediate
  ladder change; the new rung is picked up on the next poll tick.
- **idle-ladder-expression-reset**: The idle clock MUST reset to zero at the
  moment `expressionActive` (`config.expression != null`) transitions to
  true.
- **idle-ladder-listener-teardown**: On unmount, the ladder MUST clear its
  poll interval and remove its `pointermove`/`keydown`/`pointerdown`
  listeners.

**Speech (`useSpeech`, echoed by `useAvatarEngine`)**

- **speech-emission-on-mood-change**: Whenever `effective` changes,
  `useSpeech` MUST look up the line list for the new mood
  (`poses[effective]?.sayings`); if the list is non-empty it MUST emit one
  randomly chosen line immediately, tagged with a freshly incremented `id`;
  if the list is empty or absent it MUST set speech to `null`.
- **speech-looping-while-asleep**: While the `looping` flag passed to
  `useSpeech` is true (the engine passes `eyesShut`), a new random line from
  the same mood's list MUST be emitted every `mutterMs` milliseconds, and
  this loop MUST stop the instant `effective` changes again.
- **speech-mute**: While `config.mute` is true, the value of `speech`
  returned by `useAvatarEngine` MUST be `null` regardless of what the
  underlying `useSpeech` reflex is producing, and `config.onSpeak` MUST NOT
  be invoked.
- **speech-echo**: For every distinct, non-null `speech.id` produced while
  `mute` is not true, `useAvatarEngine` MUST call `config.onSpeak(text)`
  exactly once with that utterance's text.

**Gaze (`useGaze`)**

- **gaze-eyes-shut-still**: While `eyesShut` is true, gaze MUST hold the
  iris centered `(0, 0)`, the head tilt at `0`, and the lean at `(0, 0)`, and
  MUST NOT install cursor tracking or wander.
- **gaze-forced-priority**: When both `forcedX` and `forcedY` are non-null,
  gaze MUST aim the iris at `(forcedX * gazeMax, forcedY * gazeMax)`, tilt
  the head to `-forcedX * tiltMax` degrees, and lean to
  `(forcedX, forcedY) * leanMax`, and MUST ignore the cursor and the wander
  scheduler while it does.
- **gaze-cursor-follow**: Absent a forced gaze and while eyes are not shut, a
  `pointermove` on `window` MUST steer the iris toward the cursor's direction
  from the rig's SVG center, clamped to `±gazeMax`, tilt the head toward it
  (sign negated so the head leans into the cursor), and lean toward it —
  recomputed at most once per animation frame via `requestAnimationFrame`.
- **gaze-cursor-leave-recenters**: A `mouseleave` on `document` MUST recenter
  the iris to `(0, 0)`.
- **gaze-wander-after-stillness**: Once the cursor has been still longer than
  `wanderAfterMs`, gaze MUST periodically (every random interval in
  `[wanderMinMs, wanderMaxMs)`) level the head tilt and lean back to neutral
  and either recenter the iris (probability `0.25` when `curious`, `0.35`
  otherwise) or aim it at a random angle at a reach fraction of `gazeMax`
  that is wider when `curious` (`0.45`–`0.90`) than when not (`0.12`–`0.32`).
- **gaze-optional-channel-noop**: Any rig channel gaze depends on (`iris`,
  `tiltLayer`, `leanLayer`) that is absent MUST make that channel's portion
  of gaze a no-op rather than throw.
- **gaze-listener-teardown**: On unmount (or when `forcedX`/`forcedY`/
  `curious`/`eyesShut` changes trigger the effect to rerun), gaze MUST cancel
  any pending animation frame and wander timeout and remove the
  `pointermove`/`mouseleave` listeners it installed.

**Idle fidget (`useIdleFidget`)**

- **idle-fidget-condition**: The idle fidget MUST run only while `curious` is
  true and `rig.idleLayer` is present; otherwise it MUST do nothing.
- **idle-fidget-breath-loop**: While active, the idle fidget MUST run a
  continuous breathing loop on `rig.idleLayer` — scale oscillating between
  `1` and `1.035` with a `2.6`s yoyo period — independent of the sway.
- **idle-fidget-sway-loop**: While active, the idle fidget MUST continually
  retarget a small random rotation on `rig.idleLayer` (magnitude up to
  `±3.5`°, recomputed on a `0.5`–`0.9`s cadence), except that the rotation
  MUST hold at `0` whenever the shared `watchingRef` timestamp shows the
  gaze drove a cursor-watch within the last `wanderAfterMs` milliseconds.
- **idle-fidget-brow-drift**: When `rig.brows` and the idle pose's
  `browLeft`/`browRight` are present, the idle fidget MUST also jitter each
  brow's rotation (`±3`°) and vertical offset (`±2` units) around the idle
  pose's resting brow values on the same cadence as the sway.
- **idle-fidget-teardown**: When the fidget stops (curious turns false, the
  idle layer disappears, or the component unmounts), it MUST clear its
  pending timer, kill the breathing tween, and tween `rig.idleLayer` back to
  rotation `0` / scale `1`.

**Pose application (`applyPose`, orchestrated by `useAvatarEngine`)**

- **pose-application-on-mood-change**: On every change of `effective`, the
  engine MUST first kill every previously tracked looping animation
  (`loopRef.current`), then either run `config.choreography[effective]`'s
  timeline if one is configured for that mood, or call `applyPose` with
  `poses[effective]` if that mood has a pose entry; if neither a
  choreography nor a pose entry exists for `effective`, the engine MUST do
  nothing further for that render (the rig keeps whatever pose it last
  applied).
- **choreography-replaces-per-pose-tweens**: When `effective` has a
  `choreography` entry, `applyPose` MUST NOT run for that mood — the
  choreography timeline is the sole driver of that mood's motion.
- **pose-channel-guard**: `applyPose` MUST tween a channel's properties only
  when that channel's ref(s) are present on the `AvatarRig`; an avatar that
  wires none of a channel's elements MUST NOT cause `applyPose` to throw for
  that channel.
- **body-scale-rotation**: When `rig.body` is wired, `applyPose` MUST tween
  its scale to `pose.scale ?? 1` and its rotation to
  `(pose.rotation ?? 0) + 360 * (pose.spinTurns ?? 0)` degrees (landing at
  the settled `rotation` after any extra entry spins), pivoting at
  `rig.pivot`, with `overwrite: "auto"` on that tween.
- **eyes-scale-and-spread**: When `rig.eyes` is wired, `applyPose` MUST scale
  each eye per `pose.eyeLeft`/`pose.eyeRight` (falling back to `pose.eye`
  when a per-eye override is absent), offset each horizontally by
  `±pose.spread` and vertically by `pose.eyeY ?? 0`.
- **iris-pupil-dilation**: When `rig.iris` is wired, `applyPose` MUST tween
  both irises' radius attribute to `rig.iris.baseR * (pose.pupil ?? 1)`.
- **antennae-per-pose-and-continuous-sway**: When `rig.antennae` is wired,
  `applyPose` MUST tween each antenna to its per-pose `lLeft`/`lRight`
  rotation/offset (when given) regardless of `eyesShut`. Additionally, when
  `eyesShut` is false, `applyPose` MUST run a continuous, out-of-phase bend
  loop whose amplitude is `sway.lively` (default `18`) when `pose.wiggle > 0`
  and `sway.calm` (default `8`) otherwise; while `eyesShut` is true, both
  antennae MUST instead settle their bend to a neutral, still value (on top
  of, not instead of, the per-pose rotation/offset tween).
- **brows-per-pose**: When `rig.brows` is wired and `pose.browLeft`/
  `pose.browRight` are given, `applyPose` MUST tween each brow's rotation and
  vertical offset, pivoting at that brow's own `svgOrigin`.
- **face-chameleon-color**: When `rig.face` is wired and `pose.body` is set,
  `applyPose` MUST tween the face group's color to `pose.body`; eyes keep
  their own explicit fills and are unaffected by this tween.
- **mouth-morph**: When `rig.mouth` is wired and `pose.mouth` is set,
  `applyPose` MUST morph the mouth path to `pose.mouth` via MorphSVG.
- **descender-toggle-and-flick**: When `rig.descender` is wired, `applyPose`
  MUST morph the descender to `rig.descender.logoPath` when `pose.showY` is
  true and to `plainPath` otherwise, and MUST additionally loop a `±9°`
  tail-flick when `pose.wiggle > 0`, settling to rotation `0` otherwise.
- **face-bob-loop**: When `rig.face` is wired, `applyPose` MUST loop a
  vertical bob of amplitude `pose.bob` (`0.5`s yoyo) when `pose.bob > 0`, and
  MUST otherwise tween the face back to `y = 0`.
- **face-wiggle-loop**: When `rig.face` is wired, `applyPose` MUST loop a
  rotation wiggle of amplitude `pose.wiggle` degrees (`0.16`s yoyo) when
  `pose.wiggle > 0`, and MUST otherwise tween the face back to rotation `0`.
- **pose-loops-returned-for-cleanup**: `applyPose` MUST return every looping
  animation it started (antennae sway, descender flick, face bob/wiggle) so
  the caller can kill them on the next pose change; one-shot tweens are not
  included in this return value.
- **blink-collapse-independent-of-pose**: Independent of any pose-driven eye
  scale, whenever `leftBlinking`/`rightBlinking` toggles, the engine MUST
  tween that eye's dedicated blink group (`blinkLeftRef`/`blinkRightRef`) to
  `scaleY: 0.06` while blinking and back to `scaleY: 1` when not, over
  `0.09`s.
- **per-expression-effect-lifecycle**: Whenever `effective` changes, the
  engine MUST invoke `perExpressionEffects[effective]` if one is configured,
  and MUST run any cleanup function that call returns before the next mood's
  effect starts (or on unmount).
- **unmount-kills-surviving-loops**: On unmount, the engine MUST kill any
  looping animations still tracked in `loopRef.current`, independent of and
  in addition to each reflex's own teardown.

**Module load and runtime model**

- **ssr-safe-plugin-registration**: The engine MUST register
  `MorphSVGPlugin` with GSAP only when `window` is defined at module load,
  so importing the engine in a non-browser environment does not throw.
- **concurrency-model**: All engine state transitions MUST occur on the
  single browser main thread, driven serially by React's effect scheduling,
  DOM event callbacks, and timer/animation-frame callbacks; the engine MUST
  NOT use worker threads or any concurrency primitive that could interleave
  two updates to the same ref.
- **no-persistence**: The engine MUST NOT persist any state beyond the
  lifetime of the mounted component; `effective`, `resting`, the ladder
  rung, blink phase, reaction, waking mood, and speech all live in in-memory
  React state and refs that are discarded on unmount.

**Speech bubble (`useSpeechBubble`)**

- **speech-bubble-pop-and-drift**: Whenever a new, non-null `speech.id`
  arrives and `speechRef.current` is mounted, the speech bubble MUST pop in
  (opacity `0→0.7`, scale `0.7→1`, over `0.22`s) and then drift off along a
  random angle within `±55°` of straight up, over a random distance of
  `40`–`90`px with a random `±12°` spin, fading to opacity `0` across a
  `1.3`s drift that starts after a `0.5`s hold.
- **speech-bubble-noop-without-ref-or-speech**: `useSpeechBubble` MUST do
  nothing when `speech` is `null` or when `speechRef`/`speechRef.current` is
  absent, so an avatar that wires no speech node can still call the engine.

**Recommended and optional composition**

- **morph-path-point-count-consistency**: Every pair of morph targets a
  single channel can be tweened between (a mouth's `pose.mouth` values
  across all of an expression table's poses; an antenna's bend outputs; a
  descender's `logoPath`/`plainPath`) SHOULD keep the same SVG path point
  count, because MorphSVGPlugin morphs point-for-point (`pose.ts`'s own
  comment: "Keep point counts matched").
- **choreography-optional**: An avatar MAY omit `choreography` entirely and
  rely solely on `applyPose` for every mood it defines.
- **compose-reflexes-directly**: A consumer MAY call the individual
  exported reflex/pose pieces directly instead of `useAvatarEngine`, to
  compose a custom engine (`index.ts`: "a custom avatar can compose them
  differently if it needs to").

**Unvalidated input — genuine gaps**

- **morph-point-count-validation**: Matching point counts between morph targets on the same channel is an authoring precondition (see **morph-path-point-count-consistency**); nothing in `pose.ts` checks it before calling `gsap.to(..., { morphSVG: ... })`, so a mismatched pair is handed to MorphSVGPlugin as-is and its outcome is whatever the pinned `gsap`/`MorphSVGPlugin` version does.
- **pose-shape-validation**: `Pose` and `Tuning` shapes are enforced only by TypeScript's compile-time types in `types.ts`; there is no runtime schema check, and every pose table in this source is authored in TypeScript, so a well-typed value is a caller precondition. A value that bypasses the type checker (e.g. a JSON- or CMS-authored table) is passed through unchecked.

## Appearance

Not applicable — this is a headless behavior/animation engine with no visual
surface of its own; it only tweens SVG elements an avatar supplies through
`AvatarRig` (`types.ts`).

## States

Not applicable — this is a headless behavior/animation engine, not a visual
component with a visual-state table; its runtime state machines (the mood
arbitration and the inactivity ladder) are specified under Behavioral
Requirements above, not here.

## Accessibility

Not applicable — this is a headless behavior/animation engine with no
role, label, or focusable surface of its own; any such concerns belong to
the avatar component that renders the SVG this engine animates.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| avatar-behavior-001 | public-api-surface | Import `* as Avatar from "./index"`; check `useAvatarEngine`, `useBlink`, `useIdleLadder`, `useSpeech`, `useArbitration`, `useGaze`, `useIdleFidget`, `useSpeechBubble`, `applyPose`. | `typeof` each is `"function"` (per `engine.test.ts`'s existing smoke test). |
| avatar-behavior-002 | tuning-merge | `config.tuning` omitted. | The engine's effective tuning equals `DEFAULT_TUNING` exactly (every field of `DEFAULT_TUNING` is a `number`, per `engine.test.ts`). |
| avatar-behavior-003 | tuning-merge | `config.tuning = { boredAfterMs: 1000 }`. | Effective tuning has `boredAfterMs: 1000` and every other field equal to `DEFAULT_TUNING`'s value (e.g. `gazeMax: 7`). |
| avatar-behavior-004 | resting-mood-priority | `expression` unset, `ladder = "active"`, `moods = { idle: "calm" }`. | `resting === "calm"`. |
| avatar-behavior-005 | resting-mood-priority, mood-map-fallback | `expression` unset, `ladder = "bored"`, `moods = { idle: "calm" }` (no `bored` entry). | `resting === "calm"` (falls back to idle). |
| avatar-behavior-006 | resting-mood-priority | `expression = "angry"`, `ladder = "asleep"`, `moods = { idle: "calm", asleep: "sleepy" }`. | `resting === "angry"` (deliberate expression overrides the ladder entirely). |
| avatar-behavior-007 | effective-mood-priority | `resting = "calm"`, a click reaction is active (`"surprised"`), a waking one-shot is also pending (`"yawn"`). | `effective === "surprised"` (reaction outranks waking one-shot and resting). |
| avatar-behavior-008 | effective-mood-priority | `resting = "calm"`, no click reaction active, waking one-shot active (`"yawn"`). | `effective === "yawn"`. |
| avatar-behavior-009 | effective-mood-priority | `resting = "calm"`, no reaction, no waking one-shot. | `effective === "calm"`. |
| avatar-behavior-010 | poke-invocation | `config.poke` returns `null` for the current `resting`. | Calling `poke()` produces no reaction; `effective` is unchanged. |
| avatar-behavior-011 | poke-invocation | `config.poke` is `undefined`. | Calling `poke()` is a no-op; no error is thrown. |
| avatar-behavior-012 | poke-reaction-timing | `config.poke` returns `{ expression: "surprised", ms: 500 }`. | Immediately after calling `poke()`, `effective === "surprised"`; after 500ms with no further calls, `effective` returns to `resting`. |
| avatar-behavior-013 | poke-supersedes-pending-reaction | `poke()` is called, then called again with a different reaction 100ms later (before the first 500ms reaction would clear). | Only the second reaction's timer fires; the first reaction's expiry never runs, and the reaction visible at 100ms+1ms is the second one. |
| avatar-behavior-014 | poke-cleanup-on-unmount | `poke()` is called (reaction pending), then the component unmounts before the reaction's `ms` elapses. | No state update fires after unmount (no console warning / act() violation in a test harness). |
| avatar-behavior-015 | waking-trigger-condition | `waking = { from: "sleepy", to: "calm", play: "yawn", ms: 800 }`; prior render's `resting === "sleepy"`, current render's `resting === "calm"`, no reaction active. | `effective === "yawn"` for the next 800ms, then falls back to `resting`. |
| avatar-behavior-016 | waking-not-triggered-by-click | Same transition as avatar-behavior-015, but a click reaction is active at that moment. | No waking one-shot starts; `effective` is the active click reaction. |
| avatar-behavior-017 | waking-trigger-condition | Prior `resting === "calm"`, current `resting === "sleepy"` (the reverse direction of `waking.from`/`to`). | No waking one-shot starts; `effective === "sleepy"`. |
| avatar-behavior-018 | curious-flag, eyes-shut-flag | `moods = { idle: "calm", asleep: "sleepy" }`, `effective === "sleepy"`. | `curious === false`, `eyesShut === true`. |
| avatar-behavior-019 | curious-flag, eyes-shut-flag | `effective === moods.idle`. | `curious === true`, `eyesShut === false`. |
| avatar-behavior-020 | blink-scheduling | `enabled = true`, `tuning = { minBlinkMs: 100, maxBlinkMs: 200, blinkDurationMs: 50, ... }`. | Within any 300ms window, `useBlink` reports `true` for exactly one contiguous `50`ms stretch, preceded by a gap between `100` and `200`ms. |
| avatar-behavior-021 | blink-disabled-no-schedule | `enabled = false`. | `useBlink` returns `false` and schedules nothing (no timer fires later even if `enabled` never flips true). |
| avatar-behavior-022 | blink-enable-condition | `eyesShut = true`. | Blink is disabled regardless of `blinkSuppressed`. |
| avatar-behavior-023 | blink-enable-condition | `eyesShut = false`, `blinkSuppressed = ["laughing"]`, `effective === "laughing"`. | Blink is disabled. |
| avatar-behavior-024 | idle-ladder-domain, idle-ladder-thresholds | No activity for longer than `asleepAfterMs` (default `14000`ms). | Ladder reports `"asleep"`. |
| avatar-behavior-025 | idle-ladder-thresholds | No activity for longer than `boredAfterMs` (`6000`ms) but less than `asleepAfterMs`. | Ladder reports `"bored"`. |
| avatar-behavior-026 | idle-ladder-pointer-reset | Ladder is `"bored"`; a focused-window `pointermove` fires. | Ladder flips to `"active"` immediately, before the next 400ms poll tick. |
| avatar-behavior-027 | idle-ladder-background-pointer-ignored | Ladder is `"bored"`; `document.hasFocus()` returns `false`; a `pointermove` fires. | Ladder remains `"bored"`. |
| avatar-behavior-028 | idle-ladder-typing-grace | A `keydown` fires; `alertAfterTypingMs = 30000`. | For the next 30000ms, poll ticks keep the ladder `"active"` even with no further input; after 30000ms with still no input, the ladder begins counting toward `"bored"`. |
| avatar-behavior-029 | idle-ladder-pointerdown-reset | Ladder is `"bored"`; a `pointerdown` fires. | The idle clock resets (so a poll tick shortly after reports `"active"`), but the ladder does not flip synchronously the instant `pointerdown` fires. |
| avatar-behavior-030 | idle-ladder-expression-reset | `expressionActive` flips from `false` to `true`. | The idle clock resets to zero at that instant. |
| avatar-behavior-031 | speech-emission-on-mood-change | `effective` changes to a mood whose `sayings` list is `["hi", "hello"]`. | `speech` becomes `{ text: <"hi" or "hello">, id: <incremented> }` immediately. |
| avatar-behavior-032 | speech-emission-on-mood-change | `effective` changes to a mood with no `sayings` entry. | `speech` becomes `null`. |
| avatar-behavior-033 | speech-looping-while-asleep | `effective === moods.asleep`, `looping = true`, `sleepMutterMs = 11000`. | A new random line (new `id`) is emitted every 11000ms until `effective` changes. |
| avatar-behavior-034 | speech-mute | `mute = true`, the underlying reflex has a non-null utterance. | `useAvatarEngine`'s returned `speech` is `null`; `onSpeak` is not called. |
| avatar-behavior-035 | speech-echo | `mute` is falsy; `useSpeech` emits `{ text: "hi", id: 3 }`. | `config.onSpeak("hi")` is called exactly once for `id: 3`. |
| avatar-behavior-036 | gaze-eyes-shut-still | `eyesShut = true`. | Iris is at `(0,0)`, tilt is `0`, lean is `(0,0)`; no `pointermove`/`mouseleave` listeners are installed. |
| avatar-behavior-037 | gaze-forced-priority | `forcedX = 1`, `forcedY = -1`, `gazeMax = 7`, `tiltMax = 9`, `leanMax = 6`. | Iris targets `(7, -7)`; tilt targets `-9`°; lean targets `(6, -6)`; a simultaneous cursor move is ignored. |
| avatar-behavior-038 | gaze-cursor-follow | No forced gaze, eyes not shut; cursor moves to a point directly right of the rig's SVG center. | Iris targets `(gazeMax, 0)`; head tilts toward the cursor; lean moves toward it. |
| avatar-behavior-039 | gaze-cursor-leave-recenters | A `mouseleave` fires on `document`. | Iris recenters to `(0,0)`. |
| avatar-behavior-040 | gaze-wander-after-stillness | Cursor has been still for longer than `wanderAfterMs` (`1200`ms), `curious = true`. | Within `wanderMinMs`–`wanderMaxMs` (`1400`–`3200`ms), the iris either recenters or moves to a point at `0.45`–`0.90` of `gazeMax` from center; tilt/lean level to neutral first. |
| avatar-behavior-041 | idle-fidget-condition | `curious = false`. | The idle fidget starts no breathing or sway loop. |
| avatar-behavior-042 | idle-fidget-breath-loop | `curious = true`, `rig.idleLayer` present. | `rig.idleLayer`'s scale continuously oscillates between `1` and `1.035` on a `2.6`s yoyo. |
| avatar-behavior-043 | idle-fidget-sway-loop | `curious = true`, `watchingRef.current` is older than `wanderAfterMs` ago. | `rig.idleLayer`'s rotation retargets to a new random value within `±3.5°` every `0.5`–`0.9`s. |
| avatar-behavior-044 | idle-fidget-sway-loop | `curious = true`, `watchingRef.current` is within the last `wanderAfterMs`. | `rig.idleLayer`'s rotation target holds at `0` (breathing continues unaffected). |
| avatar-behavior-045 | idle-fidget-teardown | `curious` flips from `true` to `false`. | The fidget timer is cleared, the breath tween is killed, and `rig.idleLayer` tweens back to rotation `0` / scale `1`. |
| avatar-behavior-046 | pose-application-on-mood-change | `effective` changes to a mood present in `poses` with no `choreography` entry. | `applyPose(rig, poses[effective], eyesShut, ...)` runs; any previously tracked loop animations are killed first. |
| avatar-behavior-047 | pose-application-on-mood-change, choreography-replaces-per-pose-tweens | `effective` changes to a mood with a `choreography` entry. | The choreography's timeline runs; `applyPose` is not called for that mood. |
| avatar-behavior-048 | pose-application-on-mood-change | `effective` changes to a mood present in neither `poses` nor `choreography`. | No new tween/timeline starts; the rig visually keeps whatever pose it last applied. |
| avatar-behavior-049 | pose-channel-guard | `rig` wires only `svg` and `pivot` (no other channels). | `applyPose` runs without throwing and produces no tweens on any channel. |
| avatar-behavior-050 | body-scale-rotation | `pose = { scale: 1.2, rotation: 10, spinTurns: 1, dur: 0.4, ease: "power3.out" }`. | `rig.body`'s element tweens scale to `1.2` and rotation to `370` (`10 + 360*1`) about `rig.pivot`. |
| avatar-behavior-051 | antennae-per-pose-and-continuous-sway | `pose.wiggle = 5` (lively), `eyesShut = false`. | Each antenna loops its bend at amplitude `sway.lively` (`18` by default), out of phase between the two sides. |
| avatar-behavior-052 | antennae-per-pose-and-continuous-sway | `eyesShut = true`. | Both antennae settle to a neutral bend and hold still; no sway loop runs. |
| avatar-behavior-053 | descender-toggle-and-flick | `pose.showY = true`, `pose.wiggle = 0`. | Descender morphs to `rig.descender.logoPath`; no tail-flick loop runs. |
| avatar-behavior-054 | descender-toggle-and-flick | `pose.showY = false`, `pose.wiggle = 5`. | Descender morphs to `plainPath`; a `±9°` tail-flick loops. |
| avatar-behavior-055 | face-bob-loop, face-wiggle-loop | `pose.bob = 0`, `pose.wiggle = 0`. | The face group tweens to `y = 0` and `rotation = 0`; no loop is started. |
| avatar-behavior-056 | blink-collapse-independent-of-pose | `leftBlinking` toggles `true` then `false`. | The left blink group's `scaleY` tweens to `0.06` then back to `1`, over `0.09`s each way, independent of the pose's own eye scale. |
| avatar-behavior-057 | per-expression-effect-lifecycle | `perExpressionEffects[effective]` returns a cleanup function; `effective` then changes again. | The cleanup function is called before the next mood's effect (or the new pose) is applied. |
| avatar-behavior-058 | unmount-kills-surviving-loops | Component unmounts while a looping antenna-sway tween is active. | The tween is killed on unmount; no animation continues against a detached element. |
| avatar-behavior-059 | ssr-safe-plugin-registration | The module is imported in a non-browser (SSR) module evaluation context (`typeof window === "undefined"`). | Import does not throw; `gsap.registerPlugin(MorphSVGPlugin)` is not called. |
| avatar-behavior-060 | speech-bubble-pop-and-drift | `speechRef.current` mounted; `speech = { text: "hi", id: 1 }`. | The bubble's timeline runs: opacity `0→0.7`/scale `0.7→1` over `0.22`s, then a `0.5`s hold, then a `1.3`s drift to `0` opacity along a computed `(driftX, driftY)` within `±55°` of straight up. |
| avatar-behavior-061 | speech-bubble-noop-without-ref-or-speech | `speech = null`. | `useSpeechBubble` starts no timeline. |
| avatar-behavior-062 | morph-point-count-validation | Two poses for the same mouth channel whose `pose.mouth` path strings have a different point count. | The engine passes both paths to MorphSVGPlugin unchecked; the outcome is the plugin's, so the test asserts only that no engine-side validation or fallback runs. |

## Edge Cases

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

## Configuration

`useAvatarEngine` takes one `AvatarEngineConfig<E>` object; there are no
environment variables, settings keys, or files involved — every input is a
typed field on that object (`engine.ts`, `types.ts`).

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `poses` | `Record<E, Pose>` | required | One `Pose` per expression the avatar defines. |
| `rig` | `AvatarRig` | required | The avatar's SVG refs + geometry; every channel beyond `svg`/`pivot` is optional. |
| `moods` | `MoodMap<E>` | required (`idle` mandatory) | Maps the idle ladder's rungs to this avatar's mood vocabulary. |
| `expression` | `E \| undefined` | `undefined` | A driver-set deliberate mood; overrides the ladder-derived resting mood. |
| `gaze` | `{ x: number; y: number } \| null \| undefined` | `undefined` | A forced, normalized gaze direction; clamped to `[-1, 1]` on each axis before use. |
| `onSpeak` | `(text: string) => void \| undefined` | `undefined` | Echoed with each unmuted utterance's text. |
| `mute` | `boolean \| undefined` | falsy | Suppresses the returned `speech` value and `onSpeak` calls without stopping the underlying reflex. |
| `poke` | `(resting: E) => { expression: E; ms: number } \| null \| undefined` | `undefined` | Click-reaction policy; omit for no click reaction. |
| `waking` | `WakingConfig<E> \| undefined` | `undefined` | A one-shot mood played across a specific resting-mood transition. |
| `choreography` | `Partial<Record<E, Choreography<E>>> \| undefined` | `undefined` | Per-mood GSAP timelines that replace `applyPose` for that mood. |
| `perExpressionEffects` | `Partial<Record<E, ExpressionEffect>> \| undefined` | `undefined` | Incidental per-mood side effects and their cleanup. |
| `blinkSuppressed` | `E[] \| undefined` | `[]` | Moods during which blinking is paused. |
| `tuning` | `Partial<Tuning> \| undefined` | `{}` (merged over `DEFAULT_TUNING`) | Overrides for any subset of the 15 timing/limit fields in `Tuning`. |

`Tuning`'s fields and `DEFAULT_TUNING`'s values (`types.ts`):

| Field | Default | Description |
|-------|---------|-------------|
| `gazeMax` | `7` | Max iris travel, viewBox units. |
| `tiltMax` | `9` | Max head-tilt toward a deliberate gaze, degrees. |
| `leanMax` | `6` | Max whole-glyph lean toward what's watched, viewBox units. |
| `wanderAfterMs` | `1200` | Cursor-still time before idle wander/sway begins. |
| `wanderMinMs` | `1400` | Minimum gap between idle glances. |
| `wanderMaxMs` | `3200` | Maximum gap between idle glances. |
| `blinkDurationMs` | `130` | How long a blink holds shut. |
| `minBlinkMs` | `2800` | Minimum gap between blinks. |
| `maxBlinkMs` | `7000` | Maximum gap between blinks. |
| `boredAfterMs` | `6000` | Inactivity before the ladder reports `"bored"`. |
| `asleepAfterMs` | `14000` | Inactivity before the ladder reports `"asleep"`. |
| `alertAfterTypingMs` | `30000` | How long typing holds the ladder `"active"`. |
| `sleepMutterMs` | `11000` | Loop period for asleep muttering. |
| `swayCalm` | `8` | Antenna sway amplitude, non-lively poses. |
| `swayLively` | `18` | Antenna sway amplitude, `wiggle > 0` poses. |

## Deep Linking

Not applicable: the engine is a React hook composition with no route, URL,
or navigation surface of its own (`engine.ts`, `arbitration.ts`, `gaze.ts`,
`idleLife.ts`, `pose.ts`, `reflexes.ts`, `speechBubble.ts`, `types.ts`
register no router, history, or URL handling of any kind).

## Localization

Not applicable: the engine defines no user-facing strings of its own. The
only text it ever surfaces is `speech.text`, and that text always comes from
the caller's own `Pose.sayings` list (looked up via `poses[e]?.sayings` in
`engine.ts`) — the engine only picks which already-authored line to show and
when, via `useSpeech` in `reflexes.ts`. There is nothing here for this
recipe to externalize.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not implemented: the engine drives several unconditional, indefinite animation loops (idle-fidget breathing and sway in `idleLife.ts`, the antenna sway and face bob/wiggle loops in `pose.ts`, the blink cadence in `reflexes.ts`, the gaze wander in `gaze.ts`) with no check against `prefers-reduced-motion` and no configuration field (in `AvatarEngineConfig` or `Tuning`) to disable or dampen idle motion — a grep of the whole package for `matchMedia`/`reduce`/`prefers` finds nothing. |
| Increase Contrast | Not applicable: color for a mood comes entirely from the caller's `pose.body` value and the rig's own fills; `applyPose`'s `faceEl` tween (**face-chameleon-color**) only interpolates toward whatever color the avatar supplies — the engine sets no palette of its own. |
| Differentiate Without Color | Not applicable: moods are differentiated by pose geometry (eye/mouth/brow/antenna shape via `Pose`) that the avatar author supplies through `AvatarRig`, not by the engine encoding state through color alone. |

## Feature Flags

Not applicable: no file in this source checks a feature-flag key or
environment-conditional switch; whether the engine runs at all is entirely
the mounting avatar's decision.

## Analytics

Not applicable: the engine emits no analytics events. `onSpeak` is a
behavioral echo of spoken text to the driver (**speech-echo**), not an
analytics call, and nothing else in the source calls out to a tracking
service.

## Privacy

Not applicable: the engine collects, stores, and transmits nothing. Its only
outbound call is `config.onSpeak(text)`, echoing text the avatar itself
already authored in its `Pose.sayings`; there is no user input capture, no
persisted data, and no network transmission anywhere in `engine.ts`,
`arbitration.ts`, `gaze.ts`, `idleLife.ts`, `pose.ts`, `reflexes.ts`,
`speechBubble.ts`, or `types.ts`.

## Logging

Not applicable: no file in this source calls `console.*` or any logging
API; failures are silent (guarded no-ops), not logged.

## Platform Notes

- **React/Web**: The reference implementation. `useAvatarEngine` (`engine.ts`)
  composes `useArbitration` (`arbitration.ts`), `useBlink`/`useIdleLadder`/
  `useSpeech` (`reflexes.ts`), `useGaze` (`gaze.ts`), `useIdleFidget`
  (`idleLife.ts`), `useSpeechBubble` (`speechBubble.ts`), and `applyPose`
  (`pose.ts`) against the shape defined in `types.ts`. Every file is marked
  `"use client"` (a Next.js App Router boundary — this code never runs on
  the server render pass). Tweening is GSAP (`gsap.to`, `gsap.quickTo`,
  `gsap.timeline`) with the `MorphSVGPlugin` registered once, guarded by a
  `typeof window !== "undefined"` check at module scope. Cursor tracking
  uses `window`/`document` pointer events throttled to one recomputation per
  `requestAnimationFrame`; all other scheduling uses `setTimeout`/
  `setInterval`. The engine's own package is
  `packages/web/packages/avatar/src/`.
- **SwiftUI**: There is no direct SwiftUI equivalent of a headless React
  hook, so port the contract as an `@Observable` (or `ObservableObject`)
  class exposing `effective`/`resting`/`speech` and a `poke()` method, owned
  by whatever `View` renders the persona. Replace GSAP tweens with
  `withAnimation`/`Animation` on `AnimatableData`, or drive continuous loops
  (breathing, sway, wander) from a `TimelineView(.animation)` or a
  `Task`-based loop using `Task.sleep`. There is no MorphSVG equivalent for
  the mouth/antenna/descender path morphs — interpolate `Shape.path(in:)`
  via `AnimatableData`, or fall back to `CAShapeLayer` path animation
  through `UIViewRepresentable`/`NSViewRepresentable`. Cursor-follow gaze is
  macOS-only (`onContinuousHover`/`NSTrackingArea`); there is no pointer
  concept on iOS to mirror it. Model `Record<E, Pose>` as
  `[E: Pose]`/a `Dictionary`, and `MoodMap<E>` as a small `struct` with one
  required and two optional `E` properties, matching `types.ts` exactly.
- **Compose**: Model the engine as a `ViewModel`/plain class holding
  `mutableStateOf` for `effective`/`resting`/`speech`, with `poke()` as a
  method. Use `LaunchedEffect`/`rememberCoroutineScope` with `delay()` in
  place of `setTimeout`/`setInterval` for the reaction, waking, blink,
  ladder-poll, wander, and mutter timers, and `Animatable`/
  `animateFloatAsState` in place of GSAP's `quickTo`/`to`. There is no
  MorphSVG equivalent; approximate mouth/antenna/descender morphs with
  `AnimatedVectorDrawable` keyframes or manual point interpolation over a
  `Path`. Cursor-follow gaze has no direct mobile analogue (pointer-hover
  input); reserve it for a pointer-capable target (e.g. Compose for
  Desktop's `PointerInputScope`) and treat wander as the primary gaze
  behavior on touch-only targets.
- **AppKit / UIKit**: Replace `requestAnimationFrame`-throttled pointer
  tracking with `NSTrackingArea` mouse-moved events (AppKit) or
  `UIHoverGestureRecognizer` (iOS 13.4+, pointer-capable devices only,
  otherwise omit cursor-follow gaze entirely and rely on wander). Use
  `CADisplayLink` for the continuous loops (breathing, antenna sway, face
  bob/wiggle) and `Timer`/`DispatchQueue.main.asyncAfter` for one-shot and
  polled schedules (reaction clear, waking clear, blink cadence, ladder
  poll, wander, mutter) — mirroring GSAP's `to()`/`quickTo()` with
  `CABasicAnimation`/`CAKeyframeAnimation` on `CALayer` transforms, and
  path morphs with `CAShapeLayer.path` animations (`CGPath`
  interpolation) in place of MorphSVGPlugin. `AvatarRig`'s transform layers
  (`body`, `tiltLayer`, `leanLayer`, `idleLayer`) map to distinct
  `CALayer`s so their transforms compose the same way `svgOrigin`-scoped
  GSAP tweens do here.
- **WinUI 3**: This is the reason this recipe exists — there is no existing
  Windows port. Model `AvatarEngineConfig`/`AvatarEngine` as a class
  implementing `INotifyPropertyChanged` (or a `CommunityToolkit.Mvvm`
  `ObservableObject`) exposing `Effective`, `Resting`, `Speech` properties
  and a `Poke()` method, in place of the hook's return value. Use
  `DispatcherQueueTimer`/`DispatcherTimer` for every scheduled/polled
  callback (`setTimeout`→one-shot `DispatcherTimer`, `setInterval`→repeating
  `DispatcherTimer`): the reaction/waking clear timers, the `400`ms ladder
  poll, the blink cadence, the wander schedule, and the sleep-mutter loop.
  Use `Microsoft.UI.Composition`'s `ScalarKeyFrameAnimation`/
  `Vector3KeyFrameAnimation` (or XAML `Storyboard`s) as the `gsap.to`/
  `quickTo` equivalent for scale, rotation, and translate tweens on
  `Visual`/`CompositionVisual` layers standing in for `AvatarRig`'s
  `body`/`tiltLayer`/`leanLayer`/`idleLayer`. There is no MorphSVGPlugin
  equivalent in WinUI 3: animate between two `CanvasGeometry` path strings
  (Win2D) with a custom point-interpolating `ICompositionAnimationBase`, or
  swap discrete `PathIcon`/`Path` `Data` values if true point-for-point
  morphing is not required. Handle `PointerMoved`/`PointerExited` on the
  root `Grid`/`Canvas` for cursor-follow gaze — a plain `PointerMoved` on
  `Window.Content` fires far more often than GSAP's rAF throttle, so debounce
  it to one recomputation per `CompositionTarget.Rendering` tick to match
  **gaze-cursor-follow**'s cadence. Model `Record<E, Pose>` as
  `IReadOnlyDictionary<TExpression, Pose>` and `Tuning` as a plain record
  type with the same 15 fields.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/avatar/src/` | unverified |

## Design Decisions

- **Decision**: Rank a click reaction above a waking one-shot, and both
  above the resting mood, when computing `effective`
  (**effective-mood-priority**).
  **Rationale**: A user-triggered poke is the most immediate, most
  intentional signal the engine ever receives; letting an ambient natural
  transition (like a waking yawn) or the plain resting mood override it
  would make the avatar feel unresponsive to direct interaction. The
  reverse priority — resting outranking waking, or waking outranking a
  click — is never checked anywhere in `arbitration.ts`.
  **Approved**: pending

- **Decision**: Use `overwrite: "auto"` on the body scale/rotation tween in
  `applyPose` (**body-scale-rotation**).
  **Rationale**: Documented directly in `pose.ts`: React re-runs this
  effect — including React Strict Mode's intentional double-invoke of
  effects in development — and without `overwrite: "auto"`, the resulting
  duplicate transform tweens on the same element cancel each other back to
  an identity transform, visually snapping the avatar flat. This is a
  workaround for a real defect class, not a stylistic preference.
  **Approved**: pending

- **Decision**: Give the antenna bend loop a bbox-relative `transformOrigin`
  (`origin?: string`, default `"50% 0%"`) instead of an absolute
  `svgOrigin` (**antennae-per-pose-and-continuous-sway**).
  **Rationale**: Documented directly in `pose.ts`: an absolute `svgOrigin`
  was tried and drifted unboundedly, because GSAP re-derives an SVG origin
  against the element's *current* bounding box, and the antenna path is
  continuously morphed by the sway loop itself — each morph shifts the
  bbox out from under an absolute origin. A bbox-relative origin
  re-resolves cleanly on every tween instead.
  **Approved**: pending

- **Decision**: Scope the pose-application, per-expression-effect, and
  onSpeak-echo effects' dependency arrays to `[effective]` only (each
  carries an explicit `eslint-disable-next-line react-hooks/exhaustive-deps`
  in `engine.ts`), rather than also depending on `poses`, `rig`, `tuning`,
  `choreography`, or `perExpressionEffects`.
  **Rationale**: These objects are expected to be stable across a mounted
  avatar's lifetime (an avatar's pose table and rig don't change shape at
  runtime); scoping to `[effective]` avoids re-killing and re-starting
  loop tweens on every unrelated re-render. The real cost, honestly stated:
  if a caller *does* mutate `poses`, `tuning`, `rig`, `choreography`, or
  `perExpressionEffects` in place without changing `effective`, the engine
  will not pick up the change until the next mood transition — this is the
  documented trade-off, not an oversight.
  **Approved**: pending

- **Decision**: Keep the underlying `useSpeech` reflex running while
  `mute` is true, and only null out the value `useAvatarEngine` returns
  (**speech-mute**), rather than suspending the reflex itself.
  **Rationale**: Muting is presented to the driver as "keeps its
  expressions but stays silent," not as pausing the mood-driven speech
  cadence. Keeping the reflex live means unmuting mid-cycle resumes
  naturally at whatever point the internal cadence has reached, instead of
  restarting the utterance schedule from the moment of unmuting.
  **Approved**: pending

- **Decision**: Keep morph-target point-count matching to a source comment
  and a SHOULD requirement (**morph-path-point-count-consistency**) rather
  than a validated MUST, and record both as caller preconditions instead of
  inventing enforcement the source doesn't have.
  **Rationale**: The source truly performs no such validation anywhere
  (`pose.ts`, `types.ts`); documenting an enforcement mechanism that
  doesn't exist would be source-fidelity idealization. See
  **morph-point-count-validation** and **pose-shape-validation**.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | failed | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |

Statuses rest on the source: identity (SVG/pose data) and behavior (this
engine) are cleanly split — no avatar's anatomy or mood names are baked into
`engine.ts`/`arbitration.ts`/`pose.ts` — so separation-of-concerns passes.
`engine.test.ts` is an explicit smoke test only (its own comment: "the
engine is a GSAP-driven hook — its motion is verified in-app, it can't be
asserted headless"); it checks the exported surface and that
`DEFAULT_TUNING` has 13 numeric fields, but omits `swayCalm`/`swayLively`
from that check and asserts none of the arbitration, blink, ladder, gaze, or
pose behavior itself, so unit-test-coverage is partial rather than passed.
No file in this source contains a `try`/`catch`, a validation guard on
`Pose`/`Tuning` shape, or a check on MorphSVG point counts, so
explicit-error-handling fails outright (see **morph-point-count-validation**
and **pose-shape-validation**). Every timer and tween is paired with a
teardown (cleared timeouts/intervals, killed GSAP animations, removed event
listeners) across `arbitration.ts`, `gaze.ts`, `idleLife.ts`, and
`engine.ts`'s own unmount effect, so fault-tolerance passes. Every channel
on `AvatarRig` is optional and every dependent effect checks for its
presence before acting, so an avatar wiring only a subset of channels still
runs without error — graceful-degradation passes. A grep of the whole
package for `matchMedia`/`reduce`/`prefers`/`contrast` finds nothing, while
several loops (breathing, sway, blink, wander) run unconditionally and
indefinitely, so reduced-motion fails (see the Accessibility Options
section above). Accessibility categories beyond reduced-motion,
internationalization, security, and privacy checks are not listed here
because this engine has no visible surface, no user-facing strings, no
authentication/credential handling, and no data collection for those
categories to apply to (see the Accessibility, Localization, and Privacy
sections above).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Claude Sonnet 5 | Initial creation from the `@adh-sdk/avatar` web source (engine, arbitration, gaze, idleLife, pose, reflexes, speechBubble, types); flagged three genuine gaps — unvalidated MorphSVG point-count matching, unvalidated Pose/Tuning shape at runtime, and no reduced-motion accommodation for the engine's continuous idle loops — with the open question and evidence needed for each recorded in place. |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.0.2 | 2026-09-25 | Mike Fullerton | Antennae per-pose rotation/offset tween now runs regardless of eyesShut; neutral bend applies on top, not instead. |
