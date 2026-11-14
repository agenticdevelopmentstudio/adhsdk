
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `env` | `GlitchtipEnv` | required | GlitchTip credentials and base URL for the fetcher |
| `allowlist` | `readonly string[]` or null | none | GlitchTip projects the board counts; from `glitchtipProjects` in the config |
| `resolvedCount` | `ResolvedCount` | required | The cached counter from `resolvedCounter`, shared across refreshes |
| `nowMs` | number | current time | The clock for judging and for the 30 day window |
| `ttlMs` | number | 3600000 | How long a resolved count stands (`RESOLVED_COUNT_TTL_MS`) |

