
Test names are the Swift Testing functions in `MailBrowserModelTests`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mail-browser-001 | reload-default-selection, first-page-replaces, mailbox-label-filter | One account `a1` with labels INBOX, SENT, UNREAD; messages m1 (INBOX) and m2 (SENT); call `reload` (test `reloadSelectsTheFirstAccountsInboxAndListsIt`) | `selectedMailbox` is account `a1` with label `INBOX`; `messages` ids are m1; `hasMore` is false |
| mail-browser-002 | reload-no-accounts, reload-accounts-only-when-configured | No accounts; call `reload` (test `withNoAccountsNothingIsSelected`) | `selectedMailbox` is nil; `messages` is empty; `errorMessage` is nil |
| mail-browser-003 | all-mail-no-label-filter, select-mailbox-first-page | After `reload`, select the mailbox with label id nil (test `allMailListsWithoutALabelFilter`) | `messages` ids are m1, m2; the last list request has no labels |
| mail-browser-004 | load-more-appends, load-more-cursor, load-more-noop, first-page-limit | Five messages, page size 2; `reload`, then `loadMore` three times (test `pagesAppendUntilTheLast`) | After `reload` ids are m1, m2 and `hasMore` is true; after two calls ids are m1 to m5 and `hasMore` is false; the third call sends no request, so three list requests were sent in all |
| mail-browser-005 | select-mailbox-first-page, select-message-clears-open | Open m1, then select the SENT mailbox (test `switchingMailboxesReplacesTheListAndClosesTheMessage`) | `messages` ids are m2; `selectedMessageId` and `openedMessage` are nil |
| mail-browser-006 | stale-list-dropped | Hold the All Mail list request, select SENT, then release the held request (test `aPageForAnEarlierMailboxIsDropped`) | `selectedMailbox` is SENT; `messages` ids are m2 |
| mail-browser-007 | first-page-failure, dismiss-error | The list request fails with "store unavailable"; `reload`, then `dismissError` (test `aFailedListBecomesTheErrorMessage`) | `errorMessage` is "store unavailable", then nil after `dismissError` |
| mail-browser-008 | select-message-load | `reload`, then `select(messageId: "m1")` (test `openingAMessageLoadsItsBody`) | Before: the listed message has no body text; after: `openedMessage` body text is "body m1" |
| mail-browser-009 | mark-read-on-open, mark-read-updates-copies, mark-read-lowers-counts | m1 labeled INBOX and UNREAD, Inbox unread 2; open m1 (test `openingAnUnreadMessageMarksItReadAndLowersTheCount`) | A modify-labels request removes UNREAD from m1; `isUnread` is false for the listed and opened copies; the Inbox unread count is 1 |
| mail-browser-010 | mark-read-no-request-when-read | m1 labeled INBOX only; open m1 (test `openingAReadMessageChangesNoLabels`) | No modify-labels request is sent |
| mail-browser-011 | refresh-if-synced, refresh-if-synced-unchanged, refresh-if-synced-local-only | Store gains m0; `refreshIfSynced` with an unchanged `lastSyncAt`; then `lastSyncAt` becomes "2026-11-07T12:00:00.000Z" and `refreshIfSynced` again (test `aFinishedSyncReloadsTheList`) | First call: ids stay m1. Second call: ids are m0, m1 |
| mail-browser-012 | reload-keeps-valid-selection, refresh-keeps-row-count | Open m1, change `lastSyncAt`, call `refreshIfSynced` (test `aRefreshKeepsTheOpenMessage`) | `selectedMessageId` is m1 and `openedMessage` id is m1 |
| mail-browser-013 | mailbox-order, mailbox-attribute-labels-omitted, mailbox-nested-title, mailbox-user-sorted, mailbox-unread-count | Labels TRASH, Label_2 "Work/Clients" (user), UNREAD, CATEGORY_UPDATES, SENT, INBOX (3 unread), Label_1 "Work" (user), SPAM (test `mailboxesFollowGmailsOrderAndSkipAttributeLabels`) | Titles are Inbox, Sent, All Mail, Work, Clients, Spam, Trash; depths are 0, 0, 0, 0, 1, 0, 0; Inbox unread is 3 |
| mail-browser-014 | sender-name, sender-name-address-only | "PayPal <service@paypal.com>", "\"Doe, Jane\" <jane@example.com>", "<only@example.com>", "plain@example.com" (test `senderNameTakesTheDisplayName`) | "PayPal", "Doe, Jane", "only@example.com", "plain@example.com" |
| mail-browser-015 | list-date-today, list-date-this-year, list-date-older, list-date-locale, date-parse-fractional | UTC, locale en_US, now 2026-11-07T20:00:00Z; dates 2026-11-07T18:59:24.000Z, 2026-03-02T10:00:00.000Z, 2024-03-02T10:00:00.000Z (test `listDateShowsTimeTodayAndDayOtherwise`) | Today contains "6:59"; this year equals "Mar 2"; older contains "2024" |
| mail-browser-016 | date-unparseable | `listDate("not a date")` and `fullDate("not a date")` | Both return "not a date" |
| mail-browser-017 | select-mailbox-noop | Mailbox already selected with messages showing; call `select(mailbox:)` with the same id | No list request is sent and the open message stays open |
| mail-browser-018 | load-more-dedupes | The next page repeats an id already in `messages` | The repeated message is not appended |
| mail-browser-019 | mailbox-system-present-only, mailbox-all-mail | Labels contain only UNREAD | The mailbox list is exactly one row: All Mail with nil label id and nil unread |
| mail-browser-020 | refresh-if-synced-silent | The account read fails during `refreshIfSynced` | `errorMessage` stays nil and no reload happens |
| mail-browser-021 | select-message-unlisted | Call `select(messageId: "zz")` for an id not in `messages` | `selectedMessageId` is "zz"; `openedMessage` is nil; no client call is made |
| mail-browser-022 | unread-count-floor, unread-count-nil-untouched | Open an unread message labeled INBOX when the Inbox count is 0 (All Mail has a nil label id and a nil count) | The Inbox count stays 0; All Mail stays nil |
| mail-browser-023 | mark-read-failure | The modify-labels request fails with "denied" | `errorMessage` is "denied"; `openedMessage` is still set |
| mail-browser-024 | select-message-account-by-email | Listed message names an email no account has | The full message is loaded for the selected mailbox's account |

Vectors 016 to 024 are derived from the source behavior; the test file has no test for them.

