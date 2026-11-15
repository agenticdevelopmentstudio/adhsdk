---
id: c1f926d2-4e97-4f0b-862e-53a8cd5ed5a6
title: "Reply Counting Transport"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Wraps an MCP transport and counts requests still owed a reply, so a server whose input has closed can wait for its answers before stopping."
platforms:
  - swift
  - macos
tags:
  - mcp
  - transport
  - protocol
  - concurrency
depends-on: []
related:
  - 52650804-a096-4b71-b4eb-da3afa95ac56
references: []
approved-by: ""
approved-date: ""
---

# Reply Counting Transport

## Overview

The Reply Counting Transport is a pass-through wrapper around another MCP `Transport`. It forwards `connect`, `disconnect`, `send` and `receive` unchanged, and keeps a set of the JSON-RPC requests that have arrived but have not yet been answered. A server whose input has closed uses that set to wait for the answers it still owes.

The need comes from the pinned swift-sdk (0.12.1), which handles every request in its own unstructured task. `Server.waitUntilCompleted()` waits only for the receive loop, and that loop ends at the input's end of file. Without the wrapper, stopping the server at that point throws away every reply still being worked on. A piped invocation such as `printf '...' | temporal mcp` would then get nothing back.

It is an internal actor of the core framework. It is used by the stdio serving path (`HostMCPServer.serveUntilDrained`), which wraps its transport in it and waits on `waitUntilNothingOwed` with a deadline. The client-side MCP plumbing is the sibling [adhsdk.ingredient.ai.mcp.mcp-plumbing](cookbook:52650804-a096-4b71-b4eb-da3afa95ac56).

The source is `packages/apple/AgenticDeveloperHubSDK/Core/MCP/ReplyCountingTransport.swift`.

## Behavioral Requirements

Pass-through

- **passthrough-connect**: `connect()` MUST call the wrapped transport's `connect()` and propagate its error.
- **passthrough-send**: `send(_:)` MUST write the data to the wrapped transport and propagate its error.
- **passthrough-receive**: `receive()` MUST return a stream that yields, in order, every message the wrapped transport's stream yields, finishes when the wrapped stream finishes, and finishes with the same error when it throws.
- **receive-stops-pump**: When the consumer of the returned stream terminates it, the task pumping the wrapped stream MUST be cancelled.
- **disconnect-releases**: `disconnect()` MUST disconnect the wrapped transport and then release every drain waiter, so nobody keeps waiting on a closed transport.
- **logger-silent**: The transport's logger MUST discard everything (a no-op handler).

Counting

- **count-request**: A message that is a JSON object with both an `id` and a `method` MUST be counted as a request owed a reply, as soon as it arrives and before it is yielded to the server, so the server cannot answer it before it is counted.
- **count-id-kinds**: A string id and a number id MUST be different ids: the string `"1"` and the number `1` MUST be recorded under different keys (`s:1` and `n:1`).
- **count-ignore-other**: A message that is not a JSON object, has no `method`, or has an `id` that is neither a string nor a number (null, object, array) MUST NOT be counted; a JSON boolean `id` is read as a number by the source (see Edge Cases). A batch (a JSON array) is not counted: the SDK answers a batch inside the receive loop, so its reply is sent before the loop ends.
- **count-notification-not-counted**: A message with a `method` and no `id` (a notification) MUST NOT be counted, except as described under cancellation.

Paying debts

- **pay-on-response**: When `send` writes a message that is a JSON object with no `method` and an `id` that is a string or a number, the matching owed id MUST be removed.
- **pay-after-send**: The debt MUST be paid after the wrapped `send` has been attempted, whether it returned or threw.
- **pay-on-cancel**: When a message arrives that has a `method` of `notifications/cancelled`, no `id`, and `params.requestId` that is a string or a number, the matching owed id MUST be removed, because the client has given up and MCP says the server need not answer a cancelled request.
- **pay-unknown-harmless**: Paying an id that is not owed MUST have no effect.
- **pay-releases-when-empty**: Whenever a payment leaves nothing owed, every drain waiter MUST be released.

Draining

- **owed-count**: `owedCount` MUST report the number of requests currently owed a reply.
- **wait-immediate-when-empty**: `waitUntilNothingOwed(deadline:)` MUST return true at once when nothing is owed.
- **wait-until-paid**: With something owed, `waitUntilNothingOwed(deadline:)` MUST suspend until nothing is owed or the deadline passes.
- **wait-deadline**: When the deadline passes first, all waiters MUST be released, and the call MUST return false because something is still owed.
- **wait-result**: The call MUST return whether nothing is owed at the moment it resumes, not whether it was released by the timer or by a payment.
- **wait-timer-cancelled**: The deadline timer MUST be cancelled when the call returns.
- **wait-multiple**: Several concurrent waiters MUST all be released by the same payment or the same deadline.

## Appearance

Not applicable — this is a transport wrapper, not a visual component.

## States

Not applicable — this is a transport wrapper, not a visual component. Its one piece of state, the set of owed ids and the list of waiting continuations, is described under Behavioral Requirements.

## Accessibility

Not applicable — this is a transport wrapper with no user interface.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| reply-counting-transport-001 | count-request, pay-on-response, wait-until-paid, passthrough-receive | A stdio script of `initialize` (id 1), the initialized notification and `tools/list` (id 2) whose input ends at once, served through `serveUntilDrained` with a source that answers `tools/list` after 300 ms | Both replies, ids 1 and 2, are written before the server returns (`HostMCPServerDrainTests.testRequestsInFlightWhenInputClosesAreStillAnswered`) |
| reply-counting-transport-002 | pay-on-cancel, count-id-kinds, wait-immediate-when-empty | A script of `tools/call` id 5, `tools/list` id `"6"`, then `notifications/cancelled` for 5, fully received; then a response for id `"6"` is sent | `owedCount` is 1 after receiving; after the send `waitUntilNothingOwed(.seconds(30))` returns true in under 5 seconds (`testACancelledRequestIsNoLongerOwedAReply`) |
| reply-counting-transport-003 | wait-deadline, wait-result | The same server with a source that takes 60 seconds, drained with a 300 ms deadline | The server returns in under 10 seconds; only the reply that came, id 1, was written (`testDrainGivesUpAtItsDeadline`) |
| reply-counting-transport-004 | count-ignore-other | A received batch `[{"jsonrpc":"2.0","id":1,"method":"ping"}]` | `owedCount` is 0 (`ReplyCountingTransportConformanceTests.testV4_aBatchIsNotCounted`) |
| reply-counting-transport-005 | count-notification-not-counted | A received `{"jsonrpc":"2.0","method":"notifications/initialized"}` | `owedCount` is 0 (`ReplyCountingTransportConformanceTests.testV5_aNotificationIsNotCounted`) |
| reply-counting-transport-006 | count-id-kinds, pay-on-response | A received request with id 1, then a sent response with id `"1"` | `owedCount` stays 1, because `n:1` and `s:1` differ (`ReplyCountingTransportConformanceTests.testV6_aStringIdAndANumberIdAreDifferentIds`) |
| reply-counting-transport-007 | pay-after-send | A received request with id 3; `send` of the response for id 3 where the wrapped `send` throws | `send` rethrows and `owedCount` is 0 (`ReplyCountingTransportConformanceTests.testV7_aThrowingSendStillPaysTheDebt`) |
| reply-counting-transport-008 | pay-unknown-harmless | `notifications/cancelled` for an id that was never received | `owedCount` is unchanged (`ReplyCountingTransportConformanceTests.testV8_cancellingAnUnknownIdChangesNothing`) |
| reply-counting-transport-009 | disconnect-releases | A waiter suspended in `waitUntilNothingOwed(deadline: .seconds(30))` with an id owed, then `disconnect()` | The waiter returns false at once, well before 30 seconds (`ReplyCountingTransportConformanceTests.testV9_disconnectReleasesASuspendedWaiter`) |
| reply-counting-transport-010 | wait-multiple | Two waiters suspended with one id owed, then the response is sent | Both return true (`ReplyCountingTransportConformanceTests.testV10_twoWaitersAreBothReleasedByOnePayment`) |

## Edge Cases

- **Null and empty input**: A message that does not parse, or parses to something other than an object, MUST be ignored by the counter and still passed through (MUST). An `id` of null (or a missing `id`) is not an id and is not counted (MUST).
- **Boundary values**: A zero or very short deadline MUST return promptly with whether anything is still owed (MUST). Number ids are keyed by their decimal string form, so `1` and `1.0` as JSON numbers share the key `n:1` (a consequence of `NSNumber.stringValue`; the source does not address fractions).
- **Concurrent access**: The type is an actor, so the owed set and waiter list are never touched concurrently. The pump task runs on the actor and calls the counter synchronously, with no suspension, before it yields the message, so a request is always counted before the server can answer it (MUST). The deadline timer of any one waiter releases every waiter, so a waiter with a longer deadline resumes at the shortest one and returns whether anything is still owed (MUST, as written). A JSON boolean `id` is read as a number (`NSNumber`), so `true` is keyed `n:1` and `false` `n:0`; the source does not address booleans.
- **Error states**: A throwing wrapped `send` still pays the debt for that response (MUST, per `pay-after-send`); a request whose reply the server could not write is therefore no longer waited for. A throwing wrapped stream ends the returned stream with the same error (MUST).
- **Disconnect with debts**: `disconnect()` releases waiters but does not clear the owed set, so `owedCount` after a disconnect still reports the unanswered requests, and a waiter released that way gets false (MUST, as written).
- **A response for a request never counted**: A response with an unknown id is a no-op (MUST).
- **A duplicate request id**: Two requests received with the same id are one entry, so a single response pays both; the source does not distinguish them (a consequence of using a `Set`).
- **Offline or disconnected state**: Not applicable — the wrapper has no network of its own; it relays whatever the wrapped transport does.
- **Timeouts**: The deadline is the only timeout, and it bounds only the drain wait, not any individual request.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `inner` (parameter of `init(wrapping:)`) | `any Transport` | none — required | The transport that does the real reading and writing. |
| `deadline` (parameter of `waitUntilNothingOwed`) | `Duration` | none — required | The longest to wait for outstanding replies. |
| Stdio drain deadline | constant in the stdio serving path (`HostMCPServer.stdioDrainDeadline`) | 360 seconds | The deadline `serveUntilDrained` passes; owned by the caller, not by this type. |

## Deep Linking

Not applicable: the wrapper is an in-process transport adapter and defines no app deep link or navigation destination.

## Localization

Not applicable: it produces no user-facing strings; the id-key prefixes `s:` and `n:` are internal.

## Accessibility Options

Not applicable: the component renders no UI, so it observes no Reduce Motion, Increase Contrast or Differentiate Without Color setting.

## Feature Flags

Not applicable: the source reads no flag or setting.

## Analytics

Not applicable: the source emits no analytics event.

## Privacy

- **Data collected**: It parses every message to read `id`, `method` and `params.requestId`, and retains only the id keys of owed requests, never bodies or params.
- **Storage**: The owed set is in memory only and lives with the actor.
- **Transmission**: It relays messages to and from the wrapped transport and adds no transmission of its own.
- **Retention**: An id is dropped when its reply is sent or its request is cancelled; ids of requests never answered stay until the actor is released.
- **Logging**: The logger is a no-op, so nothing it sees is written anywhere.

## Logging

Not applicable: the transport's logger is a deliberate no-op (`SwiftLogNoOpLogHandler`), so it logs nothing. The stdio serving path that calls it (`serveUntilDrained`) logs a warning with the unanswered count when the deadline passes with replies still owed.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/Core/MCP/ReplyCountingTransport.swift`, in the Core framework, importing Foundation, swift-log and the MCP SDK, with no UI. It conforms to the MCP SDK's `Transport` protocol as an actor and needs no main-actor hop.
- **Compose**: Port as a class holding a `Mutex`-guarded `MutableSet<String>` and a list of `CompletableDeferred<Unit>`, wrapping the target's transport interface. The deadline is `withTimeoutOrNull(deadline)` around awaiting a deferred, with the same keys (`s:`, `n:`) for the two id kinds.
- **React/Web**: Port as a class around the MCP TypeScript SDK's `Transport` interface (`start`, `send`, `close`, and the `onmessage` callback). Count in `onmessage` before forwarding, pay in `send`. A `Set<string>` and an array of resolvers replace the actor; with one thread, no lock is needed. `waitUntilNothingOwed` is `Promise.race` between a resolver and `setTimeout`.
- **AppKit / UIKit**: Identical to the SwiftUI note; the type is UI-free, and apps on either toolkit use it for command-line or piped stdio serving, where there is no window.
- **WinUI 3**: Implement as a class wrapping the app's MCP transport interface, with a `lock` (or `SemaphoreSlim`) around a `HashSet<string>` and a list of `TaskCompletionSource`. Use `Task.WhenAny(tcs.Task, Task.Delay(deadline))` for the wait, and `JsonDocument.Parse` with `TryGetProperty` for the message fields, treating any parse failure as "not counted".

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/MCP/ReplyCountingTransport.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The wrapper counts requests itself, in the transport, rather than asking the SDK.
**Rationale**: The doc comment says swift-sdk 0.12.1 runs each request in an unstructured task and exposes no drain, so the wrapper is the only place that sees both every arriving request and every outgoing reply.
**Approved**: pending

**Decision**: A request is counted before it is yielded to the server.
**Rationale**: The comment says this ensures the server cannot answer a request before it is counted; the count and the yield happen in order in the pump task.
**Approved**: pending

**Decision**: A `notifications/cancelled` for an owed id pays the debt.
**Rationale**: The comment says the client has given up and MCP says the server need not answer a cancelled request, so waiting for a reply that will never come would hold the drain to its deadline.
**Approved**: pending

**Decision**: A string id and a number id are different keys (`s:` and `n:`).
**Rationale**: The comment says `"1"` and `1` are different ids in JSON-RPC, so the key records which kind arrived.
**Approved**: pending

**Decision**: Batches are not counted.
**Rationale**: The comment says the SDK answers a batch inside the receive loop, so its reply is already sent before the loop ends and there is nothing to wait for.
**Approved**: pending

**Decision**: `send` pays the debt in a `defer`, whether or not the wrapped `send` threw.
**Rationale**: A reply the transport cannot write will not be retried by the server, so continuing to wait for it could only run the drain to its deadline; the source states the mechanism but gives no further reason.
**Approved**: pending

**Decision**: `disconnect()` releases the waiters but leaves the owed set as it was.
**Rationale**: Nobody can wait on a closed transport, but `owedCount` stays an honest record of what went unanswered; the source does not state this reason, which is inferred from the code.
**Approved**: pending

**Decision**: Waiting is bounded by a caller-supplied deadline, and the wait returns whether everything was answered.
**Rationale**: A request that never completes must not hold the process open forever; the caller decides how long to wait and can tell whether it gave up.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | passed | Access Patterns |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | passed | Reliability |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |

`separation-of-concerns` passes: one small actor does one job, counting owed replies, and leaves serving, transport and the deadline policy to others. `timeout-configuration` and `timeout-handling` pass because the drain takes its deadline from the caller and always returns at it. `unit-test-coverage` passes: `HostMCPServerDrainTests` exercises the end-of-input drain, cancellation and the deadline, and `ReplyCountingTransportConformanceTests` drives a batch, a notification, string and number ids, a throwing wrapped `send`, an unknown cancelled id, `disconnect` with a waiter, and two waiters. `explicit-error-handling` is partial because unparseable messages are ignored silently and a throwing `send` pays the debt, both deliberate and recorded under Design Decisions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (ReplyCountingTransportConformanceTests.swift, 10 of 10 vectors; 001-003 already in HostMCPServerDrainTests); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Platforms name macOS, the source platform |
