
**Decision**: The menu exposes two distinct verbs, Move and File, rather than a single combined action.
**Rationale**: Move rewrites the filing the user walked in through — one place becomes another — while File adds a second filing without touching the first, which is the only way to expose the DAG's ability for a category to live in two branches at once; the label reads "Also file … in" rather than a word like "Duplicate" because it names the graph operation (adding a filing), and "Also" signals that the original filing is kept.
**Approved**: pending

**Decision**: The component is intentionally stateless (a "dumb" component): it makes no decisions about what is editable, when dialogs open, or what data is valid.
**Rationale**: All of that logic lives in the host, which tracks the current selection and can update the target independently of the menu's own lifecycle; if the menu instead closed over the target at registration time, a rename would leave it acting on stale data after the rename completed.
**Approved**: pending

**Decision**: The "Add" action is always enabled, regardless of `canEditTarget`.
**Rationale**: Add creates a new category at the list's own level (a new root in the root list), a question the current selection cannot answer, so there is no selection state that should ever disable it.
**Approved**: pending

**Decision**: Action labels include the target's name when one is available (e.g. `Rename "Q3"…`) rather than a bare verb.
**Rationale**: The menu can be opened from a header that is not the current selection; without the name, a bare "Rename…" would leave the user guessing whether the action applies to the header, the selected row, or something else.
**Approved**: pending

