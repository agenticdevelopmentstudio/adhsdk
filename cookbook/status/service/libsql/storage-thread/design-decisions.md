
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
