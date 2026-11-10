
- **SwiftUI**: Not the source platform, but a natural additional consumer: a
  `Shape`/`Path` can be built directly from `emitPath`'s output by walking the
  same `M`/`L`/`C`/`Z` token stream into `CGMutablePath.move(to:)`/
  `addLine(to:)`/`addCurve(to:control1:control2:)` calls, and a morph can be
  driven either by feeding `morphPath`'s per-frame output into a fresh `Path`
  or by exposing the flat `points` array as a `Shape`'s `animatableData`.
- **AppKit / UIKit — this recipe's actual Swift consumer**: `Build.swift`,
  `Morph.swift`, and `ParsedPath.swift`
  (`packages/apple/AvatarAnimationEngine/Sources/Path/`) are Foundation-only
  and framework-agnostic; the engine's own render layer
  (`Sources/Render/AvatarLayerView.swift`, `PlatformShims.swift`) is what turns
  their `String` path-data output into `CGPath`/`CAShapeLayer` content on
  screen, via the same token-walking step SwiftUI would use.
- **React/Web — the other source platform**: `build.ts`, `morph.ts`,
  `parse.ts`, and `promote.ts`
  (`packages/web/packages/avatar-engine/src/path/`) already produce an SVG `d`
  attribute string directly; a React consumer binds it to
  `svg path` `d={…}` and lets the browser rasterize it, with `fmt`'s exact
  formatting doing the cross-platform-agreement work `render/svg.ts` depends
  on.
- **Compose**: `androidx.compose.ui.graphics.Path` mirrors `CGMutablePath` —
  port `parsePath`'s tokenizer to walk the same `(letter, arity)` grammar and
  call `moveTo`/`lineTo`/`cubicTo`; morph by lerping the shared `FloatArray` of
  points the way `morphPath` does, then re-tokenizing into a `Path` on the
  animated frame that needs it.
- **WinUI 3**: Model `ParsedPath` as a `readonly record struct(string Kind,
  double[] Points)` and port `ParsePath`/`EmitPath`/`Fmt` as ordinary static
  methods on a `PathGrammar` class, always parsing/formatting through
  `System.Globalization.CultureInfo.InvariantCulture` (so `.` is the decimal
  separator regardless of the host's locale, matching this layer's ASCII-only
  digit grammar). Port `Build.Disc`/`Ring`/`Arc`/`Polyline`/`Bezier` and
  `MorphPath`/`PromotePolyline` as pure static methods with no
  `INotifyPropertyChanged` or `ObservableCollection` involvement — nothing here
  is bindable state. The resulting `d`-equivalent string feeds a
  `Microsoft.UI.Xaml.Shapes.Path`'s `Data` (a `Geometry` built the same way,
  via `PathGeometry`/`PathFigure`/`LineSegment`/`BezierSegment`), with a
  `Storyboard`/`CompositionAnimation` driving the frame-by-frame `t` that
  `MorphPath` consumes; `Math.Round(x, 6, MidpointRounding.AwayFromZero)` is
  the direct equivalent of Swift's `Double.rounded()` and is what `Fmt` MUST
  use to keep this platform's path-data output byte-identical to the other
  two.

