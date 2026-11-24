
| ID | Requirements | Input | Expected |
|----|----|----|----|
| mp-001 | content-url | hit with slug="alice-wonder", publicRoute="paper-001", source with endpoints.content="/:slug/:route" and baseUrl="https://api.example.com" | Fetch request to `https://api.example.com/alice-wonder/paper-001` |
| mp-002 | render-markdown-content | Fetched JSON response `{ "content": "# Title\n\nBody text." }` | MarkdownRenderer is called with content "# Title\n\nBody text."; rendered output appears in DOM |
| mp-003 | apply-reading-theme | Component mounted with MarkdownRenderer output | Root div has data-mdv-theme, data-mdv-shiki-variant attributes; CSS custom properties from READING_THEME.palette are applied as inline style |
| mp-004 | show-loading-state | Initial render before fetch completes | Div with class "adh-mv-state" is visible, contains p with text "Loading paper…", aria-live="polite" and aria-busy="true" are set |
| mp-005 | show-empty-state | Fetch returns `{ "content": "" }` or `{ "content": "   " }` | Div with class "adh-mv-state" shows title "Empty paper" and detail "This paper has no content yet." |
| mp-006 | show-error-state | Fetch fails with HTTP 404 | Div with class "adh-mv-state adh-mv-state--error" is visible with role="alert", title "Failed to load paper", detail "Failed to load paper (HTTP 404)." |
| mp-007 | handle-timeout | timeoutMs=5000, fetch stalls > 5000ms | Request is aborted at the timeout; component shows error state with message "Timed out loading paper after 5s." |
| mp-008 | distinguish-timeout-from-other-errors | timeoutMs=5000, fetch rejects immediately with a network error (not a timeout) | Error state shows the network error's own message, never the "Timed out loading paper after …" wording |
| mp-009 | provide-retry-capability | Component in error state, user clicks Retry button | The same request is re-issued for the same hit and source, without remounting; component returns to loading state |
| mp-010 | abort-on-change | hit.author.slug changes from "alice" to "bob" while the first request is still pending (loading state) | The first request's signal is aborted; a new fetch is initiated for the new slug; the component stays in or returns to the loading state for the new document and never shows the first request's result |
| mp-011 | handle-non-ok-http-status | Fetch returns HTTP 500 | Error state is shown with message "Failed to load paper (HTTP 500)." |
| mp-012 | stable-refetch-dependencies | source prop is recreated each render (new object, same values); hit stays the same | Fetch does not re-run — no new request is issued while slug, route, baseUrl, endpoints.content, and timeoutMs stay the same |
| mp-013 | content-url | hit with slug="a b/c", publicRoute="p-1", source with endpoints.content="/:slug/:route" and baseUrl="https://api.example.com" | Fetch request to `https://api.example.com/a%20b%2Fc/p-1` |
| mp-014 | stable-refetch-dependencies | Same hit; source recreated with a different `fetchInit` (e.g. new auth header) and identical other values | No new request is issued |
| mp-015 | stable-refetch-dependencies | Same hit and source; `timeoutMs` changes from 15000 to 20000 | A new request is issued |
| mp-016 | stable-refetch-dependencies | Same hit; `source.endpoints.content` changes from "/:slug/:route" to "/v2/:slug/:route" | A new request is issued to the new URL |
| mp-017 | abort-on-change | Component unmounts while the request is pending | The request's signal is aborted and no state update occurs afterward |
| mp-018 | show-empty-state | Fetch returns `{}` (no `content` key) | Empty state is shown ("Empty paper"), not the error state |
| mp-019 | handle-timeout | `timeoutMs` prop omitted; fetch stalls longer than 15s | Request is aborted at 15s; error state shows "Timed out loading paper after 15s." |
