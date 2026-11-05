---
id: 471eb7b8-6821-4fd3-ab89-022c56757421
title: Avatar Engine Math
domain: adhsdk://recipes/avatar-engine-math
type: ingredient
version: 1.0.2
status: review
language: en
created: '2026-09-23'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Deterministic sRGB/OKLab color mixing, a closed GSAP-compatible ease vocabulary,
  2x3 affine matrices, and a seeded xoshiro128** PRNG shared verbatim by the Swift
  and TypeScript avatar animation engines.
platforms:
- swift
- macos
- ios
- typescript
- web
tags:
- math
- engine
- color
- animation
- deterministic
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Avatar Engine Math

## Overview

Avatar Engine Math is the numeric core shared by the Swift and TypeScript
avatar animation engines: four independent modules — `Color`, `Ease`, `Mat`,
and `Prng` — with no visual surface of their own. `Color` converts between
hex strings and OKLab for perceptual color mixing (`Color.swift`,
`color.ts`). `Ease` resolves a closed, GSAP-numerically-matching vocabulary of
24 named easing curves (`Ease.swift`, `ease.ts`). `Mat` composes 2x3 affine
transforms for the scene graph (`Mat.swift`, `mat.ts`). `Prng` is a seeded
xoshiro128** generator that both platforms must draw identically from
(`Prng.swift`, `prng.ts`). All four are pure, side-effect-free, and specified
down to the integer operation so that a Swift build and a TypeScript build
given the same inputs produce bit-for-bit (PRNG) or golden-tolerance (color,
easing, matrices) identical outputs.

## Behavioral Requirements

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

## Appearance

Not applicable — this is a math/logic module (color conversion, easing,
matrix, and PRNG functions), not a visual component.

## States

Not applicable — this is a math/logic module (color conversion, easing,
matrix, and PRNG functions), not a visual component.

## Accessibility

Not applicable — this is a math/logic module (color conversion, easing,
matrix, and PRNG functions), not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| avatar-engine-math-001 | hex-length-expansion, hex-serialization | `parseHex`/`toHex` round trip on `"#00ff41"`, `"#ff9500"`, `"#ffd400"`, `"#fffce0"`, `"#ff2d2d"`, `"#4f7cff"`, `"#5f7a64"`, `"#4f6e57"`, `"#33ccff"`, `"#06140d"` | Each hex parses and re-emits identically — `ColorTests.testParsesAndReEmitsEveryPaletteEntry`, `color.test.ts` "parses and re-emits every palette entry" |
| avatar-engine-math-002 | hex-charset-validation, hex-parse-failure | `parseHex("#\u{FF10}0ff41")` (fullwidth digit U+FF10) | Throws `Color.Failure.badHex`, does not trap — `ColorTests.testRejectsANonAsciiHexDigitInsteadOfCrashing` |
| avatar-engine-math-003 | nan-channel-clamped | `toHex((Double.nan, Double.nan, Double.nan))` and `toHex((Double.nan, 1, 0))` | `"#000000"` and `"#00ff00"` respectively — `ColorTests.testRendersANaNChannelAsBlackRatherThanCrashing`, `color.test.ts` "renders a NaN channel as black" |
| avatar-engine-math-004 | oklab-srgb-round-trip | `oklabToSrgb(srgbToOklab(parseHex(hex)))` for `"#00ff41"`, `"#ff2d2d"`, `"#4f7cff"`, `"#000000"`, `"#ffffff"` | Each channel within `1e-5` of the original — `ColorTests.testRoundTripsSrgbThroughOklab`, `color.test.ts` "round-trips sRGB through OKLab" |
| avatar-engine-math-005 | srgb-oklab-conversion | `srgbToOklab(parseHex("#ffffff"))` and `srgbToOklab(parseHex("#000000"))` | `L` channel within `1e-6` of `1` and within `1e-9` of `0` respectively — `ColorTests.testPinsOklabLForWhiteAndBlack` |
| avatar-engine-math-006 | mix-endpoint-exactness | `mix("#00ff41", "#ff2d2d", 0)` and `mix("#00ff41", "#ff2d2d", 1)` | `"#00ff41"` and `"#ff2d2d"` exactly — `ColorTests.testMixesEndpointsExactly` |
| avatar-engine-math-007 | mix-color-space | `mix("#00ff41", "#ff2d2d", 0.5)` | `"#cead37"` exactly — the pinned OKLab midpoint that catches a transposed matrix coefficient — `ColorTests.testAgreesWithTheWebOnTheMidpointHex`; saturation check `ColorTests.testKeepsGreenToRedSaturatedAtTheMidpoint` (chroma `> 0.55`, vs. `0.35` for a naive sRGB lerp) |
| avatar-engine-math-008 | ease-vocabulary-closed, ease-endpoint-pinning | `resolve(name)` for each of the 24 vocabulary names, sampled at `t=0` and `t=1` | Every name resolves; `e(0)` within `1e-12` of `0`, `e(1)` within `1e-12` of `1` — `EaseTests.testResolvesEveryNameInTheVocabularyAndPinsTheEndpoints` |
| avatar-engine-math-009 | power-family-formula, sine-family-formula, back-out-formula | `resolve(name)(t)` at `t = 0, 0.25, 0.5, 0.75, 1` for `"none"`, `"power1.in"`, `"power1.out"`, `"power1.inOut"`, `"power2.in"`, `"power2.out"`, `"power3.inOut"`, `"sine.in"`, `"sine.out"`, `"back.out"` | Matches the pinned sample table exactly within `1e-12`, e.g. `power1.in` → `[0, 0.0625, 0.25, 0.5625, 1]`, `back.out` → `[0, 0.8174096875, 1.0876975, 1.0641365625, 1]` — `EaseTests.testMatchesTheWebAtPinnedSamplePoints` |
| avatar-engine-math-010 | ease-unknown-name-rejected | `resolve("elastic.out")`, `resolve("back.in(2)")`, `resolve("power2")`, `resolve("back.out(2.2)")` | All four throw — `EaseTests.testRejectsAnythingOutsideTheVocabulary` |
| avatar-engine-math-011 | mat-identity-value | `Mat.identity * m` and `m * Mat.identity` for `m = Mat(a:2,b:0,c:0,d:3,e:10,f:20)` | Both equal `m` — `MatTests.testIdentityIsANoOp`, `mat.test.ts` "multiplies identity to a no-op" |
| avatar-engine-math-012 | mat-pivot-composition, mat-rotation-units | `Mat.from(rotation: 90, pivot: (200,200))`, applied to `(200,200)` and `(200,100)` | Pivot point maps to itself `(200,200)`; `(200,100)` maps to `(300,200)` — `MatTests.testRotatesAboutAnAbsolutePivotLeavingThePivotFixed`, `mat.test.ts` "rotates about an absolute pivot" |
| avatar-engine-math-013 | mat-pivot-composition | `Mat.from(scaleX:2, scaleY:2, pivot:(200,200))` | Matrix equals `Mat(a:2,b:0,c:0,d:2,e:-200,f:-200)`; applied to `(300,200)` gives `(400,200)` — `MatTests.testScalesAboutAnAbsolutePivot`, `mat.test.ts` "scales about an absolute pivot" |
| avatar-engine-math-014 | mat-from-transform-defaults, mat-pivot-composition | `Mat.from(x:5, y:7, rotation:180, scaleX:2, scaleY:2, pivot:(10,10))` applied to `(20,10)` | Result `(-5, 17)` — translate applied after the pivoted rotate/scale — `MatTests.testOrdersTranslateThenRotateThenScaleAboutThePivot`, `mat.test.ts` "orders translate, then rotate, then scale" |
| avatar-engine-math-015 | mat-multiply-order | `(Mat.from(x:100) * Mat.from(scaleX:2, scaleY:2, pivot:(0,0))).apply(x:3, y:4)` | Result `(106, 8)` — `MatTests.testComposesParentThenChild`, `mat.test.ts` "composes parent-then-child" |
| avatar-engine-math-016 | prng-cross-platform-determinism, prng-algorithm-fidelity | First five `next()` outputs of `Prng(seed: 1)` | Exactly `[1144403687, 1290228702, 3651710282, 626043614, 3583050788]` — `MathTests.testEmitsThePinnedReferenceStreamForSeedOne`, `prng.test.ts` "emits the pinned reference stream for seed 1" |
| avatar-engine-math-017 | prng-seed-expansion | `Prng(seed: 0x9e3779b9)` constructed twice, 1000 `next()` calls each | Both sequences identical at every step — `MathTests.testIsReproducibleFromASeed`, `prng.test.ts` "is reproducible from a seed" |
| avatar-engine-math-018 | prng-float-bounds | `float()` called 10,000 times on `Prng(seed: 42)` | Every value `>= 0` and `< 1` — `MathTests.testFloatsStayInTheUnitInterval`, `prng.test.ts` "floats stay in [0,1)" |
| avatar-engine-math-019 | prng-range-formula, prng-signed-formula | `signed(4)` averaged over 20,000 draws from `Prng(seed: 7)`; `range(2,5)` over 1,000 draws | Mean of `signed(4)` within `0.1` of `0`; every `range(2,5)` value in `[2, 5)` — `MathTests.testRangeAndSignedAreCentredCorrectly`, `prng.test.ts` "range and signed are centred correctly" |
| avatar-engine-math-020 | prng-pick-nonempty | `pick(["a","b","c"])` called 5,000 times on `Prng(seed: 3)` | Every result is one of `"a"`, `"b"`, `"c"` — `MathTests.testPickNeverIndexesOutOfBounds`, `prng.test.ts` "pick never indexes out of bounds" |
| avatar-engine-math-021 | prng-pick-or-nil-empty | `pickOrNil` on an empty `[Int]` array and an empty `[String]` array, both on `Prng(seed: 3)`, then `next()` | Both calls return `nil`; the following `next()` equals `Prng(seed: 3).next()` on a fresh instance — `MathTests.testPickOrNilAnswersNilForAnEmptyArrayAndDrawsNothing` |
| avatar-engine-math-022 | prng-pick-or-nil-draw, prng-pick-nonempty | 200 parallel calls to `pick(items)` on one `Prng(seed: 7)` and `pickOrNil(items)` on a second `Prng(seed: 7)`, `items = ["a","b","c","d","e"]` | Both sequences agree at every step — `MathTests.testPickOrNilConsumesTheSameStreamAsPick` |

## Edge Cases

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

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hex` (parseHex) | `String` / `string` | — (required) | A 3- or 6-digit hex color, with or without a leading `#`, with or without surrounding whitespace. No default; every call must supply one. |
| `t` (mix/mixColor) | `Double` / `number` | — (required) | Interpolation position between two colors. Values `<= 0` or `>= 1` snap to an endpoint (`mix-endpoint-exactness`); values inside `(0,1)` are used as given, unclamped. |
| `name` (Ease.resolve/resolveEase) | `String` / `string` | — (required) | One of the 24 closed vocabulary names. No default; no partial match. |
| `x`, `y` (Mat.from/fromTransform) | `Double` / `number` | `0` | Translation applied after the pivoted rotate/scale. |
| `rotation` (Mat.from/fromTransform) | `Double` / `number` | `0` | Degrees, converted internally to radians. |
| `scaleX`, `scaleY` (Mat.from/fromTransform) | `Double` / `number` | `1` | Scale factors applied about `pivot`. |
| `pivot` (Mat.from/fromTransform) | `(Double, Double)` / `readonly [number, number]` | `(0, 0)` | Absolute design-space point that rotation and scale are performed about. |
| `seed` (Prng init/createPrng) | `UInt32` / `number` | — (required) | Seed expanded via `splitmix32` into the four-word xoshiro128** state. No default; callers that want reproducibility supply a fixed seed. |
| `lo`, `hi` (Prng.range) | `Double` / `number` | — (required) | Inclusive lower / exclusive upper bound; no validation that `lo <= hi`. |
| `m` (Prng.signed) | `Double` / `number` | — (required) | Symmetric magnitude; result is drawn from `[-m, m)`. |
| `p` (Prng.chance) | `Double` / `number` | — (required) | Probability threshold compared against `float()`; not clamped to `[0,1]` by the source. |
| `items` (Prng.pick/pickOrNil/pickOrUndefined) | `[T]` / `readonly T[]` | — (required) | Candidate list; emptiness is a caller/config contract violation for `pick`, and the defined empty case for `pickOrNil`/`pickOrUndefined`. |

There are no environment variables, settings keys, or injected dependencies
anywhere in these four files — all configuration is passed as explicit
function/initializer arguments.

## Deep Linking

Not applicable: `Color`, `Ease`, `Mat`, and `Prng` expose no URLs, routes, or
navigable destinations — they are pure computation with no addressable
surface.

## Localization

Not applicable: the only user-facing strings the source produces are the
`CustomStringConvertible`/`Error` diagnostic messages (`"bad hex colour:
\(h)"`, `"unknown ease: \(name)"`) used for developer-facing error
descriptions, not localized UI text; nothing in `Color.swift`, `Ease.swift`,
`Mat.swift`, `Prng.swift`, `color.ts`, `ease.ts`, `mat.ts`, or `prng.ts`
loads a string table or locale.

## Accessibility Options

Not applicable: these are non-visual math functions with no rendering
surface, so Reduce Motion, Increase Contrast, and Differentiate Without
Color have no behavior to define here — an animation host consuming
`Ease`'s curves would apply Reduce Motion, but that decision belongs to the
host, not to this module (no such branch exists in these four files).

## Feature Flags

Not applicable: none of `Color.swift`, `Ease.swift`, `Mat.swift`,
`Prng.swift`, `color.ts`, `ease.ts`, `mat.ts`, or `prng.ts` reads a feature
flag or configuration toggle.

## Analytics

Not applicable: none of the four modules emits an analytics event; they are
called synchronously by other engine code and return a value or throw.

## Privacy

- **Data collected**: None. The four modules operate only on caller-supplied
  hex strings, ease names, transform numbers, and PRNG seeds/arrays — no
  user identity, credential, or device data is read.
- **Storage**: Not applicable — no persistence of any kind occurs in these
  files; a `Prng` instance's state lives only in process memory for its
  lifetime.
- **Transmission**: Not applicable — no network calls exist in this module.
- **Retention**: Not applicable — nothing is retained beyond the calling
  function's or object's lifetime.

## Logging

Not applicable: none of `Color.swift`, `Ease.swift`, `Mat.swift`,
`Prng.swift`, `color.ts`, `ease.ts`, `mat.ts`, or `prng.ts` contains a log or
print call. Failures are communicated exclusively through thrown Swift
errors or rejected TypeScript `Error`s (`hex-parse-failure`,
`ease-unknown-name-rejected`), never written to a log.

## Platform Notes

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

## Design Decisions

- **Decision**: Interpolate color mixing in OKLab space rather than
  componentwise sRGB.
  **Rationale**: An sRGB lerp between two fully saturated colors dips
  through grey at the midpoint (chroma `~0.35` for `#00ff41`/`#ff2d2d`); the
  OKLab midpoint stays saturated (chroma `> 0.55`, pinned exactly to
  `#cead37`). Both endpoints are identical in either color space, so only
  the interpolated interior differs — traced to the doc comments in
  `Color.swift`/`color.ts` and `ColorTests.testAgreesWithTheWebOnTheMidpointHex`.
  **Approved**: pending
- **Decision**: Clamp a `NaN` color channel to `0` instead of propagating it
  or crashing.
  **Rationale**: A naive min/max clamp lets `NaN` through (every comparison
  against `NaN` is `false`). On Swift this reaches `Int(Double.nan.
  rounded())`, which traps the process on the per-frame render path; on the
  web it reaches `Math.round(NaN).toString(16)`, which silently emits the
  string `"#NaNNaNNaN"`. Clamping to `0` makes both platforms answer black
  for the same malformed input instead of one crashing and one lying —
  traced to `clamp01`'s doc comment in both `Color.swift` and `color.ts`.
  **Approved**: pending
- **Decision**: Validate hex-digit characters with an explicit ASCII-only
  predicate on Swift instead of `Character.isHexDigit`.
  **Rationale**: `Character.isHexDigit` follows Unicode's `Hex_Digit`
  property, which is also true for fullwidth digit/letter code points
  (U+FF10-FF19, U+FF21-FF26, U+FF41-FF46) that the web's ASCII-only regex
  `/[^0-9a-fA-F]/` rejects. Using the Unicode-aware test would let a string
  the web rejects pass Swift's guard and then fail the subsequent
  `UInt8(_:radix:)` parse in a way not covered by the explicit `badHex`
  error path — traced to `isAsciiHexDigit`'s doc comment in `Color.swift`.
  **Approved**: pending
- **Decision**: `Mat` stores its six components as `Double`, never
  `CGAffineTransform`.
  **Rationale**: `CGAffineTransform`'s `CGFloat` storage is 32-bit `Float`
  on some Apple architectures, which would quietly violate the `1e-6`
  golden-comparison tolerance shared with the TypeScript implementation —
  traced to `Mat.swift`'s top-of-file doc comment.
  **Approved**: pending
- **Decision**: `Prng.pick`/`pick` on an empty array fails differently on
  the two platforms — Swift traps the process via `preconditionFailure`;
  the web throws a catchable `Error`.
  **Rationale**: Both source comments treat an empty candidate list as a
  configuration fault that `CharacterConfig.load`/`loadConfig` should have
  already rejected — reaching `pick` with an empty array means that upstream
  contract was already broken, so each platform names the responsible
  validator rather than failing anonymously. The severity differs because
  Swift's `preconditionFailure` cannot be caught by XCTest or a caller,
  while the web's `throw` can be — an intentional, documented asymmetry
  rather than a bug, but a genuine platform divergence a port must be aware
  of (see **prng-concurrency**, which this same trade-off touches).
  **Approved**: pending
- **Decision**: A caller MUST draw from a `Prng` instance only at scheduled
  events, never once per rendered frame.
  **Rationale**: A 120 Hz display would otherwise consume roughly twice as
  many random values per second of wall-clock time as a 60 Hz display for
  the same animation, breaking the determinism the pinned seed-1 stream
  test depends on — traced to the top-of-file doc comments in both
  `Prng.swift` and `prng.ts`.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [if-behavioral-requirements](agenticdevelopercookbook://compliance/artifact-formatting/ingredient-formatting#if-behavioral-requirements) | passed | Artifact Formatting |
| [if-test-vectors](agenticdevelopercookbook://compliance/artifact-formatting/ingredient-formatting#if-test-vectors) | passed | Artifact Formatting |
| [if-platform-notes](agenticdevelopercookbook://compliance/artifact-formatting/ingredient-formatting#if-platform-notes) | passed | Artifact Formatting |
| [if-design-decisions](agenticdevelopercookbook://compliance/artifact-formatting/ingredient-formatting#if-design-decisions) | passed | Artifact Formatting |
| [if-change-history](agenticdevelopercookbook://compliance/artifact-formatting/ingredient-formatting#if-change-history) | passed | Artifact Formatting |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |

`explicit-error-handling` is `partial`: `parseHex`/`resolve`/`mix` all raise
catchable errors, but `Prng.pick` on Swift fails via an uncatchable
`preconditionFailure` rather than a catchable error for the same misuse the
web's `pick` throws for — see Design Decisions and the concurrency/ordering
open question in Edge Cases.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.0.2 | 2026-09-25 | Mike Fullerton | hex-input-normalization split into platform-specific rules (Swift vs web trim/strip differ) with a new Edge Case for divergent acceptance; fixed a malformed code-span split in vector 021. |
