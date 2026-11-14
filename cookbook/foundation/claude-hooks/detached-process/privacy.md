
- **Data collected**: None of its own; it forwards the payload its caller passes (the status-line feed's snapshot, per the source's comments) to the command it starts.
- **Storage**: None beyond the empty lock file, which holds no content, mode `0600`, named from the sanitised session id.
- **Transmission**: None by this type; the payload goes to a local child process on a pipe, and its output is discarded.
- **Retention**: The lock file stays in the temporary directory until the system clears it.

