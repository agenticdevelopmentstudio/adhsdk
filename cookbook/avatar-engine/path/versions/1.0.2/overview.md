
Avatar Engine Path is the shared path-data layer under the avatar animation
engine: a deliberately tiny SVG path grammar (`parsePath`/`emitPath`), a set of
primitive shape builders (`disc`, `ring`, `arc`, `polyline`, `bezier`), an
anchor-for-anchor path morph (`morphPath`), and a polyline-to-cubic
re-expression (`promotePolyline`). Every rig shape the engine draws — mouths,
brows, rings, discs — becomes a `ParsedPath` built or parsed through this
layer, and every `.shape` channel a pose or timeline animates is a path-data
string this layer produced, morphed, or promoted. It is a headless, non-visual
computation library — no view, layer, or DOM element — implemented twice, once
in Swift (`packages/apple/AvatarAnimationEngine/Sources/Path/`) and once in
TypeScript (`packages/web/packages/avatar-engine/src/path/`), and it is the one
place in the engine where the two implementations must agree
character-for-character: recorded/replayed animation goldens compare their
path-data output byte-for-byte across platforms.

