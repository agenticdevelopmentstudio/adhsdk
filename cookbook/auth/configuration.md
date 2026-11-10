
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `KeychainCredentialStore.keyPrefix` | `String` | `"adh.api"` | Namespaces the two Keychain account keys (`.token`, `.token.kind`); lets multiple independent stores share one Keychain service. |
| `KeychainSessionStore.keyPrefix` | `String` | `"adh.api"` | Namespaces the three Keychain account keys (`.token`, `.token.kind`, `.refresh`); shares its first two keys with `KeychainCredentialStore` under the same prefix. |
| `KeychainHelper.service` | `String` (`nonisolated(unsafe) static var`) | `Bundle.main.bundleIdentifier`, else a hardcoded reverse-DNS identifier naming the hub client | The Keychain `kSecAttrService` every key is scoped under. |
| `InMemoryCredentialStore.init(_:)` | `Credentials?` | `nil` | Seeds the in-memory credential for tests or ephemeral, non-persisted sessions. |
| `InMemorySessionStore.init(_:)` | `Session?` | `nil` | Seeds the in-memory session for tests or ephemeral, non-persisted sessions. |
| `AuthenticationMiddleware.credentials` | `any CredentialProvider` | — (required) | Injected dependency the middleware reads at send time. |
| `SessionRefreshMiddleware.session` | `any SessionStore` | — (required) | Injected dependency read and written for bearer injection and refresh persistence. |
| `SessionRefreshMiddleware.onSessionExpired` | `@Sendable () -> Void` | `{}` (no-op) | Called when a refresh is `.rejected` and the store has been cleared. |
| `ADHBodyLimit.maxBuffered` | `Int` | `16 * 1024 * 1024` (16 MiB) | Shared cap for the request-body buffering `SessionRefreshMiddleware` needs to retry, and for `rawJSON`'s response-body collection. |
| `createAPIToken(name:expiresAt:)` | `String`, `Date?` | `expiresAt: nil` | Name and optional expiry for a minted long-lived API token. |
| `exchangeOAuthCode(_:userAgent:)` | `String`, `String?` | `userAgent: nil` | The exchange code and, for native callers, the captured browser `User-Agent` the code was bound to. |

