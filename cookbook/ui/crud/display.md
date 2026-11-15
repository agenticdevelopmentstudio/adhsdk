---
id: c459ad9a-fa81-45ea-a5f4-50c45d566622
title: "CrudDisplay"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "columnDisplayValue from @adh-sdk/crud: turns the /v1 integer unix-second created/updated row values into ISO date strings for list cells and leaves every other value untouched."
platforms:
  - typescript
  - web
tags:
  - crud
  - display
  - timestamp
  - formatting
depends-on: []
related:
  - ec64b22b-8a25-431d-8866-b7a01acd91fe
references: []
approved-by: ""
approved-date: ""
---

# CrudDisplay

## Overview

`columnDisplayValue(column, value)` in `@adh-sdk/crud` decides how one row value
reads in a list cell. The `/v1` API serves the `created` and `updated` row
timestamps as integer unix seconds, while every other timestamp column stays an
ISO string. This pure function converts only those two columns (when the column
descriptor says `integer` and the value is a number) into an ISO date string via
`unixToIso` from `@adh-sdk/auth/client`, and returns every other value exactly as
it was given.

It is a pure, synchronous function with no side effects. It is the single
conversion point both list surfaces share: `cellText` in `CrudTable` and the
cell rendering in `CrudDataView` each pass the raw row value through it before
their own null, stringify and truncate formatting. This recipe is
non-visual shared logic; see CrudTable ([adhsdk.ingredient.ui.crud.crud-table](cookbook:ec64b22b-8a25-431d-8866-b7a01acd91fe))
for the surface that shows its output.

## Behavioral Requirements

- **convert-unix-timestamp-columns**: When `column.name` is `created` or
  `updated`, `column.type` is `integer`, and `value` is a JavaScript number,
  the function MUST return that value converted to an ISO 8601 date string in
  UTC with millisecond precision (the `unixToIso` result).
- **interpret-value-as-seconds**: The function MUST treat the numeric value as
  unix seconds, so `0` yields `1970-01-01T00:00:00.000Z` and `1700000000`
  yields `2023-11-14T22:13:20.000Z`.
- **match-name-exactly**: The conversion MUST apply only to the exact column
  names `created` and `updated`; the name match is case-sensitive and no other
  column name qualifies.
- **require-integer-column-type**: A column named `created` or `updated` whose
  `type` is anything other than `integer` MUST be returned unconverted.
- **require-numeric-value**: A `created` or `updated` integer column whose value
  is not a JavaScript number (`null`, `undefined`, a string, an object) MUST be
  returned unchanged, so a null timestamp stays null.
- **fall-back-on-non-finite**: When the value is a number that `unixToIso`
  rejects (`NaN`, `Infinity`, `-Infinity`), the function MUST return the original
  value rather than `null`.
- **pass-through-other-columns**: Every value for a column that does not meet
  the conversion conditions MUST be returned as the identical value (same type,
  same reference for objects), including integer columns not named `created`
  or `updated` and string timestamp columns such as `granted_at`.
- **no-input-mutation**: The function MUST NOT mutate `column` or `value`.
- **no-metadata-lookup**: The function MUST decide from the supplied `column`
  descriptor alone and MUST NOT read the row or the table metadata.
- **return-type-unknown**: The function's return type is `unknown`; the caller
  MUST apply its own null, stringify and truncate formatting to the result.
- **shared-by-list-surfaces**: The table cell text helper (`cellText` in
  `CrudTable`) SHOULD obtain its displayed value from this function so that
  every list surface renders the same timestamp text; the data view also routes
  its cells, including the cells of an unsaved draft row (the buffered value, else the
  seeded baseline), through it.
- **throw-on-unrepresentable-date**: A finite number so large that its millisecond
  value falls outside the range of a JavaScript `Date` (more than 8.64e12
  seconds in magnitude) is passed to `unixToIso` unguarded, so the function MUST
  let the resulting `RangeError` propagate to the caller. (This is the source's
  actual behavior, recorded as a requirement of the port; see Edge Cases.)

## Appearance

Not applicable — this is a pure value-formatting function, not a visual component.

## States

Not applicable — this is a stateless function, not a visual component; it holds no
state and every call is independent.

## Accessibility

Not applicable — this is a pure value-formatting function, not a visual component.
It returns a value and renders nothing.

## Conformance Test Vectors

Every vector is asserted by `display.test.ts` (the `columnDisplayValue` suite and the
`display conformance vectors` suite).

| ID | Requirements | Input | Expected |
|---|---|---|---|
| display-001 | convert-unix-timestamp-columns, interpret-value-as-seconds | column `created` / `integer`, value `1700000000` (test: "renders /v1 created/updated unix seconds as an ISO date") | `2023-11-14T22:13:20.000Z` |
| display-002 | convert-unix-timestamp-columns, interpret-value-as-seconds | column `updated` / `integer`, value `0` (same test) | `1970-01-01T00:00:00.000Z` |
| display-003 | pass-through-other-columns | column `count` / `integer`, value `5`; column `granted_at` / `string`, value `2024-01-01T00:00:00Z` (test: "leaves every other column, and a null timestamp, untouched") | `5`; `2024-01-01T00:00:00Z` (both unchanged) |
| display-004 | require-numeric-value | column `updated` / `integer`, value `null` (same test) | `null` |
| display-005 | shared-by-list-surfaces | `cellText({ created: 1700000000 }, created/integer column)` (test: "is what the list cell shows") | `2023-11-14T22:13:20.000Z` |
| display-006 | require-integer-column-type | column `created` / `string`, value `1700000000` | `1700000000` (unchanged number) |
| display-007 | match-name-exactly | column `Created` / `integer`, value `1700000000` | `1700000000` (unchanged) |
| display-008 | require-numeric-value | column `created` / `integer`, value the string `"1700000000"` | the string `"1700000000"` (unchanged) |
| display-009 | fall-back-on-non-finite | column `created` / `integer`, value `NaN` | `NaN` (the original value, not `null`) |
| display-010 | fall-back-on-non-finite | column `updated` / `integer`, value `Infinity` | `Infinity` |
| display-011 | require-numeric-value | column `updated` / `integer`, value `undefined` | `undefined` |
| display-012 | throw-on-unrepresentable-date | column `created` / `integer`, value `1e20` | throws `RangeError` (invalid time value) |
| display-013 | pass-through-other-columns, no-input-mutation | column `meta` / `object`, value an object `o` | the same reference `o`, unmodified |

## Edge Cases

- **Null or undefined value**: a `created` or `updated` integer column with a null
  or undefined value MUST be returned as is, not converted and not replaced by an
  empty string; showing a placeholder is the caller's job (`cellText` renders an
  em dash for it).
- **Zero**: `0` is a valid timestamp and MUST convert to the epoch
  (`1970-01-01T00:00:00.000Z`); it is not treated as missing.
- **Negative seconds**: a negative finite number converts to a date before 1970
  through `unixToIso`; the source adds no lower bound.
- **Fractional seconds**: a non-integer number is converted without rounding, so
  the fraction appears in the millisecond field; the source does not check that an
  `integer` column holds a whole number.
- **Non-finite numbers**: `NaN` and the infinities MUST come back unchanged
  because `unixToIso` returns null for them and the function falls back to the
  original value (the `??` fallback).
- **Out-of-range magnitude**: a finite number beyond the `Date` range makes
  `unixToIso` throw `RangeError`; the function neither catches nor reports it, so
  it reaches the caller (a rendering list surface) as an exception. This is
  surfaced, not swallowed, so it is stated here as a fact.
- **Wrong column type**: a `created` or `updated` column typed `string` or
  `number` MUST pass through, so an ISO-string `created` from a different API is
  not double-converted.
- **Concurrent access**: not applicable — the function is synchronous, holds no
  state and reads only its arguments, and JavaScript runs it single-threaded.
- **Error states and offline state**: not applicable — it performs no I/O, so
  there is no dependency to be unavailable and no network to lose; the only failure
  path is the `RangeError` above.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `column` | `CrudColumn` (`name`, `type`, `required`, `nullable`, `serverManaged`, ...) | required | Descriptor of the column the value belongs to; only `name` and `type` are read |
| `value` | `unknown` | required | The raw row value for that column |
| `UNIX_SECONDS_COLUMNS` | `Set<string>` | `created`, `updated` | Module-private set of column names whose integer values are unix seconds; not caller-configurable |
| `unixToIso` | function from `@adh-sdk/auth/client` | imported | The seconds-to-ISO converter; returns null for a null, undefined or non-finite input, otherwise the UTC ISO string |

## Deep Linking

Not applicable: the function formats a value and has no routes or URLs.

## Localization

Not applicable: the function returns a locale-independent UTC ISO 8601 string and no
user-facing text; it uses no localized date formatting and owns no strings.

## Accessibility Options

Not applicable: the function returns a value and renders nothing, so Reduce Motion,
Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the function reads no flags and behaves identically in every configuration.

## Analytics

Not applicable: the function emits no events.

## Privacy

Not applicable: the function stores, transmits and logs nothing; it returns a
transformation of the one value it is given.

## Logging

Not applicable: the source contains no log calls.

## Platform Notes

- **SwiftUI**: No native implementation exists (this is a web-sourced function). A port is a free function or a `Column` extension taking a column descriptor and an `Any?` value: match `name` and an integer type, then format `Date(timeIntervalSince1970:)` with `ISO8601DateFormatter` using the `.withFractionalSeconds` option to reproduce the `.000Z` millisecond form. Return the original value for any non-number or non-finite input.
- **Compose**: No native implementation exists. A Kotlin port is a top-level function over a column descriptor and `Any?`: for a Long or Double named `created` or `updated`, return `Instant.ofEpochSecond(...)` rendered with `DateTimeFormatter.ISO_INSTANT`; guard `NaN` and infinities explicitly, and note that `Instant` throws `DateTimeException` for out-of-range seconds where the source throws `RangeError`.
- **React/Web**: Source platform. The implementation is `packages/web/packages/crud/src/display.ts`, exported from `@adh-sdk/crud`; it imports `unixToIso` from `@adh-sdk/auth/client` (defined in `packages/web/packages/auth/src/v1.ts`) and the `CrudColumn` type from `packages/web/packages/crud/src/types.ts`. Tests are `packages/web/packages/crud/src/__tests__/display.test.ts` (Vitest). Callers are `cellText` in `CrudTable.tsx` and the cell rendering in `CrudDataView.tsx`.
- **AppKit / UIKit**: No native implementation exists. A port is the same pure function used by whichever table data source builds the cell string (an `NSTableViewDelegate` cell provider or a `UITableViewCell` configuration); use `ISO8601DateFormatter` as for SwiftUI and keep the call out of the view so it stays unit-testable.
- **WinUI 3**: Implement as a static method `ColumnDisplayValue(CrudColumn column, object? value)` returning `object?`. Test the name against `created` and `updated` with `StringComparison.Ordinal` (the source match is case-sensitive), check `column.Type == "integer"`, and handle the number cases (`long`, `int`, `double`). For `double`, reject `double.NaN` and infinities by returning the original value. Convert with `DateTimeOffset.FromUnixTimeSeconds(long)` and format with `ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'", CultureInfo.InvariantCulture)` on the UTC value. `FromUnixTimeSeconds` throws `ArgumentOutOfRangeException` outside year 1 to 9999, which is the analogue of the source's unguarded `RangeError`. Use it in an `IValueConverter` for a `DataTemplate` cell, or compute it in the row view model that backs an `ItemsRepeater` or `ListView` so the XAML binds to plain text.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/crud/src/display.ts` | confirmed (1.0.1) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Only the two columns named `created` and `updated` are converted, and only when the descriptor type is `integer` and the value is a number.
**Rationale**: The `/v1` API serves exactly those two timestamps as integer unix seconds while every other timestamp column stays an ISO string, so a wider rule would risk rewriting ordinary integer columns such as counts. The source comment states this directly.
**Approved**: pending

**Decision**: A value that `unixToIso` cannot convert (non-finite numbers) falls back to the original value instead of null, through `unixToIso(value) ?? value`.
**Rationale**: The cell then shows what the server sent rather than a misleading blank or placeholder that would hide bad data.
**Approved**: pending

**Decision**: The function does no null formatting, stringification or truncation; it returns `unknown`.
**Rationale**: Those belong to each list surface (`cellText` renders an em dash, stringifies and truncates at 80 characters), which keeps this function a single-purpose conversion shared by `CrudTable` and `CrudDataView` (separation of concerns).
**Approved**: pending

**Decision**: Out-of-range finite seconds are not guarded, so the `RangeError` from `Date` propagates.
**Rationale**: The source adds no guard; the throw is visible rather than swallowed, and the `/v1` API serving real timestamps keeps the case unreachable in practice. A port should match this unless the caller decides otherwise.
**Approved**: pending

**Decision**: The output is a UTC ISO string, not a localized date.
**Rationale**: It matches the ISO strings the other timestamp columns already show, so every timestamp in a list reads in one form. Localized display is not part of the source.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | partial | Internationalization |

`separation-of-concerns` passes because the function does one conversion and leaves
null, stringify and truncate formatting to its callers. `unit-test-coverage` passes: `display.test.ts` has one test per conformance
vector (display-001 to display-013), including the non-finite, wrong-type, wrong-name
and `RangeError` cases. `explicit-error-handling` is partial because
the out-of-range case throws without a guard or a documented message, though the
error is not swallowed. `locale-aware-formatting` is partial because the output is
a fixed UTC ISO string, deliberately matching the other timestamp columns, rather
than a locale-formatted date.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Conformance tests added (display.test.ts, 13 of 13 vectors); unit-test-coverage now passed. |
