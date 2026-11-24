---
id: 67b656ef-78a2-41ae-a910-f87f527360b1
title: "Parse Result"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Four-case outcome of parsing a hook drop-file envelope: ingest the event, skip it quietly, record it as lost, or quarantine it as unparseable."
platforms:
  - swift
  - macos
tags:
  - foundation
  - sessions
  - claude-hooks
  - parsing
depends-on:
  - 81735174-d7d7-4103-87df-7be5944c78cc
related: []
references: []
approved-by: ""
approved-date: ""
---

# Parse Result

## Overview

`ParseResult` is a `Sendable` enum that reports what `ParseResult.parse(envelopeJSON:)` made of one drop-file's text. It replaces an overloaded `nil` with four cases so a valid but untracked event can never be mistaken for a malformed one: `.event(ParsedEvent)` is to be ingested, `.skip(reason:)` is well-formed but intentionally not tracked (no `session_id`) and is discarded quietly, `.lostEvent` is an empty file whose writer died before filling it, and `.unparseable` is malformed JSON or a missing event type and is a real error to quarantine.

The parser reads the envelope `{"event": "PreToolUse", "timestamp": "...", "hook_data": {...}, "context": {...}}` plus the optional `account_email` and `oauth_account_email` keys. It is the inverse of `ParsedEvent.envelopeJSON()`; the spool, the quarantine retry and the live drop scan all go through it, so there is one decoder.

## Behavioral Requirements

### Cases

- **four-cases**: The enum MUST have exactly the cases `.event(ParsedEvent)`, `.skip(reason: String)`, `.lostEvent` and `.unparseable`.
- **sendable**: `ParseResult` MUST be `Sendable`; its `ParsedEvent` ([adhsdk.ingredient.foundation.sessions.parsed-event](cookbook:81735174-d7d7-4103-87df-7be5944c78cc)) payload is `@unchecked Sendable`, so the guarantee rests on `ParsedEvent` never being mutated, which holds because every stored property of `ParsedEvent` is a `let`.

### Parsing

- **parse-signature**: `ParseResult.parse(envelopeJSON:)` MUST take the envelope as a `String` and return a `ParseResult`; it MUST NOT throw.
- **empty-is-lost**: Text that is empty or only whitespace and newlines MUST return `.lostEvent`, decided before any JSON parsing, so the live scan and the quarantine retry cannot disagree on what "empty" means.
- **not-an-object-is-unparseable**: Text that is not a JSON object (invalid JSON, a JSON array, string, number or `null`, or valid JSON followed by trailing text) MUST return `.unparseable`.
- **missing-event-is-unparseable**: An object whose `event` key is missing, not a string or an empty string MUST return `.unparseable`.
- **event-check-before-session-check**: The `event` check MUST come first, so an object with no usable `event` is `.unparseable` even when it also has no `session_id`.
- **missing-session-is-skip**: An object with a usable `event` whose `hook_data.session_id` is missing, not a string or empty MUST return `.skip(reason: "no session_id — not a trackable session event")`; this is a deliberate discard, never an error (a StatusLine drop that carries only `term_session_id` is the example).
- **hook-data-fallback**: A `hook_data` that is missing or not an object MUST be read as an empty object, which then fails the session check and returns `.skip`.
- **event-fields**: A parseable envelope MUST return `.event` whose `eventType` is the `event` string and whose `hookData` is the `hook_data` object unchanged.
- **timestamp-default**: `timestamp` MUST be the envelope's string value, and the empty string when the key is missing or not a string.
- **context-optional**: `context` MUST be the envelope's `context` object when it is an object, and nil otherwise; it is present in v5+ drops and absent in legacy v4 drops and hand-written fixtures.
- **account-email-default**: `accountEmail` MUST be the `account_email` string, and the empty string when the key is missing or not a string.
- **oauth-email-nil-when-absent**: `oauthAccountEmail` MUST be the `oauth_account_email` string when present, including an empty string, and nil when the key is missing or not a string; nil means the envelope predates the field and empty means "resolved, no oauth login".
- **json-null-is-absent**: A JSON `null` value for any key the parser reads MUST be treated as that key being absent.
- **extra-keys-ignored**: Keys the parser does not read MUST be ignored without error.
- **no-session-id-on-result**: The result MUST NOT store `session_id`; callers MUST read it from `hookData` or `ParsedEvent.sessionId`.

### Ordering and side effects

- **pure-function**: `parse(envelopeJSON:)` MUST be a pure function of its argument: no file, network, log or notification effect, so it MAY be called concurrently from any thread.
- **single-decoder**: Every capture path that reads an envelope (drop-file scan, spool drain, quarantine retry) MUST decode through this function; this type only classifies the text, and callers act on the outcome themselves.

## Appearance

Not applicable — this is a parse-outcome enum, not a visual component.

## States

Not applicable — this is a parse-outcome enum, not a visual component.

## Accessibility

Not applicable — this is a parse-outcome enum, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| parse-result-001 | empty-is-lost | `""` | `.lostEvent` |
| parse-result-002 | empty-is-lost | `"  \n\t "` | `.lostEvent` |
| parse-result-003 | not-an-object-is-unparseable | `"{not json"` | `.unparseable` |
| parse-result-004 | not-an-object-is-unparseable | `"[]"` and `"null"` | `.unparseable`, `.unparseable` |
| parse-result-005 | missing-event-is-unparseable | `{"hook_data":{"session_id":"s1"}}` | `.unparseable` |
| parse-result-006 | missing-event-is-unparseable | `{"event":"","hook_data":{"session_id":"s-u"}}` (an envelope spooled from an event with an empty type) | `.unparseable` |
| parse-result-007 | missing-event-is-unparseable | `{"event":5,"hook_data":{"session_id":"s1"}}` | `.unparseable` |
| parse-result-008 | missing-session-is-skip | `{"event":"StatusLine","hook_data":{"term_session_id":"t1"}}` | `.skip(reason: "no session_id — not a trackable session event")` |
| parse-result-009 | hook-data-fallback | `{"event":"Stop","hook_data":[]}` | `.skip` |
| parse-result-010 | event-check-before-session-check | `{"hook_data":{}}` | `.unparseable`, not `.skip` |
| parse-result-011 | event-fields, timestamp-default, account-email-default, context-optional | `{"event":"PreToolUse","hook_data":{"session_id":"s1"}}` | `.event` with `eventType == "PreToolUse"`, `timestamp == ""`, `accountEmail == ""`, `context == nil`, `oauthAccountEmail == nil`, `hookData == ["session_id": "s1"]` |
| parse-result-012 | event-fields, context-optional, account-email-default | the envelope written for `ParsedEvent(eventType: "PreToolUse", timestamp: "2026-01-01T00:00:00Z", hookData: [session_id: "s-rt", tool_name: "Bash"], context: ["cwd": "/tmp/p"], accountEmail: "a@b.c")` | `.event` with the same `eventType`, `timestamp`, `sessionId == "s-rt"`, `accountEmail == "a@b.c"` and `context["cwd"] == "/tmp/p"` (test `testEnvelopeRoundTripsThroughTheDropFileParser`) |
| parse-result-013 | single-decoder | a quarantined drop file written by the drainer for event `doomed`, session `s-q` | `.event` with `sessionId == "s-q"` (test `testAQuarantinedFileIsReadableByTheDropFileParser`) |
| parse-result-014 | oauth-email-nil-when-absent | `"oauth_account_email":""` then `"oauth_account_email":"me@x.y"` then the key absent or `null` | `""`, `"me@x.y"`, nil |
| parse-result-015 | context-optional | `"context":"text"` | `.event` with `context == nil` |
| parse-result-016 | extra-keys-ignored | the 011 envelope plus `"unknown":1` | the same `.event` as 011 |
| parse-result-017 | not-an-object-is-unparseable | `{"event":"Stop","hook_data":{"session_id":"s1"}} trailing` | `.unparseable` |
| parse-result-018 | json-null-is-absent | `{"event":"Stop","timestamp":null,"account_email":null,"hook_data":{"session_id":"s1"}}` | `.event` with `timestamp == ""` and `accountEmail == ""` |

## Edge Cases

- **Empty or whitespace-only file** (MUST): `.lostEvent`, never `.unparseable`, so the retry budget is not burned on a file that can never parse and the error badge does not stay lit.
- **Malformed JSON** (MUST): `.unparseable`, a real error the caller quarantines.
- **Wrong-typed fields** (MUST): `event`, `timestamp`, `account_email`, `oauth_account_email` and `session_id` of a non-string type are treated as missing; `hook_data` and `context` of a non-object type are treated as missing; a JSON `null` for any of them counts as missing too (**json-null-is-absent**). No field type raises an error by itself.
- **Missing `session_id`** (MUST): `.skip`, with a fixed reason string; never quarantined, because every retry would re-parse to the same skip.
- **Boundary: both event and session missing** (MUST): `.unparseable`, by the check order.
- **Valid JSON, trailing garbage** (MUST): `.unparseable`, because the whole text must parse as one JSON object.
- **Concurrent calls** (MUST): safe, the function holds no state.
- **Cancellation, timeouts** (not applicable): the function is synchronous and does no I/O.
- **Error states, offline or disconnected** (not applicable): the input is already a `String` in memory; reading the file, and what to do when it cannot be read, belong to the caller.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `envelopeJSON` | `String` | caller | The envelope text, passed as `parse(envelopeJSON:)` |

The parser reads no environment variable, setting or injected dependency.

## Deep Linking

Not applicable: this type defines no URL or deep link.

## Localization

Not applicable: the one string, the `.skip` reason, is a fixed English diagnostic for logs and callers, not a user-facing message, and the source has no localization table.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

Not applicable: the parser returns the email addresses and payload it is given and stores and transmits nothing; storage and quarantine are the callers' concern.

## Logging

Not applicable: this code makes no log call; the caller logs the outcome.

## Platform Notes

- **SwiftUI**: Not used; the enum has no view layer.
- **Compose**: Port as a Kotlin `sealed interface ParseResult` with `data class Event`, `data class Skip`, and `object LostEvent` and `object Unparseable`; parse with `kotlinx.serialization.json.Json.parseToJsonElement` inside `runCatching`, since the source's `try?` swallows the decode error.
- **React/Web**: Port as a discriminated union on a `kind` field; `JSON.parse` in `try`/`catch`, then check `typeof` for each field and reject arrays and `null` as non-objects before reading keys.
- **AppKit / UIKit**: `Core/Sessions/ParseResult.swift`, using `JSONSerialization.jsonObject(with:)` cast to `[String: Any]` and `String.trimmingCharacters(in: .whitespacesAndNewlines)`; the rest is Foundation.
- **WinUI 3**: Use an abstract record `ParseResult` with sealed records `Event`, `Skip`, `LostEvent` and `Unparseable` (or a `OneOf`-style union), `string.IsNullOrWhiteSpace` for the empty test, and `System.Text.Json.JsonDocument.Parse` in `try`/`catch (JsonException)`, checking `JsonValueKind.Object` and `JsonValueKind.String` as the source's casts do. Keep the empty-versus-malformed order. `JsonDocument` is disposable: clone `hook_data` and `context` with `JsonElement.Clone()` or convert them to `Dictionary<string, object?>` before it is disposed.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Sessions/ParseResult.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Four cases instead of an optional.
**Rationale**: The old `nil` meant both "not tracked" and "malformed"; collapsing them quarantined valid StatusLine events and lit the error badge.
**Approved**: pending

**Decision**: An empty file is `.lostEvent`, decided inside the parser, not `.unparseable`.
**Rationale**: The writer died between creating and filling the file, so the event is gone and cannot be recovered; quarantining it would spend the retry budget on a file that never parses. Deciding it here keeps the live scan and the quarantine retry from drifting.
**Approved**: pending

**Decision**: A missing `session_id` is a skip with a reason, not an error.
**Rationale**: Session-less events are deliberately not tracked (the socket path and the envelope builder drop them too); a skip is discarded quietly.
**Approved**: pending

**Decision**: Wrong-typed optional fields fall back to defaults and the parse does not fail.
**Rationale**: One bad optional field must not lose an otherwise valid event; the cost is that a mistyped `timestamp` becomes the empty string without a signal.
**Approved**: pending

**Decision**: The doc comment says "three cases" and then lists four, and the code keeps a no-op `_ = sessionId` line.
**Rationale**: Both are leftovers of the split from the old overloaded `nil`; the code has four cases and the requirements here follow the code.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

separation-of-concerns passes: the function only decodes text into one of four outcomes, while reading files, retrying, quarantining and ingesting belong to the drain, spool and quarantine code. unit-test-coverage is passed: every vector is covered by `Tests/AgenticDeveloperHubSDKCoreTests/Sessions/ParseResultConformanceTests.swift`; parse-result-013 is asserted by `IngestDrainerTests.testAQuarantinedFileIsReadableByTheDropFileParser` in the Database target, because it needs the drainer.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (ParseResultConformanceTests.swift, 17 of 18 vectors; 013 covered by IngestDrainerTests); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Removed drainer outcomes from vectors 006 and 008, linked ParsedEvent, reworded no-session-id-on-result and sendable, made trailing garbage a MUST with a vector, stated the JSON null rule once, and fixed the configuration label to envelopeJSON. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
