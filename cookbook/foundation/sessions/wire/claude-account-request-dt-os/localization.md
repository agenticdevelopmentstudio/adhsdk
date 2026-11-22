
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal) | The Stenographer app isn't running; only it can reach the saved accounts' keychain. | `ClaudeAccountRelay.noCustodianReason`, the refusal reason a user can see in `steno` output |
| (none; literal) | Usable | `ClaudeTokenState.usable.title`, quota card or CLI line |
| (none; literal) | Refreshed | `ClaudeTokenState.refreshed.title` |
| (none; literal) | Expired | `ClaudeTokenState.expired.title` |
| (none; literal) | Spent elsewhere | `ClaudeTokenState.spent.title` |
| (none; literal) | Rate limited | `ClaudeTokenState.rateLimited.title` |
| (none; literal) | Unknown — retry | `ClaudeTokenState.inconclusive.title` |
| (none; literal) | No expiry | `ClaudeTokenState.unknown.title` |

Every string here is a hardcoded English literal with no localization lookup. `noCustodianReason` MUST NOT be localized as things stand, because `steno` matches on its exact text; translating it would break that match. The `title` strings are display text with no such match on them.

