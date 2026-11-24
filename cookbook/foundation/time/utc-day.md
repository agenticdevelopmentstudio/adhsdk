---
id: 533c7d81-1380-4fba-a5d0-54271dd51772
title: "UTC Day"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "UTC-pinned day helpers: the yyyy-MM-dd UTC day containing a date, and the day after a day string, matching day buckets taken from stored UTC timestamps."
platforms:
  - swift
  - macos
tags:
  - foundation
  - time
  - utc
  - day-keys
depends-on: []
related:
  - 59f7893e-58fe-4f11-abd9-f80c1e05c002
references: []
approved-by: ""
approved-date: ""
---

# UTC Day

## Overview

UTC calendar-day helpers for code that stores UTC ISO-8601 timestamps and buckets days by their 10-character prefix (`substr(timestamp, 1, 10)`). Day strings produced in Swift must use the same fixed UTC calendar; otherwise the host's locale or time zone could shift a boundary. The civil-date arithmetic belongs to [adhsdk.ingredient.foundation.time.utc-timestamp](cookbook:59f7893e-58fe-4f11-abd9-f80c1e05c002); this type is its UTC-pinned spelling. It is a caseless `enum` with two static functions, `string(from:)` and `dayAfter(_:)`, and no stored state beyond a private constant UTC time zone.

## Behavioral Requirements

- **day-string-from-date**: `string(from:)` MUST return the `yyyy-MM-dd` calendar day in UTC that contains the given `Date`.
- **utc-pinned**: `string(from:)` MUST NOT depend on the host's locale or time zone; the day is computed with the fixed `UTC` time zone.
- **matches-wire-prefix**: The output of `string(from:)` MUST equal the first 10 characters of the instant's UTC ISO-8601 form.
- **day-after**: `dayAfter(_:)` MUST return the `yyyy-MM-dd` UTC day following a `yyyy-MM-dd` UTC string, carrying across month, year and leap-day boundaries.
- **day-after-parses-midnight**: `dayAfter(_:)` MUST read its input as the UTC midnight that starts that day.
- **day-after-unparseable**: `dayAfter(_:)` MUST return its input unchanged when that instant cannot be parsed.
- **day-after-out-of-range**: `dayAfter(_:)` MUST return its input unchanged when a field is out of range, for example month 13 (`2026-13-01`).
- **no-throw**: Both functions MUST NOT throw; failure is expressed only by `dayAfter(_:)` returning its input.
- **stateless**: Both functions MUST be pure apart from reading their arguments; the type holds no mutable state.

## Appearance

Not applicable — this is a pair of date-string helpers, not a visual component.

## States

Not applicable — this is a stateless helper, not a visual component; it has no runtime state machine.

## Accessibility

Not applicable — this is a pair of date-string helpers, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| utc-day-001 | day-string-from-date, matches-wire-prefix | `string(from:)` of epoch 0 and of epoch 1,700,000,000 (`2023-11-14T22:13:20Z`). | `1970-01-01` and `2023-11-14`, the UTC day and not the local-time day (test: testStringFromEpochIsUTC). |
| utc-day-002 | day-after | `dayAfter("2026-06-19")`. | `2026-06-20` (test: testDayAfterSimple). |
| utc-day-003 | day-after | `dayAfter("2026-01-31")`. | `2026-02-01` (test: testDayAfterMonthBoundary). |
| utc-day-004 | day-after | `dayAfter("2026-12-31")`. | `2027-01-01` (test: testDayAfterYearBoundary). |
| utc-day-005 | day-after | `dayAfter("2024-02-28")`, `dayAfter("2024-02-29")` and `dayAfter("2026-02-28")`. | `2024-02-29`, `2024-03-01` and `2026-03-01` (test: testDayAfterLeapDay). |
| utc-day-006 | day-after-unparseable, no-throw | `dayAfter("not-a-date")`. | `not-a-date`, unchanged (test: testDayAfterReturnsInputOnGarbage). |
| utc-day-007 | utc-pinned | `string(from:)` of epoch 1,700,000,000 with the host time zone set to Pacific/Auckland (UTC+13 in November). | `2023-11-14` regardless of host zone; the source pins the zone (test: testUtcDay007_stringIgnoresHostTimeZone). |
| utc-day-008 | day-after-unparseable | `dayAfter("")` (test: see UTCDayTests). | The empty string, unchanged. |
| utc-day-009 | day-after-out-of-range | `dayAfter("2026-13-01")` (test: see UTCDayTests). | `2026-13-01`, unchanged. |
## Edge Cases

- **Null / empty input**: `dayAfter("")` MUST return the empty string unchanged.
- **Boundary values**: Month ends, year ends and leap days MUST roll over to the next civil day; a non-leap 28 February MUST be followed by 1 March.
- **Out-of-range fields**: `dayAfter("2026-13-01")` MUST return the input unchanged. Other impossible dates (`2026-02-30`) and trailing characters (`2026-06-19x`) are not specified here, because the shared parser's handling of them is not covered by a test.
- **Malformed input**: A string that does not parse as `<day>T00:00:00Z` MUST come back unchanged rather than produce a wrong day; a caller cannot distinguish this from success except by comparing input to output.
- **Concurrent access**: Both functions are stateless and the only stored value is an immutable private `TimeZone`, so concurrent calls need no coordination.
- **Error states**: Nothing throws or logs; the only error signal is the unchanged return of `dayAfter(_:)`.
- **Offline / disconnected state**: Not applicable: the type has no network or file access.
- **Cancellation**: Not applicable: both functions are synchronous and return immediately.

## Configuration

None — the type reads no environment variable or settings key; the UTC zone is a private constant and every other value arrives as a parameter.

## Deep Linking

Not applicable: the type defines no URL scheme, route or navigation destination.

## Localization

Not applicable: the type contains no user-facing string; its output is a locale-independent `yyyy-MM-dd` key.

## Accessibility Options

Not applicable: the type presents no UI.

## Feature Flags

Not applicable: the type contains no feature-flag reference.

## Analytics

Not applicable: the type contains no analytics call.

## Privacy

- **Data handled**: Only the dates and day strings its caller passes in.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value the caller holds.

## Logging

Not applicable: the type calls no logging API.

## Platform Notes

- **SwiftUI**: The source imports only `Foundation`, so a SwiftUI host uses it unchanged from any view model or store. It is a caseless public `enum` over `TimeZone(identifier: "UTC")`: `string(from:)` calls `UTCTimestamp.day(of:in:)`, and `dayAfter(_:)` reads `<day>T00:00:00Z` through `UTCTimestamp.epochSeconds(_:)`, adds 86,400 seconds and formats with `UTCTimestamp.day(epochSeconds:in:)`.
- **Compose**: `java.time.LocalDate.ofInstant(instant, ZoneOffset.UTC).toString()` produces the `yyyy-MM-dd` key and `LocalDate.parse(day).plusDays(1)` the next day; unparseable input throws `DateTimeParseException`, so catch it and return the input to match the source.
- **React/Web**: `date.toISOString().slice(0, 10)` yields the UTC day; for the next day, add 86,400,000 ms to `Date.parse(day + 'T00:00:00Z')` and slice again, returning the input when the parse gives `NaN`.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: `DateTimeOffset.UtcDateTime.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)` writes the day, and `DateTime.TryParseExact(day, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal | DateTimeStyles.AdjustToUniversal, out var d)` followed by `d.AddDays(1).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)` gives the next day; return the input string when `TryParseExact` fails. Use `static` methods on a `static class`, with no `INotifyPropertyChanged` or UI binding needed.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Time/UTCDay.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Day strings are produced with a fixed `UTC` time zone, never the host's current zone.
**Rationale**: Days are bucketed with `substr(timestamp, 1, 10)` on stored UTC ISO-8601 timestamps, so a Swift-side day in the host zone could disagree with the database boundary.
**Approved**: pending

**Decision**: `string(from:)` and `dayAfter(_:)` delegate day formatting and parsing to the shared UTC timestamp ingredient, with the UTC zone.
**Rationale**: One owner of the civil-date arithmetic keeps the output equal to the day prefix of a wire instant.
**Approved**: pending

**Decision**: `dayAfter(_:)` adds a flat 86,400 seconds instead of using a calendar.
**Rationale**: UTC has no daylight-saving shift, so a day is always exactly 86,400 seconds and no calendar object is needed. The result cannot be told apart from calendar arithmetic, so this is a design choice and not a requirement.
**Approved**: pending

**Decision**: `dayAfter(_:)` returns an unparseable input unchanged instead of failing.
**Rationale**: The source's doc comment calls the fallback defensive, since callers only pass strings this type produced; it avoids an optional or a throw on a path that should never fail, at the cost that a bad input is silent to the caller.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`separation-of-concerns` passes because the type only pins the UTC zone and shapes the two daemon-facing calls, leaving all civil-date arithmetic to `UTCTimestamp`. `unit-test-coverage` passes because `AgenticDeveloperHubSDKCoreTests/Time/UTCDayTests.swift` covers all nine vectors, including `utc-pinned` with the host time zone set to Pacific/Auckland, empty input and an out-of-range month.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (UTCDayTests.swift, 9 of 9 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Described the contract without the daemon, restated delegation and midnight parsing as observable behavior, added empty and out-of-range vectors, marked unit-test-coverage partial and completed the WinUI 3 formatting step. |
