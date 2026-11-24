
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `range` (analytics-dashboard read) | `"24h"`, `"7d"` or `"30d"` | none — required | The window the analytics dashboard covers; part of the cache key and the request path. |
| `options.enabled` (both reads) | boolean | `true` | Set `false` to suspend fetching and polling, as the board shell does for a topic that is not open. |
| `FILLING_POLL_MS` | constant | `5000` | Poll interval while the latest body says `refreshing`. Not configurable. |
| `SETTLED_POLL_MS` | constant | `60000` | Poll interval otherwise, including while the read is in its error state. Not configurable. |
| status API client | `StatusApiClient` | the same-origin default (base path `/api`) | Injected through the dashboard's API provider; resolved with `useStatusApi`. |

The module reads no environment variables or settings keys.

