
- **Data collected**: The storage floor collects nothing; it stores whatever rows its caller writes. The account router's credential store holds the Claude account tokens a client relays (probe halves only, never a refresh token) and the router records each routed exchange's metadata.
- **Storage**: A plain, unencrypted SQLite database file (plus its companion write-ahead-log and shared-memory files) at the caller's configured path, typically inside a per-app dotfolder in the home directory; an in-memory database is never written to disk.
- **Transmission**: The storage floor performs no network I/O. The quota probe sends one `max_tokens=1` request per held account to the Anthropic API, and the router relays Claude Code's requests upstream; no route reply carries a token.
- **Retention**: Data persists until the caller deletes it or the file; the module deletes nothing.
- **Credential storage**: `KeychainAccountCredentialStore` keeps the relayed set in the Keychain, one item under the daemon's service; `InMemoryAccountCredentialStore` keeps nothing past the process.
