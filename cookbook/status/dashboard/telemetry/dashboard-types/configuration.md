
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ANALYTICS_RANGES` | constant list | `24h`, `7d`, `30d` | Time ranges the analytics dashboard accepts. Not configurable. |
| `DIMENSIONS` | constant list | `country`, `device`, `browser`, `referrer` | Breakdown dimensions of page views. Not configurable. |
| `VERCEL_BREAKDOWNS` | constant list | `countries`, `referrers`, `paths`, `devices` | Vercel breakdown names. Not configurable. |
| `VITALS` | constant list | `lcp`, `inp`, `cls`, `fcp` | Web vitals the server measures. Not configurable. |

The module reads no environment variables or settings and takes no injected dependency. The runtime window (`24h`) and the active-issue test are fixed by the server.

