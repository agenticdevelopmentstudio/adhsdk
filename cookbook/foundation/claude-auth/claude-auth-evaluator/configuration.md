
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `now` (on `state`, `evaluate`, `status`, `refresh`, `rotated`, `isAccessTokenUsable`, `publish`) | `Date` (`Double` on `merge`) | `Date()` at call time | The instant expiries are compared against and fingerprints are stamped with. |
| `refresh` (on `evaluate`) | `Refresher?` | `liveRefresher` | The refresh operation; `nil` selects classify-only mode. |
| `refresh` (on `renew`) | `Refresher` | `liveRefresher` | The refresh operation; not optional. |
| `ClaudeCredentialDTO.refreshWithin` | `Double?` (seconds) | `nil` | Widens the refresh margin for one evaluation. |
| `margin` (on `isAccessTokenUsable`) | `TimeInterval?` | `nil` | Widens the 300-second margin; never narrows it. |
| `ClaudeTokenRefresher.refreshMargin` | `TimeInterval` constant | 300 s | Minimum margin below which an access token counts as expired. |
| `ClaudeTokenRefresher.tokenURL` | `URL` constant | `https://platform.claude.com/v1/oauth/token` | Claude Code's OAuth token endpoint. |
| `ClaudeTokenRefresher.clientID` | `String` constant | `9d1c250a-e61b-44d9-88ed-5944d1962f5e` | Claude Code's OAuth client id. |
| `ClaudeTokenRefresher.beta` | `String` constant | `oauth-2025-04-20` | The `anthropic-beta` header value. |
| `ClaudeTokenRefresher.userAgent` | `String` constant | `Stenographer (macOS)` | Names the client so Cloudflare does not reject it (403, "error code: 1010"); `AccountQuotaProbe` reuses it. |
| Request timeout | private constant | 15 s | Bounds each live refresh. |
| Assumed access life | private constant | 8 h (28 800 s) | Used when the reply omits `expires_in`. |
| `path` (on `accountName`, `publish`) | `String` | `AccountFingerprints.defaultPath` | Fingerprints file location; tests and `CredentialFence` inject their own. |
| `AccountFingerprints.historyPerAccount` | `Int` constant | 8 | Fingerprints kept per account. |
| `detail` length | constant | 60 characters | `String.shortened()` default ([adhsdk.ingredient.foundation.text.short-text](cookbook:0de17653-f56d-418f-b212-33e9017972cd)). |
| Logger subsystem / category | `Loggable` defaults | main bundle identifier / `ClaudeAuthEvaluator` | Where the evaluator's error lines go. |

No environment variable or settings key is read. The fingerprints file's directory comes from `StenographerPaths` ([adhsdk.ingredient.foundation.stenographer.stenographer-identifiers](cookbook:b6d96b0b-3ca0-48ac-8e94-a25a8ee68e43)), which follows the Stenographer instance's data root.

