
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| wire coding strategy | snake_case keys | caller's coder | The types expect a coder that converts snake_case wire keys to the camelCase property names, such as `StenographerWire`. |
| `RateLimitSnapshotDTO` optional initializer parameters | String, Double, Int | `""`, `0`, `0` | `accountEmail`, `spendPct`, `spendResetsAt`. |
| `UsageRowsDTO` optional initializer parameters | lists, optional, String | `[]`, nil, `""` | `hoursRows`, `accountSections`, `hudQuota`, `oauthEmail`. |
| `UsageQuotaRowDTO` optional initializer parameters | String, Bool, optionals | `""`, `false`, nil | Everything except `label` and `pctText`. |
| `ClaudeCredentialDTO.refreshWithin` | Double (seconds) | nil | Per-evaluation expiry margin override, set only when a token is handed to a terminal. |
| `UsageQuotaRowDTO.minimumProjectionElapsed` | Double | `0.01` | Share of a window elapsed before pace and run-out are projected. |
| `headers` (`AccountQuotaReadingDTO`) | String-to-String map | required | One probe's response headers with lower-cased keys. |

