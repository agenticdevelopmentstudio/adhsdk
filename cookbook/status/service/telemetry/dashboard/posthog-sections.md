---
id: 4dc15a9e-c129-412a-9f14-e35146563d8d
title: "PostHog Dashboard Sections"
type: ingredient
version: 1.0.3
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The PostHog half of the dashboards: one HogQL query per section with UTC buckets, a production-host filter and row caps, and a pure shaper for each."
platforms:
  - typescript
  - web
tags:
  - status
  - telemetry
  - dashboard
  - posthog
  - hogql
depends-on:
  - 8648272e-2da3-46fc-b9e8-5148dacdbcff
  - d4e7dd53-4771-425f-af0a-0186ba89c3ef
related:
  - a7c2b9e1-5d4f-4a2c-9e6f-8b3a1c5d7e2f
  - f03325ef-f4c6-43ab-9a88-1a0bf3daa002
references: []
approved-by: ""
approved-date: ""
---

# PostHog Dashboard Sections

## Overview

The PostHog half of the Analytics and Errors dashboards: one HogQL query per section, each with a pure shaper that turns raw rows into the section's wire type. The loaders are `loadTraffic`, `loadDimensions`, `loadPaths`, `loadVitals`, `loadSiteHealth` and `loadSiteErrorDetail`. Each builds a query, runs it through `hogqlRows` (from the PostHog fetcher, [adhsdk.ingredient.status.service.telemetry.fetchers](cookbook:8648272e-2da3-46fc-b9e8-5148dacdbcff)), and passes the rows to a shaper (`shapeTraffic`, `shapeDimensions`, `shapeVitals`, `shapeHealth`, and for the detail `shapeErrorDays`, `shapeSiteErrors` and `shapeFailedRequests`). Two helpers, `bucketStart` and `since`, build the UTC time expressions.

Every value interpolated into a query comes from a closed enum or a `Date`, never from a request string. Queries select named properties only, because `SELECT properties` is what times out. The loaders are handed to the section caches by the dashboard set ([adhsdk.ingredient.status.service.telemetry.dashboard.dashboard-set](cookbook:f03325ef-f4c6-43ab-9a88-1a0bf3daa002)); they never cache anything themselves.

| Loader | Inputs | Row cap | Shaper | Returns |
|--------|--------|---------|--------|---------|
| `loadTraffic` | `PosthogEnv`, `RangeWindow` | 5,000 | `shapeTraffic` | `TrafficSection` |
| `loadDimensions` | `PosthogEnv`, `RangeWindow` | 5,000 | `shapeDimensions` | `DimensionsSection` |
| `loadPaths` | `PosthogEnv`, `RangeWindow` | 5,000 | none (maps rows inline) | `PathRow[]` |
| `loadVitals` | `PosthogEnv`, `RangeWindow` | 200 | `shapeVitals` | `VitalsRow[]` |
| `loadSiteHealth` | `PosthogEnv`, `RangeWindow` | 200 | `shapeHealth` | `SiteHealthRow[]` |
| `loadSiteErrorDetail` | `PosthogEnv`, `RangeWindow` | 5,000 per query | `shapeErrorDays`, `shapeSiteErrors`, `shapeFailedRequests` | `SiteErrorDetailSection` |

The `RangeWindow` comes from `rangeWindow` ([adhsdk.ingredient.status.service.telemetry.dashboard.ranges](cookbook:d4e7dd53-4771-425f-af0a-0186ba89c3ef)).
## Behavioral Requirements

- **query-per-section**: Each section loader MUST issue its queries through `hogqlRows` with a 45,000 ms timeout and no other transport.
- **failure-throws**: When a query fails, the loader MUST throw an `Error` with the message `PostHog: <error>`, so a failed query fails the section instead of reading as no traffic.
- **closed-inputs**: A query MUST interpolate only constants, a `Date`-derived time, or a name from a closed list, and MUST NOT interpolate any request string.
- **named-properties**: A query MUST select named properties, never `properties` as a whole.
- **production-hosts**: Every query MUST apply the `PRODUCTION_HOSTS` filter (see Configuration for its patterns).
- **utc-only**: Every bucket expression (`toStartOfHour` or `toStartOfDay`) and the window lower bound (`toDateTime`) MUST name the `'UTC'` zone, so rows land in the window's buckets whatever zone the PostHog project uses.
- **bucket-unit**: `bucketStart(unit)` MUST be `toStartOfHour(timestamp, 'UTC')` for `hour` and `toStartOfDay(timestamp, 'UTC')` otherwise.
- **since-bound**: `since(window)` MUST be `timestamp >= toDateTime('<UTC instant as YYYY-MM-DD HH:MM:SS>', 'UTC')` from the window's `since` date.
- **row-caps**: The traffic, dimension, path and error-detail queries MUST be limited to 5,000 rows, and the vitals and site-health queries to 200 rows.
- **one-at-a-time**: The process MUST NOT have two HogQL queries in flight at once, including queries from different sections loading together and from the monitor worker thread that adopted the shared lock state, because the PostHog API returns 503 under concurrent load. The rule is kept by `hogqlRows` in the fetcher ([adhsdk.ingredient.status.service.telemetry.fetchers](cookbook:8648272e-2da3-46fc-b9e8-5148dacdbcff)) through a lease that lapses one second after its holder's timeout, so a holder that is terminated cannot block later queries.
- **traffic-shape**: `shapeTraffic(rows, buckets)` MUST read rows as host, bucket, pageviews, sessions; return `totals`, `pageviews` and `sessions` series aligned to `buckets`; and return `sites` with per-host `series`, `pageviews` and `sessions`, ordered by `pageviews` descending then host name.
- **traffic-alignment**: A point whose timestamp is not on the bucket axis, or unreadable, MUST be dropped, and a bucket with no point MUST be zero. `totals` and every per-site `pageviews` and `sessions` figure MUST be summed from the aligned series, so a dropped point is in no figure at all.
- **dimension-shape**: `shapeDimensions` MUST read rows as host, device, browser, country, referrer, pageviews.
- **dimension-blank-labels**: `shapeDimensions` MUST label a blank host `(unknown)`, a blank device, browser or country `Unknown`, and a blank referrer `$direct`.
- **dimension-truncated**: `shapeDimensions` MUST set `truncated` when the row count reaches `DIMENSION_ROW_LIMIT`.
- **paths-shape**: `loadPaths` MUST return rows of `host`, `path` and `pageviews`, with host `(unknown)` and path `/` for blanks.
- **vitals-shape**: `shapeVitals` MUST read rows as host, samples, lcp, inp, cls, fcp (each the 75th percentile) and MUST keep a vital with no value as null, never zero.
- **health-shape**: `shapeHealth` MUST read rows as host, errors, requests, failures, p95 milliseconds, with `p95Ms` null when absent.
- **failure-definition**: A failed request MUST be an `http_request` whose status is 500 or above, or 0 (no response).
- **site-detail-sequence**: `loadSiteErrorDetail` MUST run its three queries (days, errors, requests) one after another, so the first failure ends the section without spending the other scans.
- **site-detail-shape**: It MUST return `buckets` (the window's), `days` (per host `errors` and `failures`, zero-filled and aligned), `errors` rows of host, name, feature, step, boundary, page, count, lastSeen, and `requests` rows of host, status, method, path, count, lastSeen. Fields the event did not report MUST be null; a missing host MUST read `(unknown)`, a missing error name `(unnamed)` and a missing request path `(unknown)`.
- **site-detail-truncated**: `truncated` MUST be true when any of the three queries returned 5,000 rows.
- **metric-coercion**: Counts MUST be read with `toMetricValue`, which accepts a finite number or a numeric string, and a non-numeric value MUST count as zero (or null for the nullable vitals and p95 fields).
- **per-site-health-source**: Per-site health MUST come from PostHog's `error_reported` and `http_request` events and MUST NOT query GlitchTip for it.

## Appearance

Not applicable — this is a query-and-shaping service, not a visual component.

## States

Not applicable — this is a query-and-shaping service, not a visual component.

## Accessibility

Not applicable — this is a query-and-shaping service, not a visual component.

## Conformance Test Vectors

Vectors 001 to 014 are traced to `telemetry-dashboard-sections.test.ts` (PostHog shapers, `loadSiteErrorDetail` and `loadTraffic`); 015 and later are in `telemetry-dashboard-sections.test.ts` and `telemetry-posthog-sections-queries.test.ts`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| posthog-sections-001 | traffic-shape | Rows for two hosts over a bucket axis | Totals sum the aligned series, which here holds every row; `sites` biggest first, each with its own series |
| posthog-sections-002 | dimension-shape | Rows with blank device and referrer, and a row count at the limit | `Unknown` and `$direct` labels, `truncated` true |
| posthog-sections-003 | vitals-shape | A host row with LCP 1200, a null INP, CLS `"0.1"` and FCP 800 | `inp` null, not 0; `cls` 0.1 |
| posthog-sections-004 | health-shape | Row `["a.com", 1, 100, 2, null]` | `{ host: "a.com", errors: 1, requests: 100, failures: 2, p95Ms: null }` |
| posthog-sections-005 | site-detail-shape | Rows for one host on some of the buckets | `errors` and `failures` series zero-filled to every bucket |
| posthog-sections-006 | site-detail-shape | An error row with no feature, step, boundary or page | Those fields null |
| posthog-sections-007 | failure-definition, site-detail-shape | A request row with status 0 | Kept as status 0, a request with no response |
| posthog-sections-008 | production-hosts, failure-definition | `loadSiteErrorDetail` with a stubbed fetch | Three queries, each containing `NOT LIKE 'staging.%'`; the requests query contains the 500-or-0 predicate |
| posthog-sections-009 | site-detail-truncated, row-caps | The requests query answers 5,000 rows | `truncated` true; `requests` has 5,000 rows |
| posthog-sections-010 | site-detail-truncated | All three queries answer nothing | `truncated` false |
| posthog-sections-011 | failure-throws | Fetch answers HTTP 504 | `loadTraffic` rejects with a message containing `HTTP 504` |
| posthog-sections-012 | utc-only | `loadTraffic` for `24h` and `7d`, and `loadSiteErrorDetail` for `30d` | Every `toStartOf...(...)` and `toDateTime(...)` in the queries ends with `, 'UTC')` |
| posthog-sections-013 | site-detail-sequence | Fetch answers HTTP 503 | `loadSiteErrorDetail` rejects with `HTTP 503` after exactly one fetch call |
| posthog-sections-014 | one-at-a-time | `loadSiteErrorDetail` and `loadTraffic` started together | At most one fetch in flight at any time |
| posthog-sections-015 | metric-coercion | Counts `'7'`, `null`, `'abc'` | 7, 0, 0 |
| posthog-sections-016 | closed-inputs, named-properties | The queries of every loader | No query contains `SELECT properties`, and each interpolated value is a constant, a UTC time or a name from the closed list |
| posthog-sections-017 | bucket-unit | `bucketStart('hour')` and `bucketStart('day')` | `toStartOfHour(timestamp, 'UTC')` and `toStartOfDay(timestamp, 'UTC')` |
| posthog-sections-018 | since-bound | `since` of a window whose `since` is `2026-01-02T03:04:05Z` | `timestamp >= toDateTime('2026-01-02 03:04:05', 'UTC')` |
| posthog-sections-019 | traffic-alignment | A traffic row whose bucket timestamp is off the axis, and a bucket with no row | The off-axis point is dropped from the series and from `totals`; the empty bucket is 0 |
| posthog-sections-020 | paths-shape | `loadPaths` rows `['', '', 3]` and `['a.com', '/x', 2]` | `{ host: '(unknown)', path: '/', pageviews: 3 }` and `{ host: 'a.com', path: '/x', pageviews: 2 }` |
| posthog-sections-021 | row-caps | `loadVitals` and `loadSiteHealth` queries | Each ends with `LIMIT 200`; the traffic, dimension, path and detail queries end with `LIMIT 5000` |
| posthog-sections-022 | query-per-section | Any loader with a stubbed `hogqlRows` | The call is made with timeout 45000 and no other transport |
## Edge Cases

- An empty result set gives an empty `sites`, zero totals and series of zeros; it is a valid answer, distinct from a failed query, which throws.
- PostHog not configured makes the query fail with `PostHog: PostHog is not configured`; the dashboard set avoids this by not calling the loaders for an unconfigured provider.
- A response with no `results` array fails the query with `response had no results`.
- A query that outlasts 45 seconds is aborted and fails with the abort message; the timeout starts when the query starts, not while it waits its turn.
- A host with a null or empty `$host` is grouped under `(unknown)`.
- Timestamps that are not exactly on a bucket boundary in UTC are dropped from the series and from `totals`, which sum the aligned series; the UTC bucket expressions are what keep rows on the axis.
- A busy site can have hundreds of distinct failing paths, so the detail cap is high and hitting it is reported through `truncated`.
- `loadTraffic` has no truncation flag; it silently returns at most 5,000 host-and-bucket rows, so a very busy window loses its latest rows' totals without notice.
- `loadPaths` has no truncation flag; it silently returns at most 5,000 rows, ordered by pageviews.
- `loadSiteHealth` and `loadVitals` return at most 200 hosts with no truncation flag.
- Both the API thread and the monitor's worker thread query PostHog; the lease that orders them is in the fetcher and is part of `one-at-a-time`.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `env` | `PosthogEnv` | required | `POSTHOG_HOST`, `POSTHOG_API_KEY`, `POSTHOG_PROJECT_ID` |
| `window` | `RangeWindow` | required | The window (`since`, `unit`, `buckets`) from `rangeWindow(range, now)` |
| `QUERY_TIMEOUT_MS` | number | 45000 | Per-query timeout; a module constant |
| `TRAFFIC_ROW_LIMIT`, `DIMENSION_ROW_LIMIT`, `PATH_ROW_LIMIT`, `ERROR_DETAIL_ROW_LIMIT` | number | 5000 | Row caps; module constants |
| `SITE_ROW_LIMIT` | number | 200 | Row cap for vitals and site health; a module constant |
| `PRODUCTION_HOSTS` | string | `$host NOT LIKE` each of `testing.%`, `staging.%`, `%localhost%`, `%127.0.0.1%` and `%.vercel.app` | The host filter every query applies; a module constant |
## Deep Linking

Not applicable: the module builds queries and shapes rows; it has no addressable surface.

## Localization

Not applicable: the module's fixed labels (`(unknown)`, `Unknown`, `$direct`, `(unnamed)`) are English data keys that the views present, and its one error message is developer-facing.

## Accessibility Options

Not applicable: the module has no rendering.

## Feature Flags

Not applicable: the module reads no flag.

## Analytics

Not applicable: the module reads analytics data from PostHog but emits no events of its own.

## Privacy

The module passes `POSTHOG_API_KEY` to the fetcher as a bearer token and never returns it. It reads only aggregate counts per host, path, device, browser, country and referrer, and no person data or `person_id`; this matches the privacy-first capture the events come from.

## Logging

Not applicable: the loaders return or throw failures and make no log call; the section cache that calls them logs a failed section.

## Platform Notes

- **SwiftUI**: Build query strings with plain `String` constants and `Date` formatted by a UTC `ISO8601DateFormatter`; send them with `URLSession` and `async`/`await`. Serialise queries through one `actor`. The shapers are pure functions over `[[Any]]` rows.
- **Compose**: Use `HttpURLConnection` or OkHttp with `withTimeout(45_000)`, and a single `Mutex` around the query call; shapers are pure Kotlin functions over `List<List<Any?>>` with `kotlinx.serialization.json` for the response.
- **React/Web**: Keep the module as is: `fetch` with an `AbortController`, and the shared lease in the fetcher for one query at a time across threads.
- **AppKit / UIKit**: Same as SwiftUI; run the loaders on a background `Task`.
- **WinUI 3**: Use `HttpClient` with a `CancellationTokenSource` of 45 seconds and `System.Text.Json` (`JsonDocument`) for the response; serialise queries with a `SemaphoreSlim(1, 1)` held by the data service, and format the window bound with `DateTimeOffset.UtcDateTime.ToString("yyyy-MM-dd HH:mm:ss")`. Shapers are static methods over `IReadOnlyList<object?[]>` using LINQ `GroupBy` and `OrderByDescending`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-server/src/telemetry/dashboard/posthog-sections.ts` | confirmed (1.0.3) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: UTC everywhere.
**Rationale**: HogQL reads a zone-less literal, and starts a day or an hour, in the PostHog project's timezone; naming UTC keeps rows in the window's buckets for any project.
**Approved**: pending

**Decision**: Production hosts only.
**Rationale**: Stray local, staging and preview hits can reach PostHog, so the host filter removes them from every figure.
**Approved**: pending

**Decision**: Named properties.
**Rationale**: `SELECT properties` times out; naming the few properties each section needs keeps queries fast.
**Approved**: pending

**Decision**: Throw, don't return empty.
**Rationale**: A failed query fails its section so the cache keeps the last good data and shows an error, instead of drawing zero traffic.
**Approved**: pending

**Decision**: One query at a time, enforced in the fetcher.
**Rationale**: Callers do not know about each other, so the rule lives where the queries are sent.
**Approved**: pending

**Decision**: Detail fetched for all sites at once.
**Rationale**: Moving between sites then costs no query; the high cap and the `truncated` flag cover busy sites.
**Approved**: pending

**Decision**: Detail queries in sequence.
**Rationale**: The first failure ends the section without spending the other two scans.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | passed | Access Patterns |
| [adc.check.access-patterns.rate-limit-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/aed555ee-66e3-5f99-88ab-24674ed5c789) | partial | Access Patterns |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |

Query building, shaping and transport are separate, with pure shapers and a closed set of interpolated values. The tests cover the traffic, dimension, vitals, health and detail shapers, the production filter, UTC, truncation, failure and the one-at-a-time rule; the paths loader, the row caps, the closed query inputs and the 45 second timeout are covered in `telemetry-posthog-sections-queries.test.ts`, so every vector has a test. Every query has a 45 second timeout. Concurrency is kept to one query at a time, which avoids the 503 but there is no retry or backoff here, so rate-limit handling is partial; a failed section is retried by the section cache on its own schedule.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.3 | 2026-11-14 | Mike Fullerton | Conformance tests added (telemetry-dashboard-sections.test.ts, telemetry-posthog-sections-queries.test.ts, 22 of 22 vectors); unit-test-coverage now passed. |
| 1.0.2 | 2026-11-14 | Mike Fullerton | Added a loader table, links and depends-on for the fetcher and ranges specs, a traffic truncation edge case, seven vectors, a PRODUCTION_HOSTS configuration row, and split dimension-shape; clarified totals, the host-filter rationale and per-site-health-source. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Each design decision carries its own approval line |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
