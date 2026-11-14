
- **Malformed hex input (empty, wrong length, non-hex characters, non-ASCII
  hex-looking digits)**: `parseHex` MUST throw a catchable error rather than
  crash, per `hex-parse-failure`. An empty string has length 0 (not 3 or 6)
  and fails the length check before any charset check runs.
- **A `#` that is not a single leading character, or whitespace outside
  Swift's `.whitespaces` set (a newline, a BOM) — divergent acceptance
  across platforms**: per `hex-input-normalization`, Swift strips only a
  leading `#` and trims only spaces/tabs, so an embedded `#` (`"abc#def"`)
  or a trailing/leading newline or U+FEFF is left in the string and MUST
  fail `hex-charset-validation` (or the length check). Web's `.replace`
  deletes the first `#` wherever it occurs and `.trim()` removes newlines
  and U+FEFF too, so the same inputs normalize to a valid 6-character body
  and MUST parse successfully. A shared conformance vector cannot assert
  one outcome for both platforms on such an input.
- **Colour-channel `NaN`** (e.g. from an upstream divide-by-zero in an
  interpolation): `toHex` MUST render the affected channel as `00` rather
  than propagating `NaN` or trapping, per `nan-channel-clamped`.
- **`mix` at or beyond the unit interval boundary** (`t <= 0`, `t >= 1`,
  including negative `t` or `t > 1`): MUST short-circuit to the corresponding
  endpoint color without an OKLab conversion, per `mix-endpoint-exactness`.
  The source does not clamp `t` to `[0,1]` for the values it forwards to
  `parseHex`/`toHex` in the interpolated case (`0 < t < 1`); any `t` in that
  open interval is used as given.
- **Ease name outside the closed vocabulary, including near-misses**
  (`"power2"` bare, `"back.out(2.2)"`, `"back.in(2)"`, `"elastic.out"`): MUST
  throw, per `ease-unknown-name-rejected`. The table is a fixed lookup, not a
  parser, so no numeric argument to `back.out` other than the six listed
  values is ever evaluated.
- **PRNG seed of `0`**: `prng-zero-state-avoidance` forces `s0` to `1` after
  `splitmix32` expansion if all four words are zero, so a seed of `0` still
  produces a valid, non-degenerate stream.
- **`pick`/`pickOrNil` on an empty array — divergent failure mode across
  platforms**: `pickOrNil`/`pickOrUndefined` MUST return `nil`/`undefined`
  without consuming a draw (`prng-pick-or-nil-empty`). `pick`/`pick` itself
  has no total behavior for an empty array: the web's `pick` throws a
  catchable `Error` naming `loadConfig` as the validator that should have
  rejected the empty list upstream; Swift's `pick` instead calls
  `preconditionFailure`, which **terminates the process** and cannot be
  caught by a Swift caller or a test — a documented, intentional
  cross-platform divergence in failure severity for the same misuse (see
  Design Decisions), not an oversight.
- **Concurrent access to a single `Prng` instance**: `Prng` is a Swift
  `final class` with four mutable `var` state words and is not declared
  `Sendable`; `createPrng`'s returned object closes over mutable `let`
  bindings. Both source comments state the caller obligation that draws
  happen "ONLY at scheduled events, never per tick" (`prng-scheduled-draw-
  only`), but neither the Swift type nor the TypeScript type enforces
  single-writer access — there is no lock, actor isolation, or atomic
  compare-and-swap around `s0`..`s3` — see **prng-concurrency**
  below.
- **prng-concurrency**: The Swift `Prng` is a non-`Sendable` `public final class` with no lock or actor, so strict concurrency confines each instance to one isolation domain and a second thread cannot draw from it; the TypeScript `Prng` runs on the single-threaded JS event loop, where each draw completes synchronously. Draws on one instance are therefore serialized by construction, and the stream order is the order of the caller's calls.
- **Degenerate/non-finite `Mat` transform inputs** (`NaN` or `Infinity` in
  `rotation`, `scaleX`, `scaleY`, `x`, `y`, or a pivot coordinate): unlike
  `Color`'s explicit `clamp01`, neither `Mat.from`/`fromTransform` nor
  `apply`/`applyPoint` clamps, checks, or rejects non-finite input anywhere
  in `Mat.swift`/`mat.ts`, and no test in `MatTests`/`mat.test.ts` exercises
  `NaN` or `Infinity` input — see the open question on mat-non-finite-input
  below.
- **mat-non-finite-input**: NEEDS REVIEW: Not implemented in source. Neither `Mat.from`/`fromTransform` nor `apply`/`applyPoint` rejects, clamps, or checks a non-finite (`NaN`/`Infinity`) `rotation`, `scaleX`, `scaleY`, `x`, `y`, or pivot coordinate in `Mat.swift`/`mat.ts`, so such a value propagates silently into whatever consumes the transform (e.g. a renderer) — the same failure mode `Color`'s `clamp01` exists to prevent; resolving it needs a decision from whoever owns the renderer contract on whether `Mat` should guard the same way `Color` does.
- **Concurrent calls into `Ease.resolve`/`resolveEase`**: the Swift ease
  table is a `static let` built by an immediately-invoked closure, which
  Swift's runtime guarantees is initialized exactly once even under
  concurrent first access; the web `TABLE` is a module-level `const`
  populated at module load, before any concurrent call can occur. Both are
  read-only after construction, so concurrent `resolve` calls are safe by
  construction — this is a resolved contract, not an open question.
- **Offline/disconnected state**: Not applicable — none of the four modules
  perform network access; there is no connectivity-dependent behavior to
  define.

