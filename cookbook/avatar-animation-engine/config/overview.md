
The avatar engine config loader is the single entry point that turns six
author-written JSON files — `character.json`, and the rig/poses/timelines/
behavior/sayings files it names — into one validated, in-memory
`CharacterConfig`. It is a headless **engine** component: a pure function from
raw config text to a typed model, with no view, no window, and no rendering.
Every per-frame consumer downstream (rig walker, pose blender, timeline
player, behavior arbiter) trusts the shapes and cross-references
`CharacterConfig` hands it; the loader is the one place a bad reference, a bad
colour, or a bad shape is still attributable to the authored key that caused
it.

Two independent implementations conform to this contract:

- **Apple** (Swift, macOS + iOS): `CharacterConfig.load(_:)` in
  `packages/apple/AvatarAnimationEngine/Sources/Config/Loader.swift`, over the
  types in `Sources/Config/Types.swift`. `RawFiles.read(fromDirectory:)`
  additionally reads the six files from disk (Apple-only; there is no web
  equivalent because the web build receives already-bundled JSON modules).
- **Web** (TypeScript): `loadConfig(input)` in
  `packages/web/packages/avatar-engine/src/config/load.ts`, over the types in
  `src/config/types.ts`.

Both loaders MUST agree on the verdict (accept the config, or reject it) for
every input. They are not required to agree on exact error message text —
several messages differ deliberately between platforms, and each divergence
called out below is intentional, not a defect.

Because this recipe documents a validation contract rather than a widget, the
Appearance, States, and Accessibility sections below each collapse to one
line: the loader draws nothing, has no interaction state, and exposes nothing
to assistive technology.

