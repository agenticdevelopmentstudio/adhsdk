
- **Decision**: `Failure.http(Int)` carries only the numeric status code,
  never the response body.
  **Rationale**: the status mapping discards `data` for every branch except
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
  [adhsdk.ingredient.data.sync.offline-sync-client](cookbook:d3a0b65f-92c0-43c1-b04c-77638eb72044) ingredient's `SyncEngine` — not this type — owns
  retry, backoff, and treating `resyncRequired`/`unauthorized` as
  engine-level pause/reset triggers.
  **Approved**: pending

- **Decision**: the bearer credential is read via
  `credentials.currentCredentials()` on every call, never
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
  inside `ADHSyncAPI` would duplicate what [secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) already
  expects of any production caller while blocking the test seam this type
  is built around.
  **Approved**: pending


- **Decision**: cancellation is not a distinct `Failure` case; it arrives as
  `Failure.transport` like any other error from the underlying call.
  **Rationale**: `Failure` is kept to the four outcomes the sync engine acts on
  (`unauthorized`, `resyncRequired`, `http`, `transport`), and the type's scope is URLs,
  auth and status mapping. A caller that must tell a cancelled request apart can only
  inspect the unstable description string; a port MAY add a `cancelled` case.
  **Approved**: pending
