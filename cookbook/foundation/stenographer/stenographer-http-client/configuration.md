
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `baseURL` | `URL` | none (required) | Daemon address. There is no default: the retired stenographerd's `22847` is not assumed. |
| `session` | `URLSession` | `.shared` | Injected for tests with a stub protocol. |
| `healthPollInterval` | `TimeInterval` | 30 | Seconds between health polls once `onReconnect` has been called. |

