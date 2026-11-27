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
version: 1.1.0
created: 2026-11-26
modified: 2026-11-27
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
related: []
references: []
---
# Product Site Client

## Overview

This is the web client for a product's site (product sites phase 5). A product is an ecosystem, and every product is given a site when it is made: `https://<handle>.<base domain>`, where its customers sign in and sign up and, once the console is switched on, where its admins run its people under `/admin`. The hub's managers read and change that site through this client. It replaces the admin site client of phase 6, whose host-per-product registration is gone. The backend owns every rule; this code builds the request, maps the answer and wraps each call in a React Query hook.

Since product sites phase 8 it is also the client for a product's custom domains: a domain the product's owner holds, added so the product answers there too, checked until its DNS records are found, and made the product's primary address once verified.

The component is three files in `packages/web/packages/data/src/product-sites/`, published as `@adh-sdk/data/product-sites`. `product-site.ts` holds the site's wire and row types, `productSiteApi`, `ProductSiteError` and the two site hooks. `product-domains.ts` follows it exactly for the custom domains: the wire and row types, `productDomainsApi`, `ProductDomainError`, `productDomainsAvailable` and five hooks. `index.ts` re-exports both. Requests go through `authedJson` (and `authedRequest` for the domain `DELETE`, which answers 204 with no body) with the query string built by `withV1Query`, from the shared /v1 conventions ([adhsdk.ingredient.data.services.auth.v1](cookbook:870c182f-1a80-4254-8fec-3eb35c8f13f7)) and the authentication client ([adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)); nothing here reads a token or a base URL itself.

The routes are the backend's own, not `/v1` ones: the hub's `/api/:path*` rewrite forwards them unchanged, so each answer is the route's camelCase body and a change stays a `PATCH`. Every call carries the product's ecosystem uuid in an `ecosystem` query parameter.

| Route | Verb | Client function |
|---|---|---|
| `/api/ecosystem/product-site` | GET | `productSiteApi.get`, `useProductSite` |
| `/api/ecosystem/product-site` | PATCH | `productSiteApi.update`, `useUpdateProductSite` |
| `/api/ecosystem/product-domains` | GET | `productDomainsApi.list`, `useProductDomains` |
| `/api/ecosystem/product-domains` | POST | `productDomainsApi.add`, `useAddProductDomain` |
| `/api/ecosystem/product-domains/:id/check` | POST | `productDomainsApi.check`, `useCheckProductDomain` |
| `/api/ecosystem/product-domains/:id` | PATCH | `productDomainsApi.setPrimary`, `useSetPrimaryProductDomain` |
| `/api/ecosystem/product-domains/:id` | DELETE | `productDomainsApi.remove`, `useRemoveProductDomain` |

The row type `ProductSite` carries `ecosystemId`, `handle`, `primaryOrigin`, `subdomainOrigin`, `adminEnabled`, `adminClientId`, `consoleLive` and `contentGated`. `consoleLive` is the one rule the rail and the Product site pane share for "the console answers at the product's address now". `primaryOrigin` is the custom domain once one is primary; `subdomainOrigin` is always the product's own `<scheme>://<handle>.<base>`, which the hub cannot derive because it does not know the base domain.

The row type `ProductDomain` carries `id`, `host`, `status` (`pending`, `verified`, `failed` or `removing`), `isPrimary`, `records` (each a `type` of `A`, `CNAME` or `TXT`, a `name` and a `value`), `misconfigured`, `vercelVerified`, `error`, `createdAt`, `verifiedAt`, `checkedAt` and `expiresAt`. The domain routes answer 404 `not_found` while the backend's `product_custom_domains` switch is off.

## Behavioral Requirements

### Reading

- **site-read**: `productSiteApi.get` MUST `GET` `/api/ecosystem/product-site?ecosystem=<uuid>` and return the body as a `ProductSite`: `ecosystemId`, `handle`, `primaryOrigin` (`null` when the body has none, the backend having no base domain), `adminEnabled` coerced to a boolean, `adminClientId` (`null` when absent), `consoleLive` and `contentGated`.
- **site-read-older-backend**: a body without `consoleLive` or without `contentGated`, from a backend that predates it, MUST read as `false` for that field: not live, not gated.
- **site-subdomain-origin**: the row MUST carry `subdomainOrigin`, the product's own `<scheme>://<handle>.<base>` address, read from the body as is when the field is present (a string, or `null` when the backend has no base domain). From an older backend that does not answer the field (`undefined`) it MUST read as `primaryOrigin ?? null`: such a backend reports no custom domain, so its primary is the subdomain. While no custom domain is primary it is the same string as `primaryOrigin`.
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

### Custom domains

- **domains-path-constant**: `PRODUCT_DOMAINS_PATH` MUST be `/api/ecosystem/product-domains`. Every domain call MUST carry `?ecosystem=<uuid>` through `withV1Query` and MUST go through the bearer SDK transport: `authedJson` for every call that answers a body, and `authedRequest` for the `DELETE`, whose answer is a 204 that `authedJson` would refuse. Both send the same bearer token, never cookies.
- **domains-row-mapper**: a domain MUST be mapped to a `ProductDomain` by copying only the fields it knows (`id`, `host`, `status`, `isPrimary`, `records`, `misconfigured`, `vercelVerified`, `error`, `createdAt`, `verifiedAt`, `checkedAt`, `expiresAt`), never by spreading the wire object; the answer is already camelCase.
- **domains-list**: `productDomainsApi.list(id)` MUST `GET` the path and return the body's `domains` as `ProductDomain[]`.
- **domains-add**: `productDomainsApi.add(id, host)` MUST `POST` the path with the JSON body `{ host }` and return the answer as one `ProductDomain`.
- **domains-check**: `productDomainsApi.check(id, domainId)` MUST `POST` `<path>/<domainId>/check` and return the answer as one `ProductDomain`.
- **domains-set-primary**: `productDomainsApi.setPrimary(id, domainId, primary)` MUST `PATCH` `<path>/<domainId>` with the JSON body `{ primary }` and return the answer as `ProductDomain[]`, the whole list, since a change of primary moves the mark between rows.
- **domains-remove**: `productDomainsApi.remove(id, domainId)` MUST `DELETE` `<path>/<domainId>` and resolve to nothing on the 204.
- **domains-error**: a domain call's failure that has an HTTP status MUST be rethrown, by `asProductDomainError`, as a `ProductDomainError(status, message, code?)` exactly as [site-error-carries-sentence](#requirements/site-error-carries-sentence) says for the site; a failure with no status MUST be rethrown unchanged.
- **domains-hook-key**: `useProductDomains(id)` MUST read under `["product-domains", <id>]` (`PRODUCT_DOMAINS_KEY`), MUST be disabled without an ecosystem id, and MUST NOT retry a 404 (`retry: (n, err) => !isNotFound(err) && n < 1`); any other failure is retried once.
- **domains-poll**: `useProductDomains(id)` MUST read the list again every `PRODUCT_DOMAINS_POLL_MS` (60 seconds) while any cached domain is `pending` or `removing`, and MUST NOT poll otherwise: its `refetchInterval` is a function of the query's data, `false` when there is none. The backend's sweep verifies a pending domain and finishes a removal on its own, so the list follows without a reload. The site's query is not polled.
- **domains-add-cache**: `useAddProductDomain` MUST, on success, append the new domain to the product's domain list in the cache.
- **domains-check-cache**: `useCheckProductDomain` MUST, on success, replace that domain's row in the cache with the answer.
- **domains-primary-cache**: `useSetPrimaryProductDomain` MUST, on success, set the product's domain list in the cache to the answer and then invalidate `PRODUCT_SITE_KEY` for the product, so the site's `primaryOrigin` follows.
- **domains-remove-cache**: `useRemoveProductDomain` MUST drop the row from the cache on success, MUST invalidate the domain list on a 502 (the backend leaves the row `removing`), and MUST invalidate `PRODUCT_SITE_KEY` for the product either way, since a removed primary moves the address back to the subdomain.
- **domains-available**: `productDomainsAvailable(err)` MUST answer false for a 404 whose `code` is `not_found` or absent (the `product_custom_domains` switch is off) and true for any other failure, so the section can hide itself.

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
| product-site-client-010 | site-subdomain-origin | `get("eco-1")` over a body with `subdomainOrigin`; over a body without it and with a `primaryOrigin`; over a body without it and with `primaryOrigin: null`; over a body with `subdomainOrigin: null` and a `primaryOrigin` (tests: "reads the site from the backend's own route", "reads a backend without subdomainOrigin as its primary origin", "reads a backend without subdomainOrigin or a primary origin as null", "keeps an explicit null subdomainOrigin even when there is a primary origin") | The body's string; the `primaryOrigin`; `null`; `null` |
| product-site-client-011 | domains-list, domains-path-constant, domains-row-mapper | `list("eco-1")` over `{ domains: [ <a domain with an extra field> ] }` (tests: "lists the domains from the backend's own route", "maps only the fields it knows") | A `GET` of `/api/ecosystem/product-domains` with params `{ ecosystem: "eco-1" }`; one `ProductDomain` holding the twelve known fields and not the extra one |
| product-site-client-012 | domains-add | `add("eco-1", "app.example.com")` (test: "adds a host with POST { host }") | A `POST` of the path with body `{"host":"app.example.com"}`; the answer is one `ProductDomain` |
| product-site-client-013 | domains-check | `check("eco-1", "dom-1")` (test: "checks a domain with POST /:id/check and no body") | A `POST` of `/api/ecosystem/product-domains/dom-1/check` with the same params; the answer is one `ProductDomain` |
| product-site-client-014 | domains-set-primary | `setPrimary("eco-1", "dom-1", true)` (test: "sets the primary with PATCH /:id { primary } and answers the list") | A `PATCH` of `/api/ecosystem/product-domains/dom-1` with body `{"primary":true}`; the answer is the list |
| product-site-client-015 | domains-remove | `remove("eco-1", "dom-1")` answered 204 (test: "removes a domain with DELETE /:id through the no-body transport") | A `DELETE` of `/api/ecosystem/product-domains/dom-1`; resolves to nothing |
| product-site-client-016 | domains-error | A 409 body `{ error: { code: "product_domain_taken", message } }`; then a `TypeError` from the transport (tests: "surfaces a coded refusal with its code and the backend's sentence", "passes a failure with no status through unchanged") | A `ProductDomainError` with status 409, that code and that message; then the same `TypeError` |
| product-site-client-017 | domains-hook-key | `useProductDomains(null)`; then over a 404; then over a 500 (tests: "does not ask without an ecosystem", "asks once when the switch answers 404", "still retries any other failure once") | No request; one request; two requests |
| product-site-client-018 | domains-add-cache, domains-check-cache | An add, then a check of that domain answered `verified` (tests: "appends the new domain to the list", "replaces the checked row in the list") | The list in the cache gains the new row, then that row is replaced by the verified one |
| product-site-client-019 | domains-primary-cache | `setPrimary` answered with a list whose second row is primary (test: "sets the list and invalidates the product site") | The cache holds that list and the product site's query is invalidated |
| product-site-client-020 | domains-remove-cache | A remove answered 204; then one answered 502 (tests: "drops the row and invalidates the product site", "invalidates the list on a 502, since the row is left removing") | The row leaves the cache and the site's query is invalidated; then the domain list and the site's query are both invalidated |
| product-site-client-021 | domains-available | A 404 with code `not_found`; a 404 with no code; a 404 with `product_domain_not_found`; a 500 (tests: "is false for the switch's 404 not_found", "is false for a 404 with no code", "is true for a 404 with another code, any other refusal, or none") | false; false; true; true |
| product-site-client-022 | domains-poll | `useProductDomains("eco-1")` over a list holding a `pending` domain, then over one whose domains are `verified` and `failed`, each with a minute or more passing (tests: "reads the list again every minute while a domain is pending", "does not poll when every domain is verified or failed") | A second request after one minute; then no request after the first, even after three minutes |

Every vector is asserted by the tests named, which stub the transport: 001 to 010 in `packages/web/packages/data/src/product-sites/__tests__/product-site-hook.test.tsx`, and 011 to 022 in the same folder's `product-domains-hook.test.tsx`.

## Edge Cases

- **A workspace asked about (MUST)**: the All Data pane asks about a workspace's ecosystem too, which is not a product and answers 404; the hook asks once and the pane reads the failure as "not gated".
- **No base domain (MUST)**: a backend with no product sites base domain answers `primaryOrigin: null`; the row keeps the handle and the caller says the address is not configured.
- **A change that conflicts (MUST)**: the 409 reaches the caller as a `ProductSiteError`, carrying the backend's code and sentence, and the cached site is not touched.
- **Custom domains switched off (MUST)**: every domain route answers 404 `not_found`; `useProductDomains` asks once and `productDomainsAvailable` answers false, so the caller shows nothing.
- **A remove the domain service did not finish (MUST)**: a 502 leaves the row `removing` on the backend; the hook reads the list again rather than dropping the row, so the caller can offer Remove again.
- **A removed or changed primary (MUST)**: the product's address moves, so the site's query is read again and `primaryOrigin` follows.
- **A domain the sweep settles (MUST)**: the backend verifies a pending domain, or finishes a removal, on its own; while any row is `pending` or `removing` the list is read again every minute, so the change shows without a reload.
- **An older backend (MUST)**: a site body with no `subdomainOrigin` reads it as its `primaryOrigin` (or `null` when that is null too), so the handle's suffix and the rename warning's addresses still show; an explicit `null` stays `null`.

## Configuration

| Parameter | Type | Default | Description |
|---|---|---|---|
| `PRODUCT_SITE_PATH` | string constant | `/api/ecosystem/product-site` | The route. |
| `PRODUCT_SITE_KEY(ecosystemId)` | function | `["product-sites", ecosystemId]` | The query key of one product's site. |
| `PRODUCT_DOMAINS_PATH` | string constant | `/api/ecosystem/product-domains` | The custom domains route. |
| `PRODUCT_DOMAINS_KEY(ecosystemId)` | function | `["product-domains", ecosystemId]` | The query key of one product's custom domains. |
| `PRODUCT_DOMAINS_POLL_MS` | number constant | `60000` | How often the domain list is read again while a domain is `pending` or `removing`. |

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

**Decision**: The site answers `subdomainOrigin` beside `primaryOrigin`.
**Rationale**: Once a custom domain is primary the pane still needs the product's own address, to say it still works, to warn what a rename breaks and to show the handle's suffix; the hub does not know the base domain, so it cannot derive it.
**Approved**: pending

**Decision**: Changing or removing a domain invalidates the product site's query.
**Rationale**: The product's address is the site's `primaryOrigin`, which a primary change or a removed primary moves; reading the site again keeps one source for the address.
**Approved**: pending

**Decision**: `productDomainsAvailable` reads a 404 `not_found` as the switch being off.
**Rationale**: The backend hides the routes while `product_custom_domains` is off, so the section hides itself rather than showing an error a manager cannot act on.
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
| 1.1.0 | 2026-11-27 | Mike Fullerton | Phase 8: subdomainOrigin on the site, and the product domains client (productDomainsApi, ProductDomainError, five hooks, productDomainsAvailable) |
| 1.0.0 | | | Initial creation |
