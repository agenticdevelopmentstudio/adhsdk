
- **Data collected**: working directories, project roots, session names, git branches, model, pid and the summarizer's line about what the session is doing.
- **Storage**: none here; the daemon owns the session record.
- **Transmission**: values go from the daemon to `steno` and the app on the local machine; this code opens no connection.
- **Retention**: none defined by this code.

