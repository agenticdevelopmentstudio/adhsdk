
### The person's own view

- **side-prefix**: `supportApi` MUST send `customer` calls to `/v1/customer/support/...` and `account` calls to `/v1/account/support/...`, and MUST send nothing else differently between them.
- **grants-read**: `grants` MUST `GET` `.../grants` and map each row to `{ id, ecosystemId, granteeKind, granteeName, granteeRole, reason, consent, requestedFor, requestedAt, decision, decidedAt, expiresAt, revokedAt }`, with every timestamp as an ISO string or `null`. `consent` is `customer` or `break_glass`, and a break-glass grant MUST keep that value so the pane can mark it. A missing `decision` maps to `null`, meaning undecided.
- **grant-state**: the module MUST export `grantState(grant, now)`, returning `pending` for an undecided grant that is not lapsed, `live` for an approved, unrevoked grant whose `expiresAt` is after `now`, and `ended` for every other grant (denied, revoked, expired, or lapsed after seven days undecided).
- **decide-and-revoke**: `approve`, `deny` and `revoke` MUST `POST` `.../grants/{id}/approve`, `.../deny` and `.../revoke`, with the id URL-encoded and no body, and return nothing.
- **access-read**: `access({ grantId, cursor })` MUST `GET` `.../access`, with `grant` and `cursor` only when each is set, and MUST map each row to `{ id, grantId, granteeName, route, path, method, at }` with a `nextCursor` (`null` on the last page). The client MUST NOT page by itself.
- **access-grouping**: the module MUST export `groupAccess(rows)`, grouping rows by grant, table (the route's table name) and calendar day in the viewer's time zone, and returning for each group its count and latest time. Groups are newest first.
- **switch-off**: when the `grants` read is answered `404` (the `consented_access` switch is off) the client MUST rethrow the error unchanged. `isSupportOff(error)` MUST return true only for an error with HTTP status 404, and callers MUST apply it to the grants read alone, never to the viewer's paths, where a 404 means a refused table.

### A product admin

- **admin-list**: `supportAdminApi.list(ecosystemId)` MUST `GET` `/v1/support/grants?ecosystem=<uuid>` and map the rows as in **grants-read**, adding `targetId` and `targetName`.
- **admin-request**: `request(ecosystemId, { targetId, reason, hours })` MUST `POST` `{ target_id, reason, hours }` to the same path with the ecosystem, and return the new grant. The client MUST NOT check the reason length or the hours; the pane does, and the backend answers 422.
- **admin-step-up**: `isStepUpRequired(error)` MUST return true for an error with status 403 and the code `step_up_required`, and for nothing else. The client does not redirect; the caller does.
- **admin-revoke**: `revoke(ecosystemId, id)` MUST `POST` `/v1/support/grants/{id}/revoke?ecosystem=`.
- **viewer-reads**: `data(id, schema, table, { cursor })` MUST `GET` `/v1/support/grants/{id}/data/{schema}/{table}` with `cursor` only when set, and return `{ rows, nextCursor }`; `row(id, schema, table, rowId)` MUST `GET` `.../{rowId}` and return one row. Every path segment MUST be URL-encoded. There MUST be no function that sends a write to these paths.
- **content-tables**: the module MUST export `SUPPORT_CONTENT_TABLES`, the static list of `schema.table` names the viewer offers, with a comment naming the backend's `rls-forms.json` as its source. A table the backend refuses with 404 is shown as unavailable by the caller; the list is not authority.

### An operator

- **operator-list**: `operatorSupportApi.list(filters)` MUST `GET` `/v1/system/support-grants` with `ecosystem`, `state`, `grantee` and `cursor` only when each is set, and map rows as in **admin-list**.
- **operator-request**: `request(body)` MUST `POST` `{ ecosystem_id, target_id, target_kind, reason, hours }` to `/v1/system/support-grants`.
- **break-glass**: `breakGlass(body)` MUST `POST` `{ ecosystem_id, target_id, target_kind, reason, attestation, attestation_ref, hours }` to `/v1/system/support-grants/break-glass`. The client MUST NOT validate the attestation; the pane checks at least 40 characters and the backend refuses a shorter one.
- **operator-revoke-access**: `revoke(id)` MUST `POST` `/v1/system/support-grants/{id}/revoke`, and `access(filters)` MUST `GET` `/v1/system/support-access` with `grant`, `from`, `to` and `cursor` only when each is set.

### The emailed link

- **public-get**: `publicSupportApi.get(id, token)` MUST `GET` `/v1/public/support/{id}?token=<token>` with no authorization header and map the grant and its log as in **grants-read** and **access-read**.
- **public-writes**: `deny` and `revoke` MUST `POST` the id and token alone. `sendCode(id, token)` MUST `POST` `.../code`. `approve(id, token, code)` MUST `POST` `{ token, code }` to `.../approve`. The token MUST NOT be stored by the client.

### Hooks

- **hook-names**: the module MUST export `useSupportGrants(side)`, `useSupportAccess(side, grantId?)`, `useDecideSupportGrant(side)` (approve, deny and revoke), `useAdminSupportGrants(ecosystemId)`, `useRequestSupportGrant(ecosystemId)`, `useRevokeAdminGrant(ecosystemId)`, `useSupportData(grantId, schema, table, cursor?)`, `useOperatorSupportGrants(filters)`, `useOperatorSupportAccess(filters)`, `useBreakGlass()` and `usePublicSupportGrant(id, token)`. The grants key MUST be `["support", <side>, "grants"]` and the log key `["support", <side>, "access", <grantId or "">]`; the product admin's keys MUST start `["support", "admin", <ecosystemId>]` and the operator's `["support", "operator"]`.
- **hooks-keys**: every read hook MUST be disabled while a required id is empty, null or undefined, and MUST read under a key that starts `["support", <side or role>, ...]`.
- **writes-invalidate**: the `approve`, `deny`, `revoke` and `request` hooks MUST, on success, invalidate the grant list and the access log under the key prefix of the caller that made the write (the side's, the product admin's for that ecosystem, or the operator's). `useBreakGlass` MUST invalidate the operator prefix.

