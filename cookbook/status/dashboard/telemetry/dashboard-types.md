---
id: e8f3cd4d-e208-49db-a500-24d6f7b978f9
title: "Dashboard Wire Types"
type: ingredient
version: 1.0.3
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
tags:
  - dashboard
  - telemetry
  - wire-types
  - analytics
depends-on: []
related:
  - 564c6102-e100-41ad-9c92-14606a33c394
  - c861465b-50c8-49d1-93cc-00d9e062ad5f
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

The constant lists are the analytics ranges (`ANALYTICS_RANGES`), the breakdown dimensions (`DIMENSIONS`), the Vercel breakdowns (`VERCEL_BREAKDOWNS`) and the web vitals (`VITALS`). The dashboard queries recipe consumes the responses, and the formatting module, Dashboard Formatting ([adhsdk.ingredient.status.dashboard.lib.dashboard-format](cookbook:c861465b-50c8-49d1-93cc-00d9e062ad5f)), consumes `AnalyticsRange`, `Vital` and the site list. For number and time wording see Format ([adhsdk.ingredient.status.dashboard.logic.format](cookbook:564c6102-e100-41ad-9c92-14606a33c394)).

## Behavioral Requirements

### Constants

- **ranges-list**: `ANALYTICS_RANGES` MUST be exactly `"24h"`, `"7d"`, `"30d"`, in that order, and `AnalyticsRange` MUST be derived from it.
- **dimensions-list**: `DIMENSIONS` MUST be exactly `"country"`, `"device"`, `"browser"`, `"referrer"`, in that order.
- **vercel-breakdowns-list**: `VERCEL_BREAKDOWNS` MUST be exactly `"countries"`, `"referrers"`, `"paths"`, `"devices"`, in that order.
- **vitals-list**: `VITALS` MUST be exactly `"lcp"`, `"inp"`, `"cls"`, `"fcp"`, in that order.
- **vital-rating-values**: A vital rating MUST be one of `"good"`, `"fair"` or `"poor"`; a missing rating is `null`, not a fourth value.
- **breakdown-topics**: A breakdown topic MUST be one of `"pages"`, `"countries"`, `"referrers"`, `"devices"` or `"browsers"`.

### Sections

- **section-shape**: Every section MUST be typed with `data`, `error` and `updatedAt`, each nullable, and a response MUST be typed with one section for each name in its section-data type (`DashboardSections` maps every name to a `DashboardSection` of that name's data).
- **analytics-sections**: The analytics sections MUST be `traffic`, `dimensions`, `paths`, `vitals`, `health` and `vercel`.
- **errors-sections**: The errors sections MUST be `issues`, `sites`, `detail` and `runtime`.

### Envelope

- **envelope-common**: Both responses MUST be typed with `generatedAt` (a timestamp string), `refreshing` (a boolean), `configured` (a flag per source) and `views`.
- **analytics-envelope**: The analytics response MUST carry its `range` and `configured` flags for `posthog` and `vercel`.
- **errors-envelope**: The errors response MUST carry `refreshingSources` with a flag each for `glitchtip` and `posthog`, and `refreshing` MUST be true when either is true; `configured` MUST carry flags for `glitchtip`, `posthog` and `vercel`.

### Errors

- **runtime-window**: The runtime report's `window` MUST be typed as the literal `"24h"`.

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

Vectors 001, 002 and 025 are the runtime assertions in `dashboard-types-parity.test.ts`; the others are compile-time type checks in the same file. Client reading rules over server data are not vectors here: that behavior is not in this module (see Design Decisions).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dtypes-001 | ranges-list, mirror-constants | test "offer the same ranges": the web `ANALYTICS_RANGES` and the server's | equal lists `["24h","7d","30d"]` |
| dtypes-002 | dimensions-list, vercel-breakdowns-list, vitals-list, mirror-constants | test "name the same breakdowns and vitals": the three web lists and the server's | each pair equal, in order |
| dtypes-003 | mirror-parity | type check: the exported `responsesAgree` tuple of five mutual-assignability checks | compiles only while the analytics response, errors response, runtime report and both views agree; fails the type check otherwise |
| dtypes-009 | errors-envelope | errors response with `refreshingSources` of glitchtip true and posthog false | `refreshing` true |
| dtypes-012 | runtime-window | runtime report | `window` is `"24h"` |
| dtypes-015 | analytics-sections, section-shape | analytics response | exactly the six sections `traffic`, `dimensions`, `paths`, `vitals`, `health`, `vercel`, each typed with nullable `data`, `error` and `updatedAt` |
| dtypes-016 | errors-sections | errors response | exactly the four sections `issues`, `sites`, `detail`, `runtime` |
| dtypes-017 | envelope-common | either response | carries `generatedAt`, `refreshing`, `configured` and `views` |
| dtypes-018 | analytics-envelope | analytics response | carries `range` and `configured` flags for `posthog` and `vercel` |
| dtypes-025 | types-only | importing the module | only the four lists exist at run time; nothing else runs at load |
## Edge Cases

- **Null and empty input — sections**: `data`, `error` and `updatedAt` are each typed nullable, so a section can be fully empty.
- **Null and empty input — views**: the view fields typed nullable may be `null`; lists such as `sites` may be empty, and `siteReports` may be an empty object.
- **Malformed input — versions**: the types say `views` is required; tolerating a backend that sends none is done by the components (`viewsMissing`), not by this module.
- **Concurrent access**: not applicable — the module holds only immutable constants and types.
- **Error states**: not applicable — the module holds no behavior; the section `error` field is only a typed string or `null`.
- **Offline and cancellation**: not applicable — the module performs no I/O.
- **Drift**: if the server adds or renames a field, the parity check fails until the web copy is updated; a field the web copy lacks is not visible to the pages.

## Configuration
Not applicable: this module has no configurable options. The four constant lists are fixed and specified by `ranges-list`, `dimensions-list`, `vercel-breakdowns-list` and `vitals-list` under Behavioral Requirements. The module reads no environment variables or settings and takes no injected dependency. The runtime window (`24h`) and the active-issue test are fixed by the server.
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

- **SwiftUI**: Model the shapes as `Codable` structs with `let` properties, optional types for every nullable field, and `enum`s with `String` raw values for `AnalyticsRange`, `Dimension`, `Vital`, `VitalRating`, `VercelBreakdown` and `BreakdownTopic` (conform to `CaseIterable` for the lists). `DashboardSection<T: Codable>` is a generic struct. `siteReports` is `[String: SiteReport]`. Timestamps stay `String` or decode with `ISO8601DateFormatter` including fractional seconds. A fixed list of cases gives the same drift check through a test that decodes a server fixture.
- **Compose**: Kotlin `@Serializable` data classes with nullable types for nullable fields; enums with `@SerialName` for the lists; a generic `DashboardSection<T>`. Use `Map<String, SiteReport>` for `siteReports`. Set `ignoreUnknownKeys = false` in tests so a field the server adds fails the parity test, and `true` in production so an extra field does not break the app.
- **React/Web**: Source platform. `packages/web/packages/status-web/src/telemetry/dashboard-types.ts` is the file, and `dashboard-types-parity.test.ts` beside it is the drift guard: the runtime half compares the four lists, and the type half is a tuple of `Exact` mutual-assignability checks that only compiles while both copies agree. Because `pnpm test` transpiles without type checking, the type half is caught by the type check, not by the test run. The lists use `as const` so each type is a union of its literals.
- **AppKit / UIKit**: The same Swift `Codable` model as SwiftUI, shared from a framework target. Decode with `JSONDecoder`; there is no `DateFormatter` need unless a screen shows a timestamp.
- **WinUI 3**: C# `record` types in a .NET class library, deserialised with `System.Text.Json` and `JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase }`. Use nullable reference types (`string?`) and nullable value types (`int?`, `double?`) for every nullable field, so `null` reads as unknown and never as zero. Model the lists as `enum`s with `JsonStringEnumConverter` and camel-case naming, but note `24h`, `7d` and `30d` are not valid C# identifiers: map them with a custom converter or keep the range as a string constant list. `DashboardSection<T>` is a generic record. Use `IReadOnlyDictionary<string, SiteReport>` for `siteReports`. No `INotifyPropertyChanged` is needed here; the view model that owns the response raises change notifications.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-web/src/telemetry/dashboard-types.ts` | confirmed (1.0.2) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The web package keeps a hand mirror of the server's types instead of importing them.
**Rationale**: The header comment of `dashboard-types.ts`: the package has the server only as a development dependency, so it cannot import the types at run time. A drift test stops the copies diverging.
**Approved**: pending

**Decision**: A section keeps its last good `data` beside the latest `error`.
**Rationale**: The `DashboardSection` doc comment in `dashboard-types.ts`: the last good answer survives a later failure, so stale data stays on screen instead of the page going blank when one source fails.
**Approved**: pending

**Decision**: The server derives the views and the pages only lay them out.
**Rationale**: The section comment above the views in `dashboard-types.ts`: every join, sort, threshold and rating lives in the server's views module, so every client shows the same answer and a port copies shapes, not logic.
**Approved**: pending

**Decision**: Unknown numbers are `null`, not zero.
**Rationale**: The `VercelRosterEntry.pageviews` doc comment in `dashboard-types.ts`: null when analytics is off or the count could not be read, which is not a zero. A zero would read as "measured, and none".
**Approved**: pending

**Decision**: Parity is checked by mutual assignability, with the lists compared at run time.
**Rationale**: The `Exact` type comment in `dashboard-types-parity.test.ts`: a renamed field, a nullability change or a union member stops the check being true. It catches drift that a transpile-only test run would not.
**Approved**: pending

**Decision**: Client reading rules over server data were removed from this recipe; this module only declares types and four constants.
**Rationale**: An earlier version of this recipe described 18 rules such as keeping stale section data after a failure, reading a null count as unknown, treating a request `status` of 0 as no response, treating `truncated` and `incomplete` as short results, and tolerating a response with no `views`. None of them runs in `dashboard-types.ts`. They are implemented in the status-web components instead: `DashboardPanel` and `viewsMissing` in `DashboardParts.tsx`, the truncation notes in `AnalyticsView.tsx` and `ErrorsSitePage.tsx`, the "No response" label in `ErrorsSitePage.tsx`, and `failureRateHigh` and the failure lists in the site pages. The server produces the rest (series length, sessions sum, runtime group message, path and key, the active-issue rule, the `views` joins), so they are not client code anywhere in status-web.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.good-test-properties](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9144e220-ad70-51db-ba81-cdb0cc1b66c8) | passed | best-practices |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |

**Separation of Concerns**: The module holds shapes and four constants only; derivation lives on the server and layout in the pages.

**Unit Test Coverage**: `dashboard-types-parity.test.ts` covers all 10 vectors (`dtypes-001`, `002`, `003`, `009`, `012`, `015`, `016`, `017`, `018`, `025`): the four lists, the five agreeing types, the section and envelope key sets and the load-time exports. The module has no other behavior to test.

**Good Test Properties**: The parity test is deterministic, has no I/O and checks one thing per case.

**Data Minimization**: No shape carries a user identifier.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.3 | 2026-11-14 | Mike Fullerton | Match recipe to source: drop 18 client reading rules the types-only module does not implement |
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (dashboard-types-parity.test.ts, 10 of 28 vectors; 18 type-only client reading rules skipped); unit-test-coverage now partial. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Rephrased server-derived requirements as client reads, added views-absent-older-backend and vercel-incomplete-series, linked the formatting recipe, cited source files in rationales, added tags, fixed the privacy category, replaced the configuration table, and added vectors dtypes-014 to dtypes-028. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial recipe extracted from `dashboard-types.ts` |
