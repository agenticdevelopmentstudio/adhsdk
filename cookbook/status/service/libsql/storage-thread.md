---
id: dccad63a-f56e-4c97-b182-8cdeb7c1a983
title: "Status Server Storage Thread"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Main-thread handle that spawns the database thread, waits for it to be ready, and hands out Storage ports to this thread and to any other thread."
platforms:
  - typescript
tags:
  - storage
  - worker-threads
  - libsql
  - concurrency
depends-on:
  - 020cc0f0-04e9-4d03-8796-76027fb1131f
  - e79dbcca-1d0e-41bd-a757-e0db8e5a5e8d
related:
  - bd58dfa4-13f8-4e92-adbe-45f8a020168d
references: []
approved-by: ""
approved-date: ""
---

# Status Server Storage Thread

## Overview

The storage thread module is the host's handle to the status server's database thread. The host calls `startStorageThread` once at boot, in place of opening a database connection itself. The call spawns a worker thread that runs the storage worker entry (see Storage Worker, [adhsdk.ingredient.status.service.libsql.storage-worker](cookbook:020cc0f0-04e9-4d03-8796-76027fb1131f)), waits until that thread has opened, tuned and migrated the database, and then connects the calling thread to it. From then on no thread but the database thread touches the database file; every other thread, the API thread and the monitor worker alike, uses the `Storage` port as a client over a `MessagePort`.

It exports:

- **the start function** (`startStorageThread`) — takes a database connection description and an `onExit` callback, and resolves to a storage thread handle.
- **the storage thread handle** (`StorageThread`) — a `storage` port for this thread and a `connect()` function that makes a new port for another thread.
- **three wire types** shared with the worker: `StorageWorkerData` (`{ db }`, the worker's start data), `StorageWorkerRequest` (`{ attach }`, a port to serve) and `StorageWorkerReply` (`{ ready: true }` or `{ ready: false, error }`).

The reason for the design is in Storage Remote ([adhsdk.ingredient.status.service.storage.remote](cookbook:e79dbcca-1d0e-41bd-a757-e0db8e5a5e8d)), in its `single-queue` requirement and its outage rationale: an embedded database connection runs statements on the calling thread and a lock wait blocks that thread, so a shared connection once froze the API event loop and caused an outage. Here the module's job is only spawn and attach policy; the queue and wire protocol live in Storage Remote, and the database work lives in the worker.

## Behavioral Requirements

### Spawning

- **entry-resolved-from-package**: The module MUST resolve the worker entry through the package's own `exports` (the specifier `@adh-sdk/status-server/storage-worker`) using `createRequire(import.meta.url).resolve`, never a relative path, so the entry is always the built output; the source gives the same reason as the monitor worker client ([adhsdk.ingredient.status.service.monitor.worker-client](cookbook:bd58dfa4-13f8-4e92-adbe-45f8a020168d), its spawn).
- **worker-data**: The module MUST start the worker with `workerData` of `{ db: conn }`, the connection description it was given, unchanged.
- **single-worker**: Each call MUST spawn exactly one worker thread.
- **no-connection-opened**: The module MUST NOT open a database connection on the calling thread.

### Waiting for ready

- **ready-resolves**: The start function MUST wait for the worker's first message and, when it is `{ ready: true }`, continue to connect this thread.
- **ready-false-rejects**: The start function MUST reject with `Error("storage thread failed to start: <error>")` when the first message is `{ ready: false, error }`, where `<error>` is the text the worker sent.
- **early-error-rejects**: The start function MUST reject with the worker's own error when the worker emits `error` before its first message (for example the worker's precondition throws, which post no reply).
- **no-timeout**: The start function MUST NOT impose a timeout of its own; it waits until the worker sends a message or emits `error`.
- **failed-start-leaves-worker**: When the start function rejects, it MUST NOT terminate the worker; see the Design Decision on a rejected start.
- **exit-before-ready-unhandled**: NEEDS REVIEW: Not implemented in source. Behavior undefined.

### After startup

- **on-exit-error**: After the start function has resolved the ready wait, the module MUST call `opts.onExit("storage thread crashed: <message>")` for each `error` event the worker emits.
- **on-exit-exit**: After the ready wait, the module MUST call `opts.onExit("storage thread exited (<code>)")` for each `exit` event, with the numeric exit code.
- **on-exit-may-repeat**: `onExit` MAY be called more than once for one failure, because a crash emits `error` and then `exit`; the module does not de-duplicate.
- **on-exit-is-fatal**: The module's contract is that a dead database thread makes every pending and later call reject, so the host SHOULD treat `onExit` as fatal; the module itself does not stop the host.
- **listeners-after-ready**: The `error` and `exit` listeners that call `onExit` MUST be attached after the ready wait completes, so a failed start is reported by the rejection and not also by `onExit`.

### Connecting

- **connect-new-channel**: Each call to `connect()` MUST create a new `MessageChannel`, post `{ attach: port1 }` to the worker with `port1` in the transfer list, and return `port2`.
- **connect-same-queue**: Every port made by `connect()` MUST be served by the same database thread and the same queue, so calls from every thread run one at a time in arrival order.
- **connect-sync**: `connect()` MUST return synchronously and MUST NOT wait for the worker to answer; the caller transfers the returned port to another thread and builds its client there.
- **connect-unbounded**: `connect()` MUST allow any number of calls over the life of the thread; the module keeps no count or list of ports.
- **connect-after-exit**: `connect()` called after the worker has exited MUST NOT throw; the attach request is dropped, so the returned port never receives a reply.
- **this-thread-port**: The start function MUST connect this thread by calling its own `connect()` once and passing the port to `connectStorage`, and MUST resolve with that result as `storage`.
- **storage-ready-on-hello**: The `storage` port MUST be usable when the start function resolves, because `connectStorage` resolves only after the worker has sent the method tree.
- **handle-shape**: The resolved handle MUST be an object of exactly `{ storage, connect }`.

### Calls through the port

- **port-behavior-is-remote**: A call through any port from this module MUST behave as Storage Remote ([adhsdk.ingredient.status.service.storage.remote](cookbook:e79dbcca-1d0e-41bd-a757-e0db8e5a5e8d)) specifies for `connectStorage`: `unclonable-args` for arguments that cannot be cloned, `error-flatten` and `error-rebuild` for errors that keep their detail, and `closed-port-client` (rejection with `storage connection closed`) once the database thread has gone. This module adds none of that behavior.
## Appearance

Not applicable — this is a thread-management module, not a visual component.

## States

Not applicable — this is a thread-management module, not a visual component.

## Accessibility

Not applicable — this is a thread-management module, not a visual component.

## Conformance Test Vectors

Every vector is covered by `test/storage-thread.test.ts`, which runs the module against a fake Worker that serves attached ports through the real Storage Remote server. `storage-thread.int.test.ts` › "migrates, serves two ports, and carries driver errors intact" also runs the real built thread under bare node (start, a store call, a second port, a duplicate-insert error, a monitor cycle, an empty `exits` list).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| sthread-001 | worker-data, single-worker, ready-resolves, handle-shape | start with `{ url: "file:status.db" }` and the worker answers `{ ready: true }` | one worker spawned with `workerData` of `{ db: { url: "file:status.db" } }`; resolves to `{ storage, connect }` (the integration test's start resolves and `exits` stays empty) |
| sthread-002 | ready-false-rejects | the worker answers `{ ready: false, error: "no such table" }` | rejects with `storage thread failed to start: no such table` |
| sthread-003 | early-error-rejects | the worker emits `error` with message `boom` before any message | rejects with that error |
| sthread-004 | failed-start-leaves-worker | after sthread-002 | the module made no `terminate` call, so the worker (`worker.threadId`) is still alive |
| sthread-005 | on-exit-error, listeners-after-ready | after a successful start, the worker emits `error` with message `oom` | `onExit` called once with `storage thread crashed: oom` |
| sthread-006 | on-exit-exit | after a successful start, the worker exits with code 1 | `onExit` called with `storage thread exited (1)` |
| sthread-007 | on-exit-may-repeat | a crash that emits `error` then `exit` | `onExit` called twice, once per event |
| sthread-008 | listeners-after-ready | the worker answers `{ ready: false }` and then exits | `onExit` is not called for the failed start |
| sthread-009 | connect-new-channel, connect-sync | `connect()` twice | two distinct ports returned at once; two `{ attach }` requests posted, each transferring one port (the test makes two ports with `connect()` and a client on the second reads what the first wrote) |
| sthread-010 | connect-same-queue | two ports each send a call at the same time | the calls run one after the other on the database thread, in arrival order |
| sthread-011 | this-thread-port, storage-ready-on-hello | start resolves | `storage` exposes the store methods the worker listed, as functions |
| sthread-012 | port-behavior-is-remote | the worker exits, then a call is made through `storage` | rejects with `storage connection closed` |
| sthread-013 | port-behavior-is-remote | a store method throws an error with `code` `SQLITE_CONSTRAINT` and a cause | the caller's error has the same `message`, `code` and `cause` (the test's duplicate insert reaches the caller with a message chain that `isUniqueViolation` recognises) |
| sthread-014 | entry-resolved-from-package | the module is loaded from source or from the built package | the worker entry is the built `storage-worker` file, not a path beside the source file |

## Edge Cases

- **Null and empty input — connection**: the module passes the connection to the worker as given; a connection with no `url` makes the worker throw at load, which the host sees as the worker's `error` event before any reply.
- **Boundary — repeated connects**: any number of ports may be attached; each adds a listener on the database thread but no new connection.
- **Boundary — double start**: calling the start function twice spawns two worker threads that each open the file; the module does not prevent it, and the host calls it once at boot (see the Design Decision on not guarding against a second start).
- **Malformed input — failed start**: a `{ ready: false }` reply rejects the start, and the module does not terminate the worker or attach an `onExit` listener afterwards.
- **Concurrent access**: calls from every attached port, and from this thread's own port, are serialised by one queue on the database thread, so a slow call holds up the rest; the slow-call log belongs to the worker (see Storage Worker, [adhsdk.ingredient.status.service.libsql.storage-worker](cookbook:020cc0f0-04e9-4d03-8796-76027fb1131f), `slow-call-warning`).
- **Cancellation and timeouts**: the start function takes no abort signal and has no timeout; a call through a port has none either, and an unanswered call stays pending until the port closes.
- **Error states — database thread death**: `onExit` fires; pending and later calls through every port reject with `storage connection closed`.
- **Error states — exit before ready**: see `#requirements/exit-before-ready-unhandled`; no `exit` listener is attached during the ready wait.
- **Offline**: not applicable — the database is a local file or a connection the worker owns; the module itself performs no network I/O.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `conn` | `LibsqlConnection` (`url`, optional `authToken`) | none — required | The database to open, handed to the worker unchanged as `workerData.db`. |
| `opts.onExit` | function taking a reason string | none — required | Called after startup when the database thread errors or exits. The host SHOULD treat it as fatal. |
| Worker entry | package export `@adh-sdk/status-server/storage-worker` | fixed | Not configurable. |

The module reads no environment variables or settings.

## Deep Linking

Not applicable: the module registers no route or URL.

## Localization

Not applicable: the module's error messages (`storage thread failed to start`, `storage thread crashed`, `storage thread exited`) are English diagnostics for logs, not user-facing text.

## Accessibility Options

Not applicable: the module has no visual output.

## Feature Flags

Not applicable: no behavior is gated by a flag.

## Analytics

Not applicable: the module emits no events.

## Privacy

The module passes a connection description, which may include an authentication token (`authToken`), to the worker thread in the same process, and stores or sends nothing else. It never logs `workerData`, and the host MUST NOT log it either. Reasons surfaced to `onExit` carry thread error text, which may include driver text, so the host decides how to log them.

## Logging

The module does not log. Failures reach the host as a rejection (a failed start) or through `opts.onExit` (a later crash or exit). The slow-call warning is logged from the worker and belongs to Storage Worker ([adhsdk.ingredient.status.service.libsql.storage-worker](cookbook:020cc0f0-04e9-4d03-8796-76027fb1131f), `slow-call-warning`), not to this module.

## Platform Notes

- **SwiftUI**: Port as an actor that owns the database and serves one call at a time; `startStorageThread` becomes an `async` initialiser that opens, tunes and migrates the database inside the actor and returns once ready. `connect()` has no counterpart when all callers share a process, because actor isolation already gives one queue; hand the same actor reference to the other components. Surface death of the database as a thrown error on every later call.
- **Compose**: Use a single-threaded `CoroutineDispatcher` (`newSingleThreadContext`) or a `Mutex`-guarded repository as the one queue. The start function is a `suspend` function that opens and migrates on that dispatcher and returns the repository; `connect()` is not needed in one process. Treat an uncaught exception in the dispatcher as the `onExit` event.
- **React/Web**: Source platform. `packages/web/packages/status-server/src/libsql/storage-thread.ts` uses Node `worker_threads` (`Worker`, `MessageChannel`, `MessagePort`) and `createRequire` to resolve the built worker entry. It is Node-only: a browser has no such module. The module is driven by the host at boot and its worker is `storage-worker.ts` beside it; the monitor worker receives a port made by `connect()` (see the monitor worker client recipe).
- **AppKit / UIKit**: The same actor design as SwiftUI; AppKit adds nothing, because there is no UI here. If the database must not block the main thread, keep the actor off `MainActor`.
- **WinUI 3**: Use one dedicated worker, for example a `Channel<Func<Task>>` read by a single long-running `Task` (or a `SemaphoreSlim(1,1)` around the connection), as the one queue; callers `await` replies and never touch the connection. `StartStorageThreadAsync` is an `async Task<StorageThread>` that opens, tunes and migrates the database and returns when ready, surfacing a failed start as an exception with the message `storage thread failed to start: <error>`. There is no thread-to-thread port transfer inside one .NET process, so `Connect()` is replaced by sharing the one service instance through dependency injection. Report the database thread's death with an `Action<string> onExit` called from the task's `ContinueWith` on `IsFaulted`. For a process-per-service split, use a named pipe with `System.Text.Json` messages in place of the `MessagePort`. Dispose the connection on shutdown, and keep the UI thread free of database calls; marshal results back with `DispatcherQueue.TryEnqueue`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-server/src/libsql/storage-thread.ts` | confirmed (1.0.2) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: One thread owns the database file and every other thread is a client of it.
**Rationale**: Storage Remote ([adhsdk.ingredient.status.service.storage.remote](cookbook:e79dbcca-1d0e-41bd-a757-e0db8e5a5e8d)) records the outage this prevents: an embedded connection runs statements on the calling thread and a lock wait spins there for up to the busy timeout, so a read that met a write or checkpoint froze the API event loop, `/health` timed out and the supervisor restarted the container. Behind the thread, callers only await a reply.
**Approved**: pending

**Decision**: The host starts the thread once at boot and does not open a connection itself.
**Rationale**: The header comment of `storage-thread.ts`: from then on "no thread but that one touches the database file", which removes lock contention between threads.
**Approved**: pending

**Decision**: The worker entry is resolved through the package's `exports`, never a relative path.
**Rationale**: The comment in `startStorageThread`: the entry is always the built output, the same reason as `MonitorWorkerClient.spawn` ([adhsdk.ingredient.status.service.monitor.worker-client](cookbook:bd58dfa4-13f8-4e92-adbe-45f8a020168d)). A relative path would load TypeScript source in a worker.
**Approved**: pending

**Decision**: `connect()` is synchronous and returns a transferable port.
**Rationale**: The host passes the port to another thread as a transfer, and that thread builds its own client. Each port is served by the same queue, so there is one lock and no contention.
**Approved**: pending

**Decision**: The module reports a later death through `onExit` and treats it as fatal.
**Rationale**: The doc comment on `startStorageThread`: once the thread dies, "every pending and later call then rejects, so the host should treat it as fatal." A server with no database cannot answer correctly, so it is left to the supervisor to restart it.
**Approved**: pending

**Decision**: A failed start is reported by the rejection, and `onExit` listeners are attached only after the ready wait.
**Rationale**: The two reporting paths do not overlap: a start failure reaches the caller through the returned promise, and a later failure reaches the host through the callback.
**Approved**: pending


**Decision**: A rejected start does not terminate the worker.
**Rationale**: The source has no cleanup on that path, and ending the process is left to the host; the source gives no further reason. A worker left alive after a failed start can keep the process running, so a host that survives a failed start should end the process itself. Recorded here for review, not as a settled choice.
**Approved**: pending

**Decision**: The module does not guard against a second start.
**Rationale**: The host calls `startStorageThread` once at boot, and the source adds no check. A second call would spawn a second worker that opens the same file, which breaks the one-owner design; the source gives no reason for omitting a guard. Recorded here for review.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | privacy-and-data |

**Separation of Concerns**: The module only spawns the worker, waits for ready and attaches ports. The queue and wire protocol are in the Storage Remote module, and the database work is in the worker, so each has one reason to change.

**Unit Test Coverage**: `test/storage-thread.test.ts` covers vectors 001 to 014 against a fake Worker that serves ports through the real Storage Remote server: the start and its failures, `onExit` for crash and exit, `connect()`, the shared queue, a call after the thread dies, error fidelity, and the package-resolved entry. `storage-thread.int.test.ts` still runs the real built thread under bare node.

**No PII in Logs**: The module logs nothing; its failure reasons contain thread error text and no user data.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (storage-thread.test.ts, 14 of 14 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Replaced the three restated port requirements with one dependency on Storage Remote, linked Storage Remote, Storage Worker and the monitor worker client, moved the slow-call log to Storage Worker, recorded two Design Decisions (rejected start, second start), stated the privacy rule, and set tags and platforms. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial recipe extracted from `storage-thread.ts` |
