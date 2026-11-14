
Vectors derive from `ITermColorsParserTests` (Swift Testing suite `ITermColorsParser`) unless marked "source". The fixture builds a plist with all 16 ANSI colors plus `Foreground Color`, `Background Color`, and optional `Cursor Color` (0.9, 0.9, 0.9) and `Selection Color` (0.2, 0.2, 0.2).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| itermcolors-001 | parse-data-returns-theme, ansi-order-preserved, not-built-in | Test `parsesPalette`: foreground (1,1,1), background (0,0,0), `Ansi 5 Color` (1,0,0.5), rest black; name `Test` | `name == "Test"`; foreground is `RGBAColor(1,1,1,1)`; background `RGBAColor(0,0,0,1)`; `ansi.count == 16`; `ansi[5] == RGBAColor(1,0,0.5,1)`; `isBuiltIn == false` |
| itermcolors-002 | appearance-inferred | Test `infersDark`: foreground white, background black, no `appearance` | `appearance == .dark` |
| itermcolors-003 | appearance-inferred | Test `infersLight`: foreground black, background white, no `appearance` | `appearance == .light` |
| itermcolors-004 | appearance-explicit-wins | Test `explicitAppearance`: white on black, `appearance: .light` | `appearance == .light` |
| itermcolors-005 | foreground-equals-background-rejected | Test `rejectsForegroundEqualsBackground`: foreground and background both (0,0,0) | throws `ITermColorsParseError.foregroundMatchesBackground` |
| itermcolors-006 | cursor-fallback, selection-fallback | Test `fallbacks`: white on black, no `Cursor Color`, no `Selection Color` | `cursor == foreground`; `selection == background.blended(withFraction: 0.25, of: foreground)` |
| itermcolors-007 | top-level-must-be-dictionary | Test `notADictionary`: plist root is the array `[1, 2, 3]` | throws `ITermColorsParseError.notADictionary` |
| itermcolors-008 | foreground-required, fail-fast | Test `missingColor`: no `Foreground Color` key | throws `ITermColorsParseError.missingColor("Foreground Color")` |
| itermcolors-009 | component-required | Test `missingComponent`: `Foreground Color` has Green and Blue but no `Red Component` | throws `missingComponent(colorKey: "Foreground Color", component: "Red Component")` |
| itermcolors-010 | alpha-default-opaque | Source: a color dictionary with Red, Green, Blue and no `Alpha Component` | decoded color has `alpha == 1.0` and no error |
| itermcolors-011 | channel-clamping | Source: `Red Component` 1.2 and `Green Component` -0.1 | decoded channels are 1.0 and 0.0 |
| itermcolors-012 | ansi-required | Source: all required colors present except `Ansi 7 Color` | throws `missingColor("Ansi 7 Color")` |
| itermcolors-013 | degenerate-check-before-ansi | Source: foreground equals background and all ANSI keys absent | throws `foregroundMatchesBackground`, not `missingColor` |
| itermcolors-014 | url-overload-default-name | Source: `parse(contentsOf:)` on `/tmp/Dracula.itermcolors` with no `name` | `name == "Dracula"` |
| itermcolors-015 | id-default-fresh-uuid | Source: two calls to `parse(data:name:)` with the same data and no `id` | the two themes have different `id` values, each a valid UUID string |
| itermcolors-016 | foundation-errors-propagate | Source: `parse(data:)` on the bytes `not a plist` | throws a Foundation error from `PropertyListSerialization`, not an `ITermColorsParseError` |
| itermcolors-017 | cursor-fallback | Source: `Cursor Color` present but missing `Blue Component` | no error; `cursor == foreground` |

