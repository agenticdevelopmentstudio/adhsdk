
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dash-types-001 | export-range-constant, mirror-constants | Test "offer the same ranges" in `dashboard-types-parity.test.ts`: the mirror's `ANALYTICS_RANGES` and the server's | Equal arrays, `["24h", "7d", "30d"]` |
| dash-types-002 | export-view-constants, mirror-constants | Test "name the same breakdowns and vitals": `DIMENSIONS`, `VERCEL_BREAKDOWNS`, `VITALS` from both sides | Each pair equal, in order: `["country","device","browser","referrer"]`, `["countries","referrers","paths","devices"]`, `["lcp","inp","cls","fcp"]` |
| dash-types-003 | mirror-parity, analytics-response-fields, errors-response-fields | Type check of the `responsesAgree` tuple in the parity test | Compiles only when the five server and mirror types are mutually assignable |
| dash-types-004 | analytics-response-fields, analytics-configured | `analytics("7d")` with neither provider configured | `range` `"7d"`, `configured` `{ posthog: false, vercel: false }`, `refreshing` false, every section `{ data: null, error: null, updatedAt: null }` |
| dash-types-005 | analytics-refreshing | PostHog dashboard refreshing, Vercel idle | `refreshing` true |
| dash-types-006 | errors-refreshing, errors-response-fields | GlitchTip idle, site health refreshing | `refreshing` true; `refreshingSources` `{ glitchtip: false, posthog: true }` |
| dash-types-007 | errors-runtime-source | Vercel not configured | `sections.runtime` is `{ data: null, error: null, updatedAt: null }` |
| dash-types-008 | traffic-buckets, traffic-sites | A `TrafficSection` for range `"7d"` | `buckets` has 7 entries; `pageviews` and `sessions` have 7 values; each `sites[].series` has 7 values |
| dash-types-009 | vercel-roster-null | A project with analytics off | Its roster entry has `analyticsOn` false and `pageviews` and `visitors` null, not 0 |
| dash-types-010 | site-failed-request-row | A request with no response | `status` is 0 |
| dash-types-011 | issues-resolved-null, issues-complete | GlitchTip's resolved count unreadable and list walk cut short | `summary.resolved` null; `summary.complete` false |
| dash-types-012 | generated-at | Any response | `generatedAt` parses as an ISO 8601 date-time |
| dash-types-013 | no-behavior, export-runtime-types | Import `RuntimeErrorGroup` and `RuntimeErrorsReport` from the module | Both resolve as types from `../types` |

