---
id: 150bf00e-6c6b-4f91-a323-d307ebd5700d
title: "Product Admin Client"
type: ingredient
status: review
language: en
summary: "Web client for a product's admin site: totals, the customer roster and its pause, quota and delete writes, and the admin site registration, with their React Query hooks."
platforms:
  - typescript
  - web
tags:
  - data
  - product-admin
  - api
depends-on:
  - 870c182f-1a80-4254-8fec-3eb35c8f13f7
  - 3ea9329e-5acc-4c43-b5ce-bb8c50570104
version: 1.1.0
created: 2026-11-23
modified: 2026-11-23
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
related: []
references: []
---
# Product Admin Client

## Overview

This is the web client for a product's admin site (phase 6). A product is an ecosystem; its admin site is a separate host where the product's own admins, signed in with the product's customer login, read the product's totals and roster and pause, re-quota or delete a customer. The hub's managers use the same client to set that site up and to read the totals. The backend owns every rule; this code builds requests, maps `snake_case` wire rows to `camelCase` rows, and wraps each call in a React Query hook.

The component is four files in `packages/web/packages/data/src/product-admin/`, published as `@adh-sdk/data/product-admin`. `product-totals.ts` reads a product's counts. `product-customers.ts` reads and changes the roster. `admin-site.ts` reads, sets up, moves and takes down the site. `index.ts` re-exports all three and declares `DEFAULT_QUOTA_BYTES`, the most storage a product admin may give one customer: 5 GiB (5,368,709,120 bytes), mirroring the backend's own default. Every request goes through `authedJson` or `authedRequest`, with query strings built by `withV1Query`, from the shared /v1 conventions ([adhsdk.ingredient.data.services.auth.v1](cookbook:870c182f-1a80-4254-8fec-3eb35c8f13f7)) and the authentication client ([adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)); nothing here reads a token or a base URL itself.

Every call carries the product's ecosystem uuid in an `ecosystem` query parameter, never an rdid, because the backend compares it exactly.

| Route | Verb | Client function |
|---|---|---|
| `/api/v1/product_admin/totals` | GET | `fetchProductTotals`, `useProductTotals` |
| `/api/v1/product_admin/customers` | GET | `productAdminApi.customers`, `useProductCustomers` |
| `/api/v1/product_admin/customers/{id}` | DELETE | `productAdminApi.deleteCustomer`, `useDeleteCustomer` |
| `/api/v1/product_admin/customers/{id}/pause` | POST, DELETE | `productAdminApi.pause` and `unpause`, `usePauseCustomer` and `useUnpauseCustomer` |
| `/api/v1/product_admin/customers/{id}/quota` | POST | `productAdminApi.setQuota`, `useSetCustomerQuota` |
| `/api/v1/admin_site` | GET, POST, DELETE | `adminSiteApi.get`, `put` and `remove`, with `useAdminSite`, `usePutAdminSite` and `useRemoveAdminSite` |

## Behavioral Requirements

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
- **admin-site-hooks**: `useAdminSite` MUST be disabled while there is no ecosystem id and read under the key `["product-admin", <id>, "admin-site"]`. It MUST NOT retry a 404, which an ecosystem with no admin site answers every time; any other failure is retried once, as the provider's default does. `usePutAdminSite` MUST, on success, write the returned state straight into that cache entry. `useRemoveAdminSite` MUST, on success, invalidate it.

## Appearance

Not applicable: this is a data client with mappers, types and hooks, not a visual component.

## States

Not applicable: this is a data client with no visual states; its hooks expose React Query's own pending, error and success states and keep no state of their own.

## Accessibility

Not applicable: this is a data client with no user interface; the panes that consume it are separate components.

## Conformance Test Vectors

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
| product-admin-client-009 | admin-site-read | `get("eco-1")` over a body with a site and `enabled: true`, then over `{ site: null, enabled: false }` (tests: "reads the site and the switch", "reads no site") | The first maps the site's fields camel-cased; the second is `{ site: null, enabled: false, contentGated: false }`, a body without `content_gated` reading as not gated |
| product-admin-client-010 | admin-site-put, admin-site-remove | `put("eco-1", "admin.example.com")`, then `remove("eco-1")` (tests: "sets the site up with POST and the host", "takes the site down with DELETE") | A `POST` of `/api/v1/admin_site?ecosystem=eco-1` with `{"host":"admin.example.com"}`; then a `DELETE` of the same path |
| product-admin-client-011 | roster-writes-invalidate | Any roster write succeeding for "eco-1" | The roster queries and the totals query of "eco-1" are invalidated |
| product-admin-client-012 | totals-hook, customers-hook, admin-site-hooks | Each read hook given `null`, `undefined` or `""` | No request is made |
| product-admin-client-013 | quota | The constant `DEFAULT_QUOTA_BYTES` (test: "is the backend's 5 GiB") | 5368709120 |
| product-admin-client-014 | totals-jobs | `fetchProductTotals("eco-1")` over a body with `jobs_by_status: { failed: 2, done: 9 }`, then over one without it | `jobsByStatus` is `{ failed: 2, done: 9 }`, then `{}` |
| product-admin-client-015 | admin-site-read | `get("eco-1")` over a body with `content_gated: true`, then over one without the field (tests: "reads content enforcement as contentGated (phase 7)", "reads a backend without content_gated as not gated") | `contentGated` is `true`, then `false` |
## Edge Cases

- **Empty and absent ids (MUST)**: the read hooks are disabled for an empty, null or undefined ecosystem id and make no request; a hook given no id still builds a stable query key from an empty string.
- **Missing wire fields (MUST)**: a roster body with no `items` reads as an empty page, a missing `next_cursor` as `null`, and a row's missing `roles` or `sets` as empty lists.
- **Quota above the default (MUST NOT validate)**: the client sends any byte count; the 403 for a value above `DEFAULT_QUOTA_BYTES` is the backend's, and the panes check the ceiling themselves before sending.
- **A pause that fails (MUST)**: a refusal is rethrown unchanged to the caller, and the roster is not invalidated.
- **A manager calling the roster (MUST NOT recover)**: the backend answers a manager 403; the client does not retry or fall back.
- **A set-up that conflicts (MUST)**: the 409 from the admin site route reaches the caller as the transport's error, carrying the backend's message.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ecosystemId` | string | none, required | The product's ecosystem uuid every call names as `?ecosystem=<id>`. |
| `opts.q` | string | none | On the roster read, filters email and name. |
| `opts.cursor` | string | none | On the roster read, the `nextCursor` of the page before. |
| `DEFAULT_QUOTA_BYTES` | number | `5368709120` | The most storage a product admin may give one customer. |
| `PRODUCT_TOTALS_PATH`, `PRODUCT_CUSTOMERS_PATH`, `ADMIN_SITE_PATH` | string constants | `/api/v1/product_admin/totals`, `/api/v1/product_admin/customers`, `/api/v1/admin_site` | The base routes. |
| Transport | injected module imports | `authedJson`, `authedRequest`, `httpStatus`, `unixToIso`, `withV1Query` from `../http`, and `enc` from `../client-helpers` | The caller's environment supplies the token and base URL; this module reads no environment variable or setting. |

## Deep Linking

Not applicable: this is a data client; it declares no URL scheme or route of its own, only the backend `/api/v1` paths it calls.

## Localization

Not applicable: the module defines no user-facing string; an error's message is the backend's, passed through untranslated.

## Accessibility Options

Not applicable: this is a data client with no visual output.

## Feature Flags

Not applicable: the module reads no flag. Whether admin sites are on for a product is the backend's `product_admin_site` switch, reported as `enabled` in the admin site answer.

## Analytics

Not applicable: the module emits no event.

## Privacy

- **Data collected**: None by this module. It carries customer emails, display names, avatar URLs, external ids, roles, set ids and storage figures in transit between the backend and the caller. The roster is existence, not content: it says who a customer is, when they were last active, what they hold and how much storage they use, and never anything they made.
- **Storage**: None beyond React Query's in-memory cache.
- **Transmission**: Each call goes to the `/api/v1` path with the bearer token attached by the transport; the ecosystem uuid and customer id appear in the query string or path. Who may read or change the roster is the backend's decision.
- **Retention**: None; the cache is the caller's.

## Logging

Not applicable: no file contains a log call; a failure surfaces only as a thrown error.

## Platform Notes

- **SwiftUI**: Port the wire types as `Codable` structs with `CodingKeys` and the roster page as an `async throws` method over `URLSession`, keeping `ecosystem` as a query item. A cache that invalidates the roster and totals together replaces the React Query hooks.
- **Compose**: Use `kotlinx.serialization` data classes with `@SerialName`, and a repository whose write functions refresh the roster and totals flows together.
- **React/Web**: This is the source platform: `packages/web/packages/data/src/product-admin/` with its tests in `__tests__/product-admin.test.ts`. The files carry the `"use client"` directive and import `@tanstack/react-query`; the package's `exports` map publishes the folder as `@adh-sdk/data/product-admin` and its build config lists the entry.
- **AppKit / UIKit**: The same Foundation approach as SwiftUI; `JSONDecoder` with `convertFromSnakeCase` fits every row here.
- **WinUI 3**: One shared `HttpClient` with a bearer handler, and `System.Text.Json` with `[JsonPropertyName]` on records.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/data/src/product-admin/product-totals.ts` | confirmed (1.1.0) |
| web | `packages/web/packages/data/src/product-admin/product-customers.ts` | confirmed (1.1.0) |
| web | `packages/web/packages/data/src/product-admin/admin-site.ts` | confirmed (1.1.0) |
| web | `packages/web/packages/data/src/product-admin/index.ts` | confirmed (1.1.0) |

## Design Decisions

**Decision**: Every call names the product by its ecosystem uuid in the `ecosystem` query parameter, never an rdid.
**Rationale**: The roster file's header says the backend's `:eco` matcher and its realm check compare the uuid exactly.
**Approved**: pending

**Decision**: The client does not enforce `DEFAULT_QUOTA_BYTES`; it exports the constant and leaves the check to the panes and the backend.
**Rationale**: The backend is authoritative and answers 403 above it; the constant only lets a pane say so before sending.
**Approved**: pending

**Decision**: Every roster write invalidates the totals as well as the roster.
**Rationale**: The hook's own comment says they count the same people, so a pause, quota change or delete would otherwise leave the totals stale.
**Approved**: pending

**Decision**: The wire types are written by hand in this package rather than taken from the generated API types.
**Rationale**: The index file's header says every client in this package does so, following the sets client.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |

The module keeps wire types, mapping and routes apart from transport, which it delegates wholly to the shared HTTP layer, so separation of concerns passes. Unit-test coverage is partial: the tests assert routes, bodies, mapping, the seat-protected check and the admin site calls, but not the hooks' cache invalidation or disabled states.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.0 | 2026-11-23 | Mike Fullerton | Phase 7: consented support access |
| 1.0.0 | | | Initial creation |
