
**Decision**: One catalog serves enumeration, matching and activation.
**Rationale**: The source calls it the single source of truth shared by the activation tester and the bring-to-front strategy, so a terminal added once is listed, matched and activated; the conversation summary reads it too.
**Approved**: pending

**Decision**: `match` takes the catalog as a parameter that defaults to `all`.
**Rationale**: The source says callers can pass a custom list to support more terminals without patching the toolkit; the default lets the conversation summary call it with one argument, while the bring-to-front strategy passes its own catalog, which itself defaults to `all`.
**Approved**: pending

**Decision**: Matching is by whole-value equality on `TERM_PROGRAM`.
**Rationale**: The environment value is a fixed token each terminal sets; exact matching cannot confuse two terminals, and the prefix search a user types lives in the conversation summary, not here.
**Approved**: pending

**Decision**: An entry lists several `TERM_PROGRAM` values.
**Rationale**: The source notes a terminal may expose more than one, for distribution variants; one entry then covers them all.
**Approved**: pending

