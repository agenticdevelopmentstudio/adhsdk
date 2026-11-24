---
id: 81735174-d7d7-4103-87df-7be5944c78cc
title: "Parsed Event"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Immutable value for one hook event ready for ingestion, built by the drop-file parser or the envelope builder and consumed by the daemon's ingestion handler."
platforms:
  - swift
  - macos
tags:
  - foundation
  - sessions
  - claude-hooks
  - ingestion
depends-on: []
related:
  - 7dfeb441-3681-45d3-a11b-049294168607
  - 67b656ef-78a2-41ae-a910-f87f527360b1
  - 1c2b7ff7-4d12-4580-94b0-17258d3384e1
references: []
approved-by: ""
approved-date: ""
---

# Parsed Event

## Overview

`ParsedEvent` is a struct holding one Claude Code hook event in the form the daemon ingests: the event type string, a timestamp string, the hook's payload (`hookData`), an optional `context` of facts about the live `claude` process, the `accountEmail` the event was fingerprinted to, and an optional `oauthAccountEmail`. The oauth login is resolved when the hook fires and carried on the event, not looked up at write time; that capture-time requirement belongs to the hook-capture producer, and the reasoning is in Design Decisions.

It is produced by the drop-file parser (`ParseResult.parse(envelopeJSON:)`, Parse Result ([adhsdk.ingredient.foundation.sessions.parse-result](cookbook:67b656ef-78a2-41ae-a910-f87f527360b1))) or the envelope builder (the Unix socket path) and consumed by the daemon's ingestion handler.

It is `@unchecked Sendable`: the dictionaries are built once and never mutated afterwards, so the value can cross task boundaries even though the compiler cannot prove it. The type has no behavior beyond storing its fields; the envelope encoding and `sessionId` accessor live in an extension in `ParsedEventEnvelope.swift` (Parsed Event Envelope ([adhsdk.ingredient.foundation.sessions.parsed-event-envelope](cookbook:7dfeb441-3681-45d3-a11b-049294168607))).

## Behavioral Requirements

### Fields

- **event-type**: `eventType` MUST hold the event name string exactly as given; the type does not check it against `HookEventType`, so an unmodelled type is carried.
- **timestamp**: `timestamp` MUST hold the timestamp string exactly as given, with no parsing or format check.
- **hook-data**: `hookData` MUST hold the hook payload dictionary as given; it is not copied deeply or inspected.
- **context**: `context` MUST hold the optional context dictionary as given; nil means no context (present in v5+ drops, absent in legacy v4 drops and hand-written fixtures).
- **account-email**: `accountEmail` MUST hold the account email string as given; it is empty when no token could be fingerprinted.
- **oauth-account-email**: `oauthAccountEmail` MUST hold the optional oauth login email as given, and the initializer MUST default it to nil.
- **oauth-nil-versus-empty**: nil MUST mean "this envelope predates the field" (a drop file written by an older build), the only case where resolving the login at write time is still the best answer; the empty string MUST mean "resolved at capture, and there was no oauth login", a real answer and not a missing one.

### Construction

- **initializer**: The public initializer MUST take `eventType`, `timestamp`, `hookData`, `context` and `accountEmail` with no defaults, and `oauthAccountEmail` defaulting to nil.
- **no-validation**: The initializer MUST NOT validate or normalise any argument; an empty `eventType`, an empty `timestamp` or a `hookData` with no `session_id` is accepted, and the later parse step decides what such an event is.
- **immutable-fields**: Every field MUST be a `let`, so an instance cannot be changed after construction.

### Concurrency

- **unchecked-sendable**: The type MUST be `@unchecked Sendable` on the stated invariant that its dictionaries are constructed once and never mutated; the compiler does not enforce that the `Any` values inside are immutable, so a caller MUST NOT put a mutable reference object into `hookData` or `context` and change it later.
- **no-side-effects**: Constructing or reading a `ParsedEvent` MUST NOT perform I/O, logging or notification.

### Related behavior in the same module

- **session-id-accessor**: `ParsedEvent.sessionId` is defined by the envelope-encoding spec (Parsed Event Envelope ([adhsdk.ingredient.foundation.sessions.parsed-event-envelope](cookbook:7dfeb441-3681-45d3-a11b-049294168607))); this type adds no accessor of its own.
- **no-equatable**: The type MUST NOT conform to `Equatable` or `Codable`; tests compare fields one by one, and the serialized form is the envelope.

## Appearance

Not applicable — this is a data value type, not a visual component.

## States

Not applicable — this is a data value type, not a visual component.

## Accessibility

Not applicable — this is a data value type, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| parsed-event-001 | initializer, event-type, timestamp, hook-data, account-email, context | `ParsedEvent(eventType: "PreToolUse", timestamp: "2026-01-01T00:00:00Z", hookData: ["session_id": "s-1", "tool_name": "Bash"], context: nil, accountEmail: "a@b.c")` (the `event()` helper in `IngestSpoolTests`) | each field reads back as given; `context == nil` |
| parsed-event-002 | oauth-account-email, initializer | the same call as 001 | `oauthAccountEmail == nil` |
| parsed-event-003 | oauth-nil-versus-empty | `oauthAccountEmail: ""` | `oauthAccountEmail == ""`, which is not nil |
| parsed-event-004 | oauth-account-email | `oauthAccountEmail: "me@x.y"` | `"me@x.y"` |
| parsed-event-005 | context | `context: ["cwd": "/tmp/p"]` | `context?["cwd"] as? String == "/tmp/p"` (test `testEnvelopeRoundTripsThroughTheDropFileParser`, after the round trip) |
| parsed-event-006 | no-validation, event-type | `eventType: ""`, `hookData: ["session_id": "s-u"]` | constructed without error (what parsing does with it is in the Parse Result ([adhsdk.ingredient.foundation.sessions.parse-result](cookbook:67b656ef-78a2-41ae-a910-f87f527360b1)) vectors) |
| parsed-event-007 | no-validation | `hookData: [:]` | constructed without error; its `sessionId` is `""` (the parse outcome is in the Parse Result ([adhsdk.ingredient.foundation.sessions.parse-result](cookbook:67b656ef-78a2-41ae-a910-f87f527360b1)) vectors) |
| parsed-event-008 | account-email | `accountEmail: ""` | `accountEmail == ""` |
| parsed-event-009 | session-id-accessor | `hookData: ["session_id": "s-rt"]` | `sessionId == "s-rt"` (test `testEnvelopeRoundTripsThroughTheDropFileParser`) |
| parsed-event-010 | immutable-fields | static check (code review or API-surface inspection, not a runtime test): every stored property is declared `let` | no stored property is `var`; assigning to `eventType` on a constant is a compile error |

## Edge Cases

- **Empty or missing data** (MUST): empty strings and an empty `hookData` are accepted; the type never rejects its input.
- **Nil versus empty oauth email** (MUST): the two differ in meaning and MUST NOT be conflated by a port.
- **Boundary values** (not applicable): no field has a range or length limit in this type.
- **Non-JSON values in `hookData`** (SHOULD): a port SHOULD accept them here and leave detection to encoding, where `envelopeJSON()` throws `EnvelopeEncodingError.notSerializable`.
- **Concurrent access** (MUST): safe only while nothing mutates a reference value held inside `hookData` or `context`; the type itself has no mutable state.
- **Error states, offline or disconnected** (not applicable): the type does no I/O and raises no errors.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `eventType` | `String` | required | Hook event name |
| `timestamp` | `String` | required | Event timestamp text |
| `hookData` | `[String: Any]` | required | Hook payload |
| `context` | `[String: Any]?` | required (may be nil) | Facts about the live `claude` process, resolved at capture |
| `accountEmail` | `String` | required | Fingerprinted account email, empty when none |
| `oauthAccountEmail` | `String?` | `nil` | Oauth login at capture; nil means the envelope predates the field |

## Deep Linking

Not applicable: this type defines no URL or deep link.

## Localization

Not applicable: this type contains no user-facing string.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy
This type stores no data of its own beyond its in-memory fields and transmits nothing, but it carries personal data (`accountEmail`, `oauthAccountEmail`, and whatever the hook payload and `context` hold). Storage and retention belong to the spool, the quarantine and the ingest store.

- **no-logging-of-fields**: A port MUST NOT write `accountEmail`, `oauthAccountEmail`, `hookData` or `context` to a log, and MUST NOT include them in a `description` or other default string representation of the value.
## Logging

Not applicable: this code makes no log call.

## Platform Notes

- **SwiftUI**: Not used; the type has no view layer.
- **Compose**: Port as a Kotlin `data class` with `Map<String, Any?>` for the payload and `String?` for the oauth email; make the maps read-only copies (`toMap()`) to enforce the never-mutated invariant the source only states. A `data class` synthesizes structural `equals`, `hashCode` and `toString`, which the source deliberately does not have; use a plain `class` with `val` properties, or override those three so they do not compare or print the payload.
- **React/Web**: Port as a readonly TypeScript interface with `Readonly<Record<string, unknown>>`, `oauthAccountEmail?: string`; keep `undefined` distinct from `""`.
- **AppKit / UIKit**: Use the Swift struct as is; it is Foundation-only and has no view layer, so macOS and iOS share it. Keep `@unchecked Sendable`, since `[String: Any]` is not `Sendable`, and do not add `Equatable` conformance.
- **WinUI 3**: Use a C# `sealed record ParsedEvent` with `init` properties, `IReadOnlyDictionary<string, object?>` for `HookData` and `Context` (wrap with `ReadOnlyDictionary` over a copy so the never-mutated invariant is enforced by the type, which the source only promises), and `string?` for `OauthAccountEmail` with nullable reference types enabled so nil and empty stay distinct. A record's synthesized equality compares dictionaries by reference, unlike the source which has no equality at all. Hand it to other tasks as is; an immutable record needs no lock.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Sessions/ParsedEvent.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The oauth email is carried on the event, resolved at capture.
**Rationale**: Write time may be much later (spool during a migration, a drop file across a reboot), and the first-oauth-wins upsert would make a wrong attribution permanent.
**Approved**: pending

**Decision**: `oauthAccountEmail` is optional, and nil and empty are different answers.
**Rationale**: Older drop files carry no field, where write-time resolution is still the best answer; empty is a resolved "no login".
**Approved**: pending

**Decision**: The type is `@unchecked Sendable` with immutable fields instead of holding a `Sendable` payload type.
**Rationale**: Hook payloads are arbitrary JSON, held as `[String: Any]`; the invariant is that they are built once and never mutated, which the compiler cannot verify.
**Approved**: pending

**Decision**: The initializer validates nothing.
**Rationale**: Deciding what a malformed or session-less event is belongs to `ParseResult`, which has three non-event outcomes for it; a second check here would drift.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

separation-of-concerns passes: the type only stores one event's fields, while parsing is `ParseResult`, encoding is the envelope extension and persistence is the spool and ingest store. unit-test-coverage is partial: `Tests/AgenticDeveloperHubSDKCoreTests/Sessions/ParsedEventConformanceTests.swift` covers parsed-event-001 to 009; parsed-event-010 is skipped because it is a static check (every stored property is `let`), not a runtime test.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (ParsedEventConformanceTests.swift, 9 of 10 vectors; 010 is a static check); unit-test-coverage now partial. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Linked the envelope, ParseResult and HookEventType specs, moved the capture-time requirement to Design Decisions, added keywords to no-equatable, made Privacy applicable with a no-logging requirement, added platform guidance and an equality caveat, and reworded vectors 006, 007 and 010. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
