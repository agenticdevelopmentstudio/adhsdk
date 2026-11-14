
- **Data collected**: The store holds what its callers give it: message sender and recipient addresses, subjects, snippets, bodies, label ids and attachment references; connection account addresses and display names; provider client ids; error text; and action log request payloads and results. It holds no password, access token or refresh token; the schema has no column for one.
- **Storage**: In the SQLite database the injected `BoundedDatabase` points at. The source applies no encryption of its own and sets no file protection; whatever protects the file belongs to the caller.
- **Transmission**: None. The store makes no network call and sends nothing off the device.
- **Retention**: Rows are tombstoned, never purged, so message content and addresses stay in the file after a delete, including after `deleteConnection`. No code in the store removes them.

