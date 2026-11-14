
- **AppKit / UIKit**: uses `Foundation`'s `Double` for all timestamps/durations
  (no `Date`/`DispatchTime`), Swift's native `struct`/`enum`/`final class`
  for data shapes, and `throws`/`Error` for the two validated failure paths.
  An unreachable/loader-guaranteed branch (an unrecognized predicate kind,
  a spin channel not present where expected) uses `preconditionFailure`/
  `try!`, which traps the process rather than returning an error — see
  Design Decisions.
- **SwiftUI**: Nothing in this component is view-specific, so a SwiftUI host uses the Swift types unchanged and drives `Scheduler.tick`, the arbiter and reflexes, and `Tweens.tick` from its own frame source (a `TimelineView` or display link), then renders `Channels` values.
- **Compose**: Translate the data shapes to Kotlin `data class` and `sealed interface` types, with `Double` timestamps and `Map` in place of dictionaries. The two validated failure paths (`setMood`, `play`) throw `IllegalArgumentException` with the same messages. Drive the fixed tick order from `withFrameNanos`, and keep all calls on one coroutine dispatcher, since the contract is single-caller.
- **React/Web**: mirrors every type one-for-one (`MoodSource`,
  `SpeechState`, `ArbiterState` are the same names on both sides) using
  plain interfaces/discriminated unions and `Map`/plain objects in place of
  Swift's `Dictionary`; the same unreachable/loader-guaranteed branches
  `throw` a catchable `Error` on this side instead of trapping, which is
  the one systematic behavioral divergence between the platforms (see
  Design Decisions).
- **WinUI 3**: this component's data shapes translate directly
  to C# `record`/`readonly struct` types; `Scheduler`/`Tweens`/`Channels`
  (from `avatar-engine-runtime`) are the natural home for
  `System.Threading.Tasks`/`DispatcherQueue.TryEnqueue`-based scheduling in
  place of the given sources' plain closures, and `ObservableCollection`/
  `INotifyPropertyChanged` are not needed here since this component exposes
  no bindable UI state of its own — a WinUI host reads `Arbiter.state` and
  drives its own bound view-models from it. The two validated failure paths
  (`setMood`, `play`) map to a thrown `InvalidOperationException` or a
  dedicated exception type, matching the web side's catchable-`Error`
  choice rather than the Swift side's `preconditionFailure`s. .NET does
  have a process-ending idiom (`Environment.FailFast`), but a library should
  not end its host process over a config the loader should have rejected,
  so throwing is the better choice here.

