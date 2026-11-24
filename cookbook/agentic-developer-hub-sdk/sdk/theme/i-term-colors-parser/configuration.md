
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `data` | `Data` | required | Raw `.itermcolors` bytes (XML or binary plist), data overload only |
| `url` (`contentsOf`) | `URL` | required | Location of the `.itermcolors` file, URL overload only |
| `name` | `String` (data overload) / `String?` (URL overload) | required / `nil` | Theme display name; the URL overload falls back to the file's base name |
| `id` | `String` | `UUID().uuidString` | Stable theme identifier |
| `appearance` | `ThemeAppearance?` | `nil` | `.dark`, `.light` or `.auto`; `nil` infers from background luminance |

The number of ANSI colors required is `ColorTheme.ansiColorCount` (16), a compile-time constant of `ColorTheme` ([adhsdk.ingredient.agentic-developer-hub-sdk.sdk.theme.color-theme](cookbook:932449c9-b57f-4e2c-992a-1e27584742b6)) that callers cannot set. The parser reads no environment variables and no settings keys. The selection fallback fraction (0.25) and the luminance threshold (0.5, in `RGBAColor.isDark`) are constants in the source.

