
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `url` | string | required | Collection URL for `listAllV1` and `listV1Page`; may carry filters. For `withV1Query`, the URL to extend. |
| `init` | `RequestInit` | `{}` | Passed unchanged to every page request. |
| `opts.cursorOf` | `(row: unknown) => string \| undefined` | row `id` as a string | Derives the paging cursor from a page's last row. |
| `params` | `Record<string, QueryValue>` | required | Query values for `withV1Query`; a value is a string, number, boolean, null, undefined or a readonly array of strings and numbers. |
| `V1_PAGE_MAX` | number | `100` | Page size `listAllV1` requests. |
| Injected dependency | `authedJson` | from `./client` | Authenticated JSON fetch; supplies the bearer token, refresh and error mapping. The access token and its storage key come from the host's auth configuration. |

