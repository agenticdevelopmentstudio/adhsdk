---
id: 7fd507a8-73a6-48f0-83c8-36789f3c9be4
title: "Daemon Health Report"
type: ingredient
version: 1.0.3
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A Foundation-only client mirror of a daemon's GET /health body, with a decoder, a strategy-tree search and an HTTP probe that yields the raw body or nil."
platforms:
  - swift
  - macos
tags:
  - foundation
  - daemon
  - health
  - networking
depends-on: []
related:
  - 9c7c78d3-23ca-4ca6-a519-9968b440b8c6
references: []
approved-by: ""
approved-date: ""
---

# Daemon Health Report

## Overview

A client-side mirror of the `GET /health` wire format that every DaemonKit daemon serves (`DaemonHealthRouter`). It is kept in a Foundation-only file so a menu bar app, or any other client, can read a daemon's health without linking DaemonKit. The JSON keys are the contract. The Swift type names (`DaemonHealthReport`, `DaemonStrategyReport`, `DaemonWorkUnitReport`) are deliberately distinct from DaemonKit's `HealthStatus`, `StrategySnapshot` and `WorkUnitSnapshot`, so a file that imports both never meets an ambiguity. The file holds four things: the report value types, a lenient decoder, a depth-first search of the strategy tree, and `DaemonHealthProbe`, which builds the async closure a menu bar app polls.

## Behavioral Requirements

**Report shape**

- **report-fields**: `DaemonHealthReport` MUST carry `status` (String), `version` (String), `uptimeSeconds` (TimeInterval) and `strategy` (a `DaemonStrategyReport`), and MUST be `Codable`, `Sendable` and `Equatable`.
- **status-opaque**: `DaemonHealthReport.status` MUST be a free String that the report does not interpret; it MUST NOT be an enum.
- **strategy-fields**: `DaemonStrategyReport` MUST carry `name` (String), `kind` (String), `workUnits` (an array of `DaemonWorkUnitReport`) and `children` (an array of `DaemonStrategyReport`).
- **kind-constants**: `DaemonStrategyReport` MUST expose the static constants `timingKind` equal to `"timing"`, `eventKind` equal to `"event"` and `compositeKind` equal to `"composite"`, which are the kinds DaemonKit's `TimingStrategy`, `EventStrategy` and `CompositeStrategy` report.
- **kind-open**: `DaemonStrategyReport.kind` MUST accept any String value, because a daemon may report its own kind; a consumer SHOULD treat an unknown kind as opaque.
- **children-recursive**: `DaemonStrategyReport.children` MUST hold the child strategies of a composite and MUST be empty for a leaf strategy.
- **workunit-fields**: `DaemonWorkUnitReport` MUST carry `name` (String), `state` (a `State`), `nextActivation` (optional Date), `consecutiveFailures` (Int), `isBlocklisted` (Bool) and `lastMessage` (optional String). `nextActivation` and `lastMessage` are the optional fields: one that does not apply to a work unit MUST be `nil`.
- **workunit-state-values**: `DaemonWorkUnitReport.State` MUST be a String-backed enum with exactly the raw values `idle`, `running`, `disabled` and `blocklisted`.
- **workunit-memberwise-defaults**: The `DaemonWorkUnitReport` initializer MUST default `nextActivation` to `nil`, `consecutiveFailures` to `0`, `isBlocklisted` to `false` and `lastMessage` to `nil`.
- **strategy-memberwise-default**: The `DaemonStrategyReport` initializer MUST default `children` to an empty array.

**Decoding**

- **children-optional-on-wire**: Decoding a `DaemonStrategyReport` MUST treat a missing `children` key as an empty array, so a leaf strategy may omit it.
- **strategy-required-keys**: Decoding a `DaemonStrategyReport` MUST fail when `name`, `kind` or `workUnits` is missing.
- **workunit-required-keys**: Decoding a `DaemonWorkUnitReport` MUST fail when `name`, `state`, `consecutiveFailures` or `isBlocklisted` is missing; the initializer defaults do not apply to decoding.
- **workunit-optional-keys**: Decoding a `DaemonWorkUnitReport` MUST accept a missing or null `nextActivation` and a missing or null `lastMessage` as `nil`.
- **unknown-state-fails**: Decoding MUST fail for a work unit whose `state` is not one of the four `State` raw values, and because the enum has no fallback case, that failure fails the whole report.
- **decode-iso8601**: `DaemonHealthReport.decode(_:)` MUST decode dates with the ISO-8601 strategy, which is what DaemonKit encodes.
- **decode-nil-on-mismatch**: `DaemonHealthReport.decode(_:)` MUST return `nil` for any body it cannot decode, including a body in some other schema, because a daemon may answer `/health` in its own shape and still be up.
- **decode-no-error-detail**: `DaemonHealthReport.decode(_:)` MUST NOT surface the decoding error; the underlying failure is discarded and the caller receives only `nil`.

**Tree search**

- **first-of-kind-self**: `DaemonStrategyReport.first(ofKind:)` MUST return the receiver when the receiver's `kind` equals the argument.
- **first-of-kind-depth-first**: `DaemonStrategyReport.first(ofKind:)` MUST search `children` in order, depth first, and MUST return the first match found.
- **first-of-kind-none**: `DaemonStrategyReport.first(ofKind:)` MUST return `nil` when no strategy in the tree has the requested kind.

**Probe**

- **probe-url**: `DaemonHealthProbe.http(baseURL:timeout:)` MUST build the probe URL by appending the path component `health` to `baseURL` parsed as a URL. A trailing slash on `baseURL` MUST NOT produce a double slash, and a path on `baseURL` MUST be kept: `http://h:9000/` gives `http://h:9000/health` and `http://h/api` gives `http://h/api/health`.
- **probe-request**: Each invocation of the returned closure MUST issue one GET request that gives up when no data has been received for `timeout` seconds. The timeout is an idle timeout: a server that keeps sending bytes slowly MUST NOT trip it, and the total duration of the request is not bounded.
- **probe-default-timeout**: The `timeout` parameter MUST default to 2 seconds.
- **probe-200-only**: The returned closure MUST return the response body only when the HTTP status code is exactly 200.
- **probe-nil-on-failure**: The returned closure MUST return `nil` for any other status code, for a transport error and for an idle timeout.
- **probe-nil-on-bad-url**: The returned closure MUST return `nil`, without making a request, when `baseURL` cannot be parsed as a URL.
- **probe-non-http-response**: The returned closure MUST return `nil` when the response is not an `HTTPURLResponse`.
- **probe-body-raw**: The returned closure MUST return the body bytes undecoded; decoding is a separate call to `DaemonHealthReport.decode(_:)`.
- **probe-ephemeral-session**: The probe MUST use one ephemeral URL session, created when the probe is built and reused by every invocation of the returned closure, so that no cache, cookies or credentials persist to disk.
- **probe-sendable-async**: The returned closure MUST be `@Sendable` and `async`, so a caller may invoke it from any task.
- **probe-no-retry**: The probe MUST NOT retry; each invocation makes exactly one attempt, and the polling cadence belongs to the caller.

## Appearance

Not applicable — this is a data model and a network probe, not a visual component.

## States

Not applicable — this is a data model and a network probe, not a visual component. The only enumerated state is the wire value `DaemonWorkUnitReport.State`, specified under Behavioral Requirements.

## Accessibility

Not applicable — this is a data model and a network probe, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| daemon-health-report-001 | decode-iso8601, children-optional-on-wire, workunit-optional-keys, report-fields | Test `decodesWireFormat`: body `{"status":"ok","version":"2.1.0","uptimeSeconds":90,"strategy":{"name":"root","kind":"composite","workUnits":[],"children":[{"name":"jobs","kind":"timing","workUnits":[{"name":"sync","state":"idle","nextActivation":"2026-01-01T00:00:00Z","consecutiveFailures":2,"isBlocklisted":false}]}]}}` passed to `decode` | A non-nil report; `version` is `"2.1.0"`; `first(ofKind: "timing")` finds `jobs`, whose `children` is empty, whose first work unit has `state == .idle`, `consecutiveFailures == 2` and a non-nil `nextActivation` |
| daemon-health-report-002 | decode-nil-on-mismatch, strategy-required-keys | Test `otherSchemaIsNil`: body `{"status":"ok"}` passed to `decode` | `nil` |
| daemon-health-report-003 | decode-nil-on-mismatch, decode-no-error-detail | Bytes that are not JSON (for example `not json`) passed to `decode` | `nil`, with no error raised |
| daemon-health-report-004 | unknown-state-fails | A well-formed body whose one work unit has `"state":"paused"` | `decode` returns `nil` for the whole report |
| daemon-health-report-005 | workunit-required-keys | A well-formed body whose work unit omits `consecutiveFailures` | `decode` returns `nil` |
| daemon-health-report-006 | workunit-optional-keys | A work unit with only `name`, `state`, `consecutiveFailures` and `isBlocklisted` | Decodes; `nextActivation` and `lastMessage` are `nil` |
| daemon-health-report-007 | children-optional-on-wire | A strategy object with `name`, `kind` and `workUnits` and no `children` key | Decodes with `children == []` |
| daemon-health-report-008 | first-of-kind-self | `DaemonStrategyReport(name: "t", kind: "timing", workUnits: [])` and `first(ofKind: "timing")` | Returns the receiver |
| daemon-health-report-009 | first-of-kind-depth-first | A composite with children `a` (kind `timing`, containing a child `a1` of kind `event`) then `b` (kind `event`); `first(ofKind: "event")` | Returns `a1`, not `b` |
| daemon-health-report-010 | first-of-kind-none | A leaf strategy of kind `timing`; `first(ofKind: "composite")` | `nil` |
| daemon-health-report-011 | workunit-memberwise-defaults | `DaemonWorkUnitReport(name: "x", state: .running)` | `nextActivation == nil`, `consecutiveFailures == 0`, `isBlocklisted == false`, `lastMessage == nil` |
| daemon-health-report-012 | kind-constants | Read the three static constants | `"timing"`, `"event"` and `"composite"` |
| daemon-health-report-013 | probe-200-only, probe-body-raw | A server answering `GET /health` with status 200 and a JSON body | The closure returns the exact body bytes |
| daemon-health-report-014 | probe-nil-on-failure | A server answering `GET /health` with status 503 | The closure returns `nil` |
| daemon-health-report-015 | probe-request, probe-nil-on-failure, probe-default-timeout | A server that accepts the connection and sends no data for longer than 2 seconds | The closure returns `nil` after about 2 seconds of silence |
| daemon-health-report-016 | probe-nil-on-failure | No server listening at `baseURL` | The closure returns `nil` |
| daemon-health-report-017 | probe-nil-on-bad-url | `baseURL` set to a string `URL(string:)` rejects, such as the empty string | The closure returns `nil` and issues no request |
| daemon-health-report-018 | probe-url | `baseURL` `http://127.0.0.1:9000` | The request is a GET to `http://127.0.0.1:9000/health` |
| daemon-health-report-019 | probe-no-retry | Invoke the closure twice against a server that answers 500 | Two requests are made, one per invocation, and both return `nil` |
| daemon-health-report-020 | kind-open | Body with a strategy whose `kind` is `"custom"` | Decodes; `kind == "custom"` |
| daemon-health-report-021 | probe-request | A server that sends a valid 200 response body in small pieces, one piece every second, for longer than 2 seconds in total | The closure returns the complete body bytes; the idle timeout never fires |
| daemon-health-report-022 | probe-non-http-response | A probe over a transport whose response is not an `HTTPURLResponse` (for example a `file:` URL as `baseURL`) | The closure returns `nil` |
| daemon-health-report-023 | strategy-memberwise-default | `DaemonStrategyReport(name: "t", kind: "timing", workUnits: [])` | `children == []` |
| daemon-health-report-024 | children-recursive | A composite strategy with one child that itself has one child; a leaf strategy | The composite's `children` holds the child, whose `children` holds the grandchild; the leaf's `children` is empty |
| daemon-health-report-025 | status-opaque | A well-formed body whose `status` is `"degraded"` | Decodes; `status == "degraded"` |
| daemon-health-report-026 | decode-iso8601, decode-nil-on-mismatch | A well-formed body whose `nextActivation` is the number `1767225600` rather than an ISO-8601 string | `decode` returns `nil` for the whole report |
| daemon-health-report-027 | probe-url | `baseURL` `http://127.0.0.1:9000/` and, separately, `http://127.0.0.1:9000/api` | The requests are GETs to `http://127.0.0.1:9000/health` and `http://127.0.0.1:9000/api/health` |
## Edge Cases

- **Null and empty input**: An empty `Data` passed to `decode` MUST return `nil`. An empty `workUnits` array is valid and decodes as an empty array. A null `nextActivation` or `lastMessage` decodes as `nil`.
- **Malformed input**: Any JSON that does not match the schema, including a missing required key, a wrong type, or an unknown `state` value, MUST yield `nil` from `decode`; the decoder never returns a partially filled report.
- **Date format**: A `nextActivation` that is not an ISO-8601 date string (for example a numeric timestamp; whether fractional seconds parse is up to the OS release's `.iso8601` strategy, and macOS 26 accepts them) fails decoding of the whole report, so `decode` returns `nil`.
- **Boundary values**: `uptimeSeconds` and `consecutiveFailures` are not range-checked; negative or very large values pass through unchanged.
- **Deep or wide trees**: `first(ofKind:)` recurses without a depth limit, and a tree is bounded only by what the daemon sends.
- **Unreachable server**: A refused connection, DNS failure or lost connectivity MUST make the probe closure return `nil`; the closure does not distinguish those causes from one another or from a non-200 status.
- **Timeout**: A request that receives no data for `timeout` seconds MUST make the closure return `nil`. A server that sends bytes slowly but steadily never trips the timeout, so the closure can run longer than `timeout` seconds.
- **Base URL with a trailing slash or a path**: `http://h:9000/` MUST probe `http://h:9000/health`, and `http://h/api` MUST probe `http://h/api/health`.
- **Non-200 status**: Any status other than 200, including other 2xx codes and redirects the session does not follow to a 200, MUST return `nil`; the body of such a response is discarded.
- **Cancellation**: The closure has no explicit cancellation handling; its `try?` turns a cancelled request into `nil`, so cancellation is indistinguishable from failure.
- **Concurrent access**: The report types are immutable value types marked `Sendable`, so they are safe to share. Concurrent invocations of one probe closure each issue an independent request and share the one ephemeral session; the probe adds no serialisation, and none is needed because the closure holds no mutable state.
- **Offline state**: There is no offline mode; losing connectivity mid-request is the same as an unreachable server and returns `nil`.
- **Daemon up but different schema**: A 200 response whose body is in the daemon's own shape returns the body from the probe, and `decode` then returns `nil`; a caller can treat that combination as reachable but opaque.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `baseURL` | String | none (required) | Base URL of the daemon; `health` is appended as a path component. |
| `timeout` | TimeInterval | `2` | Request timeout in seconds for each probe call. |
| Date decoding | fixed | ISO-8601 | The decoder's `dateDecodingStrategy`; not configurable. |
| URL session | fixed | `.ephemeral` | The configuration of the session the probe creates; not configurable. |

## Deep Linking

Not applicable: The file defines a data model and an HTTP probe and registers no URL scheme, route or link handler.

## Localization

Not applicable: The file contains no user-facing strings. The `State` raw values and the kind constants are wire identifiers, and `lastMessage` is text supplied by the daemon and passed through as received.

## Accessibility Options

Not applicable: The file has no visual surface, so no Reduce Motion, Increase Contrast or Differentiate Without Color behavior exists.

## Feature Flags

Not applicable: The source reads no flag; the probe and the decoder are always active.

## Analytics

Not applicable: The source emits no analytics events.

## Privacy

- **Data collected**: None by this code. It carries whatever the daemon reports, including free text in `lastMessage`.
- **Storage**: None. The probe uses an ephemeral session, so no cache, cookie or credential store is written to disk.
- **Transmission**: One GET to `<baseURL>/health`. The request adds no headers, credentials or body; whether the transport is encrypted depends on the scheme the caller passes in `baseURL`.
- **Retention**: None beyond the lifetime of the value or closure the caller holds.

## Logging

Not applicable: The source calls no logging API; failures are returned as `nil` to the caller.

## Platform Notes

- **SwiftUI**: The source is `Core/DaemonHealth/DaemonHealthReport.swift` and imports only `Foundation`, so a SwiftUI host uses it unchanged. The three report types are plain `struct`s, `DaemonHealthProbe` is a caseless `enum` whose `http` returns a `@Sendable () async -> Data?` closure, and the probe's session comes from `URLSession(configuration: .ephemeral)`. Poll the closure from a `.task` or a view model and publish the decoded report.
- **Compose**: Model the report as Kotlin `data class`es with `kotlinx.serialization` (`@Serializable`, a default of `emptyList()` for `children`, and an enum with `@SerialName` per state). Return `null` from a `suspend` probe built on `OkHttp` with `readTimeout(2, SECONDS)` (an idle timeout; do not use `callTimeout`, which bounds the whole call), and decode with `Json.decodeFromString` inside `runCatching` to match the nil-on-mismatch rule. Parse ISO-8601 dates with `java.time.Instant.parse`.
- **React/Web**: Use TypeScript interfaces for the three shapes and a union of the four state strings. The probe is `fetch(base + "/health", { signal: AbortSignal.timeout(2000) })`, returning the raw text or `ArrayBuffer` body only when `response.status === 200`, and `null` on any rejection. `AbortSignal.timeout` bounds the whole request, so for the idle timeout the spec requires, use an `AbortController` whose timer restarts each time a chunk of the response body is read. Write a validating `decode` that returns `null` for a missing required key or unknown state, since `JSON.parse` does not enforce a schema; convert date strings with `Date.parse` or `new Date`.
- **AppKit / UIKit**: Identical to the SwiftUI note: the contract is UI-framework-agnostic, and a menu bar app (the stated consumer) calls the probe on a timer from its status item delegate. Only the embedding differs.
- **WinUI 3**: Use records or classes with `System.Text.Json` (`JsonSerializer.Deserialize` wrapped in a `try`/`catch (JsonException)` that returns `null`), `JsonStringEnumConverter` for `State` with `JsonSerializerOptions` configured so an unknown value throws, and `List<T>` for the arrays, defaulting `Children` to an empty list when absent. Required members use the C# `required` modifier so a missing key fails, and `DateTimeOffset?` carries `NextActivation`. Build the probe as `Func<Task<byte[]?>>` over one shared `HttpClient` (the analogue of the shared ephemeral session; create it once, not per call) with `Timeout = Timeout.InfiniteTimeSpan`, read the response stream with `HttpCompletionOption.ResponseHeadersRead` and a `CancellationTokenSource` that is re-armed for 2 seconds each time data arrives (`HttpClient.Timeout` bounds the whole call, which is not the idle timeout the spec requires), catch `HttpRequestException` and `TaskCanceledException` to return `null`, and return the body only when `StatusCode == HttpStatusCode.OK`. A view model exposing the decoded report implements `INotifyPropertyChanged` and is updated from a `DispatcherQueueTimer`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/DaemonHealth/DaemonHealthReport.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The report types mirror DaemonKit's wire format in this file rather than importing DaemonKit.
**Rationale**: A menu bar app or other client reads a daemon's health with Foundation only, the same arrangement [adhsdk.ingredient.foundation.stenographer.stenographer-http-client](cookbook:9c7c78d3-23ca-4ca6-a519-9968b440b8c6) uses for stenographerd, and the JSON keys alone are the contract between the two.
**Approved**: pending

**Decision**: The Swift names (`DaemonHealthReport`, `DaemonStrategyReport`, `DaemonWorkUnitReport`) differ from DaemonKit's `HealthStatus`, `StrategySnapshot` and `WorkUnitSnapshot`.
**Rationale**: A file importing both modules never meets an ambiguous type name.
**Approved**: pending

**Decision**: `decode` returns `nil` for any undecodable body and discards the error.
**Rationale**: A daemon may answer `/health` in its own shape and still be up, so a mismatch is a normal outcome, not an error to surface. The cost is that a caller cannot tell which key failed.
**Approved**: pending

**Decision**: `status` and `kind` are Strings while the work-unit `State` is a closed enum.
**Rationale**: A daemon may report its own `kind` value, so a consumer treats unknown kinds as opaque. The closed `State` enum has no fallback, so a daemon reporting a fifth state makes the whole report fail to decode; this is the actual behavior and a port must reproduce it.
**Approved**: pending

**Decision**: `DaemonStrategyReport` has a hand-written `init(from:)` that makes `children` optional on the wire, while the other two structs use synthesized decoding.
**Rationale**: A leaf strategy need not send `children`, because it is empty for a leaf. For the work unit, the initializer defaults are not used when decoding, so its non-optional fields are required keys.
**Approved**: pending

**Decision**: The probe collapses every failure (non-200, transport error, timeout, bad URL, cancellation) into `nil`.
**Rationale**: A menu bar app polling for reachability needs a binary answer. The probe returns `nil` for any other status, a transport error or a timeout. It also does not retry, because the caller owns the polling cadence.
**Approved**: pending

**Decision**: The probe takes a 2 second default timeout and uses an ephemeral session created once per probe.
**Rationale**: A poll must not hang a menu bar refresh, and an ephemeral session keeps cookies, caches and credentials off disk. The session is built when the probe is built, not per call, so the closure reuses it.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | passed | Access Patterns |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |

`separation-of-concerns` passes because the file only models, decodes and fetches the health body; it holds no polling schedule, rendering or alerting, which belong to the menu bar app. `unit-test-coverage` is partial: 25 of 27 vectors have a test. `DaemonHealthReportConformanceTests.swift` (Core tests) covers every vector except 001 and 002, which the `DaemonHealthReportTests` suite in `AgenticDeveloperHubSDKMenuBarTests/MenuSectionTests.swift` covers. It runs the probe against a loopback HTTP responder. Skipped: daemon-health-report-015 (the 2 second idle timeout needs a real wait) and daemon-health-report-021 (a body trickled for several real seconds). `timeout-configuration` passes because the probe takes a `timeout` parameter with a 2 second default and applies it to the request. `graceful-degradation` passes because every probe failure and every decode mismatch returns `nil` rather than throwing, so a client keeps running when the daemon is down or answers in another shape.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.3 | 2026-11-14 | Mike Fullerton | Vectors no longer depend on Foundation accepting or rejecting a trailing comma or fractional-second dates |
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (DaemonHealthReportConformanceTests.swift, 25 of 27 vectors); unit-test-coverage now partial. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Restated the probe timeout as an idle timeout with a slow-server vector, added the stenographer-http-client link and related entry, merged the optional-field requirement into workunit-fields, added vectors for the uncovered requirements and trailing-slash base URLs, and corrected the timeout and response handling in the Compose, React and WinUI notes. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
