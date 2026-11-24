
**Decision**: One catalog serves enumeration, matching and activation.
**Rationale**: Adding a terminal in one place updates the listing, the matching and the activation together, so the activation tester, the bring-to-front strategy and the conversation summary cannot disagree about which terminals exist.
**Approved**: pending

**Decision**: `match` takes the catalog as a parameter that defaults to `all`.
**Rationale**: A caller can pass a custom list to support more terminals without patching the toolkit; the default lets the conversation summary call it with one argument, while the bring-to-front strategy passes its own catalog, which itself defaults to `all`.
**Approved**: pending

**Decision**: Matching is by whole-value equality on `TERM_PROGRAM`.
**Rationale**: The environment value is a fixed token each terminal sets; exact matching cannot confuse two terminals, and the prefix search a user types lives in the conversation summary, not here.
**Approved**: pending

**Decision**: An entry lists several `TERM_PROGRAM` values.
**Rationale**: A terminal may expose more than one value, for distribution variants that share a bundle id; one entry then covers them all. A variant with a different bundle id needs its own entry and its own distinct value.
**Approved**: pending

