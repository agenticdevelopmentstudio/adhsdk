
- **Data collected**: The worker reads each Gmail message the settings allow, through `GmailAPI.message(id:)`, and parses it into an `EmailMessage` with `GmailMessageParser`. It reads label names and counts. It handles no password or token itself; credentials live inside the injected `GmailAPI`.
- **Storage**: Messages, labels and the sync state go to the injected `IntegrationsStore` only. The worker writes nothing else to disk.
- **Transmission**: The worker sends only ids, query text, history cursors and page tokens to Gmail, through `GmailAPI`. It sends no stored data anywhere.
- **Retention**: A message that leaves the window, is deleted in Gmail or is excluded by the settings is tombstoned, which the store records as a soft delete with `is_deleted` and `deletedAt`; this worker never purges a row.

