---
id: 81f8c0bd-ce00-43b3-816e-b63e96baeacc
title: "Avatar Engine Path"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-09-23
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Shared SVG path grammar, primitive shape builders, anchor-for-anchor morph, and polyline-to-cubic promotion the avatar engine's Apple and web code both draw from."
platforms:
  - swift
  - macos
  - ios
  - typescript
  - web
tags:
  - avatar-engine
  - path
  - svg
  - morphing
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Avatar Engine Path

## Overview

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

## Behavioral Requirements

**Data shape**

- **parsed-path-shape**: A `ParsedPath` MUST consist of a `kind` string (the
  concatenation of its command letters, e.g. `"MLL"`, `"MCCCCZ"`) and a
  `points` array of `Double`/`number` values whose total length equals the sum
  of each command's arity in `kind` (`M` = 2, `L` = 2, `C` = 6, `Z` = 0).

**Grammar — `parsePath`**

- **supported-commands**: `parsePath` MUST accept only the uppercase absolute
  commands `M`, `L`, `C`, and `Z`, and MUST reject every other letter,
  including the lowercase relative forms (`m`, `l`, `c`, `z`) and commands
  outside this subset (e.g. `A`, `Q`).
- **number-token-grammar**: `parsePath` MUST recognize a numeric token as an
  optional leading `-`, then either one or more ASCII digits optionally
  followed by a `.` and one or more ASCII digits, or a `.` followed by one or
  more ASCII digits, optionally followed by an exponent (`e` or `E`, an
  optional `-`, then one or more ASCII digits); non-ASCII digit characters
  MUST NOT be recognized.
- **decimal-point-restarts-number**: `parsePath` MUST treat a `.` that follows
  an already-completed number as the start of a new number rather than an
  extension of the first, so that `"1.2.3"` parses as the two numbers `1.2`
  and `0.3`.
- **dangling-punctuation-not-consumed**: `parsePath` MUST NOT consume a `.`
  with no following digit, an `e`/`E` with no following digit, or a trailing
  `-` that leads nothing, as part of a number.
- **separator-set**: `parsePath` MUST treat only space, comma, tab, carriage
  return, and line feed as separators between tokens; every other character
  (including vertical tab) MUST NOT be treated as a separator.
- **no-character-silently-skipped**: `parsePath` MUST fail with an
  "unsupported path syntax" error whenever a character between two recognized
  tokens is not one of the separator characters, rather than discarding it and
  continuing.
- **arity-enforced**: `parsePath` MUST require exactly the number of numeric
  arguments a pending command's arity specifies (2 for `M`/`L`, 6 for `C`, 0
  for `Z`) before it accepts the next command letter.
- **truncated-command-rejected**: `parsePath` MUST fail with a "truncated"
  error when a new command letter appears, or the input ends, while a
  pending command still needs arguments. Web's message names the pending
  command letter (`` `truncated ${pending} in path: ${d}` ``); Apple's
  message uses the literal word `command` and does not name which one
  (`"truncated command in path: \(s)"`) — the message text differs between
  platforms (see Design Decisions).
- **stray-number-rejected**: `parsePath` MUST fail with a "stray number" error
  when a numeric token appears with no command pending to receive it.
- **empty-input-parses-empty**: `parsePath` given an empty string MUST return
  a `ParsedPath` with `kind` `""` and `points` `[]` rather than throwing.
- **round-trip**: For any `ParsedPath` `p` whose `points` are already
  quantized to the 1/1,000,000 grid `fmt` rounds to (see
  fmt-rounds-half-away-from-zero), `parsePath(emitPath(p))` MUST yield
  `points` equal to `p.points`. For an off-grid `p` (a coordinate not
  already a multiple of 1e-6, such as a value with more than six decimal
  digits), `emitPath` quantizes every coordinate through `fmt`, so
  `parsePath(emitPath(p))`'s `points` MUST instead equal `p.points` rounded
  coordinate-by-coordinate the same way (round-half-away-from-zero to
  1/1,000,000) — not `p.points` itself.

**Number formatting — `fmt` / `emitPath`**

- **fmt-rounds-half-away-from-zero**: `fmt` MUST round its input to the
  nearest 1/1,000,000 using round-half-away-from-zero, so a negative value
  exactly halfway between two representable steps (e.g. `-1.5e-6`,
  `-187.0000005`) rounds away from zero (`"-0.000002"`, `"-187.000001"`)
  rather than toward positive infinity.
- **fmt-zero-has-no-sign**: `fmt` MUST render any value that rounds to zero,
  including negative zero, as `"0"`, never `"-0"`.
- **fmt-integers-have-no-decimal**: `fmt` MUST render a value that rounds to a
  whole number without a decimal point or trailing zeros (`"13"`, not
  `"13.0"`).
- **fmt-never-emits-exponent**: `fmt` MUST NOT produce exponential notation
  for any input magnitude, including values at or beyond `1e21`.
- **emit-path-format**: `emitPath` MUST render each command as its letter
  immediately followed by its arguments (each formatted through `fmt`) joined
  by commas, and MUST concatenate successive commands with no separator
  between them.

**Primitive builders — `Build` / `build`**

- **quarter-circle-constant**: The cubic circle approximation MUST use the
  constant `0.5523` as the control-point scalar for a quarter circle, not a
  higher-precision value.
- **cubic-o-shape**: `cubicO(cx, cy, rx, ry)` MUST return a single closed path
  of kind `"MCCCCZ"` starting at `(cx, cy − ry)`, with each control point
  offset from its anchor by `rx * 0.5523` or `ry * 0.5523`.
- **disc-is-cubic-o**: `disc(cx, cy, r)` MUST return the same path as
  `cubicO(cx, cy, r, r)`.
- **ring-is-outer-then-reversed-inner**: `ring(cx, cy, r, band)` MUST return
  the outer circle of radius `r` followed by the inner circle of radius
  `r − band` drawn with reversed winding (via a negated `rx`), producing a
  path of kind `"MCCCCZMCCCCZ"`.
- **ring-parameterized-by-band**: `ring` MUST take the outer radius and the
  band (stroke) width as its two radius parameters, not an outer and an inner
  radius.
- **arc-emits-only-cubics**: `arc(cx, cy, r, from, to)` MUST express the arc
  from `from` to `to` degrees, in screen-space with `y` increasing downward,
  as a single `M` followed by one or more `C` commands, and MUST NOT emit an
  `A` command.
- **arc-segment-count**: `arc` MUST use
  `max(1, ceil(|to − from in radians| / (π/2)))` cubic segments, so that no
  single segment spans more than a quarter circle.
- **polyline-minimum-points**: `polyline` MUST throw an error when given
  fewer than 2 points, and otherwise MUST emit `M` to the first point followed
  by one `L` per remaining point.
- **bezier-point-count**: `bezier` MUST throw an error when given fewer than 4
  points, or a point count that is not `3n + 1`, and otherwise MUST emit `M`
  to the first point followed by one `C` per group of 3 subsequent points.

**Morphing — `morphPath`**

- **morph-requires-matching-kind**: `morphPath(a, b, t)` MUST throw a
  shape-mismatch error naming both `a.kind` and `b.kind` when they differ, and
  MUST NOT interpolate paths whose `kind` values are unequal.
- **morph-exact-endpoints**: `morphPath(a, b, t)` MUST return `a` unchanged
  when `t` is exactly `0` and `b` unchanged when `t` is exactly `1`, rather
  than a computed lerp.
- **morph-unclamped-lerp**: For any other `t`, `morphPath` MUST compute each
  output point as `a.points[i] + (b.points[i] − a.points[i]) * t` and MUST NOT
  clamp `t` to `[0, 1]`, so a `t` below `0` or above `1` extrapolates past the
  corresponding endpoint.

**Promotion — `promotePolyline`**

- **promote-requires-open-polyline**: `promotePolyline(p, segments)` MUST
  throw an error naming `p.kind` when `p.kind` is not an `M` followed by one
  or more `L` commands (i.e., is not an open polyline).
- **promote-requires-whole-multiple**: `promotePolyline(p, segments)` MUST
  throw an error naming both the polyline's line count and `segments` when
  `segments` is less than that line count or is not an exact multiple of it.
- **promote-preserves-anchors**: `promotePolyline` MUST re-express each
  original line as `segments / lines` cubic sub-segments computed from that
  line's own endpoints (not by walking cumulative output), such that every
  anchor of the input polyline reappears unchanged as an anchor of the output,
  and the result MUST remain open (no `Z`).
- **promote-straight-cubic**: Each cubic sub-segment `promotePolyline` emits
  MUST place its control points at exactly 1/3 and 2/3 of the way along that
  sub-segment's own chord.

**Purity and side effects**

- **no-side-effects**: `parsePath`, `emitPath`, `fmt`, every `Build`/`build`
  function, `morphPath`, and `promotePolyline` MUST be pure computations over
  their arguments — none performs file, network, process, or notification
  side effects, and none reads or mutates state outside its own parameters and
  return value.

## Appearance

Not applicable — this is a path-data computation library (parsing, building,
morphing, and re-expressing SVG path strings), not a visual component; nothing
in `Build.swift`, `Morph.swift`, `ParsedPath.swift`, `build.ts`, `morph.ts`,
`parse.ts`, or `promote.ts` renders a view, layer, or DOM element.

## States

Not applicable — this is a stateless computation library, not a visual
component; every function is a pure function of its arguments with no
persisted state or state machine of its own (the same source files as
Appearance).

## Accessibility

Not applicable — this is a non-visual computation library, not a visual
component; it exposes no control, role, label, or focus target for assistive
technology to reach (the same source files as Appearance).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| path-001 | supported-commands, decimal-point-restarts-number | `parsePath("M1.2.3")` | `kind = "M"`, `points = [1.2, 0.3]` — `PathTests.swift`'s `testASecondDecimalPointStartsAFreshNumber`, `parse.test.ts`'s "agrees with Swift on the whole grammar" |
| path-002 | supported-commands, separator-set | `parsePath("M187,233 L200,246 L213,233")` | `kind = "MLL"`, `points = [187, 233, 200, 246, 213, 233]` — `PathTests.swift`'s `testReadsAThreePointMouthPolyline`, `parse.test.ts`'s "reads a 3-point mouth polyline" |
| path-003 | arity-enforced | `parsePath` on the closed 4-anchor cubic-O string (`"M200,224C204.97,224…Z"`) | `kind = "MCCCCZ"`, `points.count == 2 + 4 * 6` — `PathTests.swift`'s `testReadsAClosedFourAnchorCubicO`, `parse.test.ts`'s "reads a closed 4-anchor cubic O" |
| path-004 | no-character-silently-skipped | `parsePath("m0,0 l1,1")` and `parsePath("M0,0 A45,45 0 0 1 10,10")` | Both throw an "unsupported path syntax" error — `PathTests.swift`'s `testRejectsCommandsOutsideTheSubset`, `parse.test.ts`'s "rejects commands outside the subset" |
| path-005 | separator-set | `parsePath("M0,0\u{000B}L1,1")` (vertical tab) | Throws — `parse.test.ts`'s "agrees with Swift on the whole grammar" (rejected list) |
| path-006 | truncated-command-rejected | `parsePath("M0,0 C1,1")` | Throws a "truncated" error — `parse.test.ts`'s "agrees with Swift on the whole grammar" (rejected list) |
| path-007 | stray-number-rejected | `parsePath("0,0")` | Throws a "stray number" error — `parse.test.ts`'s "agrees with Swift on the whole grammar" (rejected list) |
| path-008 | round-trip | `parsePath(emitPath(parsePath("M183,169 C180,148 175,126 179,105"))).points` | Equals `parsePath("M183,169 C180,148 175,126 179,105").points` — `PathTests.swift`'s `testRoundTrips`, `parse.test.ts`'s "round-trips" |
| path-009 | fmt-rounds-half-away-from-zero | `fmt(-1.5e-6)`, `fmt(-187.0000005)` | `"-0.000002"`, `"-187.000001"` — `PathTests.swift`'s `testRoundsNegativeHalfStepsAwayFromZero`, `parse.test.ts`'s "rounds negative half-steps the way Swift does" |
| path-010 | fmt-zero-has-no-sign | `fmt(-0.0000004)` and `fmt(-0)` | Both `"0"` — same tests as path-009 |
| path-011 | emit-path-format, fmt-rounds-half-away-from-zero | `emitPath({kind: "ML", points: [-0.0000005, 0, 1, -1.5e-6]})` | `"M-0.000001,0L1,-0.000002"` — `PathTests.swift`'s `testEmitsANegativeCoordinateTheSameWayTheWebDoes`, `parse.test.ts`'s "emits a negative coordinate the same way Swift does" |
| path-012 | cubic-o-shape, disc-is-cubic-o | `Build.disc(cx: 152, cy: 200, r: 9)` | Exact string `"M152,191C156.9707,191 161,195.0293 161,200C161,204.9707 156.9707,209 152,209C147.0293,209 143,204.9707 143,200C143,195.0293 147.0293,191 152,191Z"` — `PathTests.swift`'s `testMatchesTheWebsTextByteForByte` |
| path-013 | ring-is-outer-then-reversed-inner | `parsePath(Build.ring(cx: 152, cy: 200, r: 35, band: 8)).kind` | `"MCCCCZMCCCCZ"` — `PathTests.swift`'s `testBuildsARingAsTwoConcentricCirclesOuterThenInnerReversed`, `build.test.ts`'s "builds a ring as two concentric circles" |
| path-014 | arc-emits-only-cubics, arc-segment-count | `parsePath(Build.arc(cx: 152, cy: 200, r: 45, from: 233.1301, to: 306.8699))` | Kind starts with `M` then only `C`s; first point within `1e-3` of `(125, 164)`, last point within `1e-3` of `(179, 164)` — `PathTests.swift`'s `testEmitsAnArcAsCubicsWithNoACommand` / `testPlacesTheBrowEndpointsAtCxPlusMinus27AtY164`, `build.test.ts`'s "places the brow endpoints at cx +/- 27, y 164" |
| path-015 | polyline-minimum-points | `Build.polyline([[187, 233]])` (1 point) | Throws with message `"polyline needs at least 2 points"` — traced to `Build.swift`'s `PathError.badPointCount` guard and the identical `build.ts` throw text |
| path-016 | bezier-point-count | `Build.bezier([[0, 0], [1, 1], [2, 2]])` (3 points) | Throws with message `"bezier needs 3n+1 points, got 3"` — traced to `Build.swift`'s `PathError.badPointCount` guard and the identical `build.ts` throw text |
| path-017 | morph-unclamped-lerp | `morphPath(a="M187,233 L200,246 L213,233", b="M189,235 L200,235 L211,235", t=0.5)` | `kind = "MLL"`, `points = [188, 234, 200, 240.5, 212, 234]` — `PathTests.swift`'s `testInterpolatesTwoSameKindMouths`, `morph.test.ts`'s "interpolates two same-kind mouths" |
| path-018 | morph-exact-endpoints | `morphPath(a, b, 0)` and `morphPath(a, b, 1)` (same `a`/`b` as path-017) | `emitPath` output equals `emitPath(a)` and `emitPath(b)` respectively — `PathTests.swift`'s `testReturnsTheEndpointsExactly`, `morph.test.ts`'s "returns the endpoints exactly" |
| path-019 | morph-unclamped-lerp | `morphPath(a="M187,233 L200,246 L213,233", b="M195,230 L200,235 L205,230", t=1.1)` then `t=-0.1` | `points[3]` ≈ `233.9` then ≈ `247.1` (within `1e-9`) — `PathTests.swift`'s `testExtrapolatesPastTheTargetWhenTheEaseOvershoots`, `morph.test.ts`'s "extrapolates past the target when the ease overshoots" |
| path-020 | morph-requires-matching-kind | `morphPath` of an `"MLL"` polyline against an `"MCCCCZ"` cubic-O, `t=0.5` | Throws an error whose message contains both `"MLL"` and `"MCCCCZ"` — `PathTests.swift`'s `testRefusesToMorphAcrossShapeFamilies`, `morph.test.ts`'s "refuses to morph across shape families" |
| path-021 | promote-preserves-anchors, promote-straight-cubic | `promotePolyline(parsePath("M0,0L9,9"), 1)`, then emitted | `"M0,0C3,3,6,6,9,9"` — `promote.test.ts`'s "rewrites one line as the cubic that draws it" |
| path-022 | promote-preserves-anchors | `promotePolyline(parsePath("M0,0L12,0"), 3)`, then emitted | `"M0,0C1.333333,0,2.666667,0,4,0C5.333333,0,6.666667,0,8,0C9.333333,0,10.666667,0,12,0"` — `promote.test.ts`'s "splits a line into equal segments" |
| path-023 | promote-preserves-anchors | `promotePolyline(parsePath("M10,20L30,40L50,20"), 4)` | Anchors (every 3rd point pair) equal `[[10,20],[20,30],[30,40],[40,30],[50,20]]` — `promote.test.ts`'s "draws the same ink: every original anchor survives as an anchor" |
| path-024 | promote-requires-open-polyline | `promotePolyline(parsePath("M0,0C1,1,2,2,3,3"), 2)` and `promotePolyline(parsePath("M0,0L9,9Z"), 2)` | Both throw an error matching `/open polyline/` — `promote.test.ts`'s "refuses anything but an open polyline" |
| path-025 | promote-requires-whole-multiple | `promotePolyline(parsePath("M0,0L5,5L10,0"), 3)` and the same path with `segments=1` | Both throw an error matching `/whole multiple/` — `promote.test.ts`'s "refuses a segment count that is not a whole multiple" |

## Edge Cases

- **Empty path string.** `parsePath("")` MUST return `ParsedPath(kind: "", points: [])` rather than throwing — the loop over an empty character array never executes and the "all arities satisfied" guard trivially passes.
- **Empty coordinate list.** `Build.polyline([])` and `Build.bezier([])` MUST throw the same "at least 2 points" / "3n+1 points, got 0" errors as any other under-count input (edge case of `polyline-minimum-points` / `bezier-point-count`, not a separate code path).
- **Boundary: `segments == lines` in `promotePolyline`.** The minimum accepted `segments` (one cubic per original line, `per = 1`) MUST succeed, not be treated as a no-op or a rejection — exercised directly by `promote.test.ts`'s "rewrites one line as the cubic that draws it" (`lines = 1`, `segments = 1`).
- **Boundary: `t == 0` / `t == 1` in `morphPath`.** These MUST return the input endpoint exactly (see `morph-exact-endpoints`) rather than the arithmetically equivalent lerp, because `v + (b - v) * 1` is not always bit-identical to `b` in floating point.
- **Boundary: zero-length arc.** `arc(cx, cy, r, from, to)` with `from == to` MUST still emit a valid single-segment path (`segments = max(1, ceil(0 / (π/2))) = 1`) rather than an empty string or a division-related failure.
- **Malformed input the tokenizer must not silently skip.** A dangling sign (`"M0,0-"`), a dangling exponent marker (`"M0,0e"`), a lone `.` (`"M5.,3"`, `"M5..3"`), and a mid-path SVG command outside the four-letter subset (`"M0,0 Q1,1"`) MUST all be rejected (SHOULD-equivalent leniency is explicitly ruled out by `no-character-silently-skipped`) rather than silently dropped, matching both platforms' tests for the same corpus.
- **Concurrent access.** Not applicable — every function in this layer is a pure, synchronous computation over its own arguments with no shared mutable state; `ParsedPath` is declared `Sendable` in `ParsedPath.swift`, and neither the Swift nor the TypeScript sources use a lock, an actor, `async`/`await`, or any I/O that could race. There is no ordering or serialization rule to define.
- **Error states (external dependencies).** Not applicable — this layer has no network, database, or file-system dependency to fail; every error this layer raises is an input-validation failure on the caller-supplied path string or point list, already covered by the "malformed input" and grammar requirements above.
- **Offline / disconnected state.** Not applicable — this layer performs no network operation, so connectivity loss cannot occur within it; none of `Build.swift`, `Morph.swift`, `ParsedPath.swift`, `build.ts`, `morph.ts`, `parse.ts`, or `promote.ts` imports a networking API.
- **ring-band-bound**: NEEDS REVIEW: Not implemented in source. `ring(cx, cy, r, band)` does not validate `0 < band <= r`. When `band > r`, `inner = r - band` is negative, so the inner `cubicO` call receives `rx = -inner` (positive) and `ry = inner` (negative) — a sign-mismatched radius pair the function's own "negative `rx` reverses winding" design does not anticipate (only `rx` is meant to flip). Neither `Build.swift`'s `ring` nor `build.ts`'s `ring` guards this, and no test in `BuildTests`/`build.test.ts` exercises `band > r`. Evidence that would settle it: confirming with whoever owns the rig/config schema whether `band <= r` is already enforced upstream (e.g. JSON-schema validation in `avatar-engine/src/config`) — if so, this layer's lack of a guard is intentional and this note can be dropped.
- **parse-path-leading-command**: NEEDS REVIEW: Not implemented in source. `parsePath` does not require the first command to be `M`. A string like `"L1,1"` or `"Z"` alone parses successfully (kind `"L"` or `"Z"`, no error), even though every accepted-corpus example in both `PathTests.swift` and `parse.test.ts` begins with `M` and every `Build`/`build` function always emits one first. Evidence that would settle it: confirming whether any caller ever feeds `parsePath` a fragment that is not expected to start with `M` — if not, a port should decide once whether to add a leading-`M` check rather than silently accepting a path no renderer can usefully draw.
- **parsed-path-arity-invariant**: NEEDS REVIEW: Not implemented in source. `ParsedPath.init(kind:points:)` (Swift) and the equivalent object-literal construction of the `ParsedPath` interface (TypeScript) do not validate that `points.count` equals the sum of each `kind` letter's arity. A caller who constructs a `ParsedPath` directly, bypassing `parsePath`, can hand `emitPath` a mismatched pair; `emitPath` will then either trap (Swift array slice out of range) on too few points or silently drop trailing values on too many. Neither `ParsedPath.swift` nor `parse.ts` guards this at construction. Evidence that would settle it: confirming with the engine team whether every call site that builds a `ParsedPath` directly (outside `parsePath`) is already trusted by convention — if so, a port need not add a check; if not, this is the one place a malformed `.shape` channel value could reach `emitPath` unchecked.

## Configuration

This layer takes no defaults, environment variables, settings keys, or
injected dependencies — every operation is an explicit function call with
explicit arguments. The table below lists the parameters each public
operation's caller supplies.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `d` (`parsePath`) | `String` / `string` | none — required | Path-data string to parse into a `ParsedPath`. |
| `p` (`emitPath`, `promotePolyline`) | `ParsedPath` | none — required | The parsed path to serialize or re-express. |
| `v` (`fmt`) | `Double` / `number` | none — required | The coordinate value to format for path-data output. |
| `cx, cy, rx, ry` (`cubicO`) / `cx, cy, r` (`disc`) | `Double` / `number` | none — required | Center and radii of the ellipse or circle to draw. |
| `cx, cy, r, band` (`ring`) | `Double` / `number` | none — required | Center, outer radius, and band (stroke) width of the annulus. |
| `cx, cy, r, from, to` (`arc`) | `Double` / `number` | none — required | Center, radius, and start/end angle in degrees (screen-space, `y` down). |
| `points` (`polyline`, `bezier`) | `[[Double]]` / `readonly (readonly [number, number])[]` | none — required | Ordered `[x, y]` pairs the shape is built from. |
| `a, b, t` (`morphPath`) | `ParsedPath`, `ParsedPath`, `Double` / `number` | none — required | The two paths to interpolate and the (unclamped) interpolation factor. |
| `segments` (`promotePolyline`) | `Int` / `number` | none — required | The target cubic-segment count; MUST be a whole multiple of the polyline's line count. |

## Deep Linking

Not applicable: this is a pure computation library with no URL scheme, route,
or navigable surface — nothing in `Build.swift`, `Morph.swift`,
`ParsedPath.swift`, `build.ts`, `morph.ts`, `parse.ts`, or `promote.ts` is
deep-linkable.

## Localization

Not applicable: the error strings this layer throws (`PathError.description`
in `ParsedPath.swift`; the `Error` messages in `parse.ts`/`build.ts`/
`morph.ts`/`promote.ts`) are internal diagnostic text read by callers and
tests, not user-facing UI copy, and none of the given sources contains a
localization or string-table mechanism.

## Accessibility Options

Not applicable: this is a non-visual computation library — it responds to no
Reduce Motion, Increase Contrast, or Differentiate Without Color setting,
because it renders nothing (same reasoning as Appearance/States/Accessibility
above).

## Feature Flags

Not applicable: none of the given sources contains a feature-flag check or
config gate; every function in this layer unconditionally executes its
algorithm on its arguments.

## Analytics

Not applicable: none of the given sources contains an analytics or
event-emission call.

## Privacy

Not applicable: no credential, token, or user-identifying data flows through
this layer — its inputs are path-data strings and numeric geometry (rig shape
coordinates), and its outputs are path-data strings; nothing here is stored,
transmitted, or retained.

## Logging

Not applicable: none of `Build.swift`, `Morph.swift`, `ParsedPath.swift`,
`build.ts`, `morph.ts`, `parse.ts`, or `promote.ts` contains a logging call
(no `print`, `os_log`, `Logger`, or `console.*` usage).

## Platform Notes

- **SwiftUI**: Not the source platform, but a natural additional consumer: a
  `Shape`/`Path` can be built directly from `emitPath`'s output by walking the
  same `M`/`L`/`C`/`Z` token stream into `CGMutablePath.move(to:)`/
  `addLine(to:)`/`addCurve(to:control1:control2:)` calls, and a morph can be
  driven either by feeding `morphPath`'s per-frame output into a fresh `Path`
  or by exposing the flat `points` array as a `Shape`'s `animatableData`.
- **AppKit / UIKit — this recipe's actual Swift consumer**: `Build.swift`,
  `Morph.swift`, and `ParsedPath.swift`
  (`packages/apple/AvatarAnimationEngine/Sources/Path/`) are Foundation-only
  and framework-agnostic; the engine's own render layer
  (`Sources/Render/AvatarLayerView.swift`, `PlatformShims.swift`) is what turns
  their `String` path-data output into `CGPath`/`CAShapeLayer` content on
  screen, via the same token-walking step SwiftUI would use.
- **React/Web — the other source platform**: `build.ts`, `morph.ts`,
  `parse.ts`, and `promote.ts`
  (`packages/web/packages/avatar-engine/src/path/`) already produce an SVG `d`
  attribute string directly; a React consumer binds it to
  `svg path` `d={…}` and lets the browser rasterize it, with `fmt`'s exact
  formatting doing the cross-platform-agreement work `render/svg.ts` depends
  on.
- **Compose**: `androidx.compose.ui.graphics.Path` mirrors `CGMutablePath` —
  port `parsePath`'s tokenizer to walk the same `(letter, arity)` grammar and
  call `moveTo`/`lineTo`/`cubicTo`; morph by lerping the shared `FloatArray` of
  points the way `morphPath` does, then re-tokenizing into a `Path` on the
  animated frame that needs it.
- **WinUI 3**: Model `ParsedPath` as a `readonly record struct(string Kind,
  double[] Points)` and port `ParsePath`/`EmitPath`/`Fmt` as ordinary static
  methods on a `PathGrammar` class, always parsing/formatting through
  `System.Globalization.CultureInfo.InvariantCulture` (so `.` is the decimal
  separator regardless of the host's locale, matching this layer's ASCII-only
  digit grammar). Port `Build.Disc`/`Ring`/`Arc`/`Polyline`/`Bezier` and
  `MorphPath`/`PromotePolyline` as pure static methods with no
  `INotifyPropertyChanged` or `ObservableCollection` involvement — nothing here
  is bindable state. The resulting `d`-equivalent string feeds a
  `Microsoft.UI.Xaml.Shapes.Path`'s `Data` (a `Geometry` built the same way,
  via `PathGeometry`/`PathFigure`/`LineSegment`/`BezierSegment`), with a
  `Storyboard`/`CompositionAnimation` driving the frame-by-frame `t` that
  `MorphPath` consumes; `Math.Round(x, 6, MidpointRounding.AwayFromZero)` is
  the direct equivalent of Swift's `Double.rounded()` and is what `Fmt` MUST
  use to keep this platform's path-data output byte-identical to the other
  two.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/avatar-engine/src/path/` | unverified |
| apple | `packages/apple/AvatarAnimationEngine/Sources/Path/` | unverified |

## Design Decisions

- **Decision**: Pin the quarter-circle control-point constant to `0.5523`
  rather than the mathematically precise `0.5522847498`.
  **Rationale**: Per `Build.swift`'s doc comment, the higher-precision value
  would move every circle by roughly `1e-5` units and fail the byte-for-byte
  golden comparison between the Swift and web output; the four-digit pin is a
  deliberate cross-platform-agreement choice, not a rounding shortcut.
  **Approved**: pending
- **Decision**: `fmt` rounds half-away-from-zero, matching Swift's
  `Double.rounded()`; the web's `fmt` was rewritten to match Swift rather than
  the reverse.
  **Rationale**: Per `parse.ts`'s comment and `PathTests.swift`'s
  `testRoundsNegativeHalfStepsAwayFromZero`, JavaScript's `Math.round` is
  half-toward-positive-infinity, which disagrees with Swift on every negative
  half-step. A `back.out` easing extrapolates past `t = 1` and is the
  realistic route to a negative coordinate landing exactly on that boundary,
  so the web side moved to match the Swift behavior the animation goldens
  already depended on.
  **Approved**: pending
- **Decision**: `morphPath` does not clamp `t` to `[0, 1]`.
  **Rationale**: Per `Morph.swift`'s and `morph.ts`'s comments, an eased `t`
  from a `back.out(3)` curve crosses `1` a quarter of the way through the
  tween and stays above it for the remaining three quarters. Clamping here
  would delete the overshoot the original animation relies on — a measured
  `3.16` design-unit difference on the `startled` pose and `2.26` on
  `surprised` — and visibly soften every `back.out` pose.
  **Approved**: pending
- **Decision**: `ring(cx, cy, r, band)` takes an outer radius and a band
  width, not an outer and an inner radius.
  **Rationale**: Per `Build.swift`'s doc comment, a character drawn at a
  single stroke weight holds that band constant across every ring it has;
  making the band the datum keeps that invariant in the data instead of a
  comment, so a visual variant can patch one number (the band) instead of two
  (both radii) to change optical weight.
  **Approved**: pending
- **Decision**: `promotePolyline` lives in `Sources/Anim/Timelines.swift` on
  Apple, not alongside `Build.swift`/`Morph.swift`/`ParsedPath.swift` under
  `Sources/Path/`, while its web equivalent lives in `src/path/promote.ts`.
  **Rationale**: The Apple port grew `promotePolyline` as a helper local to
  the timeline-promotion feature (`Timelines.swift`'s `tryPromote`) rather
  than placing it in the shared Path module; the two implementations are
  contract-identical — confirmed line-for-line against `promote.ts` and its
  exact-string assertions in `promote.test.ts` — but a port to a new platform
  should place this function alongside the other Path primitives (matching
  the web's layout) rather than copying Apple's file location.
  **Approved**: pending
- **Decision**: Apple types its path errors (`PathError: Error,
  CustomStringConvertible`, with distinct `unsupported`/`truncated`/`stray`/
  `badPointCount`/`shapeMismatch` cases); the web throws untyped `Error`
  objects instead.
  **Rationale**: This is an observed platform divergence, not a design
  recommendation: `ParsedPath.swift` declares a closed enum with a computed
  `description`, while `parse.ts`/`build.ts`/`morph.ts`/`promote.ts` all throw
  a plain `new Error(message)`. The `unsupported`/`stray` message text does
  match across platforms, but the `truncated` text does not (see
  truncated-command-rejected): Apple's version never names the pending
  command. No test on either platform asserts this text — both are bare
  `.toThrow()`/`XCTAssertThrowsError` checks — so a port cannot preserve one
  exact truncated-message text for both platforms at once; it must pick
  one, and the `unsupported`/`stray` text is the only text a port can match
  on both.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.artifact-formatting.ingredient-formatting.if-behavioral-requirements](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/192770a1-b6b6-5782-bc29-251a8a941272) | passed | Artifact Formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-test-vectors](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/91ba975a-1f6a-5a85-8652-26e76cf324f4) | passed | Artifact Formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-compliance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1888cb38-9583-5657-a76f-c9685d296d6c) | passed | Artifact Formatting |

`explicit-error-handling` is `partial` rather than `passed` because the three
open questions in Edge Cases (`ring`'s unvalidated `band`, `parsePath`'s
missing leading-`M` requirement, and `ParsedPath`'s unvalidated construction
invariant) are unvalidated-input paths the source leaves undefined rather than
explicit, handled error conditions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial extraction from `Build.swift`, `Morph.swift`, `ParsedPath.swift`, `build.ts`, `morph.ts`, `parse.ts`, and `promote.ts`. |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.0.2 | 2026-09-25 | Mike Fullerton | round-trip now scoped to already-grid-quantized points, with the off-grid case spelled out; truncated-command-rejected and the error-representation Decision corrected for the Swift/web message-text divergence; renamed cubicO-shape/disc-is-cubicO to kebab-case. |
