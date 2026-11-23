---
id: 059c2877-d705-4ff4-b649-554fdafcfaaa
title: "Support Client"
type: ingredient
status: draft
language: en
summary: "Web client for consented support access: the customer's and hub user's grants and read log, a product admin's grant requests and read-only data viewer, the operator's grants, break-glass and read log, and the emailed-link page's calls, with their React Query hooks."
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
version: 1.0.0
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

This is the web client for consented support access (phase 7). A person who built content in a product, or a hub user, can be looked at by support only after they approve it, for a length they were told, and every read is logged. The backend owns every rule: who may ask, how long a grant lasts, what the viewer may read, what the log records. This code builds requests, maps `snake_case` wire rows to `camelCase` rows, and wraps each call in a React Query hook.

The component is three files in `packages/web/packages/data/src/support/`, published as `@adh-sdk/data/support`: `wire.ts` (the wire types and mappers), `support.ts` (the four clients and their hooks) and `index.ts` (the re-exports). It uses the shared /v1 conventions ([adhsdk.ingredient.data.services.auth.v1](cookbook:870c182f-1a80-4254-8fec-3eb35c8f13f7)) and the authentication client ([adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)); nothing here reads a token or a base URL itself. A product admin's calls name the product the way the product admin client does ([adhsdk.ingredient.adh.hub.product-admin.product-admin-client](cookbook:150bf00e-6c6b-4f91-a323-d307ebd5700d)), by ecosystem uuid.

Four clients, one for each kind of caller. Every path is a `/v1` path.

| Client | Caller | Functions |
|---|---|---|
| `supportApi(http, side)` | a customer (`side` `customer`) or a hub user (`account`) | `grants`, `approve`, `deny`, `revoke`, `access` |
| `supportAdminApi(http)` | a product admin on the product's admin site | `list`, `request`, `revoke`, `data`, `row` |
| `operatorSupportApi(http)` | an operator on the operator admin site | `list`, `request`, `breakGlass`, `revoke`, `access` |
| `publicSupportApi(http)` | a person following an emailed link, with no session | `get`, `deny`, `revoke`, `sendCode`, `approve` |

## Behavioral Requirements

### The person's own view

- **side-prefix**: `supportApi` MUST send `customer` calls to `/v1/customer/support/...` and `account` calls to `/v1/account/support/...`, and MUST send nothing else differently between them.
- **grants-read**: `grants` MUST `GET` `.../grants` and map each row to `{ id, ecosystemId, granteeKind, granteeName, granteeRole, reason, consent, requestedFor, requestedAt, decision, decidedAt, expiresAt, revokedAt }`, with every timestamp as an ISO string or `null`. `consent` is `customer` or `break_glass`, and a break-glass grant MUST keep that value so the pane can mark it. A missing `decision` maps to `null`, meaning undecided.
- **grant-state**: the module MUST export `grantState(grant, now)`, returning `pending` for an undecided grant that is not lapsed, `live` for an approved, unrevoked grant whose `expiresAt` is after `now`, and `ended` for every other grant (denied, revoked, expired, or lapsed after seven days undecided).
- **decide-and-revoke**: `approve`, `deny` and `revoke` MUST `POST` `.../grants/{id}/approve`, `.../deny` and `.../revoke`, with the id URL-encoded and no body, and return nothing.
- **access-read**: `access({ grantId, cursor })` MUST `GET` `.../access`, with `grant` and `cursor` only when each is set, and MUST map each row to `{ id, grantId, granteeName, route, path, method, at }` with a `nextCursor` (`null` on the last page). The client MUST NOT page by itself.
- **access-grouping**: the module MUST export `groupAccess(rows)`, grouping rows by grant, table (the route's table name) and calendar day in the viewer's time zone, and returning for each group its count and latest time. Groups are newest first.
- **switch-off**: when `grants` is answered `404` (the `consented_access` switch is off) the client MUST rethrow the error unchanged, and `isSupportOff(error)` MUST return true only for an error whose HTTP status is 404.

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

- **hooks-keys**: every read hook MUST be disabled while a required id is empty, null or undefined, and MUST read under a key that starts `["support", <side or role>, ...]`.
- **writes-invalidate**: the `approve`, `deny`, `revoke` and `request` hooks MUST, on success, invalidate the grant list and the access log of that side.

## Appearance

Not applicable: this is a data client with mappers, types and hooks, not a visual component.

## States

Not applicable: this is a data client with no visual states; its hooks expose React Query's own pending, error and success states and keep no state of their own.

## Accessibility

Not applicable: this is a data client with no user interface; the panes that consume it are a separate component.

## Conformance Test Vectors

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

## Edge Cases

- **Switch off (MUST)**: the grants read is 404 while the backend's `consented_access` switch is off; the client rethrows and `isSupportOff` lets a caller hide its surface.
- **A lapsed request (MUST)**: a request undecided for seven days is read as `ended` by `grantState`, whatever the backend has recorded yet.
- **Empty and absent ids (MUST)**: the read hooks are disabled and make no request.
- **A write that fails (MUST)**: a refusal is rethrown unchanged; nothing is invalidated.
- **A refused table (MUST)**: a 404 from the viewer path reaches the caller as the transport's error; the client does not fall back to another route.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `side` | `"customer"` or `"account"` | none, required | Picks the person's own routes. |
| `ecosystemId` | string | none, required for a product admin | The product's ecosystem uuid every product admin call names as `?ecosystem=<id>`. |
| `SUPPORT_CONTENT_TABLES` | list of strings | the backend's content list | The tables the viewer offers. |
| Transport | injected module imports | `authedJson`, `authedRequest`, `httpStatus`, `unixToIso`, `withV1Query` from `../http`, and `enc` from `../client-helpers` | The caller's environment supplies the token and base URL. The public client sends none. |

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
- **React/Web**: The source platform: `packages/web/packages/data/src/support/`. The files carry the `"use client"` directive and import `@tanstack/react-query`; the package's `exports` map publishes the folder as `@adh-sdk/data/support`.
- **AppKit / UIKit**: The same Foundation approach as SwiftUI.
- **WinUI 3**: One shared `HttpClient` with a bearer handler, and `System.Text.Json` with `[JsonPropertyName]` on records.

## Design Decisions

**Decision**: One module with four clients, one for each caller, instead of one client with many optional arguments.
**Rationale**: Each caller reaches different routes with different rights; separate clients make a pane's reach visible in its imports.
**Approved**: pending

**Decision**: The viewer client has no write function.
**Rationale**: The phase 7 design gives a grant read-only reach with no write route behind it; leaving the function out keeps a pane from offering one.
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

The module is not written yet, so both checks are partial until the code lands and the recipe is confirmed against it.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | | | Initial creation |
