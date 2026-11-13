
GmailSettingsView is the Gmail detail pane of the macOS settings surface. It has two sections stacked vertically and separated by a divider: an **OAuth Client** section for entering or importing the Google Cloud Desktop app client, and an **Accounts** section that lists signed-in Gmail accounts and exposes sync controls for the selected one.

The view owns no business state. The contract is that it reads `GmailSettingsModel` and calls it, nothing else. The model is observed, never created, by the view. Every action the view offers is a call into the model, and every piece of display text that is not a fixed label comes from the model (`oauthClientText`, `currentClientId`, `maskedClientSecret`, `statusText`, `lastSyncedText`). The view adds two things the model does not: presentation of errors as alerts, and the two native panels (open panel for the client JSON, destructive confirmation for account removal).

Use it as the Gmail entry of a settings window whose model is already built. It does not load itself: the model must be reloaded by its owner, and until it has been, the pane shows the model's "Checking for an OAuth client…" text.

