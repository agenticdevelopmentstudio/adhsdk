---
id: 059c2877-d705-4ff4-b649-554fdafcfaaa
title: "Support Client"
type: ingredient
status: draft
language: en
summary: "Web client and React Query hooks for consented support access grants, the read-only viewer and the read log."
platforms:
  - typescript
  - web
tags:
  - data
  - support
  - api
depends-on:
  - 870c182f-1a80-4254-8fec-3eb35c8f13f7
  - 3ea9329e-5acc-4c43-b5ce-bb8c50570104
  - 150bf00e-6c6b-4f91-a323-d307ebd5700d
version: 1.1.1
created: 2026-11-23
modified: 2026-11-23
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
related: []
references: []
---
# Support Client

## Overview

This is the web client for consented support access. A person who built content in a product, or a hub user, can be looked at by support only after they approve it, for a length they were told, and every read is logged. The backend owns every rule: who may ask, how long a grant lasts, what the viewer may read, what the log records. This code builds requests, maps `snake_case` wire rows to `camelCase` rows, and wraps each call in a React Query hook.

The component is three files in `packages/web/packages/data/src/support/`, published as `@adh-sdk/data/support`: `wire.ts` (the wire types and mappers), `grants.ts` (the four clients, the rules the panes read and the hooks) and `index.ts` (the re-exports). It uses the shared /v1 conventions ([adhsdk.ingredient.data.services.auth.v1](cookbook:870c182f-1a80-4254-8fec-3eb35c8f13f7)) and the authentication client ([adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)); nothing here reads a token or a base URL itself. A product admin's calls name the product the way the product admin client does ([adhsdk.ingredient.adh.hub.product-admin.product-admin-client](cookbook:150bf00e-6c6b-4f91-a323-d307ebd5700d)), by ecosystem uuid.

Four clients, one for each kind of caller. Every path is a `/api/v1` path, the backend's path snake-cased. None takes a transport argument: each calls the shared `authedJson`, `authedRequest` and `listV1Page` imports, and the public client calls the shared token-free `publicJson` ([adhsdk.ingredient.data.services.auth.v1](cookbook:870c182f-1a80-4254-8fec-3eb35c8f13f7)).

| Client | Caller | Functions |
|---|---|---|
| `supportApi(side)` | a customer (`side` `customer`) or a hub user (`account`) | `grants`, `approve`, `deny`, `revoke`, `access` |
| `supportAdminApi` (an object) | a product admin on the product's admin site | `list`, `request`, `revoke`, `data`, `row` |
| `operatorSupportApi` (an object) | an operator on the operator admin site | `list`, `request`, `breakGlass`, `revoke`, `access` |
| `publicSupportApi` (an object) | a person following an emailed link, with no session | `get`, `deny`, `revoke`, `sendCode`, `approve` |

## Behavioral Requirements

### The person's own view

- **side-prefix**: `supportApi(side)` MUST send `customer` calls to `/api/v1/customer/support/...` and `account` calls to `/api/v1/account/support/...`, and MUST send nothing else differently between them.
- **grants-read**: `grants` MUST read every page of `.../grants` through `listAllV1`, which asks `limit=100` a page and follows `has_more` with `starting_after` (the backend keeps up to 200 grants and the gateway serves 100 a page, so one page is not all of them), and map each row of the list's `data` to `{ id, ecosystemId, granteeKind, granteeName, granteeRole, reason, consent, requestedFor, requestedAt, decision, decidedAt, expiresAt, revokedAt, status }`, `status` being the backend's own `pending`, `live`, `denied`, `lapsed`, `expired` or `revoked`. Timestamps are ISO strings on the wire already and are passed through, `null` when absent. `consent` is `customer` or `break_glass`, and a break-glass grant MUST keep that value so the pane can mark it. A missing `decision` maps to `null`, meaning undecided.
- **grant-state**: the module MUST export `grantState(grant, now = new Date())`. When the grant carries the backend's `status` it MUST return that status's state, whatever the client clock says: `pending` for `pending`, `live` for `live`, and `ended` for `denied`, `lapsed`, `expired` and `revoked`. Without a status it MUST work the state out at `now`, returning `ended` for any revoked grant, `pending` for an undecided grant that is not lapsed, `live` for an approved grant whose `expiresAt` is after `now`, and `ended` for every other grant (denied, expired, or undecided for `SUPPORT_LAPSE_DAYS` (seven) days or more, counted from `requestedAt`). An approved grant with no `expiresAt` is `ended`.
- **decide-and-revoke**: `approve`, `deny` and `revoke` MUST `POST` `.../grants/{id}/approve`, `.../deny` and `.../revoke`, with the id URL-encoded and no body, and return nothing.
- **access-read**: `access({ grantId, cursor })` (the argument is optional) MUST `GET` `.../access` with `grant_id` and `cursor` only when each is set and `limit=50`, and MUST map each row to `{ id, grantId, granteeName, route, path, method, at }` (`method` is `null` on a person's row) and return `{ items, nextCursor }`, where `nextCursor` is the last row's id when the list's `has_more` is true and `null` otherwise. The client MUST NOT page by itself.
- **access-grouping**: the module MUST export `groupAccess(rows)`, grouping rows by grant, table and calendar day in the viewer's time zone, and returning for each group `{ grantId, granteeName, schema, table, day, count, latestAt }`. The table comes from the row's `path` (its `/data/{schema}/{table}` segments, read by the exported `accessTable(row)`), not from the route. Groups are newest first by `latestAt`.
- **switch-off**: when the `grants` read is answered `404` (the `consented_access` switch is off) the client MUST rethrow the error unchanged. `isSupportOff(error)` MUST return true only for an error with HTTP status 404, and callers MUST apply it to the grants read alone, never to the viewer's paths, where a 404 means a refused table.

### A product admin

- **admin-list**: `supportAdminApi.list(ecosystemId)` MUST read every page of `/api/v1/support/grants?ecosystem=<uuid>` through `listAllV1`, as in **grants-read**, and map the rows as in **grants-read**, adding `targetId` and `targetName`.
- **admin-request**: `request(ecosystemId, { targetId, reason, hours })` MUST `POST` `{ target_id, reason, hours }` to the same path with the ecosystem, and return the new grant (with `targetId` and `targetName`). `hours` is optional. The client MUST NOT check the reason length or the hours; the pane does, with the exported `supportRequestProblem(req, maxHours)`, and the backend answers 422.
- **request-limits**: the module MUST export the limits the backend enforces, so a form can say so before it sends: `SUPPORT_REASON_MIN` (10), `SUPPORT_REASON_MAX` (500), `SUPPORT_HOURS_MAX` (168), `SUPPORT_BREAK_GLASS_HOURS_MAX` (4), `SUPPORT_ATTESTATION_MIN` (40) and `SUPPORT_HOURS_DEFAULT` (24). `supportRequestProblem` MUST return one sentence naming the first problem, counting the reason trimmed and requiring the hours to be a whole number from 1 to `maxHours`, and `null` when the request would pass.
- **admin-step-up**: `isStepUpRequired(error)` MUST return true for an error with status 403 whose `code`, or whose body's `error.code`, is `step_up_required`, and for nothing else. The client does not redirect; the caller does.
- **admin-revoke**: `revoke(ecosystemId, id)` MUST `POST` `/api/v1/support/grants/{id}/revoke?ecosystem=` and return nothing.
- **viewer-reads**: `data(id, schema, table, { cursor })` MUST `GET` `/api/v1/support/grants/{id}/data/{schema}/{table}` with `starting_after` set to the cursor only when set, and `limit=50`, and return `{ rows, nextCursor, hasMore }` (`nextCursor` the last row's `id` when `has_more` is true, else `null`; `hasMore` the list's `has_more`, so a caller can tell a table that ends from one whose last row has no `id` to page from); `row(id, schema, table, rowId)` MUST `GET` `.../{row_id}` and return one row. Every path segment MUST be URL-encoded. There MUST be no function that sends a write to these paths: `supportAdminApi` has exactly `data`, `list`, `request`, `revoke` and `row`.
- **content-tables**: the module MUST export `SUPPORT_CONTENT_TABLES`, the static list of 89 `schema.table` names the viewer offers, with a comment naming the `content` list of the backend's `src/db/rls-forms.json` as its source. A table the backend refuses with 404 is shown as unavailable by the caller; the list is not authority.

### An operator

- **operator-list**: `operatorSupportApi.list(filters)` MUST `GET` `/api/v1/system/support_grants` with `status`, `consent` and `cursor` only when each is set, and `limit=50`, and map rows as in **admin-list**, returning `{ items, nextCursor }` with the last grant's id as the cursor when `has_more` is true.
- **operator-request**: `request(body)` MUST `POST` `{ target_kind, target_id, ecosystem_id, reason, hours }` to `/api/v1/system/support_grants`. `ecosystem_id` and `hours` are omitted when not given: a customer's grant needs the ecosystem, a hub user's names none.
- **break-glass**: `breakGlass(body)` MUST `POST` the same body plus `attestation` and `attestation_ref` to `/api/v1/system/support_grants/break_glass`. The client MUST NOT validate the attestation; the pane checks at least 40 characters and the backend refuses a shorter one.
- **operator-revoke-access**: `revoke(id)` MUST `POST` `/api/v1/system/support_grants/{id}/revoke`, and `access({ grantId, cursor })` MUST `GET` `/api/v1/system/support_access` with `grant_id` always, `cursor` only when set, and `limit=50`, mapping rows with `granteeName` `null` and the actor's `method`.

### The emailed link

- **public-get**: `publicSupportApi.get(id, token)` MUST `GET` `/api/v1/public/support/grants/{id}?token=<token>` with no authorization header and return `{ grant, reads }`, the grant mapped as in **admin-list** and each read as in **access-read** (`method` `null`).
- **public-writes**: `deny` and `revoke` MUST `POST` `{ token }` to `.../grants/{id}/deny` and `.../revoke`. `sendCode(id, token)` MUST `POST` `{ token }` to `.../approve/code` and return `{ ok }`. `approve(id, token, code)` MUST `POST` `{ token, code }` to `.../approve`. `deny`, `revoke` and `approve` return the updated grant. A refusal MUST be thrown with its status. The token MUST NOT be stored by the client.

### Hooks

- **hook-names**: the module MUST export `useSupportGrants(side)`, `useSupportAccess(side, grantId?)` (an infinite query that follows `nextCursor`), `useDecideSupportGrant(side)` (a mutation taking `{ id, action }` with `action` one of `approve`, `deny` or `revoke`), `useAdminSupportGrants(ecosystemId)`, `useRequestSupportGrant(ecosystemId)`, `useRevokeAdminGrant(ecosystemId)`, `useSupportData(grantId, schema, table, cursor?)`, `useOperatorSupportGrants(filters)`, `useOperatorSupportAccess(filters)`, `useOperatorRequestGrant()`, `useOperatorRevokeGrant()`, `useBreakGlass()` and `usePublicSupportGrant(id, token)`. The grants key MUST be `["support", <side>, "grants"]` and the log key `["support", <side>, "access", <grantId or "">]` (exported as `SUPPORT_GRANTS_KEY` and `SUPPORT_ACCESS_KEY`); the product admin's keys MUST start `["support", "admin", <ecosystemId>]` (`SUPPORT_ADMIN_KEY`), with the list under `"grants"`, and the operator's `["support", "operator"]` (`SUPPORT_OPERATOR_KEY`), with the list at `["support", "operator", "grants", <status>, <consent>, <cursor>]` and the log at `["support", "operator", "access", <grantId>, <cursor>]`, an empty string for each absent value. The viewer's key is `["support", "admin", "data", grantId, schema, table, cursor]` and the emailed link's `["support", "public", id]`. `useSupportGrants` MUST NOT retry a 404, and `useSupportData` and `usePublicSupportGrant` MUST NOT retry at all.
- **hooks-keys**: every read hook except `useOperatorSupportGrants` MUST be disabled while a required value is empty, null or undefined (the side; the ecosystem; the grant, schema and table; the operator log's `grantId`; the link's id and token), and MUST read under a key that starts `["support", <side or role>, ...]`.
- **writes-invalidate**: on success the person's `useDecideSupportGrant` MUST invalidate the side's grants key and the prefix `["support", <side>, "access"]`; `useRequestSupportGrant` and `useRevokeAdminGrant` MUST invalidate the product admin's prefix for that ecosystem; and `useOperatorRequestGrant`, `useOperatorRevokeGrant` and `useBreakGlass` MUST invalidate the operator prefix. The viewer's key sits outside the ecosystem prefix, so a write does not invalidate it.
## Appearance

Not applicable: this is a data client with mappers, types and hooks, not a visual component.

## States

Not applicable: this is a data client with no visual states; its hooks expose React Query's own pending, error and success states and keep no state of their own.

## Accessibility

Not applicable: this is a data client with no user interface; the panes that consume it are a separate component.

## Conformance Test Vectors

Vectors are asserted in `packages/web/packages/data/src/support/__tests__/support.test.ts`, which stubs `authedJson`, `authedRequest` and `listV1Page` of `../../http` (and `fetch` for the public client). Vectors 012 to 015 concern the hooks and the caller, and that file does not assert them yet.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| support-client-001 | side-prefix, grants-read | `supportApi("customer").grants()` then the same for `account` | `listAllV1` of `/api/v1/customer/support/grants`, then of `/api/v1/account/support/grants`, so every page is read; rows are camel-cased |
| support-client-002 | decide-and-revoke | `approve`, `deny` and `revoke` of `"a/b"` on `account` | `POST` of `/api/v1/account/support/grants/a%2Fb/approve`, `.../deny`, `.../revoke`, no body |
| support-client-003 | access-read | `access({ grantId: "g1", cursor: "c1" })`, then `access()` | The first carries `grant_id=g1`, `cursor=c1` and `limit=50`; the second only `limit=50`; `nextCursor` is the last id when more remain, else `null` |
| support-client-004 | grant-state | With no `status`: an undecided grant, one undecided for seven days, an approved one expiring later, an approved one past `expiresAt`, a denied one, a revoked one | `pending`, `ended`, `live`, `ended`, `ended`, `ended` |
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
| support-client-019 | grant-state | Grants with each `status` (`pending`, `live`, `denied`, `lapsed`, `expired`, `revoked`), and a `live` one whose `expiresAt` the client clock has passed | `pending`, `live`, `ended`, `ended`, `ended`, `ended`, then `live` |
## Edge Cases

- **Switch off (MUST)**: the grants read is 404 while the backend's `consented_access` switch is off; the client rethrows, `useSupportGrants` stops retrying, and `isSupportOff` lets a caller hide its surface.
- **A clock that disagrees (MUST)**: a grant's `status` is worked out on the backend's clock, and `grantState` prefers it, so a client clock that runs fast never shows a live grant as ended and hides its Revoke.
- **A lapsed request (MUST)**: a request with no `status` that has been undecided for seven days or more is read as `ended` by `grantState`. The seven days are the exported constant `SUPPORT_LAPSE_DAYS`, which mirrors the backend's `support:lapsed` rule that a request not decided in seven days is treated as denied.
- **Empty and absent ids (MUST)**: the read hooks (all but `useOperatorSupportGrants`) are disabled and make no request.
- **A write that fails (MUST)**: a refusal is rethrown unchanged; nothing is invalidated, because each hook invalidates on success only.
- **A malformed path in the log (MUST)**: `accessTable` decodes each of the `{schema}` and `{table}` segments, and keeps a segment whose escapes are malformed as it was logged rather than throwing, so one odd row never stops the log from rendering.
- **A refused table (MUST)**: a 404 from the viewer path reaches the caller as the transport's error; the client does not fall back to another route, and `useSupportData` does not retry.
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `side` | `"customer"` or `"account"` | none, required | Picks the person's own routes. |
| `ecosystemId` | string | none, required for a product admin | The product's ecosystem uuid every product admin call names as `?ecosystem=<id>`. |
| `SUPPORT_CONTENT_TABLES` | list of strings | the backend's 89 content tables | The tables the viewer offers. |
| `SUPPORT_LAPSE_DAYS` | number | 7 | Days an undecided request stays `pending`. |
| `SUPPORT_PAGE_SIZE` | number | 50 | The `limit` of a log, viewer or operator-list page. |
| `SUPPORT_REASON_MIN`, `SUPPORT_REASON_MAX` | numbers | 10, 500 | The reason length the backend accepts. |
| `SUPPORT_HOURS_MAX`, `SUPPORT_BREAK_GLASS_HOURS_MAX`, `SUPPORT_HOURS_DEFAULT` | numbers | 168, 4, 24 | The longest consented grant, the longest break-glass grant, and the length a request form starts at. |
| `SUPPORT_ATTESTATION_MIN` | number | 40 | The shortest break-glass attestation. |
| Transport | static imports | `authedJson`, `authedRequest`, `httpStatus`, `listAllV1`, `listV1Page` and `withV1Query` from `../http`, `enc` from `../client-helpers`, and `publicJson` from `@adh-sdk/auth/client` | No client takes a transport argument. A test replaces the `../http` imports (`authedJson`, `authedRequest`, `listAllV1`, `listV1Page`) with stubs; the caller's environment supplies the token and base URL. The public client calls the shared `publicJson` with `cache: 'no-store'` and sends no authorization. |
## Deep Linking

Not applicable: this is a data client; it declares no URL scheme or route of its own, only the backend `/v1` paths it calls.

## Localization

Not applicable: the module defines no user-facing string; an error's message is the backend's, passed through untranslated.

## Accessibility Options

Not applicable: this is a data client with no visual output.

## Feature Flags

Not applicable: the module reads no flag. Whether consented access is on is the backend's `consented_access` switch, seen here as a 404 on the grants read.

## Analytics

Not applicable: the module emits no event.

## Privacy

- **Data collected**: None by this module. It carries grants (who asked, why, for how long), the read log (which route and when, never row contents) and, through the viewer, a customer's rows in transit between the backend and a product admin holding a live grant.
- **Storage**: None beyond React Query's in-memory cache. The viewer's rows MUST NOT be written to storage. The emailed-link token is never stored.
- **Transmission**: Each call goes to a `/v1` path with the bearer token attached by the transport, except the public client, whose token travels in the query string or body. Who may read is the backend's decision, taken in the database.
- **Retention**: None; the cache is the caller's.

## Logging

Not applicable: the module logs nothing; a failure surfaces only as a thrown error.

## Platform Notes

- **SwiftUI**: Port the wire types as `Codable` structs with `CodingKeys` and each client as an `async throws` service over `URLSession`; keep the viewer read-only by exposing no write method.
- **Compose**: Use `kotlinx.serialization` data classes with `@SerialName`, and a repository whose writes refresh the grants and log flows together.
- **React/Web**: The source platform: `packages/web/packages/data/src/support/`. `wire.ts` and `grants.ts` carry the `"use client"` directive, and `grants.ts` imports `@tanstack/react-query`; the package's `exports` map publishes the folder as `@adh-sdk/data/support`, with `types` at `./dist/support/index.d.ts`, `development` at `./src/support/index.ts` and `import` at `./dist/support/index.js`. Every exported hook states its React Query result type (`UseQueryResult`, `UseInfiniteQueryResult` or `UseMutationResult`), so a write hook resolves to what its client returns rather than `unknown`, and `supportApi(side)` returns the exported `SupportApi` interface.
- **AppKit / UIKit**: The same Foundation approach as SwiftUI.
- **WinUI 3**: One shared `HttpClient` with a bearer handler, and `System.Text.Json` with `[JsonPropertyName]` on records.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/data/src/support/` | confirmed (1.1.1) |

## Design Decisions

**Decision**: One module with four clients, one for each caller, instead of one client with many optional arguments.
**Rationale**: Each caller reaches different routes with different rights; separate clients make a pane's reach visible in its imports.
**Approved**: pending

**Decision**: The viewer client has no write function.
**Rationale**: The support access design gives a grant read-only reach with no write route behind it; leaving the function out keeps a pane from offering one.
**Approved**: pending

**Decision**: The client never redirects for step-up; it only recognises the refusal.
**Rationale**: The redirect belongs to the sign-in provider, which owns navigation; the data layer stays free of it.
**Approved**: pending

**Decision**: Wire types are written by hand in this package, as the other clients here are.
**Rationale**: Every client in this package follows the sets client, keeping the generated API types out of the panes.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |

The module is written, in `wire.ts`, `grants.ts` and `index.ts`. Both checks stay partial. Separation of concerns: the wire types and mappers are apart in `wire.ts`, but `grants.ts` holds the four clients, the rules the panes read and every hook in one file. Unit-test coverage: `__tests__/support.test.ts` covers every client's paths and bodies, `grantState`, `groupAccess`, `isSupportOff`, `isStepUpRequired`, `SUPPORT_CONTENT_TABLES` and `supportRequestProblem`; no hook is tested, so the hook requirements (**hook-names**, **hooks-keys**, **writes-invalidate**) are unasserted.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-11-23 | Mike Fullerton | The public reads use the shared token-free publicJson from the Auth v1 Wire Conventions; behaviour unchanged. |
| 1.1.0 | 2026-11-23 | Mike Fullerton | Matches the code: real file names, /api/v1 snake-cased paths, has_more paging, request limits, full hook keys, and the operator and emailed-link calls |
| 1.0.0 | | | Initial creation |
