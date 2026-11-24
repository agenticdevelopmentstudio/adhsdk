
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| home | `URL` | the current user's home directory | The root every `StenographerPaths` property derives from. |
| exists | `@Sendable (URL) -> Bool` | file-system existence of the path | Injected by tests to simulate fresh, legacy and migrated installs. |
| attempts | `Int` | 3 | Maximum writes made by `writeSupportFile`. |

The types read no environment variable or settings key.

