
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

