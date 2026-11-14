
- **No credential**: With an empty credential store, `api` MUST still build and send requests; the middleware forwards them without an `Authorization` header (vector 004).
- **Rejected refresh**: A session client whose refresh is rejected MUST return the original 401 through `api`, clear the store and call `onSessionExpired` (vector 007).
- **Unreachable server**: Transport errors thrown by the underlying `ClientTransport` MUST propagate from the operation called on `api`; this file adds no timeout, retry or offline handling.
- **Repeated access**: Each read of `api` MUST build a fresh `Client`; two reads do not share a `Client` instance but share the same transport and middleware values.
- **Concurrent access**: Concurrent reads of `api` are safe because `ADHClient` is `Sendable` and its stored properties are immutable `let` values.
- **Boundary and empty input**: Not applicable — `api` takes no input; arguments belong to the generated operations.
- **Name collision across modules**: A caller that needs the auth module's `Components.Schemas.User` while both modules are visible MUST qualify it with the module name, because the unqualified name resolves to this module's own shadow.

