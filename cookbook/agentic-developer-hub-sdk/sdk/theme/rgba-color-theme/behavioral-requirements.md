
Luminance and classification

- **relative-luminance**: `relativeLuminance` MUST return the WCAG relative luminance of the color's sRGB components, `0.2126 * R + 0.7152 * G + 0.0722 * B`, where each channel is first linearized.
- **luminance-linearization**: Each channel MUST be linearized as `c / 12.92` when `c <= 0.03928`, and as `((c + 0.055) / 1.055) ^ 2.4` otherwise. The source uses the threshold 0.03928, not the 0.04045 of the current sRGB standard.
- **luminance-range**: `relativeLuminance` MUST return 0 for opaque black and 1 (within floating-point error) for opaque white.
- **luminance-ignores-alpha**: `relativeLuminance` MUST NOT read `alpha`; two colors that differ only in alpha have the same luminance.
- **is-dark-threshold**: `isDark` MUST return true exactly when `relativeLuminance < 0.5`. A luminance of exactly 0.5 is not dark.
- **is-dark-contract**: NEEDS REVIEW: Not implemented in source. The doc comment promises "dark enough to host light text on top", but the 0.5 threshold on linear luminance is not that test: a mid grey with 0.5 per channel has luminance about 0.214, so `isDark` is true while `bestTextColor` picks black (contrast about 5.28 against black versus 3.98 against white); the two agree only below a luminance of about 0.179. A design decision on whether `isDark` should mean "white text reads better" or "luminance under 0.5" would settle it.

Hex output

- **hex-rgb-format**: `hexStringRGB` MUST return `"#"` followed by six lower-case hexadecimal digits in the order red, green, blue, each zero-padded to two digits; it is always 7 characters long.
- **hex-rgb-no-alpha**: `hexStringRGB` MUST omit alpha; colors that differ only in alpha produce the same string.
- **hex-rgb-rounding**: Each channel MUST be clamped to 0 to 1, multiplied by 255 and rounded to the nearest integer, with halves rounded away from zero.
- **hex-rgb-purpose**: The format MUST match the terminal palette's color string, per the doc comment, so that `ColorTheme` can project onto `TerminalSessionColorPalette`. The RGBAColor recipe's `hexString` differs: it is upper-case and carries alpha.

Blending and compositing

- **blend-formula**: `blended(withFraction:of:)` MUST return, for every component including alpha, `self * (1 - f) + other * f`, where `f` is `fraction` clamped to 0 to 1.
- **blend-endpoints**: A fraction of 0 MUST return a color equal to `self`; a fraction of 1 MUST return a color equal to `other`.
- **blend-clamp**: A fraction below 0 MUST behave as 0 and a fraction above 1 MUST behave as 1; the operation MUST NOT extrapolate.
- **blend-alpha**: `blended(withFraction:of:)` MUST blend alpha linearly like the other channels, without premultiplying.
- **composite-formula**: `composited(over:)` MUST implement source-over: output alpha is `alpha + backdrop.alpha * (1 - alpha)`, and each color channel is `(source * alpha + under * backdrop.alpha * (1 - alpha)) / outAlpha`.
- **composite-opaque-source**: When `self.alpha` is 1, `composited(over:)` MUST return a color equal to `self`.
- **composite-clear-source**: When `self.alpha` is 0 and the backdrop is opaque, `composited(over:)` MUST return a color equal to the backdrop.
- **composite-transparent-result**: When the output alpha is 0 (both operands fully transparent), `composited(over:)` MUST return `RGBAColor(red: 0, green: 0, blue: 0, alpha: 0)` instead of dividing by zero.
- **composite-purpose**: A translucent color has no meaningful luminance or contrast alone, so a caller MUST resolve it with `composited(over:)` against its real backdrop before measuring it.

Contrast

- **contrast-formula**: `contrastRatio(against:)` MUST return `(lighter + 0.05) / (darker + 0.05)`, where `lighter` and `darker` are the greater and lesser of the two `relativeLuminance` values.
- **contrast-range**: The result MUST be 1 for two colors of equal luminance and 21 for opaque black against opaque white.
- **contrast-symmetric**: `a.contrastRatio(against: b)` MUST equal `b.contrastRatio(against: a)`.
- **contrast-opaque-precondition**: Callers MUST pass opaque operands. The doc comment states the method "assumes both operands are opaque"; the code does not check alpha, so a translucent operand is measured by its channel values alone.
- **best-text-color**: `bestTextColor(black:white:)` MUST return `white` when `contrastRatio(against: white) >= contrastRatio(against: black)`, and `black` otherwise. A tie therefore returns `white`.
- **best-text-defaults**: The `black` and `white` parameters MUST default to `RGBAColor.opaqueBlack` and `RGBAColor.opaqueWhite`.
- **best-text-returns-argument**: `bestTextColor` MUST return one of the two supplied colors unchanged; it does not blend or adjust.

Dimming

- **dimmed-search**: `dimmed(towards:by:minContrast:)` MUST clamp `fraction` to 0 to 1, then try `blended(withFraction: amount, of: background)` starting at that amount and reducing `amount` by 0.05 after each failed attempt.
- **dimmed-accept**: It MUST return the first candidate whose `contrastRatio(against: background)` is at least `minContrast`.
- **dimmed-fallback**: When `amount` falls to 0 or below without a candidate qualifying, or when the clamped fraction is 0, it MUST return `self` unchanged. The result is then below `minContrast` if `self` itself was; the method does not report that.
- **dimmed-step**: The returned amount is quantized to the starting fraction minus a whole number of 0.05 steps; the method does not search for the exact amount that meets `minContrast`.

Desaturation

- **desaturate-luma**: `desaturated(by:)` MUST compute the target grey as `0.299 * red + 0.587 * green + 0.114 * blue` over the encoded (non-linear) components, the Rec. 601 luma. It MUST NOT use `relativeLuminance`, which is linear-light and would darken every color it touched.
- **desaturate-blend**: It MUST blend `self` toward a grey whose three channels equal that luma and whose alpha equals `self.alpha`, by `amount` clamped to 0 to 1.
- **desaturate-default**: `amount` MUST default to 1, which yields a neutral grey; an amount of 0 MUST return a color equal to `self`.
- **desaturate-alpha**: Alpha MUST be preserved.
- **desaturate-idempotent**: Desaturating a grey (equal channels) MUST leave it unchanged within floating-point error.

Constants, concurrency and side effects

- **opaque-constants**: `opaqueBlack` MUST be (0, 0, 0, 1) and `opaqueWhite` MUST be (1, 1, 1, 1).
- **total-functions**: No member MUST throw, trap or return an optional; every color result is built through the `RGBAColor` component initializer, which clamps each component to 0 to 1, so a returned color is always in range.
- **concurrency**: Every member is a pure function of immutable values on a `Sendable` type, so any thread MAY call it concurrently without synchronization.
- **no-side-effects**: Members MUST NOT perform I/O, logging, notification or persistence.

