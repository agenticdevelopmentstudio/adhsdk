---
id: e8f3cd4d-e208-49db-a500-24d6f7b978f9
title: "Dashboard Wire Types"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The response shapes of the analytics and errors dashboards: sections that keep stale data, the server-derived views, and the constant lists of ranges and vitals."
platforms:
  - typescript
  - web
tags: []
depends-on: []
related:
  - 564c6102-e100-41ad-9c92-14606a33c394
references: []
approved-by: ""
approved-date: ""
---

# Dashboard Wire Types

## Overview

Dashboard Wire Types is the typed contract for the two dashboard responses the status server sends: the analytics dashboard (`GET /analytics/dashboard`) and the errors dashboard (`GET /errors/dashboard`). It holds no behavior except four constant lists. Everything else is a shape: what a client may rely on being present, nullable or a list.

The source is a hand-kept mirror of the server's own dashboard types file. The web package has the server only as a development dependency and cannot import its types at run time, so it keeps a copy. A drift test (`dashboard-types-parity.test.ts`) fails when the two copies disagree.

A response has three parts:

- **Envelope** — `generatedAt`, `refreshing`, which sources are `configured`, and (errors only) which sources are still refreshing.
- **Sections** — the raw data per source, each wrapped as a section that keeps its last good answer next to the latest failure (`DashboardSection`).
- **Views** — what the pages draw, already joined, sorted, thresholded and rated by the server. The pages only lay them out.

The constant lists are the analytics ranges (`ANALYTICS_RANGES`), the breakdown dimensions (`DIMENSIONS`), the Vercel breakdowns (`VERCEL_BREAKDOWNS`) and the web vitals (`VITALS`). The dashboard queries recipe consumes the responses, and the dashboard formatting recipe consumes `AnalyticsRange`, `Vital` and the site list. For number and time wording see Format ([adhsdk.ingredient.status.dashboard.logic.format](cookbook:564c6102-e100-41ad-9c92-14606a33c394)).

## Behavioral Requirements

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

## Appearance

Not applicable — this is a set of data types, not a visual component.

## States

Not applicable — this is a set of data types, not a visual component.

## Accessibility

Not applicable — this is a set of data types, not a visual component.

## Conformance Test Vectors

Vectors 001 and 002 are the runtime assertions in `dashboard-types-parity.test.ts`; vector 003 is its compile-time check. The rest are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dtypes-001 | ranges-list, mirror-constants | test "offer the same ranges": the web `ANALYTICS_RANGES` and the server's | equal lists `["24h","7d","30d"]` |
| dtypes-002 | dimensions-list, vercel-breakdowns-list, vitals-list, mirror-constants | test "name the same breakdowns and vitals": the three web lists and the server's | each pair equal, in order |
| dtypes-003 | mirror-parity | type check: the exported `responsesAgree` tuple of five mutual-assignability checks | compiles only while the analytics response, errors response, runtime report and both views agree; fails the type check otherwise |
| dtypes-004 | section-keeps-data, section-error-null | a section after a success and then a failure | `data` still holds the earlier answer, `error` holds the failure text, `updatedAt` is the earlier fetch time |
| dtypes-005 | section-error-null, section-updated-at | a section before any attempt finishes | `data`, `error` and `updatedAt` all `null` |
| dtypes-006 | series-per-bucket | traffic with 7 buckets | `pageviews` and `sessions` each have 7 values, and each site's `series` has 7 |
| dtypes-007 | null-is-not-zero | roster entry with analytics off | `analyticsOn` false, `pageviews` and `visitors` `null` |
| dtypes-008 | failed-request-status-zero | a failed-request row with `status` 0 | read as "no response", not an HTTP status |
| dtypes-009 | errors-envelope | errors response with `refreshingSources` of glitchtip true and posthog false | `refreshing` true |
| dtypes-010 | chart-series-nullable | chart series whose vercel list is `null` | there is no Vercel series for the chart; a `null` inside a list is a gap, not a zero |
| dtypes-011 | views-sites, views-site-reports | views with `sites` `["a.com"]` | `siteReports` is an object keyed by site name, and a client reads `a.com` with an own-key lookup |
| dtypes-012 | runtime-window | runtime report | `window` is `"24h"` |
| dtypes-013 | rated-vitals | rated vitals row with a vital that has no sample | that vital's rating is `null` |

## Edge Cases

- **Null and empty input — sections**: a section with `data` `null` is a first load or a source that has never answered; a client reads `error` to tell a failure from "not yet".
- **Null and empty input — views**: nullable view fields are `null` when their section has no data; lists such as `sites` may be empty, and `siteReports` may be an empty object.
- **Boundary — row caps**: the dimensions and site error detail sections set `truncated` when a row cap is hit; the runtime report's `groups` may be shorter than `total`.
- **Boundary — series length**: a series is one value per bucket, so the `24h` range, which the server buckets hourly (25 buckets, counting the partial first hour), has 25 values and a daily range has one per day.
- **Malformed input — versions**: a backend older than `views` sends no `views`; the shape here says `views` is required, so a client must tolerate its absence at the call site (the formatting module's site-list helper does this).
- **Malformed input — unknown names**: a site name in a URL need not be in `siteReports`; a client looks it up with an own-key check.
- **Concurrent access**: not applicable — the module holds only immutable constants and types.
- **Error states**: a failed source shows as a section `error` and as an entry in the views' failure list; other sections stay usable.
- **Offline and cancellation**: not applicable — the module performs no I/O.
- **Drift**: if the server adds or renames a field, the parity check fails until the web copy is updated; a field the web copy lacks is not visible to the pages.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ANALYTICS_RANGES` | constant list | `24h`, `7d`, `30d` | Time ranges the analytics dashboard accepts. Not configurable. |
| `DIMENSIONS` | constant list | `country`, `device`, `browser`, `referrer` | Breakdown dimensions of page views. Not configurable. |
| `VERCEL_BREAKDOWNS` | constant list | `countries`, `referrers`, `paths`, `devices` | Vercel breakdown names. Not configurable. |
| `VITALS` | constant list | `lcp`, `inp`, `cls`, `fcp` | Web vitals the server measures. Not configurable. |

The module reads no environment variables or settings and takes no injected dependency. The runtime window (`24h`) and the active-issue test are fixed by the server.

## Deep Linking

Not applicable: the module registers no route. Site names and ranges that appear in URLs are typed here (`AnalyticsRange`, the keys of `siteReports`).

## Localization

Not applicable: the module holds identifiers and numbers, with no user-visible text. Error text in `error` and in the failure lists comes from the server as given.

## Accessibility Options

Not applicable: the module has no visual output.

## Feature Flags

Not applicable: no type or constant is gated. The `configured` flags report which sources the server has set up, which pages use to explain an empty section.

## Analytics

Not applicable: the module emits no events. It describes analytics data that other systems collected.

## Privacy

The module defines shapes that carry site hostnames, page paths, countries, referrers, device and browser names, error names and Vercel request ids. It stores and sends nothing itself. The source notes that PostHog error data holds no message text, only error names, and that runtime messages are cut to the first line, at most 200 characters. A request id (`sampleRequestId`) is a lookup handle in Vercel, not a user identifier.

## Logging

Not applicable: the module logs nothing.

## Platform Notes

- **SwiftUI**: Model the shapes as `Codable` structs with `let` properties, optional types for every nullable field, and `enum`s with `String` raw values for `AnalyticsRange`, `Dimension`, `Vital`, `VitalRating` and `BreakdownTopic` (conform to `CaseIterable` for the lists). `DashboardSection<T: Codable>` is a generic struct. `siteReports` is `[String: SiteReport]`. Timestamps stay `String` or decode with `ISO8601DateFormatter` including fractional seconds. A fixed list of cases gives the same drift check through a test that decodes a server fixture.
- **Compose**: Kotlin `@Serializable` data classes with nullable types for nullable fields; enums with `@SerialName` for the lists; a generic `DashboardSection<T>`. Use `Map<String, SiteReport>` for `siteReports`. Enable `ignoreUnknownKeys = false` in tests so a field the server adds fails the parity test, and `true` in production so an extra field does not break the app.
- **React/Web**: Source platform. `packages/web/packages/status-web/src/telemetry/dashboard-types.ts` is the file, and `dashboard-types-parity.test.ts` beside it is the drift guard: the runtime half compares the four lists, and the type half is a tuple of `Exact` mutual-assignability checks that only compiles while both copies agree. Because `pnpm test` transpiles without type checking, the type half is caught by the type check, not by the test run. The lists use `as const` so each type is a union of its literals.
- **AppKit / UIKit**: The same Swift `Codable` model as SwiftUI, shared from a framework target. Decode with `JSONDecoder`; there is no `DateFormatter` need unless a screen shows a timestamp.
- **WinUI 3**: C# `record` types in a .NET class library, deserialised with `System.Text.Json` and `JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase }`. Use nullable reference types (`string?`) and nullable value types (`int?`, `double?`) for every nullable field, so `null` reads as unknown and never as zero. Model the lists as `enum`s with `JsonStringEnumConverter` and camel-case naming, but note `24h`, `7d` and `30d` are not valid C# identifiers: map them with a custom converter or keep the range as a string constant list. `DashboardSection<T>` is a generic record. Use `IReadOnlyDictionary<string, SiteReport>` for `siteReports`. No `INotifyPropertyChanged` is needed here; the view model that owns the response raises change notifications.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-web/src/telemetry/dashboard-types.ts` | confirmed (1.0.0) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The web package keeps a hand mirror of the server's types instead of importing them.
**Rationale**: The source header: the package has the server only as a development dependency, so it cannot import the types at run time. A drift test stops the copies diverging.
**Approved**: pending

**Decision**: A section keeps its last good `data` beside the latest `error`.
**Rationale**: Doc comment: the last good answer survives a later failure, so stale data stays on screen instead of the page going blank when one source fails.
**Approved**: pending

**Decision**: The server derives the views and the pages only lay them out.
**Rationale**: Source comment: every join, sort, threshold and rating lives in the server's views module, so every client shows the same answer and a port copies shapes, not logic.
**Approved**: pending

**Decision**: Unknown numbers are `null`, not zero.
**Rationale**: Doc comments on the Vercel roster: null when analytics is off or the count could not be read, which is not a zero. A zero would read as "measured, and none".
**Approved**: pending

**Decision**: Parity is checked by mutual assignability, with the lists compared at run time.
**Rationale**: Test comment: a renamed field, a nullability change or a union member stops the check being true. It catches drift that a transpile-only test run would not.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.good-test-properties](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9144e220-ad70-51db-ba81-cdb0cc1b66c8) | passed | best-practices |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy |

**Separation of Concerns**: The module holds shapes and four constants only; derivation lives on the server and layout in the pages.

**Unit Test Coverage**: The parity test covers the four lists and the five agreeing types. The field-level rules (series length, null meaning, status zero) are documented in comments and have no runtime test, since the module has no code to run.

**Good Test Properties**: The parity test is deterministic, has no I/O and checks one thing per case.

**Data Minimization**: Error rows carry names only, runtime messages are cut to one line of at most 200 characters, and no user identifier appears in any shape.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial recipe extracted from `dashboard-types.ts` |
