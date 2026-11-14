
- **Start returns no terminal (MUST)**: The start call can return nothing; the controller connects the session to nothing, ends the starting state and shows the remembered-unavailable status.
- **Choice changes during a start (MUST)**: The newer choice is put off while a start is in flight (a second start is refused) and acted on the moment the first finishes, whether it succeeded or failed.
- **Start error for a superseded pane (MUST)**: The error is dropped, not shown.
- **Remembered pane closed (MUST)**: Re-making the connection finds no pane and only refreshes the state; the remembered identifier stays until the user connects elsewhere or disconnects.
- **Minimized or never-appeared pane (MUST)**: Connecting starts that pane's terminal, since a minimized pane never appears to start itself.
- **No window (MUST)**: The disconnect confirmation and the picker are not started when the view has no window.
- **Picker already running (MUST)**: A second request is ignored.
- **Concurrent access**: The controller is main-actor isolated and the notification handler asserts main-actor isolation; no other concurrency is defined.
- **Offline or disconnected state**: Not applicable: the component talks only to an in-process terminal session, not to a network; the exit of the shell is covered by the terminal-exit-refresh requirement.
- **Null and empty input**: A nil directory or listing keeps the chat private to the window; an unparseable remembered string is treated as no remembered pane.
- **Boundary values**: Not applicable: the component takes no numeric input beyond its fixed container size.

