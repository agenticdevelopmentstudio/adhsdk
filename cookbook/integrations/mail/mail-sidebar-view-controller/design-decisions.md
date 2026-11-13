
**Decision**: The controller reads and calls the model only; it holds no mail state and no networking.
**Rationale**: The model's actions are the tested unit, so the sidebar only displays its published `accounts`, `mailboxes` and `selectedMailbox` and calls `select(mailbox:)`.
**Approved**: pending

**Decision**: Outline rows are instances of a private class, not values.
**Rationale**: The source comment states the outline tracks items by identity, so each rebuild creates new node objects and reloads the outline.
**Approved**: pending

**Decision**: A flag, `applyingSelection`, silences the selection callback while the model's selection is applied.
**Rationale**: Without it, applying the model's selection would call `select(mailbox:)` back and loop between outline and model; the source comment states the change is not sent back.
**Approved**: pending

**Decision**: Selection is matched on account id and label id, not on mailbox identity.
**Rationale**: Two accounts can each have a mailbox with the same label id, such as `INBOX`, so the label id alone would select the wrong row; All Mail has a nil label id and still matches by account.
**Approved**: pending

**Decision**: When the model's selection matches no row, the sidebar leaves the outline selection as it is.
**Rationale**: The source returns early rather than clearing the selection; this keeps the previous row highlighted until the model selects a listed mailbox, which is observable behavior implementations must copy.
**Approved**: pending

**Decision**: Each rebuild expands all account groups, discarding any collapse by the user.
**Rationale**: The source expands every root after each reload and tracks no expansion state, so a group the user collapsed re-expands when the model changes. This is a quirk of the source, recorded so other platforms match or knowingly diverge.
**Approved**: pending

**Decision**: Mailbox rows indent by 14 points times depth inside the cell, not through the outline's own indentation.
**Rationale**: Mailboxes are one outline level below accounts, and the model supplies a depth for nested labels, so the cell draws the extra indent itself.
**Approved**: pending

**Decision**: Mailbox symbols are chosen by a fixed switch on label id with a tag as the fallback.
**Rationale**: System labels have a known symbol and every user label shares the tag, so no symbol is stored in the model.
**Approved**: pending

**Decision**: The view controller has no test of its own; coverage comes from the model's tests of mailbox ordering, depth and unread counts.
**Rationale**: `MailBrowserModelTests` covers the data the sidebar displays, and no test builds this view controller.
**Approved**: pending

