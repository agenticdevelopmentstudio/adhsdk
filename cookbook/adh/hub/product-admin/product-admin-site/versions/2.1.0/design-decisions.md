
**Decision**: The product's admins are managed on the Admin site page, and the hub's people pages leave once a site exists.
**Rationale**: The phase 6 design puts the product's own admins on their own host; showing the same pages on the hub would make two places to do one thing.
**Approved**: pending

**Decision**: An admin is added as a sign-up list entry carrying the admin role, not through a new route.
**Rationale**: The sign-up list already grants a role on first sign-in, so the admin seat needs no route of its own.
**Approved**: pending

**Decision**: The topic list has its own `./topics` export.
**Rationale**: The barrel is a client module; a server module must be able to read the list without it.
**Approved**: pending

