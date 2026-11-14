
Logging is a single `console.warn` on the server for a slow call.

| Event | Level | Message |
|-------|-------|---------|
| A call took 2,000 ms or more | warn | `[storage] slow call <path joined with dots> <ms>ms` |

