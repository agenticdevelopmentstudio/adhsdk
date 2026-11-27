
- **A workspace asked about (MUST)**: the All Data pane asks about a workspace's ecosystem too, which is not a product and answers 404; the hook asks once and the pane reads the failure as "not gated".
- **No base domain (MUST)**: a backend with no product sites base domain answers `primaryOrigin: null`; the row keeps the handle and the caller says the address is not configured.
- **A change that conflicts (MUST)**: the 409 reaches the caller as a `ProductSiteError`, carrying the backend's code and sentence, and the cached site is not touched.
- **Custom domains switched off (MUST)**: every domain route answers 404 `not_found`; `useProductDomains` asks once and `productDomainsAvailable` answers false, so the caller shows nothing.
- **A remove the domain service did not finish (MUST)**: a 502 leaves the row `removing` on the backend; the hook reads the list again rather than dropping the row, so the caller can offer Remove again.
- **A removed or changed primary (MUST)**: the product's address moves, so the site's query is read again and `primaryOrigin` follows.
- **A domain the sweep settles (MUST)**: the backend verifies a pending domain, or finishes a removal, on its own; while any row is `pending` or `removing` the list is read again every minute, so the change shows without a reload.
- **An older backend (MUST)**: a site body with no `subdomainOrigin` reads it as its `primaryOrigin` (or `null` when that is null too), so the handle's suffix and the rename warning's addresses still show; an explicit `null` stays `null`.

