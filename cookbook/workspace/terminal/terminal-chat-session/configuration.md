
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `quietPeriod` | `Duration` | 300 ms | How long output must stop before it counts as one reply. |
| `maximumLatency` | `Duration` | 1 s | Longest output waits to be reported while it keeps coming. |
| `returnDelay` | `Duration` | 250 ms | Pause between typing the text and writing Return. |
| settle | `Duration` | 1.5 s | Quiet a wait needs, from the shared defaults. |
| timeout | `Duration` | 60 s (10 s for interrupt) | Longest a wait waits, from the shared defaults. |
| `lines` | `Int` | 40 | Lines `screen` returns. |
| `unclaimedLimit` | characters | 64 KiB | Cap on kept unclaimed output. |
| `terminalDidExit` | closure | nil | Called after the shell exits and the chat has let go. |

