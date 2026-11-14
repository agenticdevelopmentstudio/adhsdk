
**Decision**: The web package keeps a hand mirror of the server's types instead of importing them.
**Rationale**: The source header: the package has the server only as a development dependency, so it cannot import the types at run time. A drift test stops the copies diverging.
**Approved**: pending

**Decision**: A section keeps its last good `data` beside the latest `error`.
**Rationale**: Doc comment: the last good answer survives a later failure, so stale data stays on screen instead of the page going blank when one source fails.
**Approved**: pending

**Decision**: The server derives the views and the pages only lay them out.
**Rationale**: Source comment: every join, sort, threshold and rating lives in the server's views module, so every client shows the same answer and a port copies shapes, not logic.
**Approved**: pending

**Decision**: Unknown numbers are `null`, not zero.
**Rationale**: Doc comments on the Vercel roster: null when analytics is off or the count could not be read, which is not a zero. A zero would read as "measured, and none".
**Approved**: pending

**Decision**: Parity is checked by mutual assignability, with the lists compared at run time.
**Rationale**: Test comment: a renamed field, a nullability change or a union member stops the check being true. It catches drift that a transpile-only test run would not.
**Approved**: pending

