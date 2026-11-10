
| Option | Type | Default | Description |
|---|---|---|---|
| `fetcher` | `MarkdownFetcher` | `defaultMarkdownFetcher` | `useMarkdownDocument` option overriding how the document is retrieved; held in a ref so an unmemoized inline function does not re-trigger the fetch effect. |
| `timeoutMs` | `number` | `15000` (`DEFAULT_TIMEOUT_MS`) | `useMarkdownDocument` option controlling how long to wait before aborting the fetch with reason `'mdv-timeout'`. |
| `MarkdownText.excerptLines` | `Int` (constant) | `4` | Apple-side constant capping the number of lines `deriveExcerpt` collects; not exposed as a runtime option. |
| `MarkdownText.excerptLineCharacters` | `Int` (constant) | `160` | Apple-side constant capping each excerpt line, in UTF-16 code units. |
| `MarkdownText.excerptSourceCharacters` | `Int` (constant) | `2000` | Apple-side constant windowing `excerptSource` to this many Unicode scalars before excerpt derivation runs. |
| `titleCharacterLimit` / `MAX_TITLE` | `Int` / `number` (constant) | `500` | Shared cap, on both Apple and web, on a derived or written title's length. |

