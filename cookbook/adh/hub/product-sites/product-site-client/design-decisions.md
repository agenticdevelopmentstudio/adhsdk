
**Decision**: The row carries `consoleLive` as its own field rather than the caller combining `adminEnabled` with `adminClientId`.
**Rationale**: The rail and the pane both move people rows on the same rule, so the backend answers it once; the field is optional on the wire so an older backend reads as not live and the hub keeps every pane.
**Approved**: pending

**Decision**: A refusal is a `ProductSiteError` that keeps the backend's code and sentence.
**Rationale**: The pane shows the sentence as the backend wrote it, and a caller that needs to tell a taken handle from a missing base domain reads the code.
**Approved**: pending

**Decision**: A 404 is not retried.
**Rationale**: An ecosystem that is not a product answers it every time, and the All Data pane asks about workspaces, so a retry only doubles the failed requests.
**Approved**: pending

**Decision**: The wire types are written by hand in this package rather than taken from the generated API types.
**Rationale**: The module's header says every client in this package does so, following the sets client.
**Approved**: pending

