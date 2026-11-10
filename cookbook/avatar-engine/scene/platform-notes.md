
- **SwiftUI**: this is one of the source platforms. `Rig.swift` is plain
  Foundation code with no `import SwiftUI`/`AppKit`/`UIKit`; a SwiftUI host
  re-invokes `scene.compose(channels)` every frame (typically from a
  `TimelineView(.animation)` or a `CADisplayLink`-driven wrapper, see
  [adhsdk.ingredient.avatar-animation-engine.render.platform-shims](cookbook:39f26055-c002-40fe-81e2-74c0f9c9311d)) and hands the
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
  port ([adhsdk.ingredient.avatar-animation-engine.runtime](cookbook:74ba9dde-4963-42cb-aa03-bf1ee4dcc794)) backs
  the per-node channel lookups this component performs.
- **WinUI 3 (.NET, port target)**: model `DisplayItem` as a C# record (with
  a nested `Paint` record for `ink`/`alpha`/`fill`/`width`), and port
  `Scene`/`buildScene`, `compose`, and `crop`/`cropList` as ordinary
  synchronous methods returning `IReadOnlyList<DisplayItem>` — no
  `Task`/`async` is warranted, matching the synchronous reference on both
  source platforms. Back the per-frame `<id>.x`/`.rotation`/etc. lookups
  with the `Channels`/`ChannelValue` port described in
  [adhsdk.ingredient.avatar-animation-engine.runtime](cookbook:74ba9dde-4963-42cb-aa03-bf1ee4dcc794)
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

