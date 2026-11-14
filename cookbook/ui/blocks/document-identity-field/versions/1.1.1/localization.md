
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `titleLabel` | "Title" | Label for title input; passed as a prop, so callers can localize it |
| `slugLabel` | "Slug" | Label for slug input; passed as a prop, so callers can localize it |
| `statusText.checking` | "Checking…" | Verdict status while availability check is in progress; hardcoded in source, not exposed as a prop |
| `statusText.available` | "Available" | Verdict status when slug is available; hardcoded in source, not exposed as a prop |
| `statusText.unavailable` | "Unavailable" | Verdict status when slug is unavailable; overridden by verdict.reason if present; hardcoded in source, not exposed as a prop |

`titleLabel` and `slugLabel` are props, so callers can localize them. The three status strings are not: they live in a `STATUS_TEXT` map inside the component and are not exposed through any prop, so a caller cannot localize "Checking…", "Available", or "Unavailable" without patching the component. A caller can only work around this for the "unavailable" case by supplying a localized `verdict.reason`, which replaces the default text. The component does not load a translation table.

