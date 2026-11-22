
This is the client for the backend's sets admin surface (phase 5), written for an ecosystem's managers. A set is a named bundle of an ecosystem's permissions (catalog features) and limits (typed values such as a usage tier). Sets contain other sets. A customer holds sets through grants (an offer bought, a direct grant, the sign-up list), and the backend resolves what the customer holds into one effective answer. The backend owns every rule; this code only builds requests, maps `snake_case` wire rows to `camelCase` rows, and turns the backend's 422 `set_refused` body into a typed error.

The component is three files in `packages/web/packages/data/src/sets/`. `wire.ts` declares the types: the `camelCase` shapes the panes consume (`SetRow`, `SetGrantRow`, `EffectiveSets`, `UnresolvedSets`, `SetsAnswer`, `SetInput`, `SetPatch`, `SetValue`, `SetRefusal`, `SetEntries`, `SetLimitEntry`, `SetLimitType`, `SetGrantSource`) and the `*Wire` shapes they map from (`SetWire`, `SetGrantWire`, `SetsAnswerWire`, `SetEntriesWire`). `sets.ts` holds the mappers, the refusal error, the `setsApi` object and the catalog helpers. `index.ts` is the package entry `@adh-sdk/data/sets` and re-exports both with `export *`.

Every request goes through `authedJson` or `authedRequest` and the list walker `listAllV1`, with query strings built by `withV1Query`; those come from the shared /v1 conventions ([adhsdk.ingredient.data.services.auth.v1](cookbook:870c182f-1a80-4254-8fec-3eb35c8f13f7)) and the authentication client ([adhsdk.ingredient.data.services.auth.auth-client](cookbook:3ea9329e-5acc-4c43-b5ce-bb8c50570104)). Bearer-token attachment and the single refresh-and-retry on a 401 are inherited from there, not repeated here.

The routes, as the file header lists them:

| Route | Verb | Client function |
|---|---|---|
| `/api/v1/sets` | GET | `setsApi.list` |
| `/api/v1/sets` | POST | `setsApi.create` |
| `/api/v1/sets/{id}` | POST | `setsApi.edit` |
| `/api/v1/sets/{id}` | DELETE | `setsApi.remove` |
| `/api/v1/sets/{id}/members` | POST | `setsApi.setMembers` |
| `/api/v1/sets/{id}/values` | POST | `setsApi.setValues` |
| `/api/v1/set_grants?customer=` | GET | `setsApi.grants` |
| `/api/v1/set_grants` | POST | `setsApi.grant` |
| `/api/v1/set_grants/{id}` | DELETE | `setsApi.revoke` |
| `/api/v1/set_grants/effective/{customer_id}` | GET | `setsApi.effective` |
| `/api/v1/offers/{offer_id}/set` | POST | `setsApi.setOfferSet` |

