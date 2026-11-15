---
id: 2affdc87-3c3b-4f7d-819d-f54ba947f2f1
title: "HostMCPServer Stdio"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Serves HostMCPServer over stdin and stdout, then waits up to 360 seconds for replies still owed after input closes before stopping, so piped requests are answered."
platforms:
  - swift
  - macos
tags:
  - mcp
  - server
  - stdio
  - drain
depends-on: []
related:
  - 52650804-a096-4b71-b4eb-da3afa95ac56
references: []
approved-by: ""
approved-date: ""
---

# HostMCPServer Stdio

## Overview

`HostMCPServer+Stdio` is an extension of `HostMCPServer` that serves the host's MCP tools over this process's standard input and output and shuts down cleanly when input ends. It adds the public `serveStdio()`, a drain deadline constant `stdioDrainDeadline` of 360 seconds, and an internal `serveUntilDrained(over:deadline:)` that works with any transport.

The reason it exists is stated in the source: the pinned MCP Swift SDK (0.12.1) answers each request in its own unstructured task, and `waitUntilServerCompleted()` waits only for the receive loop, which ends at end of input. Stopping at that point drops every reply still in flight, so `printf '...' | temporal mcp` would print nothing. The extension wraps the transport in a `ReplyCountingTransport`, which counts requests that have arrived and are not yet answered, and waits for that count to reach zero or for the deadline before it stops the server.

## Behavioral Requirements

Public surface

- **drain-deadline-value**: `stdioDrainDeadline` MUST be 360 seconds, long enough, per its comment, for a slow tool call such as temporal's mail sign-in, which waits up to 300 seconds for the browser plus an XPC timeout above that.
- **serve-stdio-transport**: `serveStdio()` MUST serve over a stdin and stdout transport using `stdioDrainDeadline`.
- **serve-stdio-returns**: `serveStdio()` MUST return only after input has closed and every request that arrived before that has been answered, or after the deadline has passed.
- **serve-stdio-throws**: `serveStdio()` MUST throw whatever error `serve(over:)` throws while starting.

Draining

- **drain-wraps-transport**: `serveUntilDrained(over:deadline:)` MUST wrap the given transport in a `ReplyCountingTransport` and serve over the wrapper.
- **drain-default-deadline**: The deadline parameter MUST default to `stdioDrainDeadline`.
- **drain-waits-for-loop**: After starting, the method MUST wait until the server's message loop ends, which happens when the transport's input ends.
- **drain-waits-for-replies**: After the loop ends, the method MUST wait until no request is owed a reply or until the deadline has passed, whichever is first.
- **drain-deadline-from-eof**: The deadline MUST count from the moment the wait begins, which is after the input has ended.
- **drain-stops-always**: The method MUST call `stop()` after the wait, whether or not every reply was written.
- **drain-warning**: When the deadline passes with replies still owed, the method MUST write one warning log line `MCP input closed; <n> request(s) unanswered at the deadline` with the count logged as public, and MUST then still stop.
- **drain-abandons**: A reply still missing at the deadline MUST be abandoned; it is not written.

Reply counting (`ReplyCountingTransport`)

- **counting-passthrough**: The wrapper MUST pass connect, disconnect, send and receive through to the wrapped transport unchanged, and MUST yield every received message to the server in order.
- **counting-request**: A received message with both an `id` and a `method` MUST be counted as owed as soon as it arrives, before the server sees it.
- **counting-response**: A sent message with an `id` and no `method` MUST pay the matching owed id.
- **counting-cancel**: A received `notifications/cancelled` whose `params.requestId` names an owed id MUST pay that id, because the client has given up and MCP lets the server skip a cancelled request.
- **counting-id-kind**: A string id and a number id MUST be different ids; the string `"1"` and the number `1` MUST NOT match each other.
- **counting-ignores-notifications**: A received message with a `method` and no `id`, other than a cancellation, MUST NOT be counted.
- **counting-batches**: A batch (a JSON array) MUST NOT be counted, because the SDK answers a batch inside its receive loop so the reply is written before the loop ends.
- **counting-unparseable**: A message that is not a JSON object MUST NOT be counted.
- **owed-count**: The wrapper MUST expose the number of owed ids as `owedCount`.
- **wait-nothing-owed**: `waitUntilNothingOwed(deadline:)` MUST return true at once when nothing is owed.
- **wait-releases-on-last-reply**: It MUST return true when the last owed id is paid before the deadline.
- **wait-deadline**: It MUST return false when the deadline passes first with ids still owed.
- **disconnect-releases-waiters**: `disconnect()` on the wrapper MUST release any waiter, so a drain does not outlive its transport.
- **input-end-passthrough**: The wrapper MUST finish its received stream when the wrapped stream finishes, and MUST finish it with the error when the wrapped stream throws.
- **stream-termination**: When the consumer ends the wrapper's received stream, the wrapper MUST cancel the task that reads the wrapped transport.

## Appearance

Not applicable — this is a protocol server extension, not a visual component.

## States

Not applicable — this is a protocol server extension, not a visual component. Its runtime states are described under Behavioral Requirements: serving, draining (input closed, replies owed), and stopped.

## Accessibility

Not applicable — this is a protocol server extension, not a visual component.

## Conformance Test Vectors

Derived from `HostMCPServerDrainTests` where named; the rest are traced to the source. The scripted transport used by the tests yields a fixed list of messages and ends at once, as piped standard input does.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| host-mcp-server-stdio-001 | drain-waits-for-replies, drain-stops-always | Script: `initialize` (id 1), `notifications/initialized`, `tools/list` (id 2); a source whose definitions take 300 ms; `serveUntilDrained(over:)` (`testRequestsInFlightWhenInputClosesAreStillAnswered`) | Responses for ids 1 and 2 are both sent before the method returns |
| host-mcp-server-stdio-002 | counting-cancel, owed-count, wait-releases-on-last-reply | Script: `tools/call` id 5, `tools/list` id `"6"`, `notifications/cancelled` for 5; read to the end (`testACancelledRequestIsNoLongerOwedAReply`) | `owedCount` is 1 |
| host-mcp-server-stdio-003 | counting-response, wait-releases-on-last-reply, counting-id-kind | Then send the response with id `"6"` and wait with a 30 s deadline (`testACancelledRequestIsNoLongerOwedAReply`) | The wait returns true in under 5 s |
| host-mcp-server-stdio-004 | drain-deadline-from-eof, drain-abandons, drain-warning, wait-deadline | Same script; a source whose definitions take 60 s; deadline 300 ms (`testDrainGivesUpAtItsDeadline`) | The method returns in under 10 s; only the response for id 1 was sent |
| host-mcp-server-stdio-005 | counting-id-kind | Receive a request with number id 1 and send a response with string id `"1"` | `owedCount` stays 1 |
| host-mcp-server-stdio-006 | counting-ignores-notifications | Receive `notifications/initialized` | `owedCount` is 0 |
| host-mcp-server-stdio-007 | counting-batches | Receive a JSON array of two requests | `owedCount` is 0 |
| host-mcp-server-stdio-008 | wait-nothing-owed | Wait with nothing owed and a 30 s deadline | Returns true at once |
| host-mcp-server-stdio-009 | counting-unparseable | Receive the bytes `not json` | `owedCount` is 0 and the bytes are still yielded |
| host-mcp-server-stdio-010 | drain-deadline-value | Read `HostMCPServer.stdioDrainDeadline` | 360 seconds |
| host-mcp-server-stdio-011 | counting-passthrough | Send bytes through the wrapper | The wrapped transport receives the same bytes |
| host-mcp-server-stdio-012 | disconnect-releases-waiters | One request owed, a waiter pending, then `disconnect()` | The waiter returns false |
| host-mcp-server-stdio-013 | input-end-passthrough | Wrapped stream throws an error | The wrapper's stream ends with that error |
| host-mcp-server-stdio-014 | serve-stdio-throws | Transport whose connect throws, via `serveUntilDrained(over:)` | The method throws that error |
| host-mcp-server-stdio-015 | drain-warning | Same as 004 with the logs captured | One warning `MCP input closed; 1 request(s) unanswered at the deadline` |
| host-mcp-server-stdio-016 | drain-wraps-transport, drain-default-deadline, serve-stdio-transport, serve-stdio-returns, drain-waits-for-loop | `serveStdio()` with stdin piped one `tools/list` request | The reply is written to stdout before the method returns. The source gives no test; this is asserted from the source comments and the `temporal mcp` example. |
| host-mcp-server-stdio-017 | counting-request, owed-count, stream-termination | Receive a request, then end the consumer's stream early | The reader task is cancelled; `owedCount` is 1 |

## Edge Cases

- **Input closes before any request**: nothing is owed, so the method MUST stop at once.
- **Input closes with several requests in flight**: every reply MUST be written if each finishes before the deadline.
- **A reply never comes**: the method MUST give up at the deadline, log the warning with the count and stop; the reply is lost.
- **Cancelled request**: MUST NOT hold the drain open; covered by `testACancelledRequestIsNoLongerOwedAReply`.
- **Cancellation of an id that is not owed**: MUST have no effect.
- **Duplicate request ids**: the owed set holds each id once, so a second request with the same id, and then one reply, leaves nothing owed.
- **Batch request**: not counted; the reply is written inside the receive loop, so a batch is answered before the loop ends.
- **Malformed message**: not counted and still passed to the server, which decides what to do.
- **Transport throws while reading**: the error ends the wrapper's stream, the server's loop ends, and the drain proceeds to its wait and stop.
- **Start fails**: `serve(over:)` throws, the error propagates, and the wait and stop are skipped.
- **Concurrent access**: `ReplyCountingTransport` is an actor, so its owed set and waiter list are serialised; any number of waiters may wait at once and all are released together.
- **Offline or disconnected state**: standard input and output are local pipes; a peer that disconnects looks like end of input and follows the normal drain path.
- **Slow tool call**: a tool call that takes longer than 360 seconds after input closes is abandoned at the deadline.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `stdioDrainDeadline` | `Duration` (static) | 360 seconds | How long a server whose input has closed waits for the replies it still owes |
| `deadline` | `Duration` | `stdioDrainDeadline` | The same wait, per call of `serveUntilDrained(over:deadline:)` |
| `transport` | `Transport` | none | The transport `serveUntilDrained(over:deadline:)` serves over; `serveStdio()` supplies the standard stream transport |

## Deep Linking

Not applicable: the extension serves standard input and output and defines no URL scheme or route.

## Localization

The only user-visible text is the warning log line, written in English as a diagnostic, not as interface text. Not applicable otherwise: the extension returns no strings to a caller.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal) | `MCP input closed; <n> request(s) unanswered at the deadline` | Warning log line at the drain deadline |

## Accessibility Options

Not applicable: the extension has no visual output, so Reduce Motion, Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the source reads no flag or setting; the deadline is a constant and a parameter.

## Analytics

Not applicable: the source emits no analytics events.

## Privacy

- **Data collected**: None. Message bodies are parsed only for `id`, `method` and `params.requestId`, and are not stored or logged.
- **Storage**: Owed ids are held in memory until paid or the process ends.
- **Transmission**: Messages travel between the process's standard input and output and the server; nothing else is sent.
- **Retention**: Not applicable: nothing is persisted.

## Logging

Subsystem: `AgenticDeveloperHubSDK` | Category: `automation`

| Event | Level | Message |
|-------|-------|---------|
| Deadline passed with replies still owed | warning | `MCP input closed; <n> request(s) unanswered at the deadline` |

`ReplyCountingTransport` supplies the SDK's logger requirement with a no-op log handler, so it writes no log lines of its own.

## Platform Notes

- **SwiftUI**: Sources are `packages/apple/AgenticDeveloperHubSDK/Core/MCP/HostMCPServer+Stdio.swift` and `ReplyCountingTransport.swift` in the Core module. There is no view; a command-line entry point (`temporal mcp`) calls `serveStdio()` and exits when it returns. A SwiftUI app would use `serveUntilDrained(over:)` only with a non-stdio transport.
- **Compose**: Use a Kotlin coroutine scope on the server: wrap the transport in a class counting owed ids in a `ConcurrentHashMap.newKeySet()`, and wait with `withTimeoutOrNull(deadline)` on a `CompletableDeferred` completed when the set empties. The Swift workaround exists for the pinned Swift SDK's unstructured tasks; keep the drain only if the Kotlin SDK also ends its loop before replies are written.
- **React/Web**: In Node, serve over `StdioServerTransport` from `@modelcontextprotocol/sdk`, track owed ids in a `Set<string>` keyed with a type prefix (`s:` or `n:`) to keep `"1"` and `1` apart, and wait with `Promise.race` between a promise resolved when the set empties and a `setTimeout` for the deadline. Do not call `process.exit` until the race settles. A browser has no standard input, so this does not apply there.
- **AppKit / UIKit**: Same files; they use only `Foundation`, `Logging` (swift-log) and `MCP`. Standard input and output belong to a command-line or helper process, not an AppKit app, so the host app uses the HTTP transport instead and does not call `serveStdio()`.
- **WinUI 3**: Implement as a .NET class that wraps the C# MCP SDK's `StdioServerTransport` (or `Console.OpenStandardInput` and `Console.OpenStandardOutput` streams) in a counting decorator. Keep owed ids in a `HashSet<string>` guarded by `lock` or a `SemaphoreSlim`, with keys prefixed `s:` or `n:`; read ids with `System.Text.Json` (`JsonDocument`, `JsonValueKind.String` or `Number`). Wait with `Task.WhenAny(drained.Task, Task.Delay(deadline))` where `drained` is a `TaskCompletionSource`, using `TimeSpan.FromSeconds(360)` as the default; log the warning through `ILogger.LogWarning`. A WinUI app has no console, so run this in a console or background-service host (`IHostedService`), not in the XAML process, and call `await host.StopAsync()` after the wait.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/MCP/HostMCPServer+Stdio.swift` | confirmed (1.0.1) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The server waits for owed replies after end of input instead of stopping when the receive loop ends.
**Rationale**: The source comment explains that the pinned SDK answers each request in an unstructured task and the receive loop ends at EOF, so an immediate stop drops every reply in flight; `printf '...' | temporal mcp` would get nothing back.
**Approved**: pending

**Decision**: Owed requests are counted by a transport wrapper instead of by the server.
**Rationale**: The source does not state why the count lives in a wrapper. The wrapper is where every request in and every response out passes, so it can count without changing the server; the source comments describe the SDK's per-request unstructured tasks, not any way to read them.
**Approved**: pending

**Decision**: The deadline is 360 seconds and counts from the end of input.
**Rationale**: The source comment gives the longest known tool call: temporal's mail sign-in waits up to 300 seconds for the browser plus an XPC timeout above that. A reply missing at the deadline is abandoned and logged.
**Approved**: pending

**Decision**: A cancellation pays the cancelled id.
**Rationale**: MCP says a server need not answer a cancelled request, so waiting for it would hold the drain open until the deadline (`testACancelledRequestIsNoLongerOwedAReply`).
**Approved**: pending

**Decision**: Batches are not counted.
**Rationale**: The SDK answers a batch inside the receive loop, so its reply is written before the loop ends (source comment).
**Approved**: pending

**Decision**: String and number ids are kept apart with a type prefix.
**Rationale**: JSON-RPC treats `"1"` and `1` as different ids; the key records which kind each was.
**Approved**: pending

**Decision**: The SDK version is pinned in the comments (0.12.1) because the workaround depends on it.
**Rationale**: If a later SDK waits for in-flight replies itself, the wrapper becomes redundant; the source does not test for that, so a port to a different SDK should verify before copying it.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | passed | reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | partial | reliability |

The drain logic sits in an extension and a transport wrapper, apart from routing in `HostMCPServer`. `HostMCPServerDrainTests` and `HostMCPServerStdioConformanceTests` cover every vector except host-mcp-server-stdio-015 (the drain warning line, skipped because the `Logger` cannot be captured in a unit test) and host-mcp-server-stdio-016 (`serveStdio()`, skipped because it reads the real process stdin and writes the real stdout). Coverage is therefore partial. The deadline bounds the wait and a missed reply is logged, so timeout handling passes. On a timeout the late replies are dropped with a warning, a degraded but surfaced result, so graceful degradation is partial.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Conformance tests added (HostMCPServerStdioConformanceTests.swift, 13 new vectors; 15 of 17 covered with HostMCPServerDrainTests); unit-test-coverage now partial (stdio-015 log capture and stdio-016 real stdin/stdout skipped). |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
