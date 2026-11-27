
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

