
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
  own contract ([adhsdk.ingredient.avatar-animation-engine.runtime](cookbook:74ba9dde-4963-42cb-aa03-bf1ee4dcc794)),
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

