
The model contract the controller relies on is covered by `MailBrowserModelTests`; no test file covers the controller itself, so the controller vectors below are manual or UI-test vectors derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mail-browser-vc-001 | client-only-dependency, model-owned | Construct with a client and no interval. | The controller exists and its `model` is non-nil. |
| mail-browser-vc-002 | shared-model | Construct, load the view, then on the controller's `model` select the "Sent" mailbox and then one message in it. | The sidebar highlights "Sent", the message list shows the Sent messages, and the reader shows the selected message's body (the panes hold the model privately, so only the shared instance can drive all three). |
| mail-browser-vc-003 | no-coder-init | Decode the controller from an archive. | The process traps with "init(coder:) has not been implemented". |
| mail-browser-vc-004 | pane-order | Load the view. | Items are, in order: sidebar, message list, reader. |
| mail-browser-vc-005 | sidebar-width, list-min-width, reader-min-width | Drag each divider to its extremes. | Sidebar stays within 180 to 320 points; list never below 280; reader never below 360. |
| mail-browser-vc-006 | divider-persistence | Move a divider, close and reopen the window. | The divider is where it was left; the autosave name is "MailBrowserSplit". |
| mail-browser-vc-007 | initial-load | Load the view with a scripted client holding one account. | The model reloads once; its selected mailbox is that account's Inbox (see `reloadSelectsTheFirstAccountsInboxAndListsIt`). |
| mail-browser-vc-008 | poll-interval, poll-action | Appear with a 30 s interval and a client whose account sync time is later changed. | No refresh at 0 s; the first refresh call happens at 30 s; new messages show after it (model side: `aFinishedSyncReloadsTheList`). |
| mail-browser-vc-009 | poll-stop, poll-cancel-exit | Appear, then disappear 5 s later, with a 30 s interval. | No refresh call is made after the disappearance. |
| mail-browser-vc-010 | poll-start | Appear twice without disappearing in between. | Only one refresh task runs; the first is cancelled. |
| mail-browser-vc-011 | error-observe, error-alert-content, error-sheet, error-dismiss | Model fails a list request with "store unavailable" (see `aFailedListBecomesTheErrorMessage`) while the view is in a window. | A warning sheet titled "Mail" shows "store unavailable" with one "OK" button; after OK the model's error message is nil. |
| mail-browser-vc-012 | error-modal-fallback, error-dismiss | Same failure while the view has no window. | A modal alert runs; when it returns the model's error message is nil. |
| mail-browser-vc-013 | error-nil-ignored | Model's error message goes from a message to nil via dismiss. | No second alert appears. |
| mail-browser-vc-014 | poll-default-interval | Construct without an interval. | Refreshes occur every 30 seconds while on screen. |
| mail-browser-vc-015 | poll-no-retain | Release the controller while a refresh task is waiting. | When the wait ends the task exits and makes no model call. |
| mail-browser-vc-016 | poll-interval, poll-action, poll-stop, poll-cancel-exit, poll-no-retain | Construct with `refreshInterval` of 100 ms and a scripted client whose account sync time changes once; appear, wait 250 ms, then disappear and wait 250 ms more; repeat, releasing the controller instead of disappearing. | No refresh before 100 ms; the refresh after the sync change reloads the list; no model call follows the disappearance or the release. Runs in milliseconds, with no 30 s wait; vectors 008, 009, 014 and 015 use the same check with the default interval. |
