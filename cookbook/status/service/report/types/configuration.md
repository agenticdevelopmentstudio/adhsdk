
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `range` | `24h`, `7d` or `30d` | `24h` | Analytics window for the analytics section |
| `days` | integer 1-365 | 7 | Uptime window in days |
| `wait` | integer 0-60 | 20 | Seconds to wait for cold dashboards to finish their first read |
| `logs` | boolean (`0` or `1` on the wire) | false | Attach the build-log tail to failing deploys |

