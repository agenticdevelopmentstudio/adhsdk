
- **Data handled**: The requests passed through `handle`, which may carry headers and a body; the table only forwards them to handlers.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access itself.
- **Retention**: None beyond the lifetime of the table and the requests the caller holds.

