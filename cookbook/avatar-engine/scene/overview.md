
This is a non-UI component: a logic seam with no visual surface of its own.
`Scene` (`Scene.init`/`compose`/`crop` in `Rig.swift`) and its web
counterpart (`buildScene`/`compose`/`cropList` in `rig.ts`, re-exported by
`compose.ts`) are two independent implementations of the same contract: fold
one optional variant into a flattened, depth-first walk of a rig tree once,
then, every frame, turn a `Channels` store into a `DisplayList` — an ordered
array of fully resolved `DisplayItem`s (a world transform `m`, resolved path
data `d`, a command-signature `kind`, and a `Paint` of ink/alpha/fill/width) a
renderer can paint without knowing anything about rigs, channels, or config.
A third operation, `crop`/`cropList`, filters an already-composed
`DisplayList` down to the features one named crop declares.

Building a `Scene` is the only place a variant is ever mentioned: it patches
the rig's shapes and inks once, into a scene-local, variant-folded ink table
(`inks`) that `compose` reads from exclusively — never from
`config.character.inks` directly — so a variant can never leak into
per-frame logic, the tween engine, the golden recorder, or the renderer.
Apple's flattened record (`Placed`) keeps only a node's immediate parent id;
the web's flattened record (`{ node, parents }`) keeps the whole ancestor
chain but reads only its last element — the same information in a
differently shaped container (see Design Decisions).

`compose` walks the flattened list once per call, composing each node's
world matrix from its parent's already-computed matrix and its own six
transform channels, resolving a shaped node's path and paint, and appending
one `DisplayItem` per shaped node in the list's declaration order. Resolving
an item's ink is itself a small recursive contract (`resolveInk`/
`resolveColourRef`/`resolveLateBound`) over four reference forms — a literal
hex, a late-bound `@nodeId`, a named ink, or a palette key — guarded against
infinite recursion by a fixed depth limit.

Two independent implementations conform to this contract:

- **Apple** (Swift, macOS + iOS): `Scene`, `DisplayItem`, `DisplayList`, and
  `SceneError` in
  `packages/apple/AvatarAnimationEngine/Sources/Scene/Rig.swift`, plus a
  `CharacterConfig.seed(into:)`/`CharacterConfig.crop(_:to:)` extension in
  the same file.
- **Web** (TypeScript): `buildScene`, `compose`, `cropList`, and
  `seedChannels` in
  `packages/web/packages/avatar-engine/src/scene/rig.ts`, re-exported for
  import-site clarity by `packages/web/packages/avatar-engine/src/scene/compose.ts`.

Both implementations MUST agree on the verdict (a `DisplayList`, or a raised
error) for the same `CharacterConfig`, variant, and `Channels` state. They
are not required to agree on exact error message text.

