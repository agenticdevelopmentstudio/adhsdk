---
id: c708a65f-4d6c-40e4-b1b8-a24584cd45a1
title: Avatar Engine Scene
domain: adhsdk://recipes/avatar-engine-scene
type: ingredient
version: 1.0.2
status: review
language: en
created: '2026-09-23'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: 'Scene/buildScene and compose: folds a variant into a flattened rig, then
  turns per-frame Channels into the DisplayList a renderer paints.'
platforms:
- swift
- macos
- ios
- typescript
- web
tags:
- avatar
- engine
- scene
- compositing
depends-on:
- adhsdk://recipes/avatar-engine-config
- adhsdk://recipes/avatar-engine-math
- adhsdk://recipes/avatar-engine-path
- adhsdk://recipes/avatar-engine-runtime
related:
- adhsdk://recipes/avatar-engine-render
- adhsdk://recipes/avatar-engine
references: []
approved-by: ''
approved-date: ''
---

# Avatar Engine Scene

## Overview

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

## Behavioral Requirements

### Scene construction (`Scene.init` / `buildScene`)

- **variant-resolution**: constructing a Scene MUST accept an optional
  variant name. When given, it MUST look up that name in
  `config.character.variants`; an unknown name MUST raise, naming the
  variant. `nil`/`undefined` MUST leave the rig unpatched — the "true rig".
- **prototype-safe-variant-lookup** (web only): `buildScene` MUST test
  variant existence with `Object.hasOwn(config.character.variants, variant)`
  rather than a plain indexed lookup, because `character.variants` is a
  JSON-derived `Record` whose plain index sees `Object.prototype` members
  (e.g. `"constructor"`) as truthy. The Apple `Dictionary` lookup has no
  equivalent hazard.
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
  present in the store but does not hold a number (Apple: not a `.number`
  case; web: `typeof v !== "number"`), `compose` MUST silently use that
  channel's fallback default rather than raising or propagating the
  wrongly-typed value.
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
- **bezier-without-bend-uses-authored-points**: a `bezier` shape with no
  `bend` definition MUST build its path directly from its authored
  `points`, unmodified by any channel.
- **bend-damping-applied-upstream**: `compose`/`resolvePath` MUST NOT apply
  a bend's inward damping to the `.bend` channel's value itself; damping is
  applied exactly once, where the channel value is written
  (`CharacterConfig.respond`, `adhsdk://recipes/avatar-engine-config`), never at composition time.
- **unsupported-shape-kind-rejected** (web): the web `resolvePath`'s
  `switch` MUST throw `unknown shape kind: <kind>` for a `Shape.kind` value
  outside the six handled cases. The equivalent Apple code path is
  unreachable rather than checked, because `Shape.Kind` is a closed Swift
  enum the compiler enforces exhaustively at the call site.
- **kind-derived-from-parsed-path**: every `DisplayItem`'s `kind` field MUST
  equal the command-signature string (`parsePath(d).kind`,
  `adhsdk://recipes/avatar-engine-path`) of that same
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
  when the palette has no such key.
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
  depth exceeds `8` — depth increases when entering the ink table from a raw
  name (ink → its `color` field) and when following an `@`-late-bound
  reference back into full ink resolution.
- **unknown-colour-raises**: ink/colour resolution MUST raise, naming the
  unresolved key, when a raw reference matches neither `#`, `@`, a known ink
  in the scene's ink table, nor a known palette entry.

### Crop filtering (`crop` / `cropList`)

- **crop-name-must-exist**: `crop`/`cropList` MUST raise, naming the
  requested crop, when `character.crops` has no entry for it.
- **prototype-safe-crop-lookup** (web only): `cropList` MUST test crop
  existence with `Object.hasOwn(config.character.crops, crop)` rather than a
  plain indexed lookup, for the same JSON-derived-`Record` reason as
  prototype-safe-variant-lookup.
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
- **crop-does-not-consider-alpha**: `crop`/`cropList` MUST decide inclusion
  solely from a display item's inherited feature; it MUST NOT consult or
  alter `paint.alpha`.

### Channel seeding

- **rest-value-seeding**: `CharacterConfig.seed(into:)` (Apple) /
  `seedChannels` (web) MUST write every entry of `config.rest`
  (`adhsdk://recipes/avatar-engine-config`) into the given
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

- **apple-scene-is-non-sendable**: `Scene` (Apple) is declared `public` with
  no `Sendable` conformance, unlike `DisplayItem`, `DisplayList`, and
  `SceneError`, which are `Sendable`. Under Swift 6 strict concurrency, a
  `Scene` value MUST remain in the isolation domain that constructed it; the
  compiler rejects sending it across an actor boundary.
- **web-is-single-threaded**: `buildScene`, `compose`, `cropList`, and
  `seedChannels` are synchronous, non-`async` functions; JavaScript's
  single-threaded execution model serializes every call made from one
  realm, so there is no runtime data race for these functions to define
  behavior for.

- **seed-before-compose-is-host-enforced**: Scene construction and `compose`
  do not themselves validate or enforce that `CharacterConfig.seed(into:)`/
  `seedChannels` has been called on the given `Channels` store before the
  first `compose` call. `compose`'s own per-property fallback defaults
  (`x=0, y=0, rotation=0, scaleX=1, scaleY=1, pivot=(0,0)`) do not carry a
  node's authored transform override — for example an authored pivot such as
  `body.pivotX`/`body.pivotY` — which only reaches the store through
  `config.rest`. Neither `Rig.swift` nor `rig.ts` states or checks this
  precondition; the reference host's own per-frame driver enforces the
  ordering instead. `Engine.init` (`Engine.swift`) and `createEngine`
  (`engine.ts`) both call `config.seed(into: store)`/`seedChannels(config,
  channels)` immediately after creating the `Channels` store and before
  constructing the `Scene`, and neither exposes `compose` except through
  `tick`, which no caller can invoke before that constructor/factory
  returns. On both source platforms, no caller reachable through the public
  API can reach `compose` before seeding has occurred.

## Appearance

Not applicable — this is a per-frame scene compositor, not a visual
component.

## States

Not applicable — this is a per-frame scene compositor, not a visual
component.

## Accessibility

Not applicable — this is a per-frame scene compositor, not a visual
component.

## Conformance Test Vectors

| # | Requirement(s) | Input | Expected | Source |
|---|---|---|---|---|
| 1 | depth-first-flattening, parent-child-composition, world-matrix-recorded-for-every-node, unshaped-node-emits-nothing, declaration-order-preserved | Fresh scene composed with channels at rest | Returned ids exactly `["eye","pupil","limb","line","spark"]` (dot fixture) with no duplicates; the shapeless `body` node is absent | `SceneTests.testEmitsEveryShapeNodeOnceInDeclarationOrder`; `compose.test.ts` "emits every shape node once, in declaration order" (14-id olylo fixture) |
| 2 | transform-composition, primitive-shapes-always-rebuilt, bezier-without-bend-uses-authored-points, kind-derived-from-parsed-path | Fresh scene, no channels driven | `eye.m == .identity`, `eye.d == Expected.ringPlain`, `eye.kind == "MCCCCZMCCCCZ"`, `pupil.d == Expected.pupilPlain`, `line.d/kind == Expected.line/"MLL"`, `spark.d == Expected.spark` | `SceneTests.testRestsAtIdentityWithTheAuthoredGeometryInLocalSpace` |
| 3 | parent-child-composition, world-matrix-recorded-for-every-node | `body.rotation` set to `90` | `eye`'s (a child of `body` with no transform of its own) world matrix equals a 90° rotation about the body pivot, within `1e-12` | `SceneTests.testComposesAParentTransformIntoItsChildren`; `compose.test.ts` "composes a parent transform into its children" |
| 4 | parent-child-composition | `body.rotation=90`, `face.y=10` (web fixture — a rotated ancestor then a translated one) | `irisLeft`'s matrix `e,f` equal `(390,0)` within `1e-9`, discriminating parent-then-local from local-then-parent multiply order | `compose.test.ts` "pins the multiply argument order — parent-then-local, not local-then-parent" |
| 5 | transform-composition | `eyeLeftRing.scaleY`/`eye.scaleY` set to `0.1` | Only that node's matrix scale component becomes `0.1`; a sibling (`pupil`/`eyeRightRing`) stays at `1` | `SceneTests.testSquashesOnlyTheNodeWhoseScaleIsDriven`; `compose.test.ts` "squashes only the eyes when eye.scaleY is driven" |
| 6 | transform-composition (pivot channel) | `body.rotation=4`, then `body.pivotY` moved to `74` | The composed origin of a descendant (`line`) shifts by the chord distance `Δ·2·sin(2°) ≈ 1.6752` units, proving the pivot used is the channel value, not the rig's static origin | `SceneTests.testComposesAboutTheChannelsOriginNotTheRigs`; `pivot.test.ts` "composes about the CHANNEL's origin, not the rig's" |
| 7 | path-resolution-channel-first, kind-derived-from-parsed-path | `line.shape`/`mouth.shape` channel set to a literal path string | The item's `d` equals that string verbatim and its `kind` equals `"MLL"` | `SceneTests.testTakesADrivenPathStraightOffTheShapeChannel`; `compose.test.ts` "takes a driven mouth path straight off mouth.shape" |
| 8 | bezier-bend-offset, bend-damping-applied-upstream | `limb.bend`/`antennaLeft.bend` set to `10`, then `6`, then `-10` | Rebuilt control points shift proportionally to `weight × raw channel value`, with no inward damping applied inside `compose`; the bent path differs from the rest path | `SceneTests.testRebuildsABendDrivenNodeFromItsPointsAndBend`, `testRendersABendUndampedInBothDirections`; `compose.test.ts` "rebuilds a bend-driven antenna from its points and .bend" |
| 9 | ink-channel-overrides-rig-ink, ink-resolution-order, late-bound-ink-reads-channel | `body.ink` left at rest, then set to `"warm"`/`"red"` (a palette key), then to a literal `"#ff2d2d"` | Every node whose ink is `"@body"` (e.g. `eye`, `line`, `mouth`, `browLeft`) tracks each successive value; a node whose ink names its own colour (`pupil`, `irisLeft`) is unaffected by any of the three | `SceneTests.testResolvesLateBoundInkThroughTheBodysInkChannel`; `compose.test.ts` "resolves @body late-bound ink through body.ink" |
| 10 | paint-fill-and-width-from-ink | Fresh scene composed at rest | A stroked node (`eye`/`mouth`) has `paint.fill == false` and a numeric `paint.width`; a filled node (`pupil`/`irisLeft`) has `paint.fill == true` and `paint.width` absent | `SceneTests.testTakesStrokeVsFillAndWidthFromTheInkNotTheShape`; `compose.test.ts` "takes stroke-vs-fill and width from the ink, not the shape" |
| 11 | alpha-channel-default-one | `spark` left at its authored rest alpha of `0`; separately, `line.alpha`/`pinprickLeft.alpha` set to `0` | Both items remain in the returned list with `paint.alpha === 0`; list length is unchanged | `SceneTests.testKeepsAFullyTransparentNodeInTheList`; `compose.test.ts` "keeps a fully transparent node in the list" |
| 12 | variant-resolution, shape-patch-folding, ink-patch-folding, ink-table-is-scene-scoped, primitive-shapes-always-rebuilt | `Scene(config, variant: "bold")`/`buildScene(config, "optical")` vs. the unpatched Scene, composed with identical channels | Same ids, same order, same matrices in both; patched nodes' `d` and `paint.width` differ per variant; an unpatched node (`spark`/`pinprickLeft`) is byte-identical between the two | `SceneTests.testTheVariantPatchesShapesAndInksAndNothingElse`; `compose.test.ts` "applies the optical cut to shapes and inks, and nothing else" |
| 13 | variant-resolution, scene-errors-are-typed | `Scene(config, variant: "chunky")`/`buildScene(config, "chunky")` (a name absent from `character.variants`) | Raises; the error's description/message contains `"chunky"` | `SceneTests.testThrowsOnAnUnknownVariantRatherThanSilentlyRenderingTheTrueRig`; `compose.test.ts` "throws on an unknown variant rather than silently rendering the true rig" |
| 14 | prototype-safe-variant-lookup | `buildScene(config, "constructor")` | Raises, mentioning `"constructor"`, rather than silently treating `Object.prototype.constructor` as a real variant | `compose.test.ts` "throws on a variant named after an Object.prototype member instead of rendering the true rig" |
| 15 | ink-resolution-depth-guard, compose-can-throw, scene-errors-are-typed | `body.ink` channel set to `"@body"` (an ink that resolves back to itself) | Raises with a message containing `"does not resolve to a colour"`, rather than looping | `SceneTests.testRefusesAnInkThatResolvesBackToItself` |
| 16 | feature-inheritance, unfeatured-item-kept-by-every-crop, crop-is-filter-only | `crop(list, to: "full")`/`cropList(config, list, "full")` where the crop's feature set covers every feature the rig declares | Result equals the input list exactly, unchanged order and count | `SceneTests.testACropWhoseFeaturesCoverEveryNodeIsTheIdentity`; `compose.test.ts` "keeps every item when the crop's features cover every feature in the rig" |
| 17 | feature-inheritance, crop-is-filter-only | `crop(list, to: "coreOnly")`, where `pupil` declares no feature of its own but its parent `body` declares `"core"` | `pupil` is kept (inherits `"core"`); result equals `list` filtered to drop only `limb` | `SceneTests.testAFeatureIsInheritedFromTheNearestAncestorThatDeclaresOne`; `compose.test.ts` "inherits a feature from the nearest ancestor that declares one" |
| 18 | feature-inheritance, unfeatured-item-kept-by-every-crop | `crop(list, to: "limbOnly")` (excludes `"core"`), where `pupil` inherits `"core"` from `body` | `pupil` is dropped along with the rest of `"core"`, leaving only `["limb"]` — the one case distinguishing real inheritance from a no-feature-declared fallback | `SceneTests.testInheritanceIsWhatDropsAnUnfeaturedNodeFromACropThatExcludesItsAncestor`; `compose.test.ts` "drops an inherited feature the crop excludes — neither shipped crop can show this" |
| 19 | crop-name-must-exist, scene-errors-are-typed | `crop(list, to: "nope")`/`cropList(config, list, "nope")` | Raises, naming `"nope"` | `SceneTests.testAnUnknownCropNameThrows`; `compose.test.ts` "throws on an unknown crop name rather than returning an empty list" |
| 20 | prototype-safe-crop-lookup | `cropList(config, list, "constructor")` | Raises, mentioning `"constructor"`, rather than returning a garbage or empty result | `compose.test.ts` "throws on a crop named after an Object.prototype member instead of returning it" |
| 21 | channel-value-type-mismatch-falls-back | `eye.x`/an equivalent numeric channel set to the non-numeric value `"oops"` | The channel's numeric helper (`num`) falls back to its default (`0`) rather than throwing or propagating the string; traced to `channels.get(name)?.number ?? fallback` / `typeof v === "number" ? v : fallback` | Not exercised by a given test; traced directly to source |
| 22 | unsupported-shape-kind-rejected | A `Shape` object whose `kind` is a string outside the six known literals (bypassing the type system) | Web `resolvePath` throws `unknown shape kind: <kind>`; the equivalent Apple path is unreachable because `Shape.Kind` is a closed, compiler-checked enum | Not exercised by a given test; traced to the `switch`'s `default` clause |
| 23 | colour-ref-never-reenters-ink-table | An ink named `"shell"` whose own `color` field is also the palette key `"shell"` (an ink named after the very colour it points at) | `resolveColourRef` resolves it through the palette without re-entering the ink table, avoiding infinite recursion | Not exercised by a given test; traced to the source's own explicit design comment and function separation |
| 24 | late-bound-ink-reads-channel | A late-bound ink `"@missingNode"` where `missingNode.ink` has never been set on the channel store | Raises, naming the reference and the channel | Not exercised by a given test; traced to `resolveLateBound`'s guard clause |
| 25 | unknown-colour-raises | A raw ink name matching neither `#`, `@`, a known ink, nor a known palette key (e.g. `"nonexistent"`) | Raises, naming the unresolved key | Not exercised by a given test; traced to `resolveInk`/`resolveColourRef`'s final guard clause |
| 26 | crop-does-not-consider-alpha | `crop(list, to: <any declared crop>)` over a list containing an item with `paint.alpha == 0` | The item's inclusion is decided purely by its inherited feature, unaffected by its alpha value | Not exercised by a given test; traced to `crop`/`cropList`, which reads only `featureOf`, never `paint` |
| 27 | rest-value-seeding | `seed(into:)`/`seedChannels` writes `config.rest` into a fresh `Channels` store, then `compose` runs at rest | Reproduces the authored rest geometry exactly (vector 2's `eye`/`line`/`spark` values), proving every entry of `config.rest` reached the store | `SceneTests.swift`'s and `compose.test.ts`'s shared `fresh()` helper, used throughout both files |
| 28 | apple-scene-is-non-sendable | Attempting to pass a constructed `Scene` value across an actor boundary under Swift 6 strict concurrency | Fails to compile (`Scene` has no `Sendable` conformance) — a compiler-enforced property, not a runtime-observable outcome | No runtime test vector applies; enforced by the type declaration itself |
| 29 | web-is-single-threaded | Two sequential calls to `compose`/`cropList` from the same synchronous call stack | Both complete without any synchronization primitive in either file, since JavaScript's single-threaded execution model makes concurrent entry from one realm impossible | Not exercised by a given test; a property of the language runtime, not the source's own logic |

## Edge Cases

- **Null/empty input**: a `nil`/`undefined` variant MUST leave the rig
  unpatched (variant-resolution). A variant patch whose `shapes`/`inks`
  object is absent MUST fold nothing — the patch loops simply do not run,
  traced to `patch?.shapes`/`patch?.inks ?? [:]`/`patch?.inks === undefined`
  nil-coalescing. A rig node with no `children` MUST be treated as a leaf;
  `walk` MUST NOT recurse into it, traced to `node.children ?? []` on both
  platforms. Calling `crop`/`cropList` on an empty `DisplayList` MUST return
  an empty list, since a filter over nothing has nothing to keep.
- **Boundary values**: ink-resolution recursion depth exactly at the guard
  threshold (`8`) MUST still resolve; one level past it MUST raise
  (ink-resolution-depth-guard). A `bend.weights` array shorter than the
  shape's `points` array MUST fall back to an offset of `0` for the
  out-of-range index rather than raising, traced to `i < bend.weights.count
  ? bend.weights[i] : 0`/`s.bend!.weights[i] ?? 0`. A `bend.axis` value
  other than the literal `"x"` (including an unexpected string) MUST be
  treated as the y-axis (index `1`) by the ternary, with no validation of
  the axis vocabulary.
- **Concurrent access**: see the Concurrency subsection of Behavioral
  Requirements (apple-scene-is-non-sendable, web-is-single-threaded).
  Neither source file defines a synchronization contract of its own beyond
  those declarations; whether a `Channels` store may safely be read by
  `compose` while written concurrently is entirely the `Channels` store's
  own contract (`adhsdk://recipes/avatar-engine-runtime`),
  not something `Scene`/`compose` add to or subtract from.
- **Error states**: an unknown variant, an unknown crop, an unresolved
  colour reference, a missing late-bound `.ink` channel value, and a
  self-referential ink cycle each MUST raise a typed, attributable error
  rather than returning a partial or silently-wrong `DisplayList`
  (scene-errors-are-typed; vectors 13, 15, 19, 24, 25). The one documented
  exception to "raise rather than silently substitute" is
  channel-value-type-mismatch-falls-back (vector 21): a wrongly-typed
  transform channel value silently falls back to a numeric default instead
  of raising — a real, source-observed asymmetry against every other
  failure path in this component.
- **Offline/disconnected**: Not applicable — Scene construction, `compose`,
  and `crop`/`cropList` perform no network call and no file-system access;
  every input is already-in-memory (`CharacterConfig`, `Channels`) and
  every output is a plain in-memory value. Neither `Rig.swift` nor `rig.ts`
  imports a networking or file-system API.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `config` | `CharacterConfig` | none — required | Passed to `Scene.init`/`buildScene`; supplies the rig tree, the base `character.inks`/`palette`, and the `character.variants`/`character.crops` tables Scene reads from. |
| `variant` | `String?` (Apple) / `string \| undefined` (web) | `nil`/`undefined` (the "true rig") | Names a `character.variants` entry to fold into the constructed Scene's shapes and inks. |
| `channels` | `Channels` | none — required | Passed to `compose` on every frame; supplies each node's live transform, shape override, ink override, and alpha; any channel absent from the store falls back to that property's built-in default. |
| crop name | `String` | none — required | Passed to `crop`/`cropList`; names a `character.crops` entry whose declared features determine which items of a `DisplayList` are kept. |

Neither source file reads an environment variable, a settings key, or a
build-time flag; every parameter above is supplied by the caller at the call
site.

## Deep Linking

Not applicable: neither `Rig.swift` nor `rig.ts` parses or constructs a URL
— both operate purely on in-memory config, channel, and geometry values.

## Localization

Not applicable: neither file renders or reads a user-facing string; the only
strings either file handles are structural keys (node ids, ink and palette
names, crop and variant names) and path-data command letters, never text
shown to a user.

## Accessibility Options

Not applicable: Scene/`compose`/`crop` expose nothing to assistive
technology and read no accessibility display setting (Reduce Motion,
Increase Contrast, Differentiate Without Color); that concern belongs to the
render/host layer downstream (`adhsdk://recipes/avatar-engine-render`), not to this component.

## Feature Flags

Not applicable: neither `Rig.swift` nor `rig.ts` reads a flag, environment
variable, or build configuration; every branch is either a channel value or
a config-declared name.

## Analytics

Not applicable: neither file calls an event, telemetry, or usage-tracking
API.

## Privacy

- **Data collected**: None. Scene construction, `compose`, and
  `crop`/`cropList` operate only on already-authored character-configuration
  data (node ids, colours, shapes) and animation channel values; no user
  data passes through either file.
- **Storage**: Not applicable — neither file persists anything; a `Scene`
  and the `DisplayList` it produces are in-memory-only values.
- **Transmission**: Not applicable — neither file performs network I/O.
- **Retention**: Not applicable — nothing is retained beyond the caller's
  own references to the returned values.

## Logging

Not applicable: neither `Rig.swift` nor `rig.ts` contains a `print`, `log`,
`os_log`, or `console.*` call; every failure is communicated solely through
a thrown/raised error.

## Platform Notes

- **SwiftUI**: this is one of the source platforms. `Rig.swift` is plain
  Foundation code with no `import SwiftUI`/`AppKit`/`UIKit`; a SwiftUI host
  re-invokes `scene.compose(channels)` every frame (typically from a
  `TimelineView(.animation)` or a `CADisplayLink`-driven wrapper, see
  `adhsdk://recipes/avatar-engine-render`) and hands the
  resulting `DisplayList` to that render layer's bridges, never observing
  `Scene` itself as `@Published`/`@Observable` state.
- **AppKit / UIKit**: no distinction from the SwiftUI note above — the same
  `Scene`/`compose`/`crop` serve both UI hosts identically, since
  `Rig.swift` imports neither framework; the AppKit/UIKit divergence lives
  entirely in the render layer immediately downstream of this component.
- **React/Web**: this is the other source platform.
  `packages/web/packages/avatar-engine/src/scene/rig.ts` (re-exported by
  `compose.ts`, kept as a thin barrel so import sites read `scene/compose`
  by intent rather than by file layout) is plain TypeScript with no React
  import; a React host wraps `buildScene`/`compose` in a ref or a
  non-reactive `requestAnimationFrame` loop, since `compose`'s output
  changes every frame and should not be pushed through React state or a
  reducer.
- **Compose (Kotlin/Android, port target)**: model `DisplayItem`/
  `DisplayList`/`Scene` as Kotlin data classes, and port `buildScene`,
  `compose`, and `cropList` as ordinary synchronous functions — no
  coroutine or `Flow` is warranted, since the reference implementations on
  both source platforms are synchronous and side-effect free. A `Channels`
  port (`adhsdk://recipes/avatar-engine-runtime`) backs
  the per-node channel lookups this component performs.
- **WinUI 3 (.NET, port target)**: model `DisplayItem` as a C# record (with
  a nested `Paint` record for `ink`/`alpha`/`fill`/`width`), and port
  `Scene`/`buildScene`, `compose`, and `crop`/`cropList` as ordinary
  synchronous methods returning `IReadOnlyList<DisplayItem>` — no
  `Task`/`async` is warranted, matching the synchronous reference on both
  source platforms. Back the per-frame `<id>.x`/`.rotation`/etc. lookups
  with the `Channels`/`ChannelValue` port described in
  `adhsdk://recipes/avatar-engine-runtime`
  (`System.Text.Json` and `Windows.Storage` have no role here, since
  neither Scene construction nor `compose` performs any I/O). Represent
  `SceneError`/the web `Error` as a dedicated exception type (e.g.
  `SceneException`) whose message carries the same offending-value
  attribution — variant name, crop name, unresolved colour key, or
  late-bound reference — the two reference messages do.
  `ObservableCollection`/`INotifyPropertyChanged` do not apply to the
  returned `DisplayList`: it is a fresh, immutable snapshot produced once
  per `compose` call, not a live collection observed for later in-place
  mutation; a WinUI host driven by `CompositionTarget.Rendering` simply
  re-invokes `compose` each frame and consumes the new snapshot itself, as
  `avatar-engine-render`'s WinUI note describes for the render layer
  immediately downstream of this one.

## Design Decisions

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
`avatar-engine-config`'s load-time reference-integrity checks cannot see; per
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

**Decision**: The variant ink-override switch's unreachable `default: break`
(Apple) applies an override only for the exact pairings `("kind", .string)`,
`("color", .string)`, and `("width", .number)`, silently doing nothing for
any other field/value shape.
**Rationale**: The source's own comment marks this branch unreachable in
practice, because `avatar-engine-config`'s variant-ink-patch-validated
requirement already rejects any other field/value shape at load time; this
is a documented defensive no-op reachable only if that upstream contract
were ever violated, not a load-bearing runtime check of Scene's own.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [main-thread-freedom](agenticdevelopercookbook://compliance/performance#main-thread-freedom) | passed | Performance |
| [animation-frame-rate](agenticdevelopercookbook://compliance/performance#animation-frame-rate) | partial | Performance |

Every failure path in Scene construction, `compose`, and `crop`/`cropList`
(an unknown variant, an unknown crop, an unresolved colour, a missing
late-bound channel, a self-referential ink cycle) raises a typed,
attributable error rather than swallowing it; the one documented exception
is channel-value-type-mismatch-falls-back, a deliberate default rather than
a swallowed error (explicit-error-handling). Scene delegates path
construction to `avatar-engine-path` and matrix arithmetic to
`avatar-engine-math`, keeping its own responsibility limited to tree
walking, transform composition, and paint/ink resolution
(separation-of-concerns). Both platforms carry a dedicated Scene test
suite (`SceneTests.swift`, `compose.test.ts`) with meaningful per-behavior
assertions covering composition, cropping, channel seeding, and the error
paths above (unit-test-coverage). `compose` is a synchronous, O(node-count)-per-call
function with no I/O of any kind (main-thread-freedom). This is the hot
per-frame path a `CADisplayLink`/`requestAnimationFrame` loop calls at a
60fps target, but neither source file measures or enforces a time budget
for a single `compose` call, matching `avatar-engine-render`'s own note on
the same subject (animation-frame-rate: partial).

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation, covering the Apple and web avatar-engine scene compositors, with the open question about an unenforced seed-before-compose precondition carried for a future revision to resolve. |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.0.2 | 2026-09-25 | Mike Fullerton | Joined 3 hard-wrapped recipe:// code spans; added missing unit-test-coverage compliance row. |
