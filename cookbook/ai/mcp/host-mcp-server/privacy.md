
- **Data collected**: None stored. Tool names are logged. Tool arguments and results pass through to sources and clients and are not logged.
- **Storage**: None; registrations and the current server live in memory.
- **Transmission**: Results leave the process over whichever transport the caller supplies. The caller identifier is read from a request header and passed to the source; it is a pane id, not a user identity.
- **Retention**: Not applicable: nothing is persisted.

