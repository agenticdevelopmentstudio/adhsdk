
- **Row missing (MUST)**: The row is inserted on first use, keyed by path.
- **Row exists from an earlier launch (MUST)**: It is reused, so the window's saved tabs and layout stay attached to it.
- **Database error on show (MUST)**: The error is logged; no window opens and nothing is shown to the user.
- **Database error on the open-window query (MUST)**: Treated as not open.
- **No front window controller while the window is open (MUST)**: New Terminal shows the window instead.
- **Pane refused (MUST)**: The refusal is announced; it happens when the front window has no active pane or its layout allows no further terminal beside it.
- **Front window is not the workspace window (MUST NOT be relied on)**: New Terminal acts on the front project window without checking that it is the workspace window.
- **Coordinator released (MUST)**: Commands do nothing.
- **Second coordinator in the same process (MUST NOT be relied on)**: The layout is process-wide and the initializer replaces it, so a host that opens other kinds of project windows must not use this feature.
- **Concurrent access**: The type is main-actor isolated, so initialization, commands and queries run on the main actor.
- **Offline or disconnected state**: Not applicable: the component touches only the local database and windows, with no network.
- **Null and empty input**: A nil plugin manager, chat directory or privacy vault omits or privatizes the matching feature; a missing directory defaults to home.
- **Boundary values**: Not applicable: no numeric input.

