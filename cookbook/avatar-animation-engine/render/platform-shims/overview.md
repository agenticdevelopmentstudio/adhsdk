
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

