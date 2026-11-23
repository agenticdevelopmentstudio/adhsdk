
- **Data collected**: None by this module. It carries grants (who asked, why, for how long), the read log (which route and when, never row contents) and, through the viewer, a customer's rows in transit between the backend and a product admin holding a live grant.
- **Storage**: None beyond React Query's in-memory cache. The viewer's rows MUST NOT be written to storage. The emailed-link token is never stored.
- **Transmission**: Each call goes to a `/v1` path with the bearer token attached by the transport, except the public client, whose token travels in the query string or body. Who may read is the backend's decision, taken in the database.
- **Retention**: None; the cache is the caller's.

