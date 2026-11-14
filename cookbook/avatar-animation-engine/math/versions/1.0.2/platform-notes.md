
- **SwiftUI**: The source files (`Color.swift`, `Ease.swift`, `Mat.swift`,
  `Prng.swift`, under `packages/apple/AvatarAnimationEngine/Sources/Math/`)
  import only `Foundation` — no `import SwiftUI` anywhere. A SwiftUI host
  consumes them exactly as any other Swift value type/enum: `Mat` is
  `Equatable, Sendable`; `Color` and `Ease` expose only static functions; a
  view model owns a `Prng` instance and confines its draws to one call site
  per `prng-scheduled-draw-only`.
- **Compose**: Kotlin has no built-in xoshiro128**, so a port MUST hand-write
  it with `kotlin.math` (`kotlin.math.cbrt`, `pow`, `sin`, `cos`) for `Color`
  and `Mat`, and explicit `UInt`/`Int` bit operations
  (`rotateLeft`/`ushr`/`shl`, all already 32-bit-wrapping under Kotlin's
  `UInt`) for `Prng` — `kotlin.random.Random` is NOT a substitute, since it
  is neither the xoshiro128** algorithm nor guaranteed bit-identical to the
  Swift/TypeScript stream. `Ease`'s table is naturally a `Map<String, (Double)
  -> Double>` built once as a top-level `val`.
- **React/Web**: The source files (`color.ts`, `ease.ts`, `mat.ts`,
  `prng.ts`, under
  `packages/web/packages/avatar-engine/src/math/`) are the other reference
  implementation this recipe specifies verbatim; a React host imports them
  as ordinary modules with no framework coupling (no React import in any of
  the four files).
- **AppKit / UIKit**: Same Swift source files as the SwiftUI bullet — the
  module is UI-framework-agnostic. The one framework-adjacent hazard noted
  in `Mat.swift`'s own comments: do not substitute `CGAffineTransform` for
  `Mat`, because `CGAffineTransform`'s `CGFloat` storage is 32-bit `Float`
  on some architectures and would silently violate the `1e-6` cross-platform
  tolerance that `Mat`'s `Double` storage is chosen to preserve
  (`mat-double-precision`).
- **WinUI 3**: There is no bit-identical xoshiro128** or OKLab type in
  .NET/Windows App SDK, so a port hand-writes all four modules against
  `System.Math`/`double`: `Color` uses `Math.Pow`, `Math.Cbrt`, and
  `Math.Round` (guard the `NaN` case explicitly — C#'s `(int)double.NaN`
  throws `OverflowException` in a checked context, the same crash risk
  `Color.swift`'s own comments call out for `Int(Double.nan.rounded())`).
  `Mat` is a `readonly struct` of six `double` fields — NOT
  `System.Numerics.Matrix3x2`, whose components are `float` and would
  reintroduce the precision loss `mat-double-precision` exists to avoid.
  `Ease`'s table is a `static readonly Dictionary<string, Func<double,
  double>>` populated once in a static initializer (the CLR guarantees a
  type's static constructor runs exactly once, thread-safely, matching the
  Swift/web once-only table construction). `Prng` needs its 32-bit-wrapping
  arithmetic done with `uint` inside an `unchecked` block (C#'s `uint`
  overflow is unchecked by default outside a `checked` context, matching
  Swift's `&+`/`&*` and the web's `>>> 0`), and `System.Numerics.
  BitOperations.RotateLeft(uint, int)` in place of the hand-rolled `rotl`.
  None of the four modules need `HttpClient`, `System.Text.Json`, `Windows.
  Storage`, `Task`/`async`, `ObservableCollection`, or
  `INotifyPropertyChanged` — they are synchronous, in-memory, side-effect-free
  functions, so a WinUI 3 port needs no I/O, serialization, or
  notification plumbing at this layer.

