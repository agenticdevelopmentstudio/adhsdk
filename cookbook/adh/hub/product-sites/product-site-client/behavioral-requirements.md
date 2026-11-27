
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
- **domains-add-cache**: `useAddProductDomain` MUST, on success, append the new domain to the product's domain list in the cache.
- **domains-check-cache**: `useCheckProductDomain` MUST, on success, replace that domain's row in the cache with the answer.
- **domains-primary-cache**: `useSetPrimaryProductDomain` MUST, on success, set the product's domain list in the cache to the answer and then invalidate `PRODUCT_SITE_KEY` for the product, so the site's `primaryOrigin` follows.
- **domains-remove-cache**: `useRemoveProductDomain` MUST drop the row from the cache on success, MUST invalidate the domain list on a 502 (the backend leaves the row `removing`), and MUST invalidate `PRODUCT_SITE_KEY` for the product either way, since a removed primary moves the address back to the subdomain.
- **domains-available**: `productDomainsAvailable(err)` MUST answer false for a 404 whose `code` is `not_found` or absent (the `product_custom_domains` switch is off) and true for any other failure, so the section can hide itself.

