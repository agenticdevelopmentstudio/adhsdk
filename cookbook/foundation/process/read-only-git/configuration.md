
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `args` | `[String]` | none | Arguments after `git`, including an optional `-C <dir>`. |
| timeout | seconds, private constant | 5 | Time a command is given before it is stopped and `""` is returned. |
| `GIT_OPTIONAL_LOCKS` | environment variable set on the child | `0` | Stops optional index-lock use. |
| `PATH` | environment variable of the child | caller's path plus repaired directories | See `repairedPath(_:)`. |
| repaired directories | list | `/usr/bin`, `/bin`, `/usr/local/bin`, `/opt/homebrew/bin` | Appended when missing. |
| launcher | path | `/usr/bin/env` | Resolves `git` on `PATH` without a shell. |

