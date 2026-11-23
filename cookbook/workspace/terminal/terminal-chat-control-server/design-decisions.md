
**Decision**: Drive chats through the chat session, never the terminal.
**Rationale**: The source says it shows in the chat's transcript as it happens, and a chat connected to a private terminal reads back only what that terminal shows, with privacy words in place of the real ones.
**Approved**: pending

**Decision**: Hold sessions weakly and also have panes add and remove themselves.
**Rationale**: The source says a pane that goes without saying so drops out rather than lingering; the weak reference covers the pane that forgets to remove itself.
**Approved**: pending

**Decision**: Serve the chats as MCP tools rather than over a socket of the app's own.
**Rationale**: Apps suite Phase 4 retires the per-app Unix socket and the `adterm` client: the tools reach Claude Code through the MCP host the app already registers with, which carries the bearer-token check, so the app has one door rather than two.
**Approved**: pending

**Decision**: Put the directory behind `TerminalChatListing` and the session behind `TerminalChatDriving`.
**Rationale**: The tool source can then be exercised against fakes, without a terminal or a pane.
**Approved**: pending

**Decision**: Clamp settle and timeout, but not line count, and give `interrupt` the default timings only.
**Rationale**: The source clamps the two durations to a floor of 0.1 seconds and the shared maxima; the session floors `lines` itself; Control-C either works quickly or not at all.
**Approved**: pending

**Decision**: List an unconnected chat with its text as given.
**Rationale**: The code's `presentable` falls back to the plain text when the session has no terminal, while its comment says nothing is listed for a chat not yet unlocked; the recipe records the behavior of the code and flags the mismatch.
**Approved**: pending
