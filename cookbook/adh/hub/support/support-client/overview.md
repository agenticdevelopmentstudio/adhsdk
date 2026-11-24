
This is the web client for consented support access. A person who built content in a product, or a hub user, can be looked at by support only after they approve it, for a length they were told, and every read is logged. The backend owns every rule: who may ask, how long a grant lasts, what the viewer may read, what the log records. This code builds requests, maps `snake_case` wire rows to `camelCase` rows, and wraps each call in a React Query hook.

The component is three files in `packages/web/packages/data/src/support/`, published as `@adh-sdk/data/support`: `wire.ts` (the wire types and mappers), `grants.ts` (the four clients, the rules the panes read and the hooks) and `index.ts` (the re-exports). It uses the shared /v1 conventions ([adhsdk.ingredient.data.services.auth.v1](cookbook:870c182f-1a80-4254-8fec-3eb35c8f13f7)) and the authentication client ([adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)); nothing here reads a token or a base URL itself. A product admin's calls name the product the way the product admin client does ([adhsdk.ingredient.adh.hub.product-admin.product-admin-client](cookbook:150bf00e-6c6b-4f91-a323-d307ebd5700d)), by ecosystem uuid.

Four clients, one for each kind of caller. Every path is a `/api/v1` path, the backend's path snake-cased. None takes a transport argument: each calls the shared `authedJson`, `authedRequest` and `listV1Page` imports, and the public client calls the shared token-free `publicJson` ([adhsdk.ingredient.data.services.auth.v1](cookbook:870c182f-1a80-4254-8fec-3eb35c8f13f7)).

| Client | Caller | Functions |
|---|---|---|
| `supportApi(side)` | a customer (`side` `customer`) or a hub user (`account`) | `grants`, `approve`, `deny`, `revoke`, `access` |
| `supportAdminApi` (an object) | a product admin on the product's admin site | `list`, `request`, `revoke`, `data`, `row` |
| `operatorSupportApi` (an object) | an operator on the operator admin site | `list`, `request`, `breakGlass`, `revoke`, `access` |
| `publicSupportApi` (an object) | a person following an emailed link, with no session | `get`, `deny`, `revoke`, `sendCode`, `approve` |

