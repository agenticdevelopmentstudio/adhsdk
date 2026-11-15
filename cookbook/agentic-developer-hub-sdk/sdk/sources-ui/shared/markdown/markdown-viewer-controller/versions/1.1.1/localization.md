
Five user-facing strings are hardcoded and should be externalized as localization keys:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `mdv.idle.detail` | No document selected. | Idle state message |
| `mdv.loading.title` | Loading… | Loading state title |
| `mdv.error.title` | Failed to load document | Error state title |
| `mdv.empty.title` | Empty document | Empty state title |
| `mdv.empty.detail` | This document has no content yet. | Empty state detail |

The error detail text shown in the Error state comes from the fetch/network layer, not from a fixed string in this component, and is not part of this key set; a network error with no message MUST still show a generic, localized fallback (see **fetch-error-handling**, Edge Cases). Markdown content itself is localized by the backend providing the content in the appropriate language; the component renders it as-is.

