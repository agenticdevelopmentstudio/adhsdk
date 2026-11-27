
Vectors marked with a test name are asserted in `packages/web/packages/data/src/product-admin/__tests__/product-admin.test.ts`, which stubs the transport. The others follow from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| product-admin-client-001 | totals-read | `fetchProductTotals("eco-1")` with a body carrying `storage_bytes: 2048`, `pending_invitations: 3`, `pending_requests: 1` (test: "GETs the totals with the uuid and camel-cases the body") | A `GET` of `/api/v1/product_admin/totals?ecosystem=eco-1`; the result has `storageBytes` 2048, `pendingInvitations` 3, `pendingRequests` 1 |
| product-admin-client-002 | customers-page, customer-row-mapping | `customers("eco-1", { q: "ann", cursor: "c1" })` over a page whose last row has a null email and an empty avatar URL (test: "lists one roster page with q and cursor and maps each row") | The `GET` carries `ecosystem`, `q=ann` and `cursor=c1`; rows are camel-cased with the created time as ISO; the null email stays `null` and the empty avatar becomes `null`; `nextCursor` is the body's |
| product-admin-client-003 | customers-page | `customers("eco-1")` and `customers("eco-1", { q: "", cursor: "" })` (test: "leaves q and cursor off when they are empty") | Neither request carries `q` or `cursor` |
| product-admin-client-004 | pause | `pause("eco-1", "u1", "spam")`, then `pause("eco-1", "u1")` (test: "pauses with POST and the reason") | Both `POST` `/api/v1/product_admin/customers/u1/pause?ecosystem=eco-1`, with body `{"reason":"spam"}` then `{}` |
| product-admin-client-005 | pause | `unpause("eco-1", "u1")` (test: "lifts a pause with DELETE") | A `DELETE` of the same path |
| product-admin-client-006 | quota | `setQuota("eco-1", "u1", 1073741824)` answered `{ quota_bytes: 1073741824 }` (test: "sets the quota with POST (the backend's PUT) and reads quota_bytes back") | A `POST` of `.../u1/quota?ecosystem=eco-1` with `{"bytes":1073741824}`; the result is `{ quotaBytes: 1073741824 }` |
| product-admin-client-007 | delete-customer, customer-id-encoded | `deleteCustomer("eco-1", "u1")` (test: "deletes a customer with DELETE"), and the id `a/b` | A `DELETE` of `.../customers/u1?ecosystem=eco-1`; the second id appears as `a%2Fb` |
| product-admin-client-008 | admin-seat-protected | A 422 error whose body is `{ error: { code: "admin_seat_protected" } }`, then a 422 with another code, then a 403 carrying that code (test: "recognizes the 422 admin_seat_protected body" and "refuses any other error") | True, false, false |
| product-admin-client-011 | roster-writes-invalidate | Any roster write succeeding for "eco-1" | The roster queries and the totals query of "eco-1" are invalidated |
| product-admin-client-012 | totals-hook, customers-hook | Each read hook given `null`, `undefined` or `""` | No request is made |
| product-admin-client-013 | quota | The constant `DEFAULT_QUOTA_BYTES` (test: "is the backend's 5 GiB") | 5368709120 |
| product-admin-client-014 | totals-jobs | `fetchProductTotals("eco-1")` over a body with `jobs_by_status: { failed: 2, done: 9 }`, then over one without it | `jobsByStatus` is `{ failed: 2, done: 9 }`, then `{}` |
