
**Decision**: Confine every AppKit/UIKit divergence to one
`#if canImport(AppKit)` block, behind a single `Platform` enum and a single
`AvatarHostView` base class.
**Rationale**: Keeps every platform conditional in one file so the rest of the rendering and animation code stays
platform-agnostic; a new platform-specific need is added here once instead of
scattering `#if` blocks across the package.
**Approved**: pending

**Decision**: `Mat` stays a plain `Double`-based struct and is bridged to
`CGAffineTransform` only at the one point `CGAffineTransform.init(_ m: Mat)`
needs it.
**Rationale**: Keeping `Mat` a `Double` struct keeps CoreGraphics out of the
engine core, so the shared math has one storage type on both platforms and the
1e-6 golden-test tolerance never depends on `CGFloat`'s width; the conversion
happens only at this single seam.
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
**Rationale**: The alternative is three types
exposed to hide one string, or every external host reproducing the cubic
control-point-before-endpoint argument order by hand — "a version that
compiles, runs, and draws every curve wrong."
**Approved**: pending

**Decision**: An unrecognized `linecap`/`linejoin` string falls back to
Core Graphics' own default (`.butt`/`.miter`) inside `StrokeStyle.cgLineCap`/
`cgLineJoin`, rather than throwing.
**Rationale**: The config loader is where a bad
vocabulary should be caught; a renderer that refused to draw would report the
problem in the least useful place.
**Approved**: pending

**Decision**: `attrsOf` is the single function both the live-DOM path
(`applyItem`) and the string path (`renderToString`'s `attrs`) call to
compute an item's paint attributes.
**Rationale**: Two hand-written serializers
agreeing today is not the same claim as their still agreeing after someone
adds a paint attribute to one of them; a shared function makes the two paths
incapable of drifting apart.
**Approved**: pending

**Decision**: `Platform.makeDragRecognizers` returns an empty array on
AppKit rather than a click-and-drag gesture recognizer.
**Rationale**: macOS has a real cursor, which
`pointerLocation` samples every frame instead — closer to how `pointermove`
behaves than a discrete drag gesture would be.
**Approved**: pending

**Decision**: The two platforms diverge on an unrecognized cap/join value: the
Apple bridge maps it to a Core Graphics default (`.butt`/`.miter`), while the
web path writes `strokeStyle.linecap`/`.linejoin` straight through with no
mapping and no fallback (`svg-linecap-linejoin-verbatim`).
**Rationale**: `StrokeStyle.linecap`/`.linejoin` is an unconstrained `String`
in the Apple config type but a `"round" | "butt"` / `"round" | "miter"` union
in the web config type. This is a known divergence, not a contract a port must
reproduce; the config loader is where a bad value should be caught.
**Approved**: pending

**Decision**: The web renderer never removes or hides a `<path>` for an `id`
that disappears from the display list.
**Rationale**: `render` only ever creates and rewrites nodes, which is what
keeps node identity and paint order stable; a vanished `id` leaves its last
attributes on screen (see Edge Cases). The engine's display list keeps a stable
id set for a character, so the gap is accepted rather than paid for with
removal bookkeeping.
**Approved**: pending
