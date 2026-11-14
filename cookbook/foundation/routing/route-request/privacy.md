
- **Data handled**: The method, path, query values, headers and body of a request, as given by the daemon, plus the raw rejected timestamp echoed into the failure message.
- **Storage**: None; it persists nothing.
- **Transmission**: None by itself; the failure message that quotes the raw value is sent by whatever builds the response.
- **Retention**: None beyond the lifetime of the value the caller holds.

