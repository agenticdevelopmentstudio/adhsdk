
**Decision**: Each host keeps its own ledger under its own key.
**Rationale**: The source comment explains that two hosts share one daemon registry; a per-host record is what lets each delete only what it pushed.
**Approved**: pending

**Decision**: A push names removed ids explicitly instead of asking the daemon to delete everything it was not sent.
**Rationale**: When `removedConfigIds` is non-nil the daemon treats the sync as partial and deletes exactly those ids; a nil value makes it delete every stored configuration not listed, which would erase another host's.
**Approved**: pending

**Decision**: `removed(configured:)` takes every configuration the host holds, resolvable or not.
**Rationale**: A configuration that could not be resolved this time is absent from `configs` but still configured; counting it as held keeps it from being deleted from the daemon.
**Approved**: pending

**Decision**: The ledger is updated only after a push lands.
**Rationale**: A failed push must leave the ledger as it was so the removal is named again on the next push.
**Approved**: pending

**Decision**: Ids are stored sorted.
**Rationale**: A stable stored order makes the entry deterministic; the source does not state a further reason.
**Approved**: pending

