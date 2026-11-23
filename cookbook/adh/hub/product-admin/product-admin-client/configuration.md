
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ecosystemId` | string | none, required | The product's ecosystem uuid every call names as `?ecosystem=<id>`. |
| `opts.q` | string | none | On the roster read, filters email and name. |
| `opts.cursor` | string | none | On the roster read, the `nextCursor` of the page before. |
| `DEFAULT_QUOTA_BYTES` | number | `5368709120` | The most storage a product admin may give one customer. |
| `PRODUCT_TOTALS_PATH`, `PRODUCT_CUSTOMERS_PATH`, `ADMIN_SITE_PATH` | string constants | `/api/v1/product_admin/totals`, `/api/v1/product_admin/customers`, `/api/v1/admin_site` | The base routes. |
| Transport | injected module imports | `authedJson`, `authedRequest`, `httpStatus`, `unixToIso`, `withV1Query` from `../http`, and `enc` from `../client-helpers` | The caller's environment supplies the token and base URL; this module reads no environment variable or setting. |

