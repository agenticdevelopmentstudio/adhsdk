
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `markdownPreview.loading.detail` | "Loading paper…" | Loading state detail text |
| `markdownPreview.empty.title` | "Empty paper" | Empty state title |
| `markdownPreview.empty.detail` | "This paper has no content yet." | Empty state detail |
| `markdownPreview.error.title` | "Failed to load paper" | Error state title |
| `markdownPreview.error.detail` | (dynamic) | Error state detail: either the timeout message or the underlying error's message |
| `markdownPreview.retry.label` | "Retry" | Retry button label |

Note: Strings are hardcoded in the component; no i18n framework is integrated. Localization would require extracting strings to a message catalog and applying a translation layer.

