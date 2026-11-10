
Not applicable within the scope of these thirteen hooks specifically: none
of them drives an unconditional, indefinite animation loop the way, for
example, the separate avatar engine does. `useChatSizing`'s `pc-anim` class
only enables a CSS height transition the host page's own stylesheet defines
(this source contains no keyframe/tween of its own to gate), and
`useConnectRitual`'s status-line stepping is text content, not motion. A
grep of `hooks/` for `matchMedia`/`reduce`/`prefers`/`contrast` finds
nothing, consistent with there being no motion here for such a check to
guard. Separately, `useChatSession` passes a hardcoded `reducedMotion:false`
into the `DefaultOrchestrator` display config on every construction; that
field belongs to the orchestrator's own contract (covered by the
`chat-coordinator-runtime` recipe) and is out of scope for these hooks'
own behavior, so it is noted here rather than flagged as a gap of this
recipe's sources.

