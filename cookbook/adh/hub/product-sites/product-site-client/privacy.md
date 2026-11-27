
- **Data collected**: None by this module. It carries a product's handle, its address and its console's login registration id in transit between the backend and the caller.
- **Storage**: None beyond React Query's in-memory cache.
- **Transmission**: The call goes to the hub's own `/api` path with the bearer token attached by the transport; the ecosystem uuid appears in the query string and a change's fields in the body. Who may read or change a product's site is the backend's decision.
- **Retention**: None; the cache is the caller's.

