
### Initialization

- **default-base-url**: `ADHSyncAPI.init` MUST default `baseURL` to
  `DaemonContract.backendURL` when the caller supplies none.
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
  unparsed, whenever `cursor` is non-`nil`. An empty string is currently sent as
  `cursor=`; a port MAY treat it the same as `nil`.

### Push

- **push-http-method-and-path**: `push(body:)` MUST issue a `POST` request to
  `baseURL` with path `sync/push` appended, and MUST set the
  `Content-Type` header to `application/json`.
- **push-body-passthrough**: `push(body:)` MUST set the exact `Data` it is
  given as the request's `httpBody`, unmodified. It MUST NOT construct,
  encode, or validate the body's shape; the caller supplies a pre-encoded
  `SyncPushRequest`.

### Response Handling

These requirements govern both `pull` and `push`.

- **success-returns-raw-body**: On a response whose status is in
  `200...299`, `pull` and `push` MUST return the response `Data` unmodified. It MUST
  NOT decode, parse, or otherwise inspect the body.
- **maps-401-to-unauthorized**: A `401` response MUST cause `pull` and `push`
  to throw `Failure.unauthorized`.
- **maps-410-to-resync-required**: A `410` response MUST cause `pull` and `push`
  to throw `Failure.resyncRequired`.
- **maps-other-status-to-http**: Any status outside `200...299`, `401`, and
  `410` MUST cause `pull` and `push` to throw `Failure.http(statusCode)` carrying
  only the numeric status code. The response body for these statuses MUST
  NOT be read, retained, or exposed by `Failure.http` — a `503` whose body
  is a JSON error object loses that body entirely, by construction (see
  Design Decisions).
- **maps-transport-errors**: Any error thrown by the underlying
  `URLSession.data(for:)` call — a network failure, a cancellation, or any
  other `Error` — MUST be caught and rethrown as a
  `Failure.transport` whose payload is the error's description. Cancellation is
  not a separate case (see Design Decisions).
- **maps-non-http-response**: A response that cannot be cast to
  `HTTPURLResponse` MUST cause `pull` and `push` to throw
  `Failure.transport("non-HTTP response")`.
- **failure-is-equatable**: `Failure` MUST conform to `Error`, `Sendable`,
  and `Equatable`, so callers and tests can compare a thrown failure by
  value.

### Authentication

This sub-section addresses the security concerns of token handling, per
[adc.guideline.cookbook.recipe-quality.cookbook-compliance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0d3aaa29-0ce3-4803-8f8a-a7023713b574)'s
requirement that a recipe involving token handling include one.

- **bearer-attached-per-request**: `pull` and `push` MUST read the current
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
  `Auth/CredentialStore.swift`, not part of `ADHSyncAPI.swift` itself). Both
  `Credentials.Kind` cases, `jwt` and `apiToken`, are sent identically as a
  bearer value; `ADHSyncAPI` does not distinguish them (`Auth/Credentials.swift`).
- **failure-excludes-credential**: `Failure.transport` and `Failure.http` MUST NOT
  carry the bearer token or the request's headers —
  `Failure.transport`'s payload is the thrown `Error`'s own description (or
  the literal `"non-HTTP response"`), and `Failure.http`'s payload is only
  the numeric status code.

### Concurrency

- **no-internal-serialization**: `ADHSyncAPI` MUST NOT serialize or order
  concurrent `pull`/`push` calls against each other; each call is
  independent because the type holds no mutable state. Ordering guarantees
  across calls (e.g., applying pull pages in sequence) are the caller's
  responsibility — the sync engine that owns cursor state serializes
  through its own actor ([adhsdk.ingredient.data.sync.offline-sync-client](cookbook:d3a0b65f-92c0-43c1-b04c-77638eb72044)).

### Persistence and Caching

- **no-local-persistence**: `ADHSyncAPI` MUST NOT persist or cache request
  or response data. Every `pull`/`push` call performs exactly one round
  trip through `session.data(for:)` and returns.

