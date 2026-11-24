
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

