
- **SwiftUI**: The runtime is UIKit/AppKit/SwiftUI-agnostic — `Channels`,
  `Scheduler`, and `Tweens` are plain `Foundation`-only classes with no
  rendering dependency. A SwiftUI host drives `tick` from a `TimelineView` or
  a `CADisplayLink`-backed publisher, reading `Channels` afterward to update
  `@State`/`@Observable` properties that feed the view; nothing about these
  three types changes for SwiftUI versus any other Apple UI framework.
- **Compose**: Port `ChannelValue` as a `sealed interface`/`sealed class`
  with `Number`/`Text` variants (Kotlin has no built-in tagged union), back
  `Channels` with a `MutableMap<String, ChannelValue>` (or `SnapshotStateMap`
  if channel reads should trigger recomposition directly), and drive
  `Scheduler`/`Tweens.tick` from a `withFrameNanos`/`LaunchedEffect` loop
  converting nanoseconds to the same absolute-seconds clock the source uses.
- **React/Web**: This IS the reference implementation
  (`packages/web/packages/avatar-engine/src/runtime/{channels,scheduler,tween}.ts`);
  a host drives `tick` from `requestAnimationFrame`, converting the RAF
  timestamp to seconds since the engine's own origin (see `useAvatarEngine`,
  which is outside this component's scope).
- **AppKit / UIKit**: Also UI-framework-agnostic like the SwiftUI note above;
  an AppKit/UIKit host drives `tick` from a `CVDisplayLink`/`CADisplayLink`
  callback and reads `Channels` in its own drawing/layout pass — no part of
  `Channels`, `Scheduler`, or `Tweens` depends on either framework.
- **WinUI 3**: Model `ChannelValue` as a small `readonly record struct` or a
  two-case discriminated union (`double` XOR `string`, since C# has no native
  tagged union) rather than reusing `object`, so a channel can never silently
  hold an unsupported type. Back `Channels` with a plain
  `Dictionary<string, ChannelValue>` (`ObservableCollection`/
  `INotifyPropertyChanged` are unnecessary here — nothing in source makes
  `Channels` itself observable; only the rendered composition downstream
  needs to notify a view). Drive `Scheduler`/`Tweens.Tick` from
  `CompositionTarget.Rendering` or a `DispatcherQueueTimer`, using
  `Stopwatch.Elapsed.TotalSeconds` (or an injected clock) as the same
  absolute-seconds `now` the source threads through every call — never
  `DateTime.Now`, whose resolution and monotonicity guarantees are weaker
  than `Stopwatch`'s. Port the 24-entry ease table as a
  `static readonly Dictionary<string, Func<double, double>>` built once
  (mirroring the Swift `static let table` comment's reasoning: build
  immutably, once, so it is safe to read from multiple call sites without a
  lock), and port `Ease.resolve`/`resolveEase` as a method that throws
  `KeyNotFoundException` (or a dedicated exception type) for an unknown name
  rather than returning a default curve, matching **tween-ease-resolution-fails-closed**.
  There is no `Task`/`async` surface to port: every method here (`Channels.Get`/
  `Set`, `Scheduler.Tick`, `Tweens.Add`/`Tick`) is synchronous, called from
  whatever single thread drives the host's render loop — an `async` wrapper
  would misrepresent the contract.

