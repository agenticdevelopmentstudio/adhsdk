
This is the web client for consented support access (phase 7). A person who built content in a product, or a hub user, can be looked at by support only after they approve it, for a length they were told, and every read is logged. The backend owns every rule: who may ask, how long a grant lasts, what the viewer may read, what the log records. This code builds requests, maps `snake_case` wire rows to `camelCase` rows, and wraps each call in a React Query hook.

The component is three files in `packages/web/packages/data/src/support/`, published as `@adh-sdk/data/support`: `wire.ts` (the wire types and mappers), `support.ts` (the four clients and their hooks) and `index.ts` (the re-exports). It uses the shared /v1 conventions ([adhsdk.ingredient.data.services.auth.v1](cookbook:870c182f-1a80-4254-8fec-3eb35c8f13f7)) and the authentication client ([adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)); nothing here reads a token or a base URL itself. A product admin's calls name the product the way the product admin client does ([adhsdk.ingredient.adh.hub.product-admin.product-admin-client](cookbook:150bf00e-6c6b-4f91-a323-d307ebd5700d)), by ecosystem uuid.

Four clients, one for each kind of caller. Every path is a `/v1` path.

| Client | Caller | Functions |
|---|---|---|
| `supportApi(http, side)` | a customer (`side` `customer`) or a hub user (`account`) | `grants`, `approve`, `deny`, `revoke`, `access` |
| `supportAdminApi(http)` | a product admin on the product's admin site | `list`, `request`, `revoke`, `data`, `row` |
| `operatorSupportApi(http)` | an operator on the operator admin site | `list`, `request`, `breakGlass`, `revoke`, `access` |
| `publicSupportApi(http)` | a person following an emailed link, with no session | `get`, `deny`, `revoke`, `sendCode`, `approve` |

