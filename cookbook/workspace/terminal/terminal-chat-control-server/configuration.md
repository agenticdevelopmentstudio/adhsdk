
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `directory` | `TerminalChatDirectory` | none (required) | The chats the server answers from. |
| `appName` | `String` | none (required) | Reported in every answer so a client talking to several apps can tell them apart. |
| settle | seconds | 1.5, max 60 | Seconds output must stop for before a reply is complete (from the shared defaults). |
| timeout | seconds | 60 for run and wait, 10 for interrupt, max 600 | Longest a run or wait waits (from the shared defaults). |
| lines | `Int` | 40 | Lines a screen request returns. |

