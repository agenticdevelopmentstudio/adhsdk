
**Decision**: `api` is a computed property that rebuilds the `Client` on each read instead of a stored `let` on `ADHClient`.
**Rationale**: `ADHClient` is defined in the sign-in module and cannot name the full `Client` type, which only the full-client module generates; an extension in this module can add the accessor but cannot add stored properties. The `Client` is built from only three values `ADHClient` already holds: the transport's server URL, its `ClientTransport` and the middlewares.
**Approved**: pending

**Decision**: The sign-in tier is a separate module that this module re-exports.
**Rationale**: The file's doc comment says an app that only signs in then never compiles the full client, while `import AgenticDeveloperHubClient` still reaches every sign-in type.
**Approved**: pending

**Decision**: The auth module's generated client is named `HubAuthClient`, so `Client` in this module is always the full API.
**Rationale**: The doc comment records that generate.py renames it, which avoids a name clash between the two generated modules.
**Approved**: pending

**Decision**: `api`, `authAPI` and `rawJSON` all use the same transport and middleware chain.
**Rationale**: Bearer injection and refresh-and-retry then apply identically to every route into the backend, as the accessor's doc comment states.
**Approved**: pending

