
Not applicable: the engine defines no user-facing strings of its own. The
only text it ever surfaces is `speech.text`, and that text always comes from
the caller's own `Pose.sayings` list (looked up via `poses[e]?.sayings` in
`engine.ts`) — the engine only picks which already-authored line to show and
when, via `useSpeech` in `reflexes.ts`. There is nothing here for this
recipe to externalize.

