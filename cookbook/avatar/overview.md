
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

