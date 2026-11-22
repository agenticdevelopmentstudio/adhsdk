
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ecoId` | string | none, required | The ecosystem id every call names as `?ecosystem=<id>`. |
| `opts.personal` | boolean | `undefined` (omitted) | On `setsApi.list`, adds `personal=true` to include personal sets. |
| `SETS` | string constant | `/api/v1/sets` | Module-private base route for sets. |
| `GRANTS` | string constant | `/api/v1/set_grants` | Module-private base route for grants. |
| Transport | injected module imports | `authedJson`, `authedRequest`, `httpStatus`, `listAllV1`, `withV1Query` from `../http`, `enc` and `sortByText` from `../client-helpers` | The caller's environment supplies the token and base URL through the shared HTTP layer; this module reads no environment variable or setting. |

