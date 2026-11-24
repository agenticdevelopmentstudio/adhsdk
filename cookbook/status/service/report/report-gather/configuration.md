Request parameters, which a caller can set:


| Option | Type | Default | Description |
| `range` | `24h`, `7d` or `30d` | `24h` | Analytics dashboard range |
| `days` | integer 1 to 365 | 7 | Window of the uptime read |
| `wait` | integer 0 to 60 seconds | 20 | How long each dashboard may finish a cold refresh |
| `logs` | boolean | false | Attach the log tail of failing deploys |

Internal constants, which a caller cannot set and a port must not expose as settings:

| Constant | Type | Value | Description |
|----------|------|-------|-------------|
| `LOG_DEPLOY_CAP` | exported constant | 5 | Failing deploys whose log is read |
| `LOG_TAIL_LINES` | exported constant | 40 | Lines of each log kept |
| `LOG_TIMEOUT_MS` | constant, not exported | 10000 | Each log read, plus 1000 ms on the outer deadline |
| `SOURCE_TIMEOUT_MS` | constant, not exported | 20000 | Any non-dashboard source; dashboards add `wait` |

Injected dependencies and test seams, supplied by the host code or a test and never by a request:


| Option | Type | Default | Description |
| `ReportServices` | `storage`, `config`, `dashboards`, `integrations`, optional `scheduler` | injected | Built once in `createApp` and shared with MCP |
| `ReportSources` | seam of seven reads | `reportSources(services)` | Tests swap any read |
| `now` | function returning a `Date` | `() => new Date()` | Injected clock |
| `config.gitCommitSha`, `config.probeIntervalSeconds` | `StatusConfig` | from config | Report version and the no-loop stale window |
