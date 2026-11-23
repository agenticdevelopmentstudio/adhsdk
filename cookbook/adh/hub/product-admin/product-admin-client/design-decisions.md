
**Decision**: Every call names the product by its ecosystem uuid in the `ecosystem` query parameter, never an rdid.
**Rationale**: The roster file's header says the backend's `:eco` matcher and its realm check compare the uuid exactly.
**Approved**: pending

**Decision**: The client does not enforce `DEFAULT_QUOTA_BYTES`; it exports the constant and leaves the check to the panes and the backend.
**Rationale**: The backend is authoritative and answers 403 above it; the constant only lets a pane say so before sending.
**Approved**: pending

**Decision**: Every roster write invalidates the totals as well as the roster.
**Rationale**: The hook's own comment says they count the same people, so a pause, quota change or delete would otherwise leave the totals stale.
**Approved**: pending

**Decision**: The wire types are written by hand in this package rather than taken from the generated API types.
**Rationale**: The index file's header says every client in this package does so, following the sets client.
**Approved**: pending

