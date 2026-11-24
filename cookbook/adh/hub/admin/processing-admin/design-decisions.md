
**Decision**: Dead jobs go in a section of `AiNodesPane`, not a new topic.
**Rationale**: Per the phase 9 design, there was no dead job list to add Retry to and no "Jobs" topic to
relabel, and the topics stay unchanged.
**Approved**: pending

**Decision**: The Pool scope is a checkbox on the existing worker token mint.
**Rationale**: Per the design (call C9), a pool token is a worker token with one more scope, so it reuses
the mint, the reveal and the revoke.
**Approved**: pending

**Decision**: A dead row shows no payload.
**Rationale**: A step's payload can hold a customer's prompt, and the operator needs only the type,
error and attempts to decide to retry.
**Approved**: pending

