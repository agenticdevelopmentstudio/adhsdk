---
id: 703b9227-1bed-46ae-91f8-353c5908883d
title: "Summarize Reply DTO"
type: ingredient
version: 1.0.3
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Daemon summarize reply: session id plus the stored summary or the daemon's failure reason."
platforms:
  - swift
  - macos
tags:
  - foundation
  - stenographer
  - summaries
  - dto
depends-on: []
related:
  - e8286557-84ee-4f45-b78c-f1d184c51a37
  - 9c7c78d3-23ca-4ca6-a519-9968b440b8c6
references: []
approved-by: ""
approved-date: ""
---

# Summarize Reply DTO

## Overview

`SummarizeReplyDTO` is the reply payload for `summarizeSession`: `{session_id, summary}` on success and `{session_id, error}` on failure. Carrying the failure reason lets the app's manual Summarize show the daemon's own reason (for example the local-model memory guard's refusal) instead of a generic failure, which matches the HTTP twin's `error.localizedDescription`. A nil XPC reply remains "transport or encoding failed", a different case from a reply that carries an `error`.

The source is `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/SummarizeReplyDTO.swift`, which imports only `Foundation`. It is a `public struct` that is `Codable`, `Sendable` and `Equatable`, with three constants and a public initializer. The `{session_id, ...}` shape above is the snake_case spelling of `StenographerWire` ([adhsdk.ingredient.foundation.stenographer.stenographer-wire](cookbook:e8286557-84ee-4f45-b78c-f1d184c51a37)); under a default coder the keys are `sessionId`, `summary` and `error`.

No code in the repository builds or reads this type today. The in-repo path that carries the same information is HTTP: `StenographerHTTPClient.summarize` ([adhsdk.ingredient.foundation.stenographer.stenographer-http-client](cookbook:9c7c78d3-23ca-4ca6-a519-9968b440b8c6)) throws `SummarizeDaemonFailure` with the daemon's reason.

Guidance for a consumer, which belongs to the consumer's own spec and is not a rule of this type: show a reply's `error` text as the failure reason in place of a generic message, and treat a missing reply (nil from the XPC call) as "transport or encoding failed", not as a reply with an `error`.

## Behavioral Requirements

- **fields**: `SummarizeReplyDTO` MUST carry `sessionId` (String), `summary` (String, optional) and `error` (String, optional), all constants.
- **initializer**: The public initializer MUST take `sessionId` and default `summary` and `error` to nil.
- **success-shape**: A successful reply MUST carry the stored summary in `summary` and leave `error` nil.
- **failure-shape**: A failed reply MUST carry the failure description in `error` and leave `summary` nil.
- **session-id-always**: Every reply, successful or failed, MUST carry the `sessionId` of the session that was summarized.
- **codable-equatable**: The type MUST conform to `Codable`, `Sendable` and `Equatable`, so two replies with the same fields compare equal.
- **exclusivity-by-convention**: A producer MUST set exactly one of `summary` and `error`. The type does not enforce this: the initializer and the decoder accept both nil and both set (see the Design Decisions).
- **no-coding-keys**: The type MUST NOT declare `CodingKeys`, so its coded key names are its property names (`sessionId`, `summary`, `error`) under a default coder, and `session_id` only under a snake_case strategy.
- **wire-coders**: Anything that carries this type in the snake_case shape `{session_id, ...}` MUST encode and decode it with `StenographerWire.encoder()` and `StenographerWire.decoder()`; the snake_case shape depends on them.

## Appearance

Not applicable — this is a data-transfer type, not a visual component.

## States

Not applicable — this is a data-transfer type, not a visual component.

## Accessibility

Not applicable — this is a data-transfer type, not a visual component.

## Conformance Test Vectors

The source has no test of its own; `SummarizeReplyMappingTests` covers `StenographerSummarizing`, which maps the HTTP twin's `SummarizeDaemonFailure` to its error text. The vectors below are derived from the source. The consumer rules (showing the reason, the nil reply) are guidance in the Overview and have no vector here.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| summarize-reply-dto-001 | initializer, success-shape | `SummarizeReplyDTO(sessionId: "s1", summary: "Fixed the bug")` | `sessionId` `s1`, `summary` `Fixed the bug`, `error` nil. |
| summarize-reply-dto-002 | initializer, failure-shape | `SummarizeReplyDTO(sessionId: "s1", error: "model too large")` | `summary` nil, `error` `model too large`. |
| summarize-reply-dto-003 | initializer | `SummarizeReplyDTO(sessionId: "s1")` | Both `summary` and `error` are nil. |
| summarize-reply-dto-004 | codable-equatable | Two replies built with the same three values. | They compare equal; changing any one field makes them unequal. |
| summarize-reply-dto-005 | no-coding-keys | Encode `SummarizeReplyDTO(sessionId: "s1", summary: "x")` with a default `JSONEncoder`. | An object with keys `sessionId` and `summary`; no `error` key. |
| summarize-reply-dto-006 | no-coding-keys, codable-equatable | Encode with `StenographerWire.encoder()` and decode with `StenographerWire.decoder()`. | The key is `session_id` and the decoded value equals the original. |
| summarize-reply-dto-007 | failure-shape, session-id-always | Decode `{"sessionId":"s1","error":"model too large"}` with a default `JSONDecoder`. | `sessionId` `s1`, `error` `model too large`, `summary` nil (derived from the source; no test). |
| summarize-reply-dto-008 | fields | Decode `{"sessionId":"s1"}` with a default `JSONDecoder`. | Decodes with `summary` and `error` both nil; decoding `{}` throws a `DecodingError` for the missing `sessionId` (derived from the source; no test). |
| summarize-reply-dto-009 | exclusivity-by-convention | `SummarizeReplyDTO(sessionId: "s1", summary: "x", error: "y")` | The initializer accepts it; both fields are set (derived from the source; the type does not reject it). |

## Edge Cases

- **Null / empty input**: A reply with neither field set is accepted and is not an error; a consumer that gets one has no summary and no reason, and SHOULD treat it like a transport failure and show its generic text. An empty `summary` or `error` string is a value, not nil.
- **Boundary values**: Not applicable: the fields are free text with no length limit in this type.
- **Concurrent access**: Not applicable: the type is an immutable `Sendable` value, safe to pass between tasks.
- **Error states**: A reply with an `error` is a daemon refusal or failure carried as data. A reply that cannot be encoded or decoded is the "transport or encoding failed" case and surfaces as a nil XPC reply, not as this type.
- **Offline / disconnected state**: Not applicable: the type performs no network access. A daemon that is down yields a nil reply, which is the transport case.
- **Producer scope**: Where the XPC service builds and returns this type is outside the sources given; no code in the repository references `SummarizeReplyDTO` apart from its own declaration and doc comment, which names `summarizeSession`. The in-repo path that carries the same information is HTTP: `StenographerHTTPClient.summarize` throws `SummarizeDaemonFailure` with the daemon's reason, and `StenographerSummarizing` shows it.

## Configuration

Not applicable: the type has no parameters, environment variable or settings key beyond its three fields.

## Deep Linking

Not applicable: the type defines no URL scheme or route.

## Localization

Not applicable: the type defines no user-facing string of its own; the `error` text is the daemon's English message passed through unchanged.

## Accessibility Options

Not applicable: the type presents no UI.

## Feature Flags

Not applicable: the source contains no feature-flag reference.

## Analytics

Not applicable: the source contains no analytics call.

## Privacy

- **Data handled**: A session id and the session's generated summary text, which describes the user's work; or an error message.
- **Storage**: None here; the daemon stores the summary.
- **Transmission**: Returned to the app over XPC on the same machine.
- **Retention**: Not applicable: the type keeps nothing.

## Logging

Not applicable: the type calls no logging API.

## Platform Notes

- **SwiftUI**: Hold the reply in a view model: show the summary when `summary` is set, and when `error` is set show it as an inline message, such as a banner or alert, next to the session. In this repository the equivalent display is `StenographerSummarizing`, whose error text feeds the sessions list's error banner.
- **Compose**: Use a Kotlin `data class` with `@Serializable`, `summary` and `error` nullable and defaulting to null; the UI shows `error` when present, else the summary. An Android port replaces XPC with a bound service or an HTTP call.
- **React/Web**: Use a TypeScript interface with `summary?` and `error?`, or a discriminated union that enforces the one-of rule the Swift type leaves to convention.
- **AppKit / UIKit**: An AppKit view shows `error` in a label or `NSAlert` after the summarize action; XPC is macOS-only, so an iOS port would carry the reply over HTTP, where `SummarizeDaemonFailure` plays this role.
- **WinUI 3**: Use a C# `record SummarizeReply(string SessionId, string? Summary = null, string? Error = null)` serialized with `System.Text.Json`; value equality replaces `Equatable`. Replace XPC with a named pipe or loopback HTTP, and show `Error` in a `TextBlock` or `InfoBar` bound to a view model that implements `INotifyPropertyChanged`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/SummarizeReplyDTO.swift` | confirmed (1.0.3) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The reply carries the daemon's failure reason as a field instead of failing the call.
**Rationale**: The source comment states the aim: the app's Summarize shows the daemon's reason (such as the memory guard's refusal) instead of a generic failure.
**Approved**: pending

**Decision**: A nil XPC reply stays "transport or encoding failed", distinct from a reply with an `error`.
**Rationale**: The source comment states it, so the app can tell an unreachable daemon from a daemon that declined.
**Approved**: pending

**Decision**: One type with two optional fields, not a result enum.
**Rationale**: The source keeps the wire shape `{session_id, summary}` or `{session_id, error}` flat; the one-of rule is left to the producer.
**Approved**: pending

**Decision**: The type tolerates both fields nil and both set instead of rejecting them in `init(from:)` and the initializer.
**Rationale**: The source declares plain optionals with synthesized `Codable`, so the illegal states are representable. A custom decoder would parse the reply into a result instead of validating it afterwards, but the source does not do that, so the tolerance is recorded here for review.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`separation-of-concerns` passes because the type only holds a reply; building it, sending it and displaying it belong to other types. `unit-test-coverage` passes: `SummarizeReplyDTOTests` covers all nine vectors (initializer shapes, equality, default and wire coding, decoding).
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.3 | 2026-11-14 | Mike Fullerton | Conformance tests added (SummarizeReplyDTOTests.swift, 9 of 9 vectors); unit-test-coverage now passed. |
| 1.0.2 | 2026-11-14 | Mike Fullerton | Moved consumer rules out of the requirements into Overview guidance, recorded the both-nil and both-set tolerance as a decision, added a wire-coders requirement, linked the wire and HTTP client specs, and shortened the summary. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Each design decision carries its own approval line |
