
Vectors derive from `ADHClientWiringTests.swift`, which drives every typed call through `adh.api`, using `MockClientTransport` as the wire.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| adh-client-api-001 | api-accessor, api-transport | `ADHClient` over a `MockClientTransport`; call `adh.api.getHealth()` | The mock records one request: method `GET`, path `/health`, operation id `get/health`; the 200 decodes (test `typedOperationRoundTrips`). |
| adh-client-api-002 | api-server-url | Direct transport with `serverURL` equal to `DaemonContract.backendURL`; call `api.getHealth()` | The transport receives `baseURL` equal to `DaemonContract.backendURL` (test `typedOperationRoundTrips`). |
| adh-client-api-003 | api-middlewares, api-bearer-injection | Credential store holding token `tok-abc`; call `api.getHealth()` | The recorded request has `Authorization: Bearer tok-abc` (test `authHeaderInjected`). |
| adh-client-api-004 | api-middlewares, api-bearer-injection | Credential store holding no credential; call `api.getHealth()` | The recorded request has no `Authorization` header (test `noAuthHeaderWhenUnauthenticated`). |
| adh-client-api-005 | api-transport-agnostic, api-server-url | Two clients with token `tok-xyz`, one Direct (backend URL), one Daemon (`DaemonContract.daemonURL()`); call `api.getHealth()` on each | Method, path and `Authorization` are identical (`Bearer tok-xyz`); only `baseURL` differs (test `transportsDifferOnlyByBaseURL`). |
| adh-client-api-006 | api-refresh-retry | Session client with access token `jwt-wiring` and refresh token `r-wiring`; transport answers 401 to `Bearer jwt-wiring`, a new pair to `/auth/refresh`, 200 otherwise; call `api.getHealth()` | Paths seen are `/health`, `/auth/refresh`, `/health`; the store now holds token `jwt-2` (test `sessionInitWiresRefresh`). |
| adh-client-api-007 | api-refresh-retry, error-passthrough | Session client whose transport answers 401 to everything; call `api.getHealth()` | The call returns the 401 output (reading `.ok` throws), `onSessionExpired` fires and the store is cleared (test `sessionExpiryCallback`). |
| adh-client-api-008 | api-computed, api-no-failure, concurrency | Read `adh.api` twice | Each read returns a usable `Client` built from the same `(serverURL, transport, middlewares)`; no throw. Derived from the declaration; no test asserts identity. |
| adh-client-api-009 | module-reexport, client-naming | A file that only imports `AgenticDeveloperHubClient` and names `ADHClient` and `APITransport` | It compiles, because the auth module is re-exported (the wiring tests reference both through `@testable` imports of the two modules). |

