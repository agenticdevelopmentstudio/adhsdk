
**Decision**: The workspace row is found by path and not by a stored identifier.
**Rationale**: The source comment says this leaves the database as the only place that knows the row (the `dry` principle).
**Approved**: pending

**Decision**: The layout is installed in the initializer.
**Rationale**: The layout is process-wide and must be in place before any window can load; a host that also opens other kinds of project windows wants its own layout and should not use this feature.
**Approved**: pending

**Decision**: New Terminal on a closed window shows the window rather than adding a second pane.
**Rationale**: A window that opens on its starting terminal has already done what was asked.
**Approved**: pending

**Decision**: The command registry is a required parameter.
**Rationale**: As for every feature, a dropped registry is then a compile error rather than a menu that lost an item.
**Approved**: pending

**Decision**: A failure to open the workspace window is logged and not shown.
**Rationale**: The source only logs the error; no user message is defined, which is why the open question on error-surface exists.
**Approved**: pending

