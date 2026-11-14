
- **Swift/Apple**: uses `Foundation`'s `Double` for all timestamps/durations
  (no `Date`/`DispatchTime`), Swift's native `struct`/`enum`/`final class`
  for data shapes, and `throws`/`Error` for the two validated failure paths.
  An unreachable/loader-guaranteed branch (an unrecognized predicate kind,
  a spin channel not present where expected) uses `preconditionFailure`/
  `try!`, which traps the process rather than returning an error — see
  Design Decisions.
- **TypeScript/web**: mirrors every type one-for-one (`MoodSource`,
  `SpeechState`, `ArbiterState` are the same names on both sides) using
  plain interfaces/discriminated unions and `Map`/plain objects in place of
  Swift's `Dictionary`; the same unreachable/loader-guaranteed branches
  `throw` a catchable `Error` on this side instead of trapping, which is
  the one systematic behavioral divergence between the platforms (see
  Design Decisions).
- **WinUI 3 / .NET port**: this component's data shapes translate directly
  to C# `record`/`readonly struct` types; `Scheduler`/`Tweens`/`Channels`
  (from `avatar-engine-runtime`) are the natural home for
  `System.Threading.Tasks`/`DispatcherQueue.TryEnqueue`-based scheduling in
  place of the given sources' plain closures, and `ObservableCollection`/
  `INotifyPropertyChanged` are not needed here since this component exposes
  no bindable UI state of its own — a WinUI host reads `Arbiter.state` and
  drives its own bound view-models from it. The two validated failure paths
  (`setMood`, `play`) map to a thrown `InvalidOperationException` or a
  dedicated exception type, matching the web side's catchable-`Error`
  choice rather than the Swift side's `preconditionFailure`s, since .NET
  has no equivalent "fail the whole process" trap idiom for library code.

