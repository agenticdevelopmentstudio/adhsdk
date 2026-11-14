
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

