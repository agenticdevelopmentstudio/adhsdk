
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| gmail-api-001 | full-sync-after, full-sync-class-filter, full-sync-include-flag | `fullSync(settings: .default, now: Date(timeIntervalSince1970: 1_730_800_000))`; default is 30 days, nothing included (test `fullSyncQueryDefault`) | query `after:1728208000 {in:inbox in:sent in:drafts is:starred has:userlabels}`, `includeSpamTrash` false |
| gmail-api-002 | full-sync-spam-trash-terms, full-sync-include-flag | `includeSpam` and `includeTrash` true, `windowDays` 1, `now` is `Date(timeIntervalSince1970: 1_730_800_000)` (test `fullSyncQueryWithSpamAndTrash`) | query `after:1730713600 {in:inbox in:sent in:drafts is:starred has:userlabels in:spam in:trash}`, `includeSpamTrash` true |
| gmail-api-003 | full-sync-archived, full-sync-include-flag | `includeArchived` and `includeSpam` true, `windowDays` 2, `now` is `Date(timeIntervalSince1970: 1_730_800_000)` (test `fullSyncQueryArchivedDropsClassFilter`) | query exactly `after:1730627200`, `includeSpamTrash` true |
| gmail-api-004 | cursor-expired | `history` against a server answering 404 (test `historyNotFoundThrowsCursorExpired`) | throws `GmailCursorExpired` |
| gmail-api-005 | thread-messages-optional | decode `{"id":"t1"}` as a thread (test `aThreadWithNoMessagesDecodesEmpty`) | `id` is `t1`, `messages` is empty |
| gmail-api-006 | batch-modify | `batchModify(ids: ["a"], add: ["STARRED"], remove: ["INBOX"])` (test `batchModifyPostsBody`) | one POST with body `ids ["a"]`, `addLabelIds ["STARRED"]`, `removeLabelIds ["INBOX"]` |
| gmail-api-007 | batch-modify-limits | empty `ids`, then 1001 ids (test `batchModifyRejectsEmptyAndOversizedListsWithoutCallingGmail`) | each throws `IntegrationError`; zero requests sent |
| gmail-api-008 | history-page | a history response with changed and deleted entries (test `historyPageCollectsChangedAndDeleted`) | `changedIds`, `deletedIds`, `historyId` and `nextPageToken` populated from the response |
| gmail-api-009 | thread-id-required | decode `{"messages":[]}` as a thread (no test yet) | decoding throws |
| gmail-api-010 | failure-surfaces, no-error-translation-here | `profile()` against a 403 with message `Insufficient Permission` (test `errorBodyMessageSurfaces`) | throws an implementation error other than `GmailCursorExpired` (for `GmailRESTClient`, `IntegrationError.gmail(status: 403, message: "Insufficient Permission")` after one request) |
| gmail-api-011 | message-shape | decode `{"id":"m","threadId":"t"}` as a message (no test yet) | succeeds; all optional fields are nil |
| gmail-api-012 | label-shape | decode `{"id":"L","name":"n"}` as a label (no test yet) | decoding throws because `type` is missing |
| gmail-api-013 | part-tree | decode `{"mimeType":"multipart/mixed","parts":[{"mimeType":"text/plain","body":{"data":"aGk","size":2}},{"mimeType":"multipart/alternative","parts":[{"mimeType":"text/html"}]}]}` as a part (no test yet) | `parts` has two children; the first has `body.data` `aGk` and `size` 2; the second has one child with `mimeType` `text/html`; every other field is nil |
| gmail-api-014 | sub-second-now, full-sync-after | `fullSync(settings: .default, now: Date(timeIntervalSince1970: 1_730_800_000.9))` with `windowDays` 1 (no test yet) | query starts `after:1730713600` (the fraction is dropped) |
| gmail-api-015 | window-days-boundary, full-sync-after | `fullSync` with `windowDays` 0, `includeArchived` true and `now` `Date(timeIntervalSince1970: 1_730_800_000)` (no test yet) | query exactly `after:1730800000` |
