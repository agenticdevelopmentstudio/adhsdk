---
id: f06a7f7a-1b36-4dfc-a17d-71d20d576155
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
summary: "Wire shapes of GET /analytics/dashboard and GET /errors/dashboard: per-section data, the two response envelopes, and the types and constants re-exported for clients."
platforms:
  - typescript
  - web
tags:
  - status
  - telemetry
  - dashboard
  - wire-contract
depends-on: []
related: []
references:
  - packages/web/packages/status-server/src/telemetry/dashboard/types.ts (adhsdk)
  - packages/web/packages/status-web/src/telemetry/dashboard-types-parity.test.ts (adhsdk)
  - packages/web/packages/status-server/src/telemetry/dashboard/dashboard-set.ts (adhsdk)
approved-by: ""
approved-date: ""
---

# Dashboard Wire Types

## Overview

`types.ts` declares the wire shapes of the two telemetry dashboard endpoints: `GET /analytics/dashboard` (`AnalyticsDashboardResponse`) and `GET /errors/dashboard` (`ErrorsDashboardResponse`). It also gathers the names a client needs in one place: it re-exports the range, dimension, vercel-breakdown and vital constants and the view types from `views.ts`, and the runtime-error types from `../types`.

The file holds only interfaces, type re-exports and three value re-exports. It has no behavior. The contract it states is the JSON that `dashboard-set.ts` builds and the routes in `routes/telemetry-dashboards.ts` send.

The web client `status-web` keeps a hand-written mirror in `telemetry/dashboard-types.ts`, because it has the server only as a devDependency. The test `dashboard-types-parity.test.ts` holds the mirror to this file. A recipe-following port to another platform carries the same obligation: its model types must stay equal to these.

Each endpoint answers with a set of cached sections, each in the shape `DashboardSection` from the sectioned-dashboard recipe (`data`, `error`, `updatedAt`), plus a derived `views` object.

## Behavioral Requirements

**Module exports**

- **export-range-constant**: The module MUST re-export `ANALYTICS_RANGES` from `ranges.ts`: `"24h"`, `"7d"`, `"30d"`.
- **export-view-constants**: The module MUST re-export `DIMENSIONS` (`country`, `device`, `browser`, `referrer`), `VERCEL_BREAKDOWNS` (`countries`, `referrers`, `paths`, `devices`) and `VITALS` (`lcp`, `inp`, `cls`, `fcp`) from `views.ts`.
- **export-view-types**: The module MUST re-export these types from `views.ts`: `AnalyticsViews`, `BreakdownTopic`, `ChartSeries`, `Dimension`, `ErrorsSiteChart`, `ErrorsSiteReport`, `ErrorsViews`, `JoinedSite`, `RatedHealth`, `RatedVitalsRow`, `SectionFailure`, `SiteBreakdown`, `SiteErrorView`, `SiteFailedRequestView`, `SiteReport`, `VercelBreakdown`, `VercelProjectBar`, `Vital` and `VitalRating`.
- **export-runtime-types**: The module MUST re-export `RuntimeErrorGroup` and `RuntimeErrorsReport` from `../types`.
- **no-behavior**: The module MUST NOT contain runtime logic beyond the three constant re-exports; every other export is a type.

**Analytics response**

- **analytics-response-fields**: `AnalyticsDashboardResponse` MUST carry `generatedAt` (ISO string), `refreshing` (boolean), `range` (an `AnalyticsRange`), `configured` (`{ posthog: boolean; vercel: boolean }`), `sections` and `views`.
- **analytics-sections-shape**: `sections` MUST be `DashboardSections<AnalyticsSectionData>`, so each of `traffic`, `dimensions`, `paths`, `vitals`, `health` and `vercel` is a `{ data, error, updatedAt }` section.
- **analytics-section-data**: `AnalyticsSectionData` MUST map `traffic` to `TrafficSection`, `dimensions` to `DimensionsSection`, `paths` to an array of `PathRow`, `vitals` to an array of `VitalsRow`, `health` to an array of `SiteHealthRow`, and `vercel` to `VercelTrafficSection`.
- **analytics-refreshing**: `refreshing` MUST be true when either provider's dashboard is refreshing, and false when neither is. `dashboard-set.ts` computes it as `Boolean(ph?.refreshing || vc?.refreshing)`.
- **analytics-configured**: `configured` MUST say which providers are set up. A provider that is not configured contributes sections in the initial empty state (`data` null, `error` null, `updatedAt` null) and no refresh.
- **analytics-views**: `views` MUST hold what the pages draw, derived on the server from `sections` by `views.ts`.

**Errors response**

- **errors-response-fields**: `ErrorsDashboardResponse` MUST carry `generatedAt`, `refreshing`, `refreshingSources` (`{ glitchtip: boolean; posthog: boolean }`), `configured` (`{ glitchtip: boolean; posthog: boolean; vercel: boolean }`), `sections` and `views`.
- **errors-sections-shape**: `sections` MUST be `DashboardSections<ErrorsSectionData>`, with `issues` (`ErrorsIssuesSection`), `sites` (array of `SiteHealthRow`), `detail` (`SiteErrorDetailSection`) and `runtime` (`RuntimeErrorsReport`).
- **errors-refreshing**: `refreshing` MUST be true when either `refreshingSources.glitchtip` or `refreshingSources.posthog` is true.
- **errors-runtime-source**: The `runtime` section MUST be the Vercel runtime errors of the last 24 hours, read from the store; its body is the same as `GET /errors/runtime`. It is read fresh on each request, and without Vercel configured it holds the empty section state.
- **errors-views**: `views` MUST hold what the per-site pages draw, derived on the server.
- **generated-at**: `generatedAt` MUST be an ISO 8601 string of when the response was built (the server clock for analytics, the passed-in `nowMs` for errors).

**PostHog sections**

- **traffic-buckets**: `TrafficSection.buckets` MUST be the ISO bucket starts of the range window; `pageviews` and `sessions` MUST each hold one value per bucket.
- **traffic-totals**: `TrafficSection.totals` MUST carry `pageviews` and `sessions`. `sessions` sums per-bucket uniques, so a session spanning two buckets counts twice.
- **traffic-sites**: `TrafficSection.sites` MUST be a list of `{ host, pageviews, sessions, series }`, with `series` one value per bucket.
- **dimensions-row**: `DimensionRow` MUST carry `host`, `device`, `browser`, `country`, `referrer` (strings) and `pageviews` (number).
- **dimensions-truncated**: `DimensionsSection.truncated` MUST be true when the row cap was hit, which means the tail is missing from every breakdown.
- **path-row**: `PathRow` MUST carry `host`, `path` and `pageviews`.
- **vitals-row**: `VitalsRow` MUST carry `host`, `samples` and four metrics `lcp`, `inp`, `cls`, `fcp`, each a number or null.
- **site-health-row**: `SiteHealthRow` MUST carry `host`, `errors`, `requests`, `failures` and `p95Ms` (a number or null).

**Vercel section**

- **marginal-shape**: `Marginal` MUST carry `name` and `pageviews`.
- **vercel-project-traffic**: `VercelProjectTraffic` MUST carry `project`, `domain` (string or null), `pageviews`, `visitors`, `series` (numbers), the four lists `countries`, `referrers`, `paths`, `devices` (each a list of `Marginal`) and `incomplete`.
- **vercel-project-incomplete**: `incomplete` MUST be true when a breakdown call failed, which makes `series` and the lists short while `pageviews` is still whole.
- **vercel-roster-entry**: `VercelRosterEntry` MUST describe one production project whether or not it has analytics on or any traffic: `project`, `domain`, `analyticsOn`, `pageviews`, `visitors`.
- **vercel-roster-null**: `VercelRosterEntry.pageviews` and `visitors` MUST be null when analytics is off or the count could not be read; null is not a zero.
- **vercel-section-fields**: `VercelTrafficSection` MUST carry `buckets`, `projectsTotal`, `projectsEnabled`, `failed`, `incomplete`, `roster`, `totals` (`{ pageviews, visitors }`), `pageviews`, `visitors` and `projects`.
- **vercel-production-only**: `projectsTotal` counts production projects only; staging and testing are never counted.
- **vercel-failed-count**: `failed` MUST count projects whose count could not be read, which makes `totals` and the roster short.
- **vercel-incomplete-count**: `incomplete` MUST count projects included in `totals` whose breakdowns could not all be read, which makes the series and lists short.

**Errors sections**

- **error-issue-fields**: `ErrorIssue` MUST carry `id`, `shortId` (or null), `title`, `type` (the exception class, or null), `source` (the raising file when GlitchTip knows, or null), `level` (or null), `count`, `userCount`, `firstSeen` and `lastSeen` (or null), `release` (or null), `project`, `permalink` (or null) and `active`.
- **error-issue-active**: `active` MUST use the same test that puts an error on the board, `errorCountsAsProblem` in `board/derive-problems.ts`: the issue's project is on the board's project allowlist (when one is set), its level is a judged level (the source comment says error or fatal), and it was seen within the activity window (24 hours). While the error feed is frozen the recency test is suspended, so a judged-level issue stays active.
- **issues-section**: `ErrorsIssuesSection` MUST carry `buckets`, `issues` and `summary`.
- **issues-summary**: `summary` MUST carry `active`, `backlog`, `events`, `resolved`, `complete`, `byType` and `newPerDay`.
- **issues-resolved-null**: `summary.resolved` MUST be null when the resolved count could not be read.
- **issues-complete**: `summary.complete` MUST be false when GlitchTip's list could not be walked to its end.
- **issues-by-type**: `summary.byType` MUST be a list of `{ name, issues, events }`.
- **issues-new-per-day**: `summary.newPerDay` MUST hold currently unresolved issues counted by the day they first fired.
- **site-error-row**: `SiteErrorRow` MUST carry `host`, `name`, `feature`, `step`, `boundary`, `page` (each of the last four a string or null), `count` and `lastSeen`. PostHog holds no message text, only these names.
- **site-failed-request-row**: `SiteFailedRequestRow` MUST carry `host`, `status`, `method` (or null), `path`, `count` and `lastSeen`. A `status` of 0 means the request never got a response.
- **site-error-days**: `SiteErrorDays` MUST carry `host` and two series, `errors` and `failures`, each with one value per bucket.
- **site-error-detail**: `SiteErrorDetailSection` MUST carry `buckets`, `days`, `errors`, `requests` and `truncated`; it backs each site's own page.
- **site-error-detail-truncated**: `truncated` MUST be true when a row cap was hit, which means the rarest errors or failed requests are missing.

**Parity with the client mirror**

- **mirror-parity**: The client mirror MUST be mutually assignable with these types for `AnalyticsDashboardResponse`, `ErrorsDashboardResponse`, `RuntimeErrorsReport`, `AnalyticsViews` and `ErrorsViews`. A renamed field, a changed nullability or a different union member breaks it.
- **mirror-constants**: The mirror's `ANALYTICS_RANGES`, `DIMENSIONS`, `VERCEL_BREAKDOWNS` and `VITALS` MUST equal the server's lists, in the same order.
- **mirror-check-is-types**: The type half of the parity check is verified by a type check, not by the test run, because the test runner transpiles without type-checking.

## Appearance

Not applicable — this is a set of data type declarations, not a visual component.

## States

Not applicable — this is a set of data type declarations, not a visual component. The loading state of a section is carried by `data`, `error`, `updatedAt` and the response's `refreshing` flag, specified above and in the sectioned-dashboard recipe.

## Accessibility

Not applicable — this is a set of data type declarations, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dash-types-001 | export-range-constant, mirror-constants | Test "offer the same ranges" in `dashboard-types-parity.test.ts`: the mirror's `ANALYTICS_RANGES` and the server's | Equal arrays, `["24h", "7d", "30d"]` |
| dash-types-002 | export-view-constants, mirror-constants | Test "name the same breakdowns and vitals": `DIMENSIONS`, `VERCEL_BREAKDOWNS`, `VITALS` from both sides | Each pair equal, in order: `["country","device","browser","referrer"]`, `["countries","referrers","paths","devices"]`, `["lcp","inp","cls","fcp"]` |
| dash-types-003 | mirror-parity, analytics-response-fields, errors-response-fields | Type check of the `responsesAgree` tuple in the parity test | Compiles only when the five server and mirror types are mutually assignable |
| dash-types-004 | analytics-response-fields, analytics-configured | `analytics("7d")` with neither provider configured | `range` `"7d"`, `configured` `{ posthog: false, vercel: false }`, `refreshing` false, every section `{ data: null, error: null, updatedAt: null }` |
| dash-types-005 | analytics-refreshing | PostHog dashboard refreshing, Vercel idle | `refreshing` true |
| dash-types-006 | errors-refreshing, errors-response-fields | GlitchTip idle, site health refreshing | `refreshing` true; `refreshingSources` `{ glitchtip: false, posthog: true }` |
| dash-types-007 | errors-runtime-source | Vercel not configured | `sections.runtime` is `{ data: null, error: null, updatedAt: null }` |
| dash-types-008 | traffic-buckets, traffic-sites | A `TrafficSection` for range `"7d"` | `buckets` has 7 entries; `pageviews` and `sessions` have 7 values; each `sites[].series` has 7 values |
| dash-types-009 | vercel-roster-null | A project with analytics off | Its roster entry has `analyticsOn` false and `pageviews` and `visitors` null, not 0 |
| dash-types-010 | site-failed-request-row | A request with no response | `status` is 0 |
| dash-types-011 | issues-resolved-null, issues-complete | GlitchTip's resolved count unreadable and list walk cut short | `summary.resolved` null; `summary.complete` false |
| dash-types-012 | generated-at | Any response | `generatedAt` parses as an ISO 8601 date-time |
| dash-types-013 | no-behavior, export-runtime-types | Import `RuntimeErrorGroup` and `RuntimeErrorsReport` from the module | Both resolve as types from `../types` |

## Edge Cases

- **Null and empty values**: Nullable fields (`domain`, `p95Ms`, the vitals metrics, `shortId`, `release`, `permalink`, `firstSeen`, `lastSeen`, `summary.resolved`, `VercelRosterEntry.pageviews`) MUST be sent as `null` when unknown, never as 0 or an empty string. The roster comment says null "is not a zero".
- **Section never loaded or failed**: A section's `data` may be `null` while `error` is set or both are null; clients MUST handle a `null` `data` in every section.
- **Provider not configured**: Its sections are empty and its `configured` flag is false; clients MUST NOT treat that as a failure.
- **Partial answers**: `incomplete`, `failed`, `truncated`, `complete` and `resolved` null signal data that is short. A client MUST NOT present totals from a short answer as whole without saying so. These flags carry the information; the types do not hide it.
- **Row caps**: When `DimensionsSection.truncated` or `SiteErrorDetailSection.truncated` is true, the rarest rows are absent from every derived breakdown.
- **Session counts**: `TrafficSection.totals.sessions` counts a session twice if it spans two buckets, so it is not a deduplicated unique-visitor count.
- **Series length**: Every per-bucket array MUST have the same length as its section's `buckets`; a hole is a zero.
- **Type drift between server and client**: The server and the web mirror can drift apart, because the mirror is hand-kept. The parity test catches it at type-check time only.
- **Concurrent access**: Not applicable: the file declares types and has no state; responses are built per request, and the cache beneath them is specified in the sectioned-dashboard recipe.
- **Error and offline states**: Not applicable here: the module does no I/O; a provider failure is carried in each section's `error` field, and the type has no separate failure envelope for the whole response.
- **Boundary values**: Not applicable: the types constrain no numeric ranges; the only enumerations are the range, dimension, breakdown and vital lists.

## Configuration

Not applicable: the module reads no environment variables, settings or injected dependencies. Which providers are configured is decided by `dashboard-set.ts` and reported through the `configured` flags.

| Option | Type | Default | Description |
|--------|------|---------|-------------|

## Deep Linking

Not applicable: the module has no URLs or routes of its own. The two endpoints are `GET /analytics/dashboard` (query `range`, default `7d`) and `GET /errors/dashboard`, served by `routes/telemetry-dashboards.ts`.

## Localization

Not applicable: the types carry data fields only and no display strings. The `Dimension`, vital and breakdown names are machine identifiers.

## Accessibility Options

Not applicable: the module is not a visual component, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply to it.

## Feature Flags

Not applicable: the source reads no flags. The `configured` fields report provider setup, not feature flags.

## Analytics

Not applicable: the module emits no events. It describes the data of analytics dashboards.

## Privacy

Not applicable as a data handler: the module stores and sends nothing. The shapes describe site-level aggregates (hosts, paths, counts, countries, browsers) and error summaries; the `SiteErrorRow` comment notes that PostHog holds no message text, only names, and `RuntimeErrorGroup.message` is the first line of a runtime message, at most 200 characters. No field holds a credential.

## Logging

Not applicable: the source makes no log calls.

## Platform Notes

- **SwiftUI**: Port the shapes as `Codable` structs with `Optional` for each nullable field. Use `JSONDecoder` with the same field names. The `sections` generic maps to a `struct DashboardSection<T: Codable>`. Decode the `views` structures from the same JSON and let the view models read them. Dates are ISO strings; decode them with `ISO8601DateFormatter` with fractional seconds only where the field is a timestamp.
- **Compose**: Use `kotlinx.serialization` `@Serializable` data classes with nullable types for the null fields, and a generic `DashboardSection<T>`. Keep the same JSON names. Treat an unknown extra field as ignorable (`ignoreUnknownKeys = true`) so server additions do not break the client.
- **React/Web**: This is the source platform. `types.ts` in `packages/web/packages/status-server/src/telemetry/dashboard/` is the source of truth. It is exposed to clients as `@adh-sdk/status-server/dashboard-types`; `status-web` keeps the hand mirror in `telemetry/dashboard-types.ts` and the `dashboard-types-parity.test.ts` drift guard.
- **AppKit / UIKit**: Use the same `Codable` structs as SwiftUI and feed them to table or collection views. Keep optionals optional so a null cell shows a dash instead of 0, matching the null-is-not-zero rule.
- **WinUI 3**: Port as C# `record` types (or classes) deserialised with `System.Text.Json`. Use `JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase }` to match the camel-case fields, `int?` and `double?` for the nullable numbers (`p95Ms`, `lcp`, `pageviews` in the roster), `string?` for the nullable strings, and `DateTimeOffset` or `string` for the ISO fields. Model `DashboardSection<T>` as a generic record with `T? Data`. The `Marginal`, `Dimension` and vital enums can be `enum` types with `JsonStringEnumConverter` and a camel-case policy, or plain strings. For `ObservableCollection` binding, wrap the arrays in a view model that implements `INotifyPropertyChanged`; keep the DTOs plain. Fetch with `HttpClient.GetFromJsonAsync` and poll while `Refreshing` is true. Because JSON `number` covers integers and decimals, use `long` for counts only if the server's counts can exceed `int`; the source does not say, so `double` is the safe default. In an ASP.NET Core server, the same records are the minimal API response types.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-server/src/telemetry/dashboard/types.ts` | confirmed (1.0.0) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The response is a set of independently cached sections plus a derived `views` object, instead of one finished document.
**Rationale**: `AnalyticsDashboardResponse.views` is described as "what the pages draw, derived from `sections` on the server". The sections let the client show data as each provider answers; the views keep the shaping on the server so pages draw directly.

**Approved**: pending

**Decision**: Unknown, unreadable or short values are signalled with `null`, `incomplete`, `failed`, `truncated` and `complete` fields rather than being zero-filled or hidden.
**Rationale**: The roster comment says a null count "is not a zero". The flags let a page show that a total is a floor instead of whole.

**Approved**: pending

**Decision**: The client keeps a hand mirror of these types, held to the server by a type-level parity test.
**Rationale**: The comment says status-web has the server only as a devDependency, and that the parity test is a typecheck "that catches drift: `pnpm test` transpiles without checking types". This is a known cost: the mirror can drift without a failing test run.

**Approved**: pending

**Decision**: `sessions` in `TrafficSection.totals` sums per-bucket uniques.
**Rationale**: The field comment states "a session spanning two buckets counts twice". The total is the sum of the per-bucket series and not a distinct count.

**Approved**: pending

**Decision**: The errors response has a separate `refreshingSources` object besides `refreshing`.
**Rationale**: The comment says "`refreshing` is either of them". GlitchTip and PostHog refresh independently, and a page can tell which is still filling in.

**Approved**: pending

**Decision**: The Vercel runtime section is read fresh from the store on every request and is not part of any cached view input.
**Rationale**: The `dashboard-set.ts` comment says "Runtime is read fresh every request and no view uses it, so it is not an input".

**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.access-patterns.api-design-conventions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b6745c95-4ef2-5ab4-8791-00ffc1d7b82d) | partial | access-patterns |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | internationalization |

Separation of concerns passes: the file declares shapes and re-exports and holds no logic, with building in `dashboard-set.ts` and derivation in `views.ts`. Unit-test coverage is partial: `dashboard-types-parity.test.ts` checks the constants and the type agreement of five response types, but no test asserts the runtime shape of a built response field by field. API design conventions are partial: the endpoints share one section envelope and ISO strings for times, but the file records no version field and relies on the hand-kept client mirror to track changes. No user-facing strings exist; the identifiers are machine names.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
