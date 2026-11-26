
**Decision**: A new SDK `Server` is created for each `serve(over:)`.
**Rationale**: The source comment explains that the SDK marks a `Server` initialized on its first `initialize` and never clears it, not even in `stop()`, so reuse answers the next client with "Server is already initialized".
**Approved**: pending

**Decision**: An existing connection is stopped before a new one starts.
**Rationale**: The source comment notes that the SDK's `Server.start` would overwrite the connection and receive task without cancelling the old ones.
**Approved**: pending

**Decision**: The server is not created in strict mode.
**Rationale**: A stateless HTTP caller sends `tools/call` with no `initialize` first, and strict mode would refuse it (source comment).
**Approved**: pending

**Decision**: Unknown tools, a missing server and source errors are returned as error results, not protocol errors.
**Rationale**: The model sees the sentence and can recover; `testUnknownToolIsAnErrorResultNotAProtocolError` asserts it for unknown names.
**Approved**: pending

**Decision**: Routing asks each candidate source for its definitions on every call instead of keeping a name table.
**Rationale**: Sources may change what they advertise (the `tools/list` capability sets `listChanged` false, so the server never announces the change, and a client reads the new list only by asking again). The cost is one definition fetch per call; the source does not say why a cache was not used.
**Approved**: pending

**Decision**: A PNG data URL becomes image content.
**Rationale**: The source comment says the tool set renders screenshots as a data URL so a text-only chat still gets something, and this is where MCP gets the real image.
**Approved**: pending

**Decision**: Registrations survive `stop()`.
**Rationale**: The same server is served over several transports in turn (stop then serve), and the source comment forbids re-registering.
**Approved**: pending

**Decision**: `AgentToolSource` runs every tool with its own fixed caller and ignores the pane id the MCP request names.
**Rationale**: The source comment says "The MCP caller id is not passed on: a tool sees `caller`." `AgentToolSourceTests.callSucceeds` asserts the fixed caller wins over the request's.
**Approved**: pending

**Decision**: The bridge does not enforce `permissionDefault` or record activity for mutating tools.
**Rationale**: `ToolPermission`'s doc comment says permissions are "Stored per agent now; enforced in phase 2", and `AgentTool` says a mutating tool's run is reported as an activity entry by the host; the bridge contains neither step.
**Approved**: pending

**Decision**: `AgentToolSource` stays inside this ingredient and is not split into its own.
**Rationale**: It is a small adapter that exists only to feed `HostMCPServer`'s `ChatToolSource` contract, so the two are versioned together. The cost is that an Agents-module type shares a recipe with a Core-module type, which is why the Configuration table has an Owner column. Splitting it into an ingredient that lists this one in `depends-on` is the alternative if the bridge grows or gains other consumers.
**Approved**: pending

**Decision**: The bridge runs mutating and ask-permission tools for any MCP client, including stateless HTTP callers, with no permission check and no activity record. This is an accepted risk for now.
**Rationale**: Permissions are stored per agent but not enforced until phase 2 (`ToolPermission`'s doc comment), and the transport owner limits who can reach the server. Removal trigger: the bridge MUST gain a permission check and an activity record before any non-loopback transport, any transport without authentication, or any untrusted MCP client is allowed to reach it, and in any case when phase 2 permission enforcement ships.
**Approved**: pending

**Decision**: There is no per-call timeout on a source call, and no option to set one.
**Rationale**: This is deliberate debt. The transport owner or the stdio drain deadline bounds a hung source today, and a per-call timeout needs a cancellation contract that `ChatToolSource` does not have. The debt is paid when `ChatToolSource.callTool` gains cancellation, at which point a timeout option MUST be added to `HostMCPServer`.
**Approved**: pending

**Decision**: The `Logger` is a private instance with no injection point, so the call log (vector host-mcp-server-022) has no test.
**Rationale**: The source constructs its own OSLog `Logger`. Injecting a logger or log sink through the initializer would make vector 022 assertable and is the intended direction; until then the lines are specified here and verified by reading the source.
**Approved**: pending

**Decision**: `serve(over:)` and `stop()` are serialised through one queue, in call order, and the last call wins.
**Rationale**: Actor isolation alone does not order them: each suspends after reading the current server, so a second call could start a server the first then overwrote without stopping, leaking a connection and its receive task. Refusing a second `serve` would break the existing `serve-stops-previous` contract, where a host re-serves over a new transport on reconnect; queueing keeps that contract and makes it hold under overlap. Each call is a task that awaits the one before it, so a thrown `serve` releases the queue (`serve-serialized`).
**Approved**: pending
