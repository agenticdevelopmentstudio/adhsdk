
### Constants

- **ranges-list**: `ANALYTICS_RANGES` MUST be exactly `"24h"`, `"7d"`, `"30d"`, in that order, and `AnalyticsRange` MUST be derived from it.
- **dimensions-list**: `DIMENSIONS` MUST be exactly `"country"`, `"device"`, `"browser"`, `"referrer"`, in that order.
- **vercel-breakdowns-list**: `VERCEL_BREAKDOWNS` MUST be exactly `"countries"`, `"referrers"`, `"paths"`, `"devices"`, in that order.
- **vitals-list**: `VITALS` MUST be exactly `"lcp"`, `"inp"`, `"cls"`, `"fcp"`, in that order.
- **vital-rating-values**: A vital rating MUST be one of `"good"`, `"fair"` or `"poor"`; a missing rating is `null`, not a fourth value.
- **breakdown-topics**: A breakdown topic MUST be one of `"pages"`, `"countries"`, `"referrers"`, `"devices"` or `"browsers"`.

### Sections

- **section-shape**: Every section MUST carry `data`, `error` and `updatedAt`, each nullable, and a response MUST carry one section for each name in its section-data type (`DashboardSections` maps every name to a `DashboardSection` of that name's data).
- **section-keeps-data**: A client MUST read `data` as the last good answer: it survives a later failure, so stale data stays on screen while `error` carries the reason the latest attempt failed.
- **section-error-null**: `error` MUST be `null` when the latest attempt succeeded or none has finished.
- **section-updated-at**: `updatedAt` MUST be the time `data` was fetched, and `null` while no data has arrived.
- **analytics-sections**: The analytics sections MUST be `traffic`, `dimensions`, `paths`, `vitals`, `health` and `vercel`.
- **errors-sections**: The errors sections MUST be `issues`, `sites`, `detail` and `runtime`.

### Envelope

- **envelope-common**: Both responses MUST carry `generatedAt` (a timestamp string), `refreshing` (a boolean), `configured` (a flag per source) and `views`.
- **analytics-envelope**: The analytics response MUST carry its `range` and `configured` flags for `posthog` and `vercel`.
- **errors-envelope**: The errors response MUST carry `refreshingSources` with a flag each for `glitchtip` and `posthog`, and `refreshing` MUST be true when either is true; `configured` MUST carry flags for `glitchtip`, `posthog` and `vercel`.

### Counts and series

- **series-per-bucket**: Every series on a response (`pageviews`, `sessions`, `visitors`, `series`, `errors`, `failures`) MUST have one value per entry of the `buckets` list beside it, in the same order, except that on an `incomplete` Vercel project (and on the Vercel section when `incomplete` is nonzero) `series` may be short.
- **sessions-sum**: A traffic `sessions` total MUST be read as a sum of per-bucket unique counts, so a session spanning two buckets counts twice.
- **null-is-not-zero**: Fields typed as nullable numbers (a vitals measure, `p95Ms`, a roster's `pageviews` and `visitors`, `resolved`) MUST be read as "unknown or not applicable", never as zero; the source says a roster count is null when analytics is off or the count could not be read.
- **failed-request-status-zero**: A failed-request `status` of `0` MUST be read as a request that never got a response.
- **truncated-flags**: A `truncated` flag (dimensions, per-site error detail) MUST be read as "a row cap was hit, so the tail is missing from every breakdown."
- **incomplete-flags**: `incomplete` on a Vercel project, `incomplete` and `failed` counts on the Vercel section, `vercelIncomplete` on a site report and `complete: false` on the errors summary and the runtime report MUST each be read as "totals or lists may be short".
- **vercel-production-only**: The Vercel section MUST count production projects only; staging and testing are never counted.

### Errors

- **active-rule**: An error issue is `active` by the same test that puts an error on the board: error or fatal level, seen in the last 24 hours.
- **runtime-window**: The runtime report's `window` MUST be the literal `"24h"`, and the runtime section of the errors dashboard MUST have the same body as the runtime errors endpoint.
- **runtime-group-message**: A runtime group's `message` MUST be the first line of the message, at most 200 characters.
- **runtime-group-path**: A runtime group's `path` MUST have numeric, uuid and hash segments replaced by `:id`.
- **runtime-group-key**: A runtime group's `key` MUST be a stable hash of its grouping fields (project, source, method, normalized path, status and first message line).
- **runtime-group-deployment**: A runtime group's `deploymentId` MUST name the deployment the group was last seen on.
- **posthog-no-text**: Site error rows MUST carry error names only, because PostHog holds no message text.

### Views

- **views-derived**: Every join, sort, threshold and rating behind `views` MUST be done by the server, and a client MUST NOT recompute them.
- **views-sites**: Both views MUST carry `sites`, a list of site names.
- **views-site-reports**: Both views MUST carry `siteReports`, an object keyed by site name.
- **rated-health**: A rated health row MUST be a site health row plus `failureRateHigh`, the server's verdict that `failures / requests` is high.
- **rated-vitals**: A rated vitals row MUST be a vitals row plus its `site` and one rating (or `null`) for each vital.
- **chart-series-nullable**: A chart series MUST carry `labels` and a series per source that is either a list of numbers and nulls or `null` as a whole; a null entry is a bucket the provider has not reached on the shared axis, a gap rather than a zero.
- **views-null-sections**: View fields typed as nullable (`pages`, `dimensions`, `vercelProjects`, `vercelBreakdowns`, `vitals`) MUST be read as "the section has no data to show".
- **site-error-ids**: Site error and failed-request views MUST carry an `id`.
- **views-failures**: `failures` (analytics) and `siteFailures` (errors) MUST list each section failure with its source (`"PostHog"` or `"Vercel"`), what failed and the error text.
- **most-errors-limit**: `mostErrorsLimit` MUST be the cap applied to `mostErrors`; the server derives both.

### Parity

- **mirror-parity**: The web copy MUST stay mutually assignable with the server's types for the two responses, the runtime report and both views; a renamed field, changed nullability or changed union member MUST fail the type check.
- **mirror-constants**: The four constant lists MUST equal the server's lists, in value and order.
- **types-only**: Apart from the four lists, the module MUST hold only types and interfaces and MUST NOT run code at load beyond defining those lists.

