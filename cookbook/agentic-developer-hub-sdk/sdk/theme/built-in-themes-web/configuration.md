
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `BuiltInThemes.webPorted` | `[ColorTheme]` | the 21 themes above | The generated catalogue; read-only |
| `ThemeTypography.sizeScale` | `Double` | 1.0 | Per theme; set from the web body size over a 15px baseline |
| Generator inputs | files | none | `scripts/extract_web_themes.py` output (from `packages/web/packages/themes/src/styles/*.css`), consumed by `scripts/generate_web_theme_swift.py` |

The theme data takes no environment variables, settings keys or injected dependencies at read time.

