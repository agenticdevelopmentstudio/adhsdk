
Vectors 001 and 002 are the runtime assertions in `dashboard-types-parity.test.ts`; vector 003 is its compile-time check. The rest are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dtypes-001 | ranges-list, mirror-constants | test "offer the same ranges": the web `ANALYTICS_RANGES` and the server's | equal lists `["24h","7d","30d"]` |
| dtypes-002 | dimensions-list, vercel-breakdowns-list, vitals-list, mirror-constants | test "name the same breakdowns and vitals": the three web lists and the server's | each pair equal, in order |
| dtypes-003 | mirror-parity | type check: the exported `responsesAgree` tuple of five mutual-assignability checks | compiles only while the analytics response, errors response, runtime report and both views agree; fails the type check otherwise |
| dtypes-004 | section-keeps-data, section-error-null | a section after a success and then a failure | `data` still holds the earlier answer, `error` holds the failure text, `updatedAt` is the earlier fetch time |
| dtypes-005 | section-error-null, section-updated-at | a section before any attempt finishes | `data`, `error` and `updatedAt` all `null` |
| dtypes-006 | series-per-bucket | traffic with 7 buckets | `pageviews` and `sessions` each have 7 values, and each site's `series` has 7 |
| dtypes-007 | null-is-not-zero | roster entry with analytics off | `analyticsOn` false, `pageviews` and `visitors` `null` |
| dtypes-008 | failed-request-status-zero | a failed-request row with `status` 0 | read as "no response", not an HTTP status |
| dtypes-009 | errors-envelope | errors response with `refreshingSources` of glitchtip true and posthog false | `refreshing` true |
| dtypes-010 | chart-series-nullable | chart series whose vercel list is `null` | there is no Vercel series for the chart; a `null` inside a list is a gap, not a zero |
| dtypes-011 | views-sites, views-site-reports | views with `sites` `["a.com"]` | `siteReports` is an object keyed by site name, and a client reads `a.com` with an own-key lookup |
| dtypes-012 | runtime-window | runtime report | `window` is `"24h"` |
| dtypes-013 | rated-vitals | rated vitals row with a vital that has no sample | that vital's rating is `null` |

| dtypes-014 | section-shape | analytics response | `sections` holds `traffic`, `dimensions`, `paths`, `vitals`, `health` and `vercel`, each with `data`, `error` and `updatedAt` |
| dtypes-015 | analytics-sections | analytics response | exactly the six sections `traffic`, `dimensions`, `paths`, `vitals`, `health`, `vercel` |
| dtypes-016 | errors-sections | errors response | exactly the four sections `issues`, `sites`, `detail`, `runtime` |
| dtypes-017 | envelope-common | either response | carries `generatedAt`, `refreshing`, `configured` and `views` |
| dtypes-018 | analytics-envelope | analytics response | carries `range` and `configured` flags for `posthog` and `vercel` |
| dtypes-019 | truncated-flags | dimensions section with `truncated` true | read as "the tail is missing from every breakdown" |
| dtypes-020 | incomplete-flags | Vercel project with `incomplete` true | `series` and lists may be short; `pageviews` is still whole |
| dtypes-021 | rated-health | rated health row | a site health row plus `failureRateHigh` |
| dtypes-022 | views-null-sections | views built while the vitals section has no data | `vitals` is `null`, read as "nothing to show" |
| dtypes-023 | site-error-ids | site error and failed-request views | each row carries an `id` |
| dtypes-024 | views-failures | a failed PostHog section | `failures` lists an entry with source `"PostHog"`, what failed and the error text |
| dtypes-025 | types-only | importing the module | only the four lists exist at run time; nothing else runs at load |
| dtypes-026 | series-per-bucket | traffic for the `24h` range | 25 buckets, and `pageviews` and `sessions` each have 25 values |
| dtypes-027 | views-absent-older-backend | response from an older backend with no `views` | the client shows nothing for views and does not throw |
| dtypes-028 | vercel-incomplete-series | Vercel project with `incomplete` true | its `series` may be shorter than `buckets` |
