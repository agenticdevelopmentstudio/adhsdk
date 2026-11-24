
- **Data handled**: `secrets` carries credentials such as API keys in plain text inside the struct and its encoded body, alongside the non-secret `values`.
- **Storage**: None by the types. The daemon persists non-secret values in its settings table and secrets in the keychain (the keychain service is injected into the daemon's `SecretStoring`; the identifiers define one per daemon, `ADKDIdentifiers.keychainService` for the Kitchen daemon and `StenographerIdentifiers.daemonKeychainService` for Stenographer's); those writes are outside this file.
- **Transmission**: The body travels from app to daemon over loopback HTTP or XPC. The types add no encryption; no timeout, idempotency key or redaction exists in them.
- **Retention**: Not applicable to the types; the daemon keeps a configuration until a sync deletes it.

