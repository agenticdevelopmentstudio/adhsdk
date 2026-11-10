
| ID | Requirements | Input | Expected |
|----|----|----|----|
| mp-001 | content-url, stable-refetch-dependencies | hit with slug="alice-wonder", publicRoute="paper-001", source with endpoints.content="/:slug/:route" and baseUrl="https://api.example.com" | Fetch request to `https://api.example.com/alice-wonder/paper-001` (URL-encoded); slug and route are percent-encoded if they contain special characters |
| mp-002 | render-markdown-content | Fetched JSON response `{ "content": "# Title\n\nBody text." }` | MarkdownRenderer is called with content "# Title\n\nBody text."; rendered output appears in DOM |
| mp-003 | apply-reading-theme | Component mounted with MarkdownRenderer output | Root div has data-mdv-theme, data-mdv-shiki-variant attributes; CSS custom properties from READING_THEME.palette are applied as inline style |
| mp-004 | show-loading-state | Initial render before fetch completes | Div with class "adh-mv-state" is visible, contains p with text "Loading paper…", aria-live="polite" and aria-busy="true" are set |
| mp-005 | show-empty-state | Fetch returns `{ "content": "" }` or `{ "content": "   " }` | Div with class "adh-mv-state" shows title "Empty paper" and detail "This paper has no content yet." |
| mp-006 | show-error-state | Fetch fails with HTTP 404 | Div with class "adh-mv-state adh-mv-state--error" is visible with role="alert", title "Failed to load paper", detail "Failed to load paper (HTTP 404)." |
| mp-007 | handle-timeout | timeoutMs=5000, fetch stalls > 5000ms | Request is aborted at the timeout; component shows error state with message "Timed out loading paper after 5s." |
| mp-008 | distinguish-timeout-from-other-errors | timeoutMs=5000, fetch rejects immediately with a network error (not a timeout) | Error state shows the network error's own message, never the "Timed out loading paper after …" wording |
| mp-009 | provide-retry-capability | Component in error state, user clicks Retry button | The same request is re-issued for the same hit and source, without remounting; component returns to loading state |
| mp-010 | abort-on-change | hit.author.slug changes from "alice" to "bob" during error state | In-flight fetch is aborted (if any); new fetch is initiated for the new slug; component transitions through loading state for the new document |
| mp-011 | handle-non-ok-http-status | Fetch returns HTTP 500 | Error state is shown with message "Failed to load paper (HTTP 500)." |
| mp-012 | stable-refetch-dependencies | source prop is recreated each render (new object, same values); hit stays the same | Fetch does not re-run — no new request is issued while slug, route, baseUrl, endpoints.content, and timeoutMs stay the same |

