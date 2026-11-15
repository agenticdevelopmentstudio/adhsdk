---
id: 6a37e531-b5ae-4eea-b4f0-d28866776ddc
title: "Session Event Sink"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Transport-neutral protocol a daemon publishes ingested events and session status changes through, plus the one JSON encoding every sink receives."
platforms:
  - swift
  - macos
tags:
  - foundation
  - sessions
  - claude-hooks
  - event-publishing
depends-on:
  - 787b5da6-2f20-4f3e-8104-1763959a735f
related:
  - 81735174-d7d7-4103-87df-7be5944c78cc
  - 706313bb-1a26-4477-9250-62ad50aff110
references: []
approved-by: ""
approved-date: ""
---

# Session Event Sink

## Overview

`SessionEventSink` is where a daemon publishes what it has ingested, so the code that ingests does not know whether subscribers are reached over SSE, XPC, both or neither. It has two operations: `broadcast(eventType:payload:sessionId:)` for one ingested hook event, and `broadcastSessionStatus(sessionId:status:)` for a liveness change that happened outside any hook event.

`SessionEventEncoding` is the one encoding of what a sink publishes. Ingestion encodes once and hands every sink the same bytes, so two daemons publish identical payloads whatever their transports. That holds byte for byte only when every daemon uses this encoder's options, including the `/` escaping fixed by `encode-slash-escaping`. In the SDK's daemon code, `EventIngestor` calls `SessionEventEncoding.encode` on each ingested event and passes the bytes to `sink.broadcast`; `EventIngestor.broadcastSessionStatus` forwards status changes to the sink, and `LivenessService` reports its changes through an `onStatusChange` callback.

## Behavioral Requirements

**Sink protocol**

- **sink-sendable**: `SessionEventSink` MUST be a `Sendable` protocol, so one sink can be shared across the daemon's queues and tasks.
- **sink-broadcast-signature**: A sink MUST implement `broadcast(eventType: String, payload: Data, sessionId: String?)`, which returns nothing and does not throw.
- **sink-status-signature**: A sink MUST implement `broadcastSessionStatus(sessionId: String, status: SessionStatus)` (Session Status ([adhsdk.ingredient.foundation.sessions.session-status](cookbook:787b5da6-2f20-4f3e-8104-1763959a735f))), which returns nothing and does not throw.
- **broadcast-payload-prebuilt**: The `payload` given to `broadcast` MUST be the already-encoded wire JSON of the event; a sink MUST NOT re-encode it.
- **broadcast-session-filter**: `sessionId` MUST be passed so a transport can filter subscribers to one session; it is optional and `nil` means the event is not tied to one session.
- **status-payload-shape**: A transport publishing a session status change MUST publish the payload `{"session_id": ..., "status": ...}` produced by `SessionEventEncoding.encodeSessionStatus(sessionId:status:)`.
- **sink-transport-neutral**: The ingesting code MUST NOT depend on how a sink delivers; whether it uses SSE, XPC, both or neither is the sink's concern.
- **sink-no-delivery-signal**: A sink MUST NOT report delivery success or failure to its caller; neither protocol method returns a value or throws.

**Caller obligations**

- **caller-skips-on-encode-failure**: A caller that encodes an event for a sink MUST NOT call `broadcast` with a payload for that event when `encode` returns `nil`. `EventIngestor` logs a debug line `broadcast encode failed` and returns without publishing, so a failed encode is a logged drop, not a crash.

**Encoding**

- **encode-snake-case**: `SessionEventEncoding.encode(_:)` MUST convert coding keys to snake_case.
- **encode-iso8601**: `SessionEventEncoding.encode(_:)` MUST encode dates in the ISO-8601 strategy.
- **encode-sorted-keys**: `SessionEventEncoding.encode(_:)` MUST output object keys in sorted order, so equal values give equal bytes.
- **encode-optional-result**: `SessionEventEncoding.encode(_:)` MUST return `nil` when encoding fails; it MUST NOT throw and the error is discarded.
- **encode-generic**: `encode(_:)` MUST accept any `Encodable` value.
- **encode-status-fields**: `encodeSessionStatus(sessionId:status:)` MUST produce a JSON object with exactly two keys: `session_id` holding the id and `status` holding the status's raw string.
- **encode-status-raw**: The `status` field MUST be `SessionStatus.rawValue`: `"active"`, `"stale"` or `"ended"`.
- **encode-status-via-encode**: `encodeSessionStatus` MUST encode through `encode(_:)`, so it shares the same options and the same `nil` on failure.
- **encode-stateless**: `SessionEventEncoding.encode(_:)` MUST be stateless and safe to call concurrently; the type holds no shared encoder state.
- **encode-slash-escaping**: `SessionEventEncoding.encode(_:)` MUST escape `/` in string values as `\/`, which is Foundation's default, so that every port gives the same bytes as the Swift source.

## Appearance

Not applicable — this is a publishing protocol and an encoder, not a visual component.

## States

Not applicable — this is a publishing protocol and an encoder, not a visual component. The protocol itself has no runtime state machine; any state belongs to a conforming transport.

## Accessibility

Not applicable — this is a publishing protocol and an encoder, not a visual component.

## Conformance Test Vectors

The source has no test of `SessionEventEncoding` beside it. `RecordingSink` (database test support) is a test double that records each call; the sink vectors below drive it through `EventIngestor`, the real caller, and assert what gets published.
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| session-event-sink-001 | encode-status-fields, encode-status-raw | `encodeSessionStatus(sessionId: "s1", status: .active)` | The bytes of `{"session_id":"s1","status":"active"}` |
| session-event-sink-002 | encode-status-raw | `encodeSessionStatus(sessionId: "s1", status: .ended)` | `status` is `"ended"` |
| session-event-sink-003 | encode-status-raw | `encodeSessionStatus(sessionId: "s1", status: .stale)` | `status` is `"stale"` |
| session-event-sink-004 | encode-snake-case | `encode` of a struct with property `lastEventType` | JSON key `last_event_type` |
| session-event-sink-005 | encode-iso8601 | `encode` of a struct holding the `Date` for 2026-01-01T00:00:00Z | The value is the string `"2026-01-01T00:00:00Z"` |
| session-event-sink-006 | encode-sorted-keys | `encode` of a struct with properties declared `zeta` then `alpha` | `alpha` appears before `zeta` in the bytes |
| session-event-sink-007 | encode-sorted-keys, encode-stateless | Encode the same value twice, and from several tasks at once | The byte sequences are all equal |
| session-event-sink-008 | encode-optional-result | `encode` of a value whose `encode(to:)` throws, or that holds a non-finite `Double` | `nil`, with no error raised |
| session-event-sink-009 | sink-broadcast-signature, broadcast-payload-prebuilt | Test `testTheDrainWritesASpooledEventAndPublishesIt`: an `EventIngestor` built with a `RecordingSink` drains one spooled event | `sink.events` holds an entry for the event with `sessionId == "s-p2"` and the bytes `SessionEventEncoding.encode` gave for the ingested event |
| session-event-sink-010 | broadcast-session-filter | `broadcast(eventType: "Stop", payload: bytes, sessionId: nil)` on a `RecordingSink` | The recorded `sessionId` is `nil` |
| session-event-sink-011 | sink-status-signature | `EventIngestor.broadcastSessionStatus(sessionId: "s1", status: .ended)` with a `RecordingSink` injected | `statuses` holds `("s1", .ended)` |
| session-event-sink-012 | sink-no-delivery-signal | `EventIngestor` ingests an event while the injected sink delivers to no subscribers (a sink that drops every call) | Ingestion completes and the ingested row is written; the caller sees no error |
| session-event-sink-013 | caller-skips-on-encode-failure | `EventIngestor` ingests an event whose `SessionEventEncoding.encode` returns `nil`, with a `RecordingSink` injected | `sink.events` is empty and no crash occurs |
| session-event-sink-014 | encode-slash-escaping | `encode` of a struct whose string property is `"a/b"` | The bytes contain `a\/b` |
## Edge Cases

- **Encoding failure**: see `#requirements/caller-skips-on-encode-failure`; a failed encode is a logged drop, not a crash.
- **Nil session id**: `broadcast` with `sessionId` of `nil` MUST be accepted; a transport that filters by session decides who receives it.
- **Empty payload**: The protocol does not reject an empty `Data` payload; no source rule covers it, and the sink publishes what it is given.
- **No subscribers or transport down**: A sink MAY drop or ignore the call; the protocol has no return value or throw, so ingestion proceeds regardless.
- **Slash in a session id**: The encoder sets only `sortedKeys`, so Foundation's default escaping of `/` as `\/` applies to any string value; `encode-slash-escaping` makes that part of the contract for every port.
- **Snake-case conversion of keys**: `convertToSnakeCase` applies to every key of the encoded value, including nested objects, and not only top-level ones.
- **Status payload keys**: `StatusPayload` declares its own coding keys `session_id` and `status`, which are already snake_case, so the conversion leaves them unchanged.
- **Concurrent access**: The protocol is `Sendable`, so calls MAY arrive from several queues at once; whether a sink serializes them is the conforming type's job. The encoding type is stateless and safe to call concurrently. `RecordingSink` guards its arrays with an `NSLock`.
- **Boundary values, offline, cancellation**: Not applicable to the protocol: it holds no numeric limits, does no I/O of its own and has no asynchronous work to cancel; network behavior belongs to a conforming transport.

## Configuration
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `sink` | `any SessionEventSink` | none | Injected into ingestion by the daemon runtime (`behavior.sink`); the daemon picks the transports. |

The encoder's key, date and output options are fixed by the Encoding requirements and are not configurable.
## Deep Linking

Not applicable: the protocol and encoder have no URLs or routes; any endpoint belongs to a conforming transport.

## Localization

Not applicable: the payloads are machine JSON with fixed keys, and the source holds no user-facing strings.

## Accessibility Options

Not applicable: the component is not a visual component, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply to it.

## Feature Flags

Not applicable: the source reads no flags.

## Analytics

Not applicable: the protocol publishes ingested hook events to subscribers; it records no usage analytics of its own.

## Privacy

Not applicable: the component holds and stores nothing. It forwards bytes the caller built, which may carry session ids and hook event data, so the privacy of those payloads is the caller's concern.

## Logging

Not applicable: the source makes no log calls. The only related log line is written by `EventIngestor` when `encode` returns `nil`, outside this file.

## Platform Notes

- **SwiftUI**: `SessionEventSink.swift` in `Core/Sessions` is Foundation-only. A SwiftUI app does not call the sink; it subscribes to the daemon's transport and decodes the snake_case JSON with `convertFromSnakeCase` and the ISO-8601 date strategy.
- **Compose**: Port the protocol as a Kotlin `interface SessionEventSink` with two functions. Use kotlinx.serialization `Json` with a snake-case naming strategy, and sort keys by writing through a `TreeMap` or a sorted `JsonObject`. A `SharedFlow` is a natural transport.
- **React/Web**: Port as a TypeScript interface with two methods. A browser client receives the payload over `EventSource` and parses it with `JSON.parse`, treating `status` as the union `"active" | "stale" | "ended"`. Encode with a function that sorts keys before `JSON.stringify`.
- **AppKit / UIKit**: Conforming sinks in the daemon bridge to SSE or XPC; on the client side an AppKit or UIKit controller decodes the payload and updates its model on the main thread. The `Sendable` conformance means the sink may be called from any queue.
- **WinUI 3**: Port as a C# `interface ISessionEventSink` with `void Broadcast(string eventType, ReadOnlyMemory<byte> payload, string? sessionId)` and `void BroadcastSessionStatus(string sessionId, SessionStatus status)`. Encode with `System.Text.Json`: `JsonNamingPolicy.SnakeCaseLower` (.NET 8 and later) gives the snake_case keys, and `DateTime` and `DateTimeOffset` serialize as ISO-8601 by default. `System.Text.Json` has no sorted-keys option, so sort manually with a `SortedDictionary` or a custom `JsonConverter`, and note it does not escape `/` where Foundation does, so write `/` as `\/` yourself (a custom `JavaScriptEncoder` or a post-pass) to meet `encode-slash-escaping`. Return `null` from a `TryEncode` wrapper that catches `JsonException`. For fan-out use `System.Threading.Channels` or `SignalR`; for a server-sent stream in an ASP.NET Core minimal API use `TypedResults.ServerSentEvents` or write `text/event-stream` to the response body, hosted in an `IHostedService`. The sink methods are synchronous in the source, so keep them non-blocking, such as `Channel.Writer.TryWrite`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Sessions/SessionEventSink.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |
| apple | `packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKDatabaseTests/Daemon/Support/RecordingSink.swift` | confirmed (1.0.2) |

## Design Decisions

**Decision**: Ingestion encodes each event once and hands every sink the same bytes.
**Rationale**: The doc comment on `SessionEventSink` in `SessionEventSink.swift` says the encoding is not the sink's concern, so two daemons publish identical payloads whatever their transports, and no transport serializes the event twice on the ingest hot path (the comment in `broadcastIngestedEvent` in `Database/Daemon/Ingestion/EventIngestor.swift`, line 261).
**Approved**: pending

**Decision**: The sink protocol returns nothing and cannot throw.
**Rationale**: Ingestion must not depend on, or be blocked by, delivery. A transport with no subscribers is a normal condition, and the source gives callers no delivery signal.
**Approved**: pending

**Decision**: `encode` returns `nil` on failure, using `try?`, rather than throwing.
**Rationale**: The caller treats an unencodable event as a dropped broadcast and logs it. The cost is that the underlying error is discarded, which is a deliberate lossy projection and not a silent one: the caller logs the failure.
**Approved**: pending

**Decision**: Keys are sorted and converted to snake_case, and dates are ISO-8601.
**Rationale**: The source names these as the wire format (snake_case, ISO-8601 dates, sorted keys). Sorted keys make equal values byte-equal, so payloads from two daemons can be compared.
**Approved**: pending

**Decision**: The status payload is built with explicit coding keys in a private struct.
**Rationale**: It pins `session_id` and `status` as the contract regardless of the key strategy, and sends the status as its raw string.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |

Separation of concerns passes: the file splits publishing (the protocol) from encoding (`SessionEventEncoding`), and leaves transport choice to conforming types. Unit-test coverage is partial: `SessionEventEncodingConformanceTests` (Core) covers vectors 001-008 and 014, `SessionEventSinkConformanceTests` (Database) covers 010-012 and `IngestionPipelineTests` covers 009. Vector 013 is skipped: `IngestedEvent` holds only `Int64` and `String` fields, so no ingested event can make `encode` return `nil` in a unit test. Explicit error handling is partial: `encode` discards the encoding error and the protocol methods give no delivery signal, though the one caller logs an encode failure.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (SessionEventEncodingConformanceTests.swift, SessionEventSinkConformanceTests.swift, IngestionPipelineTests.swift extended, 13 of 14 vectors); unit-test-coverage now partial (013 skipped: IngestedEvent cannot fail to encode). |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Added a slash-escaping requirement and a caller obligation for encode failure, restated the encoder statelessness requirement, added RFC 2119 wording to sink-no-delivery-signal, cited EventIngestor, drove the sink vectors through EventIngestor, trimmed Configuration, filled depends-on and related, and emptied references. |
