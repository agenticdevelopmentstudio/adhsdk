
- **Null/empty input**: a `nil`/`undefined` variant leaves the rig unpatched
  (variant-resolution). A variant patch whose `shapes`/`inks` object is absent
  folds nothing. A rig node with no `children` is a leaf
  (leaf-node-without-children), and an empty `DisplayList` crops to an empty
  list (crop-empty-list-returns-empty).
- **Boundary values**: ink-resolution depth `8` still resolves and depth `9`
  raises (ink-resolution-depth-guard; vectors 28 and 29). A short
  `bend.weights` array and a non-`"x"` axis follow
  bend-weights-short-falls-back-to-zero and bend-axis-non-x-is-y.
- **Concurrent access**: see the Concurrency subsection of Behavioral
  Requirements (apple-scene-is-non-sendable, web-is-single-threaded).
  Neither source file defines a synchronization contract of its own beyond
  those declarations; whether a `Channels` store may safely be read by
  `compose` while written concurrently is entirely the `Channels` store's
  own contract ([adhsdk.ingredient.avatar-animation-engine.runtime](cookbook:74ba9dde-4963-42cb-aa03-bf1ee4dcc794)),
  not something `Scene`/`compose` add to or subtract from.
- **Error states**: see scene-errors-are-typed (vectors 13, 15, 19, 24, 25).
  The one exception to "raise rather than silently substitute" is
  channel-value-type-mismatch-falls-back (vector 21), recorded in Design
  Decisions.
- **Offline/disconnected**: Not applicable — Scene construction, `compose`,
  and `crop`/`cropList` perform no network call and no file-system access;
  every input is already-in-memory (`CharacterConfig`, `Channels`) and
  every output is a plain in-memory value. Neither `Rig.swift` nor `rig.ts`
  imports a networking or file-system API.

