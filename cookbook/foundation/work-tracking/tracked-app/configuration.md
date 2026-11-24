
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `preferences` | `WorkTrackingPreferences` | none (required) | Supplies `removedBundleIds` and `addedBundleIds`; `enabled` and `retentionDays` are not read |
| `defaults` | `[TrackedApp]` | `AppAllowlist.defaults` | The built-in list the preferences are applied to; injectable for tests |

