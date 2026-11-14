
**Decision**: The hub mirror is a separate store and framework from the direct Gmail worker.
**Rationale**: The direct path stays until the owner decides its fate, and keeping the two apart means removing either touches nothing in the other. It also lets iOS link hub mail without the macOS-only Integrations framework.
**Approved**: pending

**Decision**: Typed tables through a projection rather than the sync store's generic JSON mirror.
**Rationale**: Mail is read by connection, label, thread and date, and typed columns with indexes answer those directly instead of through JSON expressions on every row.
**Approved**: pending

**Decision**: Keyset paging on `(internal_date, id)`.
**Rationale**: A mailbox is large and grows at the top while the user scrolls; a keyset cursor neither repeats nor skips when new mail arrives, where an offset would.
**Approved**: pending

**Decision**: A label change is written into the mirror right after the hub accepts it, keeping the row's sync version.
**Rationale**: The hub's `modify_labels` action changes Gmail, not the hub's table; the worker's next run brings the new labels back. Writing them locally meanwhile keeps the UI honest, and leaving the sync version alone means the next pulled copy still wins, so the mirror never drifts from the hub for long.
**Approved**: pending
