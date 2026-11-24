---
id: 03ac452d-50c9-4438-9cfb-9cb2c2b65249
title: "MCP HTTP Endpoint"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Serves a host MCP server over stateless Streamable HTTP on loopback with a bearer token, a single POST /mcp route, unique request ids and real cancellation."
platforms:
  - swift
  - macos
tags:
  - mcp
  - http
  - server
  - protocol
depends-on: []
related:
  - 52650804-a096-4b71-b4eb-da3afa95ac56
references: []
approved-by: ""
approved-date: ""
---

# MCP HTTP Endpoint

## Overview

The MCP HTTP Endpoint is the listening half of the app's automation surface. It takes a `HostMCPServer` and serves it to local MCP clients (Claude Code, for one) over MCP Streamable HTTP on `127.0.0.1`. FlyingFox owns the socket. The MCP SDK's `StatelessHTTPServerTransport` owns the protocol, including Origin and Host checks, Accept and Content-Type checks, and the protocol-version check. The endpoint adds what the SDK leaves to the host:

- A bearer token on every request.
- One `POST /mcp` route, with 404 and 405 for everything else.
- A unique JSON-RPC id per request. The stateless transport keys its bookkeeping by id alone, so two callers who both send `"id": 1` would otherwise collide.
- Cancellation. Because a request runs under an id its caller did not send, the endpoint translates a caller's `notifications/cancelled` to the id the SDK knows, and turns FlyingFox's request timeout, which on its own cancels only the HTTP handler, into the same cancellation, so the tool call stops when the client is told it failed.
- A start and stop lifecycle that survives a busy port and a stop that races a start.

It is an actor. One instance serves one `HostMCPServer` on one port. The registration side, which writes the command that points Claude Code at this endpoint, is the MCP registration ingredient (ai/mcp/mcp-registration). The client-side MCP plumbing is the sibling [adhsdk.ingredient.ai.mcp.mcp-plumbing](cookbook:52650804-a096-4b71-b4eb-da3afa95ac56).

The source is `packages/apple/AgenticDeveloperHubSDK/macOS/Features/MCP/MCPHTTPEndpoint.swift`. It depends on the core `HostMCPServer` (`serve(over:)`, `stop()`, `callerHeader`), FlyingFox, and the MCP SDK.

## Behavioral Requirements

Constants and construction

- **path-constant**: `MCPHTTPEndpoint.path` MUST be `/mcp`.
- **preferred-port-constant**: `MCPHTTPEndpoint.preferredPort` MUST be `51477`.
- **timeout-constant**: `MCPHTTPEndpoint.requestTimeout` MUST be 120 seconds, because a navigation or wait tool can legitimately run for a while; FlyingFox's default is 15 seconds.
- **init-parameters**: The initializer MUST take the server, the bearer token, an optional preferred port (default `preferredPort`), an optional request timeout (default `requestTimeout`) and an optional logger (default subsystem `AgenticDeveloperHubSDK`, category `automation`). Construction MUST NOT bind anything.

Starting and stopping

- **start-returns-bound-port**: `start()` MUST bind `127.0.0.1` on the preferred port and return the port actually listening.
- **start-loopback-only**: The listening address MUST be `127.0.0.1`, never a wildcard or external address.
- **start-falls-back-to-ephemeral**: When binding the preferred port fails and the preferred port is not 0 and no stop was requested, `start()` MUST log that the port is taken and bind port 0, then return the ephemeral port the system gave.
- **start-idempotent-when-running**: `start()` called while running MUST return the port it is already on without binding again.
- **start-serves-before-listening**: `start()` MUST first call `server.serve(over:)` with a fresh stateless transport, and only then bind the socket, so the first request already finds a served server.
- **start-while-starting-or-stopping**: `start()` called while another `start()` is binding, or while a `stop()` is tearing down, MUST throw `StartError.alreadyStarting`.
- **start-bind-confirmation**: `start()` MUST treat the bind as failed when the HTTP server's run loop ends early or does not report listening within 5 seconds, and MUST read the bound port from the listening address (IPv4 or IPv6); any other address kind, or no address, MUST fail with a file-not-found Cocoa error.
- **start-failure-cleans-up**: When `start()` throws for any reason, it MUST tear down everything it built (listener, run task, transport, port, server), return to idle, clear the stop request, and rethrow.
- **stop-tears-down**: `stop()` MUST stop the listener with a 1 second timeout, cancel the run task, clear the port and transport, and stop the `HostMCPServer`, then leave the endpoint idle and restartable.
- **stop-while-starting**: `stop()` called while `start()` is binding MUST record the request and return at once; `start()` then tears down what it built and throws `StartError.stoppedWhileStarting`.
- **stop-idempotent**: `stop()` called while already stopping, or while idle, MUST NOT fail; while stopping it returns at once.
- **stop-hides-closing-port**: `stop()` MUST flip the phase to stopping and move the listener, task, transport and port out of the actor's state before its first suspension, so a `start()` arriving meanwhile can neither see the closing port nor bind a second server.
- **port-observable**: The `port` property MUST be the bound port while running and nil otherwise.

Authorization

- **auth-bearer-required**: Every `POST /mcp` request MUST carry `Authorization: Bearer <token>` equal to the configured token; any other value, or no header, MUST be answered 401 with the response header `WWW-Authenticate: Bearer`.
- **auth-constant-time**: The token comparison MUST combine the length difference and every byte difference into one accumulator and MUST NOT return early on the first differing byte.
- **auth-before-body**: Authorization MUST be checked before the body is read or parsed.

Routing

- **route-post-only**: Only `POST /mcp` MUST reach the MCP transport.
- **route-wrong-method-405**: A request to `/mcp` with any other method MUST be answered 405 with the header `Allow: POST`.
- **route-wrong-path-404**: A request to any other path MUST be answered 404.

Id rewriting

- **rewrite-single-object-with-id**: A request body that is a single JSON object whose `id` is a string or an integer MUST be forwarded with its `id` replaced by a fresh UUID string, and the original id MUST be remembered.
- **rewrite-passthrough**: A body that is an array, has no `id`, has a null, boolean or fractional `id`, or cannot be parsed or re-serialised MUST be forwarded unchanged. A null id is no id to the SDK (a notification), so the endpoint MUST NOT turn it into a request.
- **rewrite-restore-response**: In the response body, when it is a JSON object whose `id` equals the unique id, the endpoint MUST put the caller's original id back, preserving its type (integer stays integer, string stays string). Any other response body MUST pass through unchanged.

Caller identity

- **caller-header-forwarded**: The endpoint MUST forward every request header to the transport so the server can read the caller header (`HostMCPServer.callerHeader`, `X-ADKitchen-Pane`) and give the tool source the caller id; a request without it reaches the source with no caller.

Cancellation

- **cancel-recognise**: A body MUST be treated as a cancellation when it is a JSON object with no rewritable id, whose `method` is the MCP cancelled-notification name (`notifications/cancelled`), and whose `params.requestId` is a string or an integer.
- **cancel-keyed-by-caller**: The endpoint MUST track in-flight requests by the pair (caller header value or empty, the id the caller sent) so a cancellation from one caller cannot stop another caller's request that happens to use the same id.
- **cancel-translate**: For a recognised cancellation whose key is in flight, the endpoint MUST forward the notification with `params.requestId` replaced by the unique id, then release the waiting request (see `cancel-release`).
- **cancel-unknown-passes**: For a cancellation whose key is not in flight (already answered, or another caller's), the endpoint MUST forward it unchanged and the SDK ignores it; the HTTP answer to the notification itself MUST be the transport's (202 with no body).
- **cancel-release**: Releasing a cancelled request MUST send the transport a JSON-RPC error response for the unique id with code `-32800` and message `request cancelled: <reason>`, so the HTTP call waiting on it is answered rather than held open until the timeout. A release arriving after a real response finds no waiter and the transport drops it.
- **cancel-timeout-forwarded**: When FlyingFox's request timeout cancels a handler, the endpoint MUST send the transport a `notifications/cancelled` for the unique id with reason `the HTTP request timed out`, and then release it, so the tool call stops and the client is answered.
- **inflight-reuse-last-wins**: When a caller reuses an id while the first request is still in flight, the later request's unique id MUST win the key; the earlier request's completion MUST NOT forget the later entry.
- **inflight-cleared-on-completion**: A request's in-flight entry MUST be removed when its handler returns.

Response mapping

- **response-status-map**: The SDK's status code MUST be mapped to the matching FlyingFox status for 200, 202, 400, 401, 403, 404, 405, 406, 421 and 500, and to a status with that numeric code and an empty phrase otherwise.
- **response-headers-copied**: The SDK response's headers MUST be copied onto the FlyingFox response.
- **response-stream-collected**: A streamed SDK response MUST be collected into one body. A stream that fails midway MUST become an empty 500, never a truncated 200.

Logging

- **log-outcomes**: The endpoint MUST log each handled request's path and status, each 401, each cancellation, the port-taken fallback, and the listening port, none of which includes the token or body.

## Appearance

Not applicable — this is a network service actor, not a visual component.

## States

The endpoint is a four-phase state machine, `idle`, `starting`, `running` and `stopping`, with the port observable only while running.

| State | Entered when | Behavior |
|-------|-------------|----------|
| idle | Construction; after `stop()` completes; after a failed `start()` | `start()` begins binding. `stop()` runs the teardown (nothing to close, but it still stops the `HostMCPServer`) and ends idle. `port` is nil. |
| starting | `start()` begins | A second `start()` throws `alreadyStarting`. `stop()` records a stop request and returns. When binding finishes the stop request makes `start()` tear down and throw `stoppedWhileStarting`. |
| running | The listener is confirmed and the port recorded | `start()` returns the same port. `stop()` begins tearing down. Requests are served. |
| stopping | `stop()` begins | `start()` throws `alreadyStarting`. A second `stop()` returns at once. Ends in idle. |

Transitions: idle to starting on `start()`; starting to running on a confirmed bind; starting to idle on any `start()` failure or a recorded stop; running to stopping and then idle on `stop()`.

## Accessibility

Not applicable — this is a network service actor with no user interface.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mcphttp-endpoint-001 | start-returns-bound-port, route-post-only | Start with preferred port 0, then `POST /mcp` with a valid bearer and `tools/list` | Status 200 and the registered tool names in order (`MCPHTTPEndpointTests.testToolsListRoundTrip`) |
| mcphttp-endpoint-002 | auth-bearer-required | `POST /mcp` with bearer `nope` | Status 401 (`testWrongBearerIs401`) |
| mcphttp-endpoint-003 | auth-bearer-required | `POST /mcp` with no Authorization header | Status 401 (`testMissingBearerIs401`) |
| mcphttp-endpoint-004 | route-wrong-path-404 | `POST /other` with a valid bearer | Status 404 (`testOtherPathIs404`) |
| mcphttp-endpoint-005 | route-wrong-method-405 | `GET /mcp` with a valid bearer | Status 405 (`testGetIs405`) |
| mcphttp-endpoint-006 | rewrite-restore-response | Two concurrent `tools/call` requests, both `"id": 1`, from panes `pane-A` and `pane-B` | Each answer carries id 1 and text `caller:<its pane>`, and the source saw both panes (`testConcurrentCallsWithTheSameIdKeepTheirOwnCaller`) |
| mcphttp-endpoint-007 | rewrite-restore-response | `tools/list` with `"id": "abc"` | Status 200 and the response id is the string `abc` (`testStringIdsRoundTripToo`) |
| mcphttp-endpoint-008 | rewrite-passthrough | `tools/list` with `"id": null` | Status 202 and no body (`testNullIdIsStillANotification`) |
| mcphttp-endpoint-009 | caller-header-forwarded | `tools/call whoami` with header `X-ADKitchen-Pane: pane-7`; then the same with no header | Text `caller:pane-7`; then `caller:none` (`testCallerHeaderReachesTheSource`, `testMissingCallerHeaderIsNone`) |
| mcphttp-endpoint-010 | cancel-recognise, cancel-translate, cancel-release | A 2 second `sleep` call with id 5 from pane-C; after 0.3 seconds a `notifications/cancelled` for id 5 from pane-C | The cancel POST answers 202 with no body; the call answers 200 in under 1.5 seconds with id 5 and an `error`; the tool recorded `cancelled` (`testCallerCancellationReachesTheTool`) |
| mcphttp-endpoint-011 | cancel-keyed-by-caller | The same `sleep` call from pane-C and a cancellation for id 5 from pane-D | The cancel answers 202; the sleep call finishes with a `result`; the tool recorded `finished` (`testCancellationFromAnotherCallerCancelsNothing`) |
| mcphttp-endpoint-012 | cancel-timeout-forwarded | An endpoint with `requestTimeout` 0.5 and a 2 second `sleep` call | Status 500 in under 1.5 seconds and the tool recorded `cancelled` (`testHTTPTimeoutCancelsTheTool`) |
| mcphttp-endpoint-013 | start-idempotent-when-running | `start()` on a running endpoint | Returns the same port (`testStartWhileRunningReturnsTheSamePort`) |
| mcphttp-endpoint-014 | start-falls-back-to-ephemeral | A second endpoint whose preferred port is the first endpoint's port | `start()` returns a different, non-zero port (`testSecondEndpointFallsBackToAnotherPort`) |
| mcphttp-endpoint-015 | route-post-only | `POST /mcp` with `Origin: https://evil.example` | Status is not 200; it is 400, 403 or 421 from the SDK pipeline (`testForeignOriginIsRefused`) |
| mcphttp-endpoint-016 | stop-while-starting, start-while-starting-or-stopping | `stop()` called while `start()` is binding; then a second `start()` during a stop | The first `start()` throws `stoppedWhileStarting`; the second throws `alreadyStarting` (derived from the phase switch; no test) |
| mcphttp-endpoint-017 | rewrite-passthrough | Bodies `[{"id":1}]`, `{"id":1.5,"method":"x"}`, `{"id":true}` and `not json` | Each is forwarded unchanged (derived from `rewriteID`; no test) |
| mcphttp-endpoint-018 | cancel-unknown-passes | A cancellation for id 99 when nothing is in flight | Status 202 with no body and no other request disturbed (derived from the cancel branch; no test) |

## Edge Cases

- **Null and empty input**: An empty body, or a body that does not parse, MUST be forwarded unchanged and the SDK answers it (MUST, per `rewrite-passthrough`). An empty token string MUST still be compared byte for byte, so the only authorised header is exactly `Bearer ` (MUST, per `auth-constant-time`).
- **Boundary values**: Preferred port 0 means "ephemeral" and MUST NOT trigger the port-taken fallback path (MUST). A fractional or boolean id is not rewritable and passes through; an integer id outside the range `JSONSerialization` round-trips exactly is not specified by the source.
- **Concurrent access**: Two callers using the same id are kept apart by the unique id and the caller key (MUST). A caller reusing an id while its first request is in flight has broken JSON-RPC; the later request wins the key and the earlier one's completion does not forget it (MUST).
- **Error states**: A failed bind MUST clean up fully. A non-IP bound address or a missing listening address fails with a file-not-found Cocoa error (MUST). A stream that fails midway becomes an empty 500 (MUST). The endpoint turns any cancellation of the handler task into the SDK cancellation sent for a timeout (`cancel-timeout-forwarded`); the source has no separate handling for a caller that drops the connection.
- **Offline or disconnected state**: Not applicable — the endpoint binds the loopback interface only, so it needs no network.
- **Timeouts**: A request that exceeds `requestTimeout` MUST be cancelled in the SDK through `cancel-timeout-forwarded`, so the tool stops; the test observes status 500 within about the timeout (`testHTTPTimeoutCancelsTheTool`), and the source does not set that status itself (MUST).
- **Port already taken**: The preferred port taken by another process (or by another endpoint in the same process) MUST fall back to an ephemeral port, and the caller learns the real port from the return value (MUST).
- **Stop racing start**: `stop()` during `start()` leaves no listener behind; `start()` throws `stoppedWhileStarting` (MUST).
- **Late release**: A release arriving after the real response finds no waiter and is dropped by the transport (MUST NOT affect the answered request).
- **Cancellation of an unrewritten request**: A request with no rewritable id has no unique id, so a timeout cannot be forwarded as a cancellation for it (the `onCancel` handler returns without sending); the source states no reason for this beyond there being no id to name.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `server` | `HostMCPServer` | none — required | The server to serve. |
| `token` | `String` | none — required | The bearer token every request must present. |
| `preferredPort` | `UInt16` | 51477 | The port to try first; 0 asks the system for an ephemeral port. |
| `requestTimeout` | `TimeInterval` | 120 seconds | FlyingFox's whole-handler timeout for each request. |
| `logger` | `Logger?` | subsystem `AgenticDeveloperHubSDK`, category `automation` | Where the endpoint logs. |
| `path` | `String` constant | `/mcp` | The one route. |
| Bind wait | constant inside the source | 5 seconds | How long `start()` waits for the listener to report listening. |
| Stop timeout | constant inside the source | 1 second | How long `stop()` gives the listener to close. |
| Cancel error code | constant inside the source | `-32800` | The JSON-RPC code of the cancelled-request error. |

## Deep Linking

Not applicable: the endpoint serves one machine-to-machine route and defines no app deep link or navigation destination.

## Localization

Not applicable: every string it produces (error messages such as `request cancelled: <reason>`, header names, log lines) is a protocol or diagnostic literal, not user-facing text.

## Accessibility Options

Not applicable: the component renders no UI, so it observes no Reduce Motion, Increase Contrast or Differentiate Without Color setting.

## Feature Flags

Not applicable: the source reads no flag; its behavior is set by the initializer's parameters.

## Analytics

Not applicable: the source emits no analytics event; its only reporting is the diagnostic log under Logging.

## Privacy

- **Data collected**: Request bodies are tool calls and their arguments from a local MCP client, plus the caller-pane header. The endpoint reads them to route and rewrite ids and does not keep them past the request.
- **Storage**: The endpoint stores nothing durable. The in-flight table holds only caller and id strings for the life of a request. The token is held in memory.
- **Transmission**: The socket binds `127.0.0.1` only, so nothing is reachable from another machine, and traffic is plain HTTP on loopback guarded by the bearer token.
- **Retention**: Nothing is retained after a request completes or the endpoint stops.
- **Token handling**: The token is compared in constant time and is never logged; the 401 log line names only the path and status.

## Logging

- **Subsystem and category**: `AgenticDeveloperHubSDK` and `automation` by default, injectable.
- **Levels**: `info` for each request's path and status (including the 401 and cancel lines) and the port-taken fallback; `notice` for the listening port.
- **Privacy**: Port numbers and paths are logged as public. Bodies, headers and the token MUST NOT be logged.
- **Events**: port taken then ephemeral bind; listening on port; each `POST /mcp` status; each 401; each cancellation status.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/macOS/Features/MCP/MCPHTTPEndpoint.swift`, a `public actor` built into the macOS framework target on FlyingFox and the MCP SDK. The host's automation feature, which lives outside this source, starts it and publishes the returned port to `AutomationServerStatus`, which builds the URL from `MCPHTTPEndpoint.path`; the endpoint has no view of its own. Await `start()` and `stop()` off the main actor.
- **Compose**: Port as a class owning a coroutine scope, using an embedded HTTP server (Ktor with the CIO engine bound to `127.0.0.1`), a `Mutex`-guarded phase enum, a `ConcurrentHashMap` for in-flight keys, and `withContext` plus `Job.cancel` for timeout forwarding. Desktop JVM targets only; an Android app has no local MCP client to serve.
- **React/Web**: Not meaningful in a browser, which cannot listen on a port. A Node.js or Electron host ports it with `http.createServer` bound to `127.0.0.1`, `crypto.timingSafeEqual` over equal-length buffers for the token (after a length check, since the Swift version folds the length into the accumulator), an `AbortController` per request for timeout cancellation, and a `Map` for the in-flight table.
- **AppKit / UIKit**: Identical to the SwiftUI note; the endpoint is UI-free. Any AppKit surface only displays the status that the returned port yields.
- **WinUI 3**: Implement as a class in the app's service layer using Kestrel or `HttpListener` bound to `127.0.0.1`, `CryptographicOperations.FixedTimeEquals` for the token, a `SemaphoreSlim`-guarded phase enum, a `ConcurrentDictionary<string,string>` for in-flight keys, and a linked `CancellationTokenSource` with `CancelAfter(requestTimeout)` per request; the `WWW-Authenticate` and `Allow` headers are set explicitly. Surface the port through a bound view-model property.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/MCP/MCPHTTPEndpoint.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Every request with a rewritable id runs under a fresh UUID id, and the caller's id is restored in the answer.
**Rationale**: The doc comment says the stateless transport keys its bookkeeping by id alone, so two callers sending `"id": 1` would collide; a unique id per request removes the collision without changing what a caller sees.
**Approved**: pending

**Decision**: The endpoint owns cancellation, translating the caller's cancellation to the unique id and turning FlyingFox's timeout into an SDK cancellation.
**Rationale**: Because the running id is not the caller's, the SDK cannot match a caller's cancellation, and FlyingFox's timeout cancels only the HTTP handler; without the endpoint the tool call would run to its end and the transport's waiter would never be released.
**Approved**: pending

**Decision**: A cancelled request is answered with a JSON-RPC error carrying code `-32800` instead of being left without a response.
**Rationale**: The comment says the SDK sends no response for a cancelled request, as the spec says, but over stateless HTTP that holds the connection open to the timeout and leaks a transport waiter; `-32800` is the code the LSP uses, since JSON-RPC and MCP define none.
**Approved**: pending

**Decision**: When binding the preferred port fails, the endpoint falls back to an ephemeral port instead of failing.
**Rationale**: The source logs that the preferred port is taken and returns the port actually bound, so a caller building the URL uses the real port; failing outright would leave no endpoint.
**Approved**: pending

**Decision**: The token is compared without an early exit.
**Rationale**: The doc comment says the compare must not stop at the first differing byte, so timing does not reveal how much of a guess was right.
**Approved**: pending

**Decision**: A stop that arrives during a start is recorded and acted on by `start()` itself, and the phase flips before the first suspension in `stop()`.
**Rationale**: The comments say this keeps a racing `start()` from seeing the closing port or binding a second server; actor reentrancy makes both interleavings reachable.
**Approved**: pending

**Decision**: A streamed SDK response is collected into a single body, and a failed stream becomes an empty 500.
**Rationale**: The comment says the stateless transport never opens a stream for `tools/*`, so collecting is safe, and a truncated 200 would be worse than a visible failure.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.security.secure-authentication](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1d5c23d5-9a26-57fb-a23d-358271e4204a) | passed | Security |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | passed | Security |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | passed | Access Patterns |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | passed | Reliability |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | passed | Reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | partial | Security |

`secure-authentication` passes on the constant-time bearer check made before the body is read. `secure-log-output` passes because the log lines carry only path, status and port. `timeout-configuration` and `timeout-handling` pass on the injectable 120 second timeout that is forwarded into the SDK as a real cancellation. `error-recovery` passes on the failed-start cleanup and the fallback to an ephemeral port. `separation-of-concerns` passes: the SDK keeps the protocol, FlyingFox the socket, and this actor the host policy. `unit-test-coverage` is partial: the suite covers routing, auth, id round-trips, cancellation and the port fallback, but no test drives `stop()` during `start()`, a second `start()` during a stop, or the array, fractional, boolean and unparseable bodies (only the null id has a test). `secure-transport` is partial by design: traffic is plain HTTP, confined to the loopback address and guarded by the bearer token.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
