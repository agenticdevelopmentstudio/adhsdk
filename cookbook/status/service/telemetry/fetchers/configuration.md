
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `env.GLITCHTIP_URL` | `string \| undefined` (`GlitchtipEnv` field) | caller-supplied | GlitchTip instance base URL; trailing slashes are stripped before building the issues-endpoint URL. All three GlitchTip fields must be present or the fetcher no-ops. |
| `env.GLITCHTIP_API_TOKEN` | `string \| undefined` (`GlitchtipEnv` field) | caller-supplied | Sent as `Authorization: Bearer` on the issues request. |
| `env.GLITCHTIP_ORG` | `string \| undefined` (`GlitchtipEnv` field) | caller-supplied | GlitchTip organization slug interpolated into the issues-endpoint path. |
| `TIMEOUT_MS` | `number` (module constant, `glitchtip.ts`) | `12_000` | Deadline for the whole GlitchTip walk, every page and the closing re-read of page 1, via one `AbortController`. Not exported; not caller-configurable. |
| `MAX_PAGES` | `number` (exported module constant, `glitchtip.ts`) | `20` | Hard stop for the walk: 2,000 unresolved issues at `PAGE_LIMIT` per page. Reaching it ends the walk `complete: false`. |
| `PAGE_LIMIT` | `number` (exported module constant, `glitchtip.ts`) | `100` | Page size requested from GlitchTip (its own cap) and the threshold `complete-flag-by-page-size` compares a page's length against when the `Link` header is unusable. |
| `env.POSTHOG_HOST` | `string \| undefined` (`PosthogEnv` field) | caller-supplied | PostHog project host; trailing slashes stripped before building the query-endpoint URL. All three PostHog fields must be present or the fetcher no-ops. |
| `env.POSTHOG_API_KEY` | `string \| undefined` (`PosthogEnv` field) | caller-supplied | Sent as `Authorization: Bearer` on every HogQL query. |
| `env.POSTHOG_PROJECT_ID` | `string \| undefined` (`PosthogEnv` field) | caller-supplied | Interpolated into the HogQL query-endpoint path. |
| `KPI_COLUMNS` | array (module constant, `posthog.ts`) | fixed 4 entries: `pageviews`/`24h`, `visitors`/`24h`, `pageviews`/`7d`, `visitors`/`7d` | The column order of the one KPI query's row. Not exported; not caller-configurable. |
| `KPI_QUERY` | `string` (module constant, `posthog.ts`) | one HogQL `SELECT` over `$pageview` events of the last 7 days | Answers all four KPIs at once. Not exported; not caller-configurable. |
| `KPI_TIMEOUT_MS` | `number` (module constant, `posthog.ts`) | `20_000` | Deadline for the KPI query, via its own `AbortController`, counted from when the query starts. Not exported; not caller-configurable. |
| `timeoutMs` | `number` (`hogqlRows` argument) | caller-supplied | Deadline for one HogQL query from any caller; the lease is held for this plus `HOGQL_LEASE_GRACE_MS`. |
| `HOGQL_LEASE_GRACE_MS` | `number` (module constant, `posthog.ts`) | `1_000` | How long past a query's own timeout its lease is held, so the abort can land and unwind. |
| `HOGQL_LEASE_POLL_MS` | `number` (module constant, `posthog.ts`) | `50` | How often a thread waiting on the other thread's lease looks again. |

