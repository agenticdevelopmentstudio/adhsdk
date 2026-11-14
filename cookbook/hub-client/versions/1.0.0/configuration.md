
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `transport` | `APITransport` | none (required) | The `(serverURL, transport)` seam every request routes through. |
| `credentials` (bearer-only init/factories) | `any CredentialStore` | `KeychainCredentialStore()` | Backs `AuthenticationMiddleware`; storage is `hub-client-auth`'s contract. |
| `session` (session-backed init/factories) | `any SessionStore` | none (required) | Backs `SessionRefreshMiddleware`. |
| `onSessionExpired` | `@Sendable () -> Void` | `{}` (no-op) | Called when a refresh is rejected and the session store has been cleared. |
| `resolver` (`.resolved` parameter) | `TransportResolver` | `TransportResolver()` (auto-probing) | Decides Direct vs. Daemon; probing/caching is `hub-client-transport`'s contract. |
| `port` (`.daemon(session:port:)` parameter) | `Int` | `DaemonContract.port` (`22850`) | Loopback port the daemon-backed session client targets. |
| `rawJSON`: `method` | `HTTPRequest.Method` | none (required) | The HTTP method for the raw request. |
| `rawJSON`: `path` | `String` | none (required) | Must start with `/`; rejected otherwise. |
| `rawJSON`: `query` | `[String: String]` | `[:]` | Sorted and percent-encoded onto `path`. |
| `rawJSON`: `body` | `Data?` | `nil` | Sent verbatim; presence alone controls the default `Content-Type`. |
| `rawJSON`: `headers` | `[String: String]` | `[:]` | Applied after, and able to override, the default `Accept` / `Content-Type` headers. |
| `ADHBodyLimit.maxBuffered` | `Int` (internal constant, not caller-configurable) | `16 * 1024 * 1024` | Shared cap for `rawJSON`'s response-body collection and (via `hub-client-auth`) `SessionRefreshMiddleware`'s request-body buffering. |

