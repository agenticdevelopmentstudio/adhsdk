
Vectors 001 to 014 are traced to `telemetry-dashboard-sections.test.ts` (PostHog shapers, `loadSiteErrorDetail` and `loadTraffic`); 015 and later are in `telemetry-dashboard-sections.test.ts` and `telemetry-posthog-sections-queries.test.ts`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| posthog-sections-001 | traffic-shape | Rows for two hosts over a bucket axis | Totals sum the aligned series, which here holds every row; `sites` biggest first, each with its own series |
| posthog-sections-002 | dimension-shape | Rows with blank device and referrer, and a row count at the limit | `Unknown` and `$direct` labels, `truncated` true |
| posthog-sections-003 | vitals-shape | A host row with LCP 1200, a null INP, CLS `"0.1"` and FCP 800 | `inp` null, not 0; `cls` 0.1 |
| posthog-sections-004 | health-shape | Row `["a.com", 1, 100, 2, null]` | `{ host: "a.com", errors: 1, requests: 100, failures: 2, p95Ms: null }` |
| posthog-sections-005 | site-detail-shape | Rows for one host on some of the buckets | `errors` and `failures` series zero-filled to every bucket |
| posthog-sections-006 | site-detail-shape | An error row with no feature, step, boundary or page | Those fields null |
| posthog-sections-007 | failure-definition, site-detail-shape | A request row with status 0 | Kept as status 0, a request with no response |
| posthog-sections-008 | production-hosts, failure-definition | `loadSiteErrorDetail` with a stubbed fetch | Three queries, each containing `NOT LIKE 'staging.%'`; the requests query contains the 500-or-0 predicate |
| posthog-sections-009 | site-detail-truncated, row-caps | The requests query answers 5,000 rows | `truncated` true; `requests` has 5,000 rows |
| posthog-sections-010 | site-detail-truncated | All three queries answer nothing | `truncated` false |
| posthog-sections-011 | failure-throws | Fetch answers HTTP 504 | `loadTraffic` rejects with a message containing `HTTP 504` |
| posthog-sections-012 | utc-only | `loadTraffic` for `24h` and `7d`, and `loadSiteErrorDetail` for `30d` | Every `toStartOf...(...)` and `toDateTime(...)` in the queries ends with `, 'UTC')` |
| posthog-sections-013 | site-detail-sequence | Fetch answers HTTP 503 | `loadSiteErrorDetail` rejects with `HTTP 503` after exactly one fetch call |
| posthog-sections-014 | one-at-a-time | `loadSiteErrorDetail` and `loadTraffic` started together | At most one fetch in flight at any time |
| posthog-sections-015 | metric-coercion | Counts `'7'`, `null`, `'abc'` | 7, 0, 0 |
| posthog-sections-016 | closed-inputs, named-properties | The queries of every loader | No query contains `SELECT properties`, and each interpolated value is a constant, a UTC time or a name from the closed list |
| posthog-sections-017 | bucket-unit | `bucketStart('hour')` and `bucketStart('day')` | `toStartOfHour(timestamp, 'UTC')` and `toStartOfDay(timestamp, 'UTC')` |
| posthog-sections-018 | since-bound | `since` of a window whose `since` is `2026-01-02T03:04:05Z` | `timestamp >= toDateTime('2026-01-02 03:04:05', 'UTC')` |
| posthog-sections-019 | traffic-alignment | A traffic row whose bucket timestamp is off the axis, and a bucket with no row | The off-axis point is dropped from the series and from `totals`; the empty bucket is 0 |
| posthog-sections-020 | paths-shape | `loadPaths` rows `['', '', 3]` and `['a.com', '/x', 2]` | `{ host: '(unknown)', path: '/', pageviews: 3 }` and `{ host: 'a.com', path: '/x', pageviews: 2 }` |
| posthog-sections-021 | row-caps | `loadVitals` and `loadSiteHealth` queries | Each ends with `LIMIT 200`; the traffic, dimension, path and detail queries end with `LIMIT 5000` |
| posthog-sections-022 | query-per-section | Any loader with a stubbed `hogqlRows` | The call is made with timeout 45000 and no other transport |
