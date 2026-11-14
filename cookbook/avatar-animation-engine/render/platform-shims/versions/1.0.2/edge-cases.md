
- **Empty or malformed hex string (Apple)**: `CGColor.avatarInk("")` (or any
  string that is not a valid `#rrggbb`/`#rgb`) fails the underlying hex parse
  and `avatarInk` returns `nil`; it does not crash.
- **Empty path string (Apple)**: `CGPath.avatarItem("")` parses to a command
  string with no commands and no points, producing an empty `CGPath`; it does
  not throw.
- **Unsupported path command (Apple)**: a path-data string containing a
  command outside `M`/`L`/`C`/`Z` (for example `Q`) makes `CGPath.avatarItem`
  throw, per **path-from-display-item-throws**.
- **Zero-size canvas (Web)**: `config.character.canvas.w`/`h` of `0` is
  written into `viewBox` verbatim (`"0 0 0 0"`); neither `createSvgRenderer`
  nor `renderToString` validates canvas dimensions.
- **Zero stroke width**: a `paint.width` of `0` is passed straight through as
  the stroke width on both platforms; neither file enforces a minimum.
- **Duplicate `id` within one `DisplayList` (Web)**: `paths.get(item.id)`
  returns the same element for both occurrences, and the later item's
  `applyItem` call overwrites the earlier one's attributes — only one
  `<path>` element ends up representing both, showing whichever item's
  attributes were applied last.
- **A `DisplayList` whose `id` set shrinks or changes between calls to
  `render` (Web)**: `createSvgRenderer`'s `paths` map and the `<svg>`'s
  children only ever grow: an `id` present in an earlier `list` but absent
  from the current one leaves its `<path>` in the DOM with stale attributes,
  since `render` has no code path that removes or hides an element for a
  vanished `id`. `renderToString` has no equivalent gap, since it always
  rebuilds its output from scratch and so cannot go stale this way.
- **Off-main-actor use of `AvatarEnvironment.live()`'s closure (Apple)**:
  calling the returned `reducedMotion` closure off the main actor traps the
  process via `MainActor.assumeIsolated`; this is documented, deliberate
  behavior, not a silently swallowed error.
- **Cursor outside the window (Apple, AppKit)**: `Platform.pointerLocation(in:)`
  returns `nil` when the screen-space cursor position falls outside the
  view's window frame (for example, the cursor is over another app or
  display), rather than reporting a stale or out-of-bounds point.
- **`createSvgRenderer` called with no `doc` argument outside a browser
  (Web)**: the default parameter `doc: Document = document` evaluates the
  global `document`; in an environment with no such global this throws
  before the function body runs. `renderToString` has no such dependency and
  is unaffected.
- **Concurrent access (Apple)**: `AvatarHostView` and `Platform` are
  `@MainActor`-isolated, so the compiler serializes every call onto the main
  actor; there is no runtime race to handle.
- **Concurrent access (Web)**: `attrsOf`, `applyItem`, `createSvgRenderer`,
  and `renderToString` are synchronous functions with no async boundary;
  JavaScript's single-threaded execution model serializes all calls.

