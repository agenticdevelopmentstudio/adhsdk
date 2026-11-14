
- **Empty accounts list**: MUST show an empty list with Remove disabled and no per-account controls; the model clears `selectedAccountId` when the selected account disappears (test `removeIntegrationClearsAccounts`).
- **Selection points at a vanished account**: MUST show no per-account controls, because they appear only for the model's `selectedAccount`; the model reselects the first account after the next reload.
- **Custom setting value**: MUST keep a window or poll value outside the fixed choices selectable by adding it to the list in ascending order (`choices(_:including:)`).
- **Whitespace-only draft fields**: MUST leave Save Client disabled, because the model trims before checking (test `anIncompleteClientFormSendsNothing`).
- **Secret too short to show a suffix**: MUST show "Stored (hidden)" instead of dots (test `aSecretTooShortToPartlyShowIsFullyHidden`).
- **Unparseable last-sync text**: MUST show "Never synced" (test `lastSyncedTextIsExactForAFixedDate`).
- **Boundary values of settings**: window choices span 7 to 365 days and poll choices 5 to 60 minutes; the view enforces no bound beyond them and shows a stored out-of-range value as a custom choice.
- **Concurrent access**: rapid toggle or picker changes MUST NOT queue one request each; the model sends the first and then only the latest (test `rapidUpdatesCoalesceToTheLatestSettings`). The view is main-actor bound and is safe to use only from the main thread.
- **Overlapping calls**: busy MUST stay true until every in-flight call finishes (tests `busyStaysTrueUntilOverlappingCallsBothFinish`, `busyIsNotClearedByTheFirstOfTwoOverlappingCalls`), so busy-gated buttons stay disabled until the last call ends.
- **Account error alerts**: MUST NOT alert again for an account error already alerted until the account leaves the error state or its error message changes; the model raises the next unseen account error only after `dismissAccountError`, and "Show Error" re-presents it on request. Whether an ordinary error alert and an account-error alert arriving together queue cleanly on one window is decided by the platform, not by the source.
- **No key window**: an error alert MUST fall back to an application-modal alert and call the close handler after it returns; the removal confirmation has no such fallback, because the shared confirmation helper answers no when given no window, so Remove then does nothing.
- **Service unavailable or call fails**: the model turns every failure into `errorMessage`, which the view shows as an alert titled "Gmail"; the view has no retry control other than pressing the same button again, and no timeout or backoff of its own.
- **Offline or disconnected**: a failed reload surfaces as the same alert and the view keeps showing the last known accounts; a pending sign-in waits on the browser until the user completes or cancels it.
- **Reconnect**: Reconnect is the Add Account flow; the service matches the account by email and reuses it (model comment on `addAccount`).
- **Sign-in cancelled**: the sign-in call fails with "Sign-in was cancelled" (model comment on `cancelSignIn`), which then appears as an alert.

