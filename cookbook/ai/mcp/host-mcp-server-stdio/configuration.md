
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `stdioDrainDeadline` | `Duration` (static) | 360 seconds | How long a server whose input has closed waits for the replies it still owes |
| `deadline` | `Duration` | `stdioDrainDeadline` | The same wait, per call of `serveUntilDrained(over:deadline:)` |
| `transport` | `Transport` | none | The transport `serveUntilDrained(over:deadline:)` serves over; `serveStdio()` supplies the standard stream transport |

