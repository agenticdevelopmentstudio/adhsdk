
### Host view lifecycle (Apple)

- **host-visibility-hook**: `AvatarHostView` MUST call its own
  `hostVisibilityChanged()` whenever the platform reports a change that could
  affect whether the view can be seen: on AppKit, from `viewDidMoveToWindow()`,
  `viewDidHide()`, and `viewDidUnhide()`; on UIKit, from `didMoveToWindow()`
  and from `isHidden`'s property observer.
- **host-visibility-hidden-change-only**: On UIKit, `AvatarHostView` MUST call
  `hostVisibilityChanged()` from its `isHidden` observer only when the new
  value differs from the old value.
- **host-visibility-default-no-op**: `hostVisibilityChanged()` MUST default to
  doing nothing; it exists to be overridden by a subclass that reacts to
  visibility changes.
- **main-actor-isolation**: `AvatarHostView` and `Platform` MUST be isolated
  to the main actor; every member of both touches a view or a main-actor-only
  system API.

### Platform capability bridge (Apple)

- **view-space-orientation**: `Platform.viewSpaceIsBottomLeft` MUST be `true`
  when compiled against AppKit (the host view space's origin is bottom-left)
  and `false` when compiled against UIKit (the origin is top-left, already
  matching the design space's y-down convention).
- **reduce-motion-read**: `Platform.reduceMotion()` MUST return the live
  system reduce-motion preference — `NSWorkspace.shared.
  accessibilityDisplayShouldReduceMotion` under AppKit,
  `UIAccessibility.isReduceMotionEnabled` under UIKit — read fresh on every
  call, never cached.
- **host-layer-access**: `Platform.hostLayer(of:)` MUST return the given
  view's backing `CALayer`; under AppKit it MUST first set `wantsLayer = true`
  on the view (an `NSView` is layer-backed only on request) before returning
  its layer; under UIKit it MUST return the view's layer directly (a `UIView`
  is always layer-backed).
- **display-link-creation**: `Platform.displayLink(on:target:selector:)` MUST
  create a `CADisplayLink` bound to the given target/selector — via the
  view's own `displayLink(target:selector:)` factory under AppKit, and via
  `CADisplayLink`'s own initializer under UIKit — and MUST NOT add it to a
  run loop itself.
- **tap-recognizer-creation**: `Platform.makeTapRecognizer(target:action:)`
  MUST return an `NSClickGestureRecognizer` under AppKit and a
  `UITapGestureRecognizer` under UIKit, both bound to the given target/action.
- **drag-recognizer-creation-appkit**: Under AppKit,
  `Platform.makeDragRecognizers(target:action:)` MUST return an empty array.
- **drag-recognizer-creation-uikit**: Under UIKit,
  `Platform.makeDragRecognizers(target:action:)` MUST return exactly one
  `UIPanGestureRecognizer` and one `UIHoverGestureRecognizer`, both bound to
  the given target/action.
- **pointer-location-appkit**: Under AppKit, `Platform.pointerLocation(in:)`
  MUST return `nil` when the view has no window, and MUST return `nil` when
  the cursor's screen-space position (`NSEvent.mouseLocation`) falls outside
  the window's frame; otherwise it MUST return that position converted into
  the given view's own coordinate space.
- **pointer-location-uikit**: Under UIKit, `Platform.pointerLocation(in:)`
  MUST always return `nil`.
- **focus-check-appkit**: Under AppKit, `Platform.isFocused(_:)` MUST return
  whether the view's window is the key window, and `false` when the view has
  no window.
- **focus-check-uikit**: Under UIKit, `Platform.isFocused(_:)` MUST always
  return `true`.
- **occlusion-notification-name**: `Platform.occlusionNotificationName` MUST
  be `NSWindow.didChangeOcclusionStateNotification` under AppKit and `nil`
  under UIKit.
- **on-screen-check-appkit**: Under AppKit, `Platform.isOnScreen(_:)` MUST
  return `true` only when the view has a window, neither it nor an ancestor
  is hidden, and that window's `occlusionState` contains `.visible`.
- **on-screen-check-uikit**: Under UIKit, `Platform.isOnScreen(_:)` MUST
  return `true` only when the view has a window and neither the view nor any
  ancestor up to the root has `isHidden` set to `true`.

### Environment factory (Apple)

- **live-environment-reduce-motion-only**: `AvatarEnvironment.live()` MUST
  return an `AvatarEnvironment` whose `reducedMotion` closure reports
  `Platform.reduceMotion()`, and MUST NOT supply any other value.
- **live-environment-main-actor-only**: The closure returned by
  `AvatarEnvironment.live()` MUST be invoked only on the main actor; it reads
  accessibility state through `MainActor.assumeIsolated`, which traps the
  process when invoked off the main actor.

### Geometry and paint bridges (Apple)

- **matrix-bridge-field-order**: `CGAffineTransform.init(_ m: Mat)` MUST map
  `Mat`'s six fields onto `CGAffineTransform` by name and position only —
  `a→a`, `b→b`, `c→c`, `d→d`, `e→tx`, `f→ty` — converting each `Double` to
  `CGFloat`, with no other transformation.
- **ink-color-from-hex**: `CGColor.avatarInk(_:)` MUST parse a `#rrggbb` (or
  `#rgb`) hex string into an sRGB `CGColor` with alpha fixed at `1`, and MUST
  return `nil` when the string does not parse as a hex color.
- **ink-color-excludes-item-alpha**: `CGColor.avatarInk(_:)` MUST NOT
  incorporate a display item's `paint.alpha` into the returned color; alpha
  MUST be applied separately, through the target's own opacity.
- **path-from-display-item**: `CGPath.avatarItem(_:)` MUST parse the given
  path-data string and convert it to a `CGPath`, mapping `M` to a move, `L`
  to a line, `C` to a cubic curve read in the order `c1 c2 end`, and `Z` to
  closing the current subpath.
- **path-from-display-item-throws**: `CGPath.avatarItem(_:)` MUST throw
  whatever error the underlying path parse throws when the path-data string
  contains a command outside the `M`/`L`/`C`/`Z` alphabet.
- **stroke-cap-mapping**: `StrokeStyle.cgLineCap` MUST map `"round"` to
  `.round`, `"square"` to `.square`, and any other value to `.butt`.
- **stroke-join-mapping**: `StrokeStyle.cgLineJoin` MUST map `"round"` to
  `.round`, `"bevel"` to `.bevel`, and any other value to `.miter`.
- **stroke-mapping-never-throws**: `cgLineCap` and `cgLineJoin` MUST NOT throw
  or fail for an unrecognized vocabulary value.

### SVG attribute computation (Web)

- **svg-attribute-set**: For a given `DisplayItem` and `CharacterConfig`,
  `attrsOf` MUST return, in order: `d` (the item's path data, verbatim),
  `transform` (`matrix(a,b,c,d,e,f)` joined from the item's 6-element
  matrix), `opacity` (the item's `paint.alpha`, stringified), then either
  `fill`/`stroke` (when `paint.fill` is `true`: `fill` = the item's ink,
  `stroke` = `"none"`) or `fill`/`stroke`/`stroke-width`/`stroke-linecap`/
  `stroke-linejoin` (when `paint.fill` is `false`: `fill` = `"none"`,
  `stroke` = the item's ink, `stroke-width` = `paint.width` if present else
  `config.character.strokeStyle.width`, `stroke-linecap`/`stroke-linejoin` =
  the config's values verbatim).
- **svg-attribute-single-source**: Both the live DOM path (`applyItem`) and
  the string path (`attrs`/`renderToString`) MUST derive an item's paint
  attributes from `attrsOf` and MUST NOT compute a paint attribute
  independently.
- **svg-data-id-write-once**: A `<path>` element's `data-id` attribute MUST
  be written exactly once, at element creation, and MUST NOT be part of the
  set `attrsOf`/`applyItem` rewrite on later frames.
- **svg-ink-excludes-alpha**: As on Apple, the `fill`/`stroke` value MUST
  carry no alpha; alpha MUST be expressed only through the `opacity`
  attribute.
- **svg-linecap-linejoin-verbatim**: `stroke-linecap` and `stroke-linejoin`
  MUST be written from `config.character.strokeStyle.linecap`/`.linejoin`
  verbatim, with no mapping table and no fallback for an unrecognized value.

### SVG renderer lifecycle (Web)

- **svg-renderer-single-svg-element**: `createSvgRenderer(config, doc)` MUST
  create exactly one `<svg>` element (via `doc.createElementNS`), and MUST
  set its `viewBox` to `"0 0 <canvas.w> <canvas.h>"` and its `xmlns` to the
  SVG namespace, both from `config.character.canvas`.
- **svg-renderer-node-creation-once**: `render(list)` MUST create a new
  `<path>` element, set its `data-id`, append it to the `<svg>`, and record
  it by the item's `id` only the first time that `id` is seen; on every later
  call for a known `id` it MUST reuse the same element and only rewrite its
  attributes.
- **svg-renderer-paint-order-fixed-on-first-appearance**: A `<path>`'s
  position among its siblings MUST be fixed by the order in which its `id`
  first appears across calls to `render`; `render` MUST NOT reorder existing
  `<path>` elements.
- **svg-renderer-destroy-clears-paths**: `destroy()` MUST clear the internal
  `id`→element map and remove every child from the `<svg>`, but MUST NOT
  remove or alter the `<svg>` element itself or its attributes.
- **svg-renderer-render-after-destroy**: Calling `render(list)` after
  `destroy()` MUST recreate a fresh `<path>` element for every item in
  `list`, exactly as on the first call to `render`.
- **render-to-string-purity**: `renderToString(config, list)` MUST build its
  output without reading or creating any DOM node, and MUST produce
  byte-identical output for two calls given the same `config` and `list`.
- **render-to-string-structure**: `renderToString(config, list)` MUST return
  one `<svg xmlns="..." viewBox="0 0 <w> <h>">` element containing one
  self-closing `<path .../>` per item in `list`, in list order, each
  carrying `data-id` followed by `attrsOf`'s attribute set for that item.

### Cross-platform contract

- **matrix-order-shared**: The Apple `Mat` bridge and the web `matrixOf`
  function MUST treat a display item's transform as the same six values in
  the same order (`a, b, c, d, e/tx, f/ty`) that both SVG's `matrix()` and
  `CGAffineTransform` use.
- **fill-stroke-selection-shared**: On both platforms, an item whose
  `paint.fill` is `true` MUST be painted using its ink as a fill with no
  stroke, and an item whose `paint.fill` is `false` MUST be painted using its
  ink as a stroke with no fill.
- **stroke-width-fallback-shared**: On both platforms, a stroked item's line
  width MUST come from `paint.width` when present, and MUST fall back to the
  character's `strokeStyle.width` otherwise.
- **cap-join-source-shared**: On both platforms, the line cap and line join
  used to stroke an item MUST come from the character's `strokeStyle`, never
  from a per-item value.
- **cap-join-vocabulary-diverges**: The two platforms MUST diverge in how an
  unrecognized cap/join value is handled: the Apple bridge maps it to a
  Core Graphics default (`stroke-cap-mapping`, `stroke-join-mapping`), while
  the web path writes `strokeStyle.linecap`/`.linejoin` straight through with
  no mapping and no fallback (`svg-linecap-linejoin-verbatim`) — a
  consequence of `StrokeStyle.linecap`/`.linejoin` being an unconstrained
  `String` in the Apple config type versus a `"round" | "butt"` /
  `"round" | "miter"` union in the web config type.

