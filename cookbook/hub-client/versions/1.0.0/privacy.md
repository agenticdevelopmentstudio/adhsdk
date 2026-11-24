
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

