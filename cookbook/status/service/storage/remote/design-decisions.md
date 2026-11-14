
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

