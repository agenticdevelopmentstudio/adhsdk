
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `env` | `GlitchtipEnv` | required | GlitchTip credentials and base URL for the fetcher |
| `allowlist` | `readonly string[]` or null | `null` | GlitchTip projects the board counts; from `glitchtipProjects` in the config |
| `resolvedCount` | `ResolvedCount` | required | The cached counter from `resolvedCounter`, shared across refreshes |
| `nowMs` | number | current time | The clock for judging and for the 30 day window |
| `ttlMs` | number | 3600000 | How long a resolved count stands (`RESOLVED_COUNT_TTL_MS`) |
| Page size | number | 100 | Issues per GlitchTip page; the fetcher's `PAGE_LIMIT` |
| Page cap | number | 20 | The most pages one walk reads (2,000 issues); the fetcher's `MAX_PAGES`. A list that reaches it is capped |
| Walk budget | number | 12000 | Milliseconds for the whole walk, not per request; the fetcher's `TIMEOUT_MS` |
