
**Decision**: Every list and message answer is guarded by a generation counter (`listGeneration`, `messageGeneration`) rather than cancelling the request.
**Rationale**: The source comment says the counter is bumped "whenever the list is replaced, so a page answering an older selection is dropped." The model never cancels a request; it ignores the stale answer when it arrives. The trade-off: a cancelled request needs a cancellation path through the client and the transport, while an ignored answer costs only a wasted round trip and keeps the model independent of how the client works. A port with cheap cancellation may cancel too, but it must still guard against a late answer.
**Approved**: pending

**Decision**: A refresh keeps as many rows as were showing and does not clear the list or the open message.
**Rationale**: The source comment says "A refresh keeps as many rows as were showing, so the list does not shrink under the user." A sync therefore does not disturb reading. The trade-off: the refresh request grows with the list, and a refresh keeps the old row count instead of returning to one page.
**Approved**: pending

**Decision**: The selected mailbox is held by identity only (`MailboxID`), not as a `Mailbox`.
**Rationale**: The source comment says this is "so a reload that changes counts keeps it." Counts change whenever a sync brings new mail. Holding the whole `Mailbox` would make every count change look like a different selection and drop the list and the open message.
**Approved**: pending

**Decision**: The sync poll reads only the account list and compares `lastSyncAt` values, and swallows its own failure.
**Rationale**: The source comment says it "Reads only the local store, never Gmail", so polling is cheap. A poll failure is not shown to the user, which differs from every other action, and the next poll tries again. The trade-off: a silent poll never interrupts the reader with an error for a background check, at the cost that a persistently failing store is invisible until the user acts.
**Approved**: pending

**Decision**: Unread counts are lowered locally when a message is marked read, for every mailbox whose label the message carries (including user labels and Starred), and are left to the next sync to correct.
**Rationale**: The source comment says this keeps counts "in step with a read made here, until the next sync brings Gmail's own counts." It is an estimate, and the decrement applies to the labels of the message as loaded, before the read.
**Approved**: pending

**Decision**: `loading` covers `reload` only.
**Rationale**: Mailbox switches, paging and opening a message do not set it, so a view that shows progress for those needs its own signal. Setting it for paging or opening would flash a progress indicator for small, frequent actions, but the cost is that a view wanting one must track its own signal.
**Approved**: pending

**Decision**: Errors are only ever set, never cleared by a later success, and failures during `reload` do not stop it from choosing a selection.
**Rationale**: `errorMessage` stays until `dismissError`, so a failure is not hidden by the next success. Continuing after a failure lets a transient label error still show the list.
**Approved**: pending

**Decision**: The status, account and label reads of `reload` share one error path; the first failure abandons the rest of that step.
**Rationale**: The source wraps status, accounts and labels in one `do` block, so a failure leaves `mailboxes` unchanged while `accounts` may already be new. This is technical debt that affects behavior, recorded here so a port does not smooth it over.
**Approved**: pending

**Decision**: The sender name, the list date, the full date and the unread test stay in the model as static functions instead of a separate formatter.
**Rationale**: They are pure and hold no state, so they test without a client, and keeping them beside the model gives the view controllers one import. The cost is that the model has two concerns; a port may move them into their own unit without changing behavior.
**Approved**: pending

**Decision**: System mailbox titles are fixed English strings.
**Rationale**: The source holds a private table and does not localize it. A port that localizes them changes a visible string, so every port keeps the English titles unless the owner approves a change. Fixed titles keep the sidebar identical across ports, at the cost of the failed no-hardcoded-strings check.
**Approved**: pending

