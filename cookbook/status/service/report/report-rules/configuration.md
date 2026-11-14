
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `now` | `Date` | supplied by the caller | The report's `generatedAt` |
| `monitorVersion` | string or null | supplied by the caller | Echoed into the report |
| `monitor`, `deploys`, `integrations`, `errors`, `runtimeErrors`, `analytics`, `uptime` | `SourceRead` | supplied by the caller | One payload or failure per source |
| `UPTIME_FLOOR` | constant | 99.5 | Uptime percent below which a service is a finding |
| `ERROR_ISSUE_CAP` | constant | 15 | GlitchTip issues listed as findings |
| `RUNTIME_GROUP_CAP` | constant | 15 | Vercel runtime groups listed as findings |
| `SITE_ROW_CAP` | constant | 10 | PostHog sites considered for findings |
| `RUNTIME_5XX_MAJOR_COUNT` | constant | 5 | Count at which a 5xx group is major |
| `FAILURE_RATE_HIGH` | constant in the dashboard views | 0.05 | Failure rate line used by `siteTroubled`, defined in `telemetry/dashboard/views.ts` and pinned by `constants-values` |

