
- **Missing documentHref**: `documentHref` is a required, non-optional prop with no runtime default. This is a type-level constraint enforced by the TypeScript compiler at call sites, not an observable runtime behavior, so it has no conformance test vector.
- **authorSlug whitespace**: See **author-slug-normalization** — authorSlug is trimmed and lowercased before being passed to fixedParams, and an empty string after trimming is treated as authorSlug not having been provided.
- **baseUrl override**: When baseUrl is provided, it MUST override the default `/api` value. No validation of baseUrl format is performed by the component.
- **Label customization**: The searchLabel, searchPlaceholder, and searchLandmarkLabel props exist to support host-specific terminology. The component MUST NOT validate or modify these values.
- **Empty corpus response**: No edge case handling is specified for empty search results; this is handled by SearchView.

