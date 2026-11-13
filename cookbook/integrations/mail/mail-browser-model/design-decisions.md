
**Decision**: Every list and message answer is guarded by a generation counter (`listGeneration`, `messageGeneration`) rather than cancelling the request.
**Rationale**: The source comment says the counter is bumped "whenever the list is replaced, so a page answering an older selection is dropped." The model never cancels a request; it ignores the stale answer when it arrives.
**Approved**: pending

**Decision**: A refresh keeps as many rows as were showing and does not clear the list or the open message.
**Rationale**: The source comment says "A refresh keeps as many rows as were showing, so the list does not shrink under the user." A sync therefore does not disturb reading.
**Approved**: pending

**Decision**: The selected mailbox is held by identity only (`MailboxID`), not as a `Mailbox`.
**Rationale**: The source comment says this is "so a reload that changes counts keeps it." Counts change whenever a sync brings new mail.
**Approved**: pending

**Decision**: The sync poll reads only the account list and compares `lastSyncAt` values, and swallows its own failure.
**Rationale**: The source comment says it "Reads only the local store, never Gmail", so polling is cheap. A poll failure is not shown to the user, which differs from every other action, and the next poll tries again.
**Approved**: pending

**Decision**: Unread counts are lowered locally when a message is marked read, for every mailbox whose label the message carries (including user labels and Starred), and are left to the next sync to correct.
**Rationale**: The source comment says this keeps counts "in step with a read made here, until the next sync brings Gmail's own counts." It is an estimate, and the decrement applies to the labels of the message as loaded, before the read.
**Approved**: pending

**Decision**: `loading` covers `reload` only.
**Rationale**: Mailbox switches, paging and opening a message do not set it, so a view that shows progress for those needs its own signal. The source gives no reason; this records the behavior.
**Approved**: pending

**Decision**: Errors are only ever set, never cleared by a later success, and failures during `reload` do not stop it from choosing a selection.
**Rationale**: `errorMessage` stays until `dismissError`, so a failure is not hidden by the next success. Continuing after a failure lets a transient label error still show the list.
**Approved**: pending

**Decision**: The status, account and label reads of `reload` share one error path; the first failure abandons the rest of that step.
**Rationale**: The source wraps status, accounts and labels in one `do` block, so a failure leaves `mailboxes` unchanged while `accounts` may already be new. This is technical debt that affects behavior, recorded here so a port does not smooth it over.
**Approved**: pending

**Decision**: System mailbox titles are fixed English strings.
**Rationale**: The source holds a private table and does not localize it. A port that localizes them changes a visible string.
**Approved**: pending

