
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

