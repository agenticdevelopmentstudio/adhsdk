
Constructor options:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `prefix` | `String` | required | Namespace prepended to every key; the app's only decision. Not itself a stored value. |

Stored settings:

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `enabled` | `Bool` | `false` | Whether tracking is on. |
| `addedBundleIds` | `[String]` | `[]` | Bundle ids the user added. |
| `removedBundleIds` | `[String]` | `[]` | Bundle ids the user removed. |
| `retentionDays` | `Int` | `90` | Days of history kept; range 7 through 3650 on the snapshot. |

Storage is the shared `UserSettings.shared` store that `UserSetting` reads; no environment variables.

