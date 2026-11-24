
- **Data collected**: None of its own; `settings.json` may hold tokens, and an adopted status-line command can embed one.
- **Storage**: `settings.json` keeps its mode (`0600` when new); status-line entries are written owner-only by `ClaudeStatusLine` (directories `0700`, entries `0600`).
- **Transmission**: None; the installer makes no network calls, and the hooks it registers write local drop files.
- **Retention**: Entries and markers stay until uninstall, a switch or a user action removes them.

