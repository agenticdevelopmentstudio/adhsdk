
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `storage` | `any ThemeStorage` | none (required) | Injected in `init(storage:)`: persists `customThemes` and `activeThemeID` and offers `onExternalChange` |
| `addNewTheme(basedOn:)` | `ColorTheme` | `BuiltInThemes.solarizedDark` | Template copied for a new theme; the doc comment suggests callers pass the active theme |
| `addNewTheme(name:)` | `String` | `"New Theme"` | Base name, disambiguated against `allThemes` |
| `duplicate(nameSuffix:)` | `String` | `" Copy"` | Appended to the source name before disambiguation |
| `ThemeTypography.sizeScaleRange` | `ClosedRange<Double>` | `0.5...4` | Bound applied to an imported theme's `sizeScale` |
| `ColorTheme.ansiColorCount` | `Int` | `16` | Required ANSI palette length for JSON import |

