
- **Data collected**: SearchView itself collects no data beyond what the user types or selects. The search query, filters, and selected result are held in local state and passed to the host's data-fetching layer and link builder.
- **Storage**: Filters are written to the URL query string if `urlSync` is true. No other persistent storage is used by the component.
- **Transmission**: The component performs network requests itself, via its `useDocumentSearch` and `useFacets` hooks (plain `fetch`), against the endpoint and parameters defined by the host's `source` prop; the supplied `Preview` component may issue additional requests. The host controls the destination through `source`, but SearchView — not just the host application — is the one making the calls.
- **Retention**: The component itself retains no data beyond the current render. However, because the query and active facets are written into the URL (when `urlSync` is enabled), they persist wherever the URL persists — browser history, bookmarks, shared links, and server referrer logs — for as long as those retain it, independent of the page session and outside the component's control.

