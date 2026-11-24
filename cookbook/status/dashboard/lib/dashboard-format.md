---
id: c861465b-50c8-49d1-93cc-00d9e062ad5f
title: "Dashboard Formatting"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Presentation helpers for the analytics and errors pages: UTC bucket labels, web-vital values, the server's site list and one site's report."
platforms:
  - typescript
  - web
tags:
  - dashboard
  - formatting
  - analytics
depends-on: []
related:
  - 564c6102-e100-41ad-9c92-14606a33c394
references: []
approved-by: ""
approved-date: ""
---

# Dashboard Formatting

Dashboard Formatting words the values the status server derived for the Analytics and Errors pages, as pure functions.

## Overview

Dashboard Formatting is a set of six pure functions that word what the status server derived for the Analytics and Errors pages. They are presentation only: the source's header comment says every join, sort, threshold and rating happens on the server and arrives in the response's `views`. The module has no state, no I/O and no dependency beyond two types from the dashboard wire types (an analytics range, and a web vital).

It exports:

- **the bucket-label function** (`bucketLabel`) — takes an ISO timestamp and an analytics range and returns the short axis label: `HH:mm` for the `24h` range, otherwise a short month and day.
- **the bucket-detail function** (`bucketDetail`) — the same bucket for a tooltip or table, with the time zone stated.
- **the vital-formatting function** (`formatVital`) — takes a web vital and a number and returns the value in its unit.
- **the listed-sites function** (`listedSites`) — takes a dashboard response body, or `undefined`, and returns the server's site list or `null`.
- **the with-site function** (`withSite`) — places one extra site name into that list.
- **the site-report function** (`siteReportFor`) — returns the server's report for the site a URL names, or a caller-supplied "none" value.

The callers are the analytics and errors pages and the board shell, which feeds the site rail from `listedSites` and `withSite`. For general number and duration formatting see Format ([adhsdk.ingredient.status.dashboard.logic.format](cookbook:564c6102-e100-41ad-9c92-14606a33c394)); this module covers only the dashboard-specific wording.

### API

- `bucketLabel(iso: string, range: AnalyticsRange): string` — `iso` is an ISO 8601 timestamp for the start of a bucket; `range` is `"24h"`, `"7d"` or `"30d"`, and `"24h"` chooses the hour format while any other value takes the day format.
- `bucketDetail(iso: string, range: AnalyticsRange): string` — the same parameters as `bucketLabel`.
- `formatVital(vital: Vital, value: number): string` — `vital` is `"lcp"`, `"inp"`, `"cls"` or `"fcp"` and picks the unit; `value` is the raw measurement.
- `listedSites(body: { views?: { sites?: string[] } } | undefined): string[] | null` — a dashboard response body, or the absence of one.
- `withSite(sites: readonly string[], site: string | null): string[]` — the server's list and the site the URL names.
- `siteReportFor<T>(reports: Readonly<Record<string, T>>, site: string, none: T): T` — the server's per-site reports, the URL's site, and what to return when there is none.
## Behavioral Requirements

### Bucket labels

- **bucket-utc**: Both bucket functions MUST format the timestamp in UTC, never in the viewer's local zone; the source's comment gives the reason: buckets are UTC, and "a local 'Nov 3' over a UTC-day bucket would be a different day's traffic for anyone west of Greenwich."
- **label-24h**: The bucket-label function MUST return the hour and minute as two digits each on a 24-hour clock (for example `14:00`) when the range is `"24h"`.
- **label-days**: The bucket-label function MUST return the abbreviated English month and the day of the month with no zero padding (for example `Nov 4`) when the range is `"7d"` or `"30d"`.
- **detail-24h**: The bucket-detail function MUST return the day label, a comma and a space, the 24-hour time and the suffix ` UTC` (for example `Nov 4, 14:00 UTC`) when the range is `"24h"`.
- **detail-days**: The bucket-detail function MUST return the day label followed by ` (UTC)` (for example `Nov 4 (UTC)`) when the range is `"7d"` or `"30d"`.
- **label-locale**: Both bucket functions MUST use English month names regardless of the viewer's locale.
- **label-invalid-date**: Both bucket functions MAY throw when the timestamp does not parse to a valid date; the source does so because the underlying date formatter throws a range error for an invalid date, and the module does not guard against it. Callers MUST NOT rely on the error type.

### Vital values

- **vital-cls**: The vital-formatting function MUST return the value with exactly two decimal places and no unit when the vital is `"cls"` (for example `0.1` becomes `0.10`).
- **vital-ms**: The vital-formatting function MUST return the value rounded to the nearest whole number followed by `ms` (for example `180` becomes `180ms`) when the vital is not `"cls"` and the value is below 1000.
- **vital-seconds**: The vital-formatting function MUST return the value divided by 1000, with exactly one decimal place, followed by `s` (for example `2400` becomes `2.4s`) when the vital is not `"cls"` and the value is 1000 or more.
- **vital-threshold-before-rounding**: The vital-formatting function MUST compare the raw value against 1000 before rounding, so a value of `999.6` is written `1000ms` and not `1.0s`.
- **vital-no-validation**: The vital-formatting function SHOULD NOT validate the value; as observed in the source, a negative number is written in milliseconds (`-5` becomes `-5ms`), and `NaN` is written as the text `NaN` for `"cls"` and `NaNms` for the other vitals.

### Site list

- **listed-present**: The listed-sites function MUST return the body's `views.sites` list itself, not a copy, when the body has one.
- **listed-absent**: The listed-sites function MUST return `null` when the body is `undefined`, has no `views`, or has a `views` with no `sites`; the source comment names the case: a backend older than `views` (a staggered deploy or a rollback) "must leave the rail empty rather than throw during render."
- **listed-empty-list**: The listed-sites function MUST return an empty list as an empty list, not `null`, when the server sent `sites: []`.
- **with-copy**: The with-site function MUST return a new list and MUST NOT mutate or return the list it was given.
- **with-none-or-listed**: The with-site function MUST return a copy of the list in its original order when the site is `null` or already in the list.
- **with-unlisted**: The with-site function MUST add a site that is not in the list and sort the whole result alphabetically using the platform's locale comparison (the order across runtimes is unspecified, because the source passes no locale), so a deep-linked site the server has no data for yet is still shown as selected.
- **with-exact-match**: The with-site function MUST treat a site as listed only on an exact, case-sensitive match.
- **with-sort-whole-list**: Because the sort runs over the whole result, the with-site function MAY reorder the server's entries too when it adds a site and the server's order differs from the locale order; this is observed behavior, not a requirement ports must copy.

### Site report

- **report-own-entry**: The site-report function MUST return the entry stored under `site` when the reports object has an own entry by that name.
- **report-none**: The site-report function MUST return the caller's `none` value, unchanged and by reference, when the reports object has no own entry for `site`.
- **report-inherited-names**: The site-report function MUST treat inherited property names such as `constructor`, `toString`, `hasOwnProperty` and `__proto__` as absent, because a site segment taken from a URL could otherwise read a function or the shared prototype object as a report; this is the reason the source gives for checking own entries.
- **report-no-copy**: The site-report function MUST return the stored entry itself, not a copy.

### Purity and ordering

- **pure-functions**: Every exported function MUST be pure: it MUST NOT mutate its arguments, read the clock, use storage or the network, or log.
- **synchronous**: Every exported function MUST return synchronously and MUST NOT depend on call order; the module holds no state, so concurrent calls cannot interleave.
- **module-formatters**: The two date formatters SHOULD be created once when the module loads and reused on every call, not rebuilt per call.

## Appearance

Not applicable — this is a set of formatting functions, not a visual component.

## States

Not applicable — this is a set of formatting functions, not a visual component.

## Accessibility

Not applicable — this is a set of formatting functions, not a visual component.

## Conformance Test Vectors

Vectors 001–011 are the assertions in `dashboard-format.test.ts`; the rest are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dfmt-001 | label-days, bucket-utc | test "label in UTC": bucket-label of `2026-11-04T00:00:00.000Z` with `"7d"` | `Nov 4` |
| dfmt-002 | label-24h | bucket-label of `2026-11-04T14:00:00.000Z` with `"24h"` | `14:00` |
| dfmt-003 | detail-24h | bucket-detail of `2026-11-04T14:00:00.000Z` with `"24h"` | `Nov 4, 14:00 UTC` |
| dfmt-004 | detail-days | bucket-detail of `2026-11-04T00:00:00.000Z` with `"30d"` | `Nov 4 (UTC)` |
| dfmt-005 | vital-seconds, vital-ms, vital-cls | test "writes each vital in its unit": `("lcp", 2400)`, `("inp", 180)`, `("cls", 0.1)` | `2.4s`, `180ms`, `0.10` |
| dfmt-006 | listed-present | test "is the server's list": body with `views.sites` of `["a.com","b.com"]` | `["a.com","b.com"]` |
| dfmt-007 | listed-absent | test "is null, not a throw": `undefined`, `{}`, and `{ views: {} }` | `null` for each |
| dfmt-008 | with-none-or-listed | test "keeps the server's list": `(["a.com","c.com"], "c.com")` and `(["a.com"], null)` | `["a.com","c.com"]` and `["a.com"]` |
| dfmt-009 | with-unlisted | test "puts a deep-linked site": `(["a.com","c.com"], "b.com")` | `["a.com","b.com","c.com"]` |
| dfmt-010 | report-own-entry | test "returns the server's report": reports with `example.com` mapped to `{ empty: false }`, site `example.com` | `{ empty: false }` |
| dfmt-011 | report-inherited-names, report-none | test "treats %s as no report" for `unknown.com`, `constructor`, `toString`, `hasOwnProperty`, `__proto__` | the `none` value itself, for each (five cases) |
| dfmt-012 | with-copy | `with-site` on `["a.com"]` with `"a.com"`; compare identity | an equal list that is not the same object |
| dfmt-013 | listed-empty-list | body with `views.sites` of `[]` | `[]`, not `null` |
| dfmt-014 | vital-threshold-before-rounding | `("lcp", 999.6)` and `("lcp", 1000)` | `1000ms` and `1.0s` |
| dfmt-015 | vital-no-validation | `("inp", -5)` and `("cls", NaN)` | `-5ms` and `NaN` |
| dfmt-016 | label-invalid-date | bucket-label of `not-a-date` with `"7d"` | throws a range error |
| dfmt-017 | with-sort-whole-list | `(["c.com","a.com"], "b.com")` | `["a.com","b.com","c.com"]` (ASCII names sort the same under any sensible collation) |
| dfmt-018 | with-exact-match | `(["a.com"], "A.com")` | `["a.com","A.com"]` under the default English ICU collation, which puts lowercase first (the lookup is case-sensitive, so the site is added; the order of the two is unspecified across runtimes, so a port MAY order them differently) |

| dfmt-019 | vital-ms | `("lcp", 999.4)` | `999ms` |
| dfmt-020 | label-days | bucket-label of `2026-11-04T00:00:00.000Z` with an unknown range `"1y"` | `Nov 4`, the day format |
| dfmt-021 | bucket-utc | bucket-label of `2026-11-04T23:59:59.999Z` with `"7d"` | `Nov 4`, the earlier day |
| dfmt-022 | report-none | empty reports object, site `""`, a `none` value | the `none` value itself |
## Edge Cases

- **Null and empty input — site list**: a `null` site and an empty list MUST give an empty copy; `undefined` body and a body with no `views` MUST give `null` from the listed-sites function, which callers read as "nothing to show."
- **Null and empty input — reports**: an empty reports object MUST give the `none` value for any site, including the empty string.
- **Boundary — vitals at 1000**: exactly `1000` MUST be written `1.0s`; `999.4` MUST be written `999ms`; `999.5` and above rounds to `1000ms` because the comparison runs on the raw value.
- **Boundary — day buckets near midnight UTC**: a timestamp one millisecond before midnight UTC MUST label the earlier day, whatever the viewer's zone is.
- **Malformed input — timestamps**: an unparseable timestamp makes the bucket functions throw; callers pass timestamps the server produced, and nothing here catches the error.
- **Malformed input — range**: any range other than `"24h"` takes the day format, so an unknown range string is formatted like `"7d"`.
- **Malformed input — site names**: names from a URL are used as given; the report lookup is protected against inherited property names, but the module does no decoding, trimming or case folding.
- **Concurrent access**: not applicable — the functions are pure and hold no state beyond two immutable formatters, so any number of calls may run in any order.
- **Error states and offline**: not applicable — the module performs no I/O and has no dependency that can fail or disconnect.
- **Cancellation and timeouts**: not applicable — every call completes synchronously.
- **Locale**: the sort in the with-site function uses the runtime's default locale, so the order of non-ASCII or mixed-case names can differ between runtimes; the date formatters are fixed to English and UTC.

## Configuration
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Hour format | constant | English, two-digit hour and minute, 24-hour cycle, UTC | Fixed in the module. Not configurable. |
| Day format | constant | English, short month and numeric day, UTC | Fixed in the module. Not configurable. |
| Seconds threshold | constant | `1000` | Values at or above this are written in seconds. Not configurable. |

The module reads no environment variables or settings keys and takes no injected dependency. The function parameters are in the API section of the Overview.
## Deep Linking

Not applicable: the module registers no route or URL; it only copes with a site name that a URL happens to carry.

## Localization

The module formats dates with fixed English month names and a fixed UTC zone, and writes the literal suffixes ` UTC`, ` (UTC)`, `ms` and `s`. These are hardcoded English strings that are not externalised, so a viewer with another locale still sees English month names. The fixed zone is deliberate (see Design Decisions); the fixed language is recorded as a pending Design Decision, though the source states no reason for it. Sorting in the with-site function follows the runtime's default locale.

## Accessibility Options

Not applicable: the module has no visual output and responds to no display setting; it returns text for the pages to render.

## Feature Flags

Not applicable: no function reads a flag or branches on configuration.

## Analytics

Not applicable: the module emits no events.

## Privacy

Not applicable: the module handles timestamps, numbers and site names it is given, stores nothing and transmits nothing.

## Logging

Not applicable: no function in the module logs.

## Platform Notes

- **SwiftUI**: Port as free functions or static members of an `enum DashboardFormat`. Build the two date formats once with `Date.FormatStyle` (or `DateFormatter`) fixed to `Locale(identifier: "en")` and `TimeZone(identifier: "UTC")` with `.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)` for `HH:mm`, and `.dateTime.month(.abbreviated).day()` for `Nov 4`; parse the ISO string with `ISO8601DateFormatter` including fractional seconds. Write `formatVital` with `String(format: "%.2f")` and `.rounded()`; compare against `1000` before rounding. `withSite` is `(sites + [site]).sorted { $0.localizedCompare($1) == .orderedAscending }`. `siteReportFor` is a plain dictionary lookup, which is already own-key only, so the inherited-name guard is not needed. Return `[String]?` from `listedSites`.
- **Compose**: Kotlin top-level functions in an `object DashboardFormat`. Use `java.time.format.DateTimeFormatter.ofPattern("HH:mm", Locale.ENGLISH).withZone(ZoneOffset.UTC)` and `"MMM d"` for the labels, parsing with `Instant.parse`. `String.format(Locale.ROOT, "%.2f", value)` writes the vital; note that `%.1f` rounds half up where JavaScript's `toFixed` works on the binary value, so edge digits can differ. `withSite` uses `(sites + site).sortedWith(String.CASE_INSENSITIVE_ORDER)` only if locale parity is not required; use `java.text.Collator` to approximate `localeCompare`. Use a `Map<String, T>` lookup for reports, which has no inherited keys.
- **React/Web**: Source platform. `packages/web/packages/status-web/src/lib/dashboard-format.ts` holds the functions and `dashboard-format.test.ts` beside it is the Vitest suite behind vectors 001–011. The two `Intl.DateTimeFormat` instances are module constants with `timeZone: "UTC"` and `hourCycle: "h23"`; `Intl` throws a range error for an invalid date, which is where label-invalid-date comes from. `siteReportFor` uses `Object.hasOwn`, the guard against `constructor` and `__proto__` that a plain index lookup lacks; `toFixed` works on the binary value, and `Math.round` rounds halves toward positive infinity. Callers are `AnalyticsParts.tsx`, `ErrorsView.tsx`, `ErrorsSitePage.tsx`, `AnalyticsSitePage.tsx` and `BoardShell.tsx`. The module has no `"use client"` directive because it uses no React.
- **AppKit / UIKit**: The same Swift port as SwiftUI; share it from a framework target. Use `DateFormatter` with a fixed `en` locale, `UTC` zone and format strings `HH:mm` and `MMM d`, and keep the formatters as static properties because `DateFormatter` is expensive to build, mirroring the module-level constants in the source.
- **WinUI 3**: A C# `static class DashboardFormat` in a .NET class library. Parse with `DateTimeOffset.Parse(iso, CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal)` (it throws `FormatException` where the source throws a range error), and format with `ToUniversalTime().ToString("HH:mm", CultureInfo.InvariantCulture)` and `"MMM d"` using `new CultureInfo("en-US")`. `FormatVital` uses `value.ToString("F2", CultureInfo.InvariantCulture)` for CLS and `Math.Floor(value + 0.5)` for milliseconds, which matches JavaScript's `Math.round` on negative halves (`-2.5` gives `-2`); `MidpointRounding.AwayFromZero` would give `-3`, and the default `Math.Round` rounds halves to even. `ListedSites` returns `IReadOnlyList<string>?`. `WithSite` copies into a `List<string>` and sorts with `StringComparer.CurrentCulture`, close to `localeCompare`. `SiteReportFor` is `reports.TryGetValue(site, out var report) ? report : none` on an `IReadOnlyDictionary<string, T>`, which holds only its own keys. Nothing here needs `Task`/`async`, `ObservableCollection` or `INotifyPropertyChanged`; expose the results as bound properties from the view model that owns the dashboard response. Deserialise the response with `System.Text.Json` and map `views` and `sites` to nullable types so a missing `views` reads as `null`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-web/src/lib/dashboard-format.ts` | confirmed (1.0.2) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Bucket labels are formatted in UTC.
**Rationale**: The source comment: buckets are UTC, so they are labelled in UTC; "a local 'Nov 3' over a UTC-day bucket would be a different day's traffic for anyone west of Greenwich." Detail text states the zone (` UTC`, ` (UTC)`) because a tooltip or table has room to say it.
**Approved**: pending

**Decision**: The module words values and does not derive them.
**Rationale**: The header comment: every join, sort, threshold and rating is computed by the status server and arrives in `views`, so clients show the same answer and a port has little logic to copy.
**Approved**: pending

**Decision**: `listedSites` returns `null` for a missing list instead of throwing or returning an empty list.
**Rationale**: Doc comment: a backend older than `views` (staggered deploy, rollback) sends none, which "must leave the rail empty rather than throw during render." Returning `null` also lets a caller tell "no read yet" apart from a server that sent an empty list.
**Approved**: pending

**Decision**: `withSite` adds a URL-named site that the server lacks and re-sorts the whole list.
**Rationale**: Doc comment: a deep link to a site with no data yet must still show as selected. The list is otherwise in the server's order, so the helper is used only for that case, and the re-sort of the whole list is a simple way to find the new site's place.
**Approved**: pending

**Decision**: `siteReportFor` checks own entries with `Object.hasOwn`.
**Rationale**: Doc comment: a site segment such as `constructor` or `__proto__` would otherwise read a property every object inherits, "and the page would destructure a function or Object.prototype as a report."
**Approved**: pending

**Decision**: Vitals use milliseconds below 1000 and seconds with one decimal above, and CLS has two decimals and no unit.
**Rationale**: Doc comment: "CLS is unitless, the rest are milliseconds." The seconds form keeps long values short. The threshold compares the raw value, so a value that rounds up to 1000 reads `1000ms`, a small inconsistency kept as the source behaves. Known debt: the source does not record the inconsistency as a defect; the remedy is to compare after rounding, so `999.6` reads `1.0s`.
**Approved**: pending


**Decision**: Month names and the literal suffixes (` UTC`, ` (UTC)`, `ms`, `s`) are fixed English strings.
**Rationale**: The source builds both date formatters with the `"en"` locale and writes the suffixes as literals, so every viewer sees the same wording. It is a choice that affects what ports show, so it is recorded here for review rather than left implicit.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.good-test-properties](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9144e220-ad70-51db-ba81-cdb0cc1b66c8) | passed | best-practices |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | partial | internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | internationalization |

**Separation of Concerns**: The functions only word values; the derivation lives in the status server and the rendering in the pages and charts, so the module has one reason to change.

**Unit Test Coverage**: `dashboard-format.test.ts` has a test for each of vectors dfmt-001 to dfmt-022, covering every exported function, the 1000 boundary, rounding to 1000, invalid timestamps, an unknown range, the whole-list re-sort, the inherited-name guard and the absent-views path.

**Good Test Properties**: The tests are deterministic, use fixed timestamps and one table-driven case, and do not depend on the viewer's zone because the code and the expected values are both UTC.

**Locale Aware Formatting**: Dates use `Intl` rather than hand-built strings, but the locale and zone are fixed to English and UTC on purpose, and the with-site sort follows the runtime's default locale, so formatting is consistent rather than locale-aware.

**String Externalization**: The ` UTC`, ` (UTC)`, `ms` and `s` literals and the English month names are hardcoded in the module and not routed through a string table.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (dashboard-format.test.ts, 22 of 22 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Added tags and an intro sentence, recorded the 999.6 debt and a fixed-English decision, softened incidental MUSTs, corrected the WinUI and React rounding notes, moved function signatures into an Overview API section, and added vectors dfmt-019 to dfmt-022. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial recipe extracted from `dashboard-format.ts` |
