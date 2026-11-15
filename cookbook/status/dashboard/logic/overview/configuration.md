| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `fromMs` / `toMs` | a number | none (required) | Window bounds; the caller passes the board's own reported window start and end. |
| `state` / `count` | a sign state / a number | none (required) | Inputs to the headline operation. |
| `row` | an activity row | none (required) | The feed row the still-unresolved operation judges. |
| `problems` | a list of problems (target and onset time) | none (required) | The board's current problems, looked up by the still-unresolved operation. |
| 48-hour day threshold | constant | 48 | Minimum hours before the caption switches to days, compiled in. |

The module reads no environment variables or settings keys and takes no injected dependencies. It imports only shapes/types from elsewhere.
