
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| built-in-themes-001 | all-count, all-composition | Read `BuiltInThemes.all` | 36 themes; the first 15 are `handAuthored` in order, the remaining 21 are `webPortedNative` (`BuiltInThemesTests.count`) |
| built-in-themes-002 | unique-ids | Collect `all.map(\.id)` into a `Set` | Set size equals 36 (`BuiltInThemesTests.uniqueIDs`) |
| built-in-themes-003 | built-in-flag, ansi-count | Iterate `all` | Every theme has `isBuiltIn == true` and `hasValidPalette == true`, meaning 16 ANSI colors (`BuiltInThemesTests.validity`) |
| built-in-themes-004 | chrome-override-roles | Iterate `handAuthored`, read `roleOverrides` for the five chrome roles | No role is missing for any theme (`BuiltInThemesTests.chromeOverrides`) |
| built-in-themes-005 | default-id, default-resolves | `theme(withID: BuiltInThemes.defaultID)` | Returns the theme whose `name` is "Solarized Dark" (`BuiltInThemesTests.defaultResolves`) |
| built-in-themes-006 | lookup-miss | `theme(withID: "no-such-id")` | Returns `nil` |
| built-in-themes-007 | lookup-exact-match | `theme(withID: "a1b2c3d4-0001-4000-8000-000000000001")` (lower case) | Returns `nil` |
| built-in-themes-008 | lookup-hit | `theme(withID: "A1B2C3D4-0003-4000-8000-000000000003")` | Returns Dracula |
| built-in-themes-009 | hex-accuracy | Compare `dracula.background` with `RGBAColor(hexString: "#282A36FF")` | Equal (`BuiltInThemesTests.hexAccuracy`) |
| built-in-themes-010 | hex-accuracy, ansi-count | Compare `dracula.ansi[5]` with `#FF79C6FF` and `solarizedLight.background` with `#FDF6E3FF` | Both equal (`BuiltInThemesTests.hexAccuracy`) |
| built-in-themes-011 | legibility, distinct-surface | For each theme build `SemanticPalette(theme:)` and read contrast ratios | primaryText over windowBackground at least 4.0; secondaryText over windowBackground at least 2.5; onAccentText over accent at least 3.0; surface differs from windowBackground (`BuiltInThemesTests.legibility`) |
| built-in-themes-012 | hand-authored-order, hand-authored-appearance | Read `handAuthored.map(\.name)` and `.appearance` | First name Solarized Dark, last Gruvbox Light; 11 `.dark` and 4 `.light` |
| built-in-themes-013 | opaque-colors | Read `alpha` of `nord.foreground` and of every `nord.roleOverrides` value | Every alpha equals 1 |
| built-in-themes-014 | chrome-override-only | Read `Set(solarizedDark.roleOverrides.keys)` | Equals the five raw values `surface`, `elevatedSurface`, `controlBackground`, `border`, `outline` |
| built-in-themes-015 | chrome-builder | Read `solarizedDark.roleOverrides` for `border` and `outline` | `border` is `0e4452` and `outline` is `1d5b69`, both opaque |
| built-in-themes-016 | hex-optional-hash | Call `rgb("#839496")` and `rgb("839496")` (the helper is private, so assert through a theme constant built with each form in a test double) | Both return the same opaque color |
| built-in-themes-017 | hex-invalid-traps | Call `rgb("xyz")` | Halts with the message `Invalid built-in theme hex: xyz` (a crash, so a port asserts it through its equivalent of a death test) |
| built-in-themes-018 | attribution-present, stable-ids | Read `solarizedDark.attribution` and `.id` | Attribution is "Ethan Schoonover"; id is `A1B2C3D4-0001-4000-8000-000000000001` |

