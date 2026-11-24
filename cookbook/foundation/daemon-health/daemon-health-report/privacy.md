
- **Data collected**: None by this code. It carries whatever the daemon reports, including free text in `lastMessage`.
- **Storage**: None. The probe uses an ephemeral session, so no cache, cookie or credential store is written to disk.
- **Transmission**: One GET to `<baseURL>/health`. The request adds no headers, credentials or body; whether the transport is encrypted depends on the scheme the caller passes in `baseURL`.
- **Retention**: None beyond the lifetime of the value or closure the caller holds.

