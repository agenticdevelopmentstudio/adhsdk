
Dashboard Formatting is a set of six pure functions that word what the status server derived for the Analytics and Errors pages. They are presentation only: the source's header comment says every join, sort, threshold and rating happens on the server and arrives in the response's `views`. The module has no state, no I/O and no dependency beyond two types from the dashboard wire types (an analytics range, and a web vital).

It exports:

- **the bucket-label function** (`bucketLabel`) — takes an ISO timestamp and an analytics range and returns the short axis label: `HH:mm` for the `24h` range, otherwise a short month and day.
- **the bucket-detail function** (`bucketDetail`) — the same bucket for a tooltip or table, with the time zone stated.
- **the vital-formatting function** (`formatVital`) — takes a web vital and a number and returns the value in its unit.
- **the listed-sites function** (`listedSites`) — takes a dashboard response body, or `undefined`, and returns the server's site list or `null`.
- **the with-site function** (`withSite`) — places one extra site name into that list.
- **the site-report function** (`siteReportFor`) — returns the server's report for the site a URL names, or a caller-supplied "none" value.

The callers are the analytics and errors pages and the board shell, which feeds the site rail from `listedSites` and `withSite`. For general number and duration formatting see Format ([adhsdk.ingredient.status.dashboard.logic.format](cookbook:564c6102-e100-41ad-9c92-14606a33c394)); this module covers only the dashboard-specific wording.

### API

- `bucketLabel(iso: string, range: AnalyticsRange): string` — `iso` is an ISO 8601 timestamp for the start of a bucket; `range` is `"24h"`, `"7d"` or `"30d"`, and `"24h"` chooses the hour format while any other value takes the day format.
- `bucketDetail(iso: string, range: AnalyticsRange): string` — the same parameters as `bucketLabel`.
- `formatVital(vital: Vital, value: number): string` — `vital` is `"lcp"`, `"inp"`, `"cls"` or `"fcp"` and picks the unit; `value` is the raw measurement.
- `listedSites(body: { views?: { sites?: string[] } } | undefined): string[] | null` — a dashboard response body, or the absence of one.
- `withSite(sites: readonly string[], site: string | null): string[]` — the server's list and the site the URL names.
- `siteReportFor<T>(reports: Readonly<Record<string, T>>, site: string, none: T): T` — the server's per-site reports, the URL's site, and what to return when there is none.
