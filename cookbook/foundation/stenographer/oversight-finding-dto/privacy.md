
- **Data collected**: `sessionId`, `reason` and `detail` describe a user's live coding session and may name projects or contain structured context.
- **Storage**: The type stores nothing; the daemon persists findings in its own database.
- **Transmission**: Over XPC to the app and over HTTP on the daemon's loopback address (`http://127.0.0.1:22847` by default) to the CLI and app.
- **Retention**: Not set by this type; the daemon's findings table owns it.

