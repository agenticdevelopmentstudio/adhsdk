
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `side` | `"customer"` or `"account"` | none, required | Picks the person's own routes. |
| `ecosystemId` | string | none, required for a product admin | The product's ecosystem uuid every product admin call names as `?ecosystem=<id>`. |
| `SUPPORT_CONTENT_TABLES` | list of strings | the backend's content list | The tables the viewer offers. |
| Transport | `http` argument to each client, and static imports | `authedJson`, `authedRequest`, `httpStatus`, `unixToIso`, `withV1Query` from `../http`, and `enc` from `../client-helpers` | Each client takes an `http` object built from those imports, so a test can pass a stub; the caller's environment supplies the token and base URL. The public client sends none. |

