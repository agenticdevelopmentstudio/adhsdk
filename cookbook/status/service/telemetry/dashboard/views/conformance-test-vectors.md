
Vectors views-001 to views-037 come from `dashboard-views.test.ts`; each ID names the test it summarizes. Vectors views-038 and later give literal inputs and expected values that follow from the requirements.

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
| views-038 | site-key, project-key | `siteKey("  WWW.X.com ")`, `siteKey("www.www.x.com")`; `projectKey` of a project with domain `WWW.x.com`, and of a project named `odd-name` with domain null | `x.com`; `www.x.com`; `x.com`; `odd-name` |
| views-039 | site-names-sorted, tiebreak-comparator | `sortSiteNames(["b.com", "a.com"])` | `["a.com", "b.com"]`; the input list is unchanged |
| views-040 | add-series | `addSeries([1, 2, 3], [4])` | `[5, 2, 3]` |
| views-041 | join-sort | Two joined rows with equal pageviews, keys `b.com` and `a.com` | `a.com` then `b.com` |
| views-042 | join-key, join-merge, join-side-by-side | PostHog host `www.x.com` with 10 pageviews, and a Vercel project with domain `x.com` and 7 pageviews | One row keyed `x.com`; PostHog pageviews 10 and Vercel pageviews 7, not 17 |
| views-043 | vital-limits | `vitalRating("lcp", 2500)`, `2501`, `4000`, `4001`; `vitalRating("cls", 0.1)`, `0.25`, `0.26` | `good`, `fair`, `fair`, `poor`; `good`, `fair`, `poor` |
| views-044 | series-labels, series-gap | PostHog buckets `["d1", "d2"]`, Vercel buckets `["d2", "d3"]` | Labels `["d1", "d2", "d3"]`; PostHog is `null` at `d3` and Vercel is `null` at `d1` |
| views-045 | breakdown-topics, breakdown-null | Topic `browsers` with a PostHog dimension row and Vercel projects; then topic `countries` with null dimension rows | The first has only PostHog's list and `null` for Vercel; the second has `null` for PostHog |
| views-046 | error-row-id | Error row `name` `E`, all other fields null; failed request `status` 0, `method` null, `path` `/a` | `["E",null,null,null,null]`; `[0,null,"/a"]` |
| views-047 | merge-rows | Rows for hosts `www.x.com` (count 2, `lastSeen` `2026-11-04T10:00:00Z`) and `x.com` (count 3, `lastSeen` `2026-11-04T12:00:00Z`) with the same name, merged for site `x.com` | One row: `host` `x.com`, `count` 5, `lastSeen` `2026-11-04T12:00:00Z` |
| views-048 | merge-rows | The same two rows, one with `lastSeen` null | `lastSeen` is the non-null value |
| views-049 | most-errors | Sites `b.com` (3 errors, 1 failure), `a.com` (3 errors, 1 failure), `c.com` (3 errors, 2 failures) and `d.com` (0 errors) | Order `c.com`, `a.com`, `b.com`; `d.com` is dropped |
| views-050 | errors-chart | A site whose detail `days` hold only zeros, then a site with no detail section | `chart` is `null` in both cases |
| views-051 | analytics-views-reports | Health for host `WWW.Only-Health.com` and no traffic | `siteReports` has the key `only-health.com`; `sites` does not list it |
