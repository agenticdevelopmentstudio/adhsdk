
- **Data collected**: None of its own; `settings.json` may hold tokens, an adopted status-line command can embed one, and a foreign `ANTHROPIC_BASE_URL` can carry credentials in its userinfo.
- **Storage**: `settings.json` keeps its mode (`0600` when new); status-line entries are written owner-only by `ClaudeStatusLine` (directories `0700`, entries `0600`); the marker files are empty.
- **Transmission**: None; the installer makes no network calls, and the hooks it registers write local drop files. The router pointer it writes makes Claude Code send its API traffic to `routerBaseURL`, a loopback address by default.
- **Retention**: Entries, markers and the router pointer stay until uninstall, a switch or a user action removes them.
- **Display redaction**: A router value that is not ours is only ever exposed as `scheme://host[:port]` or `custom value`, never with its path, query, fragment or userinfo, so a conflict message or `other` state cannot leak a credential.

