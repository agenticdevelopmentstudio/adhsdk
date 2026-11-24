---
id: d4e7dd53-4771-425f-af0a-0186ba89c3ef
title: "Analytics Ranges"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Shared time axis for the Analytics and Errors dashboards: the 24h, 7d and 30d ranges, their UTC bucket windows, and zero-filling alignment of provider points."
platforms:
  - typescript
  - web
tags:
  - status
  - telemetry
  - dashboard
  - time-series
depends-on: []
related:
  - f06a7f7a-1b36-4dfc-a17d-71d20d576155
  - 77587f0b-5a27-44d9-a507-46bb90c9046a
  - 4dc15a9e-c129-412a-9f14-e35146563d8d
  - 55ffb81c-6a7d-4837-9180-0b5d3fe952ec
references: []
approved-by: ""
approved-date: ""
---

# Analytics Ranges

## Overview

`ranges.ts` defines the time axis that the Analytics and Errors dashboard topics share. It names the three selectable ranges, turns a range and a clock reading into a window of bucket start times, and aligns a provider's timestamped values onto that window.

Every provider's answer is aligned onto the same buckets, so a quiet hour reads as a zero rather than a gap, and PostHog's and Vercel's series can share one chart. The module is pure: it reads no clock, no network and no storage. The caller passes the current time in as `nowMs`.

## Behavioral Requirements

**Range names**

- **range-names**: `ANALYTICS_RANGES` MUST be the ordered list `"24h"`, `"7d"`, `"30d"`.
- **range-type**: `AnalyticsRange` MUST be the union of exactly those three strings.
- **range-validation-by-callers**: Callers that accept a range from outside the process MUST validate it against `ANALYTICS_RANGES` first. This module does not validate; `rangeWindow` takes only an `AnalyticsRange`, and any other value is outside its contract.

**Window shape**

- **window-fields**: `rangeWindow(range, nowMs)` MUST return a `RangeWindow` with `since`, `until`, `unit` and `buckets`.
- **window-until**: `until` MUST be a `Date` equal to `nowMs`, unaligned to any bucket.
- **window-buckets-format**: Each entry of `buckets` MUST be an ISO 8601 string in the form produced by `Date.prototype.toISOString` (UTC, with milliseconds and a trailing `Z`).
- **window-buckets-order**: `buckets` MUST be ordered oldest first, with consecutive entries one step apart.
- **window-since-is-first-bucket**: `since` MUST equal the first bucket's start.

**The 24h window**

- **window-24h-unit**: For `"24h"`, `unit` MUST be `"hour"` and the step MUST be 3,600,000 ms.
- **window-24h-start**: For `"24h"`, the first bucket MUST start 24 hours before the start of the hour that contains `nowMs`.
- **window-24h-count**: For `"24h"`, `buckets` MUST hold 25 entries: 24 full hours plus the current, partial hour.
- **window-24h-last-bucket**: For `"24h"`, the last bucket MUST be the start of the hour that contains `nowMs`.

**The 7d and 30d windows**

- **window-day-unit**: For `"7d"` and `"30d"`, `unit` MUST be `"day"` and the step MUST be 86,400,000 ms (24 hours).
- **window-day-count**: For `"7d"`, `buckets` MUST hold 7 entries; for `"30d"`, 30 entries.
- **window-day-boundaries**: Day buckets MUST start at 00:00:00.000 UTC, computed by flooring `nowMs` to a multiple of 86,400,000 ms.
- **window-day-includes-today**: The last day bucket MUST be the UTC day that contains `nowMs`, and the first MUST be `days - 1` days earlier. The source comment states "that many UTC days including today".
- **window-day-no-local-time**: Day boundaries MUST NOT depend on the host's time zone or daylight-saving rules; they follow UTC arithmetic on epoch milliseconds only.

**Alignment**

- **align-length**: `alignToBuckets(buckets, points)` MUST return an array the same length as `buckets`, in the same order.
- **align-zero-fill**: A bucket that no point lands in MUST hold `0`.
- **align-sum**: Points that land in the same bucket MUST be summed, not replaced or averaged.
- **align-exact-match**: A point MUST land in a bucket only when its timestamp, parsed and re-serialised with `toISOString`, equals the bucket string exactly. The module MUST NOT round a timestamp down to the containing bucket; a provider whose timestamps are not already on a bucket boundary has them dropped.
- **align-timestamp-spellings**: A timestamp MAY be a string or a number. Both `"2026-11-04T00:00:00Z"` and `"2026-11-04T00:00:00.000Z"` MUST land on the bucket `"2026-11-04T00:00:00.000Z"`.
- **align-drop-off-axis**: A point whose timestamp matches no bucket MUST be dropped.
- **align-drop-unparseable**: A point whose timestamp is neither a string nor a number, or whose string or number does not parse to a valid date, MUST be dropped without throwing. `null`, `undefined`, objects and `"nope"` all fall in this case.
- **align-input-iterable**: `points` MAY be any iterable of `[timestamp, value]` pairs; it is consumed once.
- **align-value-added-as-is**: The value of a matched point MUST be added to the bucket total as given. The function does not validate it, and a non-numeric or `NaN` value is outside its contract; callers MUST coerce values to numbers before the call, as the sibling modules do.
- **align-pure**: `alignToBuckets` MUST NOT modify `buckets` or its input pairs.

**Side effects**

- **no-side-effects**: Neither function MUST read a clock, perform I/O, log or keep state. The same inputs MUST give the same outputs.

## Appearance

Not applicable — this is a time-axis helper, not a visual component.

## States

Not applicable — this is a time-axis helper, not a visual component. Both functions are stateless; nothing in the module moves between states.

## Accessibility

Not applicable — this is a time-axis helper, not a visual component.

## Conformance Test Vectors

The vectors use `NOW = 2026-11-04T15:30:20.000Z`, the clock reading in `telemetry-dashboard-sections.test.ts`. Vectors 001 to 003 and 006 and 007 come from the `rangeWindow` and `alignToBuckets` blocks of that test file.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ranges-001 | range-names, range-type | Read `ANALYTICS_RANGES` | `["24h", "7d", "30d"]` |
| ranges-002 | window-24h-unit, window-24h-count, window-24h-start, window-24h-last-bucket, window-buckets-format | Test "24h is 25 hourly buckets ending in the current hour": `rangeWindow("24h", NOW)` | `unit` is `"hour"`; 25 buckets; first `"2026-11-03T15:00:00.000Z"`; last `"2026-11-04T15:00:00.000Z"` |
| ranges-003 | window-day-unit, window-day-count, window-day-boundaries, window-day-includes-today | Test "7d and 30d are that many UTC days including today": `rangeWindow("7d", NOW)` and `rangeWindow("30d", NOW)` | 7d: `unit` `"day"`, 7 buckets, first `"2026-10-29T00:00:00.000Z"`, last `"2026-11-04T00:00:00.000Z"`; 30d: 30 buckets |
| ranges-004 | window-until, window-since-is-first-bucket, window-fields | `rangeWindow("7d", NOW)` | `until` equals `new Date(NOW)`; `since` is `2026-10-29T00:00:00.000Z` |
| ranges-005 | window-buckets-order, window-24h-count | `rangeWindow("24h", NOW).buckets` | Strictly ascending; every consecutive pair 3,600,000 ms apart |
| ranges-006 | align-zero-fill, align-timestamp-spellings, align-sum | Test "zero-fills, tolerates either timestamp spelling, and sums repeats": buckets `["2026-11-03T00:00:00.000Z", "2026-11-04T00:00:00.000Z"]`, points `["2026-11-04T00:00:00Z", 2]` and `["2026-11-04T00:00:00.000Z", 3]` | `[0, 5]` |
| ranges-007 | align-drop-off-axis, align-drop-unparseable | Test "drops what is off the axis or unparseable": same buckets, points `["2026-01-01T00:00:00Z", 9]`, `["nope", 9]`, `[null, 9]` | `[0, 0]`; nothing thrown |
| ranges-008 | window-day-boundaries, window-day-no-local-time | `rangeWindow("7d", Date.parse("2026-11-04T00:00:00.000Z"))` run once under `TZ=UTC` and once under `TZ=Pacific/Chatham`, with identical output | Last bucket `"2026-11-04T00:00:00.000Z"`; first `"2026-10-29T00:00:00.000Z"` |
| ranges-009 | window-24h-start, window-24h-last-bucket | `rangeWindow("24h", Date.parse("2026-11-04T15:00:00.000Z"))` (exactly on the hour) | First `"2026-11-03T15:00:00.000Z"`; last `"2026-11-04T15:00:00.000Z"`; 25 buckets |
| ranges-010 | align-exact-match | Buckets as in ranges-006, point `["2026-11-04T06:00:00Z", 4]` (inside the day, not on its boundary) | `[0, 0]`; the point is dropped, not rounded |
| ranges-011 | align-timestamp-spellings | Buckets as in ranges-006, point `[Date.parse("2026-11-03T00:00:00.000Z"), 6]` (a number) | `[6, 0]` |
| ranges-012 | align-length, align-zero-fill | `alignToBuckets([], [["2026-11-04T00:00:00Z", 1]])` | `[]` |
| ranges-013 | align-input-iterable | Buckets as in ranges-006; points supplied as a generator yielding the one pair `["2026-11-04T00:00:00.000Z", 1]` | The pair is counted once; the result is `[0, 1]` |
| ranges-014 | align-pure | Call `alignToBuckets` twice with the same arrays | Equal results; the `buckets` array is unchanged |
| ranges-015 | window-day-includes-today, window-day-count | `rangeWindow("30d", NOW)` | 30 buckets; first `"2026-10-06T00:00:00.000Z"`; last `"2026-11-04T00:00:00.000Z"` |

## Edge Cases

- **Empty bucket list**: `alignToBuckets([], points)` MUST return `[]`, because nothing can match. Not a source-defined case in the tests; it follows from the length rule.
- **Empty points**: An empty iterable MUST give an all-zero array of the bucket length.
- **Timestamp on a bucket boundary but a different spelling**: Parsing then re-serialising MUST normalise it, so `"...T00:00:00Z"` and `"...T00:00:00.000Z"` agree.
- **Timestamp inside a bucket but off its start**: MUST be dropped. The module matches bucket starts exactly and has no rounding. A provider that returns finer-grained timestamps needs to truncate them first.
- **Unparseable or non-scalar timestamp**: `"nope"`, `null` and any value that is not a string or number MUST be skipped without an error.
- **Timestamp outside the window**: Points older than `since` or newer than the last bucket MUST be dropped.
- **Time of day exactly on an hour or day boundary**: For `"24h"`, a `nowMs` on the hour still yields 25 buckets, with the current hour as the last and zero elapsed time in it. For day ranges, a `nowMs` of 00:00:00.000 UTC makes that new day the last bucket.
- **Range outside the union**: Undefined behaviour: the module does not handle it, and a port MUST NOT copy what any one runtime happens to do. Callers MUST validate against `ANALYTICS_RANGES` first.
- **Invalid `nowMs`**: Undefined behaviour: a non-finite clock reading is outside the contract and is not validated. Callers pass `Date.now()` or a fixed test value.
- **Concurrent access**: Not applicable: both functions are synchronous and pure, JavaScript runs them without interleaving, and no state is shared.
- **Error states and offline**: Not applicable: the module does no I/O and has no dependency that can be unavailable. It has no defined error path.

## Configuration

Not applicable beyond the arguments below: the module reads no environment variables, settings or injected dependencies.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `range` | `AnalyticsRange` | none; callers choose (the analytics route defaults to `"7d"`) | Which window `rangeWindow` builds |
| `nowMs` | number (epoch ms) | none | The clock reading the window is anchored to; the caller supplies it |
| `buckets` | readonly string array | none | The axis `alignToBuckets` fills, normally `RangeWindow.buckets` |
| `points` | iterable of `[unknown, number]` | none | Timestamp and value pairs to sum onto the axis |

## Deep Linking

Not applicable: the module has no URLs or routes. The `range` query parameter is read by the dashboard route, which only checks it against `ANALYTICS_RANGES`.

## Localization

Not applicable: the module holds no user-facing strings; the range names are machine identifiers and the buckets are ISO timestamps.

## Accessibility Options

Not applicable: the module is not a visual component, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply to it.

## Feature Flags

Not applicable: the source reads no flags.

## Analytics

Not applicable: the module emits no events. It supplies the axis for analytics dashboards but records nothing itself.

## Privacy

Not applicable: the module handles timestamps and counts only, and stores and transmits nothing.

## Logging

Not applicable: the source makes no log calls.

## Platform Notes

- **SwiftUI**: Port as a Swift `enum AnalyticsRange: String, CaseIterable` with `"24h"`, `"7d"`, `"30d"` raw values, and a pure function `rangeWindow(_:now:)`. Use a `Calendar` fixed to the UTC time zone, or plain `TimeInterval` arithmetic on `timeIntervalSince1970`, so day buckets are UTC rather than local. Format bucket strings with `ISO8601DateFormatter` and `.withFractionalSeconds` to match the `.000Z` spelling. A Swift Charts view takes the aligned arrays directly.
- **Compose**: Use `java.time.Instant` and `ChronoUnit.HOURS` or `DAYS` with `truncatedTo` for the floors, and `Instant.toString` for buckets, but `Instant.toString` drops a zero fraction, so a formatter that always writes `.000Z` is MANDATORY (for example `DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")` in UTC). Port `alignToBuckets` over a `LinkedHashMap` from bucket string to index with a `DoubleArray` result.
- **React/Web**: This is the source platform. `ranges.ts` in `packages/web/packages/status-server/src/telemetry/dashboard/` is pure TypeScript with no dependencies. `ANALYTICS_RANGES` is a `const` tuple, and `types.ts` in the same folder re-exports it. The tests are in `test/telemetry-dashboard-sections.test.ts`.
- **AppKit / UIKit**: The same Foundation-only Swift port serves both. Charts built on Swift Charts or a custom `NSView` or `UIView` read the aligned arrays; keep the axis labels formatting in the view layer, not in this helper.
- **WinUI 3**: Port as a static C# class. Use an `enum AnalyticsRange { H24, D7, D30 }` with a lookup from the wire strings `"24h"`, `"7d"`, `"30d"`, since C# identifiers cannot start with a digit. Compute windows with `DateTimeOffset.FromUnixTimeMilliseconds(nowMs)` and floor with integer arithmetic on `ToUnixTimeMilliseconds()` (not `DateTime.Today`, which is local time). Convert to UTC first (`.UtcDateTime` or `ToUniversalTime()`), then produce bucket strings with `ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'", CultureInfo.InvariantCulture)` to match `toISOString`. For alignment, parse incoming timestamps with `DateTimeOffset.TryParse` using `DateTimeStyles.AssumeUniversal | DateTimeStyles.AdjustToUniversal` and a `Dictionary<string, int>` index. Return `double[]` or `IReadOnlyList<double>`. The chart control (for example a WinUI chart library bound through `ObservableCollection<double>` and `INotifyPropertyChanged`) takes the arrays; no Windows storage or networking APIs are involved.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-server/src/telemetry/dashboard/ranges.ts` | confirmed (1.0.2) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |
| web | `packages/web/packages/status-server/test/telemetry-dashboard-sections.test.ts` | confirmed (1.0.2) |

## Design Decisions

**Decision**: The 24h range has 25 buckets, not 24.
**Rationale**: The window holds 24 full hours plus the current, partial hour. Anchoring the first bucket to the hour boundary 24 hours before the current hour start keeps every bucket on a whole hour, so provider data grouped by hour lines up exactly.
**Approved**: pending

**Decision**: Day ranges are UTC days including today, so the last bucket is a partial day.
**Rationale**: The source comment says "that many UTC days including today". A fixed UTC boundary gives the same buckets for every viewer and matches providers that group by UTC day; a rolling 7 or 30 times 24 hours would not align to those groupings.
**Approved**: pending

**Decision**: Alignment matches bucket starts exactly and drops everything else, instead of rounding timestamps into the containing bucket.
**Rationale**: The source comment says "Anything off the axis is dropped". The providers are queried with the same grouping as the buckets, so exact matching is enough, and it keeps stray out-of-window points from inflating the edge buckets.
**Approved**: pending

**Decision**: Quiet buckets hold zero instead of being absent.
**Rationale**: The module's header comment states it: "a quiet hour reads as a zero rather than a gap", so that PostHog's and Vercel's series can share one chart.
**Approved**: pending

**Decision**: Timestamps are normalised through `new Date(ms).toISOString()` before lookup, and both a string and a number are accepted.
**Rationale**: Providers spell the same instant differently (`...00Z` against `...00.000Z`). The test "zero-fills, tolerates either timestamp spelling, and sums repeats" pins this.
**Approved**: pending

**Decision**: The module does not validate its range argument or the clock reading.
**Rationale**: The function is typed to `AnalyticsRange`, and validation of outside input happens at the edge, in the dashboard route and the report parameter parser, both of which check against `ANALYTICS_RANGES`.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | internationalization |

Separation of concerns passes: the file holds the axis arithmetic and alignment and nothing else, with provider queries, shaping and routing in sibling modules. Unit-test coverage passes: `telemetry-dashboard-sections.test.ts` covers every vector, including the exact `until` and `since` values, a `nowMs` exactly on a boundary, numeric timestamps, an empty bucket list and time-zone independence. No user-facing strings exist and the module formats no locale-dependent text; timestamps are UTC ISO strings.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (telemetry-dashboard-sections.test.ts, 15 of 15 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Kept route and parser behavior out of the module, marked undefined inputs as outside the contract, added RFC 2119 keywords, fixed the 24h bucket description, made vectors 008, 013 and 015 concrete, tightened the Compose and WinUI 3 notes, added related specs and emptied references. |
