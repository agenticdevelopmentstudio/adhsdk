
This is the web client for a product's site (product sites phase 5). A product is an ecosystem, and every product is given a site when it is made: `https://<handle>.<base domain>`, where its customers sign in and sign up and, once the console is switched on, where its admins run its people under `/admin`. The hub's managers read and change that site through this client. It replaces the admin site client of phase 6, whose host-per-product registration is gone. The backend owns every rule; this code builds the request, maps the answer and wraps each call in a React Query hook.

The component is two files in `packages/web/packages/data/src/product-sites/`, published as `@adh-sdk/data/product-sites`. `product-site.ts` holds the wire and row types, `productSiteApi`, `ProductSiteError` and the two hooks. `index.ts` re-exports it. Requests go through `authedJson` with the query string built by `withV1Query`, from the shared /v1 conventions ([adhsdk.ingredient.data.services.auth.v1](cookbook:870c182f-1a80-4254-8fec-3eb35c8f13f7)) and the authentication client ([adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)); nothing here reads a token or a base URL itself.

The route is the backend's own, not a `/v1` one: the hub's `/api/:path*` rewrite forwards it unchanged, so the answer is the route's camelCase body and a change stays a `PATCH`. The call carries the product's ecosystem uuid in an `ecosystem` query parameter.

| Route | Verb | Client function |
|---|---|---|
| `/api/ecosystem/product-site` | GET | `productSiteApi.get`, `useProductSite` |
| `/api/ecosystem/product-site` | PATCH | `productSiteApi.update`, `useUpdateProductSite` |

The row type `ProductSite` carries `ecosystemId`, `handle`, `primaryOrigin`, `adminEnabled`, `adminClientId`, `consoleLive` and `contentGated`. `consoleLive` is the one rule the rail and the Product site pane share for "the console answers at the product's address now".

