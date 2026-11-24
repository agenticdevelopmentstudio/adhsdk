
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `conn` | `LibsqlConnection` (`url`, optional `authToken`) | none — required | The database to open, handed to the worker unchanged as `workerData.db`. |
| `opts.onExit` | function taking a reason string | none — required | Called after startup when the database thread errors or exits. The host SHOULD treat it as fatal. |
| Worker entry | package export `@adh-sdk/status-server/storage-worker` | fixed | Not configurable. |

The module reads no environment variables or settings.

