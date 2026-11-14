**Decision**: One queue, one connection.
**Rationale**: A single FIFO queue means no statement can contend for a lock and an async store method's statements never interleave with another call's, at the cost of throughput.
**Approved**: pending

**Decision**: Shape handshake instead of a Proxy.
**Rationale**: Sending the method tree once lets the client build plain stubs; a catch-all Proxy would look like a thenable to `await`.
**Approved**: pending

**Decision**: Flattened error with code and cause.
**Rationale**: Callers match on message, code and the cause chain, so all three cross the wire, and the chain is capped at four causes below the error to bound the payload.
**Approved**: pending

**Decision**: No timeout.
**Rationale**: A call runs until its store method settles; a hang is logged by neither side until it ends, because the queue's purpose is serialisation, not supervision.
**Approved**: pending
