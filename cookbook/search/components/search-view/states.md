
| State | Appearance change |
|-------|------------------|
| Default | —  |
| Loading | Loading skeleton: 3 placeholder bars with `animate-pulse` and `bg-apt-surface-2`. Container has `aria-busy="true"`. |
| Inactive (no query/facet) | EmptyState prompt displayed; no list or fetch occurs. |
| Empty results | "No matching documents" message with optional "remove filters" hint. |
| Hard error (error, no cache) | Full error block (min-height 160px) centered, with error message and Retry button. |
| Stale error (error, cached results) | Compact error strip above cached results; no min-height, self-start Retry button. |
| Preview collapsed | Preview dock shows minimal header: collapse toggle, title (or "Preview"), subtitle hint. No body region. |
| Preview disclosed | Preview dock expands to fill its flex ratio; metadata header and rendered body visible; SplitDivider above the dock appears. |

