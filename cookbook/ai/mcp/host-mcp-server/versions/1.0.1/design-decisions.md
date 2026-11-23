
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

