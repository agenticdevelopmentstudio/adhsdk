
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

