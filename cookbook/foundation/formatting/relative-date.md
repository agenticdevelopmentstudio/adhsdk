---
id: 873f79b1-444d-4c2c-8a5f-4fc01cd9022e
title: "Relative Date"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A date relative to now (`3h ago`) while recent and an absolute day (`Nov 1, 2026`) past a cutoff, with style, locale and clock injected."
platforms:
  - swift
  - macos
tags:
  - foundation
  - formatting
  - time
  - date
depends-on: []
related:
  - e3a194dc-3acc-4206-ae6e-105a15fb9f55
references:
  - packages/apple/AgenticDeveloperHubSDK/Core/Formatting/RelativeDateFormatting.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKCoreTests/Formatting/RelativeDateFormattingTests.swift (adhsdk)
approved-by: ""
approved-date: ""
---

# Relative Date

## Overview

One shared formatter for a date shown relative to now: `3h ago` or `3 hours ago` while the date is recent, and an absolute day such as `Nov 1, 2026` once it is more than a week old. A commit history, a notes list and an account's last sync all call it, so every relative date in the toolkit reads the same way and none of them builds its own formatter. It is pure Foundation, and the clock, the units style, the locale and the cutoff are all parameters, so a test fixes every one of them.

## Behavioral Requirements

- **relative-when-recent**: A date no more than the cutoff before now MUST render as the platform's localized relative phrase for the interval from now to the date (`3 hours ago`).
- **absolute-when-old**: A date more than the cutoff before now MUST render as an absolute day with the year, the abbreviated month and the day, in the given locale (`Nov 1, 2026`), with no time of day.
- **cutoff-boundary**: A date exactly the cutoff before now MUST still render relatively; only a strictly larger interval switches to the absolute form.
- **default-cutoff**: The cutoff MUST default to seven days (604,800 seconds).
- **no-cutoff**: A caller MUST be able to pass no cutoff, in which case every date renders relatively, however old.
- **future-is-relative**: A date after now MUST render relatively (`in 3 hours`), never in the absolute form.
- **units-style**: The units style MUST be a parameter, defaulting to abbreviated (`3h ago` in `en_US`); full gives `3 hours ago`.
- **locale-and-clock-injected**: The locale and the reference date MUST be parameters, defaulting to the current locale and the current time.

## Appearance

Not applicable: The formatter is not a visual component; the view that shows its string owns the appearance.

## States

Not applicable: The formatter is stateless.

## Accessibility

Not applicable: The formatter presents no UI; its strings are plain localized text that a label reads as it is.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| relative-date-001 | relative-when-recent, units-style | now − 3 hours, `en_US`, full | `3 hours ago` (test: recentIsRelative). |
| relative-date-002 | units-style | now − 3 hours, `en_US`, default style | `3h ago` (test: defaultStyleIsAbbreviated). |
| relative-date-003 | absolute-when-old, default-cutoff | 2026-11-01 against now 2026-11-13, `en_US` | `Nov 1, 2026` (test: olderThanAWeekIsAbsolute). |
| relative-date-004 | cutoff-boundary | now − exactly 7 days, `en_US`, full | `1 week ago`; one second earlier, `Nov 6, 2026` (test: exactlyTheCutoffIsRelative). |
| relative-date-005 | no-cutoff | now − 400 days, `en_US`, full, no cutoff | `1 year ago` (test: noCutoffIsAlwaysRelative). |
| relative-date-006 | future-is-relative | now + 30 days, `en_US`, full | `in 1 month` (test: futureIsRelative). |

## Edge Cases

- **Null / empty input**: Not applicable: The formatter takes a non-optional date; a caller with no date decides its own text (the Gmail settings pane shows `Never synced`).
- **Boundary values**: An interval of exactly the cutoff is relative; one second more is absolute. A date equal to now renders the platform's relative phrase for a zero interval.
- **Concurrent access**: A stateless function; each call builds its own formatter, so calls from any thread are independent.
- **Error states**: Not applicable: Formatting cannot fail.
- **Offline / disconnected state**: Not applicable: The formatter has no network access.
- **Cancellation**: Not applicable: The formatter has no concern of this kind beyond what Behavioral Requirements state.

## Configuration

None — The formatter reads no environment variable or settings key.

## Deep Linking

Not applicable: The formatter defines no URL scheme, route or navigation destination.

## Localization

The formatter contains no user-facing string literal of its own. Both forms come from the platform's localized formatters in the locale passed in, so the phrase, the month name and the field order follow that locale.

## Accessibility Options

Not applicable: The formatter presents no UI.

## Feature Flags

Not applicable: The formatter contains no feature-flag reference.

## Analytics

Not applicable: The formatter contains no analytics call.

## Privacy

Not applicable: The formatter stores and transmits nothing; it turns a date into text in memory.

## Logging

Not applicable: The formatter calls no logging API.

## Platform Notes

- **SwiftUI**: The source file imports only `Foundation`, so a SwiftUI view or model calls `RelativeDateFormatting.string(for:)` unchanged. The relative form is `RelativeDateTimeFormatter.localizedString(for:relativeTo:)` with the given `unitsStyle` and `locale`; the absolute form is `Date.FormatStyle.dateTime.year().month(.abbreviated).day()` with the same locale.
- **Compose**: `DateUtils.getRelativeTimeSpanString(time, now, minResolution, FORMAT_ABBREV_RELATIVE)` gives the relative form; `DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM)` gives the absolute form; compare the interval against the cutoff first.
- **React/Web**: `Intl.RelativeTimeFormat` (with `style: 'short'` or `'long'`) for the relative form, choosing the largest whole unit yourself, and `Intl.DateTimeFormat(locale, { year: 'numeric', month: 'short', day: 'numeric' })` for the absolute form.
- **AppKit / UIKit**: Identical to the SwiftUI note. Call sites in the toolkit: the notes list's cell (`NoteListCellView`) shows a note's modified date with the abbreviated style and no cutoff, and the Gmail settings model's `lastSyncedText` uses the full style and no cutoff, both keeping the output they had before this formatter existed.
- **WinUI 3**: No built-in relative formatter; pick the largest whole unit from the `TimeSpan` and format it through localized resources, and use `DateTimeFormatter("shortdate")` or `ToString("MMM d, yyyy", culture)` for the absolute form.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Formatting/RelativeDateFormatting.swift` | confirmed (1.0.0) |

## Design Decisions

**Decision**: The cutoff is a parameter that can be turned off, not a fixed rule.
**Rationale**: The two call sites this formatter replaced never switched to an absolute date, and moving them onto it must not change what they show; a history list wants the absolute day for old commits.
**Approved**: pending

**Decision**: Each call builds its own `RelativeDateTimeFormatter` rather than sharing a cached one.
**Rationale**: The style and locale vary per call, and a shared formatter would need locking to be safe from more than one thread; building one is cheap next to drawing the row that shows it.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`separation-of-concerns` passes because the type only turns a date into text; what to show when there is no date, and any prefix such as `Last synced`, belong to the caller. `unit-test-coverage` passes because `AgenticDeveloperHubSDKCoreTests/Formatting/RelativeDateFormattingTests.swift` asserts the exact string for every vector above.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation |
