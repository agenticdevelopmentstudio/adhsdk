
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `session` | `URLSession` | `.shared` | The transport. Supplies the request timeout and TLS behavior; tests pass a stubbed session. |
| `sleep` | `@Sendable (Duration) async throws -> Void` | `Task.sleep(for:)` | Waits out a pacing delay or a backoff. Injected so tests record delays. |
| `pacer` | `GmailQuotaPacer` | `.shared` | Reserves quota per attempt; `shared` runs 200 units per second with a 200-unit burst for the whole process. |
| `accessToken` | `@Sendable () async throws -> String` | none (required) | Returns a fresh bearer token each time a request is built. |
| `baseURL` | `String` (private constant) | `https://gmail.googleapis.com/gmail/v1/users/me/` | Not configurable by the caller. |
| `maxRetries` | `Int` (internal constant) | `6` | Retries per call after the first attempt. |
| `baseDelay` | `Duration` (private constant) | 1 second | Backoff start; doubles per retry. |
| `maxDelay` | `Duration` (private constant) | 32 seconds | Cap for any backoff, including a `Retry-After` value. |
| `batchModifyLimit` | `Int` (public constant) | `1000` | Most ids per `batchModify` call. |
| `transientCodes` | `Set<URLError.Code>` (private constant) | `timedOut`, `networkConnectionLost`, `notConnectedToInternet`, `cannotConnectToHost` | Network errors that are retried. |
| `listMessageIds` page size | `Int` (literal) | `500` | Sent as `maxResults`; `searchMessageIds` takes it from the caller. |

There are no environment variables or settings keys.

