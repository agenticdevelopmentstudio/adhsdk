
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| the counts argument (to the uptime-percent function and the day-status function) | counts (four numbers) | none — required | The day's check counts: `total`, `healthy`, `degraded`, `down`. |
| the services argument (to the overall-uptime-percent function) | a list of objects each carrying `uptimePercent` (a number or null) | none — required | One entry per service; the list of services from the uptime state ([adhsdk.ingredient.status.dashboard.state.uptime](cookbook:e322fd0c-1552-4bd9-b129-3c809af3a972)), or an empty list while loading. |
| Down-majority threshold | constant | `0.5` | Hardcoded in the day-status function; strictly greater than this share of down checks makes the day `"down"`. Not configurable. |
| Rounding precision | constant | 2 decimal places | Hardcoded in both percent functions. Not configurable. |

This logic reads no environment variables, settings keys or injected dependencies.

