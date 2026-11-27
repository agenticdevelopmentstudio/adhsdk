
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
| product-site-client-010 | site-subdomain-origin | `get("eco-1")` over a body with `subdomainOrigin`, then over a body without it | The row's `subdomainOrigin` is the body's string; then `null` |
| product-site-client-011 | domains-list, domains-path-constant, domains-row-mapper | `list("eco-1")` over `{ domains: [ <a domain with an extra field> ] }` | A `GET` of `/api/ecosystem/product-domains` with params `{ ecosystem: "eco-1" }`; one `ProductDomain` holding the twelve known fields and not the extra one |
| product-site-client-012 | domains-add | `add("eco-1", "app.example.com")` | A `POST` of the path with body `{"host":"app.example.com"}`; the answer is one `ProductDomain` |
| product-site-client-013 | domains-check | `check("eco-1", "dom-1")` | A `POST` of `/api/ecosystem/product-domains/dom-1/check` with the same params; the answer is one `ProductDomain` |
| product-site-client-014 | domains-set-primary | `setPrimary("eco-1", "dom-1", true)` | A `PATCH` of `/api/ecosystem/product-domains/dom-1` with body `{"primary":true}`; the answer is the list |
| product-site-client-015 | domains-remove | `remove("eco-1", "dom-1")` answered 204 | A `DELETE` of `/api/ecosystem/product-domains/dom-1`; resolves to nothing |
| product-site-client-016 | domains-error | A 409 body `{ error: { code: "product_domain_taken", message } }`; then a `TypeError` from the transport | A `ProductDomainError` with status 409, that code and that message; then the same `TypeError` |
| product-site-client-017 | domains-hook-key | `useProductDomains(null)`; then over a 404; then over a 500 | No request; one request; two requests |
| product-site-client-018 | domains-add-cache, domains-check-cache | An add, then a check of that domain answered `verified` | The list in the cache gains the new row, then that row is replaced by the verified one |
| product-site-client-019 | domains-primary-cache | `setPrimary` answered with a list whose second row is primary | The cache holds that list and the product site's query is invalidated |
| product-site-client-020 | domains-remove-cache | A remove answered 204; then one answered 502 | The row leaves the cache and the site's query is invalidated; then the domain list and the site's query are both invalidated |
| product-site-client-021 | domains-available | A 404 with code `not_found`; a 404 with no code; a 404 with `product_domain_not_found`; a 500 | false; false; true; true |

Vectors 001 to 009 are asserted in `packages/web/packages/data/src/product-sites/__tests__/product-site-hook.test.tsx`, which stubs the transport, by the tests named. Vectors 010 to 021 are written from the phase 8 design and asserted in the same folder's `product-site-hook.test.tsx` (010) and `product-domains-hook.test.tsx` (011 to 021).

