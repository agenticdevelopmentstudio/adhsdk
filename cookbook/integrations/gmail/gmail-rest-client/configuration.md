
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `session` | `URLSession` | `.shared` | The transport. Supplies the request timeout and TLS behavior; tests pass a stubbed session. |
| `sleep` | `@Sendable (Duration) async throws -> Void` | `Task.sleep(for:)` | Waits out a pacing delay or a backoff. Injected so tests record delays. |
| `pacer` | `GmailQuotaPacer` | `.shared` | Reserves quota per attempt; `shared` runs 200 units per second with a 200-unit burst for the whole process. |
| `accessToken` | `@Sendable () async throws -> String` | none (required) | Returns a fresh bearer token each time a request is built. |

Constants the caller cannot set; a port keeps them fixed and does not expose them as options.

| Constant | Type | Value | Description |
|----------|------|-------|-------------|
| `baseURL` | `String` (private) | `https://gmail.googleapis.com/gmail/v1/users/me/` | Prefix of every request. |
| `maxRetries` | `Int` (internal) | `6` | Retries per call after the first attempt. |
| `baseDelay` | `Duration` (private) | 1 second | Backoff start; doubles per retry. |
| `maxDelay` | `Duration` (private) | 32 seconds | Cap for any backoff, including a `Retry-After` value. |
| `batchModifyLimit` | `Int` (public) | `1000` | Most ids per `batchModify` call. |
| `transientCodes` | `Set<URLError.Code>` (private) | `timedOut`, `networkConnectionLost`, `notConnectedToInternet`, `cannotConnectToHost` | Network errors that are retried. |
| `listMessageIds` page size | `Int` (literal) | `500` | Sent as `maxResults`; `searchMessageIds` takes it from the caller. |

There are no environment variables or settings keys.
