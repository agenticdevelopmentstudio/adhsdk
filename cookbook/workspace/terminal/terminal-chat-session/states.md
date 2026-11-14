
| State | Appearance change |
|-------|------------------|
| Disconnected (default) | No terminal; sends fail with a turn failure and calls return the not-connected text. |
| Connected, idle | Subscribed to the terminal's output activity and state; no wait and no timers. |
| Connected, collecting | Quiet and latency timers running after output arrived. |
| Waiting (armed) | A caller waits; its settle and timeout timers run. |
| Waiting (unarmed) | A run has typed its text but not yet its Return; nothing can settle it. |
| Exited | The shell has ended; the session reports it, ends the wait, disconnects and calls `terminalDidExit`. |
| Closed | The event stream is finished and released. |
| Pressed | Not applicable: the session has no interactive element. |
| Disabled | Not applicable: the composer is never locked, since the state is never responding. |
| Focused | Not applicable: no focus handling. |
| Loading | Not applicable: no loading indication; a long command is reported as still running at its timeout. |

