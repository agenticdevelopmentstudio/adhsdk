
- **Data collected**: None by this module. It carries customer ids, set ids, grant rows (including `billing_account_id` and `granted_by`) and effective answers in transit between the backend and the caller.
- **Storage**: None; rows live in local variables and are returned to the caller.
- **Transmission**: Each call goes to the `/api/v1` path on the backend with the bearer token attached by the transport; the ecosystem id and customer id appear in the query string or path. Authorization to read or change sets is the backend's decision; the client sends the token and relays a 403.
- **Retention**: None; nothing is cached between calls.

