
**Site identity**

- **tiebreak-comparator**: Every alphabetical sort and every name tiebreak in this module (`sortSiteNames`, `join-sort`, `marginal-sort`, `errors-site-rows`, `most-errors`, `merge-rows`) MUST use one comparator: a locale-aware string comparison with the fixed locale `en`. The source calls `localeCompare` with no locale argument, so its order follows the host's default locale; a port MUST fix `en` so every platform sorts the same way.

- **site-key**: `siteKey(host)` MUST trim, lower-case and strip one leading `www.`, so `WWW.X.com ` and `x.com` are one site.
- **project-key**: `projectKey(project)` MUST be `siteKey(domain)` when the project has a domain, and the project name otherwise.
- **site-names-sorted**: `sortSiteNames` MUST return a new list sorted alphabetically with the tiebreak comparator, so a site stays where the reader last found it.

**Failure rate and health**

- **failure-rate-threshold**: `FAILURE_RATE_HIGH` MUST be 0.05. `isFailureRateHigh(failures, requests)` MUST be true only when `requests > 0` and `failures / requests >= 0.05`; a site that served nothing is never high.
- **rated-health**: A rated health row MUST be the health row plus `failureRateHigh`.
- **merge-health**: `mergeHealth(seen, site)` MUST return a copy of `site` when `seen` is null; otherwise it keeps `seen.host`, adds `errors`, `requests` and `failures`, and takes the larger `p95Ms`. Percentiles do not add, so p95 is the worse one; when exactly one side is null the other is used; both null stays null.
- **add-series**: `addSeries(a, b)` MUST add element-wise to the longer length, reading a missing element as 0.

**Joined sites**

- **join-key**: `joinSites(traffic, vercel, health)` MUST give one row per site key, where PostHog rows key by `siteKey(host)` and Vercel projects by `projectKey`.
- **join-merge**: Several hosts or projects of one site MUST be merged: pageviews, sessions and visitors add and series add with `addSeries`.
- **join-side-by-side**: PostHog and Vercel counts MUST stay side by side and never be summed, because they measure different things and a site reporting to both would count every visit twice.
- **join-null-provider**: A provider that has not seen a site MUST be `null` on that row, not zeros. A provider whose section is null contributes no rows.
- **join-health-no-add**: Health MUST attach only to a row that traffic already created; health alone MUST NOT add a row, because that would add every API host. Attached health is merged across hosts with `mergeHealth` and rated.
- **join-sort**: Rows MUST be sorted by the larger of the two providers' pageviews, descending, with ties broken by key ascending with the tiebreak comparator.

**Pageview chart**

- **series-labels**: `pageviewSeries(traffic, vercel, site)` MUST put both providers on the sorted union of their bucket labels.
- **series-gap**: A label a provider's axis lacks MUST be `null` (a gap), never 0, because the sections are fetched separately and around a day boundary their axes can differ by a bucket.
- **series-site**: With `site` null each provider contributes its section's aggregate `pageviews`; with a site it contributes the sum of the matching rows' series (PostHog by `siteKey(host)`, Vercel by `projectKey`).
- **series-absent**: A provider whose section is null, or that has no row for the site, MUST be `null` rather than a list.

**Marginals**

- **country-name**: `countryName(code)` MUST return the English region name for a two-letter upper-case code, and the input unchanged for anything else (including lower-case or longer codes) and when the region lookup has no name.
- **marginal-sort**: Every marginal list MUST be sorted by `pageviews` descending, ties by name ascending with the tiebreak comparator.
- **dimension-totals**: `dimensionTotals(rows, dimension, site)` MUST sum `pageviews` by the dimension's value over rows of the chosen site (all rows when `site` is null). The dimensions are `country`, `device`, `browser` and `referrer`.
- **dimension-words**: A referrer of `$direct` MUST be named `Direct`, and a country code MUST be passed through `countryName`.
- **path-totals**: `pathTotals(rows, site)` MUST sum `pageviews` by path. With `site` null the name MUST be `siteKey(host)` followed by the path, because `/` is a different page on each site; with a site it is the bare path.
- **vercel-totals**: `vercelTotals(projects, breakdown, site)` MUST sum the chosen breakdown (`countries`, `referrers`, `paths`, `devices`) over the projects of the site (all when null).
- **vercel-words**: Vercel's values MUST be worded as PostHog's panels are: countries through `countryName`, referrer `(none)` as `Direct`, devices with the first letter upper-cased, and paths prefixed with the site key when no site is chosen and bare otherwise.
- **breakdown-topics**: `breakdownTotals(topic, dimensionRows, pathRows, projects, site)` MUST answer for the topics `pages`, `countries`, `referrers`, `devices` and `browsers`. `pages` reads PostHog's paths and Vercel's `paths`; `countries`, `referrers` and `devices` read the matching dimension and Vercel breakdown; `browsers` has only PostHog's side because Vercel reports none.
- **breakdown-null**: A provider whose input is `null`, or that has no Vercel field for the topic, MUST be `null`; an input that is present but empty gives an empty list, not `null`.

**Web vitals**

- **vital-limits**: `vitalRating(vital, value)` MUST be `good` when the value is at or below the first limit, `fair` when at or below the second, and `poor` above. The limits are Google's Core Web Vitals boundaries: `lcp` 2500 and 4000, `inp` 200 and 500, `cls` 0.1 and 0.25, `fcp` 1800 and 3000.
- **rate-vitals**: `rateVitals(row)` MUST return the row plus `site` (the host's site key) and a `ratings` record with an entry for each of `lcp`, `inp`, `cls` and `fcp`, where an unmeasured (null) vital is rated `null`.

**Site list**

- **analytics-sites**: `analyticsSites(sections)` MUST list, alphabetically and without duplicates, every site any of these name: traffic-joined sites, every Vercel roster entry (so a project with analytics off or no domain stays findable), vitals hosts, PostHog dimension hosts and path hosts.
- **analytics-sites-no-health**: Health alone MUST NOT add a site.
- **analytics-sites-empty**: With nothing answered the list MUST be empty.

**Site report (Analytics)**

- **report-figures**: `siteReport(sections, site)` MUST give `posthog` as `{ pageviews, sessions }` and `vercel` as `{ pageviews, visitors }` only when at least one of that provider's two figures is above zero for the site; when both are zero, or the provider has no row for the site, the field is `null`.
- **report-health**: `health` MUST be the site's health rows merged with `mergeHealth` and rated, and `null` unless it has requests above 0, errors above 0 or a non-null `p95Ms`. A site with zero errors that served requests keeps its health, because that zero is the finding.
- **report-chart**: `pageviews` MUST be the site's chart from each provider that counted pageviews for it, and `null` when neither did.
- **report-breakdowns**: `breakdowns` MUST list the topics in the order `pages`, `countries`, `referrers`, `devices`, `browsers`, each with the site's bare-path lists, and leave out a provider's empty list (as `null`) and a topic where both are empty.
- **report-projects**: `projects` MUST be the Vercel roster entries whose `projectKey` is the site.
- **report-vercel-incomplete**: `vercelIncomplete` MUST be true when any of the site's Vercel projects is marked `incomplete`, and only that site's projects count.
- **report-vitals**: `vitals` MUST be the site's rated vitals rows.
- **report-empty**: `empty` MUST be true when there is no `posthog`, `vercel` or `health`, no breakdowns, no projects and no vitals. A project with analytics off is a roster entry, so its site is not empty.

**Failures**

- **collect-failures**: `collectFailures(named)` MUST include a section only when its `data` is null and its `error` is not null, grouped by source and identical error text with the `what` labels in input order. A section holding last-good data is not a failure, because its card shows.
- **section-failures**: `sectionFailures(sections, configured)` MUST consider the PostHog sections `traffic` (what: traffic), `paths` (pages), `dimensions` (breakdowns), `health` (health) and `vitals` (web vitals), and the Vercel section `vercel` (traffic), and skip every section of a provider that is not configured.

**Analytics views**

- **analytics-views-shape**: `analyticsViews(sections, configured)` MUST return `sites`, `joined`, `pageviews` (the all-sites chart), `pages`, `dimensions`, `vercelProjects`, `vercelBreakdowns`, `vitals`, `siteReports` and `failures`.
- **analytics-views-null**: `pages`, `dimensions`, `vercelProjects`, `vercelBreakdowns` and `vitals` MUST be `null` until their provider section has answered, and not an empty value. `dimensions` is a record over `country`, `device`, `browser` and `referrer`; `vercelBreakdowns` over `countries`, `referrers`, `paths` and `devices`.
- **analytics-views-projects**: `vercelProjects` MUST list only projects with pageviews above 0, in Vercel's section order, each as `{ site, project, pageviews, visitors }` where `site` is the project key.
- **analytics-views-reports**: `siteReports` MUST have a report for every listed site and also for every host that has health, keyed by `siteKey(host)` (the same key as the listed sites), so a deep link to a health-only host still draws.
- **analytics-views-joined**: `joined` MUST be built with the health rows, so the Sites table rates failures.

**Errors views**

- **errors-site-rows**: `errorsSiteRows(sections)` MUST merge the `sites` rows by site key (host set to the key), rate them, and sort by `requests` descending, ties by host ascending with the tiebreak comparator.
- **most-errors**: `mostErrorSites(sections, limit)` MUST drop sites with zero errors, sort by `errors` descending, then `failures` descending, then host ascending with the tiebreak comparator, and keep at most `limit`. `MOST_ERRORS_LIMIT` MUST be 10 and the default limit.
- **errors-sites**: `errorsSites(sections)` MUST list alphabetically every site named by the `sites` rows or by the detail's `days`, `errors` or `requests`, and be empty before anything loads.
- **error-row-id**: `errorRowId` MUST be the JSON array string of `name`, `feature`, `step`, `boundary`, `page`; `failedRequestRowId` the JSON array of `status`, `method`, `path`.
- **merge-rows**: Rows of one site's hosts with the same id MUST merge into one row with `host` set to the site, `count` added and `lastSeen` the later of the two (by `Date.parse`; a null yields the other; when either value does not parse, the comparison is false and the already accumulated row's value is kept). The result MUST be sorted by `count` descending, ties by id ascending with the tiebreak comparator, and each row MUST carry its `id`.
- **errors-chart**: `chart` MUST sum the site's per-day `errors` and `failures` series over the detail buckets, and be `null` when the detail is missing or every value is 0.
- **errors-report**: `errorsSiteReport(sections, site)` MUST give `health` (null unless requests or errors are above 0), `chart`, `errors`, `requests` and `empty` (true when all four are empty or null).
- **errors-site-failures**: `errorsSiteFailures` MUST name the `sites` section (site totals) and the `detail` section (errors and failed requests), both from PostHog, by the rule of `collect-failures`.
- **errors-views**: `errorsViews(sections, configured)` MUST return `sites`, `mostErrors`, `mostErrorsLimit`, one `siteReports` entry per listed site, and `siteFailures`, which MUST be empty when PostHog is not configured.

**Side effects**

- **pure**: The module MUST perform no I/O, read no clock and mutate none of its inputs; sorting copies the list first.

