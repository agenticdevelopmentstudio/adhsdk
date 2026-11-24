
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `resolve` | `@MainActor @Sendable () -> TerminalChatSession?` | none (required) | Answers the Terminal Chat to talk to, or nil when there is none; read on the main actor. |
| settle and timeout | `Duration` | 1.5 s and 60 s (10 s for interrupt) | Taken from the session's defaults; this source passes none of its own. |

