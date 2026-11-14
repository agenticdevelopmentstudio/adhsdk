
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `probeIntervalMs` | `number \| null \| undefined` | none (treated as 0) | Probe cadence scaling the freshness and unconfirmed windows to five times the interval, never below their floors. `liveFreshness` takes a `number` and the other functions accept `null` or `undefined`; any missing value counts as 0. |
| `SNAPSHOT_STALE_FLOOR_MS` | `number` | `300000` | Minimum freshness window. Compile-time constant. |
| `UNCONFIRMED_AFTER_MS` | `number` | `600000` | Minimum unconfirmed window. Compile-time constant. |
| `STALE_MONITOR_MS` | `number` | `604800000` | Default stale-monitor threshold. Compile-time constant. |
| `thresholdMs` | `number` | `STALE_MONITOR_MS` | Optional third argument to `selectStaleMonitors`; `staleMonitorsView` never passes it. |
| `nowMs` | `number` | none, required | Caller's clock for the deploy and stale-monitor verdicts. |

