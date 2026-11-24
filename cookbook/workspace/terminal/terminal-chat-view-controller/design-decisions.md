
**Decision**: The connection is remembered by the chosen pane's node identifier and re-made when the chat appears and when a connectable-terminal-changed notification arrives.
**Rationale**: The remembered pane can only be found once the chat is in the tab tree, and a private terminal may start after the chat appears; the source comments say both cases connect "the moment it is there".
**Approved**: pending

**Decision**: Connecting to a pane with no running terminal starts that terminal.
**Rationale**: A minimized pane never appears to start itself, so the connection is the reason to start it.
**Approved**: pending

**Decision**: A choice made while a start is in flight is put off, then acted on when the start ends.
**Rationale**: Only one start runs at a time; the source comment says the choice "was put off only because a start was in flight".
**Approved**: pending

**Decision**: The chat enables its interrupt control.
**Rationale**: Control-C is how a terminal is stopped, so the chat standing in for its command line must be able to send it.
**Approved**: pending

**Decision**: The unlinked glyph is drawn by slashing the link symbol.
**Rationale**: The system symbol set has no broken link, so the slash is drawn the way the system's own slash variants are, with a cleared gap so the stroke reads apart from the link.
**Approved**: pending

**Decision**: Disconnecting keeps the chat history.
**Rationale**: The confirmation text states the chat only stops typing into and reading from the terminal.
**Approved**: pending

