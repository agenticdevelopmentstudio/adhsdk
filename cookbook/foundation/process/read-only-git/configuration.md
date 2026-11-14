
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `args` | `[String]` | none | Arguments after `git`, including an optional `-C <dir>`. |
| timeout | seconds, private constant | 5 | Fixed, not configurable. Time a command is given before it is stopped and `""` is returned. |
| `GIT_OPTIONAL_LOCKS` | environment variable set on the child | `0` | Fixed, not configurable. Stops optional index-lock use. |
| `PATH` | environment variable of the child | caller's path plus repaired directories | Fixed, not configurable. See `repairedPath(_:)`. |
| repaired directories | list | `/usr/bin`, `/bin`, `/usr/local/bin`, `/opt/homebrew/bin` | Fixed, not configurable. Appended when missing. |
| launcher | path | `/usr/bin/env` | Fixed, not configurable. Resolves `git` on `PATH` without a shell. |

