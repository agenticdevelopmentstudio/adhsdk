
**Project selection**

- **list-projects**: The loader MUST list every project the token can see through `listProjects(env)`, which walks `GET /v9/projects` pages (limit 100, at most 20 pages).
- **candidate-filter**: A project MUST be a candidate only when it has an `id` and a `name` and `isProductionProject` is true. `isProductionProject` excludes a name ending in `-staging` or `-testing` (case-insensitive) and a project whose production alias is a `staging.` or `testing.` host. A name such as `testing-production` is still production.
- **domain-lookup**: For each candidate the loader MUST resolve a domain with `fetchProjectPrimaryDomain(token, teamId, name)` (the canonical pick among the project's verified, non-redirecting custom domains, excluding `*.vercel.app`), falling back to `productionDomain(project)` (the first production alias that does not end in `.vercel.app`) when the lookup returns null.
- **domain-lookup-concurrency**: Domain lookups MUST run with at most 6 at once.
- **domain-lookup-failure**: A failed domain lookup MUST NOT fail the section. `fetchProjectPrimaryDomain` answers null when the project has no verified custom domain that is not a redirect, and when the lookup failed (403, 5xx, timeout) with no cached list; a failed lookup answers from the last cached list when there is one. While the shared Vercel cooldown is in force the lookup does not call the API and is answered as a failure. In every null case the alias fallback applies.
- **listed-filter**: After the domain is known, a project whose domain is a `staging.` or `testing.` host MUST be dropped, uncounted and unqueried. The remaining projects are the `listed` set.
- **enabled-rule**: A project MUST count as enabled when `analyticsEnabled` is true: `webAnalytics.enabledAt` is set and `webAnalytics.disabledAt` is not.
- **no-projects**: An empty project list MUST give an empty roster, `projectsTotal` 0 and zero totals, with no error.
- **projects-total**: `projectsTotal` MUST be the size of the listed set and `projectsEnabled` the number of enabled projects in it.

**Window parameters**

- **window-day-dates**: For a day window, `since` and `until` MUST be sent as `YYYY-MM-DD` dates (the first 10 characters of the ISO string), because the API takes dates for whole days.
- **window-hour-instants**: For an hour window, `since` and `until` MUST be sent as full ISO instants, because hourly buckets need instants to be told apart.
- **team-id**: Requests MUST carry `teamId` when `VERCEL_TEAM_ID` is set, and authenticate with a bearer `VERCEL_API_TOKEN`.

**Count phase**

- **count-call**: For every enabled project the loader MUST call `GET /v1/query/web-analytics/visits/count` with `projectId` and the window parameters, at most 6 projects at once.
- **count-values**: A count answer's `data.pageviews` and `data.visitors` MUST default to 0 when absent.
- **count-failure**: A project whose count call fails with any error other than a rate limit MUST be counted in `failed`, and MUST NOT fail the section.
- **count-all-failed**: When at least one project is enabled and every count failed, the loader MUST throw `Error("every Vercel analytics call failed")`.
- **count-none-enabled**: When no project is enabled, the loader MUST NOT throw; `failed` is 0 and the totals are 0.
- **rate-limit-ends-load**: A `VercelRateLimited` error from the project list, count or breakdown phase MUST end the whole load and reject the section. Domain lookups never throw it (see `domain-lookup-failure`), so when a lookup is the one that hits a 429, the load ends at the next `vercelGet` call after the cooldown is recorded. Further calls do not run, because each call checks the shared cooldown first and throws.

**Breakdown phase**

- **breakdown-targets**: Only projects whose count has `pageviews` above 0 MUST get breakdowns, at most 6 projects at once.
- **breakdown-calls**: Each such project MUST be queried with five calls to `GET /v1/query/web-analytics/visits/aggregate`, with `by` set to the window unit (`hour` or `day`), `country`, `referrerHostname`, `requestPath` and `deviceType`, each with `limit` 100 and the window parameters. 100 is the API's maximum; the default of 10 would cut a 30-day series short.
- **breakdown-parallel**: A project's five calls MUST run in parallel and settle independently.
- **breakdown-rate-limit**: If any of the five rejected with `VercelRateLimited`, the loader MUST rethrow it, because settling the calls would otherwise hide it.
- **breakdown-short**: If any of the five rejected for another reason, the project MUST still be included, its failed calls MUST contribute empty data, its `incomplete` MUST be true, and the section's `incomplete` count MUST go up by 1.
- **breakdown-not-failed**: A short breakdown MUST NOT add to `failed`: the project's count is in the totals, and what is short is its series and lists.
- **project-traffic-shape**: Each project entry MUST carry `project` (the project name), `domain`, `pageviews`, `visitors` (from the count call), `series` (the aligned day or hour series of pageviews), the four lists `countries`, `referrers`, `paths`, `devices`, and `incomplete`.
- **series-alignment**: A project's `series` MUST be its aggregate rows aligned onto `window.buckets` by their `timestamp` field, summing `pageviews`, with missing buckets zero-filled and a non-numeric `pageviews` read as 0.

**Marginals**

- **marginal-by-column**: `shapeMarginal(rows, by)` MUST read each row's dimension value from the column named `by`.
- **marginal-others-dropped**: A row whose value is `"Others"` MUST be left out, because past its limit Vercel folds the rest into that row, which is not a page or a country and cannot be summed across projects as if it were one.
- **marginal-none-name**: A row whose value is not a string or is the empty string MUST be named `"(none)"`.
- **marginal-pageviews**: A row's `pageviews` MUST be `Number(row.pageviews)`, or 0 when that is not a number.
- **marginal-sort**: The result MUST be sorted by `pageviews`, highest first.
- **marginal-columns**: The breakdowns MUST read `country`, `referrerHostname`, `requestPath` and `deviceType` as their `by` columns, and publish them as `countries`, `referrers`, `paths` and `devices`.

**Assembly**

- **totals-from-traffic**: `totals.pageviews` and `totals.visitors` MUST be the sums over projects that had traffic (those with breakdowns), not over all counted projects.
- **series-sum**: Section-level `pageviews` and `visitors` MUST be the sum, per bucket, over every project's aggregate rows using the `pageviews` and `visitors` fields, aligned to the window buckets.
- **projects-sort**: `projects` MUST be sorted by `pageviews`, highest first.
- **roster-membership**: `roster` MUST list every listed project, whether or not analytics is on or it had traffic.
- **roster-entry**: Each roster entry MUST carry `project`, `domain`, `analyticsOn`, and the project's counted `pageviews` and `visitors`, or `null` for both when the project has no count.
- **roster-null-cases**: A project with analytics off, or whose count call failed, MUST have no count, so its roster entry MUST hold `null`, which is not a zero.
- **roster-sort**: `roster` MUST be sorted by `pageviews` descending, with a missing count (null) after every number including 0, and ties broken by `project` name with `localeCompare`.
- **section-buckets**: `buckets` MUST be the window's buckets.
- **section-counters**: The section MUST carry `failed` (count calls that failed), `incomplete` (projects with short breakdowns), `projectsTotal` and `projectsEnabled`.

**Side effects**

- **network-only**: The loader's only side effects MUST be HTTP calls to the Vercel API (the project list, domain lookups, counts, aggregates); it MUST NOT write files or storage.
- **domain-cache**: Domain lookups SHOULD share an hour-long per-project cache inside `fetchProjectPrimaryDomain`'s module, so repeated loads do not repeat the domains call.
- **rate-limit-recording**: A 429 answer from a call made through `vercelGet` MUST record the shared cooldown (`noteRateLimited("vercel", retry-after)`) and throw `VercelRateLimited`; the cooldown is honored by the deploy poll as well.
- **per-call-timeout**: Each analytics call MUST be bounded by a 20-second timeout, and each domain lookup by 5 seconds, both set in the shared clients.
- **no-retry**: The loader MUST NOT retry a call. Retrying a section is left to the sectioned-dashboard cache ([adhsdk.ingredient.status.service.telemetry.dashboard.sectioned-dashboard](cookbook:af0bacb9-bc1f-4773-85f5-35e33ae590ab)), which re-runs the section after its retry delay when `failed > 0` or `incomplete > 0`.

