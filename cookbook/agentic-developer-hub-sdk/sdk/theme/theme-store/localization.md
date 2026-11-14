
`ThemeImportError` carries user-facing English text that is hardcoded in `errorDescription` and is not routed through a localization table.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (hardcoded) | `This theme has N ANSI colors; a valid theme needs exactly 16.` | `invalidPalette(count:)`, where N is the decoded count and 16 is `ColorTheme.ansiColorCount` |
| none (hardcoded) | `This theme's foreground and background are the same color, so its text would be invisible.` | `foregroundMatchesBackground` |

The default names `"New Theme"` and `" Copy"` are also hardcoded English defaults that a caller can override through the `name` and `nameSuffix` parameters.

