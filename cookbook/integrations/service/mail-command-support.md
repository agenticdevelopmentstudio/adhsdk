---
id: 3d12c073-edc3-44fb-a988-5edec20575e0
title: "MailCommandSupport"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-13
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Shared helpers for the mail CLI and MCP tools: sorted pretty JSON output and strict since/until bounds that become UTC strings the store can compare."
platforms:
  - swift
  - macos
tags:
  - mail
  - json
  - date-parsing
  - cli
  - mcp
depends-on:
  - 888b7ba2-61f6-4251-88df-3586c5c86b1f
related:
  - be4db0fe-628d-41f8-9fdf-25a6d46844cf
  - cbee8b02-9456-4d9b-942a-51f8a9c074fc
  - aed9acc9-6340-487b-acfb-b7b13f14e59a
references: []
approved-by: ""
approved-date: ""
---

# MailCommandSupport

## Overview

`MailCommandSupport.swift` holds two caseless, internal enums used by both front ends of the mail integration: the `--json` flag of the command-line tool ([adhsdk.ingredient.integrations.cli.mail-command-line](cookbook:be4db0fe-628d-41f8-9fdf-25a6d46844cf)) and the MCP tools ([adhsdk.ingredient.integrations.mcp.mail-tool-source](cookbook:cbee8b02-9456-4d9b-942a-51f8a9c074fc)). Putting them in one place means the two front ends print the same JSON and read dates by the same rules.

- `MailJSON` turns any `Encodable` value into the JSON text both front ends print.
- `MailDateBound` reads a `since` or `until` value and returns a UTC timestamp string, or nil when the text is not a date or timestamp.

They sit beside the mail integration service ([adhsdk.ingredient.integrations.service.mail-integration-service](cookbook:aed9acc9-6340-487b-acfb-b7b13f14e59a)). The source file is `packages/apple/AgenticDeveloperHubSDK/Integrations/Service/MailCommandSupport.swift`. It uses `Foundation` only: `JSONEncoder` with `.prettyPrinted` and `.sortedKeys`, `Calendar(identifier: .gregorian)` pinned to UTC, and `ISO8601DateFormatter` with two option sets. No test sits beside it.

Neither type holds state, touches a file, uses the network, or logs.

## Behavioral Requirements

### MailJSON

- **json-encode-signature**: `MailJSON.encode(_:)` MUST accept any `Encodable` value and return its JSON as a `String`.
- **json-pretty-printed**: The output MUST be pretty-printed (multi-line, indented).
- **json-sorted-keys**: Object keys MUST be written in sorted order, so the same value always prints the same text.
- **json-output-contract**: Ports MUST produce valid JSON, pretty-printed, with sorted keys and deterministic text. They need not match Swift byte for byte: Apple's Foundation writes `/` as `\/`, and a port MAY write `/` unescaped. Both front ends on a platform MUST call the same shared encode function.
- **json-source-of-truth**: `MailJSON.encode` MUST be the one encoder for the JSON that the MCP tools and the `--json` flag both print. How each front end calls it is specified in its own recipe (see Callers below).
- **json-encoder-errors**: `encode` MUST throw whatever error the encoder throws for a value it cannot encode; the error is not wrapped or caught. (The source also has a guard that throws `EncodingError.invalidValue` if the bytes are not UTF-8; it is unreachable and is described in Design Decisions, not required of ports.)
- **json-default-strategies**: `encode` MUST NOT set a date, data, key or non-conforming-float strategy. Values passed to `encode` MUST NOT contain `Date` or `Data` fields: timestamps arrive as strings, because Swift's default would write a `Date` as a number of seconds from 2001-01-01 (a `Date` at the Unix epoch encodes as -978307200) and no other platform has a matching default.
- **json-no-shared-state**: `encode` MUST NOT depend on state kept between calls, so the same value always gives the same text.

### MailDateBound

- **bound-signature**: `MailDateBound.normalize(_:edge:)` MUST take the raw text and an `Edge` (`start` or `end`) and return `String?`: a UTC timestamp, or nil for rejected input.
- **bound-date-start**: Text shaped `YYYY-MM-DD` that names a real date MUST return the text followed by `T00:00:00.000Z` when `edge` is `start`.
- **bound-date-end**: Text shaped `YYYY-MM-DD` that names a real date MUST return the text followed by `T23:59:59.999Z` when `edge` is `end`.
- **bound-date-shape**: A value counts as `YYYY-MM-DD` only when it splits on `-` into exactly three parts of 4, 2 and 2 characters, and every character is `-` or an ASCII digit.
- **bound-date-reality**: A value of that shape that does not name a real Gregorian date, in UTC, MUST return nil. The check builds the date and compares the year, month and day it reads back; a date the calendar rolls forward is rejected.
- **bound-date-no-fallthrough**: A value of `YYYY-MM-DD` shape that is not a real date MUST return nil and MUST NOT be tried as a timestamp.
- **bound-timestamp-utc**: Text that is not date-shaped but is a full ISO-8601 internet date-time (with a zone designator) MUST return that instant converted to UTC and written by `IntegrationClock.string(from:)` (see [adhsdk.ingredient.integrations.model.integration-records](cookbook:888b7ba2-61f6-4251-88df-3586c5c86b1f)), which gives the form `yyyy-MM-dd'T'HH:mm:ss.SSS'Z'`.
- **bound-timestamp-fractions**: A timestamp MUST be accepted both with fractional seconds and without them; the fractional form is tried first.
- **bound-timestamp-form**: The accepted timestamp text MUST match `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|z|[+-]\d{2}(:?\d{2})?)$`: an uppercase `T`, seconds, and a zone designator that is `Z`, `z` or a signed offset with or without a colon. Text without a zone designator, with a lowercase `t`, or with a space instead of `T` MUST return nil.
- **bound-fraction-truncate**: Fractional seconds beyond the millisecond MUST be truncated, not rounded, so `10:30:00.9996Z` gives `10:30:00.999Z`.
- **bound-timestamp-edge-ignored**: For a timestamp, `edge` MUST have no effect; the result is the given instant, not a start or end of day.
- **bound-reject-other**: Any other text, including the empty string, MUST return nil.
- **bound-lexical-compare**: The UTC string form is required because the store compares UTC strings lexically; callers MUST pass the returned string to the store unchanged.
- **bound-no-throw**: `normalize` MUST NOT throw; rejection is expressed only by nil.

### Callers

How a nil bound is reported, which edge each argument uses and how JSON is printed belong to the callers: [adhsdk.ingredient.integrations.cli.mail-command-line](cookbook:be4db0fe-628d-41f8-9fdf-25a6d46844cf) and [adhsdk.ingredient.integrations.mcp.mail-tool-source](cookbook:cbee8b02-9456-4d9b-942a-51f8a9c074fc). They are not repeated here.

### Runtime shape

Both enums are pure functions of their inputs. `normalize` builds a Gregorian UTC calendar and ISO-8601 formatters per call and never reads the clock. No ordering or concurrency rule applies: each call builds its own calendar, formatter or encoder.

## Appearance

Not applicable — this is a pair of formatting and parsing helpers with no visual surface, not a visual component.

## States

Not applicable — this is a stateless helper pair, not a visual component; neither enum has a runtime state machine.

## Accessibility

Not applicable — this is a helper pair with no user interface, not a visual component.

## Conformance Test Vectors

No test in the repository references `MailJSON` or `MailDateBound`; every vector below is derived from the source and its doc comments.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mail-command-support-001 | bound-date-start | `normalize("2026-11-13", edge: .start)` | `"2026-11-13T00:00:00.000Z"` |
| mail-command-support-002 | bound-date-end | `normalize("2026-11-13", edge: .end)` | `"2026-11-13T23:59:59.999Z"` |
| mail-command-support-003 | bound-date-reality, bound-date-no-fallthrough | `normalize("2026-02-30", edge: .start)` | nil |
| mail-command-support-004 | bound-date-reality | `normalize("2023-02-29", edge: .end)` (not a leap year) | nil |
| mail-command-support-005 | bound-date-reality | `normalize("2024-02-29", edge: .start)` (leap year) | `"2024-02-29T00:00:00.000Z"` |
| mail-command-support-006 | bound-timestamp-utc, bound-timestamp-edge-ignored | `normalize("2026-11-13T10:30:00+02:00", edge: .end)` | `"2026-11-13T08:30:00.000Z"` |
| mail-command-support-007 | bound-timestamp-fractions | `normalize("2026-11-13T10:30:00.250Z", edge: .start)` | `"2026-11-13T10:30:00.250Z"` |
| mail-command-support-008 | bound-reject-other | `normalize("", edge: .start)` | nil |
| mail-command-support-009 | bound-reject-other, bound-date-shape | `normalize("2026-1-5", edge: .start)` (parts of 4, 1 and 1 characters) | nil |
| mail-command-support-010 | bound-reject-other | `normalize("yesterday", edge: .end)` | nil |
| mail-command-support-011 | bound-date-shape | `normalize("2026-11-1３", edge: .start)` (final digit a full-width digit) | nil |
| mail-command-support-012 | bound-reject-other | `normalize("2026-11-13T10:30:00", edge: .start)` (no zone designator) | nil |
| mail-command-support-013 | json-sorted-keys, json-pretty-printed | `encode` of a dictionary with keys `b` then `a` | multi-line text in which `"a"` appears before `"b"` |
| mail-command-support-014 | json-encoder-errors | `encode` of a value whose `encode(to:)` throws | the same error is thrown |
| mail-command-support-015 | bound-date-shape, bound-reject-other | `normalize(" 2026-11-13", edge: .start)` (leading space) | nil |
| mail-command-support-016 | bound-date-shape, bound-reject-other | `normalize("2026/11/13", edge: .start)` | nil |
| mail-command-support-017 | bound-date-reality | `normalize("2026-00-10", edge: .start)` | nil |
| mail-command-support-018 | bound-timestamp-utc | `normalize("2026-11-13T10:30:00.1234Z", edge: .start)` | `"2026-11-13T10:30:00.123Z"` |
| mail-command-support-019 | bound-fraction-truncate | `normalize("2026-11-13T10:30:00.9996Z", edge: .start)` | `"2026-11-13T10:30:00.999Z"` (truncated, not rounded) |
| mail-command-support-020 | bound-timestamp-form | `normalize("2026-11-13t10:30:00Z", edge: .start)` (lowercase `t`) | nil |
| mail-command-support-021 | bound-timestamp-form | `normalize("2026-11-13T10:30:00z", edge: .start)` (lowercase `z`) | `"2026-11-13T10:30:00.000Z"` |
| mail-command-support-022 | bound-timestamp-form, bound-timestamp-utc | `normalize("2026-11-13T10:30:00+0200", edge: .start)` (offset without a colon) | `"2026-11-13T08:30:00.000Z"` |
| mail-command-support-023 | bound-date-reality | `normalize("0000-01-01", edge: .start)` | nil |
| mail-command-support-024 | json-default-strategies | `encode` of a struct holding a `Date` at the Unix epoch (a value callers must not pass) | the field is written as the number `-978307200`, which is why callers must not pass a `Date` |
| mail-command-support-025 | json-output-contract | `encode` of the string `"a/b"` | valid JSON that decodes back to `a/b`; the text is `"a\/b"` on Apple Foundation and a port MAY write `"a/b"` |
## Edge Cases

- **Empty text**: `normalize("")` MUST return nil. It is not date-shaped and is not a timestamp.
- **Surrounding whitespace**: `normalize(" 2026-11-13")` MUST return nil. The source does not trim, so a leading or trailing space breaks both the date shape and the timestamp parse.
- **Wrong separators or lengths**: `2026/11/13`, `26-11-13` and `2026-1-5` MUST return nil.
- **Non-ASCII digits**: Digits from other scripts MUST NOT count; only `-` and ASCII digits pass the shape test.
- **Year range**: The source sets no year range of its own; a four-digit year is accepted when the Gregorian calendar can build the date and read the same year, month and day back. Years such as `0001` and `2026` satisfy that; `0000` returns nil, because the year read back from the calendar is not 0 (vector 023).
- **Impossible dates**: A month of `00` or `13`, a day of `00` or `32`, and 29 February in a non-leap year MUST return nil.
- **Date-only start and end**: The same date returns different strings for `start` and `end`, so `since=until=D` covers the whole UTC day.
- **Timestamp without a zone designator**: Rejected. Both ISO-8601 option sets used require an internet date-time, which carries a zone (see #requirements/bound-timestamp-form).
- **Local time**: Date-only values are read as UTC days regardless of the machine's zone; a timestamp's offset is honored and converted.
- **Precision loss**: A timestamp with more precision than milliseconds is rewritten by `IntegrationClock.string(from:)` in millisecond form, truncating the extra digits (vectors 018 and 019).
- **Unencodable value**: `MailJSON.encode` MUST propagate the encoder's error; the front ends decide how to show it. The source also guards against bytes that are not UTF-8 by throwing `EncodingError.invalidValue` (`not UTF-8`); the standard encoder never produces such bytes, so the branch is unreachable and no port needs it.
- **Escaped slashes**: Because the encoder is left on its defaults, a `/` in a string is written as `\/` on Apple's Foundation. This is not part of the output contract (see #requirements/json-output-contract); ports need only valid, sorted, deterministic output.
- **Dates inside encoded values**: Callers must not pass `Date` or `Data` fields (see #requirements/json-default-strategies); the records the front ends print carry timestamps as strings already.
- **Concurrent calls**: Not applicable to shared state; every call makes its own encoder, calendar and formatters, so calls cannot interfere.
- **Offline, cancellation, timeouts**: Not applicable; both enums are synchronous and touch no network, file or process.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `value` (encode) | `Encodable` | none, required | The value to print. |
| `text` (normalize) | `String` | none, required | The raw `since` or `until` value. |
| `edge` (normalize) | `MailDateBound.Edge` | none, required | `start` or `end`; used only for date-only text. |

There are no environment variables, settings keys or injected dependencies. The one fixed dependency is `IntegrationClock.string(from:)`, which writes the UTC timestamp for a parsed instant; it lives in `Mail/Model/IntegrationRecords.swift` ([adhsdk.ingredient.integrations.model.integration-records](cookbook:888b7ba2-61f6-4251-88df-3586c5c86b1f)).

## Deep Linking

Not applicable: the file exposes no URL or navigation entry point; it only encodes JSON and parses date text.

## Localization

Not applicable: the file holds no user-facing string. The only text it creates is `not UTF-8`, a debug description on an unreachable error. The rejection message `<key> must be YYYY-MM-DD or an ISO-8601 timestamp` is written by `MailToolSource`, not here.

## Accessibility Options

Not applicable: the file has no visual output, motion or colour, so no display option applies.

## Feature Flags

Not applicable: the source reads no flag or setting; behavior varies only by the arguments.

## Analytics

Not applicable: the source emits no events.

## Privacy

- **Data collected**: None by this file. `MailJSON.encode` prints whatever it is given, which for mail results includes addresses, subjects and bodies.
- **Storage**: None.
- **Transmission**: None; the text is returned to the caller, which prints it to a terminal or returns it as an MCP tool result.
- **Retention**: None.

## Logging

Not applicable: the source makes no log call.

## Platform Notes

- **SwiftUI**: The Swift source is the reference, so there is nothing to translate. Both enums are internal to the SDK module, so a SwiftUI host reaches them only through [adhsdk.ingredient.integrations.cli.mail-command-line](cookbook:be4db0fe-628d-41f8-9fdf-25a6d46844cf) and [adhsdk.ingredient.integrations.mcp.mail-tool-source](cookbook:cbee8b02-9456-4d9b-942a-51f8a9c074fc); it never calls them directly.
- **Compose**: Kotlin has no pretty printer with sorted keys by default; use `kotlinx.serialization` `Json { prettyPrint = true }` and sort map keys before encoding (or encode to a `JsonObject` built with a `TreeMap`). For dates, apply the #requirements/bound-date-shape check (exactly 4-2-2 characters, ASCII digits and `-`) first, because `LocalDate.parse` also accepts signed and longer years; then use `java.time.LocalDate.parse` in strict mode, then `atStartOfDay(ZoneOffset.UTC)` or `atTime(LocalTime.of(23, 59, 59, 999_000_000))`, and `OffsetDateTime.parse(...).withOffsetSameInstant(ZoneOffset.UTC)` formatted with a fixed pattern for the timestamp form. `LocalDate.parse` rejects 30 February without a manual round-trip check.
- **React/Web**: Use `JSON.stringify(value, sortedReplacer, 2)` with a replacer that rebuilds objects with sorted keys (`JSON.stringify` does not escape `/`, which #requirements/json-output-contract allows). For dates, match `^\d{4}-\d{2}-\d{2}$` with ASCII digit classes, build `new Date(Date.UTC(y, m - 1, d))` and compare the year, month and day it reports; for a timestamp, do not rely on `Date` parsing, which is lenient: first require the text to match the regex in #requirements/bound-timestamp-form, then truncate any fraction beyond three digits (#requirements/bound-fraction-truncate) before calling `new Date(text)` and `toISOString()`, which gives the milliseconds-and-Z form.
- **AppKit / UIKit**: The same Swift source serves AppKit; it uses only `Foundation` and has no AppKit or UIKit dependency. Output goes to a terminal for the CLI and to an MCP tool result, never to a view.
- **WinUI 3**: Write a static class `MailJson` and a static class `MailDateBound` in C#. For JSON, use `System.Text.Json.JsonSerializer.Serialize` with `JsonSerializerOptions { WriteIndented = true }`; `System.Text.Json` does not sort object keys, so serialize through a `JsonNode` tree and re-add properties in ordinal order, or sort dictionaries first, and leave `/` escaping to the serializer, since #requirements/json-output-contract does not require the `\/` form. For bounds, use `DateOnly.TryParseExact(text, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var date)` after the same shape check (it also rejects 30 February), then `date.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc)` or `new TimeOnly(23, 59, 59, 999)`; for a timestamp use `DateTimeOffset.TryParseExact` with explicit ISO-8601 formats (`yyyy-MM-dd'T'HH:mm:ssK` and `yyyy-MM-dd'T'HH:mm:ss.FFFFFFFK`, each requiring a zone designator, and after the regex in #requirements/bound-timestamp-form has passed) and `CultureInfo.InvariantCulture`, because `TryParse` accepts many non-ISO forms the Swift version rejects; then `ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'", CultureInfo.InvariantCulture)`. Port the `MailJSON` UTF-8 guard and the per-call encoder only if the platform needs them; neither is behavior. Return `string?` and keep rejection as null rather than an exception. These are pure static helpers, so no `ObservableCollection` or `INotifyPropertyChanged` is involved.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Integrations/Service/MailCommandSupport.swift` | confirmed (1.0.1) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Output is pretty-printed with sorted keys.
**Rationale**: The same value always prints the same text, so output can be diffed and compared between the CLI and the MCP tools.
**Approved**: pending

**Decision**: `MailJSON` leaves every `JSONEncoder` strategy at its default.
**Rationale**: The records the front ends print already carry timestamps as strings and keys in the shape the records name, so no conversion is needed, and callers must not pass `Date` or `Data` fields. A port that adds a strategy would change the shape both front ends share.
**Approved**: pending

**Decision**: Date-only bounds become the first or last millisecond of a UTC day, and timestamps are rewritten to the same millisecond UTC form.
**Rationale**: The store compares UTC strings lexically, so every bound must be in one fixed-width form.
**Approved**: pending

**Decision**: A date-shaped value that is not a real date is rejected and never retried as a timestamp.
**Rationale**: `isRealDate` returns a three-way answer (not date-shaped, real, not real) so that `2026-02-30` fails instead of falling through. The check compares the components read back from the calendar because the Gregorian calendar rolls an impossible date forward instead of failing.
**Approved**: pending

**Decision**: A rejected bound is nil, not a thrown error, and the two front ends report it differently.
**Rationale**: The MCP tools can name the argument and the accepted forms in an `ArgumentError`; the command-line parser only returns no result, so the offending value is not named. This is a difference between callers, not between the helpers.
**Approved**: pending

**Decision**: `MailJSON.encode` builds a fresh `JSONEncoder` per call and keeps a `not UTF-8` guard.
**Rationale**: A fresh encoder shares no state between calls. The guard turns a failed `String(bytes:encoding:)` into `EncodingError.invalidValue`; it is unreachable with the standard encoder, so ports are not required to reproduce either.
**Approved**: pending

**Decision**: The `\/` slash escaping is a Foundation detail, not part of the contract.
**Rationale**: Consumers parse the JSON, so only valid, sorted, deterministic output matters; this keeps ports free to use their platform's serializer.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | security |

The two enums each do one job, encoding and date-bound parsing, and leave argument handling and printing to `MailToolSource` and `MailCommandLine`, so separation of concerns passes. A search of the repository found no test that references `MailJSON` or `MailDateBound`, so unit-test coverage fails. Failures are explicit: the encoder's errors propagate and a rejected bound is nil, which both callers turn into a message or a failed parse, so explicit error handling passes. Bounds are checked by shape, by calendar reality and by a strict ISO-8601 parse before they reach the store, which is what the input-sanitization check asks of date input.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Moved the caller rules out to the callers' recipes, pinned JSON date handling, truncation, timestamp regex and year 0000 from the source, added nine vectors, and replaced prose link labels and bare fragment names. |
