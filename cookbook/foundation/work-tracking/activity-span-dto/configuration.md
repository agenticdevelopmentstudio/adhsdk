
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `id` | String | `UUID().uuidString` | Span identity |
| `bundleId` | String | required | Bundle identifier of the focused app |
| `appName` | String | required | Display name of the focused app |
| `windowTitle` | String | `""` | Mutable window title |
| `workingPath` | String | `""` | Resolved working path; empty is unresolved |
| `repoRoot` | String | `""` | Repository root; empty is no repo |
| `branch` | String | `""` | Branch name |
| `startedAt` | String | required | ISO-8601 UTC start |
| `endedAt` | String | `""` | ISO-8601 UTC end; empty is open |
| `tz` | String | required | Time zone identifier string |
| `lastSeenAt` | String | `""` | Last heartbeat; empty is none yet |

No environment variables or settings keys; the caller supplies every value.

