
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `baseURL` | String | none (required) | Base URL of the daemon; `health` is appended as a path component. |
| `timeout` | TimeInterval | `2` | Request timeout in seconds for each probe call. |
| Date decoding | fixed | ISO-8601 | The decoder's `dateDecodingStrategy`; not configurable. |
| URL session | fixed | `.ephemeral` | The configuration of the session the probe creates; not configurable. |

