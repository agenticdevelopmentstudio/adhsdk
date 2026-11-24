
- **Data collected**: None by this type. It forwards request bytes, which can carry mail account names and, for `importOAuthClient`, OAuth client JSON, and reply bytes, which can carry mail content.
- **Storage**: None; nothing is written or cached.
- **Transmission**: Bytes go only to the host's `call` closure, which owns the IPC channel to the daemon.
- **Retention**: None.
- **Error text**: The `unreachable` detail and the underlying error passed to `onFailure` come from the host and are shown or handled as the host decides.

