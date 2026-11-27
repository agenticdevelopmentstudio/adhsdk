
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

