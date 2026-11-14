
Not applicable to most of these thirteen hooks: none of them drives an
unconditional, indefinite animation loop the way, for example, the
[adhsdk.ingredient.avatar-animation-engine.avatar-engine](cookbook:bd101720-9fd3-4978-a0aa-7671e301e64b)
does. One exception is a gap: `useChatSession`'s `say()` reveals text one
simulated keystroke at a time (26–54ms apart) and does not consult
`prefers-reduced-motion`. `useChatSizing`'s `pc-anim` class
only enables a CSS height transition the host page's own stylesheet defines
(this source contains no keyframe/tween of its own to gate), and
`useConnectRitual`'s status-line stepping is text content, not motion. A
grep of `hooks/` for `matchMedia`/`reduce`/`prefers`/`contrast` finds
nothing, so `say()`'s keystroke reveal is the one motion here that has no
reduced-motion check. Separately, `useChatSession` passes a hardcoded `reducedMotion:false`
into the `DefaultOrchestrator` display config on every construction; that
field belongs to the orchestrator's own contract (covered by
[adhsdk.ingredient.chat.runtime](cookbook:98a0f3de-1489-465d-b1aa-017f4505d05d))
and is out of scope for these hooks' own behavior, so it is noted here
rather than flagged as a gap of this ingredient's sources.

