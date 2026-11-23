
**Decision**: Each host listens on a socket named for its pid in one shared directory.
**Rationale**: The directory is not named after any one app, so a client finds every running host the same way; the pid name keeps two hosts from colliding.
**Approved**: pending

**Decision**: The directory is owner-only, mode 0700.
**Rationale**: The sockets in it are then reachable by this user alone, which matters because a socket can type into a terminal.
**Approved**: pending

**Decision**: One JSON request and one JSON reply per connection.
**Rationale**: A plain request and reply keep the client a few lines long and let any language drive a chat.
**Approved**: pending

**Decision**: `Defaults` is the single statement of the timing numbers.
**Rationale**: Four readers need these numbers: the session's own defaults, the server, the transport's wait and the tool's usage text; one place stops them drifting.
**Approved**: pending

**Decision**: `send` waits the request's timeout plus 15 seconds, and a caller may pass a shorter `wait`.
**Rationale**: The margin keeps the transport from cutting off a long `run` before the app reports it, and a short wait keeps one stalled app from holding up a `list` across hosts.
**Approved**: pending

**Decision**: A command still printing at the timeout is reported as still running, with `wait` to collect more.
**Rationale**: The `timeout` and `wait` actions separate "the command failed" from "the command is not done", so a long build does not look like an error.
**Approved**: pending

**Decision**: `interrupt` gets a shorter default timeout than `run`.
**Rationale**: Control-C either works quickly or not at all, so waiting the full `run` timeout for it only delays a failure report.
**Approved**: pending

**Decision**: Everything goes through the chat, never directly through the terminal.
**Rationale**: Going through the chat means the action shows in the chat's transcript as it happens, and a private terminal reads back only what it shows, its privacy words in place of the real ones.
**Approved**: pending

