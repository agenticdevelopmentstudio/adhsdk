
The model's display helpers have tests in `MailBrowserModelTests`; the view controller has no test of its own, so the rows that name no test are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mail-list-001 | row-sender | `from` is `PayPal <service@paypal.com>` (test `senderNameTakesTheDisplayName`) | Sender text is `PayPal`. |
| mail-list-002 | row-sender | `from` is `"Doe, Jane" <jane@example.com>` (same test) | Sender text is `Doe, Jane`. |
| mail-list-003 | row-sender | `from` is `<only@example.com>` (same test) | Sender text is `only@example.com`. |
| mail-list-004 | row-sender | `from` is `plain@example.com` (same test) | Sender text is `plain@example.com`. |
| mail-list-005 | row-date | now is 2026-11-07 20:00 UTC, message dated 2026-11-07T18:59:24.000Z, locale en_US (test `listDateShowsTimeTodayAndDayOtherwise`) | Date text contains `6:59`. |
| mail-list-006 | row-date | same now, message dated 2026-03-02T10:00:00.000Z (same test) | Date text is `Mar 2`. |
| mail-list-007 | row-date | same now, message dated 2024-03-02T10:00:00.000Z (same test) | Date text contains `2024`. |
| mail-list-008 | row-date-unparsed | Message date text is `not a date` | Date text is `not a date`. |
| mail-list-009 | row-subject | Message subject is the empty string | Subject text is `(no subject)`. |
| mail-list-010 | unread-dot, unread-weight, unread-definition | Message labels contain `UNREAD` | Dot visible, sender bold, subject semibold. |
| mail-list-011 | unread-dot, unread-weight | Message labels do not contain `UNREAD` | Dot hidden, sender and subject regular. |
| mail-list-012 | row-accessibility-label | Sender `PayPal`, subject `Receipt` | Row accessibility label is `PayPal, Receipt`. |
| mail-list-013 | load-more-on-last-row | Five messages, `hasMore` is true, row 4 is shown | The model's `loadMore()` is called once. |
| mail-list-014 | load-more-on-last-row | Five messages, `hasMore` is false, row 4 is shown | `loadMore()` is not called. |
| mail-list-015 | stale-row-guard | Table asks for row 3 after `messages` shrank to two entries | No view is returned and nothing is loaded. |
| mail-list-016 | empty-label, empty-label-text | `messages` empty, `loading` true | Label visible and reads `Loading…`. |
| mail-list-017 | empty-label, empty-label-text | `messages` empty, `loading` false | Label visible and reads `No messages`. |
| mail-list-018 | empty-label | `messages` has one entry | Label hidden. |
| mail-list-019 | selection-to-model | User clicks row 1 of three | The model's `select(messageId:)` is called with row 1's id. |
| mail-list-020 | selection-from-model, selection-echo-guard | Model sets `selectedMessageId` to the id of row 2 | Row 2 is selected and the model receives no `select(messageId:)` call from the list. |
| mail-list-021 | selection-from-model | Model sets `selectedMessageId` to an id not in `messages` | The table selection clears. |
| mail-list-022 | accessibility-identifier | Inspect the table | Identifier is `mail.messages`. |
| mail-list-023 | single-column-table | Inspect the table | One column `message`, no header, row height 68. |
| mail-list-024 | model-injection | Build the controller from a coder | The process stops with the fatal error `init(coder:) has not been implemented`. |

