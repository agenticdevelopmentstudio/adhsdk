**Decision**: A mutating tool declares itself with `isMutating` and returns its undo as data (`ToolOutcome.inverse`) rather than a closure.
**Rationale**: An undo has to outlive the call that made it and cross a process boundary in the reply body, so it must be a `Codable` value; a closure can be neither stored nor sent. The context of the original call is dropped because the inverse names a tool and its arguments, which is all a replay needs. No artifact owns persisting or replaying it yet.
**Approved**: pending

**Decision**: `ToolPermission` is stored per agent but this ingredient does not enforce it.
**Rationale**: The type exists first so agent definitions can carry the setting; enforcing it needs the host's run path, which is outside this ingredient. No artifact owns enforcement yet, so until one does, nothing blocks a run on `ask` or `never`.
**Approved**: pending

**Decision**: `AgentToolError` covers only a call that could not be run (an unknown tool, or arguments that are not a JSON object); a tool that runs and fails throws its own error.
**Rationale**: The host maps the first kind to 404 and the second to 422, so a caller can tell a bad call from a failed tool. Argument refusal is client-side and sends nothing.
**Approved**: pending

**Decision**: A remote tool ignores the `ToolCallContext` and sends the `RemoteAgentTools` caller.
**Rationale**: The host sees this process as one caller, and the transport has no field for per-agent identity, so sending the context would claim an identity the host cannot verify.
**Approved**: pending

**Decision**: The transport is injected as a closure rather than a fixed HTTP client.
**Rationale**: The same client has to run over HTTP to a daemon, over XPC and over an in-process `AgentHandlers` in tests; a closure from request to response is the narrowest seam all three fit.
**Approved**: pending

**Decision**: A missing `mutating` falls back to false, and an unknown or missing `permission` falls back to `auto`, the most permissive value, with no error.
**Rationale**: The fallbacks keep `load()` working against a host that omits a field. The `auto` fallback is a known hazard, not a feature: it fails open, and it is safe today only because nothing here enforces permissions. A port may choose `ask` instead; changing the code is pending approval.
**Approved**: pending
