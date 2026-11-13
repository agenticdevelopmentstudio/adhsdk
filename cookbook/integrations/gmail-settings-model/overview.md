
`GmailSettingsModel` is the state behind the Gmail settings view. It is a main-actor `ObservableObject` that wraps a `MailClient` and exposes the mail provider status, the list of Gmail accounts, the selected account, the OAuth client form drafts, a busy flag, a sign-in flag, an error message and a pending account-error alert. Every action the view offers (reload, import or save the OAuth client, add or reconnect an account, cancel a sign-in, remove an account, update an account's sync settings, sync now, remove the integration) goes through this model. The source comment states the intent: "this is the tested unit; the view only reads it and calls it."

The file also holds `GmailSignInTracker`, a main-actor ticket counter shared by all settings models. A browser return (`temporal://signed-in`) says only that a sign-in finished, not which surface started it, so each model keeps the ticket of its last sign-in and `startedLatestSignIn` tells the surface that started the newest one apart from the others.

Use it wherever the Gmail integration is configured. It owns no views and makes no calls except through the injected client.

