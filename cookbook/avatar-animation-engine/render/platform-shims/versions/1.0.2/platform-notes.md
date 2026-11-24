
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

