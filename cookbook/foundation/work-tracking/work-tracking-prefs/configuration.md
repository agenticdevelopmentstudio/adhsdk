### Parameters

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| store | `some WorkTrackingSettingsStore` | required | Passed to every function; the host's settings database. |
| `signer` | `String?` | required argument | Passed to `setLastAccessibility` and `trustedAccessibility`; the caller reads it from `OwnCodeSignature.designatedRequirement()`. |

### Stored keys

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `activity_enabled` | text | `false` | Whether tracking is on. |
| `activity_added_bundle_ids` | JSON array of strings | `[]` | Bundle ids the user added to the tracked apps. |
| `activity_removed_bundle_ids` | JSON array of strings | `[]` | Bundle ids the user removed from the tracked apps. |
| `activity_retention_days` | integer text | `90` | Days of history kept; clamped to 7 through 3650. |
| `activity_ax_last_status` | text | `unknown` | Last Accessibility answer: `granted`, `denied` or `unknown`. |
| `activity_ax_signer` | text | `""` | The designated requirement the last answer was recorded under. |
