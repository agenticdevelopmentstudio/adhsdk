
**Decision**: The editor edits a `GitRebasePlan` value and hands it back; it never runs git.
**Rationale**: The plan's validation and the todo it becomes are the client's, tested without a window; the editor stays a pure editor and the window's one funnel runs the result.
**Approved**: pending

**Decision**: Every reword's message is filled before the editor opens, from one `log` call for the whole range.
**Rationale**: A reword starts from the commit's real message, body included, and switching an action costs no git call on the main thread.
**Approved**: pending

**Decision**: A reword's message is edited in the subject cell itself, not in a separate pane.
**Rationale**: The row is where the user decided to reword; a field in place keeps the table the whole editor, and the message is shown only where it will be used.
**Approved**: pending

**Decision**: Start's reason for being disabled is its tooltip, not text under the table.
**Rationale**: The window shows no instruction text; the tooltip is there when the user asks why.
**Approved**: pending
