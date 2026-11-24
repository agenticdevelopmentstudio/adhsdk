
Vectors 001 and 002 are also traced to `telemetry-dashboards.int.test.ts` (routes with no provider configured); vectors 001 to 021 are traced to `telemetry-dashboard-set.test.ts`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dashboard-set-001 | analytics-shape, analytics-sections | `analytics('7d')` with no provider configured | `configured` `{ posthog: false, vercel: false }`, every section in the empty state, `refreshing` false |
| dashboard-set-002 | errors-sections, errors-shape | `errors()` with no provider configured | Empty `issues`, `sites`, `detail` and `runtime`; no failure |
| dashboard-set-003 | runtime-in-request | `errors()` with Vercel configured and a store read | `runtime.data` is the report and `updatedAt` equals its `readAt` |
| dashboard-set-004 | runtime-failure | `errors()` with Vercel configured and a store that throws `boom` | `runtime` is `{ data: null, error: 'boom', updatedAt: null }`; the other sections are unaffected |
| dashboard-set-005 | analytics-shape | `analytics('7d')` with no provider configured | `range` is `7d` and `generatedAt` is an ISO timestamp |
| dashboard-set-006 | views-memoized | Two `analytics('24h')` calls with PostHog and Vercel both configured and no section published between them | The same `views` object both times |
| dashboard-set-007 | views-memoized | `analytics('24h')` then `analytics('7d')` | Independent memos; one range's views never reused for the other |
| dashboard-set-008 | settle-never-starts | `settleAnalytics('24h', 1000)` before any read | Resolves true at once and starts no refresh |
| dashboard-set-009 | settle-analytics | A PostHog refresh that outlasts `timeoutMs` | Resolves false once `timeoutMs` has elapsed (with fake timers, after advancing by exactly `timeoutMs`); the refresh keeps running |
| dashboard-set-010 | vercel-incomplete | A Vercel result with `failed` 1 | Shown as data without an error, retried after 60 seconds (the default retry, with a fake clock advanced by 60 seconds), not after 10 minutes |
| dashboard-set-011 | errors-refreshing | GlitchTip refreshing, sites idle | `refreshing` true, `refreshingSources` `{ glitchtip: true, posthog: false }` |
| dashboard-set-012 | single-instance | `createDashboardSet(config, storage)` with a spy on every loader | No loader and no network call runs at construction |
| dashboard-set-013 | analytics-never-waits | `analytics('24h')` with a PostHog loader that never resolves | The call returns at once with empty sections and `refreshing` true |
| dashboard-set-014 | analytics-refreshing | PostHog idle, Vercel refreshing for `7d` | `analytics('7d').refreshing` is true |
| dashboard-set-015 | providers-independent | A PostHog loader that never resolves and a Vercel loader that resolves | The `vercel` section publishes while the PostHog sections stay empty |
| dashboard-set-016 | analytics-ttl | A fully successful GlitchTip refresh, then reads at 59 and 61 seconds | No refresh at 59 seconds, a new one at 61 seconds; the PostHog caches stay fresh until 10 minutes |
| dashboard-set-017 | window-per-refresh | A sites refresh for `errors()` with PostHog configured, whatever the analytics range | The sites loaders get the `30d` window, computed from the current time |
| dashboard-set-018 | configured-predicates | `analytics('24h')` with PostHog configured, then with it unconfigured | The second call reports `configured.posthog` false and reads no PostHog cache |
| dashboard-set-019 | runtime-not-a-view-input | Two `errors()` calls whose `runtime` objects differ, with `sites` and `detail` unchanged | The same `views` object both times |
| dashboard-set-020 | settle-errors | A GlitchTip refresh in flight and a sites refresh in flight, both finishing within `timeoutMs` | `settleErrors(timeoutMs)` resolves true after both settle |
| dashboard-set-021 | resolved-counter-shared | Two GlitchTip refreshes with the same credentials | Both use the same `resolvedCounter`, so the second reuses the cached resolved-issue count |
