
### Layout and structure

- **section-order**: The view MUST render the OAuth Client section first, a divider, then the Accounts section, in one leading-aligned vertical stack with 12 pt spacing between them.
- **fill-and-inset**: The view MUST inset its content by 20 pt on every edge and expand to fill the width and height offered, anchored top-leading.
- **no-self-loading**: The view MUST NOT load the provider or accounts itself; it MUST display whatever the model currently holds.

### OAuth client section

- **client-heading-and-text**: The OAuth Client section MUST show the heading "OAuth Client" followed by the model's `oauthClientText`, wrapping onto as many lines as it needs.
- **current-client-readout**: When the model reports both a current client ID and a masked client secret, the view MUST show them as a two-row grid labelled "Current client ID" and "Current secret"; when either is nil the grid MUST be absent.
- **client-id-selectable**: The current client ID MUST be shown in full, in a monospaced face, and MUST be selectable text.
- **secret-never-revealed**: The current secret MUST be shown only as the model's `maskedClientSecret`, in a monospaced face, and MUST NOT be selectable.
- **client-form-fields**: The view MUST show a "Client ID" text field with the prompt "….apps.googleusercontent.com" bound to the model's `clientIdDraft`, and a "Client secret" secure field bound to `clientSecretDraft`, in a form no wider than 460 pt.
- **save-client-button**: The view MUST show a button titled "Save Client" when no client is imported and "Replace Client" when one is, and pressing it MUST call the model's `saveClientDraft`.
- **save-client-enablement**: The save-client button MUST be disabled while the model is busy or while `canSaveClientDraft` is false.
- **import-json-button**: The view MUST show a button titled "Import Client JSON…" when no client is imported and "Replace from JSON…" when one is, separated from the save button by the secondary-styled word "or".
- **import-json-enablement**: The import button MUST be disabled while the model is busy, and MUST NOT depend on the draft fields.
- **import-json-panel**: Pressing the import button MUST open a modal file-open panel that allows only JSON files, a single selection, and no directories.
- **import-json-cancel**: If the file panel is dismissed without choosing a file, the view MUST make no model call.
- **import-json-call**: If a file is chosen, the view MUST call the model's `importClientJSON(from:)` with its URL.
- **reconnect-hint**: When a client is imported and at least one account exists, the view MUST show the caption "Accounts signed in with a replaced client need Reconnect."

### Accounts section

- **accounts-heading**: The Accounts section MUST show the heading "Accounts".
- **add-client-first-hint**: While no client is imported, the view MUST show the caption "Add the OAuth client above before adding an account."
- **account-list**: The view MUST show the model's accounts in a selectable list at least 120 pt tall, with the selection bound to the model's `selectedAccountId`.
- **account-row-content**: Each row MUST show the account's email, a capsule badge containing `GmailSettingsModel.statusText` for the account's status, and beneath them a caption in secondary style containing `GmailSettingsModel.lastSyncedText` for the account's last sync time.
- **add-account-button**: The view MUST show an "Add Account…" button that calls the model's `addAccount`, and MUST disable it while the model is busy or no client is imported.
- **remove-button**: The view MUST show a "Remove" button, MUST disable it while no account is selected or the model is busy, and on press MUST ask for confirmation for the selected account instead of removing it.
- **remove-confirmation**: The removal confirmation MUST be titled "Remove <email>?", MUST say it signs the account out of Google, removes its stored sign-in and deletes its mail from this Mac, and MUST offer an action titled "Remove".
- **remove-safe-default**: The removal confirmation MUST make Cancel the default response to Return, and Esc MUST decline.
- **remove-call**: The view MUST call the model's `remove(accountId:)` only when the user confirms, and MUST make no model call when the user declines or when there is no key window to attach the confirmation to.
- **sign-in-progress**: While the model's `signingIn` is true, the view MUST show a small spinner, the caption "Waiting for Google sign-in in your browser…" and a "Cancel" button beside the Add Account and Remove buttons.
- **cancel-sign-in**: The "Cancel" button MUST call the model's `cancelSignIn` and MUST NOT be disabled by the model's busy state.

### Selected-account controls

- **controls-follow-selection**: The per-account controls MUST appear only while the model has a selected account, and MUST act on that account.
- **reconnect-button**: The view MUST show a "Reconnect" button only when the selected account's status is revoked or error; it MUST call the model's `addAccount` and MUST be disabled while the model is busy.
- **sync-now-button**: The view MUST show a "Sync Now" button for every selected account that calls the model's `syncNow(accountId:)` and MUST be disabled while the model is busy.
- **show-error-button**: The view MUST show a "Show Error" button only when the selected account's status is error and its last error is present; it MUST call the model's `showError(accountId:)` and MUST NOT be disabled by the busy state.
- **sync-toggles**: The view MUST show three toggles, "Sync archived mail", "Sync junk mail" and "Sync deleted mail", bound to the account's `includeArchived`, `includeSpam` and `includeTrash` settings.
- **window-picker**: The view MUST show a "Fetch mail from the last" picker, no wider than 300 pt, whose fixed choices are 7, 14, 30, 90, 180 and 365 days, each labelled "<n> days".
- **poll-picker**: The view MUST show a "Check for mail every" picker, no wider than 300 pt, whose fixed choices are 5, 15, 30 and 60 minutes, each labelled "<n> minutes".
- **custom-value-preserved**: When an account's current window or poll value is not one of the fixed choices, the picker MUST add that value to its choices in ascending order so the current value stays selectable and displayed.
- **whole-settings-write**: A change to any toggle or picker MUST send the account's complete settings with only that field changed, through the model's `update(accountId:_:)`.
- **settings-stay-enabled**: The toggles and pickers MUST NOT be disabled while the model is busy, because the model coalesces rapid changes.

### Error presentation

- **error-as-alert**: When the model's `errorMessage` becomes non-nil, the view MUST present a warning alert titled "Gmail" with that message and an "OK" button, and MUST call the model's `dismissError` when the alert is closed.
- **account-error-as-alert**: When the model's `accountError` becomes non-nil, the view MUST present a warning alert titled "<email> couldn't sync" with the error's message and an "OK" button, and MUST call the model's `dismissAccountError` when the alert is closed.
- **alert-on-appear**: The view MUST present an alert for an error already set when the view first appears.
- **alert-sheet-or-modal**: The view MUST present an alert as a sheet on the key window when there is one, and otherwise as an application-modal alert, and in both cases MUST report the close to the model afterward.
- **no-inline-errors**: The view MUST NOT show error text inline in the pane; the only error text outside alerts is the account row's "Error" badge.

### Security

- **secret-entry-concealed**: The client secret entry field MUST conceal what is typed.
- **secret-masked-readout**: The view MUST NOT display the stored client secret in any form other than the model's masked value.

