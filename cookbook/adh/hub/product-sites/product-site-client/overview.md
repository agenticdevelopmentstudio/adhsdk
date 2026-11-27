
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

