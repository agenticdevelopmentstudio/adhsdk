
| String Key | Default (en) | Context | Notes |
|-----------|-------------|---------|-------|
| `allLabel` | `"All"` | "All" row label (configurable per instance; no global key). | The default is an English literal for convenience (e.g., quick prototyping); production callers SHOULD pass an already-localized string. |
| `newLabel` | `"New…"` | "New…" row label (configurable per instance; no global key). | Same as `allLabel`: the default is an English literal; production callers SHOULD pass an already-localized string. The ellipsis is the Unicode character U+2026, not three ASCII dots — the exact glyph and any surrounding punctuation are locale-sensitive choices. |
| `ariaLabel` | (caller-provided) | Accessible label for trigger. | No default; the caller MUST provide an already-localized string. |

