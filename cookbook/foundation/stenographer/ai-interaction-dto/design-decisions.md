
**Decision**: `isFailure` is the single place the outcome vocabulary is folded into success or failure.
**Rationale**: The source comment states it is shared by list and detail rendering, so a new failure outcome needs no change in either renderer.
**Approved**: pending

**Decision**: Any `outcome` other than `ok` is a failure, instead of listing the failure outcomes.
**Rationale**: A new or unknown outcome shows as a failure with its reason rather than as a success with an empty response; the source does not give a further reason.
**Approved**: pending

**Decision**: List reads truncate the three long fields in SQL and flag it with `truncated`.
**Rationale**: The source comment says the list stays light, while a by-id read returns the full text.
**Approved**: pending

**Decision**: The vocabularies for `feature`, `providerKind` and `outcome` are strings, not enums.
**Rationale**: The source documents the values in comments and does not validate them; this keeps the wire tolerant of values this build does not know. The source states no reason beyond the comments.
**Approved**: pending

