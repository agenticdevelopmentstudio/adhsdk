
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `id` | `string \| undefined` | `undefined` | (Web only) Document ID to fetch. If undefined, component shows idle state. |
| `fetcher` | `MarkdownFetcher` | `defaultMarkdownFetcher` (`GET /api/content/markdown/:id` through the host app's API forwarder) | (Web only) Optional custom fetcher function; used for testing. Production uses the real API. |
| `timeoutMs` | `number` | `15000` | (Web only) Fetch timeout in milliseconds. |
| `className` | `string` | `undefined` | (Web only) CSS class to forward to the root container element. |
| `nonce` | `string` | `undefined` | (Web only) CSP nonce for the pre-hydration bootstrap script. Required if host app enforces strict CSP. |
| `palette` | `SemanticPalette` | N/A (required) | (Apple only) Semantic color palette to apply to rendered content. |
| `highlighter` | `CodeHighlighter` | `nil` (no highlighting; falls back to monochrome themed monospace) | (Apple only) Optional custom code syntax highlighter; uses default if omitted. |

**Types referenced above:**
- `MarkdownFetcher`: `(id: string, signal: AbortSignal) => Promise<MarkdownDocument>` — given a document id and an abort signal, resolves the fetched document or rejects with an error. **fetch-timeout** and **abort-on-id-change** depend on the fetcher honoring `signal` (rejecting once it is aborted, as the default native-fetch fetcher does); a fetcher that ignores `signal` is not interrupted by an abort and can still resolve, or deliver a stale result, after the component has moved on to a new `id`.
- Document shape (fields the viewer reads): `{ id: string; title: string; content: string }` — `title` renders in the toolbar; `content` is the raw markdown body.
- `SemanticPalette` (Apple): the app-wide semantic color-role palette (e.g. `.primaryText`) — the same type used for theming elsewhere in the app.
- `CodeHighlighter` (Apple): `func highlight(_ code: String, language: String?, palette: SemanticPalette) -> NSAttributedString?`.
- Theme ID set (web): `dark` (default), `light`, `sepia`, `github` — validated against the viewer's theme registry; an unrecognized or stale id falls back to the default.

