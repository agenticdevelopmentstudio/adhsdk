---
id: 1a8e345f-c602-4ccb-8880-432b1deac6ac
title: "Route Request"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A transport-free request value for shared routes, with query accessors, SQL-safe limit and offset bounds, and ISO-8601 timestamp validation that rejects or normalizes."
platforms:
  - swift
  - macos
tags:
  - foundation
  - routing
  - http
  - query-parameters
depends-on:
  - 29a3044c-f785-4fa3-a1b9-746d069ae198
  - 59f7893e-58fe-4f11-abd9-f80c1e05c002
related: []
references: []
approved-by: ""
approved-date: ""
---

# Route Request

## Overview

A request as shared routes see it: no transport and no framework. A daemon's HTTP layer converts its own request type into `RouteRequest`, so a route written once against it can be mounted by any daemon. It is a `Sendable`, `Equatable` struct holding `method`, `path`, `queryValues` (every value of every query key, in wire order), `headers` and `body`. Beyond the plain fields it offers path splitting, query accessors, two paging bounds that are safe to hand to SQL (`boundedLimit(default:max:)`, `boundedOffset()`), and ISO-8601 timestamp validation that either returns a canonical string or a typed `InvalidTimestamp` failure. Validation is delegated to `TimestampParsing.parseISO8601` (see the Timestamp Parsing recipe ([adhsdk.ingredient.foundation.time.timestamp-parsing](cookbook:29a3044c-f785-4fa3-a1b9-746d069ae198))) and the whole-second form comes from `UTCTimestamp` (see the UTC Timestamp recipe ([adhsdk.ingredient.foundation.time.utc-timestamp](cookbook:59f7893e-58fe-4f11-abd9-f80c1e05c002))).

## Behavioral Requirements

### Shape

- **fields**: A `RouteRequest` MUST carry `method`, `path`, `queryValues` (`[String: [String]]`), `headers` (`[String: String]`) and `body` (`Data`) exactly as given to `init`.
- **init-defaults**: `init` MUST default `queryValues` to an empty dictionary, `headers` to an empty dictionary and `body` to empty `Data`.
- **value-semantics**: A `RouteRequest` MUST be `Sendable` and `Equatable`; two requests are equal when every field is equal.
- **path-components**: `pathComponents` MUST split `path` on `/` and drop empty segments, so `//sessions//abc/` yields `["sessions", "abc"]` and `/` yields an empty list.

### Query accessors

- **query-last-value**: `query(key)` MUST return the last value of `key`, or `nil` when the key is absent.
- **query-all-wire-order**: `queryAll(key)` MUST return every value of `key` in wire order, or an empty list when the key is absent.
- **query-int-default**: `queryInt(key, default:)` MUST return the last value of `key` parsed as an `Int`, and MUST return the default (0 when none is given) when the key is absent or its value is not an integer. An integer is an optional single leading `+` or `-` followed by one or more ASCII decimal digits, with no whitespace, no other character and a value that fits the platform's signed 64-bit `Int`, which is the grammar of Swift's `Int(String)`; a value outside it (`" 5"`, `"5 "`, `"1e3"`, `""`, an overflowing digit string) takes the default.

### Paging bounds

- **limit-default**: `boundedLimit(default:max:)` MUST return the default when `limit` is absent or unparseable, and MUST bound that default to `1...max` as well, so a default above `max` returns `max`.
- **limit-in-range**: `boundedLimit(default:max:)` MUST return the requested `limit` when it is within `1...max`.
- **limit-capped**: `boundedLimit(default:max:)` MUST return `max` when `limit` exceeds it.
- **limit-floored-at-one**: `boundedLimit(default:max:)` MUST return 1 when `limit` is zero or negative, and MUST NOT pass a negative value through, because SQLite reads a negative `LIMIT` as no limit.
- **limit-clamp-is-silent**: A `limit` outside `1...max` MUST be clamped silently and MUST NOT produce an error; the source records this as deliberate for read-only paging parameters on a localhost API.
- **ceiling-below-one**: NEEDS REVIEW: Not implemented in source. Behavior undefined. The doc comment promises a result always within `1...max`, but a `max` below 1 returns `max` itself (the computation is the minimum of the floored value and the ceiling), so the promise fails and nothing rejects or documents a ceiling below 1. Evidence that would settle it: a statement of whether callers may pass such a ceiling, or a precondition on the parameter.
- **offset-default**: `boundedOffset()` MUST return 0 when `offset` is absent or unparseable.
- **offset-in-range**: `boundedOffset()` MUST return the requested `offset` when it is zero or greater.
- **offset-floored-at-zero**: `boundedOffset()` MUST return 0 when `offset` is negative.

### Timestamps

- **timestamp-absent-is-unbounded**: `validatedTimestamp(name)` MUST return `.success(nil)` when the parameter is absent or its last value is empty; an unbounded window is the documented default, not a bad request.
- **timestamp-validated**: `validatedTimestamp(name)` MUST return `.failure(InvalidTimestamp)` when the last value is non-empty and is not an ISO-8601 instant accepted by `TimestampParsing.parseISO8601`, and MUST NOT clamp, guess or fall back to a default.
- **timestamp-normalized**: A valid value MUST be re-emitted in canonical form: an internet date-time in UTC with fractional seconds (`2026-01-31T00:00:00Z` becomes `2026-01-31T00:00:00.000Z`), so string comparison agrees with the instant it names.
- **timestamp-rebased-to-utc**: A valid value with a zone offset MUST be rebased to UTC (`2026-01-31T02:00:00+02:00` becomes `2026-01-31T00:00:00.000Z`).
- **timestamp-fraction-preserved**: A valid value with fractional seconds MUST keep them (`2026-01-31T00:00:00.500Z` is unchanged).
- **normalized-timestamp-static**: `RouteRequest.normalizedTimestamp(raw, name:)` MUST apply the same parse-and-canonicalize step to a given string, and MUST return `.failure` for a string `TimestampParsing.parseISO8601` rejects.
- **failure-message-format**: A rejection MUST carry exactly the message ``"`{name}` must be an ISO8601 timestamp (e.g. 2026-01-31T00:00:00Z); got \"{raw}\""``, where `{name}` is the parameter name and `{raw}` is the rejected value, unescaped, so a caller knows which of several bounds was wrong.
- **activity-since-absent-is-empty**: `RouteRequest.activitySince(raw)` MUST return `.success("")` when `raw` is `nil` or empty.
- **activity-since-whole-seconds**: `RouteRequest.activitySince(raw)` MUST return the instant in the whole-second `UTCTimestamp` form with fractions truncated (`2026-10-03T11:00:00.500Z` becomes `2026-10-03T11:00:00Z`), because the fractional form would compare wrongly byte for byte against whole-second columns.
- **activity-since-name**: `RouteRequest.activitySince(raw)` MUST name the parameter `since` in a rejection and MUST take only the text, not a parameter name.
- **same-validator-as-core**: Both timestamp paths MUST accept exactly the strings `TimestampParsing.parseISO8601` accepts, so a CLI that checks a flag and the daemon that reads it never disagree. That validator refuses the SQLite date-time shape (`2026-10-01 00:00:00`), a bare date and a bare year.
- **pure-and-synchronous**: Every accessor and validator MUST depend only on the request and its arguments, MUST NOT perform I/O, and MUST NOT mutate the request.

## Appearance

Not applicable — this is a request data type, not a visual component.

## States

Not applicable — this is an immutable value type, not a visual component; it has no runtime state beyond its fields.

## Accessibility

Not applicable — this is a request data type, not a visual component.

## Conformance Test Vectors

Tests named below are in the `RouteRequest` suite (`RouteRequestTests`).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| route-request-001 | path-components | Path `//sessions//abc/`, then path `/`. | `["sessions", "abc"]`, then `[]` (test: pathComponentsDropEmptySegments). |
| route-request-002 | query-last-value | `queryValues` `["a": ["1","2","3"]]`, then no `a`. | `query("a")` is `"3"`, then `nil` (test: queryReturnsTheLastOfRepeatedValues). |
| route-request-003 | query-all-wire-order | `["a": ["z","b","m"]]`, then no `a`. | `["z","b","m"]`, then `[]` (test: queryAllKeepsWireOrder). |
| route-request-004 | query-int-default | `n=12` with default 5; `n=x` with default 5; no `n` with no default. | 12, 5, 0 (test: queryIntFallsBackToTheDefault). |
| route-request-005 | limit-default | No `limit`, `boundedLimit(default: 50, max: 500)`. | 50 (test: missingLimitUsesTheDefault). |
| route-request-006 | limit-in-range | `limit=120`, default 50, max 500. | 120 (test: limitInRangeIsHonoured). |
| route-request-007 | limit-capped, limit-clamp-is-silent | `limit=99999`, default 50, max 500. | 500 (test: limitAboveTheCeilingIsCappedAtIt). |
| route-request-008 | limit-floored-at-one, limit-clamp-is-silent | `limit=-1`, default 50, max 500. | 1, not unlimited (test: negativeLimitIsRaisedToOneRatherThanMeaningUnlimited). |
| route-request-009 | limit-floored-at-one | `limit=0`, default 50, max 500. | 1 (test: zeroLimitIsRaisedToOne). |
| route-request-010 | limit-default | `limit=all`, default 50, max 500. | 50 (test: unparseableLimitFallsBackToTheDefault). |
| route-request-011 | limit-default | No `limit`, default 20000, max 10000. | 10000 (test: anAbsurdDefaultStillCannotExceedItsOwnCeiling). |
| route-request-012 | offset-default | No `offset`. | 0 (test: missingOffsetIsZero). |
| route-request-013 | offset-in-range | `offset=250`. | 250 (test: offsetInRangeIsHonoured). |
| route-request-014 | offset-floored-at-zero | `offset=-40`. | 0 (test: negativeOffsetIsFlooredAtZero). |
| route-request-015 | timestamp-absent-is-unbounded | No `since`. | `.success(nil)` (test: aMissingTimestampMeansAnUnboundedWindow). |
| route-request-016 | timestamp-absent-is-unbounded | `since=` (empty). | `.success(nil)` (test: anEmptyTimestampMeansAnUnboundedWindow). |
| route-request-017 | timestamp-normalized | `since=2026-01-31T00:00:00Z`. | `.success("2026-01-31T00:00:00.000Z")` (test: aWholeSecondBoundIsNormalisedToFractionalSeconds). |
| route-request-018 | timestamp-fraction-preserved | `since=2026-01-31T00:00:00.500Z`. | `.success("2026-01-31T00:00:00.500Z")` (test: aFractionalBoundSurvivesUnchanged). |
| route-request-019 | timestamp-rebased-to-utc | `since=2026-01-31T02:00:00+02:00`. | `.success("2026-01-31T00:00:00.000Z")` (test: anOffsetBoundIsRebasedOntoUTC). |
| route-request-020 | timestamp-validated, failure-message-format | `since=yesterday`. | `.failure` whose message contains `since` and `yesterday` (test: aWordIsRejectedRatherThanSortingAboveEveryRealTimestamp). |
| route-request-021 | timestamp-validated | `since=2026`. | `.failure` (test: aBareYearIsRejectedRatherThanSilentlyMeaningEverything). |
| route-request-022 | failure-message-format | `until=nope`, `validatedTimestamp("until")`. | `.failure` whose message contains `until` (test: theRejectionNamesTheParameterThatWasWrong). |
| route-request-023 | activity-since-whole-seconds | `activitySince("2026-10-03T11:00:00.500Z")`. | `.success("2026-10-03T11:00:00Z")` (test: activitySinceTruncatesToWholeSeconds). |
| route-request-024 | activity-since-absent-is-empty | `activitySince(nil)` and `activitySince("")`. | `.success("")` for both (test: activitySinceTreatsNilAndEmptyAsNoBound). |
| route-request-025 | activity-since-name | `activitySince("yesterday")` through a function typed `(String?) -> Result`. | `.failure` whose message contains `` `since` `` (test: activitySinceTakesOnlyTheTextAndItsRefusalNamesSince). |
| route-request-026 | same-validator-as-core | Each of `2026-10-01T00:00:00Z`, `2026-10-01T00:00:00.250Z`, `2026-10-01T02:00:00+02:00`, `2026-10-01 00:00:00`, `2026-10-01`, `yesterday`, `2026`, `2026-13-01T00:00:00Z`. | `activitySince` succeeds exactly when `TimestampParsing.parseISO8601` returns a date (test: activitySinceAcceptsExactlyWhatCoreAccepts). |
| route-request-027 | init-defaults | `RouteRequest(method: "GET", path: "/")`. | Empty `queryValues`, empty `headers`, empty `body` (derived from the initializer defaults; no test beside the source). |
| route-request-028 | same-validator-as-core, timestamp-validated | `since=2026-10-01 00:00:00` (the SQLite shape), `validatedTimestamp("since")`. | `.failure` (derived from `TimestampParsing.parseISO8601`, which refuses that shape; no test beside the source). |
| route-request-029 | same-validator-as-core, timestamp-validated | `since=2026-10-01` (a bare date), `validatedTimestamp("since")`. | `.failure` (derived; no test beside the source). |
| route-request-030 | same-validator-as-core, timestamp-validated | `since=2026-13-01T00:00:00Z` (month 13), `validatedTimestamp("since")`. | `.failure` (derived; no test beside the source). |
| route-request-031 | normalized-timestamp-static | `RouteRequest.normalizedTimestamp("2026-01-31T00:00:00Z", name: "until")`, then `normalizedTimestamp("nope", name: "until")`. | `.success("2026-01-31T00:00:00.000Z")`, then `.failure` whose message contains `until` (derived; no test beside the source). |
| route-request-032 | fields | `RouteRequest(method: "POST", path: "/x", queryValues: ["a": ["1"]], headers: ["h": "v"], body: Data([1, 2]))`. | Each of `method`, `path`, `queryValues`, `headers` and `body` reads back exactly as given (derived from the initializer; no test beside the source). |
| route-request-033 | value-semantics | Two requests built from identical arguments, then two that differ only in `body`. | Equal, then not equal (derived from the synthesized `Equatable`; no test beside the source). |
| route-request-034 | pure-and-synchronous | Call `boundedLimit(default: 50, max: 500)` and `validatedTimestamp("since")` twice on one request. | Both calls return equal results and the request still equals its original (derived; no test beside the source). |

## Edge Cases

- **Null / empty input**: A missing or empty timestamp MUST mean no bound (`.success(nil)`, or `""` for `activitySince`). A missing `limit` or `offset` MUST use the default; a missing path is not possible, and `/` yields no components.
- **Boundary values**: `limit` of 0 and -1 MUST become 1; `limit` above the ceiling MUST become the ceiling; `offset` of -40 MUST become 0. An integer string too large for `Int` fails to parse and takes the default (derived from `Int(String)` returning `nil`; no test beside the source).
- **Repeated query values**: When a key repeats, `query`, `queryInt`, `boundedLimit`, `boundedOffset` and `validatedTimestamp` MUST read only the last value, while `queryAll` returns all.
- **Malformed input**: A non-numeric `limit` or `offset` is silently replaced by the default; a non-ISO `since` is a failure, not a default. This asymmetry is deliberate (see Design Decisions).
- **Ceiling below one**: See the open question on `ceiling-below-one`.
- **Missing key versus empty value**: For timestamps both mean unbounded; for integers an empty value is unparseable and takes the default.
- **Concurrent access**: A `RouteRequest` is an immutable `Sendable` value and every method is pure, so handlers running concurrently can share one without ordering rules. The shared ISO formatters live in `TimestampParsing`; each canonicalization here builds its own `ISO8601DateFormatter`.
- **Error states**: Timestamp validators return a typed failure and never throw; the other accessors have no failure path.
- **Offline / disconnected state**: Not applicable: the type performs no network access; it describes a request already received.
- **Cancellation and timeouts**: Not applicable: every call is a synchronous in-memory computation.

## Configuration

None — `RouteRequest` reads no environment variable or settings key. Callers supply the paging default and ceiling per call (`boundedLimit(default:max:)`), and the timestamp parameter name (`validatedTimestamp(_:)`). The `limit`, `offset` and `since` key names are fixed by the accessors that read them (`limit` and `offset` inside the paging bounds). `activitySince` reads no key: it takes the text and uses `since` only as the parameter name in its rejection message.

## Deep Linking

Not applicable: `RouteRequest` defines no URL scheme or navigation destination; it parses the path and query it is handed and does not interpret them as app links.

## Localization

`RouteRequest` has one user-facing string, the timestamp rejection message, which is hardcoded English and is not localized. It is an API error text read by clients, not a UI string.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (inline literal) | `` `{name}` must be an ISO8601 timestamp (e.g. 2026-01-31T00:00:00Z); got "{raw}" `` | Message of `InvalidTimestamp` from `validatedTimestamp`, `normalizedTimestamp` and `activitySince`. |

## Accessibility Options

Not applicable: `RouteRequest` presents no UI and responds to no display option.

## Feature Flags

Not applicable: `RouteRequest` contains no feature-flag reference.

## Analytics

Not applicable: `RouteRequest` contains no analytics call.

## Privacy

- **Data handled**: The method, path, query values, headers and body of a request, as given by the daemon, plus the raw rejected timestamp echoed into the failure message.
- **Storage**: None; it persists nothing.
- **Transmission**: None by itself; the failure message that quotes the raw value is sent by whatever builds the response.
- **Retention**: None beyond the lifetime of the value the caller holds.

## Logging

Not applicable: `RouteRequest` calls no logging API.

## Platform Notes

- **SwiftUI**: The source file `Core/Routing/RouteRequest.swift` imports only `Foundation` and is UI-independent, so a SwiftUI host uses it unchanged. It is a `public struct` that is `Sendable` and `Equatable`. The bounds call `Swift.min` and `Swift.max` explicitly. Timestamp canonicalization uses `ISO8601DateFormatter` with `.withInternetDateTime` and `.withFractionalSeconds`, and `UTCTimestamp.string(from:)` for the whole-second form.
- **Compose**: A Kotlin `data class RouteRequest` with `Map<String, List<String>>` and `ByteArray` (note `ByteArray` compares by reference, so override `equals` or use a list or a wrapper). Use `coerceIn(1, max)` for the limit, `toIntOrNull()` for the integer accessors, and `java.time.Instant.parse` or `OffsetDateTime.parse` plus a `DateTimeFormatter` with millisecond precision for the canonical form; the SQLite shape, a bare date and a bare year must be refused, so check the chosen parser rejects them and add an explicit test where it does not.
- **React/Web**: A readonly interface or class with `Record<string, string[]>` for `queryValues` and `Uint8Array` for the body. Parse with `Number.parseInt` guarded by a digits test (it accepts trailing garbage, unlike Swift `Int`), clamp with `Math.min(Math.max(...))`, and canonicalize with `new Date(raw).toISOString()` after checking the string matches the ISO-8601 shape, because `Date` also accepts non-ISO text such as `Jan 1 2026` in some engines and reads a bare year as valid.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic and only the embedding application differs, never this contract.
- **WinUI 3**: A C# `record RouteRequest` with `IReadOnlyDictionary<string, IReadOnlyList<string>>` for query values and `ReadOnlyMemory<byte>` for the body (records compare collections by reference, so supply a custom `Equals` where value equality matters). In an ASP.NET Core minimal API, map `HttpRequest` to this type once in middleware; `Request.Query` is a `StringValues` multimap that already preserves wire order. Use `int.TryParse(..., NumberStyles.Integer, CultureInfo.InvariantCulture, ...)` and `Math.Clamp`, and `DateTimeOffset.TryParseExact` with the ISO-8601 formats followed by `ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ", CultureInfo.InvariantCulture)` for the canonical form.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Routing/RouteRequest.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: `boundedLimit` clamps in both directions instead of using `min(limit, max)`.
**Rationale**: The source records that `min(limit, max)` is not a clamp: SQLite reads a negative `LIMIT` as no limit, so `?limit=-1` turned a bounded page into the whole table (500 rows against 2,300 measured live), and four handlers had no bound at all.
**Approved**: pending

**Decision**: Out-of-range paging values are clamped silently, while a malformed timestamp is a failure.
**Rationale**: The source says paging parameters are read-only and on a localhost API, so a caller asking for more than the ceiling wants as much as it can get; a malformed timestamp has no safe interpretation, because a lexicographic comparison would return the wrong rows with HTTP 200.
**Approved**: pending

**Decision**: Timestamps are normalized to UTC with fractional seconds before they reach a query.
**Rationale**: The source records that stored timestamps carry fractions and `"…T12:00:00Z" > "…T12:00:00.123Z"` bytewise (`Z` sorts above `.`), so an un-normalized whole-second bound would skip the first sub-second of its own range.
**Approved**: pending

**Decision**: `activitySince` truncates to whole seconds and names the parameter `since` itself.
**Rationale**: The source says the activity table stores whole-second `UTCTimestamp` strings, for which the fractional form would compare wrongly byte for byte, and no caller ever named the parameter (test: activitySinceTakesOnlyTheTextAndItsRefusalNamesSince).
**Approved**: pending

**Decision**: Validation delegates to `TimestampParsing.parseISO8601` rather than a local parser.
**Rationale**: The source calls it Core's shared validator so the CLI that checks a flag and the daemon that reads it accept exactly the same strings (test: activitySinceAcceptsExactlyWhatCoreAccepts).
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

`separation-of-concerns` passes because the type holds a request and bounds its paging and timestamp inputs; routing, SQL and HTTP transport belong to callers. `unit-test-coverage` passes: `RouteRequestTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Routing/RouteRequestTests.swift`) covers all 34 vectors, including the SQLite negative-limit regression and the derived initializer, rejection, static normalizer, equality and purity vectors. `input-sanitization` is partial because paging and timestamp inputs are bounded or rejected, while a ceiling below 1 escapes the bound (the open question on `ceiling-below-one`) and the other accessors return raw strings. `explicit-error-handling` passes because a malformed timestamp is a typed failure with a message naming the parameter. `no-hardcoded-strings` fails because the rejection message is an inline English literal; it is an API error text and the source offers no localization path.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (RouteRequestTests.swift, 34 of 34 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Merged the duplicate limit and timestamp requirements, gave the exact rejection message and the integer grammar, listed Timestamp Parsing and UTC Timestamp in depends-on, added vectors 028 to 034, and corrected the configuration note. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
