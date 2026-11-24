
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
| dash-types-013 | export-runtime-types | Import `RuntimeErrorGroup` and `RuntimeErrorsReport` from the module | Both resolve as types from `../types` |
| dash-types-014 | no-behavior, export-range-constant, export-view-constants | List the runtime (value) exports of the module | Exactly `ANALYTICS_RANGES`, `DIMENSIONS`, `VERCEL_BREAKDOWNS` and `VITALS`; nothing else exists at runtime |
| dash-types-015 | series-length | A `TrafficSection` for `"24h"` with traffic in only one hour | `buckets` has 25 entries; `pageviews`, `sessions` and each `sites[].series` have 25 values, the quiet hours being 0 |
| dash-types-016 | vercel-project-incomplete | A project whose `paths` breakdown call fails while its pageview count succeeds | `incomplete` true; `pageviews` still the whole count; `paths` short or empty |
| dash-types-017 | vercel-failed-count | Two enabled projects, one of whose counts cannot be read | `failed` is 1; `totals` cover only the readable project, and the unreadable project's roster entry has `pageviews` and `visitors` null |
| dash-types-018 | error-issue-active | Issues at levels `error`, `warning` and `null`, all seen 1 hour ago, then one `error` issue last seen 48 hours ago | Only the first `error` issue is `active`; with the error feed frozen, the 48-hour-old `error` issue is `active` too |
| dash-types-019 | issues-by-type | Three unresolved issues: two of type `TypeError` (4 and 6 events), one of type `SyntaxError` (1 event) | `summary.byType` holds `{ name: "TypeError", issues: 2, events: 10 }` and `{ name: "SyntaxError", issues: 1, events: 1 }` |
| dash-types-020 | site-error-detail-truncated | More error rows than the row cap | `truncated` true; the rarest rows are absent |
| dash-types-021 | dimensions-truncated | More dimension rows than the row cap | `DimensionsSection.truncated` true; the tail is missing from every breakdown |

