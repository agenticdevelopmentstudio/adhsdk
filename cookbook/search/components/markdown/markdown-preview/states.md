
| State | Appearance change | Trigger |
|-------|------------------|---------|
| Loading | State container shown with "Loading paper…" text, aria-busy="true" | Initial mount or refetch |
| Ready | Markdown content rendered via MarkdownRenderer | Content fetch succeeds and body is non-empty |
| Empty | State container shown with "Empty paper" title and detail text | Content fetch succeeds but body is empty or whitespace-only |
| Error | State container (role="alert") shown with error title, error message, and a Retry button below it | Fetch fails (timeout, HTTP error, network error, JSON parse error) |

