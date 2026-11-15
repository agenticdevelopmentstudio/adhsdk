---
id: 0de17653-f56d-418f-b212-33e9017972cd
title: "Short Text"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Cuts a string to limit-3 Characters plus `…` (default 60): one shared budget for one-line messages."
platforms:
  - swift
  - macos
tags:
  - foundation
  - text
  - truncation
  - strings
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Short Text

## Overview

`String.shortened(to:)` is a public extension that returns a string unchanged when it fits a character budget, and otherwise cuts it to its first `limit - 3` characters followed by one ellipsis. The default budget is 60. It is one budget in one place: a width-limited card gives a one-line message about sixty characters before it wraps, and that number had been written out at three separate call sites, so tuning any one of them would have left the others saying something a different width.

## Behavioral Requirements

- **extension-scope**: The component MUST be a public method `shortened(to:)` on `String` that returns a `String`.
- **default-limit**: The `limit` parameter MUST default to 60.
- **fits-unchanged**: When the text's `Character` count is less than or equal to `limit`, the method MUST return the text unchanged.
- **cut-length**: When the text's `Character` count is greater than `limit`, the method MUST return the first `limit - 3` characters followed by the single character `…` (U+2026), so a cut result is `limit - 2` characters long, two under the limit.
- **count-in-characters**: The length and the cut MUST be measured in Swift `Character`s (extended grapheme clusters), not UTF-8 bytes or UTF-16 units, so a cut never splits a character.
- **ellipsis-single**: The ellipsis MUST be the one character `…` and MUST NOT be three full stops.
- **minimum-limit**: When the text is longer than a `limit` under 3, the method has no defined result: the Swift source traps on the negative prefix count, and no caller may rely on any returned value.
- **limit-three**: With a `limit` of exactly 3 and a text longer than 3 characters, the result MUST be the ellipsis alone.
- **pure**: The method MUST have no side effect and MUST NOT mutate the receiver.
- **no-word-boundary**: The cut MUST fall at a character position, not a word boundary, and the method MUST NOT trim trailing whitespace before the ellipsis.
- **dependencies**: The component MUST depend only on Foundation.

## Appearance

Not applicable — this is a string-truncation extension, not a visual component.

## States

Not applicable — this is a pure method on a value type, not a visual component; it holds no state.

## Accessibility

Not applicable — this is a string-truncation extension, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| short-text-001 | fits-unchanged | `"short".shortened(to: 10)` (test: underTheLimitIsUnchanged). | `short`. |
| short-text-002 | fits-unchanged | `"0123456789".shortened(to: 10)` (test: exactlyTheLimitIsUnchanged). | `0123456789`: exactly the limit is not cut. |
| short-text-003 | cut-length, ellipsis-single | `"0123456789ABC".shortened(to: 10)` (test: overTheLimitIsCutEndingInAnEllipsis). | `0123456…`, with a `count` of 8. |
| short-text-004 | default-limit, fits-unchanged | A 60-character string, then `.shortened()` (test: see ShortTextTests). | The same 60 characters. |
| short-text-005 | default-limit, cut-length | A 61-character string of `a`, then `.shortened()` (test: see ShortTextTests). | 57 `a` characters and `…`, 58 characters in all. |
| short-text-006 | limit-three | `"abcd".shortened(to: 3)` (test: see ShortTextTests). | `…`. |
| short-text-007 | fits-unchanged | `"".shortened(to: 0)` and `"ab".shortened(to: 2)` (test: see ShortTextTests). | The empty string and `ab`; no cut, so the minimum-limit precondition is never reached. |
| short-text-008 | count-in-characters | Six repetitions of the family emoji `👨‍👩‍👧` (scalars U+1F468 U+200D U+1F469 U+200D U+1F467, one Character each) with `.shortened(to: 5)` (test: see ShortTextTests). | Two whole family emoji then `…` (`👨‍👩‍👧👨‍👩‍👧…`): no emoji is split. |
| short-text-009 | no-word-boundary | `"hello world and more".shortened(to: 9)` (test: see ShortTextTests). | `hello …`: six characters (`hello ` with its trailing space) then the ellipsis. |

## Edge Cases

- **Null / empty input**: An empty string is returned unchanged for any `limit` of 0 or more (MUST); with a negative `limit` the comparison `count > limit` is true and the cut traps.
- **Boundary values**: A text of exactly `limit` characters is returned whole; one more character is cut (MUST). A `limit` of 3 on a longer text yields only the ellipsis (MUST).
- **Limit below 3**: A `limit` of 0, 1 or 2 with a text longer than the limit makes `prefix(limit - 3)` receive a negative count and trap; the doc comment declares "`limit` must be at least 3" and the method does not check it, so the contract belongs to the caller.
- **Multi-scalar characters**: Combining marks, emoji sequences and CRLF count as one `Character` each and are never split (MUST); the result can therefore have more bytes or UTF-16 units than `limit - 2`.
- **Cut length versus limit**: The result of a cut is `limit - 2` characters, two under the limit, not `limit` (MUST).
- **Concurrent access**: Not applicable: the method is a pure function over an immutable value and shares no state.
- **Error states**: There is no error return; the only failure is the trap for a limit under 3 on a longer text.
- **Offline / disconnected state**: Not applicable: the method performs no I/O.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `limit` | `Int` | 60 | The most characters allowed before the text is cut; must be at least 3 when the text can be longer. |

The method reads no environment variable and no settings key.

## Deep Linking

Not applicable: The component defines no URL scheme, route or navigation destination.

## Localization

Not applicable: The component contains no user-facing string of its own; the `…` it appends is a punctuation character, not translatable copy, and it is not replaced for right-to-left or other scripts.

## Accessibility Options

Not applicable: The component presents no UI.

## Feature Flags

Not applicable: The source contains no feature-flag reference.

## Analytics

Not applicable: The source contains no analytics call.

## Privacy

- **Data handled**: Only the text its caller passes in, which it may discard past the limit.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the returned string; the cut text is not recoverable from it.

## Logging

Not applicable: The source calls no logging API.

## Platform Notes

- **SwiftUI**: The component imports only `Foundation` and has no SwiftUI dependency. A SwiftUI `Text` can truncate by itself with `.lineLimit(1)` and `.truncationMode(.tail)`; this method is for a string that is built or stored before display.
- **Compose**: An extension `fun String.shortened(limit: Int = 60)` that counts grapheme clusters, since `String.length` counts UTF-16 units; use `java.text.BreakIterator.getCharacterInstance()` or `android.icu.text.BreakIterator`. A `Text` with `maxLines = 1` and `overflow = TextOverflow.Ellipsis` covers display-only truncation.
- **React/Web**: An exported function `shortened(text, limit = 60)` using `Intl.Segmenter` with `granularity: "grapheme"` to count and cut, since `String.length` and `slice` work in UTF-16 units and would split an emoji. CSS `text-overflow: ellipsis` covers display-only truncation but cuts by width, not by count.
- **AppKit / UIKit**: Identical to the SwiftUI note for the method; for display only, `NSTextField` and `UILabel` truncate by width through `lineBreakMode = .byTruncatingTail`, which is not the same as this character-count cut.
- **WinUI 3**: A static extension method `Shortened(this string text, int limit = 60)`. `string.Length` counts UTF-16 units, so count and cut by text element with `System.Globalization.StringInfo` (`LengthInTextElements`, `SubstringByTextElements`) to match Swift `Character`s. Throw `ArgumentOutOfRangeException` for a limit under 3 on a longer text if the port wants a defined failure in place of the Swift trap. For display only, `TextBlock.TextTrimming="CharacterEllipsis"` trims by width.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Text/ShortText.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Cut to `limit - 3` characters plus one ellipsis character, so the result is `limit - 2` characters.
**Rationale**: The source takes `prefix(limit - 3)` and appends the single `…`; its doc comment states that a cut result is `limit - 2` characters long, and the test records this ("two under the limit"), so a port must match it.
**Approved**: pending

**Decision**: Measure in `Character`s, not bytes or UTF-16 units.
**Rationale**: A cut must never split an emoji or combining sequence.
**Approved**: pending

**Decision**: One shared helper with a default of 60.
**Rationale**: A width-limited card gives a one-line message about sixty characters before it wraps, and the number had been written at three call sites, so tuning one would have left the others a different width. The number belongs to that card; callers that show a one-line message in such a card should use the default instead of writing 60 again.
**Approved**: pending

**Decision**: The method does not guard a limit under 3.
**Rationale**: The doc comment documents the precondition ("`limit` must be at least 3: a smaller value makes `prefix` trap on a negative count"); the method does not check it, so the contract belongs to the caller. This is recorded as the contract, not a gap: a precondition that fails only for long text can pass every short-string test, so a caller needs to know it.
**Approved**: pending

**Decision**: The cut is not at a word boundary and does not trim trailing whitespace.
**Rationale**: The source takes `prefix(limit - 3)` as is; the output length is therefore predictable for a width budget.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |

separation-of-concerns passes: the extension only shortens a string; where the budget comes from and how the result is shown belong to its callers. unit-test-coverage passes: `AgenticDeveloperHubSDKCoreTests/Text/ShortTextTests.swift` covers all nine vectors, including the default of 60, a limit of 3, an empty string and a multi-scalar character. unicode-support passes: the length and the cut are counted in `Character`s so a grapheme cluster is never split.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (ShortTextTests.swift, 9 of 9 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Shortened the summary, made the card context generic, moved single-budget into a Design Decision, restated minimum-limit as component behavior, removed paths from the SwiftUI note and gave vector 008 its exact scalars. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
