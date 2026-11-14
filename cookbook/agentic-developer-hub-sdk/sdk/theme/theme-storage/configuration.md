
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| customThemes | [ColorTheme] | empty array | Imported and custom themes in insertion order; read and written by `ThemeStore` |
| activeThemeID | String? | nil | `ColorTheme.id` of the selected theme; nil on a fresh install |
| onExternalChange | (() -> Void)? | nil | Set by `ThemeManager`; invoked by a conformer on a change from outside the seam |
| defaults (`UserDefaultsThemeStorage.init`) | UserDefaults | `.standard` | Domain used by the shipped conformer; pass a shared suite for an app group |
| `UserDefaultsThemeStorage.Key.customThemes` | String | `theme.custom_themes` | Defaults key for the JSON-encoded theme array; changing it orphans saved themes silently |
| `UserDefaultsThemeStorage.Key.activeThemeID` | String | `theme.active_theme_id` | Defaults key for the active theme id |

