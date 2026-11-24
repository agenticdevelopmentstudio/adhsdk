---
id: 41649904-2300-42c5-b58a-13e3854b8cf8
title: "Hub Client Full API"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: mfullerton
copyright: 2026 mfullerton
license: MIT
summary: "ADHClient.api, the computed accessor that builds the full generated typed API client over the client's own transport and middleware chain."
platforms:
  - swift
  - macos
  - ios
tags:
  - client
  - networking
  - api
depends-on: []
related:
  - 9041d819-d6bf-405a-9129-9730bb2c8a6b
  - d9dfd305-be0d-4770-9db8-43a35218c8b7
  - 8b79c521-04f3-4a43-90db-ae6e0bba9f84
references: []
approved-by: ""
approved-date: ""
---

# Hub Client Full API

## Overview

`ADHClient+API.swift` is the one file in the `AgenticDeveloperHubClient`
module that extends `ADHClient` with the whole generated typed API. `ADHClient`
itself, the transports, the session and the Keychain stores live in the sign-in
tier module, `AgenticDeveloperHubAuth`, so an app that only signs in never
compiles the full client. The file's doc comment states the split: the auth
module generates only the sign-in and session operations, exposed as
`authAPI` of type `HubAuthClient`; this module adds `api`, of type `Client`,
which is always the full API.

The file also re-exports the auth module with an exported import, so
`import AgenticDeveloperHubClient` still reaches `ADHClient`, `APITransport`,
the session and credential stores and the rest of the sign-in tier. Both
modules generate `Components` and `Operations`; where both are visible, this
module's own shadow the re-exported ones. A value returned by an `ADHClient`
sign-in call is the auth module's type, so a caller names it
`AgenticDeveloperHubAuth.Components.Schemas.User` or lets inference carry it.

The recipe covers only `api` and the module-boundary contract in that file.
The façade it hangs off is specified in
[adhsdk.ingredient.hub-client](cookbook:9041d819-d6bf-405a-9129-9730bb2c8a6b),
the transport seam in
[adhsdk.ingredient.transport](cookbook:d9dfd305-be0d-4770-9db8-43a35218c8b7),
and the credential and session types in
[adhsdk.ingredient.auth](cookbook:8b79c521-04f3-4a43-90db-ae6e0bba9f84).

## Behavioral Requirements

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

## Appearance

Not applicable — this is a non-visual client accessor, not a visual component.

## States

Not applicable — this is a non-visual client accessor, not a visual component.

## Accessibility

Not applicable — this is a non-visual client accessor, not a visual component.

## Conformance Test Vectors

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

## Edge Cases

- **No credential**: With an empty credential store, `api` MUST still build and send requests; the middleware forwards them without an `Authorization` header (vector 004).
- **Rejected refresh**: A session client whose refresh is rejected MUST return the original 401 through `api`, clear the store and call `onSessionExpired` (vector 007).
- **Unreachable server**: Transport errors thrown by the underlying `ClientTransport` MUST propagate from the operation called on `api`; this file adds no timeout, retry or offline handling.
- **Repeated access**: Each read of `api` MUST build a fresh `Client`; two reads do not share a `Client` instance but share the same transport and middleware values.
- **Concurrent access**: Concurrent reads of `api` are safe because `ADHClient` is `Sendable` and its stored properties are immutable `let` values.
- **Boundary and empty input**: Not applicable — `api` takes no input; arguments belong to the generated operations.
- **Name collision across modules**: A caller that needs the auth module's `Components.Schemas.User` while both modules are visible MUST qualify it with the module name, because the unqualified name resolves to this module's own shadow.

## Configuration

`api` has no parameters of its own; everything comes from the `ADHClient` it is read from.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `transport` | `APITransport` | none on the initializers; the factories supply `.direct()`, `.daemon()` or the `TransportResolver` choice | Supplies `serverURL` and the `ClientTransport` the `Client` is built from. |
| `middlewares` | array of `ClientMiddleware` | one `AuthenticationMiddleware` (bearer-only init) or one `SessionRefreshMiddleware` (session init) | The chain every request on `api` runs through. |

## Deep Linking

Not applicable: the file only builds a typed API client and handles no URLs or routes from the outside.

## Localization

Not applicable: the file contains no user-facing strings.

## Accessibility Options

Not applicable: the file has no visual or motion output, so no accessibility display option applies.

## Feature Flags

Not applicable: the file reads no feature flag; `api` is always available.

## Analytics

Not applicable: the file emits no analytics events.

## Privacy

Not applicable: the file itself stores and logs nothing; the bearer credential it causes to be sent is handled by the middleware and credential store specified in the auth recipe.

## Logging

Not applicable: the file contains no log calls.

## Platform Notes

- **SwiftUI** (source platform, apple, macOS and iOS): `ADHClient+API.swift` (`packages/apple/AgenticDeveloperHubClient/Sources/`), tested through `ADHClientWiringTests.swift` and the session tests in `.../Tests/AgenticDeveloperHubClientTests/`. It is an extension on a `public struct` that is `Sendable`, uses an exported import of `AgenticDeveloperHubAuth` and the swift-openapi-runtime `Client` generated by the package's OpenAPI generator.
- **Compose**: a Kotlin port would expose a property or function on the client façade that returns the generated OpenAPI client (for example an OkHttp or Ktor based one) configured with the same base URL, engine and interceptor list; Gradle module visibility (`api` dependency scope) plays the role of the exported import.
- **React/Web**: a TypeScript port would be a getter or factory on the façade returning the generated fetch client built from the same base URL, fetch implementation and middleware array; a barrel `export *` from the full-client package plays the role of the re-export.
- **AppKit / UIKit**: no change from the SwiftUI bullet; the accessor has no UI layer and both AppKit and UIKit hosts link the same package target.
- **WinUI 3**: put the full generated client behind a property on the .NET façade, for example `public ApiClient Api => new ApiClient(_http, _baseUrl)`, built from the façade's own `HttpClient` whose `DelegatingHandler` chain (the analogue of the middleware array) injects the bearer and retries after refresh. A computed property is cheap here because the `HttpClient` is shared, so the generated client (NSwag or Kiota output) holds no connection state. The split between the sign-in tier and the full client maps to two .NET assemblies, with the full one referencing the sign-in one, and `[assembly: TypeForwardedTo]` or global usings standing in for the Swift re-export.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubClient/Sources/ADHClient+API.swift` | confirmed (1.0.0) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

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

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.good-test-properties](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9144e220-ad70-51db-ba81-cdb0cc1b66c8) | passed | best-practices |
| [adc.check.access-patterns.api-design-conventions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b6745c95-4ef2-5ab4-8791-00ffc1d7b82d) | passed | access-patterns |

The accessor does one thing, wiring the generated client to the façade's own transport and middlewares, and leaves transport choice, credentials and refresh to the sign-in tier, which satisfies separation of concerns. The wiring tests exercise `api` for routing, bearer injection, transport differences, refresh-and-retry and expiry, using a hermetic mock transport with no network, so they are fast and deterministic. The accessor follows the API design convention of one generated typed surface shared across transports. The accessor itself adds no timeout, retry or error mapping; those belong to the transport and middleware recipes.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-14 | mfullerton | Initial creation |
