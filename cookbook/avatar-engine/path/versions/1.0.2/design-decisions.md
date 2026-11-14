
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

