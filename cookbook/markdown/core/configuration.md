
| Option | Type | Default | Description |
|---|---|---|---|
| `fetcher` | `MarkdownFetcher` | `defaultMarkdownFetcher` | `useMarkdownDocument` option overriding how the document is retrieved; held in a ref so an unmemoized inline function does not re-trigger the fetch effect. The default always fetches the same-origin `/api/v1/papers/{id}` and does not follow `@adh-sdk/auth`'s `configureApiBase` (this package does not depend on the auth tier), so a host with no `/api` rewrite passes its own fetcher. |
| `timeoutMs` | `number` | `15000` (`DEFAULT_TIMEOUT_MS`) | `useMarkdownDocument` option controlling how long to wait before aborting the fetch with reason `'mdv-timeout'`. |
| `MarkdownText.excerptLines` | `Int` (constant) | `4` | Apple-side constant capping the number of lines `deriveExcerpt` collects; not exposed as a runtime option. |
| `MarkdownText.excerptLineCharacters` | `Int` (constant) | `160` | Apple-side constant capping each excerpt line, in UTF-16 code units. |
| `MarkdownText.excerptSourceCharacters` | `Int` (constant) | `2000` | Apple-side constant windowing `excerptSource` to this many Unicode scalars before excerpt derivation runs. |
| `titleCharacterLimit` / `MAX_TITLE` | `Int` / `number` (constant) | `500` | Shared cap, on both Apple and web, on a derived or written title's length. |


The abort reason `'mdv-timeout'` and the `adh-mv-*` class prefix (`adh-mv-prose`, `adh-mv-alert`) are fixed parts of the hook's and the stylesheet's contract, not options; they are not placeholders for a host to substitute.
