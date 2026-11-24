
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `initial` | array of `ChatMessage` | none (required) | Transcript the session starts with and replays to each new stream |
| `send` | `@Sendable` closure taking a string | none (required) | Called by `send(_:)` with the owner's text; this type does not echo it |
| `interrupt` | `@Sendable` closure with no arguments | none (required) | Called by `interrupt()` |

