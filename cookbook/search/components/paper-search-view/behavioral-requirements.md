
- **document-href-required**: Component MUST accept a required `documentHref` prop that is a function accepting a PaperSearchHit and returning a string representing the document's URL on the host.
- **search-source-configuration**: Component MUST configure a SearchSource with endpoints for results (`/v1/papers`), tags (`/v1/paper_tags`), and categories (`/v1/paper_categories`).
- **no-store-cache-policy**: Component MUST set cache policy to `no-store` on fetch requests to ensure search results reflect the current corpus state.
- **author-slug-filter**: Component MUST accept an optional `authorSlug` prop; when provided, search results MUST be filtered to that author.
- **author-slug-normalization**: When `authorSlug` is provided, the component MUST trim it and convert it to lowercase before use. Internal whitespace is kept as is, and percent-encoding is left to the fetch layer when the `author` fixed param becomes part of the query string. If the trimmed result is an empty string, the component MUST treat `authorSlug` as if it had not been provided (no `author` fixed param).
- **base-url-override**: Component MUST accept an optional `baseUrl` prop that overrides the default API prefix. On web the default is same-origin `/api`; the component performs no validation of the value.
- **default-search-label**: Component MUST accept an optional `searchLabel` prop; when omitted, defaults to `Search research papers`.
- **default-search-placeholder**: Component MUST accept an optional `searchPlaceholder` prop; when omitted, defaults to `Search papers…`.
- **default-landmark-label**: Component MUST accept an optional `searchLandmarkLabel` prop; when omitted, defaults to `Research paper search`.
- **label-values-verbatim**: Component MUST pass `searchLabel`, `searchPlaceholder` and `searchLandmarkLabel` to SearchView without validating or modifying them.
- **document-type-registration**: Component MUST register `markdownDocumentType` as the document type for search results.
- **search-view-props**: Component MUST render the wrapped SearchView component, passing exactly these props: `source` (the configured SearchSource), `documentType`, `documentHref`, `searchLabel`, `searchPlaceholder`, and `searchLandmarkLabel`.
- **paper-search-source-factory**: The package MUST export `paperSearchSource(options?: { baseUrl?: string; authorSlug?: string }): SearchSource` as a standalone function producing the same SearchSource configuration the component uses internally, so a host can construct it without mounting the component.

