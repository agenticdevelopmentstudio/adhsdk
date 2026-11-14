
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `source` | `SearchSource` | — (required) | The search scope: base URL, endpoint, and request parameter map for document search. |
| `documentType` | `DocumentTypeConfig<Hit>` | — (required) | Result row renderer, preview component, preview header renderer, and `getId`/`getTitle` extractors. |
| `documentHref` | `(hit: Hit) => string` | — (required) | Builds the public-page URL for a hit; the primary link seam, deliberately without a default. |
| `searchLabel` | `string` | `"Search documents"` | Accessible label for the search input. |
| `searchPlaceholder` | `string` | `"Search…"` | Placeholder text in the search input. |
| `searchLandmarkLabel` | `string` | `"Document search"` | Accessible name for the `role="search"` landmark. |
| `debounceMs` | `number` | `250` | Debounce (ms) for search/filter changes before fetching. |
| `timeoutMs` | `number` | `undefined` | Per-request timeout (ms) for the search, facet, and preview fetches. |
| `urlSync` | `boolean` | `true` | Mirrors `q`/`tag`/`category` to the URL query string for a shareable, back/forward-safe results view. |
| `className` | `string` | `undefined` | Extra classes applied to the root element. |

