
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

