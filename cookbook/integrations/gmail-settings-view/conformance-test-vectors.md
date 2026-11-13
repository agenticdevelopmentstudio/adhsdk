
The model's tests are in `GmailSettingsModelTests` (`packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKMacOSTests/Integrations/GmailSettingsModelTests.swift`). The view has no test beside it, so vectors marked "(view)" are derived from the view source; those naming a test assert the model behavior the view relies on.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| gmail-001 | client-heading-and-text | Model before first load (test `oauthClientTextBeforeTheFirstLoad`) | Pane shows "Checking for an OAuth client…"; no current-value grid. |
| gmail-002 | client-heading-and-text, add-client-first-hint | Model loaded with an unconfigured provider (test `oauthClientTextWhenNoClientIsImported`) | Text begins "Enter the client ID and secret of your Google Cloud Desktop app OAuth client"; caption "Add the OAuth client above before adding an account." shown; Add Account disabled. |
| gmail-003 | current-client-readout, secret-masked-readout | Provider configured, client ID "id-9.apps.googleusercontent.com", secret suffix "12345" (test `theImportedClientIsShownWithTheSecretMasked`) | Grid shows the full ID and "••••••••••12345"; buttons read "Replace Client" and "Replace from JSON…". |
| gmail-004 | current-client-readout, secret-masked-readout | Provider configured with no secret suffix (test `aSecretTooShortToPartlyShowIsFullyHidden`) | Current secret row reads "Stored (hidden)". |
| gmail-005 | current-client-readout | Provider unconfigured (test `nothingIsShownWithoutAnImportedClient`) | No current-value grid. |
| gmail-006 | save-client-enablement | Client ID "id", secret "   " (test `anIncompleteClientFormSendsNothing`) | Save Client disabled; no import request is sent. |
| gmail-007 | save-client-button | ID "  id-1.apps.googleusercontent.com \n", secret " GOCSPX-secret " (test `savingTheClientFormSendsItAsInstalledJSONAndClearsTheFields`) | One import request with trimmed values; both fields empty afterward; no alert. |
| gmail-008 | save-client-button, error-as-alert | Service rejects the import with "bad client" (test `aRejectedClientKeepsTheFormFilled`) | Fields keep "id" and "secret"; an alert titled "Gmail" shows "bad client". |
| gmail-009 | import-json-call | Chosen file containing a client JSON (test `importFromURLSendsTheFileBytes`) | The file's bytes are sent unchanged; no error; client reported configured. |
| gmail-010 | import-json-call, error-as-alert | Chosen URL that does not exist (test `importFromMissingURLSetsErrorMessage`) | No import request; an alert titled "Gmail" shows the read failure. |
| gmail-011 | import-json-cancel | Open panel dismissed without a file (view) | No model call; no alert. |
| gmail-012 | import-json-panel | Press "Import Client JSON…" (view) | Modal open panel accepting only JSON, one file, no folders. |
| gmail-013 | reconnect-hint | Client imported, one account (view) | Caption "Accounts signed in with a replaced client need Reconnect." shown; absent when accounts is empty. |
| gmail-014 | account-row-content | Status values active, error, revoked, pending (test `statusText`) | Badges read "Connected", "Error", "Reconnect needed", "Pending". |
| gmail-015 | account-row-content | Last sync two hours before now, en_US (test `lastSyncedTextIsExactForAFixedDate`) | Caption "Last synced 2 hours ago". |
| gmail-016 | account-row-content | No last sync, or unparseable text "garbage" (same test) | Caption "Never synced". |
| gmail-017 | account-list, controls-follow-selection | Loaded accounts, no prior selection (test `reloadLoadsProviderAndAccounts`) | List shows the account; first account selected; per-account controls visible. |
| gmail-018 | add-account-button | Press "Add Account…" with a client imported (test `addAccountSendsSignInThenReloads`) | Sign-in request sent, then accounts reloaded. |
| gmail-019 | add-account-button | Model busy, or no client imported (view) | Button disabled. |
| gmail-020 | sign-in-progress, cancel-sign-in | Sign-in pending (test `cancelSignInSendsCancelWhileSigningIn`) | Spinner, waiting caption and Cancel visible; pressing Cancel sends cancel-sign-in even though busy is true; `signingIn` false after the sign-in call ends. |
| gmail-021 | remove-confirmation, remove-safe-default | Press "Remove" with "a@x.com" selected (view) | Confirmation titled "Remove a@x.com?" with the stated detail, Cancel default, action "Remove". |
| gmail-022 | remove-call | Confirm removal (test `removeSendsRemoveAccount`) | Remove-account request for that account's ID. |
| gmail-023 | remove-call | Decline removal, press Esc, or press Remove with no key window (view; the confirmation helper answers no without a window) | No model call. |
| gmail-024 | remove-button | No account selected, or model busy (view) | Remove disabled. |
| gmail-025 | sync-now-button | Press "Sync Now" (test `syncNowSendsSyncNow`) | Sync-now request for the selected account. |
| gmail-026 | reconnect-button | Selected account status revoked or error (view) | "Reconnect" shown; pressing it calls addAccount. |
| gmail-027 | reconnect-button | Selected account status active or pending (view) | "Reconnect" absent. |
| gmail-028 | show-error-button, account-error-as-alert | Account in error with a last error, press "Show Error" (view, model `showError`) | Alert titled "<email> couldn't sync" with the error message. |
| gmail-029 | show-error-button | Account in error with no last error (view) | "Show Error" absent. |
| gmail-030 | whole-settings-write | Toggle "Sync junk mail" on and set window to 90 (test `updateSendsSettings`) | Update request carries the whole settings with `includeSpam` true and `windowDays` 90; account shows them. |
| gmail-031 | whole-settings-write, error-as-alert | Update rejected with "nope" (test `updateFailureRestoresServerStateAndSetsError`) | Alert titled "Gmail" shows "nope"; account settings revert to the server's. |
| gmail-032 | settings-stay-enabled | Changes made while a settings send is in flight (tests `rapidUpdatesCoalesceToTheLatestSettings`, `aReloadDuringASettingsSendKeepsShowingTheChosenValue`) | Controls show the chosen value at once; only the first and the latest values are sent. |
| gmail-033 | window-picker, poll-picker | Account with window 30 days and poll 15 minutes (view) | Window picker lists 7, 14, 30, 90, 180, 365 days; poll picker lists 5, 15, 30, 60 minutes. |
| gmail-034 | custom-value-preserved | Account with window 45 days (view) | Window picker lists 7, 14, 30, 45, 90, 180, 365 days with 45 selected. |
| gmail-035 | error-as-alert | Sign-in fails with "sign-in cancelled" (test `remoteFailureSetsErrorMessage`) | Warning alert titled "Gmail" with that message; closing it calls `dismissError`, leaving `errorMessage` nil (test `dismissErrorClearsIt`). |
| gmail-036 | alert-on-appear | Model already holds an error message when the view appears (view) | Alert shown immediately. |
| gmail-037 | alert-sheet-or-modal | No key window when an error arrives (view) | Application-modal alert; `dismissError` called after it closes. |
| gmail-038 | secret-entry-concealed | Type into "Client secret" (view) | Characters are concealed. |
| gmail-039 | no-self-loading | View created over a fresh model (view) | No service request is made by the view itself. |

