
**Decision**: Every request with a rewritable id runs under a fresh UUID id, and the caller's id is restored in the answer.
**Rationale**: The doc comment says the stateless transport keys its bookkeeping by id alone, so two callers sending `"id": 1` would collide; a unique id per request removes the collision without changing what a caller sees.
**Approved**: pending

**Decision**: The endpoint owns cancellation, translating the caller's cancellation to the unique id and turning FlyingFox's timeout into an SDK cancellation.
**Rationale**: Because the running id is not the caller's, the SDK cannot match a caller's cancellation, and FlyingFox's timeout cancels only the HTTP handler; without the endpoint the tool call would run to its end and the transport's waiter would never be released.
**Approved**: pending

**Decision**: A cancelled request is answered with a JSON-RPC error carrying code `-32800` instead of being left without a response.
**Rationale**: The comment says the SDK sends no response for a cancelled request, as the spec says, but over stateless HTTP that holds the connection open to the timeout and leaks a transport waiter; `-32800` is the code the LSP uses, since JSON-RPC and MCP define none.
**Approved**: pending

**Decision**: When binding the preferred port fails, the endpoint falls back to an ephemeral port instead of failing.
**Rationale**: The source logs that the preferred port is taken and returns the port actually bound, so a caller building the URL uses the real port; failing outright would leave no endpoint.
**Approved**: pending

**Decision**: The token is compared without an early exit.
**Rationale**: The doc comment says the compare must not stop at the first differing byte, so timing does not reveal how much of a guess was right.
**Approved**: pending

**Decision**: A stop that arrives during a start is recorded and acted on by `start()` itself, and the phase flips before the first suspension in `stop()`.
**Rationale**: The comments say this keeps a racing `start()` from seeing the closing port or binding a second server; actor reentrancy makes both interleavings reachable.
**Approved**: pending

**Decision**: A streamed SDK response is collected into a single body, and a failed stream becomes an empty 500.
**Rationale**: The comment says the stateless transport never opens a stream for `tools/*`, so collecting is safe, and a truncated 200 would be worse than a visible failure.
**Approved**: pending

