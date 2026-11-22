
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `API_BASE` | string constant | `/api` | Same-origin BFF base for `buildRequest` and `useCrudResource`; the proxy strips `/api` and forwards to the unprefixed backend. Not configurable. |
| `token` (`buildRequest`) | `string` or `null` | none | Optional bearer token; sent as `Authorization: Bearer <token>` when truthy. The caller supplies it (from `useAuth`). |
| `values` (`buildRequest`) | `RequestValues` | required | `pathValues`, `queryValues`, and optional raw JSON `body` text. |
| `origin` (snippets) | `string` | `https://api.agenticdeveloperhub.com` (`PUBLIC_API_ORIGIN`) | Public origin used only for generated snippets. |
| `TOKEN_PLACEHOLDER` | string constant | `YOUR_TOKEN` | Token text embedded in snippets. |
| `API_ENDPOINTS`, `API_SCHEMAS` | generated constants | generated | Endpoint metadata and `components.schemas`, generated from the backend OpenAPI spec by `pnpm gen`. |
| `schemas` (schema helpers) | `ApiSchemas` | `API_SCHEMAS` | Resolution target for `$ref`; injectable for tests. |
| `EDITABLE_OVERRIDES` | `Record<string, Record<string, boolean>>` | `{}` | Per-table, per-column editability forcing for non-relational, non-server-managed columns. |
| `CRUD_TABLES` | generated constant | generated | Table descriptors emitted by `scripts/gen_table_metadata.py`; source of `CRUD_SCHEMAS`. |
| `meta` (`useCrudResource`) | `CrudTableMeta` | required | The table descriptor. |
| `filter` (`useCrudResource`) | `Record<string, string>` | none | Column-equality list filter; its `workspace` key also rides every write. |
| `scopeEcosystemId` (`useCrudResource`) | `string` | none | Ecosystem scope sent as `ecosystem_id` on every verb. |
| `isAdminViewer` (exposure checks) | `boolean` | required | Usually `useViewer().isAdmin`. |
| Auth context | optional provider | absent | `useViewer` reads it through `useOptionalAuth`. |
| Injected helpers | `authedJson`, `listAllV1`, `errorMessage` | n/a | Imported from `@adh-sdk/auth/client` and `@adh-sdk/ui/lib/errors`. |

