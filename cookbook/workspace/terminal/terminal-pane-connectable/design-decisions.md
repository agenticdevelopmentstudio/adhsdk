
**Decision**: The contract exposes only the terminal session.
**Rationale**: Whether the terminal is ordinary or private is the terminal pane's business, and what it does to text on the way in and out happens inside the session.
**Approved**: pending

**Decision**: A connection is a reason to start the terminal.
**Rationale**: The source comment says a connection starts a terminal as appearing does, so a pane that never appeared can still be started by a connection.
**Approved**: pending

**Decision**: The default start returns the current terminal.
**Rationale**: A terminal that is running as soon as it exists has nothing to start.
**Approved**: pending

**Decision**: The terminal pane content offers its selected session only while running.
**Rationale**: A stopped session cannot be typed into.
**Approved**: pending

