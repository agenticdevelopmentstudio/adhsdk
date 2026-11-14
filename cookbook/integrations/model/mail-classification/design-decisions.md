
**Decision**: The precedence is trash, then spam, then filed, then archived, and it does not depend on label order.
**Rationale**: A trashed or spam message that still carries `INBOX` or a user label must not be mirrored as filed, and the test cases `["SPAM", "INBOX"]` and `["TRASH", "Label_9"]` pin it.
**Approved**: pending

**Decision**: Any label that is not a Gmail system label counts as a user label and makes a message filed.
**Rationale**: Gmail user label ids are opaque (such as `Label_123`), so the code tests for non-membership in the system set instead of matching user ids. The cost is that a new Gmail system id not yet in `systemLabelIds` is treated as a user label and classifies as filed until the constants change, and an empty string is not rejected.
**Approved**: pending

**Decision**: `UNREAD`, `IMPORTANT`, `CHAT` and `CATEGORY_*` are attribute labels that never make a message filed, and `CATEGORY_*` is matched by prefix.
**Rationale**: These labels describe a message but do not file it. The `CATEGORY_` set is open-ended, so a prefix test avoids listing every id. The test case `["CATEGORY_PROMOTIONS", "UNREAD", "IMPORTANT"]` yields archived.
**Approved**: pending

**Decision**: The classifier returns the class and does not decide what is mirrored; `MailSyncSettings` `allows(_:)` ([adhsdk.ingredient.integrations.model.mail-sync-settings](cookbook:df121975-deb8-49a9-b023-0aadcb0923d8)) makes that decision.
**Rationale**: Keeping classification separate from policy lets a user change the include flags without changing the classifier, and keeps the function pure. Because the Gmail query only narrows the fetch, the classifier stays the authority on what is mirrored.
**Approved**: pending

**Decision**: `systemLabelIds` is public while the filing subset is private.
**Rationale**: The system set is public so a caller can tell system labels from user labels; no code outside `MailClassification.swift` reads it today. The filing subset is an internal detail of the classifier that no caller needs.
**Approved**: pending

