
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| body (set preferences) | encoded `WorkTrackingPreferences` | required | JSON snake case. |
| `since` | `String?` | nil | Cutoff string whose format the source does not state; nil is any. |
| `limit` | `Int` | required | Passed through as the caller gives it; the protocol states no meaning or bound. |
| `readFailedKey` | `String` | `work_tracking_read_failed` | Key of the failure row. |

No environment variables or settings keys.

