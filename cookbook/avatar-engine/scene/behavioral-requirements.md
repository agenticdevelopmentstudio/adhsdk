
### Scene construction (`Scene.init` / `buildScene`)

- **variant-resolution**: constructing a Scene MUST accept an optional
  variant name. When given, it MUST look up that name in
  `config.character.variants`; an unknown name MUST raise, naming the
  variant. `nil`/`undefined` MUST leave the rig unpatched — the "true rig".
- **prototype-safe-variant-lookup**: only the own-property names of
  `config.character.variants` MUST resolve as variants; a name such as
  `"constructor"` MUST raise like any other unknown variant. The mechanism is
  in Platform Notes.
- **leaf-node-without-children**: a rig node with no `children` MUST be
  treated as a leaf, and Scene construction MUST NOT recurse into it.
- **depth-first-flattening**: Scene construction MUST walk the rig tree
  depth-first, in declaration order, and record one flattened entry per
  node; this MUST be the same order `compose`'s returned `DisplayList` later
  carries.
- **shape-patch-folding**: when a variant patch names a node in
  `variant.shapes`, Scene construction MUST merge the patch's fields onto
  that node's `.shape` before flattening, leaving every field the patch does
  not name unchanged.
- **ink-patch-folding**: when a variant patch names an ink in
  `variant.inks`, Scene construction MUST produce a scene-local ink table
  equal to `config.character.inks` with each named ink's overridden fields
  (`kind`, `color`, `width`) replaced by the patch's values and every other
  field, and every un-patched ink, left as the base config supplies it.
- **ink-table-is-scene-scoped**: `compose` MUST read every ink's paint data
  from the Scene's own (possibly variant-folded) ink table, and MUST NOT
  read `config.character.inks` directly once a Scene has been constructed.

### Per-frame transform composition (`compose`)

- **transform-composition**: for each node, `compose` MUST compute a local
  transform from six channels — `<id>.x`, `<id>.y`, `<id>.rotation`,
  `<id>.scaleX`, `<id>.scaleY`, and a pivot pair `<id>.pivotX`/`<id>.pivotY`
  — falling back to `x=0, y=0, rotation=0, scaleX=1, scaleY=1,
  pivotX=0, pivotY=0` for any channel absent from the given `Channels`
  store.
- **channel-value-type-mismatch-falls-back**: when a transform channel is
  present in the store but does not hold a number, `compose` MUST silently use
  that channel's fallback default rather than raising or propagating the
  wrongly-typed value (see the matching Design Decision).
- **parent-child-composition**: `compose` MUST compute a node's world matrix
  as `parent-world-matrix * local-matrix` (parent argument first, local
  second, on both platforms), using the identity matrix for a node with no
  parent, and MUST record the result by node id before composing that
  node's children.
- **world-matrix-recorded-for-every-node**: every node's world matrix MUST
  be recorded by id regardless of whether that node carries a shape, since a
  shapeless node still transforms its descendants.
- **unshaped-node-emits-nothing**: a node with no `.shape` MUST NOT produce
  a `DisplayItem`; `compose` MUST continue to that node's children (via the
  recorded world matrix) without appending anything for the node itself.
- **declaration-order-preserved**: the `DisplayList` `compose` returns MUST
  list items in the same depth-first declaration order the Scene was
  flattened in; `compose` MUST NOT reorder, sort, or group items by any
  other key.

### Per-frame geometry resolution

- **path-resolution-channel-first**: for a shaped node, `compose` MUST use
  the current string value of the `<id>.shape` channel as the item's path
  data verbatim when present, and MUST rebuild the path from the node's rig
  shape definition only when that channel is absent.
- **primitive-shapes-always-rebuilt**: a `ring`, `disc`, `arc`, `cubicO`, or
  `polyline` shape MUST be rebuilt from its rig-declared parameters on every
  call to `compose` that reaches it (it carries no `.shape` rest channel to
  short-circuit on).
- **bezier-bend-offset**: a `bezier` shape whose declaration includes a
  `bend` definition MUST, when no `<id>.shape` channel is present, rebuild
  its points by offsetting each control point along the bend's declared
  axis (`"x"` → index `0`, any other value → index `1`) by that point's
  weight (or `0` when the weights array is shorter than the points array)
  multiplied by the current value of the `<id>.bend` channel (default `0`).
- **bend-weights-short-falls-back-to-zero**: when `bend.weights` is shorter
  than the shape's `points` array, the weight for each out-of-range point MUST
  be `0`, and `compose` MUST NOT raise.
- **bend-axis-non-x-is-y**: a `bend.axis` of exactly `"x"` MUST offset the
  x coordinate (index `0`); any other value MUST offset the y coordinate
  (index `1`), with no validation of the axis vocabulary.
- **bezier-without-bend-uses-authored-points**: a `bezier` shape with no
  `bend` definition MUST build its path directly from its authored
  `points`, unmodified by any channel.
- **bend-damping-applied-upstream**: `compose`/`resolvePath` MUST NOT apply
  a bend's inward damping to the `.bend` channel's value itself; damping is
  applied exactly once, where the channel value is written
  (`CharacterConfig.respond`, [adhsdk.ingredient.avatar-animation-engine.config](cookbook:d3e1f776-8ad1-431f-9485-386ac285a039)), never at composition time.
- **unsupported-shape-kind-rejected** (web): the web `resolvePath` MUST throw
  `unknown shape kind: <kind>` for a `Shape.kind` value outside the six
  handled cases. The equivalent Apple code path is unreachable rather than
  checked, because `Shape.Kind` is a closed Swift enum.
- **kind-derived-from-parsed-path**: every `DisplayItem`'s `kind` field MUST
  equal the command-signature string (`parsePath(d).kind`,
  [adhsdk.ingredient.avatar-engine.path](cookbook:81f8c0bd-ce00-43b3-816e-b63e96baeacc)) of that same
  item's own resolved `d`, computed fresh on every call, never cached from a
  previous frame.

### Per-frame paint resolution

- **ink-channel-overrides-rig-ink**: for a shaped node, `compose` MUST use
  the current string value of the `<id>.ink` channel as the ink name when
  present, and MUST fall back to the node's rig-declared `ink` only when
  that channel is absent or not a string.
- **paint-fill-and-width-from-ink**: a `DisplayItem`'s `paint.fill` MUST be
  `true` exactly when the resolved ink's `kind` is `"fill"`, and its
  `paint.width` MUST be that ink's `width` (absent/`nil` when the ink is
  unknown in the scene's ink table or its `width` is unset) — never derived
  from the shape.
- **alpha-channel-default-one**: a `DisplayItem`'s `paint.alpha` MUST come
  from the `<id>.alpha` channel, defaulting to `1` when absent, and the item
  MUST still be appended to the `DisplayList` when that value is `0` or
  otherwise fully transparent — `compose` MUST NOT omit an item because it
  is currently invisible.

### Ink and colour resolution

- **ink-resolution-order**: resolving a raw ink reference (`resolveInk`)
  MUST, in order: return it unchanged when it starts with `#`; resolve it
  through the late-bound path when it starts with `@`; resolve it via that
  ink's own `color` field when it names a known entry in the scene's
  (variant-folded) ink table; otherwise resolve it as a palette key, raising
  when the palette has no such key. Resolution depth starts at `0` on
  the first call.
- **colour-ref-never-reenters-ink-table**: resolving an `Ink.color` field
  specifically (`resolveColourRef`) MUST NOT look up its input in the ink
  table under any circumstance — only `#hex`, an `@`-late-bound reference,
  or a palette key are legal there, because an ink's `color` field is
  documented to never name another ink.
- **late-bound-ink-reads-channel**: resolving an `@nodeId` reference MUST
  read the `<nodeId>.ink` channel's current string value and recurse into
  full ink resolution (`resolveInk`, not `resolveColourRef`) on it; a
  missing or non-string value at that channel MUST raise, naming the
  reference and the channel.
- **ink-resolution-depth-guard**: both `resolveInk` and `resolveColourRef`
  MUST raise, rather than recurse indefinitely, once accumulated resolution
  depth exceeds `8` (depth `8` still resolves; depth `9` raises) — depth increases when entering the ink table from a raw
  name (ink → its `color` field) and when following an `@`-late-bound
  reference back into full ink resolution.
- **unknown-colour-raises**: ink/colour resolution MUST raise, naming the
  unresolved key, when a raw reference matches neither `#`, `@`, a known ink
  in the scene's ink table, nor a known palette entry.

### Crop filtering (`crop` / `cropList`)

- **crop-name-must-exist**: `crop`/`cropList` MUST raise, naming the
  requested crop, when `character.crops` has no entry for it.
- **prototype-safe-crop-lookup**: only the own-property names of
  `config.character.crops` MUST resolve as crops; a name such as
  `"constructor"` MUST raise like any other unknown crop.
- **feature-inheritance**: `crop`/`cropList` MUST determine each display
  item's effective feature by walking the rig from its root and assigning
  every node the nearest declared `feature` among itself and its ancestors
  (its own `feature`, or the value inherited from its parent).
- **unfeatured-item-kept-by-every-crop**: a display item whose id has no
  effective feature anywhere in its ancestor chain MUST be kept by every
  crop, regardless of which features that crop names.
- **crop-is-filter-only**: `crop`/`cropList` MUST return a subsequence of
  the input `DisplayList` with each kept item unchanged (same id, matrix,
  path data, and paint) and in the same relative order; it MUST NOT
  recompute, reorder, or otherwise alter any item's fields.
- **crop-empty-list-returns-empty**: `crop`/`cropList` given an empty
  `DisplayList` MUST return an empty list.
- **crop-does-not-consider-alpha**: `crop`/`cropList` MUST decide inclusion
  solely from a display item's inherited feature; it MUST NOT consult or
  alter `paint.alpha`.

### Channel seeding

- **rest-value-seeding**: `CharacterConfig.seed(into:)` (Apple) /
  `seedChannels` (web) MUST write every entry of `config.rest`
  ([adhsdk.ingredient.avatar-animation-engine.config](cookbook:d3e1f776-8ad1-431f-9485-386ac285a039)) into the given
  `Channels` store, keyed and valued exactly as the config's `rest` map
  supplies them.

### Errors

- **scene-errors-are-typed**: every rejection in Scene construction,
  `compose`, or `crop`/`cropList` MUST be raised as a typed/structured error
  (`SceneError` on Apple, an `Error` on web) whose message names the
  offending value — a variant name, an unresolved colour key, a crop name,
  or a late-bound reference and its channel — never a generic or silent
  failure.
- **compose-can-throw**: `compose` MUST be treated as fallible even against
  an already-successfully-constructed Scene, because ink resolution can
  raise from a `Channels` state written between construction and the
  `compose` call (for example, a channel set to a self-referential `@`
  reference after the Scene was built).

### Concurrency

- **apple-scene-is-non-sendable**: Apple's `Scene` MUST NOT be declared
  `Sendable`, and a caller MUST keep a `Scene` in the isolation domain that
  constructed it (see Design Decisions).
- **web-is-single-threaded**: `buildScene`, `compose`, `cropList` and
  `seedChannels` MUST remain synchronous, non-`async` functions, so no call can
  interleave with another within one realm.

### Host preconditions

- **seed-before-compose-is-host-enforced**: the host MUST call
  `CharacterConfig.seed(into:)` / `seedChannels` on a `Channels` store before
  the first `compose` call on it. `compose`'s per-property fallback defaults
  (`x=0, y=0, rotation=0, scaleX=1, scaleY=1, pivot=(0,0)`) do not carry a
  node's authored transform override, such as an authored pivot, which only
  reaches the store through `config.rest`. Neither `Rig.swift` nor `rig.ts`
  checks this precondition; `Engine.init` (`Engine.swift`) and `createEngine`
  (`engine.ts`) both seed the store before constructing the `Scene`, and
  `compose` is reachable only through `tick`, so no caller of the public API
  can reach `compose` before seeding.
