
- **SwiftUI**: The engine is UI-framework agnostic; a SwiftUI host owns the
  frame loop (a `TimelineView` or a `CADisplayLink`-backed driver) that calls
  `engine.tick(_:)` once per frame and feeds the returned `DisplayList` into a
  `Canvas` or a custom `Shape`. SwiftUI's own animation system (`.animation`,
  `withAnimation`) is not used for the avatar's motion — the engine already
  owns interpolation via its runtime's `Tweens`.
- **Compose**: The equivalent host pattern is `withFrameNanos`/a
  `LaunchedEffect` driving a per-frame call into a Kotlin port of `tick`, with
  a `Canvas` composable drawing the returned display list; as with SwiftUI,
  Compose's own animation APIs (`Animatable`, `animate*AsState`) are not used
  for avatar motion, since the engine's `Tweens` already owns it.
- **React/Web** (source platform): `engine.ts`'s `createEngine` and `env.ts`'s
  `defaultEnvironment`/`browserEnvironment` are the actual implementation. A
  host drives `tick` from a `requestAnimationFrame` loop and renders the
  returned `DisplayList` (commonly via the sibling `render/svg` entry point
  in this same package); `browserEnvironment()` supplies `reducedMotion` by
  reading `matchMedia("(prefers-reduced-motion: reduce)")` off `globalThis`
  once at construction.
- **AppKit / UIKit** (source platform): `Engine.swift` and `Environment.swift`
  are the actual implementation. A host drives `tick(_:)` from a
  `CVDisplayLink` (AppKit) or `CADisplayLink` (UIKit) callback and renders the
  returned `DisplayList`; the real, platform-backed `AvatarEnvironment` (its
  `reducedMotion` reading `NSWorkspace`'s or `UIAccessibility`'s reduce-motion
  flag) lives in `Render/PlatformShims.swift`'s `AvatarEnvironment.live()`
  extension, per `Environment.swift`'s own doc comment, not in the two files
  given to this recipe.
- **WinUI 3**: this is the platform this recipe exists to prepare a port for,
  and it needs a from-scratch host and engine, since neither given source
  compiles on .NET. Drive `Tick(double now)` from a
  `CompositionTarget.Rendering` event or a `DispatcherQueueTimer`, called
  synchronously on the UI thread — not through `Task.Run`/`async`, since the
  fixed scheduler-then-arbiter-then-tweens-then-compose order this contract
  requires must run on one thread without interleaving. Deserialize
  `CharacterConfig` with `System.Text.Json` (mirroring the config loader's
  contract, not this recipe's). Port the xoshiro128** `Prng` bit-for-bit in
  C# using `uint` arithmetic; .NET's `System.Random` will not reproduce the
  same stream and MUST NOT be substituted. Read the reduced-motion state
  from `Windows.UI.ViewManagement.UISettings` (or the Windows App SDK's
  accessibility settings API) and wire it the same way
  `AvatarEnvironment.reducedMotion`/`Environment.reducedMotion()` is wired
  here — a predicate read fresh on use, not cached. `DisplayList` is a
  fresh array/list
  returned whole on every tick, not an incrementally-mutated collection, so
  an `ObservableCollection` is unnecessary for it; wrap `ArbiterState` in an
  `INotifyPropertyChanged`-conforming type only if a XAML view will data-bind
  directly to `mood`/`speech` rather than reading them off the return value
  of a poll.

