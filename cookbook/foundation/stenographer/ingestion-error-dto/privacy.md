
- **Data collected**: the quarantined file's name, the event type, the session id and the failure reason.
- **Storage**: none here; the daemon keeps the files on disk and the rows in the `ingestion_errors` table.
- **Transmission**: values cross XPC to the app and HTTP to the CLI on the local machine; this code opens no connection.
- **Retention**: defined by the daemon; the log keeps resolved rows as history.

