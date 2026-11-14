
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| settle | Double | 1.5 (cap 60) | Seconds output has to stop for before a reply is complete. |
| timeout | Double | 60, or 10 for interrupt (cap 600) | The most seconds a run, wait or interrupt waits. |
| lines | Int | 40 | Lines `screen` returns. |
| wait | TimeInterval | the timeout plus 15 | Transport wait in `send`, for the client. |
| socketDirectory | URL | `~/Library/Application Support/TerminalChat/sockets` | Where each host's socket lives. |

