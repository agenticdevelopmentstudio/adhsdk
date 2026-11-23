
- **Data collected**: None by this module. It carries customer emails, display names, avatar URLs, external ids, roles, set ids and storage figures in transit between the backend and the caller. The roster is existence, not content: it says who a customer is, when they were last active, what they hold and how much storage they use, and never anything they made.
- **Storage**: None beyond React Query's in-memory cache.
- **Transmission**: Each call goes to the `/api/v1` path with the bearer token attached by the transport; the ecosystem uuid and customer id appear in the query string or path. Who may read or change the roster is the backend's decision.
- **Retention**: None; the cache is the caller's.

