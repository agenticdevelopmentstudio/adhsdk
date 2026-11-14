
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

