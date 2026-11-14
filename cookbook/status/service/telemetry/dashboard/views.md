---
id: 967202ce-c607-4115-9f63-466a4004e7f3
title: "Dashboard Views"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Derives the Analytics and Errors page views from the sections: site joins, rankings, per-site reports, rated vitals and failure lists, so pages only render fields."
platforms:
  - typescript
  - web
tags:
  - status
  - telemetry
  - dashboard
  - views
depends-on: []
related: []
references:
  - packages/web/packages/status-server/src/telemetry/dashboard/views.ts (adhsdk)
  - packages/web/packages/status-server/test/dashboard-views.test.ts (adhsdk)
approved-by: ""
approved-date: ""
---

# Dashboard Views

## Overview

`views.ts` computes every join, sort, threshold and per-site cut that the Analytics and Errors pages draw. PostHog answers per host and Vercel per project; the views join `www.x.com` to `x.com`, join a project to its site, rank, rate a web vital and call a failure rate high once, on the server. The result rides the dashboard response as `views`, so the website only renders fields. Each site's page is in `siteReports`, so opening a site costs no provider query and no second request.

The module is pure: every export is a function of its arguments, with no I/O, no clock and no state. The two entry points are `analyticsViews(sections, configured)` and `errorsViews(sections, configured)`; the rest are the building blocks they and the tests call.

Absence is explicit. A provider that has not answered is `null`, which is different from an answer of zero or an empty list. A site's report leaves out anything it does not have, so the page has no "nothing for this site" states of its own.

## Behavioral Requirements

**Site identity**

- **site-key**: `siteKey(host)` MUST trim, lower-case and strip one leading `www.`, so `WWW.X.com ` and `x.com` are one site.
- **project-key**: `projectKey(project)` MUST be `siteKey(domain)` when the project has a domain, and the project name otherwise.
- **site-names-sorted**: `sortSiteNames` MUST return a new list sorted alphabetically with `localeCompare`, so a site stays where the reader last found it.

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
- **join-sort**: Rows MUST be sorted by the larger of the two providers' pageviews, descending, with ties broken by key ascending (`localeCompare`).

**Pageview chart**

- **series-labels**: `pageviewSeries(traffic, vercel, site)` MUST put both providers on the sorted union of their bucket labels.
- **series-gap**: A label a provider's axis lacks MUST be `null` (a gap), never 0, because the sections are fetched separately and around a day boundary their axes can differ by a bucket.
- **series-site**: With `site` null each provider contributes its section's aggregate `pageviews`; with a site it contributes the sum of the matching rows' series (PostHog by `siteKey(host)`, Vercel by `projectKey`).
- **series-absent**: A provider whose section is null, or that has no row for the site, MUST be `null` rather than a list.

**Marginals**

- **country-name**: `countryName(code)` MUST return the English region name for a two-letter upper-case code, and the input unchanged for anything else (including lower-case or longer codes) and when the region lookup has no name.
- **marginal-sort**: Every marginal list MUST be sorted by `pageviews` descending, ties by name ascending (`localeCompare`).
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
- **analytics-views-reports**: `siteReports` MUST have a report for every listed site and also for every host that has health, so a deep link to a health-only host still draws.
- **analytics-views-joined**: `joined` MUST be built with the health rows, so the Sites table rates failures.

**Errors views**

- **errors-site-rows**: `errorsSiteRows(sections)` MUST merge the `sites` rows by site key (host set to the key), rate them, and sort by `requests` descending, ties by host.
- **most-errors**: `mostErrorSites(sections, limit)` MUST drop sites with zero errors, sort by `errors` descending, then `failures` descending, then host, and keep at most `limit`. `MOST_ERRORS_LIMIT` MUST be 10 and the default limit.
- **errors-sites**: `errorsSites(sections)` MUST list alphabetically every site named by the `sites` rows or by the detail's `days`, `errors` or `requests`, and be empty before anything loads.
- **error-row-id**: `errorRowId` MUST be the JSON array string of `name`, `feature`, `step`, `boundary`, `page`; `failedRequestRowId` the JSON array of `status`, `method`, `path`.
- **merge-rows**: Rows of one site's hosts with the same id MUST merge into one row with `host` set to the site, `count` added and `lastSeen` the later of the two (by `Date.parse`; a null yields the other). The result MUST be sorted by `count` descending, ties by id, and each row MUST carry its `id`.
- **errors-chart**: `chart` MUST sum the site's per-day `errors` and `failures` series over the detail buckets, and be `null` when the detail is missing or every value is 0.
- **errors-report**: `errorsSiteReport(sections, site)` MUST give `health` (null unless requests or errors are above 0), `chart`, `errors`, `requests` and `empty` (true when all four are empty or null).
- **errors-site-failures**: `errorsSiteFailures` MUST name the `sites` section (site totals) and the `detail` section (errors and failed requests), both from PostHog, by the rule of `collect-failures`.
- **errors-views**: `errorsViews(sections, configured)` MUST return `sites`, `mostErrors`, `mostErrorsLimit`, one `siteReports` entry per listed site, and `siteFailures`, which MUST be empty when PostHog is not configured.

**Side effects**

- **pure**: The module MUST perform no I/O, read no clock and mutate none of its inputs; sorting copies the list first.

## Appearance

Not applicable — this is a data-derivation module, not a visual component.

## States

Not applicable — this is a data-derivation module, not a visual component. Loading, stale and error states are the sections' own; the views carry them as `null` fields and `failures`.

## Accessibility

Not applicable — this is a data-derivation module, not a visual component.

## Conformance Test Vectors

Vectors come from `dashboard-views.test.ts`; each ID names the test it summarizes.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| views-001 | site-key | Test "treats www and the apex as one site": `www.x.com` and `x.com` | Both give `x.com` |
| views-002 | failure-rate-threshold | Test "is high at 5% and above, and never on a site that served nothing" | 5 of 100 is high; 4 of 100 is not; 0 of 0 is not |
| views-003 | join-key, join-merge, join-side-by-side | Test "merges a site's hosts and keeps the providers side by side" | One row per site; counts per provider not summed |
| views-004 | join-null-provider | Test "says a provider has not seen a site rather than reporting zero" | Unseen provider is `null` |
| views-005 | join-null-provider | Test "works when one provider has not answered" | Rows from the other provider only |
| views-006 | join-health-no-add | Test "does not let health data add sites with no traffic" | Health-only host adds no row |
| views-007 | merge-health | Test "adds counts across a site's hosts but takes the worse percentile, and rates the joined rate" | Counts add; p95 is the larger; rate judged on the sums |
| views-008 | series-site, series-absent | Tests "gives the aggregate from each provider", "narrows both to one site", "drops a provider that has never seen the site" | Aggregate, narrowed and null cases |
| views-009 | series-gap | Test "leaves a gap where the axes differ, never a false zero" | Union labels; a bucket one provider lacks is `null` |
| views-010 | dimension-totals, marginal-sort | Test "sums one dimension, largest first" | Summed per value, descending |
| views-011 | dimension-totals, site-key | Test "narrows to a site, counting its www host" | The `www` host counts toward the site |
| views-012 | dimension-words | Test "names direct traffic in words" | `$direct` is `Direct` |
| views-013 | path-totals | Test "keeps the host in a path until one site is chosen" | `x.com/` across sites; `/` for one site |
| views-014 | vercel-totals, vercel-words | Tests "sums Vercel's per-project breakdowns", "words Vercel's values the way PostHog's panels do" | Summed; `(none)` is `Direct`; devices capitalized |
| views-015 | country-name | Test "shows a value that is not a country code as it came" | Unchanged |
| views-016 | vital-limits | Test "rates on the published boundaries" | Boundary values are good; just above is fair, then poor |
| views-017 | rate-vitals | Test "rates every measured vital of a row and leaves an unmeasured one unrated" | Null vital has a null rating |
| views-018 | analytics-sites | Test "lists every site alphabetically, whichever provider reported it, as one site however it is spelled" | One sorted list |
| views-019 | analytics-sites | Test "includes a project with analytics off and one with no domain, so neither is unfindable" | Both listed |
| views-020 | analytics-sites-no-health, analytics-sites-empty | Tests "does not add a host that only has health..." and "has nothing to list before anything has answered" | Health-only host absent; empty list |
| views-021 | report-figures, report-health | Test "gathers one site's figures across its hosts: counts add, and p95 is the worse one" | Added counts; larger p95 |
| views-022 | report-chart | Test "charts the site from each provider that counted it" | Both providers charted |
| views-023 | report-vercel-incomplete | Test "says when this site's Vercel breakdown is short, and not another site's" | True for the site only |
| views-024 | report-breakdowns | Tests "lists breakdowns in page order..." and "leaves off a provider's list that is empty, and a card with none" | Order pages to browsers; empties dropped |
| views-025 | report-figures | Test "treats a figure of zero as absent" | Zero figures are `null` |
| views-026 | report-health | Test "keeps zero errors on a site that served requests: that is the finding" | Health kept |
| views-027 | report-empty | Test "is empty for a site nothing knows, and a project with analytics off is not empty" | `empty` true, then false |
| views-028 | section-failures, collect-failures | Tests "names what could not be read, one line per source and error" and "leaves out a section with last-good data..., and a provider that is off" | Grouped failures; last-good and unconfigured left out |
| views-029 | analytics-views-shape, analytics-views-projects | Tests "draws the overview from the sections..." and "lists only the Vercel projects that counted pageviews, named by their site" | Full shape; only projects with pageviews |
| views-030 | analytics-views-reports | Test "has a report for every listed site, and for a host with only health..." | Report for both |
| views-031 | analytics-views-null | Test "answers null, not empty, for a provider that has not answered" | `null` fields |
| views-032 | errors-site-rows | Test "joins www to its site, names the row by its key and puts the busiest first" | Merged, keyed, sorted |
| views-033 | most-errors | Test "ranks sites by errors reported, drops the ones with none and stops at the limit" | Ranked, zeros dropped, limited |
| views-034 | errors-sites | Tests "lists every site alphabetically, whichever section reported it" and "is empty before anything has loaded" | Sorted union; empty |
| views-035 | merge-rows, errors-chart, errors-report | Tests "adds a site's hosts together, and leaves other sites out", "keeps a clean site's health but draws no chart or tables for it", "has nothing for a site nothing reported" | Merged rows; health only; empty |
| views-036 | errors-site-failures | Tests "names what could not be read, one line per error" and "does not count a section still holding last good data" | Named; last-good excluded |
| views-037 | errors-views | Tests "lists the sites, ranks the most errors and reports each listed site" and "reports no read failures for PostHog when PostHog is not configured" | Full shape; empty failures |

## Edge Cases

- **Nothing answered**: Every section null gives empty lists, null optional fields and no reports.
- **Zero versus absent**: Zero figures are absent in a site report, except health on a site that served requests (see `report-health`).
- **Mismatched axes**: Handled by `series-gap`; a bucket a provider has not reached is a gap.
- **Project with no domain**: Keyed by its name, listed through the roster, and its site page is not empty.
- **Mixed-case or `www` hosts**: Normalized by `site-key`.
- **Unmeasured vital**: Null value gives a null rating, not `good`.
- **Unparseable `lastSeen`**: `Date.parse` gives NaN, and the comparison is then false so the first value is kept.
- **Equal counts**: Every sort has an explicit name tiebreak so output is stable.
- **Concurrent access**: Not applicable; the functions are pure and share nothing.
- **Offline or error**: The module does no I/O; a failed section appears in `failures` when it has no last-good data.
- **Retry**: Not applicable; the sections' cache retries.

## Configuration

Not applicable beyond the constants below: the module reads no settings.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `FAILURE_RATE_HIGH` | constant | 0.05 | Failure share at which a rate is high |
| `MOST_ERRORS_LIMIT` | constant | 10 | Sites the Errors overview ranks |
| `configured` | argument | none | `{ posthog, vercel }` flags that decide which failures are reported |

## Deep Linking

Not applicable: the module has no routes. It keys site pages by site key, which is what a page's deep link carries.

## Localization

Not applicable beyond region names: `countryName` uses English display names and the label `Direct` and the failure `what` words are hardcoded English, and Vercel's `(none)` referrer is matched as an English literal. Sorting uses `localeCompare`.

## Accessibility Options

Not applicable: the module is not a visual component.

## Feature Flags

Not applicable: the source reads no flags; `configured` is passed in by the caller.

## Analytics

Not applicable as an emitter: the module sends no events; it derives views of analytics read elsewhere.

## Privacy

- **Data collected**: None. It reshapes aggregate site statistics and error counts already in the sections; no individual is identified.
- **Storage**: None; results are returned and held by the caller.
- **Transmission**: None from this module.
- **Retention**: None.

## Logging

Not applicable: the module makes no log calls.

## Platform Notes

- **SwiftUI**: Port as pure `struct` functions over `Codable` section models; use `Dictionary(grouping:)` and `sorted(by:)` with `localizedStandardCompare`, and `Locale.current.localizedString(forRegionCode:)` for country names (force the English locale to match). Model optional providers as `Optional`, never empty arrays.
- **Compose**: Pure Kotlin functions over data classes; `groupingBy` and `sortedWith(compareByDescending...thenBy...)`; `Locale("", code).getDisplayCountry(Locale.ENGLISH)` for regions.
- **React/Web**: This is the source platform: `views.ts` in the status-server, using `Intl.DisplayNames` for regions, `Map` for totals and `localeCompare` for ties. The website only renders the returned fields.
- **AppKit / UIKit**: The same Swift port serves both; keep it off the main thread and hand the finished views to the UI.
- **WinUI 3**: Port as a static C# class of pure methods over immutable records, with `Dictionary<string, T>` for totals, `OrderByDescending(...).ThenBy(x => x.Name, StringComparer.CurrentCulture)` for sorted lists, and `RegionInfo` (`new RegionInfo(code).EnglishName`, with a try/catch that returns the code unchanged when the code is unknown) for `countryName`. Use nullable reference types (`List<Marginal>?`) so a provider that has not answered stays null. Use `System.Text.Json` to carry the views to the page. Expose the result to XAML through a view model that raises `INotifyPropertyChanged` on the `DispatcherQueue`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-server/src/telemetry/dashboard/views.ts` | confirmed (1.0.0) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Joins, sorts, thresholds and per-site cuts are computed on the server and sent as `views`.
**Rationale**: The header comment says they are computed here "so the website only renders fields", and each site's page is in `siteReports` so opening a site costs no second request.

**Approved**: pending

**Decision**: PostHog and Vercel counts are kept side by side and never summed.
**Rationale**: `joinSites` documents that they measure different things and a site reporting to both would count every visit twice.

**Approved**: pending

**Decision**: A provider with no answer is `null`, not zero or an empty list.
**Rationale**: Several comments say a null "is not the same as a zero", so the page can tell "not seen" from "seen nothing".

**Approved**: pending

**Decision**: When combining hosts, counts add and p95 takes the worse one.
**Rationale**: `mergeHealth` notes that percentiles do not add.

**Approved**: pending

**Decision**: Chart axes are joined on their union, with gaps instead of zeros.
**Rationale**: The sections are fetched separately, so around a day boundary the axes can differ by a bucket; a zero would be a false reading.

**Approved**: pending

**Decision**: Health alone never adds a site to a traffic table or the site list.
**Rationale**: It would add every API host. A health-only host still gets a report so a deep link to it draws.

**Approved**: pending

**Decision**: A failed provider section with no data is reported in `failures`, even on pages that hide absences.
**Rationale**: `sectionFailures` explains that leaving out what a site does not have must not also leave out what we failed to ask about.

**Approved**: pending

**Decision**: Zero counts as absent in a site report, except errors on a site that served requests.
**Rationale**: The `SiteReport` comment says that for such a site, zero is the finding.

**Approved**: pending

**Decision**: Vercel values are reworded to match PostHog's panels.
**Rationale**: `vercelEntryName` says this makes the two read alike side by side.

**Approved**: pending

**Decision**: Site lists are alphabetical, while tables are ranked.
**Rationale**: `sortSiteNames` says a site stays where the reader last found it.

**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.localization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | localization |

Separation of concerns passes: the module only derives views from sections, with fetching in the providers and caching in the sectioned-dashboard module. Unit-test coverage passes: `dashboard-views.test.ts` covers each exported area for both pages. Unicode support passes: names are plain strings sorted with `localeCompare` and region names come from `Intl.DisplayNames`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
