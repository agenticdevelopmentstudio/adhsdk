
**Decision**: Drive chats through the chat session, never the terminal.
**Rationale**: The source says it shows in the chat's transcript as it happens, and a chat connected to a private terminal reads back only what that terminal shows, with privacy words in place of the real ones.
**Approved**: pending

**Decision**: Hold sessions weakly and also have panes add and remove themselves.
**Rationale**: The source says a pane that goes without saying so drops out rather than lingering; the weak reference covers the pane that forgets to remove itself.
**Approved**: pending

**Decision**: Use a Unix-domain socket instead of a localhost port.
**Rationale**: The source says a socket file is reachable only by whoever can reach its path, the server makes it owner-only and refuses another user's peer, whereas a localhost HTTP port is open to every process on the machine.
**Approved**: pending

**Decision**: Clamp settle and timeout, but not line count.
**Rationale**: The source clamps the two durations to a floor of 0.1 seconds and the shared maxima and leaves `lines` as requested; the server leaves `lines` as requested because the session floors it at 1 and returns at most the lines it has.
**Approved**: pending

**Decision**: List an unconnected chat with its text as given.
**Rationale**: The code's `presentable` falls back to the plain text when the session has no terminal, while its comment says nothing is listed for a chat not yet unlocked; the recipe records the behavior of the code and flags the mismatch.
**Approved**: pending

**Decision**: Answer every failure with a protocol error message rather than closing the connection, naming the app on every answer to a decodable request.
**Rationale**: The source sets the app name on every response to a decoded request and builds failures from the shared `failure` form so a client talking to several apps can tell which answered; the decode-failure, shutting-down and encode-fallback answers carry no app name.
**Approved**: pending

