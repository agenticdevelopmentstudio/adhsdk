
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `config` | `StatusConfig` | required | Supplies `credentials`, `glitchtipProjects` and the configured predicates |
| `storage` | `Storage` | required | Read for `telemetry.runtimeErrors` |
| `range` | `24h`, `7d` or `30d` | none | The analytics window, per call |
| `nowMs` | number | current time | The clock for the errors answer and the runtime read |
| `timeoutMs` | number | none | The wait limit of a settle call |
| `ANALYTICS_TTL_MS` | number | 600000 | Freshness of the PostHog, Vercel and sites caches; a module constant |
| `ERRORS_TTL_MS` | number | 60000 | Freshness of the GlitchTip cache; a module constant |

