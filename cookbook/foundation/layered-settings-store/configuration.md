
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `overrides` | `SettingsStorageProvider` | none (required) | Where this layer's own values are held; every non-secure write lands here. |
| `fallback` | `SettingsStore` | none (required) | The broader store that non-secure reads fall through to and that owns every secure key. |

