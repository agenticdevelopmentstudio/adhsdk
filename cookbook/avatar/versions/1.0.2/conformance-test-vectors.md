
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

