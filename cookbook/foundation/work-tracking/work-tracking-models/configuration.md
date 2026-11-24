
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `WorkTrackingPreferences.defaultRetentionDays` | `Int` | 90 | Retention the default preferences carry |
| `WorkTrackingPreferences.retentionDaysRange` | `ClosedRange<Int>` | 7...3650 | Bounds `normalized()` clamps retention into |
| `WorkTrackingStatus.degradedNotice` | `String` | `Tracking without Accessibility — time is unassigned.` | Sentence shown while tracking runs without Accessibility |
| `ActivitySpanSession.prefix` | `String` | `app:` | Prefix of a billing session id made by an app span |
| Hard dependency | `BillingLimits.clamp` | n/a | The static clamp helper `normalized()` calls directly, from the billing DTOs; nothing is injected |

