---
title: "Product Site Client"
type: ingredient
status: review
language: en
summary: "Web client for a product's site: its handle, its address, the switch for its /admin console and whether the console is live, read and changed through one backend route, with their React Query hooks and a typed refusal."
platforms:
  - typescript
  - web
tags:
  - data
  - product-sites
  - api
depends-on:
  - 870c182f-1a80-4254-8fec-3eb35c8f13f7
  - 3ea9329e-5acc-4c43-b5ce-bb8c50570104
id: 1f689c5f-818d-4c64-918f-73bb9ec0be32
version: 1.0.0
created: 2026-11-26
modified: 2026-11-26
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
related: []
references: []
---
# Product Site Client

## Overview

This is the web client for a product's site (product sites phase 5). A product is an ecosystem, and every product is given a site when it is made: `https://<handle>.<base domain>`, where its customers sign in and sign up and, once the console is switched on, where its admins run its people under `/admin`. The hub's managers read and change that site through this client. It replaces the admin site client of phase 6, whose host-per-product registration is gone. The backend owns every rule; this code builds the request, maps the answer and wraps each call in a React Query hook.

The component is two files in `packages/web/packages/data/src/product-sites/`, published as `@adh-sdk/data/product-sites`. `product-site.ts` holds the wire and row types, `productSiteApi`, `ProductSiteError` and the two hooks. `index.ts` re-exports it. Requests go through `authedJson` with the query string built by `withV1Query`, from the shared /v1 conventions ([adhsdk.ingredient.data.services.auth.v1](cookbook:870c182f-1a80-4254-8fec-3eb35c8f13f7)) and the authentication client ([adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)); nothing here reads a token or a base URL itself.

The route is the backend's own, not a `/v1` one: the hub's `/api/:path*` rewrite forwards it unchanged, so the answer is the route's camelCase body and a change stays a `PATCH`. The call carries the product's ecosystem uuid in an `ecosystem` query parameter.

| Route | Verb | Client function |
|---|---|---|
| `/api/ecosystem/product-site` | GET | `productSiteApi.get`, `useProductSite` |
| `/api/ecosystem/product-site` | PATCH | `productSiteApi.update`, `useUpdateProductSite` |

The row type `ProductSite` carries `ecosystemId`, `handle`, `primaryOrigin`, `adminEnabled`, `adminClientId`, `consoleLive` and `contentGated`. `consoleLive` is the one rule the rail and the Product site pane share for "the console answers at the product's address now".

## Behavioral Requirements

### Reading

- **site-read**: `productSiteApi.get` MUST `GET` `/api/ecosystem/product-site?ecosystem=<uuid>` and return the body as a `ProductSite`: `ecosystemId`, `handle`, `primaryOrigin` (`null` when the body has none, the backend having no base domain), `adminEnabled` coerced to a boolean, `adminClientId` (`null` when absent), `consoleLive` and `contentGated`.
- **site-read-older-backend**: a body without `consoleLive` or without `contentGated`, from a backend that predates it, MUST read as `false` for that field: not live, not gated.
- **site-path-constant**: `PRODUCT_SITE_PATH` MUST be `/api/ecosystem/product-site`.

### Changing

- **site-update**: `productSiteApi.update` MUST send a `PATCH` of the same path and query with a JSON body holding only the fields given (`handle`, `adminEnabled`, or both), and return the answer as `get` does.
- **site-update-cache**: `useUpdateProductSite` MUST, on success, write the returned site straight into the product's query, and MUST leave that query as it was when the change is refused.

### Refusals

- **site-error-carries-sentence**: a failure that has an HTTP status MUST be rethrown as a `ProductSiteError` carrying that `status`, the backend's sentence as `message` (the body's `error.message`, or its top-level `message`) and, when the body has one, its `error.code` as `code` (`product_site_handle_taken`, `product_sites_unconfigured`). A malformed or reserved handle answers 400 with a sentence and no code; a taken handle, or a console with no base domain, answers 409 with both.
- **site-error-network-unchanged**: a failure with no HTTP status (the network) MUST be rethrown unchanged, so it is still reported as unexpected.

### Hooks

- **site-hook-key**: `useProductSite` MUST read under the key `["product-sites", <id>]` (`PRODUCT_SITE_KEY`) and MUST be disabled while there is no ecosystem id (`null`, `undefined` or empty).
- **site-hook-no-retry-404**: `useProductSite` MUST NOT retry a 404, which an ecosystem that is not a product (a workspace's, asked by the All Data pane) answers every time; any other failure MUST be retried once.

## Appearance

Not applicable: this is a data client with mappers, types and hooks, not a visual component.

## States

Not applicable: this is a data client with no visual states; its hooks expose React Query's own pending, error and success states and keep no state of their own.

## Accessibility

Not applicable: this is a data client with no user interface; the panes that consume it are separate components.

## Conformance Test Vectors

| ID | Requirement | Input | Expected |
|---|---|---|---|
| product-site-client-001 | site-read, site-path-constant | `get("eco-1")` over a full body (test: "reads the site from the backend's own route") | A `GET` of `/api/ecosystem/product-site` with params `{ ecosystem: "eco-1" }` and no method override; the row equals the body |
| product-site-client-002 | site-read-older-backend | `get("eco-1")` over a body with no `consoleLive` and no `contentGated` (test: "reads a backend without consoleLive or contentGated as neither") | `consoleLive` is `false` and `contentGated` is `false` |
| product-site-client-003 | site-update | `update("eco-1", { handle: "jots" })` (test: "changes the site with PATCH and only the fields given") | A `PATCH` of the same path and params with body `{"handle":"jots"}`; the answer's `handle` is `jots` |
| product-site-client-004 | site-error-carries-sentence | A 409 body `{ error: { code: "product_site_handle_taken", message } }` (test: "surfaces a coded 409 with its code and the backend's sentence") | A `ProductSiteError` with status 409, that code and that message |
| product-site-client-005 | site-error-carries-sentence | A 400 body `{ error: { message: "admin is reserved" } }`, then a 400 body `{ message: "handle is too long" }` (tests: "surfaces a 400 HTTPException's sentence", "surfaces a top-level { message } body's sentence") | Each is a `ProductSiteError` with status 400 and that sentence; the first has no `code` |
| product-site-client-006 | site-error-network-unchanged | A `TypeError("Failed to fetch")` from the transport (test: "passes a failure with no status through unchanged") | `get` rejects with that same error object |
| product-site-client-007 | site-hook-no-retry-404 | `useProductSite` over a 404, then over a 500 (tests: "asks once when the ecosystem answers 404", "still retries any other failure once") | One request for the 404; two for the 500 |
| product-site-client-008 | site-hook-key | `useProductSite(null)` (test: "does not ask without an ecosystem") | No request is made |
| product-site-client-009 | site-update-cache | `useUpdateProductSite("eco-1")` changing `adminEnabled` to `false`, then a refused change with code `product_sites_unconfigured` (tests: "writes the answer into the site's query", "leaves the query alone when refused") | The cache holds the answer after the first, with one request; the cache is unchanged after the second, and the error carries the code |

Vectors marked with a test name are asserted in `packages/web/packages/data/src/product-sites/__tests__/product-site-hook.test.tsx`, which stubs the transport.

## Edge Cases

- **A workspace asked about (MUST)**: the All Data pane asks about a workspace's ecosystem too, which is not a product and answers 404; the hook asks once and the pane reads the failure as "not gated".
- **No base domain (MUST)**: a backend with no product sites base domain answers `primaryOrigin: null`; the row keeps the handle and the caller says the address is not configured.
- **A change that conflicts (MUST)**: the 409 reaches the caller as a `ProductSiteError`, carrying the backend's code and sentence, and the cached site is not touched.

## Configuration

| Parameter | Type | Default | Description |
|---|---|---|---|
| `PRODUCT_SITE_PATH` | string constant | `/api/ecosystem/product-site` | The route. |
| `PRODUCT_SITE_KEY(ecosystemId)` | function | `["product-sites", ecosystemId]` | The query key of one product's site. |

## Deep Linking

Not applicable: this is a data client; it declares no URL scheme or route of its own, only the backend path it calls.

## Localization

Not applicable: the module defines no user-facing string; an error's message is the backend's, passed through untranslated.

## Accessibility Options

Not applicable: this is a data client with no visual output.

## Feature Flags

Not applicable: the module reads no flag. Whether the console is on for a product is the site's `adminEnabled` field, and whether it answers is `consoleLive`.

## Analytics

Not applicable: the module emits no event.

## Privacy

- **Data collected**: None by this module. It carries a product's handle, its address and its console's login registration id in transit between the backend and the caller.
- **Storage**: None beyond React Query's in-memory cache.
- **Transmission**: The call goes to the hub's own `/api` path with the bearer token attached by the transport; the ecosystem uuid appears in the query string and a change's fields in the body. Who may read or change a product's site is the backend's decision.
- **Retention**: None; the cache is the caller's.

## Logging

Not applicable: no file contains a log call; a failure surfaces only as a thrown error.

## Platform Notes

- **SwiftUI**: Port the row as a `Codable` struct with optional `consoleLive` and `contentGated` defaulting to `false`, and the change as an `async throws` method sending a `PATCH` over `URLSession`; a typed error keeps the status, code and sentence.
- **Compose**: Use `kotlinx.serialization` data classes with default values for the two optional fields, and a repository whose update replaces the cached site on success.
- **React/Web**: This is the source platform: `packages/web/packages/data/src/product-sites/` with its tests in `__tests__/product-site-hook.test.tsx`. The file carries the `"use client"` directive and imports `@tanstack/react-query`; the package's `exports` map publishes the folder as `@adh-sdk/data/product-sites` and its build config lists the entry.
- **AppKit / UIKit**: The same Foundation approach as SwiftUI.
- **WinUI 3**: One shared `HttpClient` with a bearer handler, and `System.Text.Json` with `[JsonPropertyName]` on records.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/data/src/product-sites/` | confirmed (1.0.0) |

## Design Decisions

**Decision**: The row carries `consoleLive` as its own field rather than the caller combining `adminEnabled` with `adminClientId`.
**Rationale**: The rail and the pane both move people rows on the same rule, so the backend answers it once; the field is optional on the wire so an older backend reads as not live and the hub keeps every pane.
**Approved**: pending

**Decision**: A refusal is a `ProductSiteError` that keeps the backend's code and sentence.
**Rationale**: The pane shows the sentence as the backend wrote it, and a caller that needs to tell a taken handle from a missing base domain reads the code.
**Approved**: pending

**Decision**: A 404 is not retried.
**Rationale**: An ecosystem that is not a product answers it every time, and the All Data pane asks about workspaces, so a retry only doubles the failed requests.
**Approved**: pending

**Decision**: The wire types are written by hand in this package rather than taken from the generated API types.
**Rationale**: The module's header says every client in this package does so, following the sets client.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |

The module keeps wire types, mapping and the route apart from transport, which it delegates wholly to the shared HTTP layer, so separation of concerns passes. The tests assert the route, the body, the mapping, the refusals and the hooks' retry, disabled and cache behavior, so unit-test coverage passes.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | | | Initial creation |
