
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
