---
id: 591d0b87-ce71-4b11-8642-149fc405cce9
title: "RGBAColor Theme Extension"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Color math on RGBAColor: WCAG luminance and contrast, hex output, blend, composite, dim toward a backdrop, best text color, and desaturate."
platforms:
  - swift
  - macos
  - ios
tags:
  - theme
  - color
  - wcag
  - contrast
  - logic
depends-on: []
related:
  - ad5bae6b-0172-4cd4-a4b7-297eb58eb28d
references: []
approved-by: ""
approved-date: ""
---

# RGBAColor Theme Extension

## Overview

`RGBAColor+Theme.swift` is an `extension RGBAColor` that adds the color math the theme layer needs to derive a whole palette from a few base colors. It measures a color (`relativeLuminance`, `isDark`, `contrastRatio(against:)`), writes it out (`hexStringRGB`), and builds new colors from it (`blended(withFraction:of:)`, `composited(over:)`, `bestTextColor(black:white:)`, `dimmed(towards:by:minContrast:)`, `desaturated(by:)`). It also adds two constants, `opaqueBlack` and `opaqueWhite`.

Every member is a pure computation over the four `Double` components of `RGBAColor` (see the RGBAColor recipe for the value type and its clamping). Nothing here reads or writes files, the network, defaults or logs. The callers are `SemanticPalette` (derives surface, text and accent roles), `ITermColorsParser` (derives a missing selection color and the dark or light appearance) and `VSCodeThemeImporter` in the Core layer (composites a declared selection over the background, derives a fallback selection and infers the appearance).

## Behavioral Requirements

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

## Appearance

Not applicable — this is a color-math extension on a value type, not a visual component.

## States

Not applicable — this is a set of pure functions over an immutable value type, not a visual component. `dimmed` runs a bounded loop but keeps no state between calls.

## Accessibility

Not applicable — this is a color-math extension, not a visual component. It supplies the WCAG formulas (luminance and contrast ratio) that the theme layer uses to keep derived text legible, but it renders nothing and carries no labels or focus behavior.

## Conformance Test Vectors

Tests beside the source: `RGBAColorThemeTests` (compositing), `IdleStatusInkTests` (`desaturated`), `SemanticPaletteRolesTests` ("contrastRatio matches WCAG extremes"), `ITermColorsParserTests` (selection derived by `blended`) and `SemanticPaletteTests` and `ChatRoleDerivationTests` (contrast floors). `relativeLuminance` thresholds, `isDark`, `hexStringRGB`, `bestTextColor` and `dimmed` have no direct assertions, so their vectors are derived from the source and computed by hand (approximate values stated to 0.001).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| rgbacolor-theme-001 | relative-luminance, luminance-range | `opaqueBlack.relativeLuminance`, `opaqueWhite.relativeLuminance` | 0 and 1 |
| rgbacolor-theme-002 | relative-luminance, luminance-linearization | color (0.5, 0.5, 0.5, 1) | luminance about 0.214 |
| rgbacolor-theme-003 | luminance-ignores-alpha | (0.5, 0.5, 0.5, 0.1) and (0.5, 0.5, 0.5, 1) | equal luminance |
| rgbacolor-theme-004 | is-dark-threshold | `opaqueBlack.isDark`, `opaqueWhite.isDark` | true, false |
| rgbacolor-theme-005 | is-dark-threshold, is-dark-contract | color (0.5, 0.5, 0.5, 1) | `isDark` is true and `bestTextColor()` is `opaqueBlack` |
| rgbacolor-theme-006 | hex-rgb-format, hex-rgb-rounding | (0.2, 0.4, 0.6, 1).`hexStringRGB` | `"#336699"` |
| rgbacolor-theme-007 | hex-rgb-rounding, hex-rgb-format | (1, 0.5, 0.25, 1).`hexStringRGB` | `"#ff8040"` (127.5 rounds to 128, 63.75 to 64) |
| rgbacolor-theme-008 | hex-rgb-no-alpha | (1, 0, 0, 0.2) and (1, 0, 0, 1) | both `"#ff0000"` |
| rgbacolor-theme-009 | blend-formula, blend-endpoints | `opaqueBlack.blended(withFraction: 0.25, of: opaqueWhite)`; fractions 0 and 1 | channels 0.25 with alpha 1; `self` at 0; `other` at 1 (ITermColorsParserTests: `selection == background.blended(withFraction: 0.25, of: foreground)`) |
| rgbacolor-theme-010 | blend-clamp | fractions 2 and -1 on the same pair | equal to the fraction 1 and fraction 0 results |
| rgbacolor-theme-011 | blend-alpha | (0, 0, 0, 0).blended(withFraction: 0.5, of: (1, 1, 1, 1)) | (0.5, 0.5, 0.5, 0.5) |
| rgbacolor-theme-012 | composite-opaque-source | (0.2, 0.4, 0.6, 1) over opaque white (RGBAColorThemeTests "full alpha returns the source colour unchanged") | equals the source |
| rgbacolor-theme-013 | composite-clear-source | (0.2, 0.4, 0.6, 0) over (0.9, 0.1, 0.5, 1) ("zero alpha returns the backdrop unchanged") | equals the backdrop |
| rgbacolor-theme-014 | composite-formula | (0, 0, 0, 0.5) over opaque white ("50% grey over white lands midway") | alpha 1; each channel 0.5 within 0.001 |
| rgbacolor-theme-015 | composite-formula | (1, 1, 1, 0.5) over (0, 0, 0, 0.5) ("compositing two translucent colours accumulates alpha correctly") | alpha 0.75; red 2/3 within 0.001 |
| rgbacolor-theme-016 | composite-transparent-result, total-functions | (0, 0, 0, 0) over (0, 0, 0, 0) | (0, 0, 0, 0); no division by zero |
| rgbacolor-theme-017 | contrast-formula, contrast-range | `opaqueBlack` against `opaqueWhite` (SemanticPaletteRolesTests "contrastRatio matches WCAG extremes") | above 20; 21 by the formula |
| rgbacolor-theme-018 | contrast-range | `opaqueWhite` against `opaqueWhite` | 1 within 0.0001 |
| rgbacolor-theme-019 | contrast-symmetric | `a.contrastRatio(against: b)` and `b.contrastRatio(against: a)` for (0.2, 0.4, 0.6, 1) and (0.9, 0.9, 0.1, 1) | equal |
| rgbacolor-theme-020 | best-text-color | `opaqueBlack.bestTextColor()`, `opaqueWhite.bestTextColor()` | `opaqueWhite`, `opaqueBlack` |
| rgbacolor-theme-021 | best-text-color | color (0.4, 0.4, 0.4, 1).bestTextColor() | `opaqueWhite` (contrast 5.74 against white, 3.66 against black); (0.6, 0.6, 0.6, 1) gives `opaqueBlack` |
| rgbacolor-theme-022 | best-text-returns-argument, best-text-defaults | `opaqueBlack.bestTextColor(black: X, white: Y)` for custom X and Y | returns Y unchanged |
| rgbacolor-theme-023 | dimmed-accept | `opaqueWhite.dimmed(towards: opaqueBlack, by: 0.5, minContrast: 1)` | grey (0.5, 0.5, 0.5, 1); contrast about 5.28 passes at the first attempt |
| rgbacolor-theme-024 | dimmed-search, dimmed-step | `opaqueWhite.dimmed(towards: opaqueBlack, by: 0.5, minContrast: 11)` | grey 0.75 within 0.001; attempts at 0.5 through 0.30 give contrast below 11, 0.25 gives about 11.45 |
| rgbacolor-theme-025 | dimmed-fallback | any color dimmed by a fraction of 0 | equals `self` |
| rgbacolor-theme-026 | dimmed-fallback | `opaqueWhite.dimmed(towards: opaqueBlack, by: 0.5, minContrast: 30)` (unreachable, the maximum is 21) | equals `opaqueWhite`; no error |
| rgbacolor-theme-027 | desaturate-blend | `#33ff66ff`.desaturated() (IdleStatusInkTests "a full desaturation leaves the three channels equal") | red, green and blue equal within 0.0001 |
| rgbacolor-theme-028 | desaturate-luma | `#33ff66ff`.desaturated() (IdleStatusInkTests "the grey keeps roughly the apparent lightness") | grey equals 0.299 R + 0.587 G + 0.114 B of the input within 0.0001 |
| rgbacolor-theme-029 | desaturate-luma | `#c04040ff`.desaturated() | grey red is more than the input's `relativeLuminance` plus 0.2 |
| rgbacolor-theme-030 | desaturate-default, desaturate-alpha | (0.2, 0.9, 0.4, 0.5): `desaturated(by: 0)` and `desaturated().alpha` | equals the input; alpha 0.5 |
| rgbacolor-theme-031 | desaturate-blend | `desaturated(by: 4)` and `desaturated(by: -2)` on `#33ff66ff` | equal to `desaturated(by: 1)` and to the input |
| rgbacolor-theme-032 | desaturate-idempotent | (0.4, 0.4, 0.4, 1).desaturated() | channels 0.4 within 0.0001 |
| rgbacolor-theme-033 | opaque-constants | `opaqueBlack`, `opaqueWhite` | (0, 0, 0, 1) and (1, 1, 1, 1) |
| rgbacolor-theme-034 | contrast-opaque-precondition | (0, 0, 0, 0.1).contrastRatio(against: `opaqueWhite`) | 21: alpha is ignored, so a caller must composite first |

## Edge Cases

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

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `black` (in `bestTextColor`) | `RGBAColor` | `opaqueBlack` | The dark candidate returned when it contrasts better |
| `white` (in `bestTextColor`) | `RGBAColor` | `opaqueWhite` | The light candidate returned on a tie or when it contrasts better |
| `amount` (in `desaturated`) | `Double` | 1 | Fraction of the way to the grey, clamped to 0 to 1 |
| `fraction`, `minContrast` (in `dimmed`) | `Double`, `Double` | none (required) | Starting blend toward the background, and the contrast floor against it |

Fixed values in the source: the 0.5 luminance threshold of `isDark`, the 0.03928 linearization threshold, the 0.05 step of `dimmed`, and the Rec. 601 weights 0.299, 0.587 and 0.114. There are no environment variables, settings keys or injected dependencies.

## Deep Linking

Not applicable: the extension is pure color math with no screens or URL routes.

## Localization

Not applicable: the extension emits no user-facing strings; `hexStringRGB` produces a machine format and the source contains no localizable text.

## Accessibility Options

Not applicable: the extension holds no rendering code and does not respond to Reduce Motion, Increase Contrast or Differentiate Without Color; it only supplies the contrast measurement that callers use.

## Feature Flags

Not applicable: the source reads no flags.

## Analytics

Not applicable: the source emits no events.

## Privacy

Not applicable: the extension computes on color values only. It collects, stores and transmits nothing.

## Logging

Not applicable: the source makes no log calls; `dimmed` returns `self` without a signal when it cannot meet `minContrast`, which is its documented fallback.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/RGBAColor+Theme.swift`, an extension in the SDK's `Theme` folder that imports only `Foundation` (for `pow` and `String(format:)`). It compiles for macOS and iOS. Bridge to a SwiftUI `Color(.sRGB, red:green:blue:opacity:)` in the UI layer after the math is done, and call `composited(over:)` against the real backdrop color before using `contrastRatio` on a translucent fill. The file qualifies `Swift.min` and `Swift.max` explicitly, which a port to another Swift module should keep.
- **Compose**: Use `androidx.compose.ui.graphics.Color` for display. `Color.compositeOver(background)` implements source-over. `androidx.compose.ui.graphics.lerp` blends in a chosen color space and handles alpha by premultiplying, which differs from the plain per-channel alpha blend here, so port `blended` by hand. `androidx.core.graphics.ColorUtils.calculateContrast` and `calculateLuminance` exist, but check their results against the vectors before substituting them.
- **React/Web**: Port as pure functions on a readonly color object. Use `Math.pow` for the 2.4 exponent and `Math.min` and `Math.max` for the clamps. `hexStringRGB` is `#` plus `Math.round(x * 255).toString(16).padStart(2, "0")` for each clamped channel; clamped values are never negative, where `Math.round` and Swift's `rounded()` agree on halves. In CSS, `color-mix(in srgb, ...)` approximates `blended` but premultiplies alpha, so it is not the same math.
- **AppKit / UIKit**: No platform color class is needed: the math stays on `RGBAColor`. `NSColor` and `UIColor` expose no WCAG luminance, and their brightness component is HSB value, a different quantity, so keep these helpers. Convert to `NSColor(srgbRed:green:blue:alpha:)` or `UIColor(red:green:blue:alpha:)` at the edge.
- **WinUI 3**: Implement as static extension methods on an immutable `readonly record struct RGBAColor` (`RelativeLuminance`, `ContrastRatio`, `Blended`, `Composited`, `BestTextColor`, `Dimmed`, `Desaturated`) using `Math.Pow`, `Math.Clamp` and `Math.Round(value, MidpointRounding.AwayFromZero)` to match Swift's `rounded()`. Build the hex string with lower-case `x2` formatting (`$"#{r:x2}{g:x2}{b:x2}"`). Keep the math in `double` on the struct, then bridge once to `Windows.UI.Color.FromArgb(a, r, g, b)` (alpha first) for a `SolidColorBrush`. In XAML, expose derived brushes through a `ResourceDictionary` with `ThemeDictionaries` entries for Light, Dark and HighContrast so they resolve per `RequestedTheme`. The struct is value-typed and thread-safe, so it needs no `INotifyPropertyChanged`; a view model that exposes derived brushes should raise `PropertyChanged` when the base theme colors change.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| android | (planned) | planned |
| windows | (planned) | planned |
| web | (planned) | planned |
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Theme/RGBAColor+Theme.swift` | confirmed (1.0.1) |

## Design Decisions

**Decision**: A translucent color is composited over its backdrop before contrast is measured, and `contrastRatio` does not check alpha.
**Rationale**: The source comments say a translucent color has no luminance or contrast on its own, only against what is behind it; the precondition is documented rather than enforced, and `ChatRoleDerivationTests` composites before measuring.
**Approved**: pending

**Decision**: `desaturated(by:)` uses Rec. 601 luma over encoded components, not `relativeLuminance`.
**Rationale**: The source comment explains that linear-light luminance fed into a display-encoded channel would darken every color it touched; luma keeps a phosphor green and its grey equally bright. `IdleStatusInkTests` pins this.
**Approved**: pending

**Decision**: `dimmed(towards:by:minContrast:)` steps down by 0.05 and falls back to `self` instead of solving for the exact amount or throwing.
**Rationale**: A coarse search is enough for text tones and always terminates; the caller gets legible text or the original color, never an error. The result can still be below `minContrast` when `self` already is.
**Approved**: pending

**Decision**: `relativeLuminance` linearizes with the threshold 0.03928.
**Rationale**: This is the value in the original WCAG 2.0 text; the current sRGB standard uses 0.04045. The source does not say why it chose one, so a port that must match its numbers keeps 0.03928.
**Approved**: pending

**Decision**: `isDark` is `relativeLuminance < 0.5`, and `hexStringRGB` is lower-case with no alpha.
**Rationale**: The 0.5 cut is the source's classifier for theme appearance (`ITermColorsParser` uses it to pick dark or light) and does not match its own "can host light text" comment for mid tones (see the open question on `is-dark-contract`). The lower-case six-digit form matches the terminal palette's color string, per the doc comment.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | reliability |

Separation of concerns passes because the file holds only pure color math on `RGBAColor`; the value type, platform-color bridges and palette policy live elsewhere. Unit-test coverage is partial: `composited` and `desaturated` have direct tests and `contrastRatio` has the extremes test, but `relativeLuminance`, `isDark`, `hexStringRGB`, `blended`, `bestTextColor` and `dimmed` are exercised only through the palette and parser tests. Explicit error handling passes because no member can fail: the zero-alpha composite is guarded, and `dimmed` has a defined fallback. Data integrity passes because every returned color is built through the clamping initializer.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Claims verified against source |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
