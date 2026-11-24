
- **Null / empty input**: A vault with no filter hands the session nothing; the reveal still lifts the screen with the shell not started (MUST). A nil window while editing words makes the editor and the failure alert silently not appear (MUST NOT show anything).
- **Boundary values**: Revealing a pane already revealed does nothing (MUST). Hiding a pane already hidden sets the same state again and re-applies reveal state with no authentication (MUST NOT ask).
- **Concurrent access**: Main-actor only. An authentication guard stops a second authentication from reveal or edit while one is on screen (MUST). The guard is shared, so a reveal press during an edit authentication does nothing (MUST).
- **Error states**: A failed reveal leaves the screen up with the message set; a failed silent load sets the message; a failed edit authentication shows an alert; a throwing connect propagates (MUST each). A failed reveal does not alert.
- **Offline / disconnected state**: Not applicable: the pane does not touch the network; the shell is a local process.
- **Shell exit while revealed**: The terminal stays visible and `isRunning` becomes false, so the connectable offer becomes nil (MUST); the controller adds no exit handling.
- **Words changed by another pane**: A published filter reaches a running shell from the next byte, and a pane that has not appeared waits (MUST).
- **Words under the old guard**: The silent load yields nothing, the pane waits for the eye or a connecting chat, and authenticating rewrites them without the old guard (MUST).
- **Screen capture**: While revealed the window is excluded from capture; leaving the window or hiding returns it to readable unless another revealed concealed view remains (MUST).
- **Pane removal**: A running session asks for confirmation; discarding ends the process (MUST).
- **Auto-hide**: See the open question on `auto-hide`.

