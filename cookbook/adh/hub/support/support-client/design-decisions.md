
**Decision**: One module with four clients, one for each caller, instead of one client with many optional arguments.
**Rationale**: Each caller reaches different routes with different rights; separate clients make a pane's reach visible in its imports.
**Approved**: pending

**Decision**: The viewer client has no write function.
**Rationale**: The support access design gives a grant read-only reach with no write route behind it; leaving the function out keeps a pane from offering one.
**Approved**: pending

**Decision**: The client never redirects for step-up; it only recognises the refusal.
**Rationale**: The redirect belongs to the sign-in provider, which owns navigation; the data layer stays free of it.
**Approved**: pending

**Decision**: Wire types are written by hand in this package, as the other clients here are.
**Rationale**: Every client in this package follows the sets client, keeping the generated API types out of the panes.
**Approved**: pending

