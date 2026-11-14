
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `env.VERCEL_API_TOKEN` | string, optional | none | Bearer token; shared with the deploy poll and its quota. |
| `env.VERCEL_TEAM_ID` | string, optional | none | Sent as `teamId` when non-empty. |
| `VERCEL_API` | string (exported constant) | `https://api.vercel.com` | Base URL. |
| `CALL_TIMEOUT_MS` | number (private constant) | 20,000 | Per-call timeout. |
| `MAX_PROJECT_PAGES` | number (private constant) | 20 | Page cap of `listProjects`; page size 100. |
| `signal` | `AbortSignal`, optional | none | Caller cancellation or deadline. |
| `init` | `{ json?, headers? }` | `{}` | Makes the call a POST with a JSON body; extra headers. |

