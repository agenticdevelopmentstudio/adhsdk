---
id: e8286557-84ee-4f45-b78c-f1d184c51a37
title: "Stenographer Wire"
type: ingredient
version: 1.0.3
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The one JSON spelling shared by steno, the daemon and the app: snake_case keys and ISO-8601 dates, built as a fresh encoder and decoder."
platforms:
  - swift
  - macos
  - ios
tags:
  - foundation
  - stenographer
  - wire
  - json
depends-on: []
related:
  - 9c7c78d3-23ca-4ca6-a519-9968b440b8c6
references: []
approved-by: ""
approved-date: ""
---

# Stenographer Wire

## Overview

`StenographerWire` defines the JSON spelling a request body or reply takes between `steno`, the daemon and the app: snake_case keys and ISO-8601 dates. It is one definition, so the three ends of a relayed request cannot drift into three dialects; a `Date` added to a DTO decodes the same everywhere it travels.

It is a caseless enum with two factory functions. Each call returns a new `JSONEncoder` or `JSONDecoder` configured with the two strategies. The HTTP client and the app's preference push use it; the one deliberate exception is the provider registry push, which uses a default encoder (see the HTTP client recipe, [adhsdk.ingredient.foundation.stenographer.stenographer-http-client](cookbook:9c7c78d3-23ca-4ca6-a519-9968b440b8c6)).

## Behavioral Requirements

- **encoder-factory**: `StenographerWire.encoder()` MUST return a `JSONEncoder` whose key strategy is `convertToSnakeCase` and whose date strategy is `iso8601`.
- **decoder-factory**: `StenographerWire.decoder()` MUST return a `JSONDecoder` whose key strategy is `convertFromSnakeCase` and whose date strategy is `iso8601`.
- **fresh-instance**: Each call MUST return a new instance, so a caller may keep or change its own copy without affecting any other caller.
- **round-trip**: A type encoded with `encoder()` MUST decode with `decoder()` to an equal value, for property names that survive the snake_case conversion in both directions.
- **nil-omitted**: Every DTO that travels through `encoder()` MUST omit a nil optional property from the encoded object. This holds for a synthesized `Encodable` conformance, which uses `encodeIfPresent`; a DTO with a hand-written `encode(to:)` MUST do the same itself, because the factory does not enforce it.
- **no-other-settings**: The encoder and decoder MUST NOT set any other strategy: data, non-conforming floats and output formatting stay at the `Foundation` defaults.
- **no-validation**: The functions MUST NOT validate input; a malformed body is reported by the `decode` call that uses the decoder, as the standard `DecodingError`.

## Appearance

Not applicable — this is a pair of coder factories, not a visual component.

## States

Not applicable — this is a pair of coder factories, not a visual component.

## Accessibility

Not applicable — this is a pair of coder factories, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| stenographer-wire-001 | encoder-factory, nil-omitted | Encode a `SummaryPreferenceRequest` with `enabled` false, `selectedConfigId` `abc`, `maxWords` 12 and nothing else. | Keys `enabled`, `selected_config_id` and `max_words` are present with those values; `prompt` is absent (test: testSummaryRequestEncodesSnakeCaseAndOmitsNils). |
| stenographer-wire-002 | decoder-factory | Decode a snake_case summary preference reply. | `SummaryPreferenceResponse` with `maxWords` 8, `activityLines` 60 and the other fields from the body (test: testSummaryResponseDecodesSnakeCase). |
| stenographer-wire-003 | round-trip | Encode then decode an `OversightPreferenceResponse`. | The decoded value equals the original (test: testOversightRoundTrip). |
| stenographer-wire-004 | decoder-factory | Decode a `SessionDTO` from daemon JSON with `session_id` `s1`, `event_count` 3 and `started_at` `2026-10-12T00:00:00Z`. | `sessionId` `s1` and `eventCount` 3; `SessionDTO.startedAt` is a `String`, so the timestamp is carried as text and the date strategy is not exercised (test: testSessionDTOStillDecodesFromDaemonJSON). |
| stenographer-wire-005 | fresh-instance | Call `encoder()` twice. | Two different instances (test: testV5_encoderReturnsFreshInstanceEachCall). |
| stenographer-wire-006 | encoder-factory | Encode a struct with a `Date` of 2026-10-12 00:00:00 UTC. | The field is the string `2026-10-12T00:00:00Z` (test: testV6_encoderWritesDatesAsISO8601Strings). |
| stenographer-wire-007 | decoder-factory | Decode a malformed date string, `not a date`, and a well-formed `2026-10-12T00:00:00Z`. | The well-formed date decodes; the malformed one throws a `DecodingError`. Some Foundation releases also accept fractional seconds, so the vector does not rely on that (test: testV7_decoderRejectsMalformedDateString). |
| stenographer-wire-008 | no-validation | Decode `{}` as `SummaryPreferenceResponse` with `decoder()`. | Throws a `DecodingError` for the missing keys (test: testV8_decoderDoesNotSupplyMissingKeys). |

## Edge Cases

- **Null / empty input**: A nil optional is omitted from the encoded object, not written as `null`. An empty object decodes only into a type whose properties are all optional.
- **Boundary values**: Not applicable: the factories take no input; numeric and date limits are those of `JSONEncoder` and `JSONDecoder`.
- **Concurrent access**: Each call returns a separate instance, so callers do not share state through this type. A caller that shares one returned encoder or decoder across tasks owns that sharing; the HTTP client keeps one of each as constants for its lifetime.
- **Error states**: The factories cannot fail. A body that is not valid JSON, a missing key, a wrong type or a date that is not ISO-8601 is reported by the caller's `decode` as a `DecodingError`.
- **Key conversion limits**: The snake_case strategies convert by Foundation's rules; a property name with a run of capitals (an acronym such as `baseURL`) encodes to `base_url` but decodes from `base_url` as `baseUrl`, so such a property does not round-trip unless the DTO declares `CodingKeys`. The DTOs in this family avoid acronyms in property names.
- **Dates**: The DTOs in this family carry timestamps as `String` (for example `SessionDTO.startedAt`); the date strategies apply only to a `Date` property, such as `ImportRequestDTO.since`. Only dates in whole-second ISO-8601 form decode; a daemon reply with fractional seconds would fail.
- **Offline / disconnected state**: Not applicable: the type performs no network access.

## Configuration

Not applicable: the factories take no parameters and read no environment variable or settings key; the strategies are fixed in code.

## Deep Linking

Not applicable: the type defines no URL scheme or route.

## Localization

Not applicable: the type defines no user-facing string.

## Accessibility Options

Not applicable: the type presents no UI.

## Feature Flags

Not applicable: the source contains no feature-flag reference.

## Analytics

Not applicable: the source contains no analytics call.

## Privacy

- **Data handled**: None; the type only configures coders and sees no payload.
- **Storage**: None.
- **Transmission**: None by itself; the callers that use the coders decide what is sent.
- **Retention**: Not applicable: no data is kept.

## Logging

Not applicable: the type calls no logging API.

## Platform Notes

- **SwiftUI**: Source is `Core/Stenographer/StenographerWire.swift`, a caseless `enum` with two `static` functions using `JSONEncoder.keyEncodingStrategy`, `JSONDecoder.keyDecodingStrategy` and the `iso8601` date strategies from `Foundation`. Nothing is SwiftUI-specific.
- **Compose**: Use kotlinx.serialization `Json` with `namingStrategy = JsonNamingStrategy.SnakeCase` and `explicitNulls = false` and `ignoreUnknownKeys = true` (kotlinx.serialization rejects unknown keys by default, while the Foundation decoder ignores them), with a serializer for ISO-8601 dates (`java.time.Instant`). Define it once in a single holder object.
- **React/Web**: Write one pair of functions that map keys between camelCase and snake_case and convert `Date` to and from `toISOString()`. JSON has no date type, so revive date fields per DTO from an explicit field list or schema, never by guessing from the string pattern; nothing else in the app should call `JSON.stringify` on a DTO directly.
- **AppKit / UIKit**: Same source and calls; `Foundation` behaves the same on iOS and macOS, and this recipe lists `ios` among its platforms.
- **WinUI 3**: Use `System.Text.Json.JsonSerializerOptions` with `PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower`, `DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull` and a `JsonConverter<DateTime>` for ISO-8601, exposed through a static factory that returns a new options object. `System.Text.Json` accepts fractional seconds in ISO-8601 dates, which the source's strategy does not; the whole-second-only failure is Swift-specific, so vector 007 applies to the Swift implementation only; a port MAY accept the looser input.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/StenographerWire.swift` | confirmed (1.0.3) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The JSON spelling is defined once, as factories, and used by every end of a relayed request.
**Rationale**: The source comment states the aim: the three ends cannot drift into three dialects, and a `Date` added to a DTO decodes the same everywhere.
**Approved**: pending

**Decision**: Snake_case keys and ISO-8601 dates.
**Rationale**: The source comment names them as the daemon's spelling; the route bodies and replies in the HTTP client use them.
**Approved**: pending

**Decision**: Factories return new instances.
**Rationale**: The source returns a new `JSONEncoder` or `JSONDecoder` per call, so no mutable coder is shared through a global.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`separation-of-concerns` passes because the type only configures coders; it holds no DTO and does no I/O. `unit-test-coverage` passes: vectors 001 to 004 are covered by `StenographerPreferenceDTOsTests`, and 005 to 008 by `StenographerWireConformanceTests` (fresh instances, ISO-8601 date encoding, malformed-date rejection, missing keys).
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.3 | 2026-11-14 | Mike Fullerton | Conformance tests added (StenographerWireConformanceTests.swift, 8 of 8 vectors; 001-004 via existing StenographerPreferenceDTOsTests); unit-test-coverage now passed. Vector 007 text fixed (fractional seconds are accepted on macOS 26). |
| 1.0.2 | 2026-11-14 | Mike Fullerton | Linked the HTTP client recipe, scoped nil-omitted to DTOs, flagged unverified vectors, added ios, and clarified Compose, web and WinUI port notes. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Each design decision carries its own approval line |
