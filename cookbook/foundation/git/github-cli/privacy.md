
- **Data handled**: Pull request metadata from GitHub, and a title and body the user typed for a new pull request.
- **Storage**: None; nothing is persisted. No token is stored or read; authentication is `gh`'s own.
- **Transmission**: `gh` talks to the host it is logged in to; the client adds no host and no credential.
- **Retention**: The command log's in-memory ring keeps the redacted command line and, for a failed call, the first 2 KB of standard error with URL user info redacted, for the life of the process.

