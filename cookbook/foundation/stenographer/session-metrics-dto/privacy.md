
- **Data collected**: Session identifiers, model names, token and cost totals and turn times; `sourceDirectory` is a local path.
- **Storage**: The types store nothing; the daemon persists metrics and transcript lines.
- **Transmission**: Over XPC and over HTTP on the daemon's loopback address.
- **Retention**: Not set by these types.

