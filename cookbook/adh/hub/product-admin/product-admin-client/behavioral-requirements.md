
### Totals

- **totals-read**: `fetchProductTotals` MUST `GET` `/api/v1/product_admin/totals?ecosystem=<uuid>` and map the body to `customers`, `new7d`, `new30d`, `active7d`, `active30d`, `storageBytes` (from `storage_bytes`), `pendingInvitations` (from `pending_invitations`) and `pendingRequests` (from `pending_requests`). The totals are counts only and carry no per-customer row.
- **totals-jobs**: the totals body MAY carry `jobs_by_status`, a map of job status to count, which `fetchProductTotals` MUST map to `jobsByStatus` (`Record<string, number>`), and MUST map to an empty object when the body has none. The client MUST NOT sum or filter it.
- **totals-hook**: `useProductTotals` MUST be disabled while the ecosystem id is empty, null or undefined, and MUST otherwise read under the query key `["product-admin", <id>, "totals"]`.

### Roster

- **customer-row-mapping**: each roster row MUST map `display_name` to `displayName`, `avatar_url` to `avatarUrl`, `external_id` to `externalId`, `last_active_day` to `lastActiveDay`, `storage_bytes` to `storageBytes`, `quota_bytes` to `quotaBytes` and the epoch-seconds `created` to an ISO timestamp `createdAt`. A missing email, display name, external id or last-active day MUST map to `null`, an empty avatar URL MUST map to `null`, and a missing `roles` or `sets` list MUST map to an empty list. `paused` is passed through. `sets` is the ids of the sets granted and not revoked, and `roles` the product roles held product-wide, each `{ id, slug, name }`.
- **customers-page**: `productAdminApi.customers` MUST `GET` `/api/v1/product_admin/customers` with the ecosystem, and with `q` and `cursor` only when each is non-empty, and MUST return the mapped `items` (an empty list when the body has none) and `nextCursor` (`null` on the last page). A page is 50 rows, newest first, as the backend decides; `q` filters email and name. The client MUST NOT page by itself: the caller passes `nextCursor` back as `cursor`.
- **customers-hook**: `useProductCustomers` MUST be disabled while there is no ecosystem id, and MUST read under the key `["product-admin", <id>, "customers", <q>, <cursor>]`, with an empty string for each absent value.
- **pause**: `pause` MUST `POST` `/api/v1/product_admin/customers/{id}/pause?ecosystem=` with `{ reason }` when a reason is given and `{}` otherwise, and return `{ paused }` from the body. `unpause` MUST `DELETE` the same path.
- **quota**: `setQuota` MUST `POST` `/api/v1/product_admin/customers/{id}/quota?ecosystem=` with `{ bytes }` and return `{ quotaBytes }` from the body's `quota_bytes`. The client MUST NOT check the value against `DEFAULT_QUOTA_BYTES`; the backend answers 403 above it.
- **delete-customer**: `deleteCustomer` MUST `DELETE` `/api/v1/product_admin/customers/{id}?ecosystem=`. The backend tombstones the customer and answers 409 while they still own data.
- **customer-id-encoded**: the customer id MUST be URL-encoded into the path.
- **roster-writes-invalidate**: every roster write hook (`usePauseCustomer`, `useUnpauseCustomer`, `useSetCustomerQuota`, `useDeleteCustomer`) MUST, on success, invalidate both the roster queries and the totals query of that ecosystem, because they count the same people.
- **admin-seat-protected**: `isAdminSeatProtected` MUST return true only for an error whose HTTP status is 422 and whose `code`, or whose body's `error.code`, is `admin_seat_protected` (the backend's refusal to pause or delete yourself or another holder of `admin`), and MUST return false for any other error.

### Admin site

- **admin-site-read**: `adminSiteApi.get` MUST `GET` `/api/v1/admin_site?ecosystem=<uuid>` and map the body to `{ site, enabled, contentGated }`. `enabled` is whether the `product_admin_site` switch is on, coerced to a boolean. `contentGated` is the body's `content_gated` (content enforcement is on, so the hub reads only the product's house rows), coerced to a boolean; a body without it, from a backend that predates it, MUST read as `false`, not gated. `site` is `null` when the product has none, else `{ id, host, applicationId, clientId, createdAt, updatedAt }` from `host`, `application_id`, `client_id` and the epoch-seconds `created` and `updated`.
- **admin-site-put**: `adminSiteApi.put` MUST `POST` `{ host }` to the same path, which sets the site up or moves it, and return the new state. The backend answers 409 when the product already has its own `admin-site` application or another product's site uses the host; the error is left for the caller to show.
- **admin-site-remove**: `adminSiteApi.remove` MUST `DELETE` the same path and return nothing.
- **admin-site-hooks**: `useAdminSite` MUST be disabled while there is no ecosystem id and read under the key `["product-admin", <id>, "admin-site"]`. `usePutAdminSite` MUST, on success, write the returned state straight into that cache entry. `useRemoveAdminSite` MUST, on success, invalidate it.

