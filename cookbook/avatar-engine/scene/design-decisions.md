
**Decision**: Fold a variant's shape and ink patches into the Scene once, at
construction, rather than having `compose` consult `character.variants` on
every frame.
**Rationale**: Per the source's own comment, this is deliberately the only
place a variant is ever mentioned — `compose`, the tween engine, the golden
recorder, and the renderer all stay unaware variants exist, so a variant can
never leak into per-frame logic.
**Approved**: pending

**Decision**: Apple's flattened `Placed` record keeps only a node's
immediate parent id; the web's flattened record keeps the entire ancestor
chain (`parents: readonly string[]`) but only ever reads its last element.
**Rationale**: Per the source's own comment, one parent id carries the same
information as the full chain while stating, out loud, that a node's
placement depends on exactly one other node; the two implementations differ
in the shape of an intermediate data structure, not in composed behavior —
both look up exactly one prior world matrix per node
(parent-child-composition).
**Approved**: pending

**Decision**: Give `resolveColourRef` (resolving an `Ink.color` field) its
own function, distinct from `resolveInk` (resolving a raw ink-or-colour
reference), rather than reusing one function for both.
**Rationale**: Per the source's own comment, an ink is routinely named after
the very palette colour it points at; recursing through the ink table from
inside `color`-field resolution would find that same-named ink again and
resolve to itself — a real, repeatedly-triggerable outcome on ordinary
character data, not a hypothetical edge case.
**Approved**: pending

**Decision**: Bound ink-reference recursion at a fixed depth (`8`) with a
thrown error, rather than detecting a true reference cycle.
**Rationale**: A cycle here only closes through a runtime channel value that
[adhsdk.ingredient.avatar-animation-engine.config](cookbook:d3e1f776-8ad1-431f-9485-386ac285a039)'s load-time reference-integrity checks cannot see; per
the source's own comment, failing after a fixed depth is worse to diagnose
than true cycle detection would be, but it is a deliberate tradeoff — the
character simply refuses to paint on a config that is otherwise valid,
rather than the render loop hanging.
**Approved**: pending

**Decision**: Use `Object.hasOwn` rather than a plain indexed lookup to test
variant and crop names on the web platform, with no Apple-side equivalent.
**Rationale**: `character.variants`/`character.crops` are JSON-derived
`Record`s in TypeScript, so a plain index sees `Object.prototype` members
(`"constructor"`, `"toString"`, etc.) as truthy; a Swift `Dictionary` has no
shared-prototype hazard, so the equivalent guard would be dead code on
Apple. This is a platform-driven asymmetry in the source, not a missing
guard on either side.
**Approved**: pending

**Decision**: Apple ignores a variant ink-override field or value shape that
Scene does not recognize, rather than raising: only the pairings
`("kind", .string)`, `("color", .string)` and `("width", .number)` apply.
**Rationale**: The source's own comment marks the ignored branch unreachable in
practice, because [adhsdk.ingredient.avatar-animation-engine.config](cookbook:d3e1f776-8ad1-431f-9485-386ac285a039)'s variant-ink-patch-validated
requirement already rejects any other field/value shape at load time; this
is a documented defensive no-op reachable only if that upstream contract
were ever violated, not a load-bearing runtime check of Scene's own.
**Approved**: pending

**Decision**: A transform channel that is present but not a number falls back
to that channel's default (`0` for position and rotation, `1` for scale) instead
of raising, unlike every other failure path in this component.
**Rationale**: The source records no reason for this asymmetry. Its observable
effect is that a mistyped channel write cannot stop a frame from rendering,
at the price of hiding the mistake. The owner should confirm that the fallback
is intended; the alternative is to raise like the other failures.
**Approved**: pending

**Decision**: Apple's `Scene` is deliberately not `Sendable`.
**Rationale**: `Scene` is declared `public` with no `Sendable` conformance,
unlike `DisplayItem`, `DisplayList` and `SceneError`. Under Swift 6 strict
concurrency a `Scene` value stays in the isolation domain that constructed it,
and the compiler rejects sending it across an actor boundary. This is a
compile-time property, so it has no runtime test vector.
**Approved**: pending
