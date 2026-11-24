---
id: 55ffb81c-6a7d-4837-9180-0b5d3fe952ec
title: "Vercel Traffic Section"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Loads Vercel Web Analytics for every production project over a range window: roster, per-project counts and breakdowns, summed series, with partial-failure accounting."
platforms:
  - typescript
  - web
tags:
  - status
  - telemetry
  - dashboard
  - vercel
depends-on:
  - af0bacb9-bc1f-4773-85f5-35e33ae590ab
  - f06a7f7a-1b36-4dfc-a17d-71d20d576155
  - 60ff967b-b041-4723-913e-016fba7bae6d
related: []
references:
  - https://vercel.com/docs/analytics/web-analytics-api
approved-by: ""
approved-date: ""
---

# Vercel Traffic Section

## Overview

`vercel-section.ts` produces the `vercel` section of the analytics dashboard: Vercel Web Analytics read through the REST API (`https://vercel.com/docs/analytics/web-analytics-api`). HTTP, the cooldown and project classification live in [adhsdk.ingredient.status.service.telemetry.vercel-api](cookbook:60ff967b-b041-4723-913e-016fba7bae6d). It uses the same token as the deploy poll, so it shares that token's quota and honors the shared 429 cooldown.

The API is per project, and only production projects are read at all. Counts run for every project with analytics on; the costlier breakdowns run only for projects that had traffic, because most have none.

The module exports `loadVercelTraffic(env, w)`, `analyticsEnabled(project)` and `shapeMarginal(rows, by)`. It returns a `VercelTrafficSection` (see the dashboard wire types recipe, [adhsdk.ingredient.status.service.telemetry.dashboard.types](cookbook:f06a7f7a-1b36-4dfc-a17d-71d20d576155)). The sectioned-dashboard cache ([adhsdk.ingredient.status.service.telemetry.dashboard.sectioned-dashboard](cookbook:af0bacb9-bc1f-4773-85f5-35e33ae590ab)) calls the loader and treats a section as short when `failed > 0` or `incomplete > 0`.

The work happens in phases: list the projects, resolve each candidate's domain, count visits for each enabled project, break down each project that had traffic, then assemble totals, a roster and the summed series.

## Behavioral Requirements

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

## Appearance

Not applicable — this is a data loader, not a visual component.

## States

Not applicable — this is a data loader, not a visual component. It runs once per call and holds no state between calls beyond the shared cooldown and the domain cache described above.

## Accessibility

Not applicable — this is a data loader, not a visual component.

## Conformance Test Vectors

Vectors vercel-001 to vercel-017 come from the "Vercel section" block of `telemetry-dashboard-sections.test.ts`, which stubs `fetch` per URL. Vectors vercel-018, vercel-019 and vercel-020 are not yet covered by tests there; they follow from the requirements. `w` is the 7d window at 2026-11-04T15:30:20Z.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| vercel-001 | enabled-rule | Test "only a project with analytics on, and not since disabled, counts": `{ webAnalytics: { enabledAt: 1 } }`, `{ enabledAt: 1, disabledAt: 2 }`, `{}` | `true`, `false`, `false` |
| vercel-002 | domain-lookup | Test "the domain is the first alias that isn't a vercel.app one": aliases `["x.vercel.app", "x.com"]`, then `["x.vercel.app"]` | `"x.com"`, then `null` |
| vercel-003 | candidate-filter | Test "a project is production unless its name ends in staging or testing": `site-production`, `site-staging`, `site-testing`, `testing-production`, and `x` with alias `staging.x.com` | `true`, `false`, `false`, `true`, `false` |
| vercel-004 | candidate-filter, projects-total, enabled-rule, roster-membership | Test "staging and testing are neither counted nor queried": four projects, two production (one enabled) | `projectsTotal` 2, `projectsEnabled` 1, roster `["a-production", "b-production"]`; only project `prod` queried |
| vercel-005 | roster-entry, roster-null-cases, roster-sort | Test "the roster lists every production project, busiest first...": `one` (5 pageviews), `quiet` (0), `off` (analytics off) | Roster order `one`, `quiet`, `off`; `off` has `pageviews` and `visitors` null |
| vercel-006 | marginal-others-dropped | Test "shapeMarginal drops Vercel's Others rollup": rows `Others` 9 and `/a` 1 by `requestPath` | `[{ name: "/a", pageviews: 1 }]` |
| vercel-007 | marginal-by-column, marginal-none-name, marginal-sort | Test "shapeMarginal reads the value from the `by` column": rows US 1, FR 2, no country 3 | `(none)` 3, `FR` 2, `US` 1 |
| vercel-008 | domain-lookup | Test "finds the domain of a project whose latest deployment only has vercel.app aliases": domains API returns `deploying.example.com` | Roster domain `deploying.example.com` |
| vercel-009 | domain-lookup-failure | Test "falls back to the alias when the domains API cannot be read": domains API answers 403, alias `aliased.example.com` | Roster domain `aliased.example.com` |
| vercel-010 | listed-filter, projects-total | Test "drops a project whose real domain turns out to be staging": domains API returns `staging.example.com` | Roster `[]`, `projectsTotal` 0 |
| vercel-011 | count-call, breakdown-targets, breakdown-calls, totals-from-traffic, series-sum, project-traffic-shape, team-id | Test "counts every enabled project, breaks down only those with traffic": 3 projects, 2 enabled, only `p1` has 5 pageviews and 2 visitors | `projectsTotal` 3, `projectsEnabled` 2, `failed` 0, totals 5 and 2, last series values 5 and 2, one project; aggregate calls only for `p1`, all with `limit` 100, `by` values `country`, `day`, `deviceType`, `referrerHostname`, `requestPath`; `teamId` is `team` |
| vercel-012 | window-day-dates, window-hour-instants | Test "asks for hourly buckets with instants, whole days with dates": 7d window, then 24h window | Count `since` is `2026-10-29`; then `2026-11-03T15:00:00.000Z` |
| vercel-013 | count-failure | Test "a project whose calls fail is counted, not silently zero": `p2` answers 503 | `failed` is 1 |
| vercel-014 | breakdown-short, breakdown-not-failed | Test "a failed breakdown marks the project incomplete, and keeps its count whole": the `day` aggregate answers 504 | `failed` 0, `incomplete` 1, `totals.pageviews` 5, project `one` has `incomplete` true |
| vercel-015 | count-all-failed | Test "every count failing fails the section": every non-list call answers 503 | Rejects with `every Vercel analytics call failed` |
| vercel-016 | rate-limit-ends-load, rate-limit-recording | Test "stays off a token that is cooling down": `noteRateLimited("vercel", "60")` first | Rejects with a message containing `rate limited`; no calls reach the API |
| vercel-017 | breakdown-rate-limit, rate-limit-ends-load | Test "a 429 in a breakdown fails the section and stops the calls not yet made": 8 busy projects, `b0` answers 429 | Rejects with `rate limited`; no aggregate calls for `b6` or `b7` |
| vercel-018 | count-none-enabled | Projects listed but none with analytics on | Resolves with `failed` 0, `projectsEnabled` 0, totals 0 |
| vercel-019 | roster-sort | Two projects with equal pageviews named `b` and `a` | Roster order `a`, `b` |
| vercel-020 | no-projects | The project list is empty | Empty roster, `projectsTotal` 0, zero totals, no error |

## Edge Cases

- **No projects**: See `#requirements/no-projects`.
- **No enabled project**: See `#requirements/count-none-enabled`. The all-failed check needs at least one enabled project.
- **Project with count 0**: Counted and shown in the roster with 0, but no breakdowns are requested for it.
- **Some counts fail**: Those projects are counted in `failed` and show `null` in the roster. Totals and series are then short, and the sectioned-dashboard cache retries the section after its short delay.
- **All counts fail**: The section rejects, so the dashboard keeps its last good data and shows the error.
- **A breakdown call fails**: The project stays in the totals, its `incomplete` is true, and the lists for the failed calls are empty (see `#requirements/breakdown-short`).
- **Rate limit (429)**: Ends the whole load in any phase. Workers that already started may finish, but later calls throw at the cooldown check.
- **Rate limit during domain lookup**: `fetchProjectPrimaryDomain` records the cooldown but returns a domain or null instead of throwing, so the load continues until the next Vercel call throws at the cooldown check. In the test "stays off a token that is cooling down" the cooldown is already set before the load, so the project list call throws first.
- **Project list failure**: An error from `listProjects` (HTTP error, timeout, rate limit) is not caught here and rejects the section.
- **Aggregate limit**: With 100 rows per call, a project with more than 100 distinct values in a dimension gets the remainder folded into `"Others"`, which is dropped from the list. For the series the limit of 100 covers the 30 daily or 25 hourly buckets.
- **Timestamps off the axis**: Series rows whose `timestamp` does not match a bucket start are dropped by `alignToBuckets`, in both a project's series and the summed series.
- **Domain differs between listings**: A project whose API alias is `*.vercel.app` mid-deployment still gets its custom domain from the domains API, so the roster domain does not depend on whether a deploy is in progress.
- **Missing name or id**: A listed project without an `id` or `name` is not a candidate and does not appear anywhere.
- **Non-numeric counts**: A count answer with no `data` yields 0 pageviews and 0 visitors. Aggregate values are coerced with `Number(...) || 0`.
- **Concurrent access**: The loader uses a counter (`failed`, `incomplete`) that parallel workers increment. JavaScript runs those increments one at a time, so no lock is needed. Two loads at once (for different ranges) share the cooldown and the domain cache and make independent calls.
- **Offline or unreachable API**: Each call fails with a network error. Counts then fail and, if every enabled project failed, the section throws; the cache keeps stale data.
- **Retry**: None here; see `#requirements/no-retry`.

## Configuration

Not applicable beyond the arguments and constants below: the loader reads no settings file; its credentials come in through `env`.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `env.VERCEL_API_TOKEN` | string | none | Bearer token; shared with the deploy poll |
| `env.VERCEL_TEAM_ID` | string | none | Adds `teamId` to every request when set |
| `w` | `RangeWindow` | none | The window to read: `since`, `until`, `unit`, `buckets` |
| `CONCURRENCY` | constant | 6 | Maximum parallel domain lookups, counts and project breakdowns |
| `AGGREGATE_LIMIT` | constant | `"100"` | Rows per aggregate call; the API's maximum |

## Deep Linking

Not applicable: the loader has no URLs or routes of its own; it calls the Vercel REST API.

## Localization

Not applicable: the loader has no display strings except the log-free error `every Vercel analytics call failed` and the placeholder name `(none)`, both hardcoded English. Names such as countries and paths come from Vercel as given; display names are made later in `views.ts`.

## Accessibility Options

Not applicable: the module is not a visual component, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply to it.

## Feature Flags

Not applicable: the source reads no flags. Whether Vercel is configured is decided by the caller (`dashboard-set.ts`).

## Analytics

Not applicable as an emitter: the module sends no events; it reads another service's analytics.

## Privacy

- **Data collected**: Aggregate site statistics (page view and visitor counts, country, referrer host, path and device type per project) read from Vercel Web Analytics. No individual visitor is identified.
- **Storage**: In memory, in the sectioned-dashboard cache; the domain cache keeps project domain names for one hour.
- **Transmission**: The API token is sent as a bearer token to `api.vercel.com`; the token is not logged or placed in the returned section.
- **Retention**: Until the next refresh replaces the section; nothing is persisted by this module.

## Logging

Not applicable: the module makes no log calls. Failures surface as `failed` and `incomplete` counts or as a thrown error that the sectioned-dashboard cache logs.

## Platform Notes

- **SwiftUI**: Port with `URLSession` async calls and a `TaskGroup` limited to 6 child tasks (add the next task as one finishes). Decode responses with `Codable`. Run a project's five aggregate calls with `async let` and collect each as a `Result`, so one failure leaves the others usable. Represent the rate limit as a distinct `Error` type and rethrow it from the group. Format the day-window dates with a UTC `ISO8601DateFormatter` (date-only options).
- **Compose**: Use Ktor or OkHttp with coroutines. Limit concurrency with a `Semaphore(6)` and run the five aggregate calls with `async` plus `runCatching`. Make the rate-limit error a dedicated exception that is rethrown, and cancel the scope on it. Parse with `kotlinx.serialization`.
- **React/Web**: This is the source platform. `vercel-section.ts` in `packages/web/packages/status-server/src/telemetry/dashboard/` uses global `fetch` through `vercelGet` in `vercel-api.ts`, `mapLimit` from `@adh-sdk/deploy-platform/util` and `Promise.allSettled`. The tests stub `fetch` with `vi.stubGlobal`.
- **AppKit / UIKit**: The same Swift port serves both. Keep it off the main thread (an actor or background `Task`) and hand the finished section to the views.
- **WinUI 3**: Port as a C# service class. Call the Vercel API with a shared `HttpClient` (one instance, with `BaseAddress` `https://api.vercel.com`, a bearer `AuthenticationHeaderValue`, and a per-call `CancellationTokenSource` with a 20-second `CancelAfter`). Parse with `System.Text.Json` (`JsonDocument` or typed records with `JsonNamingPolicy.CamelCase`). Limit concurrency with `SemaphoreSlim(6)` around `Task.Run` calls awaited with `Task.WhenAll`, or `Parallel.ForEachAsync` with `MaxDegreeOfParallelism = 6`. Run the five aggregates with `Task.WhenAll` over tasks that each catch their own exception and return a result record, which is the `Promise.allSettled` equivalent, then rethrow a `VercelRateLimitedException` if any carries one. Keep the failure counters in `Interlocked.Increment`, since .NET workers do run in parallel, unlike the single-threaded source. Sort with `OrderByDescending(...).ThenBy(p => p.Project, StringComparer.CurrentCulture)` to match `localeCompare`, treating null as lower than 0. Take the date-only window values with `ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)` on a UTC `DateTimeOffset` and instants with `ToString("o")`-style UTC strings. Return immutable records and expose them to a view through `INotifyPropertyChanged` or an `ObservableCollection` marshalled on the `DispatcherQueue`. Expose the loader to the rest of the app as a port, an interface that takes the environment and a window and returns the section; how the cache and views call it is specified in [adhsdk.ingredient.status.service.telemetry.dashboard.sectioned-dashboard](cookbook:af0bacb9-bc1f-4773-85f5-35e33ae590ab).

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-server/src/telemetry/dashboard/vercel-section.ts` | confirmed (1.0.2) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |
| web | `packages/web/packages/deploy-platform/src/providers/vercel.ts` | confirmed (1.0.2) |

## Design Decisions

**Decision**: Only production projects are read, and a project whose real domain is `staging.` or `testing.` is dropped after the domain lookup.
**Rationale**: Every site is three Vercel projects (`x-production`, `x-staging`, `x-testing`) and analytics runs only on the first, so the other two are not sites to report on. The domain check catches projects whose name does not follow the pattern (the project named `odd-name` in the test "drops a project whose real domain turns out to be staging").
**Approved**: pending

**Decision**: The domain comes from the domains API first and the production alias second.
**Rationale**: The domain joins Vercel's numbers to PostHog's, so it cannot depend on whether the project happens to be mid-deployment, when its aliases are only `*.vercel.app`.
**Approved**: pending

**Decision**: Counts run for every enabled project, but breakdowns only for projects with traffic.
**Rationale**: Most projects have no traffic, and the breakdowns cost five calls per project.
**Approved**: pending

**Decision**: `aggregate` sends `limit` 100.
**Rationale**: 100 is the API's maximum, and the default of 10 would cut a 30-day series short.
**Approved**: pending

**Decision**: Hourly windows send instants, daily windows send dates.
**Rationale**: The API takes dates for whole days, and hourly buckets need instants or the API cannot tell the hours apart.
**Approved**: pending

**Decision**: The `"Others"` row is dropped from the breakdown lists.
**Rationale**: It is not a page or a country, and it cannot be summed across projects as if it were the same thing.
**Approved**: pending

**Decision**: A failed breakdown is `incomplete`, not `failed`.
**Rationale**: The project's count is in the totals, and what is short is its series and lists. The two counters let the dashboard say which numbers are short.
**Approved**: pending

**Decision**: A 429 ends the whole load instead of being recorded per project.
**Rationale**: Every further call would 429 too, so a rate limit ends the whole read. The loader rethrows it from the breakdown phase because `Promise.allSettled` would otherwise hide it, and each call checks the cooldown so workers already running stop making new calls.
**Approved**: pending

**Decision**: When every count fails, the section throws instead of returning zeros.
**Rationale**: A section of zeros would look like a real quiet day. A thrown error keeps the last good data on screen and shows the error, which is the sectioned-dashboard contract.
**Approved**: pending

**Decision**: Totals sum only projects that had traffic, while the roster shows every listed project.
**Rationale**: The totals are computed over the projects with breakdowns; a project with count 0 adds nothing to a sum either way, and the roster is where a quiet or disabled project still appears (with 0 or null).
**Approved**: pending

**Decision**: The loader does not retry calls.
**Rationale**: Retry belongs to the sectioned-dashboard cache, which schedules the next attempt with backoff when `failed` or `incomplete` is above 0. Retrying inside would spend more of a shared token quota.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.access-patterns.rate-limit-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/aed555ee-66e3-5f99-88ab-24674ed5c789) | passed | access-patterns |
| [adc.check.access-patterns.retry-with-backoff](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bcb17bfe-d2d6-53f3-b2af-06b7eea3da61) | partial | access-patterns |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | passed | access-patterns |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | passed | security |

Separation of concerns passes: the file shapes Vercel's answers into the section, with HTTP, the cooldown and project classification in `vercel-api.ts`, the axis in `ranges.ts` and caching in the sectioned-dashboard module. Unit-test coverage passes: the Vercel block of `telemetry-dashboard-sections.test.ts` has a test for every vector, covering selection, domain resolution, counts, breakdowns, window parameters, the roster tie-break, the no-enabled-project and empty-list cases, partial and total failure and the 429 paths. Rate-limit handling passes: the shared cooldown is checked before every call and a 429 ends the load. Retry with backoff is partial: this module does not retry, and the retry with backoff is done one layer up by the sectioned-dashboard cache. Timeout configuration passes: calls are bounded at 20 seconds and domain lookups at 5 seconds in the shared clients. Graceful degradation passes: a project whose count or breakdown fails is reported through `failed` and `incomplete` and the rest of the section is returned. Secure transport passes: all calls go to `https://api.vercel.com` with a bearer token.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (telemetry-dashboard-sections.test.ts, 20 of 20 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Reworded descriptive requirements with RFC 2119 keywords, added a no-projects requirement and vector, narrowed rate-limit-ends-load, marked unit-test coverage partial, rewrote design rationales as reasons, linked the dependencies, and set references to the Vercel API doc. |
