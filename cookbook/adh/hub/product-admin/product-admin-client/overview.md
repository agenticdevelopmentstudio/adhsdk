
This is the web client for a product's admin console (phase 6). A product is an ecosystem; its console is the `/admin` part of the product's own site, where the product's own admins, signed in with the product's customer login, read the product's totals and roster and pause, re-quota or delete a customer. The hub's managers use the same client to read the totals. The product's site itself (its handle, address and console switch) is read and changed by the product site client ([adhsdk.ingredient.adh.hub.product-sites.product-site-client](cookbook:1f689c5f-818d-4c64-918f-73bb9ec0be32)), not here. The backend owns every rule; this code builds requests, maps `snake_case` wire rows to `camelCase` rows, and wraps each call in a React Query hook.

The component is three files in `packages/web/packages/data/src/product-admin/`, published as `@adh-sdk/data/product-admin`. `product-totals.ts` reads a product's counts. `product-customers.ts` reads and changes the roster. `index.ts` re-exports the two and declares `DEFAULT_QUOTA_BYTES`, the most storage a product admin may give one customer: 5 GiB (5,368,709,120 bytes), mirroring the backend's own default. Every request goes through `authedJson` or `authedRequest`, with query strings built by `withV1Query`, from the shared /v1 conventions ([adhsdk.ingredient.data.services.auth.v1](cookbook:870c182f-1a80-4254-8fec-3eb35c8f13f7)) and the authentication client ([adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)); nothing here reads a token or a base URL itself.

Every call carries the product's ecosystem uuid in an `ecosystem` query parameter, never an rdid, because the backend compares it exactly.

| Route | Verb | Client function |
|---|---|---|
| `/api/v1/product_admin/totals` | GET | `fetchProductTotals`, `useProductTotals` |
| `/api/v1/product_admin/customers` | GET | `productAdminApi.customers`, `useProductCustomers` |
| `/api/v1/product_admin/customers/{id}` | DELETE | `productAdminApi.deleteCustomer`, `useDeleteCustomer` |
| `/api/v1/product_admin/customers/{id}/pause` | POST, DELETE | `productAdminApi.pause` and `unpause`, `usePauseCustomer` and `useUnpauseCustomer` |
| `/api/v1/product_admin/customers/{id}/quota` | POST | `productAdminApi.setQuota`, `useSetCustomerQuota` |

