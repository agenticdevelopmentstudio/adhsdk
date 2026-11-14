
| Proposed String Key | Default (en) | Context |
|-----------|-------------|---------|
| `placeholder` | "Filter…" | Input field placeholder; customizable via props |
| `empty.no-items` | "No items." | Shown when total === 0 |
| `empty.no-matches` | "No matches for "{query}"." | Shown when filter returns zero results; customizable via emptyContent prop |

The source hardcodes these literals (`"Filter…"`, `"No items."`, `"No matches for …"`) with no localization lookup; the keys are proposed names for a future string table, and no i18n layer exists in the component.

The default filter match lower-cases both the query and each searched field using the platform's default (locale-sensitive) case folding (see **filter-items**); this is appropriate for search-as-you-type but is not a substitute for a linguistically exact comparison, and no invariant-culture-insensitive call is used or recommended for this user-facing text.

