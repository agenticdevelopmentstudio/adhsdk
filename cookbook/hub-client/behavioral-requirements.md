
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

