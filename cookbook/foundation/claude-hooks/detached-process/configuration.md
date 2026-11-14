
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `executable` | `String` | required | Absolute path of the command to run detached |
| `arguments` | `[String]` | required | Arguments passed unmodified |
| `environment` | `[String: String]` | required | The command's whole environment |
| `stdin` | `Data` | required | The payload written to the command's standard input |
| `sessionID` | `String` | required | Identifies the feed lock |
| `name` | `String` | required | The daemon's name, part of the lock file name |
| `directory` | `URL` | the temporary directory | Where lock files live |
| session id limit | `Int` | `128` | Scalars of the session id kept in the lock file name |
| lock file mode | `mode_t` | `0600` | Mode of a new lock file |

