
- **Data collected**: `sessionId`, `reason` and `detail` describe a user's live coding session and may name projects or contain structured context.
- **Storage**: The type stores nothing; the daemon persists findings in its own database.
- **Transmission**: Over XPC to the app and over HTTP on the session daemon's (adhd's) loopback API to the CLI and app; the retired stenographerd's `22847` is not used.
- **Retention**: Not set by this type; the daemon's findings table owns it.

