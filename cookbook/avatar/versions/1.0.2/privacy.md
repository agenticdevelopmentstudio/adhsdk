
Not applicable: the engine collects, stores, and transmits nothing. Its only
outbound call is `config.onSpeak(text)`, echoing text the avatar itself
already authored in its `Pose.sayings`; there is no user input capture, no
persisted data, and no network transmission anywhere in `engine.ts`,
`arbitration.ts`, `gaze.ts`, `idleLife.ts`, `pose.ts`, `reflexes.ts`,
`speechBubble.ts`, or `types.ts`.

