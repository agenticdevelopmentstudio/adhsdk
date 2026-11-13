
- **Data collected**: The client ID and client secret typed into the form (held in the model's draft fields), and the JSON file chosen by the user. The view displays account emails and sync times.
- **Storage**: The view stores nothing. Drafts live in the model until saved; they are cleared after a successful save and kept after a failure. The service stores the client secret, and the model's `maskedClientSecret` comment states "The daemon sends only those characters", the last five, so the full secret is never returned to the view.
- **Transmission**: Client values and file bytes go to the mail service through the model; the view makes no network call. Removing an account signs it out of Google and deletes its mail from this Mac, as the confirmation text states.
- **Retention**: Not governed by the view. Account mail is fetched for the chosen window (7 to 365 days by default choices) and deleted from this Mac when the account is removed.

