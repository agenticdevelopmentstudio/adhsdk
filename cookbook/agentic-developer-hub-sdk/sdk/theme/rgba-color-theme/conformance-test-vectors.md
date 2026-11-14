
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

