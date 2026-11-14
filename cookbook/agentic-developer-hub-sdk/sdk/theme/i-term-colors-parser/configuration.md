
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `data` | `Data` | required | Raw `.itermcolors` bytes (XML or binary plist), data overload only |
| `url` (`contentsOf`) | `URL` | required | Location of the `.itermcolors` file, URL overload only |
| `name` | `String` (data overload) / `String?` (URL overload) | required / `nil` | Theme display name; the URL overload falls back to the file's base name |
| `id` | `String` | `UUID().uuidString` | Stable theme identifier |
| `appearance` | `ThemeAppearance?` | `nil` | `.dark`, `.light` or `.auto`; `nil` infers from background luminance |
| `ColorTheme.ansiColorCount` | `Int` | `16` | Number of ANSI colors required, injected from `ColorTheme` |

The parser reads no environment variables and no settings keys. The selection fallback fraction (0.25) and the luminance threshold (0.5, in `RGBAColor.isDark`) are constants in the source.

