
Subsystem: main bundle identifier (`Loggable.subsystem`) | Category: `ClaudeAuthEvaluator`

| Event | Level | Message |
|-------|-------|---------|
| Expired credential with no item key, refresh refused | error | `token-evaluator: <account> is expired but carries no keychain item key — refusing to spend its refresh token on a rotation nothing could store` |
| Refresh refused by the endpoint during a round | error | `token-evaluator: can't refresh <account>: <shortText>` |
| Refresh failed with a foreign error during a round | error | `token-evaluator: can't refresh <account>: <localized description>` |
| Renewal refused by the endpoint | error | `token-evaluator: can't renew a login: <shortText>` |
| Renewal failed with a foreign error | error | `token-evaluator: can't renew a login: <localized description>` |

The account and reason are interpolated with `privacy: .public`, so the account email is visible in unified-log output. Successful refreshes and classifications are not logged. `ClaudeTokenRefresher` and `AccountFingerprints` log nothing: the refresher reports through its thrown error, and fingerprint misses return `""`.

