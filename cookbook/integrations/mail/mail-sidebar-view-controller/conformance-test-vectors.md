
The view controller has no test of its own. The model it reads has tests in `MailBrowserModelTests`, notably `mailboxesFollowGmailsOrderAndSkipAttributeLabels`, which asserts depths of `0, 0, 0, 0, 1, 0, 0` and an inbox unread count of 3; the rows below that name no test are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mail-sidebar-001 | account-groups, mailbox-children | Two accounts, the first with Inbox and Sent, the second with Inbox | Two group rows, with two mailbox rows under the first and one under the second. |
| mail-sidebar-002 | mailbox-children | An account whose id has no entry in `mailboxes` | Its group row shows with no children. |
| mail-sidebar-003 | expand-on-rebuild, rebuild-on-model | The model's `accounts` changes | The outline reloads and every group is expanded. |
| mail-sidebar-004 | account-row-text | Account email `me@example.com` | Group row text reads `me@example.com`, small system font, semibold, secondary color. |
| mail-sidebar-005 | mailbox-row-symbol | Label ids `INBOX`, `STARRED`, `IMPORTANT`, `SENT`, `DRAFT`, nil, `SPAM`, `TRASH`, `Label_9` | Symbols `tray`, `star`, `exclamationmark.circle`, `paperplane`, `doc`, `tray.full`, `xmark.bin`, `trash`, `tag`. |
| mail-sidebar-006 | mailbox-row-indent | Mailbox with depth 1 (the nested `Work/Clients` label from `mailboxesFollowGmailsOrderAndSkipAttributeLabels`) | Row content starts 14 points from the leading edge. |
| mail-sidebar-007 | mailbox-row-indent | Mailbox with depth 0 | Row content starts at the leading edge. |
| mail-sidebar-008 | mailbox-row-unread-count | Mailbox with unread 3 | A trailing label reads `3`. |
| mail-sidebar-009 | mailbox-row-unread-count | Mailbox with unread 0 | No count label. |
| mail-sidebar-010 | mailbox-row-unread-count | Mailbox with unread nil (All Mail) | No count label. |
| mail-sidebar-011 | only-mailboxes-selectable | User clicks an account group row | The selection does not change and the model is not called. |
| mail-sidebar-012 | selection-to-model | User clicks the Sent row of account `a1` | The model's `select(mailbox:)` is called with account id `a1` and label id `SENT`. |
| mail-sidebar-013 | selection-from-model, selection-echo-guard | The model sets `selectedMailbox` to account `a1`, label `INBOX` | The Inbox row of `a1` is selected and `select(mailbox:)` is not called by the sidebar. |
| mail-sidebar-014 | selection-from-model | Two accounts both have an Inbox; the model selects the second account's Inbox | The second account's Inbox row is selected, not the first. |
| mail-sidebar-015 | selection-from-model | The model selects All Mail (label id nil) | The All Mail row is selected. |
| mail-sidebar-016 | selection-no-match | The model's `selectedMailbox` is nil | The outline selection is unchanged. |
| mail-sidebar-017 | selection-no-match | The model selects a mailbox that is not listed | The outline selection is unchanged. |
| mail-sidebar-018 | selection-no-op | The model sets `selectedMailbox` to the row already selected | No selection call reaches the outline. |
| mail-sidebar-019 | selection-clear-ignored | The outline selection clears | The model is not called. |
| mail-sidebar-020 | accessibility-identifier | Inspect the outline | Identifier is `mail.sidebar`. |
| mail-sidebar-021 | mailbox-accessibility-label | Mailbox titled `Inbox` | Row accessibility label is `Inbox`. |
| mail-sidebar-022 | single-column-outline, source-list-style | Inspect the outline | One column `mailbox`, no header, source list style, group rows do not float. |
| mail-sidebar-023 | model-injection | Build the controller from a coder | The process stops with the fatal error `init(coder:) has not been implemented`. |
| mail-sidebar-024 | selection-single | Inbox row selected; the model selects the Sent row | Only the Sent row is selected. |
| mail-sidebar-025 | mailbox-row-title-yields | A mailbox with a long title and unread 12 in a narrow sidebar | The title truncates at the tail; the symbol and the `12` count stay fully visible. |
| mail-sidebar-026 | account-row-truncation | Account email longer than the sidebar width | The group row text truncates at the tail. |
| mail-sidebar-027 | main-queue-hop | The model publishes `accounts` from a background queue | The rebuild runs on the main queue. |
| mail-sidebar-028 | selection-after-rebuild | Inbox of `a1` is selected, then the model's `mailboxes` changes | After the reload the Inbox row of `a1` is selected again. |
| mail-sidebar-029 | empty-accounts | The model has no accounts | The outline has zero rows and no message is drawn. |
| mail-sidebar-030 | group-expandable-with-children | One account with no mailboxes and one with Inbox | The first group row is not expandable; the second is. |
| mail-sidebar-031 | unread-count-plain-integer | Mailbox with unread 1234 | The count label reads `1234`. |
| mail-sidebar-032 | selection-task-unhandled | The model's `select(mailbox:)` fails and sets `errorMessage` | The sidebar shows no error itself and the model's `errorMessage` is set. |
