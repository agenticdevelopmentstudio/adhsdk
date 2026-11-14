
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `BuiltInThemes.defaultID` | `String` | `A1B2C3D4-0001-4000-8000-000000000001` | ID of the theme used when no selection is persisted (Solarized Dark) |
| `BuiltInThemes.all` | `[ColorTheme]` | 36 themes | Ordered catalogue; display order in theme pickers follows it |
| `BuiltInThemes.handAuthored` | `[ColorTheme]` | 15 themes | Internal subset with authentic chrome overrides |

The catalogue takes no environment variables, settings keys or injected dependencies. It depends on `ColorTheme`, `ThemeRole`, `RGBAColor` and, for the web-ported part, the two extension files named in the Overview. Each theme leaves `isImported` at its default `false` and `typography`, `terminal` and `project` at the `ColorTheme` initializer defaults (`.system`, `nil`, `nil`).

