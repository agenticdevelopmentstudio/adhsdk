
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

