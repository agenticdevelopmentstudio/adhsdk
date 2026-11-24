
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hit` | `PaperSearchHit` | — | Required. The selected document metadata including `author.slug` and `publicRoute`. |
| `source` | `SearchSource` | — | Required. Injected scope configuration with `baseUrl`, `endpoints.content` (defaults to `DEFAULT_CONTENT_ENDPOINT`, `/public/users/:slug/papers/:route`, when omitted), and `fetchInit`. |
| `timeoutMs` | `number` | `DEFAULT_TIMEOUT_MS` (15000) | Fetch timeout in milliseconds. Passed to `AbortSignal.timeout()`. |

