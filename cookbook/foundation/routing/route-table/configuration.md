
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `handlers` (init) | `[RouteTable.Handler]` | `[]` | The handlers to try, in order; earlier handlers take precedence. |
| `other` (`merging`) | `RouteTable` | none | The table whose handlers are tried after this table's. |
| `method`, `components`, `respond` (`exact`) | `String`, `[String]`, async closure | none | The exact request method, the exact path components, and the closure that produces the response. |

`RouteTable` reads no environment variable or settings key.

