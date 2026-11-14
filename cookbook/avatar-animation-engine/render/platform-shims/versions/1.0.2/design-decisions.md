
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

