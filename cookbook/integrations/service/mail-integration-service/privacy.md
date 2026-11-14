
- **Data collected**: Email addresses of connected accounts, Gmail message metadata, snippets and (on request) bodies, label names, and the Google OAuth client id.
- **Storage**: The OAuth client secret and each account's Google credential are stored in the Keychain through `SecretStoring` (`GoogleTokenProvider.clientSecretKey` and `GoogleTokenProvider.key(connectionId:)`). Connections, labels, mirrored messages and action logs are stored in `IntegrationsStore`. Searches, threads and messages read only to resolve an id are not stored.
- **Transmission**: Requests go to Google's token endpoint and to Gmail through the injected `GmailAPI`. A reply to a client never carries the client secret beyond its last 5 characters, and only when the secret has at least 15 characters; action log payloads hold message ids and label ids, not bodies.
- **Retention**: Mirrored mail is kept for `windowDays` (default 30) and only for allowed classes; older or disallowed rows are tombstoned. Removing an account revokes its Google grant (best effort), deletes its credential and connection; removing the provider also deletes the client config and secret.

