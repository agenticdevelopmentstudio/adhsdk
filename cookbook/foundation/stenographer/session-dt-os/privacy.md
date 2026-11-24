
- **Data collected**: `cwd`, `projectRoot`, `gitBranch`, `summary`, `transcriptTitle` and `lastOutput` describe a user's working directories and the content of their coding session (the agent's last reply and an AI summary); event `detail` may hold tool details.
- **Storage**: The types store nothing; the daemon persists sessions and events.
- **Transmission**: Over XPC to the app and over HTTP on the daemon's loopback address to the CLI and app.
- **Retention**: Not set by these types; the daemon owns retention.

