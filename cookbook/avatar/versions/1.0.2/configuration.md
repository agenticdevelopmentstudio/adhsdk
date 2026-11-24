
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

