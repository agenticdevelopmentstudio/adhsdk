
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `OPAQUE` | set of key names | `config`, `detail`, `body`, `value`, `counts` | Property names whose values are copied verbatim by both mappers. Module-private constant, not caller-configurable. |
| `url` | string | none | The `/v1` endpoint or collection url passed to `v1Json`, `v1List` and `v1Page`. |
| `init` | `RequestInit` | none | Optional request init for `v1Json`; forwarded to `authedJson`. `v1List` and `v1Page` take no init. |
| `method` | `"POST"` | none | Method recorded by `v1Write`; no other method is accepted by its type. |
| Request layer | injected import | `authedJson`, `listAllV1`, `listV1Page`, `unixToIso` from the data package's `http` module | Supplies the authentication, paging (`limit=100`, `starting_after`), and timestamp conversion. A port supplies equivalents. |

