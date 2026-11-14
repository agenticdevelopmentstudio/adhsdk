---
id: e7262e09-e6f7-4152-acff-7fa09c242088
title: "Hub Client Sync"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-09-23
modified: 2026-09-23
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "ADHSyncAPI, the authenticated wire client for the backend's offline-sync pull/push endpoints, mapping HTTP status to typed failures without decoding bodies."
platforms:
  - swift
  - macos
  - ios
tags:
  - sync
  - networking
  - client
depends-on: []
related:
  - d3a0b65f-92c0-43c1-b04c-77638eb72044
references: []
approved-by: ""
approved-date: ""
---

# Hub Client Sync

## Overview

`ADHSyncAPI` is the authenticated wire client for the Agentic Developer Hub
backend's offline-sync endpoints, `GET /sync/pull` and `POST /sync/push`. Per
its own doc comment, it deliberately owns exactly three things — the request
URLs, attaching the caller's bearer credential, and mapping HTTP status codes
to a typed `Failure` — and decodes nothing: the wire shapes belong to the
backend and to the native sync core, so this package needs no sync-core
dependency. A host adapts `ADHSyncAPI` to the `SyncTransport` protocol the
sync engine (`offline-sync-client.md`) calls through, in about 20 lines,
per the same comment.

## Behavioral Requirements

### Initialization

- **default-base-url**: `ADHSyncAPI.init` MUST default `baseURL` to
  `DaemonContract.backendURL` (`"https://api.agenticdeveloperhub.com"`) when
  the caller supplies none.
- **default-session**: `ADHSyncAPI.init` MUST default `session` to
  `URLSession.shared` when the caller supplies none.
- **credentials-conformer-required**: `ADHSyncAPI.init` MUST require a
  `CredentialProvider` conformer for `credentials`; this parameter has no
  default value.
- **sendable-value-type**: `ADHSyncAPI` MUST be declared `Sendable`. It is a
  `struct` with three `let` stored properties (`baseURL: URL`,
  `credentials: any CredentialProvider`, `session: URLSession`), so an
  instance carries no mutable state and is safe to share across concurrency
  domains without additional synchronization.

### Pull

- **pull-http-method-and-path**: `pull(cursor:limit:)` MUST issue a `GET`
  request to `baseURL` with path `sync/pull` appended.
- **pull-limit-query-item**: `pull(cursor:limit:)` MUST always include a
  `limit` query item whose value is `String(limit)`.
- **pull-cursor-omitted-when-nil**: `pull(cursor:limit:)` MUST omit the
  `cursor` query item entirely when `cursor` is `nil`.
- **pull-cursor-query-item-verbatim**: `pull(cursor:limit:)` MUST include a
  `cursor` query item whose value is the exact string given, unmodified and
  unparsed, whenever `cursor` is non-`nil` — including an empty string.

### Push

- **push-http-method-and-path**: `push(body:)` MUST issue a `POST` request to
  `baseURL` with path `sync/push` appended, and MUST set the
  `Content-Type` header to `application/json`.
- **push-body-passthrough**: `push(body:)` MUST set the exact `Data` it is
  given as the request's `httpBody`, unmodified. It MUST NOT construct,
  encode, or validate the body's shape; the caller supplies a pre-encoded
  `SyncPushRequest`.

### Response Handling

`pull` and `push` both route their request through the same private
`perform(_:)`, so these requirements govern both.

- **success-returns-raw-body**: On a response whose status is in
  `200...299`, `perform` MUST return the response `Data` unmodified. It MUST
  NOT decode, parse, or otherwise inspect the body.
- **maps-401-to-unauthorized**: A `401` response MUST cause `perform` to
  throw `Failure.unauthorized`.
- **maps-410-to-resync-required**: A `410` response MUST cause `perform` to
  throw `Failure.resyncRequired`.
- **maps-other-status-to-http**: Any status outside `200...299`, `401`, and
  `410` MUST cause `perform` to throw `Failure.http(statusCode)` carrying
  only the numeric status code. The response body for these statuses MUST
  NOT be read, retained, or exposed by `Failure.http` — a `503` whose body
  is a JSON error object loses that body entirely, by construction (see
  Design Decisions).
- **maps-transport-errors**: Any error thrown by the underlying
  `URLSession.data(for:)` call — a network failure, a cancellation, or any
  other `Error` — MUST be caught and rethrown as
  `Failure.transport(String(describing: error))`.
- **maps-non-http-response**: A response that cannot be cast to
  `HTTPURLResponse` MUST cause `perform` to throw
  `Failure.transport("non-HTTP response")`.
- **failure-is-equatable**: `Failure` MUST conform to `Error`, `Sendable`,
  and `Equatable`, so callers and tests can compare a thrown failure by
  value.

### Authentication

This sub-section addresses the security concerns of token handling, per
[adc.guideline.cookbook.recipe-quality.cookbook-compliance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0d3aaa29-0ce3-4803-8f8a-a7023713b574)'s
requirement that a recipe involving token handling include one.

- **bearer-attached-per-request**: `perform` MUST read the current
  credential via `credentials.currentCredentials()` at the moment each
  request is made — never a value captured once at `init` — and, when
  `currentCredentials()?.token` is non-`nil`, MUST attach it as
  `Authorization: Bearer <token>`.
- **unauthenticated-when-absent**: When `credentials.currentCredentials()`
  returns `nil`, the request MUST be sent with no `Authorization` header
  rather than failing locally; the outcome is left to the server (typically
  a `401`, mapped by `maps-401-to-unauthorized`).
- **token-storage-and-lifetime-delegated**: `ADHSyncAPI` MUST NOT persist,
  cache, or itself manage the lifetime of the credential; it holds only a
  reference to the injected `CredentialProvider`. That provider owns
  storage and revocation — `KeychainCredentialStore` persists the token in
  the macOS Keychain until `clear()` is called, and `InMemoryCredentialStore`
  holds it only for the process's lifetime (both in
  `Auth/CredentialStore.swift`, grepped as the helper behind
  `CredentialProvider`, not part of `ADHSyncAPI.swift` itself). Both
  `Credentials.Kind` cases, `jwt` and `apiToken`, are sent identically as a
  bearer value; `ADHSyncAPI` does not distinguish them (`Auth/Credentials.swift`).
- **failure-excludes-credential**: Neither `Failure.transport` nor
  `Failure.http` MUST carry the bearer token or the request's headers —
  `Failure.transport`'s payload is the thrown `Error`'s own description (or
  the literal `"non-HTTP response"`), and `Failure.http`'s payload is only
  the numeric status code.

### Concurrency

- **no-internal-serialization**: `ADHSyncAPI` MUST NOT serialize or order
  concurrent `pull`/`push` calls against each other; each call is
  independent because the type holds no mutable state. Ordering guarantees
  across calls (e.g., applying pull pages in sequence) are the caller's
  responsibility — the sync engine that owns cursor state serializes
  through its own actor (`offline-sync-client.md`).

### Persistence and Caching

- **no-local-persistence**: `ADHSyncAPI` MUST NOT persist or cache request
  or response data. Every `pull`/`push` call performs exactly one round
  trip through `session.data(for:)` and returns.

## Appearance

Not applicable — this is a wire client for the sync API, not a visual
component.

## States

Not applicable — this is a wire client for the sync API, not a visual
component.

## Accessibility

Not applicable — this is a wire client for the sync API, not a visual
component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hub-client-sync-001 | default-base-url, default-session | Construct `ADHSyncAPI(credentials: someProvider)`, supplying neither `baseURL` nor `session` | The instance's `baseURL` equals `DaemonContract.backendURL`; its `session` equals `URLSession.shared`. Not independently asserted in `ADHSyncAPITests` — every test there overrides `session` to install `StubURLProtocol` — this follows directly from the default-parameter values on `ADHSyncAPI.init`. |
| hub-client-sync-002 | credentials-conformer-required | A call to `ADHSyncAPI.init` that omits the `credentials` argument | Fails to compile; `credentials` has no default value in the initializer's signature. |
| hub-client-sync-003 | sendable-value-type | One `ADHSyncAPI` instance passed into two concurrently running `Task`s that each call `pull` | Both calls proceed independently with no compiler diagnostic and no data race; `ADHSyncAPI` is a `struct` with only `let` properties, declared `Sendable`. |
| hub-client-sync-004 | pull-http-method-and-path, pull-limit-query-item, bearer-attached-per-request | `pull(cursor: "abc123", limit: 250)` against a 200 stub, with credentials returning token `"tok-sync"` | Captured request has `httpMethod == "GET"`, path `"/sync/pull"`, query items containing `cursor=abc123` and `limit=250`, and header `Authorization` equal to `"Bearer tok-sync"` — `ADHSyncAPITests.pullRequestShape`. |
| hub-client-sync-005 | pull-cursor-omitted-when-nil | `pull(cursor: nil, limit: 500)` against a 200 stub | Captured request's query items contain no item named `cursor` — `ADHSyncAPITests.pullFirstSync`. |
| hub-client-sync-006 | pull-cursor-query-item-verbatim | `pull(cursor: "", limit: 10)` against a 200 stub | Captured request's query items include a `cursor` item whose value is the empty string, because `cursor` is non-`nil`. Not covered by an existing test; derived from the `if let cursor` branch in `pull(cursor:limit:)`. |
| hub-client-sync-007 | push-http-method-and-path | `push(body: <push-request fixture>)` against a 200 stub | Captured request has `httpMethod == "POST"`, `url?.path == "/sync/push"`, and header `Content-Type` equal to `"application/json"` — `ADHSyncAPITests.pushRoundTrip`. |
| hub-client-sync-008 | push-body-passthrough | `push(body: <push-request fixture bytes>)` | Captured request's `httpBody` is byte-identical to the fixture's bytes, with no transformation applied — `ADHSyncAPITests.pushRoundTrip` (the same fixture is used to build the request and is not re-derived by `ADHSyncAPI`). |
| hub-client-sync-009 | success-returns-raw-body | `pull` and `push` each against a 200 stub whose body is `pull-response.json` / `push-response.json` | Returned `Data` equals the fixture bytes exactly; no JSON decoding is performed by `ADHSyncAPI` — `ADHSyncAPITests.pullRequestShape`, `pushRoundTrip`. |
| hub-client-sync-010 | maps-401-to-unauthorized, maps-410-to-resync-required, maps-other-status-to-http | `pull(cursor: nil, limit: 1)` against stubs returning, in turn, 401, 410, and 503, each with body `{"error":{"message":"x"}}` | Thrown `Failure` equals `.unauthorized`, `.resyncRequired`, and `.http(503)` respectively; the JSON error body is discarded in all three cases — none of the thrown `Failure` values carries it — `ADHSyncAPITests.errorMapping`. |
| hub-client-sync-011 | maps-transport-errors | `pull(cursor: nil, limit: 1)` where `session.data(for:)` throws `URLError(.notConnectedToInternet)` | Thrown error is a `Failure.transport` (case match only; the associated string is `String(describing: error)` and is not asserted verbatim) — `ADHSyncAPITests.transportFailureMapping`. |
| hub-client-sync-012 | maps-non-http-response | `pull` or `push` where the underlying `URLResponse` is not an `HTTPURLResponse` | Thrown error is `Failure.transport("non-HTTP response")`. Not covered by an existing test — `StubURLProtocol` always answers with an `HTTPURLResponse` — derived from the `guard let http = response as? HTTPURLResponse else` branch in `perform`. |
| hub-client-sync-013 | failure-is-equatable | Compare two `Failure.http(503)` values, and separately compare `Failure.unauthorized` against `Failure.resyncRequired` | `Failure.http(503) == Failure.http(503)` is `true`; `Failure.unauthorized == Failure.resyncRequired` is `false` — traced to `Failure: Error, Sendable, Equatable`; exercised implicitly by `ADHSyncAPITests.errorMapping`'s `#expect(throws: expected)`. |
| hub-client-sync-014 | unauthenticated-when-absent | `pull` or `push` where `credentials.currentCredentials()` returns `nil` | Captured request carries no `Authorization` header. Not covered by an existing test — every case in `ADHSyncAPITests` constructs `InMemoryCredentialStore` with a non-`nil` credential — derived from the `if let token = ...` branch in `perform`. |
| hub-client-sync-015 | token-storage-and-lifetime-delegated, failure-excludes-credential | Inspect the `Failure` values thrown during `errorMapping`/`transportFailureMapping`, and inspect `ADHSyncAPI`'s stored properties | Neither thrown `Failure` case nor any `ADHSyncAPI` property holds the bearer token string; `Credentials`'s `description` prints `"<redacted>"` in place of the token when interpolated — traced to `Auth/Credentials.swift`'s `CustomStringConvertible` conformance, and to `ADHSyncAPI`'s three stored properties, none of which is a bare token. |
| hub-client-sync-016 | no-internal-serialization | Two concurrent `pull` calls, with different cursors, issued on the same `ADHSyncAPI` instance | Both requests are sent independently with no shared mutable state touched between them. Not covered by an existing test; derived from `ADHSyncAPI` having only `let` stored properties. |
| hub-client-sync-017 | no-local-persistence | Two sequential `pull` calls against stubs returning different bodies each time | Each call returns exactly the body from its own stub response; no value from the first call is reused or cached by the second. Not covered by an existing test; derived from `perform` performing one `session.data(for:)` round trip per call with no cache. |

## Edge Cases

- **Nil cursor (first sync).** Input: `pull(cursor: nil, limit: N)`. The
  `cursor` query item is omitted entirely rather than sent as an empty or
  placeholder value. MUST — `pull-cursor-omitted-when-nil`,
  `ADHSyncAPITests.pullFirstSync`.
- **Empty-string cursor.** Input: `pull(cursor: "", limit: N)`. Because
  `""` is non-`nil`, it is sent as `cursor=` (an empty query value) rather
  than being treated as equivalent to `nil`. MUST —
  `pull-cursor-query-item-verbatim`.
- **Non-positive or oversized `limit`.** Input: `limit` of `0`, a negative
  number, or `Int.max`. `pull` performs no local validation or clamping;
  `String(limit)` is sent to the server unmodified, and any resulting
  rejection surfaces through the ordinary status-mapping path
  (`maps-other-status-to-http`). MUST — this is the observed behavior of
  `pull-limit-query-item`; no client-side bound exists in the source.
- **Concurrent calls on one instance.** Two or more `pull`/`push` calls
  issued concurrently on the same `ADHSyncAPI` value proceed independently;
  `ADHSyncAPI` has no shared mutable state to race on, and it enforces no
  ordering between the calls' completions. MUST — `no-internal-serialization`.
- **Missing or revoked credential.** Input: `credentials.currentCredentials()`
  returns `nil` (no token available), or returns a token the server no
  longer honors. The former sends the request unauthenticated; the latter
  is indistinguishable from any other `401` at this layer — both resolve
  through the server's response, mapped to `Failure.unauthorized`. MUST —
  `unauthenticated-when-absent`, `maps-401-to-unauthorized`.
- **Resync required.** Input: server responds `410`. `pull`/`push` throw
  `Failure.resyncRequired` and perform no local resync themselves — that
  policy belongs to the caller (`offline-sync-client.md`'s `SyncEngine`).
  MUST — `maps-410-to-resync-required`.
- **Unreachable server / offline device.** Input: `session.data(for:)`
  throws (verified in source with `URLError(.notConnectedToInternet)`).
  The call throws `Failure.transport(String(describing: error))`; no retry
  is attempted by `ADHSyncAPI` itself. MUST —
  `maps-transport-errors`, `ADHSyncAPITests.transportFailureMapping`.
- **Task cancellation mid-request.** Input: the calling `Task` is cancelled
  while `session.data(for:)` is in flight. `URLSession` surfaces this as a
  thrown error (typically `URLError(.cancelled)`), which `perform` catches
  through the same generic `catch` as any other transport error and
  rethrows as `Failure.transport(String(describing: error))`; a caller
  cannot distinguish a user-cancelled request from any other transport
  failure except by inspecting that description string, which is not
  documented as a stable format. MUST — `maps-transport-errors` (this is
  the same code path; it is called out separately here because it is easy
  to overlook that cancellation is not a distinct `Failure` case).
- **Non-HTTP response.** Input: the `URLResponse` returned by
  `session.data(for:)` cannot be cast to `HTTPURLResponse`. `perform`
  throws `Failure.transport("non-HTTP response")`. MUST —
  `maps-non-http-response`.
- **Error body on a non-2xx, non-401, non-410 status.** Input: a `503`
  response body carrying a structured JSON error (as in
  `ADHSyncAPITests.errorMapping`'s `{"error":{"message":"x"}}` fixture).
  `Failure.http(503)` carries only the status code; the body is never read
  for these statuses. MUST — `maps-other-status-to-http`.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `baseURL` | `URL` | `DaemonContract.backendURL` | Base URL the two endpoint paths are appended to. Caller-overridable; tests override it implicitly by installing `StubURLProtocol` on the `session` instead. |
| `credentials` | `any CredentialProvider` | none (required) | Supplies the bearer token, read fresh via `currentCredentials()` on every request. |
| `session` | `URLSession` | `.shared` | The `URLSession` `perform` issues requests through. |
| `cursor` (pull parameter) | `String?` | `nil` | Opaque, server-issued sync cursor; omitted from the query when `nil`. |
| `limit` (pull parameter) | `Int` | none (required) | Requested page size for `/sync/pull`; forwarded to the server without local validation. |
| `body` (push parameter) | `Data` | none (required) | Pre-encoded `SyncPushRequest` JSON; forwarded to the server without local validation. |

No environment variables or persisted settings keys are read by this source.

## Deep Linking

Not applicable: `ADHSyncAPI` is a headless wire client with no URL scheme or
app route of its own; its `baseURL`-relative paths (`sync/pull`, `sync/push`)
are HTTP API endpoints, not deep links.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — hardcoded, not looked up by key) | `"non-HTTP response"` | Literal string embedded in `Failure.transport("non-HTTP response")`, produced when `perform`'s response cannot be cast to `HTTPURLResponse`. It is English-only and not routed through any string catalog or localization mechanism. |

`Failure.transport(String(describing: error))`'s other payload comes from the
underlying `Error`'s own, unlocalized description — it is not authored by
`ADHSyncAPI` and carries whatever language `URLError`/`Error` produces.

## Accessibility Options

Not applicable: `ADHSyncAPI` has no visual surface, so it responds to none of
Reduce Motion, Increase Contrast, or Differentiate Without Color.

## Feature Flags

Not applicable: no flag key, feature-toggle field, or conditional gate
appears anywhere in `ADHSyncAPI.swift`; both `pull` and `push` are always
available.

## Analytics

Not applicable: no analytics event type, tracking call, or telemetry hook
appears anywhere in `ADHSyncAPI.swift`.

## Privacy

- **Data collected**: `ADHSyncAPI` does not collect data on its own; it
  forwards whatever `cursor`, `limit`, and pre-encoded `body` the caller
  supplies to `pull`/`push`, plus the bearer token obtained from the
  injected `CredentialProvider`'s `currentCredentials()`.
- **Storage**: `ADHSyncAPI` itself stores nothing — none of its three
  stored properties (`baseURL`, `credentials`, `session`) is a credential,
  cursor, or response body. Storage of the credential is entirely the
  injected `CredentialProvider`'s concern: `KeychainCredentialStore`
  persists it in the macOS Keychain until `clear()` is called;
  `InMemoryCredentialStore` holds it only for the process's lifetime
  (`Auth/CredentialStore.swift`).
- **Transmission**: The bearer token leaves the process on every
  `pull`/`push` call, as an `Authorization: Bearer <token>` header, over
  whatever scheme `baseURL` uses. `ADHSyncAPI` does not itself validate or
  reject a non-`https` `baseURL`, though its own default
  (`DaemonContract.backendURL`) is `https`. The push request body and the
  pull/push response bodies also cross the process boundary over that same
  connection; `ADHSyncAPI` adds no encryption of its own beyond what the
  transport (TLS, when `baseURL` is `https`) provides.
- **Retention**: Not applicable to `ADHSyncAPI` — it retains nothing after
  a call returns. Credential retention is the injected
  `CredentialProvider`'s policy (see Storage above); this source specifies
  no retention duration.

## Logging

Not applicable: no log, print, or diagnostic-emission call appears anywhere
in `ADHSyncAPI.swift`; every failure is communicated to the caller by
throwing a typed `Failure` value, never by writing to a log.

## Platform Notes

- **SwiftUI** (source platform — apple, `macOS 14.0` / `iOS 17.0`, one
  multi-destination target): `ADHSyncAPI.swift`
  (`packages/apple/AgenticDeveloperHubClient/Sources/Sync/ADHSyncAPI.swift`)
  and its tests, `ADHSyncAPITests.swift`
  (`.../Tests/AgenticDeveloperHubClientTests/`, using `StubURLProtocol`).
  Built on `URLSession`/`async`/`await` directly, importing
  `FoundationEssentials` where available
  (`#if canImport(FoundationEssentials)`), a `Sendable` value type, and the
  sibling `CredentialProvider`/`Credentials` types under `Auth/`.
- **Compose** (Android/Kotlin): start from `OkHttpClient` (or Ktor's
  `HttpClient`) for the two requests, a pair of `kotlinx.coroutines`
  `suspend fun`s mirroring `pull`/`push`, and a sealed interface
  (`Unauthorized` / `ResyncRequired` / `Http(code: Int)` /
  `Transport(message: String)`) matching `Failure`'s four cases exactly.
  Read the bearer token from an injected credential interface on every
  call — the same way `credentials.currentCredentials()` is read fresh
  inside `perform` — rather than capturing it once at construction.
- **React/Web**: start from `fetch` (or the project's existing HTTP
  wrapper) with two `async` functions mirroring `pull`/`push`, a
  discriminated union mirroring `Failure` (`{ kind: "unauthorized" }`,
  `{ kind: "resyncRequired" }`, `{ kind: "http", status: number }`,
  `{ kind: "transport", message: string }`), and a credential accessor
  called at request time rather than captured once.
- **AppKit / UIKit**: no change from the SwiftUI bullet — `ADHSyncAPI` has
  no UI layer; both AppKit and UIKit hosts consume the same
  `AgenticDeveloperHubClient` package target unmodified.
- **WinUI 3**: start from `System.Net.Http.HttpClient` for the two calls
  (`GetAsync("sync/pull?...")`, `PostAsync("sync/push", ...)`), reaching for
  `System.Text.Json` only if a port chooses to decode — this source does
  not — and `Task`/`async`/`await` for the asynchronous surface. Model
  `Failure` as four small exception types or a discriminated result
  (`UnauthorizedSyncException`, `ResyncRequiredSyncException`,
  `HttpSyncException(int statusCode)`, `TransportSyncException(string message)`)
  thrown from the two methods. Read the bearer token from an injected
  `ICredentialProvider.CurrentCredentials()` on every request — never
  cached on the client object, mirroring `credentials.currentCredentials()`
  being called inside `perform` rather than once in the constructor — and
  attach it via
  `request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token)`.
  Credential storage (a DPAPI-backed store, mirroring
  `KeychainCredentialStore`) belongs to whatever `ICredentialProvider`
  implementation a Windows port pairs with this client, not to the client
  itself.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubClient/Sources/Sync/ADHSyncAPI.swift` | unverified |

## Design Decisions

- **Decision**: `Failure.http(Int)` carries only the numeric status code,
  never the response body.
  **Rationale**: `perform`'s switch discards `data` for every branch except
  `200...299`. `ADHSyncAPI`'s own doc comment scopes its job narrowly to
  "URLs, auth, and HTTP error mapping," not error-body diagnostics — a
  caller that needs the server's structured error detail (as
  `ADHSyncAPITests.errorMapping`'s `{"error":{"message":"x"}}` stub
  happens to include) cannot get it from this type; it would need its own
  additional read of the response.
  **Approved**: pending

- **Decision**: `ADHSyncAPI` performs no retry, backoff, or timeout
  customization of its own.
  **Rationale**: every call is a single attempt. The type's doc comment
  scopes it to URLs, auth, and error mapping only; the sibling
  `offline-sync-client.md` recipe's `SyncEngine` — not this type — owns
  retry, backoff, and treating `resyncRequired`/`unauthorized` as
  engine-level pause/reset triggers.
  **Approved**: pending

- **Decision**: the bearer credential is read via
  `credentials.currentCredentials()` inside `perform` on every call, never
  captured once at `init`.
  **Rationale**: `CredentialProvider`'s own doc comment states this is
  deliberate — a token rotation (a refresh, or a freshly issued API token)
  takes effect on the very next call with no need to rebuild the client.
  **Approved**: pending

- **Decision**: an absent credential (`currentCredentials() == nil`) sends
  the request unauthenticated rather than failing locally.
  **Rationale**: `ADHSyncAPI` has no opinion on whether a given endpoint
  requires authentication; letting the server answer (typically `401`,
  mapped to `Failure.unauthorized`) keeps that policy in one place instead
  of duplicating it client-side.
  **Approved**: pending

- **Decision**: `baseURL` is caller-overridable with no scheme validation —
  a non-`https` value is not rejected.
  **Rationale**: `ADHSyncAPITests` substitutes `StubURLProtocol` rather
  than a real host, which requires an overridable `baseURL`; the type's
  own default (`DaemonContract.backendURL`) is `https`. Enforcing TLS
  inside `ADHSyncAPI` would duplicate what `secure-transport` already
  expects of any production caller while blocking the test seam this type
  is built around.
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
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | reliability |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | partial | reliability |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | passed | reliability |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | partial | reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |

`secure-transport` is `partial`: the default `baseURL` is `https`, but
`ADHSyncAPI` does not itself reject a caller-supplied non-`https` value (see
Design Decisions). `token-lifecycle` is `partial`: `ADHSyncAPI` neither
issues nor refreshes tokens nor enforces a lifetime — that is fully delegated
to the injected `CredentialProvider`, and neither `CredentialStore.swift` nor
`Credentials.swift` defines an expiry or rotation policy for the `jwt` kind.
`secure-data-storage` is `passed` on the basis that `ADHSyncAPI` persists
nothing itself and delegates all storage to the `CredentialProvider`
(`KeychainCredentialStore` is Keychain-backed). `error-recovery` is
`partial`: failures are always surfaced as a typed `Failure`, but no retry of
a transient failure is attempted at this layer (delegated to the caller).
`idempotent-operations` is `partial`: `push` forwards the caller's body
verbatim with no idempotency key or dedup logic of its own; the opId-based
idempotency `offline-sync-client.md` describes is enforced by the caller's
`SyncEngine`, not by this transport. `unit-test-coverage` is `partial`:
`ADHSyncAPITests` covers the pull/push request shape and the three explicit
status mappings plus one transport failure, but not the nil-credential path,
the non-HTTP-response path, or the default `baseURL`/`session` values (see
Conformance Test Vectors 001, 002, 006, 012, 014, 016, and 017, none of which
cite an existing test).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Claude Sonnet 5 | Initial creation |
