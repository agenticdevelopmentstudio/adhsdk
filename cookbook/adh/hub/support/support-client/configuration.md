
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `side` | `"customer"` or `"account"` | none, required | Picks the person's own routes. |
| `ecosystemId` | string | none, required for a product admin | The product's ecosystem uuid every product admin call names as `?ecosystem=<id>`. |
| `SUPPORT_CONTENT_TABLES` | list of strings | the backend's 89 content tables | The tables the viewer offers. |
| `SUPPORT_LAPSE_DAYS` | number | 7 | Days an undecided request stays `pending`. |
| `SUPPORT_PAGE_SIZE` | number | 50 | The `limit` of a log, viewer or operator-list page. |
| `SUPPORT_REASON_MIN`, `SUPPORT_REASON_MAX` | numbers | 10, 500 | The reason length the backend accepts. |
| `SUPPORT_HOURS_MAX`, `SUPPORT_BREAK_GLASS_HOURS_MAX`, `SUPPORT_HOURS_DEFAULT` | numbers | 168, 4, 24 | The longest consented grant, the longest break-glass grant, and the length a request form starts at. |
| `SUPPORT_ATTESTATION_MIN` | number | 40 | The shortest break-glass attestation. |
| Transport | static imports | `authedJson`, `authedRequest`, `httpStatus`, `listAllV1`, `listV1Page` and `withV1Query` from `../http`, `enc` from `../client-helpers`, and `publicJson` from `@adh-sdk/auth/client` | No client takes a transport argument. A test replaces the `../http` imports (`authedJson`, `authedRequest`, `listAllV1`, `listV1Page`) with stubs; the caller's environment supplies the token and base URL. The public client calls the shared `publicJson` with `cache: 'no-store'` and sends no authorization. |
