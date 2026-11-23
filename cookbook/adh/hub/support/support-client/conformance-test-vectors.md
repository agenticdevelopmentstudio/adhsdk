
Vectors are to be asserted in `packages/web/packages/data/src/support/__tests__/support.test.ts`, which stubs the transport.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| support-client-001 | side-prefix, grants-read | `supportApi(http, "customer").grants()` then the same for `account` | A `GET` of `/v1/customer/support/grants`, then `/v1/account/support/grants`; rows are camel-cased with ISO times |
| support-client-002 | decide-and-revoke | `approve("g/1")`, `deny("g1")`, `revoke("g1")` on `customer` | `POST` of `.../grants/g%2F1/approve`, `.../g1/deny`, `.../g1/revoke`, no body |
| support-client-003 | access-read | `access({ grantId: "g1", cursor: "c1" })`, then `access({})` | The first carries `grant=g1` and `cursor=c1`; the second carries neither |
| support-client-004 | grant-state | An undecided grant, an approved one expiring later, an approved one past `expiresAt`, a revoked one, a denied one | `pending`, `live`, `ended`, `ended`, `ended` |
| support-client-005 | access-grouping | Four rows on one grant and one table, two on Tuesday and two on Wednesday | Two groups, Wednesday first, each with count 2 |
| support-client-006 | admin-list, admin-request | `list("eco-1")`, `request("eco-1", { targetId: "u1", reason: "Fix a sync", hours: 24 })` | A `GET` of `/v1/support/grants?ecosystem=eco-1`; a `POST` with `{"target_id":"u1","reason":"Fix a sync","hours":24}` |
| support-client-007 | admin-step-up | A 403 with code `step_up_required`, then a 403 with another code | True, false |
| support-client-008 | viewer-reads | `data("g1", "content", "notes", { cursor: "c1" })`, `row("g1", "content", "notes", "r1")` | `GET` of `/v1/support/grants/g1/data/content/notes?cursor=c1` and `.../notes/r1`; the module exports no write function for these paths |
| support-client-009 | break-glass | `breakGlass({...})` | A `POST` of `/v1/system/support-grants/break-glass` with `attestation` and `attestation_ref` in the body |
| support-client-010 | public-get, public-writes | `get("g1", "t")`, `approve("g1", "t", "123456")` | A `GET` of `/v1/public/support/g1?token=t` with no authorization; a `POST` with `{"token":"t","code":"123456"}` |
| support-client-011 | switch-off | `grants()` answered 404 | The error is rethrown; `isSupportOff` is true |
| support-client-012 | hooks-keys | Each read hook given `null`, `undefined` or `""` | No request is made |
| support-client-013 | writes-invalidate | `approve` succeeding | The grant list and access log queries of that side are invalidated |

