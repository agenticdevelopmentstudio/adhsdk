---
id: 7dfeb441-3681-45d3-a11b-049294168607
title: "Parsed Event Envelope"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Encodes a ParsedEvent as the drop-file envelope JSON the parser reads, with a typed error for payloads that cannot be serialized, and exposes the event's session id."
platforms:
  - swift
  - macos
tags:
  - foundation
  - sessions
  - claude-hooks
  - serialization
depends-on:
  - 81735174-d7d7-4103-87df-7be5944c78cc
  - 67b656ef-78a2-41ae-a910-f87f527360b1
related: []
references: []
approved-by: ""
approved-date: ""
---

# Parsed Event Envelope

## Overview

`ParsedEventEnvelope.swift` extends `ParsedEvent` ([adhsdk.ingredient.foundation.sessions.parsed-event](cookbook:81735174-d7d7-4103-87df-7be5944c78cc)) with two members and declares one error. `sessionId` reads the session the event belongs to from its payload, so a spool row can be indexed by session without decoding every envelope. `envelopeJSON()` re-encodes the event as the drop-file envelope, the same shape `ParseResult.parse(envelopeJSON:)` ([adhsdk.ingredient.foundation.sessions.parse-result](cookbook:67b656ef-78a2-41ae-a910-f87f527360b1)) reads. The spool stores that one opaque blob and round-trips it through the parser every other capture path already uses, so spooling adds no second format and no second decoder. `EnvelopeEncodingError` says why an event could not be written to the spool.

The envelope is built at capture time, never at drain time; the reason is in Design Decisions.
## Behavioral Requirements

### Session id

- **session-id**: `sessionId` MUST return `hookData["session_id"]` when it is a string, and the empty string when the key is missing or not a string.
- **session-id-not-validated**: `sessionId` MUST NOT trim or validate the value; an empty result is what `ParseResult` later turns into `.skip`.

### Envelope encoding

- **envelope-signature**: `envelopeJSON()` MUST return the envelope as `Data` and MUST throw on failure.
- **envelope-required-keys**: The envelope MUST always carry `event` (the `eventType`, a JSON string), `timestamp` (the `timestamp` string written as given, with no re-formatting, so the encoder does not enforce ISO 8601), `hook_data` (the `hookData`, a JSON object) and `account_email` (the `accountEmail`, a JSON string that is empty when there is no account and never null).
- **envelope-context-when-present**: `context` MUST be written only when it is non-nil.
- **envelope-oauth-when-resolved**: `oauth_account_email` MUST be written only when `oauthAccountEmail` is non-nil, including when it is the empty string, so a round trip preserves the nil that means "this envelope never carried one".
- **envelope-round-trip**: `ParseResult.parse(envelopeJSON:)` of the encoded text, interpreted as UTF-8, MUST return `.event` carrying the same `eventType`, `timestamp`, `accountEmail`, `context` and `oauthAccountEmail` for any event whose `eventType` is non-empty and whose `hookData` has a non-empty string `session_id`.
- **envelope-round-trip-degenerate**: `envelopeJSON()` MUST encode without error an event with an empty `eventType`, which parses back as `.unparseable`, and one whose `hookData` has no non-empty `session_id`, which parses back as `.skip`; the encoder MUST NOT check either, as the parser decides what such an event is.
- **envelope-plain-serialization**: The encoded bytes MUST come from `JSONSerialization.data(withJSONObject:)` with no options, so key order and whitespace are unspecified and a reader MUST parse them as JSON and not compare text.

### Failure

- **not-serializable-pre-check**: Before encoding, `envelopeJSON()` MUST test the dictionary with `JSONSerialization.isValidJSONObject` and MUST throw `EnvelopeEncodingError.notSerializable(eventType)` when it is not valid (a payload holding a value `JSONSerialization` does not take, such as a `Date`, a non-finite number, or a dictionary with non-string keys).
- **other-errors-propagate**: An error thrown by `JSONSerialization.data(withJSONObject:)` after the check passes MUST propagate to the caller unchanged.
- **error-description**: `EnvelopeEncodingError.errorDescription` MUST be the event type followed by ` payload is not JSON-serializable`; for an empty event type the description therefore starts with a space, and the encoder adds no fallback text.
- **error-case**: `EnvelopeEncodingError` MUST have exactly one case, `notSerializable(String)`, whose associated value is the event type, and it MUST conform to `LocalizedError`.

### Concurrency and side effects

- **pure-encode**: `sessionId` and `envelopeJSON()` MUST NOT perform I/O, logging or notification; they read the event's immutable fields, so they MAY run concurrently on one event.
- **caller-handles-error**: The encoder MUST NOT log or retry; the caller that gets the thrown error MUST record the capture failure.

## Appearance

Not applicable — this is a serialization extension, not a visual component.

## States

Not applicable — this is a serialization extension, not a visual component.

## Accessibility

Not applicable — this is a serialization extension, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| parsed-event-envelope-001 | session-id | `hookData: ["session_id": "s-rt"]` | `sessionId == "s-rt"` (untested: the round-trip test `testEnvelopeRoundTripsThroughTheDropFileParser` does not check the accessor alone) |
| parsed-event-envelope-002 | session-id | `hookData: [:]`, and `["session_id": 5]` | `""`, `""` (untested: no test asserts this) |
| parsed-event-envelope-003 | envelope-required-keys, envelope-context-when-present, envelope-oauth-when-resolved | event with `context: nil`, `oauthAccountEmail: nil` | JSON object with exactly the keys `event`, `timestamp`, `hook_data`, `account_email` (untested: no test asserts this) |
| parsed-event-envelope-004 | envelope-context-when-present | event with `context: ["cwd": "/tmp/p"]` | the object also has `context == {"cwd":"/tmp/p"}` (untested: no test asserts this) |
| parsed-event-envelope-005 | envelope-oauth-when-resolved | `oauthAccountEmail: ""` | the object has `oauth_account_email == ""`; with nil the key is absent (untested: no test asserts this) |
| parsed-event-envelope-006 | envelope-round-trip | `PreToolUse`, `2026-01-01T00:00:00Z`, `["session_id": "s-rt", "tool_name": "Bash"]`, context `["cwd": "/tmp/p"]`, `a@b.c`, spooled and read back | parser returns `.event` with the same type, timestamp, `sessionId == "s-rt"`, `accountEmail == "a@b.c"`, `context["cwd"] == "/tmp/p"` (test `testEnvelopeRoundTripsThroughTheDropFileParser`) |
| parsed-event-envelope-007 | envelope-round-trip | a quarantined spool row written as the envelope for event `doomed`, session `s-q` | parser returns `.event` with `sessionId == "s-q"` (test `testAQuarantinedFileIsReadableByTheDropFileParser`) |
| parsed-event-envelope-008 | envelope-round-trip | `oauthAccountEmail` nil, then `""`, then `"me@x.y"` | parsed back as nil, `""`, `"me@x.y"` (untested: no test asserts this) |
| parsed-event-envelope-009 | envelope-round-trip-degenerate | `eventType: ""`, session `s-u` | `envelopeJSON()` succeeds; the parser returns `.unparseable` (test `testAnUnparseableEnvelopeIsQuarantinedWithoutReachingTheDatabase`) |
| parsed-event-envelope-010 | envelope-round-trip-degenerate | event `StatusLine` with `hookData["session_id"] == ""` | encodes; the parser returns `.skip` (test `testAnUntrackableEventIsDiscardedQuietlyAndNeverQuarantined`) |
| parsed-event-envelope-011 | not-serializable-pre-check | `hookData: ["session_id": "s", "when": Date()]`, `eventType: "PreToolUse"` | throws `EnvelopeEncodingError.notSerializable("PreToolUse")` (untested: no test asserts this) |
| parsed-event-envelope-012 | not-serializable-pre-check | `hookData: ["session_id": "s", "n": Double.nan]` | throws `notSerializable` (untested: no test asserts this) |
| parsed-event-envelope-013 | error-description | `EnvelopeEncodingError.notSerializable("Stop").errorDescription` | `Stop payload is not JSON-serializable` (untested: no test asserts this) |
| parsed-event-envelope-014 | not-serializable-pre-check | a non-serializable value inside `context` only | throws `notSerializable`, since `context` is part of the checked envelope (untested: no test asserts this) |
| parsed-event-envelope-015 | error-description | `EnvelopeEncodingError.notSerializable("").errorDescription` | ` payload is not JSON-serializable` with a leading space (untested: no test asserts this) |
| parsed-event-envelope-016 | envelope-required-keys | an event with `timestamp: "x"` and `accountEmail: ""` | the object has `timestamp == "x"` and `account_email == ""`, both JSON strings (untested: no test asserts this) |
## Edge Cases

- **Empty or missing data** (MUST): an empty `hookData` encodes as `{}`; `sessionId` is then empty and the parser skips it.
- **Non-serializable payload** (MUST): throws `notSerializable` with the event type, before any bytes are produced.
- **Empty event type** (MUST): encodes without error and fails at parse time as `.unparseable`; the encoder does not guard it.
- **Number and boolean fidelity** (MUST): values pass through `JSONSerialization`, so numbers come back as Foundation numbers; a port MUST preserve the JSON number and boolean distinction.
- **Large payloads** (not applicable): the source sets no size limit.
- **Concurrent access** (MUST): safe on one event, since every field is immutable and the function does no shared writes.
- **Error states, offline or disconnected** (not applicable): the function does no I/O beyond in-memory encoding; the spool write that follows and its failures belong to the caller.
- **Cancellation, timeouts** (not applicable): the function is synchronous.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| the event | `ParsedEvent` | receiver | The only input to `sessionId` and `envelopeJSON()` |

The extension reads no environment variable, setting or injected dependency.

## Deep Linking

Not applicable: this code defines no URL or deep link.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (literal in `EnvelopeEncodingError.errorDescription`) | `<eventType> payload is not JSON-serializable` | The error's description; hardcoded English with the event type interpolated and no localization table |

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy
- **Data handled**: The envelope contains personal data: the account email and, when resolved, the oauth account email, plus the event's `hookData` and `context`, which can hold prompts, file paths and working directories.
- **Storage**: This code stores nothing; the caller stores the bytes, and the spool owns where they go and how long they are retained.
- **Transmission**: None; the encoder performs no network access.
- **Retention**: None here; retention belongs to the spool that holds the bytes.
## Logging

Not applicable: this code makes no log call; its doc comment says the caller logs the capture failure when the encoder throws.

## Platform Notes

- **SwiftUI**: Not used; there is no view layer.
- **Compose**: Port with `kotlinx.serialization.json.buildJsonObject`, writing `context` and `oauth_account_email` only when non-null, and a custom exception class for the not-serializable case; check serializability by converting the `Map<String, Any?>` payload to `JsonElement` before encoding, since Kotlin has no `isValidJSONObject`.
- **React/Web**: `JSON.stringify` of a plain object, omitting `undefined` keys; `JSON.stringify` silently drops functions and converts `Date` to a string and `NaN` to `null`, so write an explicit validity walk to match the source's throw.
- **AppKit / UIKit**: The extension is Foundation-only: validate the dictionary with `JSONSerialization.isValidJSONObject`, encode it with `JSONSerialization.data(withJSONObject:)`, and let `LocalizedError` supply `errorDescription`. An AppKit or UIKit app uses it unchanged.
- **WinUI 3**: Use `System.Text.Json` (`Utf8JsonWriter` or a `JsonObject`) to build the envelope, adding `context` and `oauth_account_email` only when not null, and return `byte[]`. `System.Text.Json` has no `isValidJSONObject`: write a walk over the `IReadOnlyDictionary<string, object?>` payload that accepts string, bool, numbers (rejecting `double.NaN` and infinities, which `Utf8JsonWriter` refuses with an `ArgumentException`), null, lists and nested string-keyed dictionaries, and throw a custom `EnvelopeEncodingException : Exception` carrying the event type, with `Message` set to the source's text. Do not rely on `JsonSerializer.Serialize` of `object` for arbitrary values: it serializes a `DateTime` quietly, which the source rejects. `sessionId` becomes a property reading the payload with `TryGetValue` and a `string` pattern match.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Sessions/ParsedEventEnvelope.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The spool stores the drop-file envelope, written by this encoder and read by `ParseResult`.
**Rationale**: One opaque blob and one decoder mean spooling adds no second format to keep in step and no second decoder to get wrong.
**Approved**: pending

**Decision**: The envelope is built at capture time, never at drain time.
**Rationale**: The envelope builder resolves the live `claude` process by cwd and reads its environment, so `context` is only true when the hook fires; deferring would attribute the event to whatever process holds that cwd later.
**Approved**: pending

**Decision**: Serializability is checked up front and throws a typed error.
**Rationale**: Finding out on the hook delivery, with the event in hand, costs one logged capture failure; finding out later leaves a row that fails to decode on every drain forever.
**Approved**: pending

**Decision**: `oauth_account_email` is written only when non-nil, including the empty string.
**Rationale**: The key's absence is the nil that means "predates the field"; an empty value means "resolved, no login", and a round trip must keep the two apart.
**Approved**: pending

**Decision**: The encoder does not reject an empty event type or a missing `session_id`.
**Rationale**: Those are the parser's outcomes (`.unparseable`, `.skip`); the drain handles each, so the encoder stays a plain serializer.
**Approved**: pending

**Decision**: The error description is a hardcoded English literal.
**Rationale**: The source has no localization table, and the text is read by developers in logs, not shown as an end-user message.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |

separation-of-concerns passes: the extension only serializes one event and names the session, while parsing, spooling and quarantining are other types. unit-test-coverage passes: `ParsedEventEnvelopeConformanceTests` (`Tests/AgenticDeveloperHubSDKCoreTests/Sessions/ParsedEventEnvelopeConformanceTests.swift`) has one test per vector 001-016, covering the key set, the omitted-key rules, the round trip and `notSerializable`. explicit-error-handling passes: an unserializable payload throws a typed error before any bytes exist and other encoder errors propagate. no-hardcoded-strings is not applicable: the error description is developer-facing log text (see Design Decisions), so the check is omitted.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (ParsedEventEnvelopeConformanceTests.swift, 16 of 16 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Linked ParsedEvent and ParseResult, removed duplicated and untestable requirements, specified key types and the empty-event-type description, marked untested vectors, dropped the contradicting compliance row, and made Privacy applicable. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
