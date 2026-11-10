
Avatar Engine is the top-level orchestrator of the cross-platform avatar
animation stack: `Engine` (`Engine.swift`, the Apple `AvatarAnimationEngine`
package) and `createEngine` (`engine.ts`, the
`@adh-sdk/avatar-engine` web package) are two independent
implementations of the same deterministic, frame-clocked state machine, built
to produce byte-for-byte identical output from the same seed, the same
`CharacterConfig`, and the same sequence of `tick`/command calls. It is a
headless **engine** — no visual surface of its own — that composes a
`CharacterConfig` (documented in
[adhsdk.ingredient.avatar-animation-engine.config](cookbook:d3e1f776-8ad1-431f-9485-386ac285a039)), a `Prng`
([adhsdk.ingredient.avatar-animation-engine.math](cookbook:471eb7b8-6821-4fd3-ab89-022c56757421)), and a
`Channels`/`Scheduler`/`Tweens` runtime
([adhsdk.ingredient.avatar-animation-engine.runtime](cookbook:74ba9dde-4963-42cb-aa03-bf1ee4dcc794)) with two internal
collaborators not covered by this recipe or any sibling recipe at the time of
writing — a mood/timeline arbiter (`Arbiter.swift`/`arbiter.ts`) and an
ambient-reflex driver (`Reflexes.swift`/`reflexes.ts`) — to turn per-frame
commands into a `DisplayList` a renderer can paint. This package name is
deliberately distinct from the older, web-only
`@adh-sdk/avatar` package (`useAvatarEngine`, documented in
[adhsdk.ingredient.avatar](cookbook:ccfd0128-374c-4cca-a83f-71efd3c02176)): the two share the word
"avatar" and little else, and this recipe does not treat them as related.

