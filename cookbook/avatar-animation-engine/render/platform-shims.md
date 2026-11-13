---
id: 39f26055-c002-40fe-81e2-74c0f9c9311d
title: "Avatar Engine Render"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-09-23
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Bridges the avatar engine's per-frame DisplayList to CoreAnimation/CoreGraphics (Apple) and SVG (web) drawing primitives."
platforms:
  - swift
  - macos
  - ios
  - typescript
  - web
tags:
  - avatar-engine
  - rendering
  - cross-platform
  - logic
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Avatar Engine Render

## Overview

This is a non-UI component: a logic seam with no visual surface of its own.
It converts values the avatar engine already computed (a `Mat`, a hex ink
string, a path-data string, a `DisplayList`) into the vocabulary a
platform's own drawing API understands (`CGAffineTransform`, `CGColor`,
`CGPath`, `CGLineCap`/`CGLineJoin` on Apple; `<path>` attributes on the web).
It never decides what to draw — only how to say it in each platform's own
primitives.

`avatar-engine-render` is the boundary between the avatar engine's per-frame
`DisplayList` (composed elsewhere, by `Scene.compose`) and each platform's
native drawing surface. On Apple it is one file, `PlatformShims.swift`, built
around a single `#if canImport(AppKit)` block: everything AppKit and UIKit
disagree about — view-visibility lifecycle hooks, reduce-motion/focus/
occlusion queries, gesture-recognizer and pointer-location primitives — is
named once, behind one `Platform` enum and one `AvatarHostView` base class, so
no other file in the package imports either framework. The same file also
carries four small, standalone bridges from the engine's own types to
CoreGraphics/CoreAnimation: `Mat` → `CGAffineTransform`, a hex ink string →
`CGColor`, a path-data string → `CGPath`, and a `StrokeStyle`'s cap/join
strings → `CGLineCap`/`CGLineJoin`.

On the web it is `svg.ts`, which turns a `DisplayList` into either a live,
node-reusing `<svg>`/`<path>` DOM tree (`createSvgRenderer`) or a pure string
(`renderToString`) — both built from one shared `attrsOf` function so the two
paths can never disagree, attribute for attribute, about how an item paints.

Neither file contains drawing logic of its own beyond this translation:
geometry, color and paint decisions all arrive from the engine's
`DisplayList` and the character's config; this component only carries them
into each platform's native shape.

## Behavioral Requirements

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

## Appearance

Not applicable — this is a rendering bridge, not a visual component.

## States

Not applicable — this is a rendering bridge, not a visual component.

## Accessibility

Not applicable — this is a rendering bridge, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| avatar-engine-render-001 | matrix-bridge-field-order | `CGPoint(x:7,y:-3).applying(CGAffineTransform(Mat(a:1.5,b:-0.25,c:0.75,d:2,e:30,f:-12)))` | Equal (to 1e-12) to `Mat.apply(x:7,y:-3)` on the same `Mat` — `RenderTests.swift testTheCGAffineTransformBridgeMapsAPointExactlyAsMatDoes`. |
| avatar-engine-render-002 | live-environment-reduce-motion-only, live-environment-main-actor-only | `AvatarEnvironment.live().reducedMotion()` called on the main actor | Returns without trapping; `Platform.viewSpaceIsBottomLeft == true` on the macOS-only test bundle — `RenderTests.swift testTheLiveEnvironmentReadsTheHostAccessibilitySetting`. |
| avatar-engine-render-003 | path-from-display-item, path-from-display-item-throws | `CGPath.avatarItem("M0,0C10,0 20,10 20,20L30,20Z")` vs. `CGPath.avatarItem("Q0,0 1,1")` | First equals `AvatarLayerView.cgPath(parsePath(d))`; second throws — `RenderTests.swift testThePublicPathDoorBuildsTheSamePathAsTheInternalBuilder`. |
| avatar-engine-render-004 | stroke-cap-mapping, stroke-join-mapping, stroke-mapping-never-throws | `StrokeStyle(width:4, linecap:"wobbly", linejoin:"wobbly")` | `.cgLineCap == .butt`, `.cgLineJoin == .miter`, no throw — `RenderTests.swift testTheStrokeStyleVocabularyMapsOntoCoreGraphicsCapsAndJoins`. |
| avatar-engine-render-005 | svg-attribute-set, render-to-string-structure | `renderToString(config, engine.tick(0))` | Contains `viewBox="0 0 400 400"`; exactly one `<path ` per display item — `svg.test.ts "emits a 400x400 viewBox and one path per display item"`. |
| avatar-engine-render-006 | svg-attribute-set | `renderToString` over a list whose items carry `m: [1,2,3,4,5,6]` | Output contains `matrix(1,2,3,4,5,6)` — `svg.test.ts "writes matrix() in the a,b,c,d,e,f order"`. |
| avatar-engine-render-007 | fill-stroke-selection-shared | `renderToString(config, list)` over a mixed fill/stroke list | Count of `stroke="#` matches equals the number of unfilled items; count of `fill="#` matches equals the number of filled items — `svg.test.ts "strokes unfilled shapes and fills filled ones"`. |
| avatar-engine-render-008 | svg-linecap-linejoin-verbatim | `renderToString` with `strokeStyle.linecap/linejoin == "round"` | Output contains `stroke-linecap="round"` and `stroke-linejoin="round"`; no `<style` tag — `svg.test.ts "carries the config's stroke style, not a stylesheet"`. |
| avatar-engine-render-009 | render-to-string-purity | `renderToString(config, list)` called twice with the same arguments | Both calls return an identical string — `svg.test.ts "escapes nothing it does not need to and stays stable across renders"`. |
| avatar-engine-render-010 | svg-renderer-node-creation-once, svg-renderer-paint-order-fixed-on-first-appearance | `createSvgRenderer(config, doc)`; `render(tick(0))`; then `render(tick(t))` for `t` from `1/60` to `3` | Exactly `n+1` elements are ever created (n paths plus the `<svg>`); `root.children` after the loop is deep-equal to its value right after the first render — `svg.test.ts "creates one <path> per item on the first frame, and none on any frame after"`. |
| avatar-engine-render-011 | svg-renderer-destroy-clears-paths, svg-renderer-render-after-destroy | `render(tick(0))`; `destroy()`; `render(tick(0))` | Children count is `0` right after `destroy()`, back to `n` after the second render; total elements ever created is `2n+1` — `svg.test.ts "forgets everything on destroy"`. |
| avatar-engine-render-012 | svg-attribute-single-source | `renderToString(config, list)`'s per-`<path>` attributes vs. `createSvgRenderer(config, doc).render(list)`'s resulting node attributes, over a list containing both a filled and an unfilled item | The two attribute sets are equal, item for item — `svg.test.ts "paints exactly what renderToString writes, attribute for attribute"`. |

## Edge Cases

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

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `config` (web) | `CharacterConfig` | none — required | Passed to `createSvgRenderer` and `renderToString`; supplies `character.canvas.{w,h}` for the `<svg>` `viewBox` and `character.strokeStyle.{width,linecap,linejoin}` for a stroked item's defaults. |
| `doc` (web) | `Document` | `document` (the global) | Passed to `createSvgRenderer`; injected so the renderer can run against a fake `Document` in tests or any non-browser host. |
| `d` (apple) | `String` | none — required | The path-data argument to `CGPath.avatarItem(_:)`. |
| hex string (apple) | `String` | none — required | The `#rrggbb`/`#rgb` argument to `CGColor.avatarInk(_:)`. |
| `m` (apple) | `Mat` | none — required | The 2×3 affine argument to `CGAffineTransform.init(_:)`. |
| `target`/`selector`/`action` (apple) | `AnyObject`/`Selector` | none — required | Arguments to `Platform.displayLink(on:target:selector:)`, `.makeTapRecognizer(target:action:)`, and `.makeDragRecognizers(target:action:)`. |

Neither file reads an environment variable, a `UserDefaults`/settings key, or
a config file directly; every parameter above is supplied by the caller at
the call site.

## Deep Linking

Not applicable: neither `PlatformShims.swift` nor `svg.ts` parses or
constructs a URL — both operate purely on in-memory geometry, color and
DOM-attribute values.

## Localization

Not applicable: neither file contains a user-facing string. The strings that
pass through them — hex colors, path-data letters, stroke-style keywords,
notification and selector names — are data or API vocabulary, never text
shown to a user.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | `Platform.reduceMotion()` reads `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` (AppKit) or `UIAccessibility.isReduceMotionEnabled` (UIKit) fresh on every call; `AvatarEnvironment.live()` exposes it as the `reducedMotion` closure the engine samples elsewhere. This component only surfaces the OS setting — it does not itself change any drawing decision based on it. |
| Increase Contrast | Not applicable: neither file reads or reacts to a contrast setting; ink color values arrive from the character config verbatim. |
| Differentiate Without Color | Not applicable: paint is a single ink color used as a fill or a stroke; neither file relies on hue alone to distinguish state, nor offers an alternate encoding. |

## Feature Flags

Not applicable: neither file reads a flag or settings key. Every branch is
either a compile-time platform check (`#if canImport(AppKit)`) or a per-item
data value (`paint.fill`), never a runtime feature toggle.

## Analytics

Not applicable: neither file calls an event or telemetry API.

## Privacy

- **Data collected**: None. Both files handle only geometry (`Mat`,
  `CGAffineTransform`), color hex strings, and path-data strings drawn from
  the character's own config; nothing personally identifying passes through
  either file.
- **Storage**: Not applicable — neither file persists anything.
- **Transmission**: Not applicable — neither file performs network I/O.
- **Retention**: Not applicable — nothing is retained by this component.

## Logging

Not applicable: neither file calls a logger, `print`, `os_log`, or
`console.*`. Failures are communicated only through return values (`nil` from
`avatarInk`, a thrown error from `avatarItem`) to the caller.

## Platform Notes

- **AppKit / UIKit**: `PlatformShims.swift` is the source — a single
  `#if canImport(AppKit)` file holding `AvatarHostView` (an `NSView`/`UIView`
  subclass exposing one `hostVisibilityChanged()` hook, fired from each SDK's
  own window/visibility callbacks) and the `Platform` enum (view-space
  orientation, reduce-motion, layer access, gesture-recognizer creation, and
  pointer/focus/occlusion queries), plus the `CGAffineTransform`/`CGColor`/
  `CGPath`/`StrokeStyle` bridges. Nothing outside this file imports AppKit or
  UIKit.
- **React/Web**: `svg.ts` is the source — plain imperative DOM
  (`document.createElementNS`, `setAttribute`), not React. A `DisplayItem`
  maps to one `<path>`, created once and mutated via `attrsOf`/`applyItem` on
  every later frame. A React port that rendered a `<path>` via JSX per frame
  would need to preserve that same "create once, mutate forever" identity —
  a stable `key` on `item.id` plus an imperative attribute write in a
  `useLayoutEffect`/ref callback — rather than trusting React's virtual-DOM
  diff, which does not guarantee the same node survives frame to frame.
- **SwiftUI**: There is no SwiftUI layer in this recipe's sources; the
  consuming renderer drives raw `CAShapeLayer`s directly. A SwiftUI port
  would replace that with a `Canvas`/`GraphicsContext` view (or a custom
  `Shape`) driven by `TimelineView(.animation)` instead of `CADisplayLink`.
  The bridges here still mostly apply: `GraphicsContext.transform` takes a
  `CGAffineTransform`, and `Color(cgColor:)` can wrap `CGColor.avatarInk`'s
  result directly; per-item identity would need an explicit `id(item.id)` to
  get the same "first frame fixes paint order" guarantee `svg.ts`'s `Map`
  gives for free.
- **Compose**: The equivalent surface is a `Canvas` composable using
  `drawPath`/`withTransform`, driven by `withFrameNanos` in place of
  `CADisplayLink`/`requestAnimationFrame`. `Platform.reduceMotion()` maps to
  reading the system's animator-duration-scale setting via
  `Settings.Global.ANIMATOR_DURATION_SCALE` or an
  `AccessibilityManager`-based check. Compose's `Canvas` redraws imperatively
  inside one lambda rather than mutating retained nodes, so the "create once,
  reuse forever" node cache this recipe relies on (both the Apple layer cache
  and the web `Map`) has no direct analogue; a port would need `remember`ed
  `Path` objects keyed by `item.id` to avoid re-parsing `item.d` every frame.
- **WinUI 3**: A `Microsoft.UI.Xaml.Shapes.Path` per `DisplayItem`, held in a
  `Canvas` and reused frame-to-frame exactly as `svg.ts`'s
  `Map<string, SVGPathElement>` and the Apple layer cache do — one `Path`
  created the first time an `id` is seen, its `Data` (a `PathGeometry` or
  Win2D `CanvasGeometry`, parsed from the same `M`/`L`/`C`/`Z` string this
  recipe's path parser reads), `RenderTransform` (a `MatrixTransform` built
  from the same six fields as `Mat`/`CGAffineTransform` —
  `Matrix(a, b, c, d, e/OffsetX, f/OffsetY)`), `Opacity` (from `paint.alpha`,
  mirroring the alpha-on-opacity-not-color decision below), and `Fill`/
  `Stroke` (a `SolidColorBrush` built from the same hex string
  `CGColor.avatarInk`/the SVG `fill`/`stroke` value parse, via a small
  hex-to-`Windows.UI.Color` helper) updated on each tick. The per-frame
  driver is `CompositionTarget.Rendering` (the `CADisplayLink`/
  `requestAnimationFrame` equivalent); the update must stay synchronous —
  `CompositionTarget.Rendering` fires on the UI thread, and a `Task`/`async`
  write would land a frame late. There is no `HttpClient`/`System.Text.Json`/
  `Windows.Storage` surface to port here, since this component neither talks
  to the network nor persists anything. Reduce Motion reads
  `Windows.UI.ViewManagement.UISettings.AnimationsEnabled`, matching
  `Platform.reduceMotion()`'s AppKit/UIKit calls.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AvatarAnimationEngine/Sources/Render/PlatformShims.swift` | unverified |
| web | `packages/web/packages/avatar-engine/src/render/svg.ts` | unverified |

## Design Decisions

**Decision**: Confine every AppKit/UIKit divergence to one
`#if canImport(AppKit)` block, behind a single `Platform` enum and a single
`AvatarHostView` base class.
**Rationale**: Keeps every platform conditional in one file, per the source's
own comment, so the rest of the rendering and animation code stays
platform-agnostic; a new platform-specific need is added here once instead of
scattering `#if` blocks across the package.
**Approved**: pending

**Decision**: `Mat` stays a plain `Double`-based struct and is bridged to
`CGAffineTransform` only at the one point `CGAffineTransform.init(_ m: Mat)`
needs it.
**Rationale**: `CGAffineTransform`'s storage is `CGFloat`, which is `Float`
on some architectures and would silently cost the engine's 1e-6 golden-test
tolerance; keeping `Mat` as `Double` and converting only at this single seam
preserves that precision everywhere else.
**Approved**: pending

**Decision**: `CGColor.avatarInk`'s result and `attrsOf`'s `fill`/`stroke`
value both exclude a display item's `paint.alpha`; alpha is applied only
through the target's own opacity.
**Rationale**: `paint.alpha` animates every frame; folding it into the color
value itself would mean rebuilding a `CGColor` on Apple, or losing the
single-attribute-write economy on the web, on every frame of every fade.
**Approved**: pending

**Decision**: `CGPath.avatarItem(_:)` is the one public function this file
exposes for path conversion, rather than making the underlying parser and
path builder themselves public.
**Rationale**: Per the source's own comment, the alternative is three types
exposed to hide one string, or every external host reproducing the cubic
control-point-before-endpoint argument order by hand — "a version that
compiles, runs, and draws every curve wrong."
**Approved**: pending

**Decision**: An unrecognized `linecap`/`linejoin` string falls back to
Core Graphics' own default (`.butt`/`.miter`) inside `StrokeStyle.cgLineCap`/
`cgLineJoin`, rather than throwing.
**Rationale**: Per the source's own comment, the config loader is where a bad
vocabulary should be caught; a renderer that refused to draw would report the
problem in the least useful place.
**Approved**: pending

**Decision**: `attrsOf` is the single function both the live-DOM path
(`applyItem`) and the string path (`renderToString`'s `attrs`) call to
compute an item's paint attributes.
**Rationale**: Per the source's own comment, two hand-written serializers
agreeing today is not the same claim as their still agreeing after someone
adds a paint attribute to one of them; a shared function makes the two paths
incapable of drifting apart.
**Approved**: pending

**Decision**: `Platform.makeDragRecognizers` returns an empty array on
AppKit rather than a click-and-drag gesture recognizer.
**Rationale**: Per the source's own comment, macOS has a real cursor, which
`pointerLocation` samples every frame instead — closer to how `pointermove`
behaves than a discrete drag gesture would be.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d) | passed | Performance |
| [adc.check.performance.animation-frame-rate](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9eb9b4fc-2e44-5391-9445-d6e78caa874e) | partial | Performance |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Neither file swallows an error: `CGColor.avatarInk` returns `nil` and
`CGPath.avatarItem` throws, both propagated to the caller rather than
absorbed (explicit-error-handling). `PlatformShims.swift`'s entire structure
is one file isolating AppKit/UIKit specifics from the rest of the package,
and `svg.ts` isolates DOM/string paint decisions behind one `attrsOf`
function used by both render paths (separation-of-concerns). All operations
in both files are small, synchronous, and O(items) per frame, with no I/O or
network call in the render path (main-thread-freedom). This is the render
path for a per-frame, `CADisplayLink`/animation-loop-driven `DisplayList`,
but neither file measures or enforces a per-frame time budget — the
node-reuse design (one `<path>`/layer per id, rewritten rather than rebuilt)
supports a 60fps target without proving it from source alone
(animation-frame-rate: partial). `unit-test-coverage` is passed:
`RenderTests.swift` exercises `PlatformShims.swift`'s `AvatarLayerView`/
`CGColor.avatarInk`/`CGPath.avatarItem` machinery directly, and
`svg.test.ts` exercises `svg.ts`'s `createSvgRenderer`/`renderToString`
against real engine output, both with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.0.2 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (unit-test-coverage: passed). |
