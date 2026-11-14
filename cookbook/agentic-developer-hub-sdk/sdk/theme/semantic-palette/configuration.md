
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `theme` | `ColorTheme` | required | The only input to `init(theme:)`; supplies background, foreground, selection, cursor, ANSI table, `roleOverrides`, `typography` and `project` |
| `ColorTheme.roleOverrides` | dictionary from role raw value to `RGBAColor` | empty | Per-role overrides; keys that match no `ThemeRole` are never read |
| `factor` | `Double` | 1 (no scale) | Argument of `scaled(by:)`, clamped to 0.5 through 4 |
| `ThemeTypography.sizeScaleRange` | `ClosedRange<Double>` | 0.5 through 4 | Bound shared with `ThemeStore` |

No environment variables or settings keys are read; the host owns persistence of the theme and of the reader's text-size choice.

