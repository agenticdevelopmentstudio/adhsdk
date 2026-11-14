
- **Data collected**: None by this module; it handles list rows only in transit and returns them to the caller.
- **Storage**: None; rows, cursors and timestamps live in local variables for the duration of a call.
- **Transmission**: Each page request goes to the caller-supplied `url` with the bearer token attached by `authedJson`; the cursor and filters appear in the query string.
- **Retention**: None; nothing is cached between calls.

