
**Decision**: A message is a separate shape from the feed entry rather than reusing `ConversationEntryDTO`.
**Rationale**: The source states a feed entry carries the attribution a merged, many-session timeline needs on every row, while a message belongs to one session and carries only what the message says.
**Approved**: pending

**Decision**: Paging is by message id, not by time.
**Rationale**: The source states this is exact even where two transcript entries share a timestamp.
**Approved**: pending

**Decision**: The user / model / notice split is a fold of the extractor's kind in `type(forKind:)`, with every unknown kind falling to `model`.
**Rationale**: The source names it the one place the kinds fold, so a new extractor kind needs no change elsewhere; the cost is that an unknown kind reads as the agent speaking.
**Approved**: pending

**Decision**: `agentId` is optional.
**Rationale**: The source states this lets a reader built before the field existed still decode.
**Approved**: pending

