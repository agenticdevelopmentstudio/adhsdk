
Vectors are asserted in `packages/web/packages/data/src/support/__tests__/support.test.ts`, which stubs `authedJson`, `authedRequest` and `listV1Page` of `../../http` (and `fetch` for the public client). Vectors 012 to 015 concern the hooks and the caller, and that file does not assert them yet.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| support-client-001 | side-prefix, grants-read | `supportApi("customer").grants()` then the same for `account` | A `GET` of `/api/v1/customer/support/grants` with `limit=100`, then `/api/v1/account/support/grants`; rows are camel-cased |
| support-client-002 | decide-and-revoke | `approve`, `deny` and `revoke` of `"a/b"` on `account` | `POST` of `/api/v1/account/support/grants/a%2Fb/approve`, `.../deny`, `.../revoke`, no body |
| support-client-003 | access-read | `access({ grantId: "g1", cursor: "c1" })`, then `access()` | The first carries `grant_id=g1`, `cursor=c1` and `limit=50`; the second only `limit=50`; `nextCursor` is the last id when more remain, else `null` |
| support-client-004 | grant-state | An undecided grant, one undecided for seven days, an approved one expiring later, an approved one past `expiresAt`, a denied one, a revoked one | `pending`, `ended`, `live`, `ended`, `ended`, `ended` |
| support-client-005 | access-grouping | Three reads of one table on one day and one read of another table the next day | Two groups, the later day first; the first has count 1, the second count 3 and the latest time |
| support-client-006 | admin-list, admin-request | `list("eco-1")`, `request("eco-1", { targetId: "u1", reason: "Fix a sync", hours: 24 })` | A `GET` of `/api/v1/support/grants` with `ecosystem=eco-1`; a `POST` to that path and ecosystem with `{"target_id":"u1","reason":"Fix a sync","hours":24}` |
| support-client-007 | admin-step-up | A 403 with code `step_up_required` (on the error, then in its body), a 403 with another code, a 401 with that code | True, true, false, false |
| support-client-008 | viewer-reads | `data("g1", "content", "notes", { cursor: "c1" })`, `row("g1", "content", "notes", "r1")` | `GET` of `/api/v1/support/grants/g1/data/content/notes` with `starting_after=c1` and `limit=50`, and `.../notes/r1`; `supportAdminApi` has no function that writes to these paths |
| support-client-009 | break-glass | `breakGlass({...})` | A `POST` of `/api/v1/system/support_grants/break_glass` with `target_kind`, `target_id`, `ecosystem_id`, `reason`, `hours`, `attestation` and `attestation_ref` in the body |
| support-client-010 | public-get, public-writes | `get("g1", "t")`, `sendCode("g1", "t")`, `approve("g1", "t", "123456")` | A `GET` of `/api/v1/public/support/grants/g1?token=t` with no authorization; a `POST` to `.../approve/code`; a `POST` of `{"token":"t","code":"123456"}` to `.../approve` |
| support-client-011 | switch-off | `grants()` answered 404, and an error with status 403 | The error is rethrown; `isSupportOff` is true, then false |
| support-client-012 | hooks-keys | Each read hook given `null`, `undefined` or `""` | No request is made |
| support-client-013 | writes-invalidate | `approve` succeeding | The grant list and access log queries of that side are invalidated |
| support-client-014 | switch-off | A viewer path answered 404, then the grants read answered 404 | The caller applies `isSupportOff` to the second only |
| support-client-015 | hook-names | The exports of the module | Every hook of **hook-names** is exported with its key prefix |
| support-client-016 | content-tables | `SUPPORT_CONTENT_TABLES` | 89 distinct `schema.table` names, including `content.notes` |
| support-client-017 | request-limits | `supportRequestProblem` for reasons of 9, 10, 500 and 501 characters and hours 0, 1, 168, 169 and 1.5 | A sentence for each refused case and `null` for the rest; with a maximum of 4 hours, 5 is refused |
| support-client-018 | operator-list, operator-request, operator-revoke-access | `list({ status: "live", consent: "break_glass", cursor: "g0" })`, `request`, `revoke("g1")`, `access({ grantId })` | `GET` of `/api/v1/system/support_grants` with those filters and `limit=50`; a `POST` there with `target_kind`, `target_id`, `reason`; a `POST` of `.../g1/revoke`; a `GET` of `/api/v1/system/support_access` with `grant_id` and `limit=50` |
