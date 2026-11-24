---
id: 488a7fef-19c2-4526-8882-3d0529dda3e3
title: "Errors Dashboard Sections"
type: ingredient
version: 1.0.3
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The GlitchTip half of the Errors dashboard: issue shaping with the board's active rule, summary KPIs, and a cached resolved-issue count."
platforms:
  - typescript
  - web
tags:
  - status
  - telemetry
  - dashboard
  - glitchtip
  - errors
depends-on:
  - 8648272e-2da3-46fc-b9e8-5148dacdbcff
  - d4e7dd53-4771-425f-af0a-0186ba89c3ef
  - 7984f592-a12d-49da-806c-ff39d9557998
related:
  - a7c2b9e1-5d4f-4a2c-9e6f-8b3a1c5d7e2f
references: []
approved-by: ""
approved-date: ""
---

# Errors Dashboard Sections

## Overview

The GlitchTip half of the Errors topic: every unresolved issue, read as the board reads it. The module turns the raw GlitchTip issue list into `ErrorIssue` rows, marks each row `active` with the board's own rule (`errorCountsAsProblem`), summarises the list into the KPI figures of an `ErrorsIssuesSection`, and supplies a cached count of resolved issues.

The module has one loader, `loadErrorIssues`, which the dashboard set hands to a section cache, and four helpers: the pure `isoMs`, `toErrorIssues` and `summarizeIssues`, and the stateful `resolvedCounter`, which holds a TTL cache and a single flight. It deliberately carries no events-per-day series, because GlitchTip's `stats_v2` answers 200 with nulls for every interval on this instance while issues are firing, which would draw a flat zero beside issues reporting hundreds of events.

## Behavioral Requirements

- **iso-ms**: `isoMs(iso)` MUST return the epoch milliseconds of an ISO string, and null when the input is null, empty or unreadable. The board reads null as not current.
- **issue-mapping**: `toErrorIssues` MUST return one `ErrorIssue` per raw issue, in the same order, with `id`, `title`, `level`, `count`, `userCount`, `firstSeen`, `lastSeen`, `project` and `permalink` taken from the shared GlitchTip mapper `mapIssues`.
- **issue-extras**: Each `ErrorIssue` MUST also carry `shortId`, `type` (the metadata type), `source` (the metadata filename) and `release` (the last release version), each null when absent or empty.
- **active-rule**: `ErrorIssue.active` MUST equal `errorCountsAsProblem({ project, level, lastSeenMs }, judging)`, the board's whole rule including its allowlist: an error or fatal issue, seen in the last 24 hours, in an allowed project.
- **judging-inputs**: `loadErrorIssues` MUST judge with `{ nowMs, frozen: false, allowlist }`, where `allowlist` is the configured GlitchTip project list or null.
- **issue-order**: `summarizeIssues` MUST return `issues` sorted active first, then by event `count` descending, and MUST NOT reorder the input array.
- **summary-counts**: `summary.active` MUST count issues with `active` true, `summary.backlog` MUST be the total minus `active`, and `summary.events` MUST be the sum of `count` over all issues.
- **by-type**: `summary.byType` MUST group issues by `type` (null grouped as `Other`) with `issues` and `events` per group, sorted by `events` descending.
- **new-per-day**: `summary.newPerDay` MUST count issues by the UTC day of `firstSeen` (an issue with no `firstSeen` is not counted), aligned to the window's buckets with `alignToBuckets`.
- **section-window**: `loadErrorIssues` MUST summarise over `rangeWindow('30d', nowMs)`, and the section's `buckets` MUST be that window's buckets.
- **summary-flags**: `summary.resolved` MUST be the resolved count (null when not counted) and `summary.complete` MUST be false when the unresolved list was cut short.
- **failed-read-throws**: When the unresolved read fails, `loadErrorIssues` MUST throw `GlitchTip issues could not be read`, so the section cache keeps its last answer and its `active` flags rather than judging anything as a frozen feed.
- **resolved-optional**: A failure to count resolved issues MUST NOT fail the issue list; the count is a nice-to-have on the KPI row.
- **resolved-cached**: `resolvedCounter(env, ttlMs)` MUST read the resolved list at most once per `ttlMs` (default 60 minutes), through a single flight, and MUST return the same count to every caller within that time.
- **resolved-value**: The resolved count MUST be the length of the `is:resolved` list when the walk is complete, and null when the walk is capped (see Walk outcomes below).
- **resolved-failure-not-kept**: A resolved read that failed, or that was interrupted after its first page, MUST give null to the caller and MUST NOT be cached, so the next call reads again.
- **resolved-cap-kept**: A capped walk MUST be cached as null for the whole TTL, since walking again would meet the same limit.
- **resolved-never-throws**: The function returned by `resolvedCounter` MUST NOT reject; every failure becomes null.

Walk outcomes. The GlitchTip fetcher classifies each walk of an issue list, and these requirements use its terms:

- **failed**: the read is not ok, because no page could be read at all.
- **interrupted**: a page after the first failed, so the walk was cut short and the fetcher flags it `interrupted`.
- **capped**: the walk finished without being interrupted but is not complete, because it hit the page cap, met a repeated cursor, or got a full page with no way forward.
- **complete**: the whole list was read.

## Appearance

Not applicable — this is a data-shaping service, not a visual component.

## States

Not applicable — this is a data-shaping service, not a visual component.

## Accessibility

Not applicable — this is a data-shaping service, not a visual component.

## Conformance Test Vectors

Vectors 001 to 018 are traced to the `errors sections: conformance vectors` tests in `telemetry-dashboard-sections.test.ts`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| errors-sections-001 | active-rule | Level `error`, last seen now | `active` true |
| errors-sections-002 | active-rule | Level `FATAL` | `active` true |
| errors-sections-003 | active-rule | Level `warning`; or last seen 48 hours ago; or `lastSeen` null; or level null | `active` false in each case |
| errors-sections-004 | active-rule | Project `scratch` with allowlist `['app']`; project `app` with the same list | `active` false for `scratch`, true for `app` |
| errors-sections-005 | issue-order, summary-counts | Three issues, one active, 104 events in all, resolved 7 | `active` 1, `backlog` 2, `events` 104, `resolved` 7, `complete` true; issues ordered active first, then by count |
| errors-sections-006 | by-type | Issues with types `TypeError` (100 events), `SyntaxError` (3) and none (1) | Groups `TypeError`, `SyntaxError` and `Other`, ordered by events |
| errors-sections-007 | new-per-day | Two issues first seen on the same UTC day, a third with no `firstSeen` | That day's bucket is 2 and `newPerDay` sums to 2 |
| errors-sections-008 | issue-extras | Raw issue with `shortId` `ADH-2`, type `SyntaxError`, filename `/x.js`, release `abc` | Row carries those four values |
| errors-sections-009 | resolved-cached | Two list refreshes inside the TTL | One `is:resolved` read; both sections show `resolved` 3 |
| errors-sections-010 | resolved-failure-not-kept | A failed resolved read, then a good one | First call null, the next reads again and returns 2 |
| errors-sections-011 | failed-read-throws | The unresolved read returns not ok | `loadErrorIssues` rejects with `GlitchTip issues could not be read` |
| errors-sections-012 | iso-ms | `null`, `''`, `not a date` | null for each |
| errors-sections-013 | judging-inputs | `loadErrorIssues` with allowlist `['app']` and `nowMs` 1000 | Each issue is judged with `{ nowMs: 1000, frozen: false, allowlist: ['app'] }`; with a null allowlist, no project filter applies |
| errors-sections-014 | section-window | `loadErrorIssues` at a given `nowMs` | The section's `buckets` equal those of `rangeWindow('30d', nowMs)` |
| errors-sections-015 | summary-flags | An unresolved list the fetcher reports `complete` false | `summary.complete` is false |
| errors-sections-016 | resolved-optional | The resolved count is null because the resolved read failed | `loadErrorIssues` still returns the issue list, with `summary.resolved` null |
| errors-sections-017 | resolved-cap-kept | A resolved walk that hits the 20-page cap, then a second call inside the TTL | The first call returns null, and the second returns null without reading again |
| errors-sections-018 | resolved-never-throws | A resolved read that throws | The counter's function resolves null and does not reject |
## Edge Cases

- An empty issue list gives empty `issues` and `byType`, zero counts and a `newPerDay` of zeros over the window.
- A raw issue with no metadata gives a null `type`, `source` and `release`, and sits in the `Other` group.
- A `firstSeen` older than the window is dropped by the bucket alignment; it still counts toward `active`, `backlog` and `events`.
- A resolved walk cut short after its first page is not kept as "not counted" for the hour; the next refresh tries again.
- The unresolved fetch is bounded by the fetcher: pages of 100, at most 20 pages, and one 12 second budget for the whole walk, not per request. A list that hits the cap returns `complete` false.
- The resolved list is read only to take its length, because GlitchTip has no count endpoint; a resolved list that reaches the 20-page cap (2,000 issues) gives null.
- A null allowlist means no project filter on `active`; the config yields null when `GLITCHTIP_PROJECTS` is unset, blank or only separators. An empty array passed directly would match no project, so every issue would be inactive.
- `frozen` is always false here, so an issue list that is stale is never judged as a frozen feed; stale data is handled by the section cache keeping the last answer.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `env` | `GlitchtipEnv` | required | GlitchTip credentials and base URL for the fetcher |
| `allowlist` | `readonly string[]` or null | `null` | GlitchTip projects the board counts; from `glitchtipProjects` in the config |
| `resolvedCount` | `ResolvedCount` | required | The cached counter from `resolvedCounter`, shared across refreshes |
| `nowMs` | number | current time | The clock for judging and for the 30 day window |
| `ttlMs` | number | 3600000 | How long a resolved count stands (`RESOLVED_COUNT_TTL_MS`) |
| Page size | number | 100 | Issues per GlitchTip page; the fetcher's `PAGE_LIMIT` |
| Page cap | number | 20 | The most pages one walk reads (2,000 issues); the fetcher's `MAX_PAGES`. A list that reaches it is capped |
| Walk budget | number | 12000 | Milliseconds for the whole walk, not per request; the fetcher's `TIMEOUT_MS` |
## Deep Linking

Not applicable: the module shapes data; `ErrorIssue.permalink` is a GlitchTip URL carried as data.

## Localization

Not applicable: the module's one user-visible string, `GlitchTip issues could not be read`, is a developer-facing error message in English, and the `Other` group label is an English string emitted in the data (`byType`); the module does not localize it.

## Accessibility Options

Not applicable: the module has no rendering.

## Feature Flags

Not applicable: the module reads no flag.

## Analytics

Not applicable: the module emits no events.

## Privacy

The module passes the GlitchTip credentials in `env` to the fetcher and never returns them. It returns issue titles, filenames and user counts, which are operator-only data gated by the dashboard routes.

## Logging

Not applicable: the module makes no log call; a failed section refresh is logged by the section cache that calls `loadErrorIssues`.

## Platform Notes

- **SwiftUI**: Model `ErrorIssue` as a `Codable` struct and the section as a value type; the shaping is pure and ports as plain functions over arrays. The cached resolved count is an `actor` holding a task and an expiry date.
- **Compose**: Pure shaping in Kotlin extension functions over `List<ErrorIssue>`; the counter is a class with a `Mutex` and a `Deferred` that is cleared on failure.
- **React/Web**: Keep the module as is; `cachedSingleFlight` is the shared single-flight cache from the `@adh-sdk/deploy-platform/util` package, and `resolvedCounter` is built on it.
- **AppKit / UIKit**: Same as SwiftUI; the shaping runs on a background `Task` and publishes the section to the main actor.
- **WinUI 3**: Records and `System.Linq` (`OrderByDescending`, `GroupBy`) for the shaping, `DateTimeOffset.TryParse` for `isoMs`, and a `Lazy<Task<int?>>` guarded by a `SemaphoreSlim` with an expiry for the single-flight cache; fetch with `HttpClient` and a `CancellationTokenSource` timeout.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-server/src/telemetry/dashboard/errors-sections.ts` | confirmed (1.0.3) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The board's rule, not a second one.
**Rationale**: `active` calls the board's `errorCountsAsProblem`, so the dashboard and the board agree on which errors count, allowlist included.
**Approved**: pending

**Decision**: Throw on a failed read.
**Rationale**: A failed unresolved read throws so the section cache keeps its last good answer, rather than returning an empty list that would look like zero errors.
**Approved**: pending

**Decision**: Resolved count cached for an hour.
**Rationale**: Counting means walking every resolved page for one KPI figure that barely moves; the issue list refreshes every 60 seconds (the GlitchTip cache TTL set by [adhsdk.ingredient.status.service.telemetry.dashboard.dashboard-set](cookbook:f03325ef-f4c6-43ab-9a88-1a0bf3daa002)), so counting on each refresh would spend up to twenty requests a minute on it.
**Approved**: pending

**Decision**: Failures not cached, caps cached.
**Rationale**: A failed read is retried next refresh; a capped walk would cap again, so it stands for the TTL.
**Approved**: pending

**Decision**: No events series.
**Rationale**: GlitchTip's stats answer nulls on this instance, so a chart would mislead.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.performance.caching-strategy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/3b773606-ab90-5e7d-8e96-093777dcf070) | passed | Performance |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |

The shaping is pure and kept apart from the fetcher and the board rule it calls, and `telemetry-dashboard-sections.test.ts` has a test for every vector, 001 to 018, so unit-test coverage passes. The resolved count is cached with a TTL that keeps failures out of the cache, and a failed unresolved read is raised rather than hidden.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.3 | 2026-11-14 | Mike Fullerton | Conformance tests added (telemetry-dashboard-sections.test.ts, 18 of 18 vectors); unit-test-coverage now passed. |
| 1.0.2 | 2026-11-14 | Mike Fullerton | Defined walk outcomes once, added fetch-limit configuration rows, six vectors for untested requirements, the depends-on specs, the 60-second refresh citation and the stateful-counter wording, and marked unit-test-coverage partial. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Each design decision carries its own approval line |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
