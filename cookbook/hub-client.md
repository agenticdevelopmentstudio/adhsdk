---
id: 9041d819-d6bf-405a-9129-9730bb2c8a6b
title: "Hub Client"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-09-23
modified: 2026-09-23
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "ADHClient, the façade wiring Direct/Daemon transport and bearer or session-refresh middleware to the generated typed API, plus its rawJSON escape hatch."
platforms:
  - swift
  - macos
  - ios
tags:
  - networking
  - client
  - auth
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Hub Client

## Overview

`ADHClient` is the entry point to the Agentic Developer Hub API — a thin
façade over the generated `Client` from swift-openapi-runtime /
swift-openapi-urlsession. It wires one of two `APITransport` seams (Direct,
straight to the backend over HTTPS; Daemon, HTTP to a local `adhd` daemon —
which does not exist yet, per `DaemonContract`'s own doc comment) to exactly
one `ClientMiddleware`: the bearer-only `AuthenticationMiddleware` or the
bearer-plus-refresh-and-retry `SessionRefreshMiddleware`. The generated
client is exposed directly as `api`; consumers call any operation the
OpenAPI document describes through it (e.g. `client.api.getHealth()`).
`ADHClient+Raw.swift` extends the same façade with
`rawJSON(method:path:query:body:headers:)`, an escape hatch that runs an
arbitrary un-generated request through the identical transport-and-middleware
pipeline, for backend routes the OpenAPI document does not describe or
describes stalely.

This recipe covers exactly `ADHClient.swift` and `ADHClient+Raw.swift`
(`packages/apple/AgenticDeveloperHubClient/Sources/`). `AuthenticationMiddleware`,
`SessionRefreshMiddleware`, `RefreshCoordinator`, `CredentialStore`,
`SessionStore`, `Credentials`, `Session`, `KeychainHelper`, and the
`ADHClient+Auth.swift` / `ADHClient+Session.swift` convenience wrappers
(`login`, `signIn`, `signOut`, and the rest) are `hub-client-auth`'s
contract — they are referenced here only where `ADHClient` composes or calls
into them. `APITransport`, `DaemonContract`, and `TransportResolver` are
`hub-client-transport`'s contract — referenced here only where `ADHClient`'s
factories select between them.

## Behavioral Requirements

### Construction

- **sendable-value-type**: `ADHClient` MUST be declared `Sendable`. It is a
  `struct` with only `let` stored properties (`api: Client`,
  `transport: APITransport`, `credentials: any CredentialStore`,
  `session: (any SessionStore)?`, `middlewares: [any ClientMiddleware]`), so
  an instance carries no mutable state.
- **bearer-only-init-installs-authentication-middleware**:
  `init(transport:credentials:)` MUST default `credentials` to
  `KeychainCredentialStore()` when the caller supplies none, and MUST install
  exactly one middleware, `AuthenticationMiddleware(credentials:)` — its own
  bearer-injection contract is `hub-client-auth`'s.
- **session-init-installs-session-refresh-middleware**:
  `init(transport:session:onSessionExpired:)` MUST default
  `onSessionExpired` to a no-op closure, MUST set both `credentials` and
  `session` to the given `session` value, and MUST install exactly one
  middleware, `SessionRefreshMiddleware(session:onSessionExpired:)` — its own
  refresh-and-retry decision table is `hub-client-auth`'s.
- **generated-client-shares-transport-and-middleware**: Both initializers
  MUST construct `api` as
  `Client(serverURL: transport.serverURL, transport: transport.transport, middlewares: middlewares)`,
  so the generated typed client and any later `rawJSON` call route through
  the identical transport and middleware chain.
- **transport-kind-computed**: `transportKind` MUST be a computed property
  returning `transport.kind`, never a separately stored value that could
  drift from `transport`.
- **internal-fields-not-public**: `credentials`, `session`, and
  `middlewares` MUST NOT be `public`; only `api`, `transport`, and
  `transportKind` are part of `ADHClient`'s public surface.

### Transport Selection (Factories)

- **direct-factory-targets-backend**: `.direct(credentials:)` MUST construct
  an `ADHClient` wired to `APITransport.direct()` — HTTPS to
  `DaemonContract.backendURL` (`APITransport`'s own factory contract is
  `hub-client-transport`'s).
- **daemon-factory-targets-loopback**: `.daemon(credentials:)` MUST
  construct an `ADHClient` wired to `APITransport.daemon()` — HTTP to
  `127.0.0.1` on `DaemonContract.port`.
- **resolved-factory-follows-resolver**: `.resolved(using:credentials:)`
  MUST await `resolver.resolve()` and wire the client to
  `.daemon(port: resolver.port)` when the result is `.daemon`, or
  `.direct()` when it is `.direct` — it MUST NOT probe or decide
  independently of the injected `TransportResolver` (whose own probe/caching
  contract is `hub-client-transport`'s).
- **resolved-factory-default-resolver**: `.resolved(using:credentials:)`
  MUST default `resolver` to a freshly constructed `TransportResolver()`
  (auto-probing) when the caller supplies none.
- **session-factories-mirror-bearer-factories**:
  `.direct(session:onSessionExpired:)`, `.daemon(session:port:onSessionExpired:)`,
  and `.resolved(using:session:onSessionExpired:)` MUST select the same
  transport as their bearer-only counterparts, differing only in
  constructing a session-backed `ADHClient`.
- **daemon-session-factory-port-override**:
  `.daemon(session:port:onSessionExpired:)` MUST accept a caller-supplied
  `port`, defaulting to `DaemonContract.port`, and pass it through to
  `.daemon(port:)`.

### Typed Requests

- **typed-api-is-full-surface**: `api` MUST expose the complete generated
  `Client`, so every operation the OpenAPI document describes is callable
  directly as `client.api.<operation>(...)` with no additional wrapping by
  `ADHClient`.

### Raw Requests (`rawJSON`)

- **raw-path-must-be-absolute**: `rawJSON` MUST throw
  `RawRequestError.invalidPath(path)` when `path` does not start with `/`,
  before performing any network activity.
- **raw-query-sorted-and-percent-encoded**: When `query` is non-empty,
  `rawJSON` MUST build the query string by sorting entries by key and
  percent-encoding both key and value against `CharacterSet.urlQueryAllowed`
  minus `+&=?#`, joined with `&`.
- **raw-query-appended-correctly**: `rawJSON` MUST append the built query
  string to `path` with `&` when `path` already contains `?`, otherwise with
  `?`.
- **raw-default-headers**: `rawJSON` MUST set `Accept: application/json`
  unconditionally, and MUST set `Content-Type: application/json` only when
  `body` is non-nil.
- **raw-caller-headers-override-defaults**: `rawJSON` MUST apply the
  caller's `headers`, sorted by key, after the default `Accept` /
  `Content-Type` headers, so a caller-supplied value of the same name
  replaces a default.
- **raw-invalid-header-name-dropped**: `rawJSON` MUST silently skip any
  caller-supplied header whose name `HTTPField.Name(name)` fails to parse,
  rather than throwing.
- **raw-operation-id-derived-from-unqueried-path**: `rawJSON` MUST compute
  its `operationID` as `"raw <METHOD> <path>"` via
  `ADHClient.rawOperationID(method:path:)`, using the original, un-queried
  `path` — never the query-appended `fullPath`.
- **raw-middleware-chain-reused**: `rawJSON` MUST route the request through
  the exact same `middlewares` chain (composed by reversing `middlewares`
  and wrapping the transport's `send`) that `api` was built with, so bearer
  injection and refresh-and-retry behave identically for raw and typed
  requests.
- **raw-nil-body-yields-empty-data**: When the response has no body,
  `rawJSON` MUST set `RawResponse.body` to an empty `Data()` without
  invoking `Data(collecting:upTo:)`.
- **raw-response-body-capped**: When the response has a body, `rawJSON` MUST
  collect it via `Data(collecting: responseBody, upTo: ADHBodyLimit.maxBuffered)`
  — a shared 16 MiB cap (`ADHBodyLimit`, defined in this file and reused by
  `hub-client-auth`'s `SessionRefreshMiddleware` for request-body buffering)
  — which throws when the body exceeds that cap.
- **raw-response-headers-last-wins**: `rawJSON` MUST build
  `RawResponse.headers` by folding `response.headerFields` into a
  `[String: String]` keyed by `canonicalName`, so a response with more than
  one header of the same canonical name retains only the last value
  encountered.
- **raw-error-status-throws-http**: `rawJSON` MUST throw
  `RawRequestError.http(status:body:)` for any response with
  `status.code >= 400`, carrying the numeric status and the (already-capped)
  body.
- **raw-response-decodes-with-adh-default**: `RawResponse.decode(_:decoder:)`
  MUST default `decoder` to `JSONDecoder.adhDefault`, which parses dates as
  ISO-8601 with fractional seconds first, then plain ISO-8601, throwing
  `DecodingError.dataCorrupted` for any other string.
- **revoke-operation-id-shared-with-signout**: `ADHClient.revokeRawOperationID`
  MUST be derived from `rawOperationID(method: revokeMethod, path: revokePath)`
  (`POST /auth/revoke`) — the same helper `rawJSON` itself uses — so
  `hub-client-auth`'s `signOut()` (which sends this raw revoke request) and
  `SessionRefreshMiddleware.exemptOperationIDs`' exemption for it can never
  disagree about the operation ID string.

### Authentication

This sub-section addresses the security concerns of token handling, per
[adc.guideline.cookbook.recipe-quality.cookbook-compliance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0d3aaa29-0ce3-4803-8f8a-a7023713b574)'s
requirement that a recipe involving token handling include one. The
middleware's own decision table — which responses trigger a refresh, how
concurrent refreshes are serialized through `RefreshCoordinator.shared`,
when a rejected refresh clears the session — is `hub-client-auth`'s
contract; from `ADHClient`'s own two files, only the following is specified.

- **middleware-choice-fixed-at-construction**: Once constructed, an
  `ADHClient` MUST use exactly the one middleware chosen by which
  initializer built it — bearer-only from `init(transport:credentials:)`,
  refresh-and-retry from `init(transport:session:onSessionExpired:)` — with
  no way to swap it after construction.
- **raw-and-typed-share-identical-auth**: `rawJSON` MUST observe the exact
  same authentication and refresh behavior as the typed `api` for the same
  `ADHClient` instance, because both route through the identical
  `middlewares` array.
- **credential-and-session-storage-delegated**: `ADHClient` MUST NOT itself
  persist, cache, or manage the lifetime of a credential or session; it
  holds only references to the injected `CredentialStore` / `SessionStore`
  (storage, redaction, and lifetime are `hub-client-auth`'s contract —
  `Auth/CredentialStore.swift`, `Auth/SessionStore.swift`, grepped as the
  helpers behind these references, not part of `ADHClient.swift` itself).

### Concurrency

- **adhclient-carries-no-shared-mutable-state**: `ADHClient` MUST hold only
  `let` stored properties (including the array `middlewares`, referencing
  `Sendable` middleware instances), so concurrent calls through one instance
  need no additional synchronization beyond what the injected
  `CredentialStore` / `SessionStore` itself provides.
- **rawjson-safe-for-concurrent-calls**: `rawJSON` MUST create all of its
  per-call state (the built request, the reversed middleware chain, the
  `next` closure) locally on each call, with no instance-level mutable
  state, so concurrent `rawJSON` calls on one `ADHClient` proceed
  independently.

### Persistence and Caching

- **no-local-persistence**: `ADHClient` and `rawJSON` MUST NOT persist or
  cache request or response data of their own; the only cross-request state
  is the credential/session held by the injected store and the transport
  seam's own cached decision (`hub-client-transport`'s `TransportResolver`,
  outside these two files).

## Appearance

Not applicable — this is an API client façade, not a visual component.

## States

Not applicable — this is an API client façade, not a visual component.

## Accessibility

Not applicable — this is an API client façade, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hub-client-001 | sendable-value-type, adhclient-carries-no-shared-mutable-state | One `ADHClient` instance passed into two concurrently running `Task`s that each call `api.getHealth()` | Both calls proceed independently with no compiler diagnostic and no data race; `ADHClient` is a `struct` with only `let` properties, declared `Sendable`. Not covered by an existing test; derived from the type declaration. |
| hub-client-002 | bearer-only-init-installs-authentication-middleware, generated-client-shares-transport-and-middleware | Construct `ADHClient(transport:, credentials: someStore)` and call `api.getHealth()`, once with a credential present and once with none | `Authorization` header equals `"Bearer <token>"` when a credential is present, and is absent otherwise — `ADHClientWiringTests.authHeaderInjected` / `noAuthHeaderWhenUnauthenticated`. |
| hub-client-003 | session-init-installs-session-refresh-middleware, generated-client-shares-transport-and-middleware | `ADHClient(transport:, session: store)` where `store` holds an expired JWT plus a refresh token; call `api.getHealth()` | The 401 is refreshed and the retried request carries the new bearer; `store` ends holding the rotated token — `ADHClientWiringTests.sessionInitWiresRefresh`. |
| hub-client-004 | transport-kind-computed | `ADHClient(transport: .direct(...))` and `ADHClient(transport: .daemon(...))` | `.transportKind` equals `.direct` and `.daemon` respectively — `ADHClientWiringTests.transportKindCarried`. |
| hub-client-005 | direct-factory-targets-backend | `ADHClient.direct(credentials:)` | Resulting client's `transport.serverURL == DaemonContract.backendURL`, `transport.kind == .direct` — `ADHClientWiringTests.directFactoryTargetsBackend` exercises the underlying `APITransport.direct()` this factory calls unchanged. |
| hub-client-006 | daemon-factory-targets-loopback | `ADHClient.daemon(credentials:)` | Resulting client's `transport.serverURL == DaemonContract.daemonURL()` (`"http://127.0.0.1:22850"`), `transport.kind == .daemon` — `ADHClientWiringTests.daemonFactoryTargetsLoopback`. |
| hub-client-007 | resolved-factory-follows-resolver, resolved-factory-default-resolver | `await ADHClient.resolved(using: TransportResolver(override: .forceDaemon))` and the same with `.forceDirect` | `transportKind == .daemon` and `.direct` respectively — `TransportResolverTests.resolvedClientUsesChosenTransport`. |
| hub-client-008 | session-factories-mirror-bearer-factories, daemon-session-factory-port-override | `ADHClient.daemon(session:, port: 9999)` | Resulting client's `transport.serverURL == DaemonContract.daemonURL(port: 9999)`. Not covered by an existing test; derived from `.daemon(session:port:onSessionExpired:)` forwarding `port` to `.daemon(port:)`. |
| hub-client-009 | typed-api-is-full-surface | `client.api.getHealth()` | Routes through the transport and decodes the generated `200` response; the transport records `operationID == "get/health"` — `ADHClientWiringTests.typedOperationRoundTrips`. |
| hub-client-010 | raw-path-must-be-absolute | `rawJSON(method: .get, path: "billing/context")` | Throws `RawRequestError.invalidPath("billing/context")` before any request is sent — `RawJSONTests.rejectsRelativePath`. |
| hub-client-011 | raw-query-sorted-and-percent-encoded, raw-query-appended-correctly | `rawJSON(method: .get, path: "/organization/organizations", query: ["workspace": "a b"])` | Sent path is `"/organization/organizations?workspace=a%20b"` — `RawJSONTests.goesThroughMiddleware`. |
| hub-client-012 | raw-default-headers | `rawJSON(method: .put, path: "/me/workspace-prefs", body: Data(...))` that 401s, refreshes, and is retried | The retried request carries `Content-Type: application/json` (`body` is non-nil) — `RawJSONTests.refreshesOn401`. |
| hub-client-013 | raw-caller-headers-override-defaults, raw-invalid-header-name-dropped | `rawJSON(..., headers: ["Accept": "text/plain", "bad header": "x"])` | Sent `Accept` is `"text/plain"` (caller override wins over the default); no header is sent for the name `"bad header"` (rejected by `HTTPField.Name`). Not covered by an existing test; derived from the caller-headers loop and the `guard let field = HTTPField.Name(name) else { continue }` line. |
| hub-client-014 | raw-operation-id-derived-from-unqueried-path | `rawJSON(method: .get, path: "/billing/context", query: ["a": "b"])`, with the middleware chain inspecting `operationID` | `operationID == "raw GET /billing/context"` — the un-queried `path`, never `"raw GET /billing/context?a=b"`. Not covered by an existing test; derived from `Self.rawOperationID(method:path:)` being computed from `path`, not `fullPath`. |
| hub-client-015 | raw-middleware-chain-reused, raw-and-typed-share-identical-auth | A session-backed client's `rawJSON` call 401s | The request is refreshed and retried once with the new bearer, exactly like a typed operation — `RawJSONTests.refreshesOn401`. |
| hub-client-016 | raw-nil-body-yields-empty-data | `rawJSON` against a mock returning a `nil` response body | `RawResponse.body == Data()`. Not covered by an existing test; derived from the `if let responseBody { ... } else { Data() }` branch. |
| hub-client-017 | raw-response-body-capped | `rawJSON` against a mock whose response body exceeds 16 MiB | `Data(collecting: responseBody, upTo: ADHBodyLimit.maxBuffered)` throws before `RawResponse` is constructed — the caller never sees `RawRequestError.http` for this case, even for an error status. Not covered by an existing test; derived from `ADHBodyLimit.maxBuffered = 16 * 1024 * 1024` and the un-guarded `Data(collecting:upTo:)` call. |
| hub-client-018 | raw-response-headers-last-wins | A mocked response carrying two headers whose names share one canonical name but differ in value | `RawResponse.headers` retains only the value from whichever header `response.headerFields` iterates last. Not covered by an existing test; derived from the `for field in response.headerFields { headers[field.name.canonicalName] = field.value }` loop. |
| hub-client-019 | raw-error-status-throws-http | `rawJSON(method: .get, path: "/billing/context")` against a 404 with body `{"error":"nope"}` | Throws `RawRequestError.http(status: 404, body: Data(#"{"error":"nope"}"#.utf8))` — `RawJSONTests.throwsOnError`. |
| hub-client-020 | raw-response-decodes-with-adh-default | `response.decode([Org].self)` on a 200 JSON array body, where `Org` has no custom date fields | Decodes successfully via `JSONDecoder.adhDefault` — `RawJSONTests.goesThroughMiddleware`. |
| hub-client-021 | revoke-operation-id-shared-with-signout | Compare `ADHClient.revokeRawOperationID` to the literal it is built from | Equals `"raw POST /auth/revoke"`, matching `rawOperationID(method: .post, path: "/auth/revoke")` exactly; `hub-client-auth`'s `SessionRefreshMiddleware.exemptOperationIDs` contains this same value. Not covered by a test in the two given sources; derived from the static declarations and cross-checked against `hub-client-auth`'s `session-refresh-exempt-operations` requirement. |
| hub-client-022 | internal-fields-not-public, middleware-choice-fixed-at-construction | Attempt, from outside the module, to read or assign `client.middlewares`, `client.credentials`, or `client.session` | Fails to compile — none of the three is `public`. Not covered by an existing test; derived from the access-level declarations. |
| hub-client-023 | raw-and-typed-share-identical-auth | On one session-backed client: one 401 via `client.api.getHealth()`, one 401 via `client.rawJSON(...)` | Both are refreshed and retried identically (new bearer, same store mutation) — `ADHClientWiringTests.sessionInitWiresRefresh` and `RawJSONTests.refreshesOn401` compared side by side. |
| hub-client-024 | credential-and-session-storage-delegated | Inspect `ADHClient`'s stored properties immediately after construction | `credentials`/`session` hold only the exact store instance the caller passed in — no local copy of a credential or session value exists anywhere on `ADHClient`. Not covered by an existing test; derived from the initializer bodies. |
| hub-client-025 | rawjson-safe-for-concurrent-calls | Two concurrent `rawJSON` calls on one `ADHClient` instance, with different paths | Both proceed independently with no shared mutable state touched between them. Not covered by an existing test; derived from `rawJSON` building all of its per-call state (`request`, `next`, `fullPath`) as local variables. |
| hub-client-026 | no-local-persistence | Two sequential calls (`api.getHealth()` then `rawJSON(...)`, or the reverse) against mocks returning different bodies each time | Each call returns exactly its own response; neither `ADHClient` nor `rawJSON` caches or reuses a value from one call in the next. Not covered by an existing test; derived from `ADHClient` and `ADHClient+Raw.swift` defining no cache/store field of their own. |

## Edge Cases

- **Relative path.** Input: `rawJSON(path: "billing/context")` (no leading
  `/`). Rejected before any network activity with
  `RawRequestError.invalidPath`. MUST — `raw-path-must-be-absolute`,
  `RawJSONTests.rejectsRelativePath`.
- **Query values containing reserved characters.** Input: a query value
  containing `+`, `&`, `=`, `?`, or `#` (e.g. `"a b"`, or a value that is
  itself a URL). Percent-encoded against `urlQueryAllowed` minus those six
  characters, so they cannot be mistaken for query-string syntax once
  embedded. MUST — `raw-query-sorted-and-percent-encoded`.
- **`path` that already contains a literal `?` plus a non-empty `query`.**
  The two are joined with `&`, never a second `?`. MUST —
  `raw-query-appended-correctly`.
- **Caller-supplied header name the HTTP field grammar rejects** (e.g.
  contains a space or control character). Dropped silently rather than
  thrown — the source's own doc comment states this is deliberate ("a
  transport detail, not a place to crash a sign-in"), since the one real
  caller needing arbitrary headers must not have an unrelated malformed
  header abort the whole request. MUST — `raw-invalid-header-name-dropped`.
- **Caller-supplied `Accept` or `Content-Type` header.** Replaces the
  default of the same name, because caller headers are applied after the
  defaults. MUST — `raw-caller-headers-override-defaults`.
- **No response body on a success status** (e.g. a 204-shaped response).
  `RawResponse.body` is `Data()`, never thrown or left as an optional. MUST
  — `raw-nil-body-yields-empty-data`.
- **Response body at or beyond the 16 MiB cap.** The collection step itself
  throws before the status code is even inspected — a large body on an
  error status never reaches `RawRequestError.http`; the caller instead sees
  whatever error `Data(collecting:upTo:)` throws. MUST —
  `raw-response-body-capped` interacting with `raw-error-status-throws-http`
  (the size check runs strictly before the status check).
- **Duplicate response header names differing only by original casing.**
  Canonicalized and collapsed to the last one `response.headerFields`
  iterates — an earlier value with the same canonical name is discarded
  with no warning. MUST — `raw-response-headers-last-wins`.
- **A `rawJSON` call on a client whose session is an API-token session, or
  whose JWT session has no refresh token.** The refresh decision itself is
  `hub-client-auth`'s (`SessionRefreshMiddleware`'s exemption/no-refresh
  guards); from `ADHClient`'s perspective, `rawJSON` behaves exactly as it
  would for a typed call in the same situation, because both share the one
  `middlewares` array. MUST — `raw-and-typed-share-identical-auth`.
- **Two `ADHClient`s built independently from the same `SessionStore`**
  (e.g. two view models sharing one Keychain-backed session). Both route
  every request, typed or raw, through the identical store reference; the
  process-wide coalescing of a concurrent refresh across the two is
  `hub-client-auth`'s `RefreshCoordinator.shared` contract, not something
  either `ADHClient` instance implements itself. MUST —
  `credential-and-session-storage-delegated`.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `transport` | `APITransport` | none (required) | The `(serverURL, transport)` seam every request routes through. |
| `credentials` (bearer-only init/factories) | `any CredentialStore` | `KeychainCredentialStore()` | Backs `AuthenticationMiddleware`; storage is `hub-client-auth`'s contract. |
| `session` (session-backed init/factories) | `any SessionStore` | none (required) | Backs `SessionRefreshMiddleware`. |
| `onSessionExpired` | `@Sendable () -> Void` | `{}` (no-op) | Called when a refresh is rejected and the session store has been cleared. |
| `resolver` (`.resolved` parameter) | `TransportResolver` | `TransportResolver()` (auto-probing) | Decides Direct vs. Daemon; probing/caching is `hub-client-transport`'s contract. |
| `port` (`.daemon(session:port:)` parameter) | `Int` | `DaemonContract.port` (`22850`) | Loopback port the daemon-backed session client targets. |
| `rawJSON`: `method` | `HTTPRequest.Method` | none (required) | The HTTP method for the raw request. |
| `rawJSON`: `path` | `String` | none (required) | Must start with `/`; rejected otherwise. |
| `rawJSON`: `query` | `[String: String]` | `[:]` | Sorted and percent-encoded onto `path`. |
| `rawJSON`: `body` | `Data?` | `nil` | Sent verbatim; presence alone controls the default `Content-Type`. |
| `rawJSON`: `headers` | `[String: String]` | `[:]` | Applied after, and able to override, the default `Accept` / `Content-Type` headers. |
| `ADHBodyLimit.maxBuffered` | `Int` (internal constant, not caller-configurable) | `16 * 1024 * 1024` | Shared cap for `rawJSON`'s response-body collection and (via `hub-client-auth`) `SessionRefreshMiddleware`'s request-body buffering. |

## Deep Linking

Not applicable: `ADHClient` is a headless API client with no URL scheme or
app route of its own; its `rawJSON` paths (e.g. `/organization/organizations`)
are HTTP API endpoints, not deep links.

## Localization

| String Key | Default (en) | Context |
|-----------|---------------|---------|
| (none — inline literal) | `not an ISO-8601 date: <text>` | Debug description built in `JSONDecoder.adhDefault`'s custom `dateDecodingStrategy`, thrown inside `DecodingError.dataCorrupted` when a date string matches neither the fractional nor the plain ISO-8601 format. English-only, not routed through any string catalog or localization mechanism. |

## Accessibility Options

Not applicable: `ADHClient` has no visual surface, so it responds to none of
Reduce Motion, Increase Contrast, or Differentiate Without Color.

## Feature Flags

Not applicable: neither `ADHClient.swift` nor `ADHClient+Raw.swift` defines a
flag or feature-toggle field; every code path in these two files runs
unconditionally. (Transport selection can be steered by
`TransportResolver.fromUserDefaults(_:port:)`'s `useDirectMode` key, but that
steering lives in `TransportResolver.swift` — `hub-client-transport`'s
contract, not either of the two sources this recipe covers.)

## Analytics

Not applicable: no analytics event type, tracking call, or telemetry hook
appears anywhere in `ADHClient.swift` or `ADHClient+Raw.swift`.

## Privacy

- **Data collected**: `ADHClient` and `rawJSON` collect no data of their
  own; `rawJSON` forwards whatever `query`, `body`, and `headers` the caller
  supplies, plus the bearer token attached by whichever middleware
  (`AuthenticationMiddleware` or `SessionRefreshMiddleware`) the client was
  constructed with.
- **Storage**: `ADHClient` stores nothing itself beyond references —
  `credentials` and `session` hold the injected `CredentialStore` /
  `SessionStore`. Storage of the credential/session value is entirely
  delegated: `KeychainCredentialStore` / `KeychainSessionStore` persist to
  the Keychain, `InMemoryCredentialStore` / `InMemorySessionStore` hold
  state only for the process's lifetime (`Auth/CredentialStore.swift`,
  `Auth/SessionStore.swift` — `hub-client-auth`'s contract, grepped here
  only for accuracy).
- **Transmission**: the bearer token leaves the process on every `api` and
  `rawJSON` call, as `Authorization: Bearer <token>`, over whichever
  `(serverURL, transport)` pair the client was wired to — HTTPS for Direct,
  loopback-only HTTP for Daemon (`hub-client-transport`'s contract).
  `rawJSON`'s request and response bodies cross that same connection;
  `ADHClient` adds no encryption of its own beyond what the transport
  provides.
- **Retention**: not applicable to `ADHClient` — it retains nothing after a
  call returns. Retention of the credential/session itself is
  `hub-client-auth`'s (the injected store's) policy; this recipe's two
  sources specify no retention duration.

## Logging

Not applicable: no log, print, or diagnostic-emission call appears anywhere
in `ADHClient.swift` or `ADHClient+Raw.swift`; every failure is communicated
to the caller by throwing a typed `RawRequestError` (or whatever error the
transport/middleware itself throws), never by writing to a log.

## Platform Notes

- **SwiftUI** (source platform — apple, `macOS 14.0` / `iOS 17.0`, one
  multi-destination target): `ADHClient.swift`, `ADHClient+Raw.swift`
  (`packages/apple/AgenticDeveloperHubClient/Sources/`) and their tests,
  `ADHClientWiringTests.swift`, `RawJSONTests.swift`
  (`.../Tests/AgenticDeveloperHubClientTests/`, using `MockClientTransport`).
  Built on the generated swift-openapi-runtime `Client` /
  `ClientMiddleware` / `ClientTransport` types, `HTTPTypes`'s `HTTPRequest` /
  `HTTPResponse` / `HTTPField`, a `Sendable` value type, and the sibling
  `APITransport` / `TransportResolver` (`hub-client-transport`) and
  `CredentialStore` / `SessionStore` / `AuthenticationMiddleware` /
  `SessionRefreshMiddleware` (`hub-client-auth`) types.
- **Compose** (Android/Kotlin): start from a generated OpenAPI client (or a
  hand-rolled `OkHttpClient` / Ktor `HttpClient` wrapper) for the typed
  surface `api` exposes here, a small façade class mirroring `ADHClient`'s
  two constructors (bearer-only vs. session-backed, selecting which auth
  interceptor to install), and a `suspend fun rawJson(method, path, query, body, headers)`
  mirroring `rawJSON`'s contract — leading-slash validation, sorted
  percent-encoded query, default `Accept` / `Content-Type`, and a 16 MiB
  response-body cap.
- **React/Web**: start from the generated OpenAPI TypeScript client (or
  `fetch`) for the typed surface, a small façade module exposing the same
  two construction shapes, and an `async function rawJson(...)` mirroring
  the same query-encoding, header-override, and cap contract; browser
  `fetch` has no built-in response-size limit, so a port must enforce the 16
  MiB cap itself while reading the body.
- **AppKit / UIKit**: no change from the SwiftUI bullet — `ADHClient` has no
  UI layer; both AppKit and UIKit hosts consume the same
  `AgenticDeveloperHubClient` package target unmodified.
- **WinUI 3**: start from the nearest .NET OpenAPI-generated client (or a
  hand-written typed client) for `api`, a façade class mirroring the two
  constructors, and a `Task<RawResponse> RawJsonAsync(...)` mirroring
  `rawJSON` — `HttpRequestMessage` / `HttpResponseMessage` in place of
  `HTTPRequest` / `HTTPResponse`, `System.Text.Json` for
  `RawResponse.Decode<T>()`, and a manual read-loop (or
  `HttpClient.MaxResponseContentBufferSize`, which throws
  `HttpRequestException` rather than a dedicated typed exception) to
  enforce the 16 MiB response cap.

## Design Decisions

- **Decision**: The generated `Client` is exposed directly as `public let
  api`, with no additional per-operation wrapping on `ADHClient`.
  **Rationale**: the type's own doc comment states consumers "call the full,
  typed API through it" — this avoids re-declaring every generated
  operation on `ADHClient` itself, so a newly generated operation is usable
  immediately with no change to this façade.
  **Approved**: pending

- **Decision**: Direct and Daemon transports differ only by
  `(serverURL, transport)` on `APITransport`; `ADHClient` builds an
  identical generated `Client` from either.
  **Rationale**: swift-openapi-runtime takes the server URL on `Client`, not
  the transport, so transport selection is fully captured by that pair —
  `ADHClient` needs no branching between the two beyond which
  `APITransport` value it was given.
  **Approved**: pending

- **Decision**: `credentials`, `session`, and `middlewares` are non-public.
  **Rationale**: `api` / `transport` / `transportKind` are the intended
  public surface, per the type's own doc comment. `hub-client-auth`'s
  `ADHClient+Auth.swift` / `ADHClient+Session.swift` wrappers reach
  `credentials` / `session` from within the module, but a consumer outside
  the module has no supported reason to reach past `api` for
  authentication.
  **Approved**: pending

- **Decision**: `rawJSON` rebuilds an equivalent middleware chain from the
  same `middlewares` array `ADHClient` was constructed with, rather than
  sharing a pre-built pipeline with `api`.
  **Rationale**: swift-openapi-runtime's generated `Client` does not expose
  its assembled middleware pipeline for reuse, so `rawJSON` reconstructs one
  from the identical `middlewares` array, guaranteeing raw and typed
  requests see identical auth/refresh behavior without depending on
  `Client`'s internals.
  **Approved**: pending

- **Decision**: A caller-supplied header name that `HTTPField.Name` rejects
  is silently dropped rather than thrown.
  **Rationale**: the doc comment states this is "a transport detail, not a
  place to crash a sign-in" — the one real caller needing arbitrary headers
  (`hub-client-auth`'s `exchangeOAuthCode`) must not have an unrelated
  malformed header abort authentication.
  **Approved**: pending

- **Decision**: The 16 MiB buffering cap (`ADHBodyLimit.maxBuffered`) is a
  single, non-configurable constant, defined here and shared with
  `hub-client-auth`'s `SessionRefreshMiddleware` for request-body buffering.
  **Rationale**: the doc comment states it "covers every JSON body the hub
  sends; uploads go through storage presigned URLs, not this client" — one
  contract avoids the two call sites silently drifting to different limits.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.artifact-formatting.ingredient-formatting.if-frontmatter-complete](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/083aeeb8-a2fa-5fbc-a3e6-82df9a653872) | passed | artifact-formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-behavioral-requirements](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/192770a1-b6b6-5782-bc29-251a8a941272) | passed | artifact-formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-test-vectors](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/91ba975a-1f6a-5a85-8652-26e76cf324f4) | passed | artifact-formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-platform-notes](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90c2d8c2-cf79-5465-bffd-54f9fb1453bc) | passed | artifact-formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-design-decisions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f5b5cbe6-22e8-5954-a18d-0362ee387941) | passed | artifact-formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-compliance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1888cb38-9583-5657-a76f-c9685d296d6c) | passed | artifact-formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-change-history](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/14bf2d1d-875b-5e58-b43d-be492c9f941a) | passed | artifact-formatting |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | partial | security |
| [adc.check.security.token-lifecycle](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/61edfc73-f26a-5cfa-8c09-d1011eb8b7cd) | partial | security |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |
| [adc.check.privacy-and-data.secure-data-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9d865cfa-ff98-5b90-b5da-58a611d3535b) | passed | privacy-and-data |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | partial | reliability |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | partial | reliability |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | partial | reliability |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | passed | reliability |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | partial | reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |

`secure-transport` is partial: Direct always targets `https://` (`DaemonContract.backendURL`);
Daemon always targets `127.0.0.1` loopback, never an arbitrary
caller-supplied host — but the bearer still crosses that loopback socket
unencrypted, which is why this stays partial rather than passed (the
loopback restriction itself is `hub-client-transport`'s contract).
`token-lifecycle` is partial: the session-backed path implements real
refresh-and-retry (`hub-client-auth`'s `SessionRefreshMiddleware`), but the
bearer-only path (`AuthenticationMiddleware`) has no lifecycle handling of
its own — fully delegated to the injected `CredentialStore`, exactly as
`hub-client-sync` describes for `ADHSyncAPI`. `graceful-degradation` is
partial: only the `.resolved` factories fall back Daemon-to-Direct via
`TransportResolver`; the direct `.direct()` / `.daemon()` factories have no
fallback of their own. `fault-tolerance` is partial: the one 401
refresh-and-retry path is a real recovery mechanism, but transport-level
failures (timeouts, connection errors) are not caught or retried anywhere
in `ADHClient.swift` / `ADHClient+Raw.swift` — they propagate to the caller.
`error-recovery` is partial for the same reason: recovery is bounded to
that one 401 path. `idempotent-operations` is partial: the automatic
replay-on-401 resends the exact original request, including its body, once
with a new bearer, for any verb — with no idempotency key, assuming the
server never partially processed the 401'd attempt. `unit-test-coverage` is
partial: `ADHClientWiringTests.swift`, `RawJSONTests.swift`, and
`TransportResolverTests.swift`'s `resolvedClientUsesChosenTransport` cover
construction, the factories, typed round-trips, and the raw happy/error
paths well, but several paths are untested in the given sources — header-name
rejection, response-header collapse, an oversized raw response body, and
the daemon-session `port` override (Conformance Test Vectors 008, 013, 017,
018, none of which cite an existing test).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Claude Sonnet 5 | Initial creation |
