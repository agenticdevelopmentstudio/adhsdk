
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `STENOGRAPHER_URL` | environment variable | unset | Overrides the default base URL when it parses as a URL. |
| `baseURL` | `URL` | `defaultBaseURL` | Daemon address; the default is `StenographerIdentifiers.httpBaseURL`. |
| `session` | `URLSession` | `.shared` | Injected for tests with a stub protocol. |
| `healthPollInterval` | `TimeInterval` | 30 | Seconds between health polls once `onReconnect` has been called. |

