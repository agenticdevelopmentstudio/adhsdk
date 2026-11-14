
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `owner.text` | string | none (required) | The owner's message, passed through unchanged |
| `owner.attribution` | optional `ChatMessage.Attribution` | nil | Provenance of an owner line in a merged transcript |
| `tick.jobID`, `tick.jobName` | strings | none (required) | Id used for the key, name used in the text |
| `tick.previousTick` | optional date | nil | When set, adds the previous-tick line |
| `tick.summary` | optional string | nil | When set, adds a final line, such as the queue counts the app prepares |
| `sessionIdle` / `sessionExited` fields | `sessionID`, `title` strings | none (required) | Session identity and display title |
| `Lifecycle.started` fields | `resumed` bool, `goneSessions` strings | none (required) | Whether the partner resumed, and which sessions vanished meanwhile |
| `Lifecycle.willQuit.endingSessions` | strings | none (required) | Sessions that will end when the app quits |

