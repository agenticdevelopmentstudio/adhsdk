---
id: f3f1af27-6cd7-4b3f-9024-135c6f6e89da
title: "Work Tracking XPC Client"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The work-tracking service interface and its transport-based client: typed status, preference and span calls where every failure answers nil."
platforms:
  - swift
  - macos
tags:
  - work-tracking
  - foundation
  - client
  - xpc
depends-on:
  - aa775836-5679-4a22-9ff3-b2bdcb09cc20
  - 92a9546a-eec1-47ed-8420-7db51e8d0261
  - 02cfb457-46da-4814-a1de-8962533ad78e
related:
  - 8055f7c9-d336-4b71-9f95-1bf4bdef7b92
  - 36c76e0f-b41c-4fd6-a349-a0e9241fb489
references: []
approved-by: ""
approved-date: ""
---

# Work Tracking XPC Client

## Overview

Defines `WorkTrackingService`, "everything an app can ask of work tracking", and `WorkTrackingXPCClient`, its implementation over XPC to a daemon that exports `WorkTrackingXPCProtocol`. Per the service doc comment, reads and writes answer nil "when the daemon was unreachable, refused, or its reply couldn't be read". The client is generic over `WorkTrackingXPCTransport`, a two-method protocol shaped like DaemonKit's `XPCClient`, so any transport, including a test double, stands in and this tier links no daemon framework. Bodies are encoded snake case; replies are decoded snake case with ISO-8601 dates by one shared decoder. Two calls wait 15 seconds because the daemon's live Accessibility check can stall about ten seconds.

## Behavioral Requirements

- **service-protocol**: `WorkTrackingService` MUST be `Sendable` and declare `setPreferences(_:)` and `status()` and `recheckPermissions()` (each `async`, each returning `WorkTrackingStatus?`) and `spans(since:limit:)` (`async`, returning `[ActivitySpanDTO]?`).
- **transport-protocol**: `WorkTrackingXPCTransport` MUST be `Sendable` and declare `callData(timeout:retries:_:)` returning `Data` and `callDecodingArray(_:timeout:retries:_:)` returning `[T]`, both `async throws`, where `timeout` is a double optional (`TimeInterval??`). The client passes `.none` (written `nil`) for `status()` and `spans(since:limit:)` and a concrete number of seconds for the other two calls; it never passes `.some(nil)`. The transport contract MUST define what `.none` means (the source leaves it to the transport) and what `.some(nil)` means if it accepts it.
- **client-generic**: `WorkTrackingXPCClient` MUST be generic over a `WorkTrackingXPCTransport`, MUST hold it as the public `transport`, and MUST depend on no daemon framework.
- **reply-decoder**: `makeReplyDecoder()` MUST return a `JSONDecoder` with `convertFromSnakeCase` keys and `iso8601` dates, and the client MUST use it for every reply.
- **status-call**: `status()` MUST invoke `workTrackingStatus` with `timeout: nil` and `retries: 0` and return the decoded `WorkTrackingStatus`.
- **status-empty-nil**: A status reply of empty `Data` MUST yield nil.
- **status-unreadable-nil**: A status reply that does not decode as `WorkTrackingStatus` MUST yield nil.
- **status-throw-nil**: A transport that throws MUST yield nil from `status()`, `recheckPermissions()` and `setPreferences(_:)`.
- **recheck-call**: `recheckPermissions()` MUST invoke `workTrackingRecheckPermissions` with `timeout` of `recheckTimeout` and `retries: 0`.
- **recheck-timeout**: `recheckTimeout` MUST be 15 seconds, longer than the roughly ten-second stall of a missing Accessibility grant, so the daemon's "denied" is not dropped and shown as "Unknown".
- **set-preferences-body**: `setPreferences(_:)` MUST encode the preferences with `convertToSnakeCase` keys and send them through `workTrackingSetPreferences`.
- **set-preferences-timeout**: `setPreferences(_:)` MUST wait `setPreferencesTimeout`, which MUST equal `recheckTimeout` (15 seconds), because a turn-on is answered only after the daemon's live Accessibility check; a shorter wait would time out on a change the daemon applied.
- **set-preferences-no-retry**: `setPreferences(_:)` MUST pass `retries: 0`.
- **set-preferences-encode-failure**: If the preferences cannot be encoded, `setPreferences(_:)` MUST return nil without calling the transport.
- **set-preferences-reply**: `setPreferences(_:)` MUST return the status the daemon replies, decoded as in `status()`, with nil for empty or unreadable data.
- **spans-call**: `spans(since:limit:)` MUST invoke `workTrackingSpans(since:limit:)` with the caller's arguments, `timeout: nil` and `retries: 0`, decoding each element as `WorkTrackingListRow` of `ActivitySpanDTO`.
- **spans-order**: `spans(since:limit:)` MUST return spans in the order sent, which the protocol declares newest first; it MUST NOT re-sort.
- **spans-failure-nil**: If any element is the read-failed row (the object with `work_tracking_read_failed` true), `spans` MUST return nil, never an empty or partial list.
- **spans-throw-nil**: A transport throw, or an element that decodes as neither a span nor the failure row, MUST yield nil.
- **spans-empty**: An empty reply array MUST return an empty array, meaning no activity.
- **list-row-sentinel**: `WorkTrackingListRow` MUST decode to `readFailed` when the element has a boolean `workTrackingReadFailed` key (the snake-case sentinel arriving camel-cased) equal to true, and to `value` by decoding the element as the row type otherwise.
- **no-retries**: Every call MUST pass `retries: 0`; the client never retries.
- **stateless**: The client MUST hold no state beyond the transport and MUST NOT cache replies.
- **no-failure-reason**: The client MUST NOT report why a call failed; unreachable, refused and unreadable all answer nil.

## Appearance

Not applicable — this is a non-visual service client, not a visual component.

## States

Not applicable — this is a non-visual service client, not a visual component.

## Accessibility

Not applicable — this is a non-visual service client, not a visual component. The macOS Accessibility permission appears only as the subject of `recheckPermissions()` and a field of the decoded status.

## Conformance Test Vectors

Vectors 001 through 010 are backed by `WorkTrackingXPCClientTests`, which drives the client through a scripted transport. Vectors 011 through 014, 016 and 017 are backed by `WorkTrackingXPCClientConformanceTests`. Vector 015 is spec-only: `WorkTrackingPreferences` cannot fail to encode, so no test can reach it.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| work-tracking-xpc-client-001 | status-call, reply-decoder | Reply literal with `enabled` true, `accessibility` granted, `write_failures` 2, `last_error` "x" and a `current_span` (test `testStatusDecodesSnakeCase`) | status with `enabled` true, `.granted`, `writeFailures` 2, `lastError` "x", `currentSpan.bundleId` "com.x" |
| work-tracking-xpc-client-002 | status-empty-nil | Reply empty `Data` (test `testEmptyReplyIsNil`) | `status()` and `recheckPermissions()` return nil |
| work-tracking-xpc-client-003 | status-unreadable-nil | Reply `not json` (same test) | `status()` returns nil |
| work-tracking-xpc-client-004 | set-preferences-body, set-preferences-no-retry | `setPreferences` with added `["com.a"]`, removed `["com.b"]`, 30 days (test `testSetPreferencesSendsSnakeCaseBody`) | body text contains `added_bundle_ids`; body decodes to the same preferences; `retries` is 0 |
| work-tracking-xpc-client-005 | set-preferences-reply | Reply is an encoded status with `enabled` true (test `testSetPreferencesSendsSnakeCaseBody`) | returned status has `enabled` true |
| work-tracking-xpc-client-006 | set-preferences-timeout | Any `setPreferences` (test `testSetPreferencesWaitsLongerThanTheAccessibilityStall`) | timeout is greater than 10 s and `retries` is 0 |
| work-tracking-xpc-client-007 | recheck-call, recheck-timeout | `recheckPermissions` (test `testRecheckWaitsLongerThanTheAccessibilityStall`) | timeout is greater than 10 s (15 s) and `retries` is 0 |
| work-tracking-xpc-client-008 | spans-order | Two rows, ids `b` then `a` (test `testSpansDecodeNewestFirstAsSent`) | `spans` ids are `["b","a"]` with `bundleId` "com.x" and `startedAt` as sent |
| work-tracking-xpc-client-009 | spans-failure-nil | Rows are `[readFailedRow]` (test `testAFailedSpansReadIsNilNotEmpty`) | `spans` returns nil |
| work-tracking-xpc-client-010 | spans-empty | Rows are `[]` (same test) | `spans` returns an empty array |
| work-tracking-xpc-client-011 | status-call | `status()` (spec-only) | the call carries `timeout` nil and `retries` 0 |
| work-tracking-xpc-client-012 | spans-failure-nil | Two good rows and the failure row last (spec-only) | `spans` returns nil, not two spans |
| work-tracking-xpc-client-013 | status-throw-nil | Transport throws (spec-only) | `status()` returns nil |
| work-tracking-xpc-client-014 | list-row-sentinel | (spec-only) Element `{"work_tracking_read_failed":false}` decoded as `WorkTrackingListRow` of a span | falls through to decoding a span, and throws because the span keys are missing |
| work-tracking-xpc-client-015 | set-preferences-encode-failure | Preferences that cannot be encoded (spec-only) | `setPreferences` returns nil and the transport receives no call |
| work-tracking-xpc-client-016 | spans-throw-nil | Rows contain an element that is neither a span nor the failure row, such as `{"x":1}` (spec-only) | `spans` returns nil |
| work-tracking-xpc-client-017 | status-throw-nil | Transport throws during `setPreferences` and during `recheckPermissions` (spec-only) | each returns nil |
## Edge Cases

- **Empty reply**: Empty `Data` MUST be nil, because the daemon's "failed" and "did not apply" are empty data.
- **Garbage reply**: A body that is not a status MUST be nil, never a partial status.
- **Failed list read**: The failure row MUST make the whole read nil; a failed read is never "none".
- **Empty list**: An empty array MUST be an empty array, which the caller reads as no activity.
- **Slow Accessibility check**: A recheck, and a turn-on, MUST wait 15 seconds; a daemon that answers later makes both nil even though the daemon applied the change.
- **Timeouts on status and spans**: Both pass `timeout: nil`; the client passes `.none` and sets no wait of its own, so how long it waits is whatever the transport does for `.none`, which is outside this source and may be unbounded.
- **Body cannot be encoded**: `setPreferences` MUST return nil before any call is made.
- **Unreachable daemon**: The transport throws, the client returns nil, and the caller cannot tell it from a refusal or a bad reply.
- **Lost reply after a write**: A `setPreferences` that times out may still have been applied by the daemon; with no retry, the caller sees nil and may re-read `status()`.
- **Concurrent calls**: The client is a `final class` with only a `let` transport and no mutable state, so calls do not interfere; ordering of overlapping calls is the transport's and the daemon's.
- **Cancellation**: The calls are `async`, but the client adds no handling; whether a cancelled task abandons the XPC call is the transport's.
- **Offline**: Not applicable — XPC is local to the machine; an absent daemon is the unreachable case.

## Configuration

| Option | Type | Value | Description |
|--------|------|-------|-------------|
| `transport` | `WorkTrackingXPCTransport` | required, injected through `init` | Answers `callData` and `callDecodingArray`. |
| `recheckTimeout` | `TimeInterval` | constant 15 (static, not injectable) | Wait for a recheck. |
| `setPreferencesTimeout` | `TimeInterval` | constant, equal to `recheckTimeout` (static, not injectable) | Wait for a preferences push. |
| status and spans timeout | `TimeInterval??` | constant `.none` | Passed through to the transport. |
| retries | `Int` | constant 0 | Passed on every call. |

No environment variables or settings keys.

## Deep Linking

Not applicable: this code defines no URL or deep link.

## Localization

Not applicable: this code produces no user-facing strings; every failure is nil. The status's `degradedNotice` string belongs to `WorkTrackingStatus`, not to the client.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: The calls carry the tracked-app preferences and activity spans (app, window title, working path, repository, branch).
- **Storage**: None; the client holds no state and does not cache.
- **Transmission**: To a daemon on the same machine over XPC; no networking in this code.
- **Retention**: None here.

## Logging

Not applicable: this code makes no log calls; failures are returned as nil rather than logged.

## Platform Notes

- **SwiftUI**: The client is Foundation-only, so there is no SwiftUI surface in it. A SwiftUI view model holds a `WorkTrackingService` and awaits it in a `Task`, turning nil into "Unknown" or a retry affordance. The class is generic, so a leaf adds a retroactive conformance of its DaemonKit client to `WorkTrackingXPCTransport`.
- **Compose**: A repository class with suspend functions returning nullable values over a bound service; use `withTimeoutOrNull(15_000)` for the recheck and preferences push, `Json { namingStrategy = JsonNamingStrategy.SnakeCase }` (kotlinx.serialization) for bodies and replies, and a sealed row type for the sentinel.
- **React/Web**: A client over `fetch` with `AbortSignal.timeout(15000)` on the two long calls; each function returns `Promise<T | null>`, mapping non-OK, thrown and unparseable results to null, and the spans function returns null when any row has `work_tracking_read_failed === true`. Convert keys at the boundary or keep the wire type snake case.
- **AppKit / UIKit**: The source file is `WorkTrackingXPCClient.swift` under `Core/WorkTracking`, a Swift type used on macOS; iOS has no general XPC to a daemon, so the transport differs. The daemon connection is the leaf's `XPCClient` from DaemonKit conformed to `WorkTrackingXPCTransport`.
- **WinUI 3**: A class over an injected `IWorkTrackingTransport` using `HttpClient`, a named pipe (`NamedPipeClientStream`) or gRPC. Methods return `Task<WorkTrackingStatus?>` and `Task<IReadOnlyList<ActivitySpan>?>`; wrap each in try/catch returning null, since the Swift version uses `try?`. Use `CancellationTokenSource(TimeSpan.FromSeconds(15))` for the recheck and push, and `System.Text.Json` with `JsonNamingPolicy.SnakeCaseLower` and ISO-8601 `DateTimeOffset`. Model the span row as a `JsonConverter` that reads the sentinel property first. XAML code-behind or a view model awaits on the UI thread through `DispatcherQueue`. A DaemonKit XPC client does not exist on Windows, so the transport is a new component.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/WorkTracking/WorkTrackingXPCClient.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Every failure collapses into nil.
**Rationale**: The service doc comment says reads and writes answer nil when the daemon was unreachable, refused, or its reply couldn't be read; the caller needs only "could not do it", and distinguishing causes would need an error type on every call. The cost is a caller that cannot say why.
**Approved**: pending

**Decision**: A failed spans read is nil, not an empty array.
**Rationale**: The comment on `spans` says "a failed read is never 'none'" in the source; a nil reads as unknown while an empty array reads as nothing happened.
**Approved**: pending

**Decision**: Recheck and preferences push each wait 15 seconds.
**Rationale**: The comments explain the daemon answers only after a live Accessibility check that stalls about ten seconds on `tccd` without the grant. A shorter wait drops the "denied" about to arrive (review F24) or counts a failure on a change the daemon applied.
**Approved**: pending

**Decision**: No retries on any call.
**Rationale**: Every call passes `retries: 0`, and the source states no reason for it, so the reason is an open question for the maintainer (the approval stays pending until it is answered). The effect is that a timed-out preferences push is not repeated by the client, so the caller sees nil and decides whether to read `status()` or push again.
**Approved**: pending

**Decision**: The client is generic over a small transport protocol.
**Rationale**: The comment says the protocol has "the shape DaemonKit's XPCClient already has", so the SDK tier links no daemon framework and tests use a scripted transport.
**Approved**: pending

**Decision**: One decoder reads all replies, and the failure sentinel arrives camel-cased.
**Rationale**: `makeReplyDecoder()` is "the one JSON reading of a work-tracking reply"; because it converts from snake case, the sentinel key `work_tracking_read_failed` is read as `workTrackingReadFailed`.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | partial | reliability |

Separation of concerns passes: the client only translates the service interface to transport calls and wire coding; rules are the daemon's and the transport is injected. Unit coverage is partial: vectors 001 through 014, 016 and 017 are tested, by `WorkTrackingXPCClientTests` and `WorkTrackingXPCClientConformanceTests` (`WorkTracking/WorkTrackingXPCClientConformanceTests.swift`). Vector 015 is skipped: `WorkTrackingPreferences` holds only a Bool, a `[String]` and an Int, so no value of it can fail to encode. Timeout handling is partial: the two calls whose daemon answer is known to stall carry an explicit 15-second wait with the reason documented, but `status()` and `spans(since:limit:)` pass `.none` and leave the wait to the transport, which may be unbounded. Retry with backoff is not checked: the client never retries by design (`retries: 0`), see the no-retry design decision.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (WorkTrackingXPCClientConformanceTests.swift, 6 of 7 new vectors, 16 of 17 total); unit-test-coverage now partial (015 skipped: preferences cannot fail to encode). |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Removed the untraceable review tags, defined the nil timeout, marked vectors 011-017 spec-only and added three vectors, changed timeout handling to partial, dropped the retry row, clarified fixed constants and added dependencies. |
