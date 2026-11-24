
Not applicable beyond the arguments and constants below: the loader reads no settings file; its credentials come in through `env`.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `env.VERCEL_API_TOKEN` | string | none | Bearer token; shared with the deploy poll |
| `env.VERCEL_TEAM_ID` | string | none | Adds `teamId` to every request when set |
| `w` | `RangeWindow` | none | The window to read: `since`, `until`, `unit`, `buckets` |
| `CONCURRENCY` | constant | 6 | Maximum parallel domain lookups, counts and project breakdowns |
| `AGGREGATE_LIMIT` | constant | `"100"` | Rows per aggregate call; the API's maximum |

