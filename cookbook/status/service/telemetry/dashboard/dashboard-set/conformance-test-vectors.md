
Vectors 001, 002 and 005 are traced to `telemetry-dashboards.int.test.ts` (routes with no provider configured); the rest follow the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dashboard-set-001 | analytics-shape, analytics-sections | `analytics('7d')` with no provider configured | `configured` `{ posthog: false, vercel: false }`, every section in the empty state, `refreshing` false |
| dashboard-set-002 | errors-sections, errors-shape | `errors()` with no provider configured | Empty `issues`, `sites`, `detail` and `runtime`; no failure |
| dashboard-set-003 | runtime-in-request | `errors()` with Vercel configured and a store read | `runtime.data` is the report and `updatedAt` equals its `readAt` |
| dashboard-set-004 | runtime-failure | `errors()` with Vercel configured and a store that throws `boom` | `runtime` is `{ data: null, error: 'boom', updatedAt: null }`; the other sections are unaffected |
| dashboard-set-005 | analytics-shape | `GET /analytics/dashboard?range=forever` | The route answers 400 `invalid range` before the set is called; the set itself takes only `24h`, `7d`, `30d` |
| dashboard-set-006 | views-memoized | Two `analytics('24h')` calls with PostHog and Vercel both configured and no section published between them | The same `views` object both times |
| dashboard-set-007 | views-memoized | `analytics('24h')` then `analytics('7d')` | Independent memos; one range's views never reused for the other |
| dashboard-set-008 | settle-never-starts | `settleAnalytics('24h', 1000)` before any read | Resolves true at once and starts no refresh |
| dashboard-set-009 | settle-analytics | A PostHog refresh that outlasts `timeoutMs` | Resolves false after about `timeoutMs`; the refresh keeps running |
| dashboard-set-010 | vercel-incomplete | A Vercel result with `failed` 1 | Shown as data without an error, retried after the retry delay, not after 10 minutes |
| dashboard-set-011 | errors-refreshing | GlitchTip refreshing, sites idle | `refreshing` true, `refreshingSources` `{ glitchtip: true, posthog: false }` |

