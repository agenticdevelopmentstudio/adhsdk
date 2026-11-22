
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `baseURL` | `URL` | none (required) | The HTTP implementation's daemon address, passed by its caller; there is no default. |
| `healthPollInterval` | seconds | 30 | How often the implementation polls `/health` for restarts. |
| `session` | `URLSession` | `.shared` | The injected transport of the HTTP implementation. |

Request timeouts (10, 15 and 605 seconds, see impl-timeouts) are fixed in the implementation and are not configurable.
