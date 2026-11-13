
**Decision**: The precedence is trash, then spam, then filed, then archived, and it does not depend on label order.
**Rationale**: The source's doc comment declares this order. A trashed or spam message that still carries `INBOX` or a user label must not be mirrored as filed, and the test cases `["SPAM", "INBOX"]` and `["TRASH", "Label_9"]` pin it.
**Approved**: pending

**Decision**: Any label that is not a Gmail system label counts as a user label and makes a message filed.
**Rationale**: Gmail user label ids are opaque (such as `Label_123`), so the code tests for non-membership in the system set instead of matching user ids. The cost is that a new Gmail system id not yet in `systemLabelIds` is treated as a user label, and an empty string is not rejected.
**Approved**: pending

**Decision**: `UNREAD`, `IMPORTANT`, `CHAT` and `CATEGORY_*` are attribute labels that never make a message filed, and `CATEGORY_*` is matched by prefix.
**Rationale**: The source's doc comment names them as attribute labels. The `CATEGORY_` set is open-ended, so a prefix test avoids listing every id. The test case `["CATEGORY_PROMOTIONS", "UNREAD", "IMPORTANT"]` yields archived.
**Approved**: pending

**Decision**: The classifier returns the class and does not decide what is mirrored; `MailSyncSettings.allows(_:)` makes that decision.
**Rationale**: Keeping classification separate from policy lets a user change the include flags without changing the classifier, and keeps the function pure. The query builder's comment says the Gmail query only narrows the fetch and the classifier stays the authority.
**Approved**: pending

**Decision**: `systemLabelIds` is public while the filing subset is private.
**Rationale**: The source exposes the system set so other code can tell system from user labels, and keeps the filing subset as an internal detail of the classifier.
**Approved**: pending

