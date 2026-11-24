---
id: e79dbcca-1d0e-41bd-a757-e0db8e5a5e8d
title: "Remote Storage over a MessagePort"
type: ingredient
version: 1.0.3
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A Storage port carried over a worker-thread MessagePort: a FIFO server that owns the database and a client of stub methods, with errors flattened over the wire."
platforms:
  - typescript
  - web
tags:
  - status
  - storage
  - worker-thread
  - rpc
depends-on:
  - 1c240b7a-21b3-4a89-b24f-a5bf5cf5f37b
related:
  - 6bf27f64-59d0-4b2a-8715-92dba2856814
  - 82524881-6da8-42fe-85a9-388651ee085d
  - 5cb60b95-0a8b-43c8-a747-cb5ca7353f09
references: []
approved-by: ""
approved-date: ""
---

# Remote Storage over a MessagePort

## Overview

The `Storage` port carried over a Node `MessagePort`, so the thread that owns the database can differ from the threads that use it. An embedded `file:` libSQL connection runs every statement synchronously on the calling thread, and a lock wait spins there for up to the busy timeout (5 seconds). When a user thread holds its own connection, a read that meets another thread's write or WAL checkpoint freezes that thread's event loop, so a health check on it can time out and a supervisor can restart the process. Behind this transport a user thread only awaits a reply, and the database thread is the only one that blocks.

Two functions form the contract: `createStorageServer(storage)` runs on the database thread and answers calls from any number of ports through one queue, and `connectStorage(port)` runs on a user thread and returns a `Storage` whose every method is a request over the port. The code is driver-agnostic: it serves whatever `Storage` it is handed and never names libSQL.

## Behavioral Requirements

- **shape-handshake**: `serve(port)` MUST send one `{ shape }` message on the port, where `shape` is the method tree of the served `Storage`: `true` for a callable and a nested object for a nested store such as `telemetry.errors`.
- **shape-walk**: The shape MUST include a method defined on the object's own keys or on its prototype (excluding `constructor`), MUST nest any object-valued property, and MUST omit every other property.
- **stub-build**: `connectStorage` MUST resolve only after it receives the shape, and MUST build plain stub functions from it, not a catch-all Proxy, because `await` on a Proxy would mistake it for a thenable.
- **call-wire**: Each stub call MUST post `{ id, path, args }` with a fresh numeric id per call and MUST return a promise that settles from the matching reply.
- **reply-match**: A reply MUST settle the pending call with the same id and remove it. A reply for an unknown id MUST be ignored.
- **single-queue**: The server MUST run calls one at a time in arrival order, across every served port, through one queue, so one call's statements never interleave with another's on the shared connection.
- **queue-survives-errors**: A call that throws MUST NOT stop the queue; the next call still runs.
- **value-roundtrip**: Arguments and results MUST pass through structured clone, so values such as `Date` survive the round trip as the same type.
- **nested-dispatch**: The server MUST resolve `path` from the storage root, apply the final key as a method on its parent object (so `this` is the parent), and await its result.
- **error-flatten**: A call that throws MUST reply `{ ok: false, error }` with `name`, `message`, optional `stack` and optional `code` (converted to a string), plus the `cause` chain flattened to at most four causes below the error itself (five errors in all). This is the cause cap, a literal 4 in the source; the Design Decisions and Edge Cases refer to it and do not restate the number.
- **error-rebuild**: The client MUST reject with an `Error` rebuilt from the wire form: same `name`, `message`, `stack` and `code`, with a rebuilt `cause` chain, so callers that match on message, code or cause (such as `isUniqueViolation`) keep working.
- **non-error-throw**: A thrown value that is not an `Error` MUST reach the caller as an `Error` named `Error` whose message is `String(value)`.
- **unclonable-args**: When the arguments cannot be structured-cloned (such as a function among them), the client MUST reject that call with the clone error and MUST NOT leave an entry pending.
- **unclonable-result**: When the server cannot post a result, it MUST post an error reply for that id instead, so the caller is never left waiting on that result. The reply is the wire form of the clone error the failed post threw: its `name` (a `DataCloneError`) and its `message`.
- **slow-call-log**: The server MUST log a `console.warn` line `[storage] slow call <path> <ms>ms` for any call that took 2,000 ms or more, where `<path>` is the call's path segments joined with `.` and `<ms>` is the elapsed whole milliseconds, because one slow call holds up the whole queue.
- **closed-port-server**: The server detects a close only through the port's `close` event. When a served port closes, the server MUST remove its message listener; replies to a closed port are dropped, and other ports keep being served.
- **closed-port-client**: The client detects a close only through the port's `close` event; it does not listen for `messageerror`, and an owning thread that exits is seen only because Node closes its port. When the client's port closes, every pending call MUST reject with `storage connection closed`, and every later call MUST reject with the same error without posting.
- **connect-failure**: When the port closes before the shape arrives, the promise from `connectStorage` MUST reject with `storage connection closed`.
- **driver-agnostic**: The module MUST NOT import or name any database driver; it MUST depend only on the `Storage` type and `node:worker_threads` types.

## Appearance

Not applicable — this is a storage transport, not a visual component.

## States

Not applicable — this is a storage transport, not a visual component.

## Accessibility

Not applicable — this is a storage transport, not a visual component.

## Conformance Test Vectors

Vectors 001 to 018 are traced to `storage-remote.test.ts`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| storage-remote-001 | call-wire, value-roundtrip | Call a method with arguments including a `Date`, over a connected pair | The server receives the same values, and the result reaches the caller with the `Date` still a `Date` |
| storage-remote-002 | shape-walk, nested-dispatch | Call `telemetry.errors.<method>` on the stub | The nested store's method runs with its own `this` and its result returns |
| storage-remote-003 | error-flatten, error-rebuild | A method throws an `Error` with a `code` and a `cause` | The caller's rejection has the same message, and its `cause` has the same message and `code` |
| storage-remote-004 | single-queue | Two ports each issue calls whose handlers resolve out of order | The handlers run one at a time in arrival order across both ports |
| storage-remote-005 | unclonable-args | Call with a function among the arguments | Rejects with the clone error (the source also deletes the pending entry before rejecting) |
| storage-remote-006 | closed-port-client | The server side closes while a call is pending | The pending call rejects with `storage connection closed` |
| storage-remote-007 | queue-survives-errors | A call that throws, then a call that succeeds on the same port | The first rejects, the second resolves |
| storage-remote-008 | non-error-throw | A method throws the string `boom` | The caller receives an `Error` named `Error` with message `boom` |
| storage-remote-009 | slow-call-log | A call that takes 2,500 ms | With a fake clock that advances 2,500 ms across the call, one warning matching `/^\[storage\] slow call a\.b \d+ms$/` is logged for a method at path `a.b` (exactly `[storage] slow call a.b 2500ms`), and the reply is still delivered |
| storage-remote-010 | shape-handshake, shape-walk | `serve(port)` for a storage with a method `a`, a nested store `n` holding a method `b` and a number `c`, and a number `d` | The first message on the port is `{ shape: { a: true, n: { b: true } } }` |
| storage-remote-011 | stub-build | `connectStorage(port)` before the shape arrives, then after | The promise is pending until the shape arrives; the resolved `Storage` has no `then` property, so `await` does not treat it as a thenable, and its methods are plain functions |
| storage-remote-012 | reply-match | After the shape, a reply `{ id: 999, ok: true, value: 1 }` for an id that is not pending, while a real call is pending | The unknown reply is ignored, and the pending call still settles from its own reply |
| storage-remote-013 | unclonable-result | A store method that returns a function | The caller's call rejects with a `DataCloneError` instead of hanging, and the next call still runs |
| storage-remote-014 | closed-port-server | Two ports served; the first port closes | The server stops listening on the first port and later messages on it are not answered; the second port is still served |
| storage-remote-015 | connect-failure | The port closes before the shape message | `connectStorage` rejects with `storage connection closed` |
| storage-remote-016 | error-flatten, error-rebuild | A method throws an error with a `cause` chain of seven errors in all | The caller's rejection has five errors in its chain (the error and four causes); the deeper causes are dropped |
| storage-remote-017 | error-flatten | A method throws an error with the numeric `code` 5 | The caller's rejection has `code` `'5'`, a string |
| storage-remote-018 | driver-agnostic | The module's imports | Only the `Storage` type from `./ports` and `node:worker_threads` types are imported; no database driver is imported or named in code (comments aside) |
## Edge Cases

- A hung call blocks the queue for every port; there is no per-call timeout and no cancellation. The only signal is the slow-call warning, which is logged after the call finishes.
- A `path` that names no method, or a missing nested store, throws a `TypeError` on the server; it is flattened and rejects that call, and the queue continues.
- A `cause` chain deeper than the cause cap in `error-flatten` is cut at the cap; the deeper causes are dropped.
- A thrown non-`Error` loses its type, `code` and `cause`; only its string form survives.
- `code` is converted to a string on the wire, so a numeric code arrives as text.
- Class instances in arguments or results lose their prototype through structured clone, and `Date`, `Map`, `Set` and typed arrays survive.
- A port that closes while the server is running a call for it: the reply post is dropped, the queue continues and the call's side effect still happened.
- A call made through a stub after the client port closes rejects immediately and sends nothing.
- A second `serve` on a new port while others are active joins the same queue; there is one queue per server, not one per port.
- A message that arrives before the shape (not produced by this server) is read as a reply and ignored, since no entry is pending.
- The fallback error reply for an unclonable result is posted without a guard: if that post also throws, the exception is not caught inside the call runner.
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `storage` | `Storage` | required | The store the server serves, passed to `createStorageServer` |
| `port` | `MessagePort` | required | The port passed to `serve` (one per user thread) or to `connectStorage` |
| `SLOW_CALL_MS` | number | 2000 | Duration at which a call is logged as slow; a module constant, not configurable by the caller |

## Deep Linking

Not applicable: the module is an in-process thread transport with no addressable surface.

## Localization

Not applicable: the module holds no user-facing strings; the one error it creates, `storage connection closed`, is a developer-facing message.

## Accessibility Options

Not applicable: the module has no rendering.

## Feature Flags

Not applicable: the module reads no flag.

## Analytics

Not applicable: the module emits no events.

## Privacy

Not applicable: the module handles no credential, and the data it carries stays between threads of one process.

## Logging

Logging is a single `console.warn` on the server for a slow call.

| Event | Level | Message |
|-------|-------|---------|
| A call took 2,000 ms or more | warn | `[storage] slow call <path joined with dots> <ms>ms` |

## Platform Notes

- **SwiftUI**: Use an `actor` that owns the store and serves calls from a `Task` queue; actor isolation gives the one-at-a-time rule, and the client can be a `Sendable` wrapper that calls `await actor.method(...)`. Errors cross as `Error` values, so no flattening is needed in process.
- **Compose**: Use a single-thread `CoroutineDispatcher` (or a `Mutex`) around the store for the FIFO rule, and a `Channel` of request objects when the clients run in other processes. Throwable causes are available on the JVM as is.
- **React/Web**: In a browser use a Web Worker with a `MessageChannel`; the same shape handshake and id-matched replies apply. In Node keep `worker_threads` as in the source.
- **AppKit / UIKit**: Use a serial `DispatchQueue` that owns the store and `async` wrappers over it; a serial queue gives the FIFO rule.
- **WinUI 3**: Use a `System.Threading.Channels.Channel<Call>` with one reader loop as the single queue, and `TaskCompletionSource<object?>` per call id on the client. Serialise values with `System.Text.Json` when crossing a process boundary, and flatten exceptions to `name`, `message`, `HResult` as the code, and the `InnerException` chain. In an ASP.NET Core host the database owner is an `IHostedService` that reads the channel.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-server/src/storage/remote.ts` | confirmed (1.0.3) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: One queue, one connection.
**Rationale**: A single FIFO queue means no statement can contend for a lock and an async store method's statements never interleave with another call's, at the cost of throughput. The source records the reason it exists: on 2026-10-22 an API thread with its own connection froze on another thread's write, its `/health` check timed out, and the supervisor restarted the container.
**Approved**: pending

**Decision**: Shape handshake instead of a Proxy.
**Rationale**: Sending the method tree once lets the client build plain stubs; a catch-all Proxy would look like a thenable to `await`.
**Approved**: pending

**Decision**: Flattened error with code and cause.
**Rationale**: Callers match on message, code and the cause chain, so all three cross the wire, and the chain is bounded by the cause cap in `error-flatten` to bound the payload.
**Approved**: pending

**Decision**: No timeout, accepted as known debt.
**Rationale**: A call runs until its store method settles; a hang is logged by neither side until it ends, because the queue's purpose is serialisation, not supervision. This is deliberate debt, not a settled design: revisit it when a call is seen to hang for far longer than the 5 second busy timeout (the slow-call warning shows a duration well past it) or when calls queue up behind a hung one, and then add a per-call timeout or cancellation.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.access-patterns.timeout-configuration](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dc15eb62-a72c-5b09-b9e7-c1bed983f499) | failed | Access Patterns |

The transport is driver-agnostic and separate from any store, and `storage-remote.test.ts` has a test for every vector, 001 to 018, so unit-test coverage passes. Errors are flattened and rebuilt with code and cause, and every failure path rejects its caller. There is no per-call timeout, so a hung store method blocks the shared queue; the slow-call warning is the only mitigation.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.3 | 2026-11-14 | Mike Fullerton | Conformance tests added (storage-remote.test.ts, 18 of 18 vectors); unit-test-coverage now passed. |
| 1.0.2 | 2026-11-14 | Mike Fullerton | Marked "No timeout" as known debt with a revisit condition, set unit-test-coverage to partial, made the Overview general and moved the 2026-10-22 outage into a rationale, moved the Storage port to depends-on, fixed the blank lines in Design Decisions, added vectors 010 to 018, pinned the slow-call path and ms format, named the close event, defined the unclonable-result reply, and stated the cause cap once. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Each design decision carries its own approval line |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
