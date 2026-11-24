---
id: 020cc0f0-04e9-4d03-8796-76027fb1131f
title: "Status Server Storage Worker"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Database-thread entry that owns the one libSQL connection, migrates it, and serves the Storage port to every other thread through one queue"
platforms:
  - typescript
  - web
tags:
  - storage
  - libsql
  - worker-threads
  - concurrency
depends-on:
  - e79dbcca-1d0e-41bd-a757-e0db8e5a5e8d
related:
  - dccad63a-f56e-4c97-b182-8cdeb7c1a983
references: []
approved-by: ""
approved-date: ""
---

# Status Server Storage Worker

## Overview

The storage worker is the entry module of the status server's database thread. It runs inside a `worker_threads` `Worker` spawned by `startStorageThread` (in `storage-thread.ts`, see Storage Thread, [adhsdk.ingredient.status.service.libsql.storage-thread](cookbook:dccad63a-f56e-4c97-b182-8cdeb7c1a983)). It opens the ONE connection to the database file, tunes it, applies pending migrations, wraps the connection as a `Storage` port, and serves that port to every thread that attaches over a `MessagePort`. Every other thread (the API thread, the monitor worker) reaches the database only as a client of this thread. Per the source comment, this file is "Glue only": spawn and attach policy live in `storage-thread.ts`, the queue and wire protocol live in `storage/remote.ts` (Storage Remote, [adhsdk.ingredient.status.service.storage.remote](cookbook:e79dbcca-1d0e-41bd-a757-e0db8e5a5e8d)), and the connection helpers live in `libsql/client.ts`. The module has no exports; its only outputs are a single `StorageWorkerReply` posted to the parent and the attach handling described below.

## Behavioral Requirements

### Preconditions at module load

- **requires-worker-context**: The module MUST throw an `Error` with the message `storage worker must be spawned via worker_threads (see storage-thread.ts)` when `parentPort` from `node:worker_threads` is null (the module was loaded on the main thread).
- **requires-db-url**: The module MUST throw an `Error` with the message `storage worker spawned without workerData.db.url (see StorageWorkerData)` when `workerData` is missing, `workerData.db` is missing, or `workerData.db.url` is falsy (including the empty string).
- **precondition-throws-are-unreplied**: The two precondition errors above MUST be thrown at module top level, outside the startup `try` block, so no `StorageWorkerReply` is posted for them; the host observes them as the Worker's `error` event.
- **worker-data-shape**: The module MUST read its configuration from `workerData` as a `StorageWorkerData`, that is `{ db: LibsqlConnection }`, where `LibsqlConnection` is `{ url: string; authToken?: string }`.

### Startup sequence

- **startup-order**: The module MUST run these steps in this order and each step MUST complete before the next begins: `openLibsql(conn)`, `tuneDbForConcurrency(db, conn)`, `migrateDb(db)`, `createStorageServer(createLibsqlStorage(db, conn))`, attach the `message` listener, post the ready reply.
- **single-connection**: The module MUST open exactly one database connection, via one `openLibsql` call, and MUST pass that same connection to tuning, migration and `createLibsqlStorage`.
- **tune-before-migrate**: The module MUST apply `tuneDbForConcurrency` before `migrateDb`. What `tuneDbForConcurrency` does to the connection belongs to `libsql/client.ts`, not to this module.
- **self-migrate-on-boot**: The module MUST call `migrateDb(db)` with the default migrations folder on every boot, for every connection kind, per the source comment "embedded-file deployments self-migrate on boot". `migrateDb` is idempotent, because drizzle skips migrations already recorded in `__drizzle_migrations`.
- **storage-composition**: The module MUST build the served `Storage` with `createLibsqlStorage(db, conn)` and MUST wrap it with `createStorageServer` exactly once, so every attached port shares one server and therefore one FIFO queue.
- **ready-after-listener**: The module MUST attach the `message` listener on the parent port before it posts `{ ready: true }`, so a listener is already in place when the host sees the ready reply.
- **ready-reply**: On successful startup the module MUST post exactly `{ ready: true }` to the parent port, once.

### Startup failure

- **startup-failure-reply**: When any startup step (open, tune, migrate, storage or server construction) throws or rejects, the module MUST post `{ ready: false, error: <message> }` to the parent port, where `<message>` is `err.message` for an `Error` and `String(err)` for any other thrown value.
- **startup-failure-no-listener**: When startup fails, the module MUST NOT attach the `message` listener, so no attach request is served.
- **startup-failure-no-exit**: Current behavior: on startup failure the module calls no `process.exit`, `port.close` or other termination; it does nothing to end the worker after posting the failure reply (it attaches no listener either), and ending it is the host's decision.
- **startup-failure-no-log**: Current behavior: the module does not log a startup failure; the posted reply is the only signal. The host (`startStorageThread`) turns it into `Error("storage thread failed to start: <error>")`.

### Serving

- **attach-request**: For each message received on the parent port, the module MUST treat it as a `StorageWorkerRequest` (`{ attach: MessagePort }`) and call `server.serve(msg.attach)` once.
- **attach-no-validation**: Current behavior: the module does not validate the shape of a received message; the `StorageWorkerRequest` type is the documented contract, and the host's `connect()` is the only sender.
- **attach-multiplicity**: The module MUST accept any number of attach requests over the life of the thread, one per connecting thread, each served by the same server and queue.
- **serving-is-remote**: Everything about how an attached port is served MUST be as Storage Remote ([adhsdk.ingredient.status.service.storage.remote](cookbook:e79dbcca-1d0e-41bd-a757-e0db8e5a5e8d)) specifies for `createStorageServer`: `single-queue` (one call at a time, in arrival order, with no interleaving), `shape-handshake` (the `{ shape }` hello on attach), `error-flatten` (errors that keep their detail) and `slow-call-log` (the 2000 ms warning). This module adds none of that behavior; it only wraps the storage once (`storage-composition`).

### Runtime failure

- **post-startup-throws-uncaught**: The host MUST treat a throw inside the worker's `message` listener after startup as the end of the worker: the module has no handler for it, so it is an uncaught exception in the worker thread, which ends the worker and surfaces on the host as the Worker's `error` and `exit` events (`startStorageThread` forwards both to `opts.onExit`).
- **no-restart**: The module MUST NOT reopen or retry the connection after startup; recovery from a dead database thread is the host's responsibility.

## Appearance

Not applicable — this is a database-thread entry point, not a visual component.

## States

Not applicable — this is a database-thread entry point, not a visual component. Its runtime lifecycle (booting, ready, failed) is captured under Behavioral Requirements: booting runs the startup sequence, `ready` is reached when `{ ready: true }` is posted, and `failed` is reached when `{ ready: false, error }` is posted or a precondition throws.

## Accessibility

Not applicable — this is a database-thread entry point, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| status-server-libsql-storage-worker-001 | startup-order, self-migrate-on-boot, ready-reply, attach-request, attach-multiplicity | Spawn the built worker with `workerData = { db: { url: "file:<tmpdir>/status.db" } }` on a fresh directory, wait for the first message, then post two `{ attach: port }` requests | First message deep-equals `{ ready: true }`; the file is created and migrated; each attached port receives a `{ shape }` hello; a user insert through one port is readable through the other — `storage-thread.int.test.ts` › "migrates, serves two ports, and carries driver errors intact" (result `foundSame: true`, `createdAtIsDate: true`) |
| status-server-libsql-storage-worker-002 | serving-is-remote | Through a served port, insert the same unique value twice (for example a duplicate email) | The second call rejects with an Error whose `message`/`cause` chain makes `isUniqueViolation` return `true` — `storage-thread.int.test.ts` (result `dupChain`) |
| status-server-libsql-storage-worker-003 | serving-is-remote, storage-composition | A monitor worker handed only a storage port runs one monitor cycle against the worker | The cycle completes with `cycle: "ok"` and the worker reports `exits: []` (no thread died) — `storage-thread.int.test.ts` |
| status-server-libsql-storage-worker-004 | requires-db-url, precondition-throws-are-unreplied | Spawn the worker with `workerData = {}` | The Worker emits `error` with message `storage worker spawned without workerData.db.url (see StorageWorkerData)`; no message is posted to the parent — traced to the module's top-level guard; no test given |
| status-server-libsql-storage-worker-005 | requires-db-url | Spawn the worker with `workerData = { db: { url: "" } }` | Same `error` event and message as vector 004 (an empty url is falsy) — traced directly to the guard; no test given |
| status-server-libsql-storage-worker-006 | requires-worker-context | Import the module on the main thread (`parentPort` is null) | Import throws `storage worker must be spawned via worker_threads (see storage-thread.ts)` — traced directly to the guard; no test given |
| status-server-libsql-storage-worker-007 | startup-failure-reply, startup-failure-no-listener, startup-failure-no-exit | Spawn the worker with `workerData = { db: { url: "file:/nonexistent-dir/x/status.db" } }` so opening or tuning throws | First message is `{ ready: false, error: <the Error's message> }`; later attach requests receive no `{ shape }` hello; the module does not call exit or close — traced to the `catch` branch; no test given |
| status-server-libsql-storage-worker-008 | startup-failure-reply | A startup step throws a non-Error value; the module has no seam to inject one, so trigger it with a module mock of `openLibsql` that throws the string `"boom"` (not runnable against the built worker without that mock) | Reply is `{ ready: false, error: "boom" }` — traced to `String(err)` in the `catch` branch; no test given |
| status-server-libsql-storage-worker-009 | serving-is-remote, attach-multiplicity | Two attached ports each send a call at the same time | The calls complete one after the other in arrival order (FIFO), with no interleaving of their statements; derived from Storage Remote's `single-queue`, no test given |
## Edge Cases

- **Null and empty input**: `workerData` undefined, `workerData.db` undefined, or `db.url` equal to `""` MUST throw the `requires-db-url` error at load, with no reply posted. An `authToken` that is absent is valid and is passed through to `openLibsql` as `undefined` — MUST.
- **Boundary values**: The slow-call warning at 2000 ms and the `busy_timeout` that bounds a lock wait belong to Storage Remote ([adhsdk.ingredient.status.service.storage.remote](cookbook:e79dbcca-1d0e-41bd-a757-e0db8e5a5e8d), `slow-call-log`) and to `tuneDbForConcurrency` in `libsql/client.ts`.
- **Concurrent access**: Many threads can attach and call at once. The server serialises every call through one FIFO queue on the one connection, so calls never contend for a lock and never interleave their statements — MUST. Within the worker thread itself JavaScript is single-threaded, so the `message` listener cannot race itself.
- **Error states**: A failed open, tune, migrate or construction posts the `ready: false` reply, attaches no listener and does not end the worker itself — MUST. A Storage call that throws is returned to its caller as a wire error and does not stop the queue — MUST. A result the structured clone cannot carry is reported to the caller as an error reply rather than left hanging — MUST (`createStorageServer`). A malformed attach message, or any throw in the listener after startup, is an uncaught exception that ends the worker, and the host's `onExit` is the only recovery path — this is the behavior of the code, not an additional guarantee.
- **Offline or disconnected state**: For an embedded `file:` URL there is no network to lose. For a remote libSQL URL, a failure to reach the server during open or migration (tuning is a no-op for remote URLs) surfaces through the startup failure path; a failure during a later Storage call surfaces to that call's caller as a wire error. The worker performs no reconnection or retry of its own — MUST NOT.
- **Port lifetime**: An attached port whose thread exits stops sending; the server removes its `message` listener when the port closes and drops any reply addressed to it — MUST (`createStorageServer`).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `workerData.db.url` | `string` | none, required | Database location: `file:<path>` for an embedded SQLite file, or an https/libsql URL for remote libSQL. An empty or missing value throws at load. |
| `workerData.db.authToken` | `string \| undefined` | `undefined` | Auth token for a remote libSQL URL, passed to `openLibsql`. |
| `StorageWorkerRequest.attach` | `MessagePort` | none, required per message | The port a connecting thread is served on; transferred in the message's transfer list. |
| Migrations folder | path | `MIGRATIONS_FOLDER` from `client.ts` | Not configurable here; `migrateDb(db)` is called with the default. |
| PRAGMA settings | fixed | WAL, `busy_timeout` 5000, `synchronous` NORMAL | Applied only to `file:` URLs by `tuneDbForConcurrency`; not configurable here. |

## Deep Linking

Not applicable: the worker defines no URL scheme, route or navigable target; it exchanges messages with its parent thread only.

## Localization

Not applicable: the worker's strings (the two precondition errors and the `[storage] slow call` warning) are developer-facing diagnostics, not user-facing text; a startup `error` string is relayed to the host, which wraps it in its own error message.

## Accessibility Options

Not applicable: the worker has no UI and responds to none of Reduce Motion, Increase Contrast or Differentiate Without Color.

## Feature Flags

Not applicable: the source consults no feature-flag system; its only inputs are `workerData` and the attach messages.

## Analytics

Not applicable: the source emits no analytics or telemetry events.

## Privacy

The worker holds `workerData.db.authToken`, a credential for remote libSQL, in memory and passes it to `openLibsql`; it never logs, posts or stores it, and the startup failure reply carries only an error message. The database file itself holds the application's stored data; where that is stored (the `file:` path) and how it leaves the device are decided by the host and by the `Storage` implementation, not by this file.

## Logging

The worker itself logs nothing; its signals are the `StorageWorkerReply` message and thrown errors. The one log line produced while it runs comes from the `createStorageServer` it hosts.

Subsystem: none | Category: `storage`

| Event | Level | Message |
|-------|-------|---------|
| A single Storage call takes 2000 ms or more | warn | `[storage] slow call <path> <ms>ms` |

## Platform Notes

- **SwiftUI**: not a UI concern. An Apple companion would host the database behind a Swift `actor` that owns one SQLite or libSQL connection (for example through GRDB's `DatabaseQueue` or `DatabasePool`), so calls from any thread are serialised in arrival order; the `{ ready, error }` reply maps to an `async throws` initializer that migrates before returning.
- **Compose**: not a UI concern. A Kotlin port would run the database on one single-threaded dispatcher (`Executors.newSingleThreadExecutor().asCoroutineDispatcher()`) or a `Mutex`-guarded repository, with Room's `RoomDatabase.Builder.setQueryExecutor` pinned to that executor; startup failure maps to a thrown exception from a suspending `open()` function.
- **React/Web** (source platform): the code is `packages/web/packages/status-server/src/libsql/storage-worker.ts`, a Node `worker_threads` entry built into the package's `dist` and resolved by the host through the package export `@adh-sdk/status-server/storage-worker`. It uses top-level `await`, `workerData`, `parentPort` and `MessageChannel` ports, and relies on `storage/remote.ts` for the FIFO queue and on `libsql/client.ts` for drizzle and libSQL.
- **AppKit / UIKit**: not a UI concern. On macOS or iOS prefer the same actor-owned connection as the SwiftUI note, and keep database work off the main actor so a lock wait cannot freeze the UI, which is the failure the source's design prevents for the API event loop.
- **WinUI 3**: a .NET host would own the database in a singleton service started by an `IHostedService` (`StartAsync` opens, applies `PRAGMA journal_mode=WAL`, `busy_timeout` and `synchronous`, then runs migrations, for example EF Core `Database.MigrateAsync()`, before reporting ready). Serialise every call through a single `System.Threading.Channels.Channel<Func<Task>>` read by one consumer loop, or a `SemaphoreSlim(1,1)`, to reproduce the FIFO one-at-a-time rule; use `Microsoft.Data.Sqlite` for an embedded file. Unlike `worker_threads`, .NET threads share memory, so no `MessagePort` is needed: callers `await` the channel instead, and `System.Text.Json` is needed only if calls cross a process boundary. Surface startup failure as an exception from `StartAsync` (the host then fails to start), and report a dead consumer through `IHostApplicationLifetime.StopApplication()`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-server/src/libsql/storage-worker.ts` | confirmed (1.0.2) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

- **Decision**: One dedicated thread owns the only connection, and every other thread talks to it over a `MessagePort`.
  **Rationale**: Stated in the source comment and in `storage/remote.ts`: an embedded `file:` connection runs statements synchronously on the calling thread and a lock wait can spin up to `busy_timeout` (5 s), so when the API thread held its own connection a read that met a monitor write or WAL checkpoint froze the event loop, `/health` timed out and the supervisor restarted the container (the 2026-10-22 outage).
  **Approved**: pending
- **Decision**: Run migrations on every boot of the worker.
  **Rationale**: The source comment says "embedded-file deployments self-migrate on boot"; migrations are idempotent, so repeated boots are safe.
  **Approved**: pending
- **Decision**: Report startup failure as a reply message instead of throwing, and do not end the worker from the module.
  **Rationale**: The host is awaiting the first message in `startStorageThread` and turns `{ ready: false, error }` into a rejection with a clear message; the source does not state why the worker is left running, so this is recorded as the code's behavior, not an endorsement.
  **Approved**: pending
- **Decision**: Do not validate attach messages and do not wrap the listener in a `try`.
  **Rationale**: Not stated in a comment; `StorageWorkerRequest` is the contract and the host's `connect()` is the sole sender. A malformed message therefore ends the worker, which the host treats as fatal through `onExit`. Recorded as fact.
  **Approved**: pending
- **Decision**: Keep this file as glue and leave spawn and attach policy to `storage-thread.ts`.
  **Rationale**: Stated in the source comment ("Glue only — spawn and attach policy live in storage-thread.ts").
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | partial | Reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | Reliability |
| [adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d) | passed | Performance |

`separation-of-concerns` passes: the file only wires an existing connection helper, migration helper, storage factory and queue server together, leaving the queue to `storage/remote.ts`, spawning to `storage-thread.ts` and SQL to `libsql/index.ts`. `unit-test-coverage` is partial: `test/storage-worker.test.ts` covers vectors 001, 002 and 004 to 009 by importing the module in-process with a stand-in `parentPort`, but vector 003 (a monitor cycle through the worker) is skipped there because it needs the built dist worker under bare node; `storage-thread.int.test.ts` covers it. `fault-tolerance` is partial: startup failures are reported to the host, but a malformed attach message or a post-startup throw ends the worker with no recovery inside it. `data-integrity` passes: one connection plus a FIFO queue means no two calls interleave statements, and migrations are applied idempotently before the port is served. `main-thread-freedom` passes: the blocking lock wait of an embedded connection is confined to this thread, so the API thread only awaits replies.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (storage-worker.test.ts, 8 of 9 vectors, 003 skipped: needs built dist worker, covered by the int test); unit-test-coverage now partial. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Restated three MUST NOT rules as current behavior, replaced the queue, hello, error and slow-call requirements with one dependency on Storage Remote, dropped the client.ts vectors, added a FIFO vector, added depends-on, related and tags, and clarified the startup and offline wording. |
