
The module contains one hardcoded English string, `"down"`, used as the last-resort `detail` of a `StaleMonitor`, plus the `"HTTP <code>"` form; both are shown to dashboard users and have no localization mechanism. The other strings are enum values, not text.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a — stale-monitor detail | `HTTP <statusCode>` | `detail` when the probe saw a status code and no error |
| n/a — stale-monitor fallback | `down` | `detail` when the probe saw neither error nor status code |

