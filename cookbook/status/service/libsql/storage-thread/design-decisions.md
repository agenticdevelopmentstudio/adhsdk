
**Decision**: One thread owns the database file and every other thread is a client of it.
**Rationale**: The Storage Remote recipe records the outage this prevents: an embedded connection runs statements on the calling thread and a lock wait spins there for up to the busy timeout, so a read that met a write or checkpoint froze the API event loop, `/health` timed out and the supervisor restarted the container. Behind the thread, callers only await a reply.
**Approved**: pending

**Decision**: The host starts the thread once at boot and does not open a connection itself.
**Rationale**: Source comment: from then on "no thread but that one touches the database file", which removes lock contention between threads.
**Approved**: pending

**Decision**: The worker entry is resolved through the package's `exports`, never a relative path.
**Rationale**: Source comment: the entry is always the built output, the same reason as the monitor worker client's spawn. A relative path would load TypeScript source in a worker.
**Approved**: pending

**Decision**: `connect()` is synchronous and returns a transferable port.
**Rationale**: The host passes the port to another thread as a transfer, and that thread builds its own client. Each port is served by the same queue, so there is one lock and no contention.
**Approved**: pending

**Decision**: The module reports a later death through `onExit` and treats it as fatal.
**Rationale**: Doc comment: once the thread dies, "every pending and later call then rejects, so the host should treat it as fatal." A server with no database cannot answer correctly, so it is left to the supervisor to restart it.
**Approved**: pending

**Decision**: A failed start is reported by the rejection, and `onExit` listeners are attached only after the ready wait.
**Rationale**: The two reporting paths do not overlap: a start failure reaches the caller through the returned promise, and a later failure reaches the host through the callback.
**Approved**: pending

