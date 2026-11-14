---
id: 6edbc7b8-b533-4cca-b62d-74b92ce3f650
title: "Hub Sync Transport"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-13
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The SyncTransport that carries the sync engine's pull and push to the ADH hub through ADHSyncAPI: JSON wire coding and a fixed error mapping to SyncTransportError."
platforms:
  - swift
  - macos
  - ios
tags:
  - sync
  - transport
  - hub
depends-on:
  - 355a8f54-aee5-45cd-a28d-12c3b7a3085c
related:
  - 14ca2162-b5ec-48bb-95a0-90577e7c9810
  - d3a0b65f-92c0-43c1-b04c-77638eb72044
references: []
approved-by: ""
approved-date: ""
---

# Hub Sync Transport

## Overview

`ADHSyncTransport` is the `SyncTransport` a hub app hands to the sync engine ([adhsdk.ingredient.data.sync.sync-engine](cookbook:355a8f54-aee5-45cd-a28d-12c3b7a3085c)) so the engine pulls from and pushes to the ADH hub. It wraps `ADHSyncAPI` from the hub client, which owns the HTTP: the `GET sync/pull` and `POST sync/push` routes, the bearer token and the status codes. The transport adds the two things the API leaves out: it turns the raw bytes into the engine's wire types (`SyncPullResponse`, `SyncPushRequest`, `SyncPushResponse`) and it turns the API's `Failure` into `SyncTransportError`, the only error vocabulary the engine reacts to.

It lives in its own framework, `AgenticDeveloperHubSDKHubSync`, so a hub app links it beside the engine without the engine itself ever depending on the hub client. Any app that mirrors hub tables uses it; Temporal's hub mail is the first.

## Behavioral Requirements

- **wraps-api**: `init(api:)` MUST route `pull` to `ADHSyncAPI.pull(cursor:limit:)` and `push` to `ADHSyncAPI.push(body:)`, and hold no other state.
- **cursor-raw-value**: `pull` MUST pass the cursor's `rawValue`, or nil when the engine has no cursor, and the engine's limit unchanged.
- **decode-pull**: `pull` MUST decode the response body as `SyncPullResponse` with a default `JSONDecoder` (camelCase keys, as the hub sends them). The wire types carry no `Date` fields, so the default date strategy is never exercised.
- **encode-push**: `push` MUST encode the request with a default `JSONEncoder` and decode the body as `SyncPushResponse`.
- **map-unauthorized**: `ADHSyncAPI.Failure.unauthorized` MUST become `SyncTransportError.unauthorized`.
- **map-resync**: `.resyncRequired` MUST become `.resyncRequired`.
- **map-http**: `.http(code)` MUST become `.invalidResponse(statusCode: code)`.
- **map-transport**: `.transport(message)` MUST become `.transport(message)`.
- **map-coding**: A decode or encode failure MUST become `.transport` carrying the error's description.
- **map-unknown**: Any other error that is not a `CancellationError`, an `ADHSyncAPI.Failure` or already a `SyncTransportError` MUST become `.transport` carrying the error's description; an error that is already a `SyncTransportError` MUST pass through unchanged.
- **cancellation-passes**: A `CancellationError` MUST be rethrown unchanged, so a stopped engine is not counted as a failed cycle. Cancellation is checked before the catch-all and before the `ADHSyncAPI.Failure` mapping, so it always wins. `URLError.cancelled` is not a `CancellationError`: it is mapped like any other error (to `.transport` unless the API layer has already turned it into `ADHSyncAPI.Failure`).
- **injectable-calls**: An internal initializer MUST accept the two calls as closures, so tests drive the transport without a network.

## Appearance

Not applicable: the transport draws nothing.

- **Corner radius**: Not applicable: no visual element.
- **Padding**: Not applicable: no visual element.
- **Font**: Not applicable: no visual element.
- **Background**: Not applicable: no visual element.
- **Foreground/Text**: Not applicable: no visual element.
- **Border**: Not applicable: no visual element.
- **Shadow**: Not applicable: no visual element.
- **Min/Max size**: Not applicable: no visual element.

## States

| State | Appearance change |
|-------|------------------|
| Default | Not applicable: the transport is a stateless value; every call stands alone. |

## Accessibility

Not applicable: the transport is not a visual or interactive element.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hub-sync-transport-001 | cursor-raw-value, decode-pull | `pull(cursor: SyncCursor(rawValue: "c9"), limit: 50)`; the call returns a JSON pull body with one change | The call saw `("c9", 50)`; the result has that change and its cursor |
| hub-sync-transport-002 | cursor-raw-value | `pull(cursor: nil, limit: 10)` | The call saw `(nil, 10)` |
| hub-sync-transport-003 | encode-push | `push` of a request with one op | The call's body decodes back to the same `SyncPushRequest`; the result decodes from the returned body |
| hub-sync-transport-004 | map-unauthorized | The call throws `.unauthorized` | `SyncTransportError.unauthorized` |
| hub-sync-transport-005 | map-resync | The call throws `.resyncRequired` | `.resyncRequired` |
| hub-sync-transport-006 | map-http | The call throws `.http(503)` | `.invalidResponse(statusCode: 503)` |
| hub-sync-transport-007 | map-transport | The call throws `.transport("offline")` | `.transport("offline")` |
| hub-sync-transport-008 | map-coding, decode-pull | The call returns `not json` | `.transport(message)` where `message` is non-empty and contains the decoding error's description |
| hub-sync-transport-009 | cancellation-passes | The call throws `CancellationError()` | `CancellationError` |
| hub-sync-transport-010 | wraps-api | One `pull` and one `push`, each with its own recording call | `pull` invokes only the pull call and `push` only the push call; no other state is held |
| hub-sync-transport-011 | injectable-calls | Construct the transport from two closures with the internal initializer and call `pull` | The closure is invoked and the transport needs no network |
| hub-sync-transport-012 | map-coding, encode-push | The push call returns `not json` | `.transport(message)` where `message` is non-empty and contains the decoding error's description |
| hub-sync-transport-013 | map-unknown | The call throws an error that is not a `CancellationError`, an `ADHSyncAPI.Failure` or a `SyncTransportError` (for example `URLError(.cancelled)`) | `.transport(message)` where `message` is the error's description |
| hub-sync-transport-014 | cancellation-passes | The push call throws `CancellationError()` | `CancellationError`, unchanged |
## Edge Cases

- A 2xx body that is not a pull response (an HTML error page from a proxy) is a `.transport` error, so the engine backs off and retries rather than treating it as a resync.
- A persistent decode failure, such as version skew between client and hub, is mapped to `.transport` with the decoding error's description on every cycle. The transport does not escalate repeated failures; the description is kept so a failure event can show it, and any retry limit belongs to the engine.
- The hub's 410 is the only path to `.resyncRequired`; the transport never infers a resync from a body.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| api | `ADHSyncAPI` | required | The hub client's sync API, which holds the base URL, credentials and session. |

## Deep Linking

Not applicable: the transport handles no URL.

## Localization

Not applicable: the transport shows no text; error messages are diagnostics.

## Accessibility Options

Not applicable: no visual element.

## Feature Flags

Not applicable: the source reads no flag.

## Analytics

Not applicable: the source records no event.

## Privacy

- **Data collected**: None of its own. It carries whatever rows the engine pulls and pushes.
- **Storage**: None; nothing outlives a call.
- **Transmission**: Only to the hub, through `ADHSyncAPI`, which sends the signed-in user's bearer token.
- **Retention**: Not applicable.

## Logging

Not applicable: the transport logs nothing; the engine reports failures as `SyncEvent.failed`.

## Platform Notes

- **SwiftUI**: Same type as AppKit / UIKit below; nothing in it is SwiftUI-specific.
- **Compose**: Implement the engine's transport interface over the API layer's client (Ktor or OkHttp) with `kotlinx.serialization`, and map the API layer's failure type, not raw HTTP status codes: unauthorized to `unauthorized`, resync-required to `resyncRequired`, http(code) to `invalidResponse(code)`, transport(message) to `transport(message)`, and any coding or other error to `transport` with its description. Rethrow `CancellationException` unchanged, as coroutines require.
- **React/Web**: Not needed: the web app reads through the hub API and keeps no local mirror, so it has no sync engine to feed.
- **AppKit / UIKit**: Source: `packages/apple/AgenticDeveloperHubSDK/HubSync/ADHSyncTransport.swift`, a `Sendable` struct conforming to `SyncTransport`, built for both macOS and iOS. It is UI-agnostic Swift.
- **WinUI 3**: Implement the transport interface over the API layer's client (`HttpClient`) with `System.Text.Json`, mapping the API layer's failure type with the same five mappings as Compose (the four named failures plus coding or other errors to `transport`) and letting `OperationCanceledException` through.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/HubSync/` | confirmed (1.0.1) |

## Design Decisions

**Decision**: The transport is a separate framework from the engine and from the hub client.
**Rationale**: The engine stays free of the hub client so a daemon or test can link it alone, and the hub client stays free of the engine. The transport is the one place the two meet.
**Approved**: pending

**Decision**: Coding failures map to `.transport`, not `.invalidResponse`.
**Rationale**: `.invalidResponse` carries a status code, and a body that fails to decode came with a 2xx. Treating it as a transport error makes the engine back off and retry, which is right for a transient proxy page.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |

Vectors 001-009 each have a named test in `packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKHubMailTests/ADHSyncTransportTests.swift` (the HubMail test bundle links the HubSync framework); vectors 010-014 have no test yet, so unit-test-coverage is partial. Every error is mapped explicitly.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Split map-unknown from map-coding, stated cancellation precedence and the no-Date wire types, added a persistent-decode-failure edge case, tightened vector 008, added five vectors, fixed the Overview link label, Compose and WinUI mappings, source location and Compliance category and test path. |
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation |
