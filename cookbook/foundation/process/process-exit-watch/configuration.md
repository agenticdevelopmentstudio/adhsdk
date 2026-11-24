
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `terminationGrace` | `TimeInterval` static constant | 2 seconds (not configurable; fixed by `grace-value`) | How long a terminated process is given to die before SIGKILL, and how long SIGKILL is given. |
| `init(_:)` argument | `Process` | none | The process to watch. It MUST NOT have been launched. |
| `timeout` | `TimeInterval` | none | The argument of `waitForExit(timeout:)`, in seconds. |
| `stop(_:)` argument | `Process` | none | The process to end; the same one the watch was built for. |

