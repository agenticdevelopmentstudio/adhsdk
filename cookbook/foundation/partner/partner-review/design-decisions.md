
**Decision**: The models carry no lifecycle rules.
**Rationale**: They are plain data; the store and the review service that move a review between states own the transitions, so the types stay valid for every state a database row can hold.
**Approved**: pending

**Decision**: `supersededBy` lists later SHAs on the older review.
**Rationale**: When a review starts, the commits after it on the branch that touch the same files are recorded on the review, so the reviewer sees what changed since and the record keeps a pointer to them.
**Approved**: pending

**Decision**: `PartnerReviewStart` has no default values.
**Rationale**: The payload is built whole by the review service and returned whole as the tool result; every part is always supplied, and a part with nothing to give (a skipped review) is passed empty rather than defaulted.
**Approved**: pending

