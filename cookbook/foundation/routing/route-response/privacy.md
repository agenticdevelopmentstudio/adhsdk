
- **Data handled**: Whatever the caller encodes into `body` and `headers`, and the error message text.
- **Storage**: None; it persists nothing.
- **Transmission**: None by itself; the daemon's HTTP layer transmits the response.
- **Retention**: None beyond the lifetime of the value the caller holds.

