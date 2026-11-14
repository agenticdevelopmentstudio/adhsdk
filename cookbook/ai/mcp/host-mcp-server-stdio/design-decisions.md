
**Decision**: The server waits for owed replies after end of input instead of stopping when the receive loop ends.
**Rationale**: The source comment explains that the pinned SDK answers each request in an unstructured task and the receive loop ends at EOF, so an immediate stop drops every reply in flight; `printf '...' | temporal mcp` would get nothing back.
**Approved**: pending

**Decision**: Owed requests are counted by a transport wrapper instead of by the server.
**Rationale**: The source does not state why the count lives in a wrapper. The wrapper is where every request in and every response out passes, so it can count without changing the server; the source comments describe the SDK's per-request unstructured tasks, not any way to read them.
**Approved**: pending

**Decision**: The deadline is 360 seconds and counts from the end of input.
**Rationale**: The source comment gives the longest known tool call: temporal's mail sign-in waits up to 300 seconds for the browser plus an XPC timeout above that. A reply missing at the deadline is abandoned and logged.
**Approved**: pending

**Decision**: A cancellation pays the cancelled id.
**Rationale**: MCP says a server need not answer a cancelled request, so waiting for it would hold the drain open until the deadline (`testACancelledRequestIsNoLongerOwedAReply`).
**Approved**: pending

**Decision**: Batches are not counted.
**Rationale**: The SDK answers a batch inside the receive loop, so its reply is written before the loop ends (source comment).
**Approved**: pending

**Decision**: String and number ids are kept apart with a type prefix.
**Rationale**: JSON-RPC treats `"1"` and `1` as different ids; the key records which kind each was.
**Approved**: pending

**Decision**: The SDK version is pinned in the comments (0.12.1) because the workaround depends on it.
**Rationale**: If a later SDK waits for in-flight replies itself, the wrapper becomes redundant; the source does not test for that, so a port to a different SDK should verify before copying it.
**Approved**: pending

