
- **authorSlug whitespace**: See **author-slug-normalization** — authorSlug is trimmed and lowercased before being passed to fixedParams (internal whitespace is kept), and an empty string after trimming is treated as authorSlug not having been provided.
- **baseUrl override**: See **base-url-override** — a provided baseUrl replaces the default `/api` and its format is not validated.
- **Label customization**: The searchLabel, searchPlaceholder, and searchLandmarkLabel props exist to support host-specific terminology. See **label-values-verbatim**.
