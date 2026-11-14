
### Color

- **hex-input-normalization**: `parseHex`'s whitespace/`#`-stripping is not
  one shared rule — the two platforms normalize differently and accept
  different inputs. Swift MUST trim only `.whitespaces` (spaces and tabs;
  no newlines, no U+FEFF) via `trimmingCharacters(in: .whitespaces)`, then
  MUST strip a leading `#` only when the trimmed string starts with one
  (`hasPrefix("#")` guarding `removeFirst()`) — a `#` anywhere else in the
  string is left in place and MUST fail hex-charset-validation. Web MUST
  trim all ECMAScript whitespace (including newlines and U+FEFF) via
  `hex.trim()`, then MUST strip the FIRST `#` character occurring anywhere
  in the string via `.replace("#", "")` — including a `#` that is not
  leading. A cross-platform conformance vector cannot assume both platforms
  accept or reject the same input for this case (see Edge Cases).
- **hex-length-expansion**: `parseHex` MUST expand a 3-character hex body to
  6 characters by doubling each character (`h.map { "\($0)\($0)" }.joined()`
  in Swift; `h.split("").map((c) => c + c).join("")` on the web) before
  validating length and charset.
- **hex-charset-validation**: `parseHex` MUST require exactly 6 characters
  after expansion, each an ASCII hex digit (`0-9`, `a-f`, `A-F`). Swift's
  guard is an explicit ASCII-only `isAsciiHexDigit` predicate rather than
  `Character.isHexDigit`, because the latter is also true for Unicode's
  fullwidth digit and letter blocks (U+FF10-FF19, U+FF21-FF26,
  U+FF41-FF46); the web's guard is the ASCII-only regex
  `/[^0-9a-fA-F]/`. A string that a Unicode-aware test would accept but the
  ASCII regex would reject MUST be rejected on both platforms.
- **hex-parse-failure**: `parseHex` MUST throw a catchable error — Swift
  `Color.Failure.badHex(hex)`, web `Error("bad hex colour: ${hex}")` — for
  any input that fails length or charset validation, or whose per-byte parse
  fails (`UInt8(_:radix:)` / `parseInt` returning `NaN`-equivalent), rather
  than force-unwrapping or otherwise trapping the process.
- **hex-channel-range**: `parseHex` MUST return each of the three channels as
  a value in the closed unit interval `[0, 1]`, computed as the parsed byte
  (`0-255`) divided by 255.
- **hex-serialization**: `toHex` MUST render each channel by clamping to
  `[0, 1]`, multiplying by 255, rounding to the nearest integer, and
  formatting as a lowercase, zero-padded 2-digit hex pair, producing a
  7-character string of the form `#rrggbb`.
- **nan-channel-clamped**: `clamp01` MUST map `NaN` to `0` rather than
  passing it through a min/max comparison (every comparison against `NaN` is
  `false`, so a naive min/max clamp lets `NaN` through unchanged). Swift
  additionally depends on this because `Int(Double.nan.rounded())` traps the
  process; the web depends on it because `Math.round(NaN)` is `NaN` and
  `toHex` would otherwise emit the literal string `"#NaNNaNNaN"`. Given a
  channel tuple of `(NaN, NaN, NaN)`, `toHex` MUST return `"#000000"`; given
  `(NaN, 1, 0)` it MUST return `"#00ff00"` — only the `NaN` channel is
  affected.
- **srgb-oklab-conversion**: `srgbToOklab` and `oklabToSrgb` MUST implement
  Björn Ottosson's published sRGB-linearization/gamma functions
  (`toLinear`/`toGamma`, breakpoints `0.04045` and `0.0031308`) and the
  forward/inverse OKLab matrices with the exact coefficients given in
  `Color.swift`/`color.ts` (e.g. `0.4122214708`, `0.2104542553`,
  `0.3963377774`, …), reproduced identically on both platforms.
- **oklab-srgb-round-trip**: Converting sRGB to OKLab and back MUST return
  each channel within `1e-5` of the original value; this bound is a property
  of the published matrix constants being given to 10 decimal places, not of
  either implementation, and MUST NOT be tightened (`ColorTests.
  testRoundTripsSrgbThroughOklab`, `color.test.ts` "round-trips sRGB through
  OKLab"). `srgbToOklab` of pure white MUST have an `L` (first) channel
  within `1e-6` of `1`, and of pure black within `1e-9` of `0`.
- **mix-color-space**: `mix`/`mixColor` MUST interpolate in OKLab space, not
  componentwise sRGB: both endpoint hex strings are parsed, converted to
  OKLab, linearly interpolated per-channel by `t`, converted back to sRGB,
  and re-encoded as hex.
- **mix-endpoint-exactness**: `mix`/`mixColor` MUST return
  `toHex(parseHex(a))` unchanged when `t <= 0`, and `toHex(parseHex(b))`
  unchanged when `t >= 1`, without performing the OKLab round trip for those
  cases.
- **mix-error-propagation**: `mix`/`mixColor` MUST propagate a parse failure
  raised while parsing either endpoint color rather than catching or
  substituting a default color.

### Ease

- **ease-vocabulary-closed**: `Ease.resolve`/`resolveEase` MUST recognize
  exactly 24 named curves and no others: `none`; `power1.in`, `power1.out`,
  `power1.inOut`; `power2.in`, `power2.out`, `power2.inOut`; `power3`,
  `power3.in`, `power3.out`, `power3.inOut`; `power4.in`, `power4.out`,
  `power4.inOut`; `sine.in`, `sine.out`, `sine.inOut`; `back.out`,
  `back.out(1.5)`, `back.out(1.6)`, `back.out(1.7)`, `back.out(2)`,
  `back.out(2.4)`, `back.out(3)`. The vocabulary is a fixed table, not a
  parsed expression grammar.
- **ease-unknown-name-rejected**: `resolve`/`resolveEase` MUST throw a
  catchable error (Swift `Ease.Failure.unknown(name)`, web
  `Error("unknown ease: ${name}")`) for any name outside the 24, including
  near-misses of names that ARE in the table — a bare `power2` (only
  `power3` has a bare form) and `back.out(2.2)` (an overshoot value not among
  the six named ones) MUST both be rejected, not evaluated.
- **power-family-formula**: For family `powerN` (`N` in 1-4), `.in` MUST
  compute `t^(N+1)`, `.out` MUST compute `1 - (1-t)^(N+1)`, and `.inOut` MUST
  compute `t < 0.5 ? 2^N * t^(N+1) : 1 - 2^N * (1-t)^(N+1)`.
- **bare-power3-default**: The bare name `power3` MUST resolve to the same
  function as `power3.out`; no other bare `powerN` name exists in the
  vocabulary.
- **sine-family-formula**: `sine.in` MUST compute `1 - cos(t * pi / 2)`,
  `sine.out` MUST compute `sin(t * pi / 2)`, and `sine.inOut` MUST compute
  `-(cos(pi * t) - 1) / 2`.
- **back-out-formula**: `back.out(s)` MUST compute, with `p = t - 1`,
  `p * p * ((s + 1) * p + s) + 1`, using `s = 1.70158` for the bare
  `back.out` and each of the six listed values (`1.5`, `1.6`, `1.7`, `2`,
  `2.4`, `3`) for the corresponding named variant; `s` MUST NOT be accepted
  as an arbitrary runtime argument.
- **ease-endpoint-pinning**: Every resolvable ease function `e` MUST satisfy
  `e(0)` within `1e-12` of `0` and `e(1)` within `1e-12` of `1`
  (`EaseTests.testResolvesEveryNameInTheVocabularyAndPinsTheEndpoints`).
- **ease-table-built-once**: The name-to-function table MUST be constructed
  exactly once and reused for every `resolve` call (Swift: `static let
  table` built by an immediately-invoked closure; web: the module-level
  `TABLE` constant) rather than rebuilt per call.

### Mat

- **mat-identity-value**: `Mat.identity`/`IDENTITY` MUST equal the 2x3
  identity affine `a=1, b=0, c=0, d=1, e=0, f=0`, and multiplying any matrix
  by it on either side MUST return that matrix unchanged.
- **mat-multiply-order**: `*`/`multiply(m, n)` MUST compose with `m` as the
  parent (left operand) and `n` as the child (right operand), computing
  `a = m.a*n.a + m.c*n.b`, `b = m.b*n.a + m.d*n.b`, `c = m.a*n.c + m.c*n.d`,
  `d = m.b*n.c + m.d*n.d`, `e = m.a*n.e + m.c*n.f + m.e`,
  `f = m.b*n.e + m.d*n.f + m.f`.
- **mat-apply-point**: `apply(x:y:)`/`applyPoint` MUST transform a point as
  `(a*x + c*y + e, b*x + d*y + f)`.
- **mat-from-transform-defaults**: `Mat.from`/`fromTransform` MUST accept
  `x`, `y`, `rotation`, `scaleX`, `scaleY`, and `pivot`, defaulting absent
  values to `x=0, y=0, rotation=0, scaleX=1, scaleY=1, pivot=(0,0)`.
- **mat-pivot-composition**: `Mat.from`/`fromTransform` MUST compose the
  result as translate-by-`(x,y)` applied after a rotate-then-scale performed
  about the absolute pivot point — equivalently `T(x,y) . T(pivot) . R . S .
  T(-pivot)` — so that a point equal to the pivot is left fixed by the
  rotate/scale component and then translated by `(x,y)`.
- **mat-rotation-units**: The `rotation` parameter MUST be interpreted in
  degrees and converted to radians via `rotation * pi / 180` before use in
  `cos`/`sin`.
- **mat-double-precision**: `Mat`'s six components MUST be stored as 64-bit
  floating point (Swift `Double`, TypeScript `number`), never a 32-bit
  float type, because `CGAffineTransform`'s `CGFloat` storage is `Float` on
  some Apple architectures and would silently violate the shared `1e-6`
  golden-comparison tolerance the two platforms are held to.

### Prng

- **prng-seed-expansion**: `Prng(seed:)`/`createPrng(seed)` MUST derive the
  four 32-bit state words `s0`..`s3` by calling a `splitmix32` generator,
  seeded with the input, four times in sequence.
- **prng-zero-state-avoidance**: If all four derived state words are zero,
  the generator MUST force `s0` to `1` before the first `next()` call, since
  an all-zero xoshiro128** state is a fixed point.
- **prng-algorithm-fidelity**: `next()`/`next` MUST implement xoshiro128**
  exactly: `result = rotl(s1 * 5, 7) * 9`; then, in order,
  `t = s1 << 9; s2 ^= s0; s3 ^= s1; s1 ^= s2; s0 ^= s3; s2 ^= t; s3 =
  rotl(s3, 11)`; return `result`. Every arithmetic step MUST wrap at 32
  bits (Swift `&+`/`&*`; web `>>> 0` and `Math.imul`).
- **prng-cross-platform-determinism**: For an identical seed, `next()` MUST
  produce an identical sequence of 32-bit outputs on both platforms. Seed
  `1` MUST produce, as its first five outputs, exactly `1144403687,
  1290228702, 3651710282, 626043614, 3583050788`
  (`MathTests.testEmitsThePinnedReferenceStreamForSeedOne`,
  `prng.test.ts` "emits the pinned reference stream for seed 1").
- **prng-float-bounds**: `float()` MUST return `next() / 4294967296`, which
  is always in the half-open interval `[0, 1)`.
- **prng-range-formula**: `range(lo, hi)` MUST return `lo + float() * (hi -
  lo)`.
- **prng-signed-formula**: `signed(m)` MUST return `(float() * 2 - 1) * m`.
- **prng-chance-formula**: `chance(p)` MUST return `float() < p`.
- **prng-pick-or-nil-empty**: `pickOrNil`/`pickOrUndefined` MUST return
  `nil`/`undefined` for an empty array and MUST NOT consume a draw from the
  stream in that case — the next call to `next()` MUST return the same value
  a freshly-constructed generator with the same seed would return first
  (`MathTests.testPickOrNilAnswersNilForAnEmptyArrayAndDrawsNothing`).
- **prng-pick-or-nil-draw**: For a non-empty array, `pickOrNil`/
  `pickOrUndefined` MUST consume exactly one `float()` draw and index with
  `items[Int(float() * count)]` (Swift) / `items[Math.floor(float() *
  items.length)]` (web).
- **prng-pick-nonempty**: `pick`/`pick` MUST return an element of a
  non-empty array and MUST consume the identical stream position that
  `pickOrNil`/`pickOrUndefined` would for the same call
  (`MathTests.testPickOrNilConsumesTheSameStreamAsPick`).
- **prng-scheduled-draw-only**: A caller MUST draw from a given `Prng`
  instance only at scheduled animation events, never once per rendered
  frame/tick, so that the sequence of values consumed is independent of
  display refresh rate (documented invariant in both `Prng.swift` and
  `prng.ts`; the type does not enforce this itself — see
  **prng-concurrency**).

### Cross-cutting

- **no-side-effects**: `Color`, `Ease`, `Mat`, and `Prng` MUST be free of
  file, network, process, and notification side effects. `Color`, `Ease`,
  and `Mat` are pure functions of their arguments; `Prng`'s only mutable
  state is its own four-word generator state. None of the four files import
  anything beyond `Foundation` (Swift) or the local module itself
  (TypeScript).

