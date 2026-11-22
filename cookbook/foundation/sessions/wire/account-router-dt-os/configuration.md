
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `AccountRouterStatusDTO.defaultCooldownSeconds` | `Int` | `60` | Cool-down used when a status omits `cooldownSeconds`, and the initializer's default. |
| `AccountRouterStatusDTO.defaultExpiryMarginSeconds` | `Int` | `300` | Expiry margin used when a status omits `expiryMarginSeconds`. |
| `AccountRouterStatusDTO.defaultRetentionDays` | `Int` | `30` | Retention used when a status omits `retentionDays`. |
| `AccountRouterStatusDTO.retry` default | `Bool` | `true` | Used when a status omits `retry`. |
| `AccountRouterStatusDTO.sticky` default | `Bool` | `true` | Used when a status omits `sticky`. |
| `AccountRouterExchangeQueryDTO.defaultLimit` | `Int` | `200` | Page size when `limit` is nil. |
| `AccountRouterExchangeQueryDTO.maxLimit` | `Int` | `1000` | Upper clamp for `effectiveLimit`. |
| `AccountRouterExchangeQueryDTO.verbatimAccount` | `String` | `"-"` | Account filter value for rows forwarded verbatim. |
| JSON key strategy | caller-supplied | none | The caller's encoder and decoder choose camelCase or snake_case on the wire; the daemon uses snake_case. |

