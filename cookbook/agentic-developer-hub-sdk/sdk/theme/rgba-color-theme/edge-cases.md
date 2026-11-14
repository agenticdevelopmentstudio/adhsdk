
- **Translucent operand to contrast**: `contrastRatio(against:)` and `bestTextColor` read channel values only. A caller that passes a translucent color gets the ratio of the unblended color, not what a viewer sees. Resolve with `composited(over:)` first. MUST (caller precondition documented in the source).
- **Fully transparent composite**: both alphas 0 returns (0, 0, 0, 0) rather than NaN. MUST.
- **Fraction out of range**: `blended`, `dimmed` and `desaturated` clamp the fraction or amount to 0 to 1. MUST.
- **Unreachable minimum contrast**: `dimmed` returns `self` with no error or flag when no candidate meets `minContrast`. This is a documented fallback, not a silent failure. MUST.
- **Fraction not on the 0.05 grid**: `dimmed` tries the clamped fraction first, then steps down by 0.05, so a fraction of 0.32 tries 0.32, 0.27, 0.22 and so on. MUST.
- **Negative fraction in `dimmed`**: clamps to 0 and returns `self` without entering the loop. MUST.
- **Luminance exactly 0.5**: `isDark` is false. MUST.
- **Contrast tie**: `bestTextColor` returns `white`. MUST.
- **Grey input to `desaturated`**: unchanged within floating-point error. MUST.
- **Alpha through blend, composite and desaturate**: `blended` blends alpha linearly; `composited` produces source-over alpha; `desaturated` keeps alpha. `hexStringRGB` drops alpha. MUST.
- **Non-finite color math**: color results are built through the clamping `RGBAColor` initializer, so a NaN produced by color math is stored as 0. The `Double` values that `relativeLuminance` and `contrastRatio` return are not clamped. MUST.
- **Concurrent access**: not applicable beyond `Sendable`; the members are pure over immutable values, so concurrent calls cannot race.
- **Offline or disconnected state**: not applicable; no network or file access.
- **Cancellation and timeouts**: not applicable; every member is synchronous and bounded (`dimmed` runs at most about 21 iterations).

