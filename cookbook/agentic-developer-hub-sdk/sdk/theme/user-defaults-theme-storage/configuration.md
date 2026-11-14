
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `defaults` | `UserDefaults` | `UserDefaults.standard` | The domain to persist into; a host with an app group passes its shared suite |
| `Key.customThemes` | `String` constant | `theme.custom_themes` | Key holding the JSON-encoded array of custom themes |
| `Key.activeThemeID` | `String` constant | `theme.active_theme_id` | Key holding the active theme id string |
| `onExternalChange` | `(() -> Void)?` | nil | Set by the consumer (`ThemeManager`) to reload and repaint; invoked on the main actor |

The class reads no environment variables and no feature flags.

