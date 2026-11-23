
**Decision**: The protocol defines no transport.
**Rationale**: Apps suite Phase 4 retires the per-app Unix socket, its directory helpers and the `adterm` client; the app serves the protocol as MCP tools through the host it already registers with, so the vocabulary stays and the door is the host's.
**Approved**: pending

**Decision**: `Defaults` is the single statement of the timing numbers.
**Rationale**: Three readers need these numbers: the session's own defaults, the app's tools and the tools' descriptions; one place stops them drifting.
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
