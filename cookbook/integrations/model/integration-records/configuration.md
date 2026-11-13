
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `provider` | String | `"gmail"` | Provider tag on connections, messages and action logs |
| `providerId` | String | `"gmail"` | Provider tag on `ProviderConfig` |
| `sourceProvider` | String | `"gmail"` | Provider tag on `EmailLabel` |
| `serviceType` | String | `"messages"` | Service on `IntegrationConnection` |
| `status` (connection) | ConnectionStatus | `.pending` | Initial connection state |
| `status` (action log) | String | `"pending"` | Initial action state |
| `syncSettings` | MailSyncSettings | `.default` | Mirroring settings stored as JSON text |
| `enabled` | Bool | `true` | Provider config switch |
| `type` | String | `"user"` | Label kind |
| `createdAt`, `updatedAt` | String | `IntegrationClock.now()` | Timestamps |

