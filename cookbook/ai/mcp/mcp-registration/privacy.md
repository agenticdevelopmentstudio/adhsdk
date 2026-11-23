
- **Data collected**: None. The command and the entry name a local executable path and a loopback URL; no credential is in either.
- **Storage**: This component stores nothing. Running the returned command makes Claude Code store the entry in its own configuration file (the file `isRegistered` reads); that storage is outside this source.
- **Transmission**: The command is returned as text; whatever shows or copies it decides where it goes. `isRegistered` reads one local file and sends nothing.
- **Retention**: Not defined here. The bearer token lives with adhd, which hands it to Claude Code through the helper on each connection.
- **Token never written**: Because the entry names a helper rather than a token, a shell history, a clipboard or `~/.claude.json` never holds the token, and a token adhd rotates needs no new registration.
