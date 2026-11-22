
No string is localized. The `detail` strings put into statuses and renewals, and `ClaudeOAuthRefreshError.errorDescription`, are hardcoded English.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; `ClaudeOAuthRefreshError.shortText`) | `login spent elsewhere — save it again` | `detail` for a `.spent` refusal. |
| (none; `ClaudeOAuthRefreshError.shortText`) | `rate limited — not a credential problem` | `detail` for a `.rateLimited` refusal. |
| (none; the reason the error carries) | e.g. `HTTP 503`, `the token endpoint returned no access token`, `the token endpoint answered with no status` | `detail` for `.inconclusive` / `.unsent`, shortened to 60 characters. |
| (none; `errorDescription`) | `This saved login was spent elsewhere — logging in or refreshing on another machine voids every older copy of its refresh token. Save the account again after a fresh login.` | Full description of `.spent`. |
| (none; `errorDescription`) | `Anthropic rate-limited the token refresh. The saved login is fine; this will work again shortly.` | Full description of `.rateLimited`. |
| (none; `errorDescription`) | `Couldn't refresh this saved login: <reason>` | Full description of `.inconclusive` and `.unsent`. |

