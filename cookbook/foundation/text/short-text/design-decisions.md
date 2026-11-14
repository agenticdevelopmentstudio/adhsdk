
**Decision**: Cut to `limit - 3` characters plus one ellipsis character, so the result is `limit - 2` characters.
**Rationale**: The source takes `prefix(limit - 3)` and appends the single `…`; its doc comment states that a cut result is `limit - 2` characters long, and the test records this ("two under the limit"), so a port must match it.
**Approved**: pending

**Decision**: Measure in `Character`s, not bytes or UTF-16 units.
**Rationale**: A cut must never split an emoji or combining sequence.
**Approved**: pending

**Decision**: One shared helper with a default of 60.
**Rationale**: A quota card gives an error line about sixty characters before it wraps, and the number had been written three times (refresher, evaluator, probe), so tuning one would have left the others a different width.
**Approved**: pending

**Decision**: The method does not guard a limit under 3.
**Rationale**: The doc comment documents the precondition ("`limit` must be at least 3: a smaller value makes `prefix` trap on a negative count"); the method does not check it, so the contract belongs to the caller. This is recorded as the contract, not a gap.
**Approved**: pending

**Decision**: The cut is not at a word boundary and does not trim trailing whitespace.
**Rationale**: The source takes `prefix(limit - 3)` as is; the output length is therefore predictable for a width budget.
**Approved**: pending

