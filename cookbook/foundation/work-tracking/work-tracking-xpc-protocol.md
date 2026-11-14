---
id: 02cfb457-46da-4814-a1de-8962533ad78e
title: "Work Tracking XPC Protocol"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The Objective-C protocol a daemon exports for work tracking: four selectors, JSON-data payloads, and empty-data and sentinel-row failure replies."
platforms:
  - swift
  - macos
tags:
  - work-tracking
  - foundation
  - xpc
  - wire
depends-on: []
related:
  - 36c76e0f-b41c-4fd6-a349-a0e9241fb489
  - 8055f7c9-d336-4b71-9f95-1bf4bdef7b92
references: []
approved-by: ""
approved-date: ""
---

# Work Tracking XPC Protocol

## Overview

`WorkTrackingXPCProtocol` is the work-tracking half of a daemon's XPC surface, declared `@objc public` as its own protocol "so any app can talk to it without linking the daemon's whole protocol". Per its doc comment, "every body and reply is JSON in the daemon's snake-case style". It has four selectors: set the preferences, read the status, re-check Accessibility, and read activity spans. Failure is carried in the data, not in an error: empty `Data` for the three status calls, and a one-element sentinel row for the spans list. The daemon implements the protocol; this repo declares it and the client side (`WorkTrackingXPCClient`) calls it. The billing counterpart has the same shape (see the Billing XPC Protocol recipe).

## Behavioral Requirements

- **objc-protocol**: The protocol MUST be an Objective-C protocol (`@objc`), because XPC dispatches by selector.
- **selectors-stable**: The four selectors MUST keep their names and argument labels, because the two sides agree by selector: `workTrackingSetPreferences(_:reply:)`, `workTrackingStatus(reply:)`, `workTrackingRecheckPermissions(reply:)` and `workTrackingSpans(since:limit:reply:)`.
- **json-snake-case**: Every body and every reply MUST be JSON in snake-case keys, per the protocol comment; ISO-8601 dates are the client decoder's reading.
- **set-preferences-body**: The body of `workTrackingSetPreferences` MUST be an encoded `WorkTrackingPreferences`.
- **set-preferences-reply**: `workTrackingSetPreferences` MUST reply the encoded `WorkTrackingStatus` after applying, and MUST reply empty `Data` when it did not apply.
- **status-reply**: `workTrackingStatus` MUST reply an encoded `WorkTrackingStatus`, and MUST reply empty `Data` on failure.
- **recheck-reply**: `workTrackingRecheckPermissions` MUST re-check Accessibility and reply the new status.
- **recheck-explicit**: The recheck MUST be "the one explicit, user-driven check" of Accessibility, per the doc comment. The protocol comment names no other selector as a user-driven check, although a set-preferences that turns tracking on is also answered after a live Accessibility check (see Edge Cases).
- **spans-reply**: `workTrackingSpans` MUST reply an array of `Data`, each element one encoded `ActivitySpanDTO`, newest first.
- **spans-since**: A nil `since` MUST mean any start; a non-nil `since` is a string whose format the source does not state.
- **spans-limit**: `limit` MUST be passed through as the caller's `Int`; the protocol states no bound on it.
- **spans-failure-row**: A spans read that failed MUST reply the one element `WorkTrackingWire.readFailedRow`, which is `{"work_tracking_read_failed":true}`, so a failure never reads as "no activity".
- **spans-empty-is-none**: A successful read with no spans MUST reply an empty array, which means no activity.
- **reply-once-async**: Each selector MUST deliver its answer through its `reply` closure, which is `@escaping`, so the daemon may call it after the selector returns.
- **no-error-channel**: The protocol MUST NOT carry a Swift `Error` or a reason string; the caller learns of failure only from empty data or the sentinel row, and not why.

## Appearance

Not applicable — this is a wire protocol declaration, not a visual component.

## States

Not applicable — this is a wire protocol declaration, not a visual component.

## Accessibility

Not applicable — this is a wire protocol declaration, not a visual component. The macOS Accessibility permission appears only as the subject of the recheck selector and as a field of `WorkTrackingStatus`.

## Conformance Test Vectors

Derived from the protocol's doc comments and from `WorkTrackingXPCClientTests`, whose `RecordingProxy` conforms to the protocol and captures the set-preferences body, and whose literals show the reply shapes.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| work-tracking-xpc-protocol-001 | set-preferences-body, json-snake-case | Client sends `workTrackingSetPreferences` for added ids `["com.a"]` (test `testSetPreferencesSendsSnakeCaseBody`) | the body contains `added_bundle_ids` and decodes to the same preferences |
| work-tracking-xpc-protocol-002 | set-preferences-reply | Daemon applied the change | reply is an encoded `WorkTrackingStatus` with `enabled` true |
| work-tracking-xpc-protocol-003 | set-preferences-reply | Daemon did not apply | reply is empty `Data` |
| work-tracking-xpc-protocol-004 | status-reply | Daemon failed to build the status | reply is empty `Data` |
| work-tracking-xpc-protocol-005 | status-reply, json-snake-case | Reply literal with `write_failures`, `last_error` and `current_span` (test `testStatusDecodesSnakeCase`) | decodes to a `WorkTrackingStatus` with those fields |
| work-tracking-xpc-protocol-006 | recheck-reply | User asks Check Again | reply is the new encoded status |
| work-tracking-xpc-protocol-007 | spans-reply | Two spans stored | two elements, the later `started_at` first (test `testSpansDecodeNewestFirstAsSent`) |
| work-tracking-xpc-protocol-008 | spans-failure-row | Spans read fails | one element equal to `WorkTrackingWire.readFailedRow` (test `testAFailedSpansReadIsNilNotEmpty`) |
| work-tracking-xpc-protocol-009 | spans-empty-is-none | No spans match | empty array (same test) |
| work-tracking-xpc-protocol-010 | spans-since | `since` nil | spans from any start are included |
| work-tracking-xpc-protocol-011 | spans-failure-row | Inspect `WorkTrackingWire.readFailedRow` | the bytes are `{"work_tracking_read_failed":true}` and `readFailedKey` is `work_tracking_read_failed` |

## Edge Cases

- **Empty reply data**: For the three status calls, empty `Data` MUST mean the call failed or did not apply; a zero-byte body is never a valid status.
- **Undecodable reply**: A body that is not a valid status is not distinguished by the protocol; the client treats it like empty data.
- **Sentinel among rows**: The failure row is declared as the single element of a failed read; a client seeing it anywhere in the array treats the read as failed (client recipe).
- **Empty list**: An empty array MUST mean no activity, never a failure.
- **Slow recheck and slow turn-on**: A recheck, and a set-preferences that turns tracking on, are answered only after the daemon's live Accessibility check, which the client source says stalls about ten seconds without the grant; the protocol states no deadline, and the client owns the timeouts.
- **Daemon unreachable or interrupted**: Not expressible in the protocol; the transport call throws, and the client answers nil for it (as it does for empty data).
- **Selector drift**: Renaming a selector would make the call fail at runtime with no compile error on the daemon side, so the names are fixed.
- **Concurrent access**: The protocol declares no ordering; NSXPC delivers calls on the daemon's connection queue, and serialization is the daemon's.
- **Cancellation, offline**: Not applicable — the protocol declares no cancellation, and XPC is local to the machine.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| body (set preferences) | encoded `WorkTrackingPreferences` | required | JSON snake case. |
| `since` | `String?` | nil | Cutoff string whose format the source does not state; nil is any. |
| `limit` | `Int` | required | Passed through as the caller gives it; the protocol states no meaning or bound. |
| `readFailedKey` | `String` | `work_tracking_read_failed` | Key of the failure row. |

No environment variables or settings keys.

## Deep Linking

Not applicable: this code defines no URL or deep link.

## Localization

Not applicable: this code produces no user-facing strings; every payload is machine JSON.

## Accessibility Options

Not applicable: this code has no visual surface, so no accessibility display option applies.

## Feature Flags

Not applicable: this code reads no feature flag.

## Analytics

Not applicable: this code emits no analytics events.

## Privacy

- **Data collected**: The payloads carry the tracked-app preferences and the activity spans (app, window title, working path, repository, branch), the latter through `ActivitySpanDTO`.
- **Storage**: None here; the daemon owns persistence.
- **Transmission**: Between an app and a daemon on the same machine through XPC; this code does no networking.
- **Retention**: Not set by the protocol; retention days travel in the preferences body.

## Logging

Not applicable: this code makes no log calls; it declares no calls at all, only selectors.

## Platform Notes

- **SwiftUI**: Source platform, but there is no view here. The file is `WorkTrackingXPCProtocol.swift` under `Core/WorkTracking`. The protocol is `@objc public`, so every parameter and reply type must be Objective-C representable (`Data`, `String?`, `Int`, `[Data]`).
- **Compose**: Express the four calls as a Kotlin interface of suspend functions returning `ByteArray?` and `List<ByteArray>` over a bound service (AIDL) or a local socket; keep the same snake-case JSON and the empty-bytes and sentinel-row failure conventions.
- **React/Web**: Four `fetch` routes or WebSocket messages exchanging JSON; the spans route returns an array of objects with the sentinel object `{"work_tracking_read_failed": true}` as the only element on failure. Use a TypeScript type guard for the sentinel.
- **AppKit / UIKit**: NSXPC is macOS and the iOS-limited app-extension case; build an `NSXPCInterface(with: WorkTrackingXPCProtocol.self)` on the client and export an object conforming to it in the daemon. A daemon composes it with its own protocol by refining both.
- **WinUI 3**: No XPC on Windows. Declare a C# interface with `Task<byte[]>` for the three status calls (empty array for failure) and `Task<IReadOnlyList<byte[]>>` for spans, hosted over a named pipe (`NamedPipeServerStream`, `System.IO.Pipes`), gRPC, or a WinRT out-of-process component. Serialize with `System.Text.Json` and `JsonNamingPolicy.SnakeCaseLower`; the ISO-8601 dates are `DateTimeOffset` round-trip strings. The reply closure becomes the awaited task result, which also gives a natural place to surface a transport exception that XPC's protocol cannot express.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/WorkTracking/WorkTrackingXPCProtocol.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Work tracking is its own protocol, separate from the daemon's main protocol.
**Rationale**: The doc comment gives the reason: any app can talk to work tracking without linking the daemon's whole protocol.
**Approved**: pending

**Decision**: Payloads are JSON data rather than typed Objective-C objects.
**Rationale**: The protocol comment says every body and reply is JSON in the daemon's snake-case style; the models file says the failure-row convention is the same as `BillingWire.readFailedRow`.
**Approved**: pending

**Decision**: Failure is empty data for status calls and a sentinel row for the spans list.
**Rationale**: The comments say empty `Data` on failure, and a failed read replies `readFailedRow` "so a failure never reads as 'no activity'". An empty array has to stay a true answer, so a failed list needs its own marker (review F25).
**Approved**: pending

**Decision**: The recheck selector is the one explicit, user-driven Accessibility check.
**Rationale**: The comment calls it "the one explicit, user-driven check"; the client source notes the live check stalls on `tccd` for about ten seconds without the grant, which is why the client gives it a 15 second wait.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.access-patterns.error-response-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/064273f4-c09b-56ec-b1d2-a9ad1015b5ef) | partial | access-patterns |

Separation of concerns passes: the file declares selectors and nothing else, with the value types and the sentinel in `WorkTrackingModels.swift` and the calling logic in the client. Unit coverage is partial: `WorkTrackingXPCClientTests` conforms a recording proxy to the protocol and exercises the set-preferences body, status and span replies and the failure row, but there is no daemon-side test in this repo, so the empty-data replies of the daemon are not asserted here. Error response handling is partial: failure is signaled, but without a reason, so the caller cannot tell an unreachable daemon from a refusal or an unreadable reply.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
