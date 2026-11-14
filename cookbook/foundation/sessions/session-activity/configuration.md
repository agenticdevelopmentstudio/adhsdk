
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `isActive` | `Bool` | none | Whether the session's process is alive; `false` forces `idle`. The macOS caller passes `status == .active`. |
| `lastEventType` | `String` | none | The last hook event recorded for the main agent's turn. |
| `subagentWorking` | `Bool` | none | The daemon's verdict that a subagent was busy just now. |

