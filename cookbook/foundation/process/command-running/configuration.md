
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `backstop` (initializer) | `TimeInterval` seconds | 600 | The longest a command may run before it is terminated and reported with status -1. The source calls it "far past any legitimate helper run". |
| `argv` (each call) | array of strings | none, required | Executable first, then its arguments. |
| `environment` (`capture` only) | optional dictionary of strings | nil (inherit) | When non-nil, replaces the child's whole environment and supplies the `PATH` used for the lookup. |
| search `PATH` | string | `/usr/bin:/bin:/usr/sbin:/sbin` when none is available | Colon-separated directories searched for a bare name. |
| built-on dependencies | `CommandRunner.runToCompletion` and `BlockingWork.run` | fixed (static calls, not injectable) | The process runner and the off-pool hop `ProcessCommandRunner` is built on; the seam for substitution is the `CommandRunning` protocol, not these. |

