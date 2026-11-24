
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `executable` | `String` | required | Absolute path of the command to run detached |
| `arguments` | `[String]` | required | Arguments passed unmodified |
| `environment` | `[String: String]` | required | The command's whole environment |
| `stdin` | `Data` | required | The payload written to the command's standard input |
| `sessionID` | `String` | required | Identifies the feed lock |
| `name` | `String` | required | The daemon's name, part of the lock file name |
| `directory` | `URL` | the temporary directory | Where lock files live |

The session id limit (`128` scalars) and the lock file mode (`0600`) are fixed constants, not options; they are specified by **lock-session-sanitised** and **lock-acquire**.
