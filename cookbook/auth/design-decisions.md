
- **Decision**: Buffer the entire outgoing request body (not just failing ones) up to a single shared 16 MiB cap (`ADHBodyLimit.maxBuffered`), reused by both `SessionRefreshMiddleware`'s retry-resend and `rawJSON`'s response collection.
  **Rationale**: A retry after refresh must resend byte-identical content; buffering only on failure would require re-deriving the body from the caller, which the middleware has no way to do generically. A single shared limit avoids two independently-tuned buffering policies for what is the same underlying concern.
  **Approved**: pending

- **Decision**: Route `signOut()`'s revoke call through `rawJSON` with a hand-built `{"refreshToken": …}` body, rather than the generated `postAuthRevoke` operation.
  **Rationale**: The committed `openapi.json` still documents `POST /auth/revoke` as a bodiless 204, but the backend requires the refresh token in the body to actually revoke it; the generated client can only express the documented (stale) contract, so the raw escape hatch is the only way to send a request that revokes anything.
  **Approved**: pending

- **Decision**: Serialize every refresh through one process-wide `RefreshCoordinator.shared` actor, keyed by the expired access token, rather than one coordinator per `SessionRefreshMiddleware` instance.
  **Rationale**: The refresh token is single-use and lives in a `SessionStore` that multiple `ADHClient`s (e.g. two view models) can share; a per-instance coordinator would let two clients each lead a refresh, and the loser's replay of the already-spent refresh token would be rejected by the server, incorrectly clearing the session the winner just saved.
  **Approved**: pending

- **Decision**: On macOS, leave Keychain items on the implicit accessibility default rather than setting `kSecAttrAccessible` explicitly; on iOS, always set `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
  **Rationale**: macOS's file-based legacy Keychain rejects or ignores an explicit accessibility class unless the item also opts into the data-protection Keychain (`kSecUseDataProtectionKeychain`), and making that switch would strand items already stored under the legacy Keychain by existing callers. iOS has no such legacy-Keychain constraint, so it gets the stricter, device-local class outright.
  **Approved**: pending

- **Decision**: `createAPIToken` never writes to the credential store; only `adopt(_:)` does.
  **Rationale**: Minting a new long-lived API token is a distinct action from switching the active session to it — a caller (e.g. one creating a token to hand to a daemon or a CI secret) must not have their own active session silently replaced as a side effect of minting.
  **Approved**: pending

- **Decision**: Derive `SessionRefreshMiddleware.exemptOperationIDs` from the generated `Operations.X.id` constants, never from hand-written string literals.
  **Rationale**: The runtime hands `intercept` the generator's path-style operation ID (e.g. `"post/auth/login"`), not the Swift method name (`postAuthLogin`); a hand-written literal cannot be checked by the compiler and silently stops matching if the OpenAPI spec (and therefore the generated ID) changes, while a constant reference fails to compile instead.
  **Approved**: pending

- **Decision**: `Credentials` and `Session` both override `CustomStringConvertible`/`CustomDebugStringConvertible` to redact every token value.
  **Rationale**: The default reflection-based description prints every stored property verbatim; an app's `logger.error("\(credentials)")` or a failed `#expect(a == b)` test assertion would otherwise spill a live bearer or refresh token into a log or test report.
  **Approved**: pending

- **Decision**: `KeychainSessionStore` and `KeychainCredentialStore` share the same `<prefix>.token` / `<prefix>.token.kind` key names under a matching prefix.
  **Rationale**: This lets a credential saved by the older, session-agnostic store be read back by the newer session-aware store as a session with no refresh token, and vice versa, without a data migration step when a caller switches between the two.
  **Approved**: pending

