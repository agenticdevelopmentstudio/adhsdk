
**Module exports**

- **export-range-constant**: The module MUST re-export `ANALYTICS_RANGES` from `ranges.ts`: `"24h"`, `"7d"`, `"30d"`.
- **export-view-constants**: The module MUST re-export `DIMENSIONS` (`country`, `device`, `browser`, `referrer`), `VERCEL_BREAKDOWNS` (`countries`, `referrers`, `paths`, `devices`) and `VITALS` (`lcp`, `inp`, `cls`, `fcp`) from `views.ts`.
- **export-view-types**: The module MUST re-export these types from `views.ts`: `AnalyticsViews`, `BreakdownTopic`, `ChartSeries`, `Dimension`, `ErrorsSiteChart`, `ErrorsSiteReport`, `ErrorsViews`, `JoinedSite`, `RatedHealth`, `RatedVitalsRow`, `SectionFailure`, `SiteBreakdown`, `SiteErrorView`, `SiteFailedRequestView`, `SiteReport`, `VercelBreakdown`, `VercelProjectBar`, `Vital` and `VitalRating`.
- **export-runtime-types**: The module MUST re-export `RuntimeErrorGroup` and `RuntimeErrorsReport` from `../types`.
- **no-behavior**: The module MUST NOT contain runtime logic beyond the four constant re-exports (`ANALYTICS_RANGES`, `DIMENSIONS`, `VERCEL_BREAKDOWNS`, `VITALS`); every other export is a type.

**Analytics response**

- **analytics-response-fields**: `AnalyticsDashboardResponse` MUST carry `generatedAt` (ISO string), `refreshing` (boolean), `range` (an `AnalyticsRange`), `configured` (`{ posthog: boolean; vercel: boolean }`), `sections` and `views`.
- **analytics-sections-shape**: `sections` MUST be `DashboardSections<AnalyticsSectionData>`, so each of `traffic`, `dimensions`, `paths`, `vitals`, `health` and `vercel` is a `{ data, error, updatedAt }` section.
- **analytics-section-data**: `AnalyticsSectionData` MUST map `traffic` to `TrafficSection`, `dimensions` to `DimensionsSection`, `paths` to an array of `PathRow`, `vitals` to an array of `VitalsRow`, `health` to an array of `SiteHealthRow`, and `vercel` to `VercelTrafficSection`.
- **analytics-refreshing**: `refreshing` MUST be true when either provider's dashboard is refreshing, and false when neither is. `dashboard-set.ts` computes it as `Boolean(ph?.refreshing || vc?.refreshing)`.
- **analytics-configured**: `configured` MUST say which providers are set up. A provider that is not configured contributes sections in the initial empty state (`data` null, `error` null, `updatedAt` null) and no refresh.
- **analytics-views**: `views` MUST hold what the pages draw, derived on the server from `sections` by `views.ts`.

**Errors response**

- **errors-response-fields**: `ErrorsDashboardResponse` MUST carry `generatedAt`, `refreshing`, `refreshingSources` (`{ glitchtip: boolean; posthog: boolean }`), `configured` (`{ glitchtip: boolean; posthog: boolean; vercel: boolean }`), `sections` and `views`.
- **errors-sections-shape**: `sections` MUST be `DashboardSections<ErrorsSectionData>`, with `issues` (`ErrorsIssuesSection`), `sites` (array of `SiteHealthRow`), `detail` (`SiteErrorDetailSection`) and `runtime` (`RuntimeErrorsReport`).
- **errors-refreshing**: `refreshing` MUST be true when either `refreshingSources.glitchtip` or `refreshingSources.posthog` is true, and false when neither is.
- **errors-runtime-source**: The `runtime` section MUST be the Vercel runtime errors of the last 24 hours, read from the store; its body is the same as `GET /errors/runtime`. It is read fresh on each request, and without Vercel configured it holds the empty section state.
- **errors-views**: `views` MUST hold what the per-site pages draw, derived on the server.
- **generated-at**: `generatedAt` MUST be an ISO 8601 string of when the response was built (the server clock for analytics, the passed-in `nowMs` for errors).

**PostHog sections**

- **traffic-buckets**: `TrafficSection.buckets` MUST be the ISO bucket starts of the range window: 25 hourly buckets for `"24h"` (the partial hour it starts in and the current one), and one UTC-day bucket per day for `"7d"` (7) and `"30d"` (30), including today; `pageviews` and `sessions` MUST each hold one value per bucket.
- **series-length**: Every per-bucket array (`pageviews`, `sessions`, `series`, `errors`, `failures`, `visitors`) MUST have the same length as its section's `buckets`; a bucket with no data is a zero.
- **traffic-totals**: `TrafficSection.totals` MUST carry `pageviews` and `sessions`. `sessions` sums per-bucket uniques, so a session spanning two buckets counts twice.
- **traffic-sites**: `TrafficSection.sites` MUST be a list of `{ host, pageviews, sessions, series }`, with `series` one value per bucket.
- **dimensions-row**: `DimensionRow` MUST carry `host`, `device`, `browser`, `country`, `referrer` (strings) and `pageviews` (number).
- **dimensions-truncated**: `DimensionsSection.truncated` MUST be true when the row cap was hit, which means the tail is missing from every breakdown.
- **path-row**: `PathRow` MUST carry `host`, `path` and `pageviews`.
- **vitals-row**: `VitalsRow` MUST carry `host`, `samples` and four metrics `lcp`, `inp`, `cls`, `fcp`, each a number or null.
- **site-health-row**: `SiteHealthRow` MUST carry `host`, `errors`, `requests`, `failures` and `p95Ms` (a number or null).

**Vercel section**

- **marginal-shape**: `Marginal` MUST carry `name` and `pageviews`.
- **vercel-project-traffic**: `VercelProjectTraffic` MUST carry `project`, `domain` (string or null), `pageviews`, `visitors`, `series` (numbers), the four lists `countries`, `referrers`, `paths`, `devices` (each a list of `Marginal`) and `incomplete`.
- **vercel-project-incomplete**: `incomplete` MUST be true when a breakdown call failed, which makes `series` and the lists short while `pageviews` is still whole.
- **vercel-roster-entry**: `VercelRosterEntry` MUST describe one production project whether or not it has analytics on or any traffic: `project`, `domain`, `analyticsOn`, `pageviews`, `visitors`.
- **vercel-roster-null**: `VercelRosterEntry.pageviews` and `visitors` MUST be null when analytics is off or the count could not be read; null is not a zero.
- **vercel-section-fields**: `VercelTrafficSection` MUST carry `buckets`, `projectsTotal`, `projectsEnabled`, `failed`, `incomplete`, `roster`, `totals` (`{ pageviews, visitors }`), `pageviews`, `visitors` and `projects`.
- **vercel-production-only**: `projectsTotal` MUST count only production projects; staging and testing MUST NOT be counted.
- **vercel-failed-count**: `failed` MUST count projects whose count could not be read, which makes `totals` and the roster short.
- **vercel-incomplete-count**: `incomplete` MUST count projects included in `totals` whose breakdowns could not all be read, which makes the series and lists short.

**Errors sections**

- **error-issue-fields**: `ErrorIssue` MUST carry `id`, `shortId` (or null), `title`, `type` (the exception class, or null), `source` (the raising file when GlitchTip knows, or null), `level` (or null), `count`, `userCount`, `firstSeen` and `lastSeen` (or null), `release` (or null), `project`, `permalink` (or null) and `active`.
- **error-issue-active**: `active` MUST use the same test that puts an error on the board, `errorCountsAsProblem` in `board/derive-problems.ts`: the issue's project is on the board's project allowlist (when one is set), its level is a judged level (`error` or `fatal`, compared case-insensitively), and it was seen within the activity window (24 hours). While the error feed is frozen the recency test is suspended, so a judged-level issue stays active.
- **issues-section**: `ErrorsIssuesSection` MUST carry `buckets`, `issues` and `summary`.
- **issues-summary**: `summary` MUST carry `active`, `backlog`, `events`, `resolved`, `complete`, `byType` and `newPerDay`.
- **issues-resolved-null**: `summary.resolved` MUST be null when the resolved count could not be read.
- **issues-complete**: `summary.complete` MUST be false when GlitchTip's list could not be walked to its end.
- **issues-by-type**: `summary.byType` MUST be a list of `{ name, issues, events }`.
- **issues-new-per-day**: `summary.newPerDay` MUST hold currently unresolved issues counted by the day they first fired.
- **site-error-row**: `SiteErrorRow` MUST carry `host`, `name`, `feature`, `step`, `boundary`, `page` (each of the last four a string or null), `count` and `lastSeen`. PostHog holds no message text, only these names.
- **site-failed-request-row**: `SiteFailedRequestRow` MUST carry `host`, `status`, `method` (or null), `path`, `count` and `lastSeen`. A `status` of 0 means the request never got a response.
- **site-error-days**: `SiteErrorDays` MUST carry `host` and two series, `errors` and `failures`, each with one value per bucket.
- **site-error-detail**: `SiteErrorDetailSection` MUST carry `buckets`, `days`, `errors`, `requests` and `truncated`; it backs each site's own page.
- **site-error-detail-truncated**: `truncated` MUST be true when a row cap was hit, which means the rarest errors or failed requests are missing.

**Parity with the client mirror**

- **mirror-parity**: The client mirror MUST be mutually assignable with these types for `AnalyticsDashboardResponse`, `ErrorsDashboardResponse`, `RuntimeErrorsReport`, `AnalyticsViews` and `ErrorsViews`. A renamed field, a changed nullability or a different union member breaks it.
- **mirror-constants**: The mirror's `ANALYTICS_RANGES`, `DIMENSIONS`, `VERCEL_BREAKDOWNS` and `VITALS` MUST equal the server's lists, in the same order.
- **mirror-check-is-types**: The type half of the parity check is verified by a type check, not by the test run, because the test runner transpiles without type-checking.

