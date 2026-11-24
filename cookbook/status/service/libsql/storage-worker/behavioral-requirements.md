
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

