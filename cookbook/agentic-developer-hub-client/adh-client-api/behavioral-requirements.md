
- **api-accessor**: `ADHClient` MUST expose a public read-only property `api` of type `Client`, the full generated typed API, on which any generated operation is called directly.
- **api-computed**: `api` MUST be a computed property that builds a new `Client` on each access; it MUST NOT store the `Client` it returns.
- **api-server-url**: The `Client` returned by `api` MUST be built with the `serverURL` of the `ADHClient`'s `transport` (`APITransport.serverURL`).
- **api-transport**: The `Client` returned by `api` MUST be built with the `ClientTransport` held in the `ADHClient`'s `transport` (`APITransport.transport`).
- **api-middlewares**: The `Client` returned by `api` MUST be built with the `ADHClient`'s `middlewares` array, the same array `authAPI` and `rawJSON` use.
- **api-bearer-injection**: Because it shares the middleware chain, a request sent through `api` MUST carry the bearer credential exactly as a request sent through `authAPI` does.
- **api-refresh-retry**: When the `ADHClient` was built with the session initializer, a request sent through `api` MUST get the same refresh-and-retry behavior as `authAPI`, because the chain is the same `SessionRefreshMiddleware`.
- **api-transport-agnostic**: The `Client` returned by `api` MUST NOT differ between the Direct and the Daemon transport except for the `(serverURL, transport)` pair it is built from.
- **api-no-failure**: Reading `api` MUST NOT throw, suspend or return an optional; it is a plain synchronous accessor with no side effect beyond constructing the `Client`.
- **module-reexport**: The `AgenticDeveloperHubClient` module MUST re-export `AgenticDeveloperHubAuth` so that importing the client module alone reaches every public sign-in tier type.
- **client-naming**: Within this module `Client` MUST always denote the full API; the auth module's generated client is named `HubAuthClient`, so the two never collide.
- **generated-shadowing**: Where both modules are visible, this module's generated `Components` and `Operations` MUST shadow the re-exported ones.
- **auth-type-origin**: A value returned by an `ADHClient` sign-in call is the auth module's type; a caller that names it MUST use the `AgenticDeveloperHubAuth.Components.Schemas.User` form (or rely on inference) to reach it.
- **concurrency**: `api` MAY be read from any thread or task; `ADHClient` is a `Sendable` struct of immutable `let` properties and `api` reads only those.
- **error-passthrough**: Failures of operations called on `api` MUST surface unchanged from the generated client and middleware chain; this file adds no error mapping, retry or logging of its own.

