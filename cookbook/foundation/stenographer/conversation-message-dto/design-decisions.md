
**Decision**: A message is a separate shape from the feed entry rather than reusing `ConversationEntryDTO`.
**Rationale**: Adding project, branch and session-name attribution to every message would distort a per-session shape: a feed entry carries the attribution a merged, many-session timeline needs on every row, while a message belongs to one session and every row would repeat the same values.
**Approved**: pending

**Decision**: Paging is by message id, not by time.
**Rationale**: A time cursor cannot separate two transcript entries that share a timestamp, while a message id can, so a follower never skips or repeats a message.
**Approved**: pending

**Decision**: The user / model / notice split is a fold of the extractor's kind in `type(forKind:)`, with every unknown kind falling to `model`.
**Rationale**: Keeping the fold in one function means a new extractor kind needs no change elsewhere; the cost is that an unknown kind reads as the agent speaking.
**Approved**: pending

**Decision**: `agentId` is optional.
**Rationale**: The field was added after the first release, and an optional value lets a reader built before it still decode.
**Approved**: pending


**Decision**: The query shape validates nothing; the daemon clamps `limit` and checks cursors.
**Rationale**: Only the daemon can see the transcript, so it is the one place that can tell an unknown cursor from a valid one; validating `limit` in the shape too would put the same rule in two places that could disagree.
**Approved**: pending
